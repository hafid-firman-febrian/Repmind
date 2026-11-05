import { AI_MODELS } from "../_shared/ai_models.ts";
import type {
  ChatEvent,
  ChatModel,
  ChatModelRequest,
} from "../_shared/chat_model.ts";
import { errorResponse } from "../_shared/http.ts";
import { sseResponse, type SseSend } from "../_shared/sse.ts";
import type { CoachPlan } from "../_shared/training.ts";
import {
  buildCoachPrompt,
  buildProposalRetryPrompt,
  COACH_SYSTEM_PROMPT,
} from "./prompt.ts";
import { buildProposal, type ProposalContext } from "./proposal.ts";
import { parseCoachChatRequest } from "./request.ts";
import { PROPOSE_PLAN_CHANGE } from "./tool.ts";
import type { ChatHistoryMessage, CoachStore, PlanProposal } from "./types.ts";

const HISTORY_LIMIT = 20;
const MAX_REPLY_CHARS = 8000;
const FALLBACK_TEXT = "Here's the change I suggest.";
const FAILURE_NOTE = "I couldn't prepare that change. Try asking again.";
const NOTE_SEPARATOR = "\n\n";
const TEXT_BUDGET = MAX_REPLY_CHARS - NOTE_SEPARATOR.length -
  FAILURE_NOTE.length;

export interface CoachChatDeps {
  store: CoachStore;
  model: ChatModel;
}

interface Collected {
  text: string;
  toolArgs: unknown;
  hasToolCall: boolean;
}

interface Resolution {
  proposal: PlanProposal | null;
  userConfirmed: boolean;
  failed: boolean;
}

export async function handleCoachChat(
  request: Request,
  deps: CoachChatDeps,
): Promise<Response> {
  if (request.method !== "POST") {
    return errorResponse(405, "method_not_allowed");
  }
  const body = await parseCoachChatRequest(request);
  if (body === null) return errorResponse(400, "invalid_request");

  const { store, model } = deps;
  const userId = await store.userId();
  if (userId === null) return errorResponse(401, "unauthorized");

  const profile = await store.profile(userId);
  if (profile === null) return errorResponse(409, "profile_incomplete");

  const [plan, recent] = await Promise.all([
    store.activePlan(userId),
    store.recentMessages(userId, HISTORY_LIMIT),
  ]);
  const catalog = plan === null ? [] : await store.catalog(profile.equipment);

  let userMessageId: string;
  let conversation: ChatHistoryMessage[];
  if (body.kind === "retry") {
    const last = recent.at(-1);
    if (
      last === undefined || last.id !== body.retryMessageId ||
      last.role !== "user"
    ) {
      return errorResponse(409, "retry_not_available");
    }
    userMessageId = last.id;
    conversation = recent;
  } else {
    userMessageId = await store.saveUserMessage(userId, body.message);
    conversation = [
      ...recent.slice(-(HISTORY_LIMIT - 1)),
      {
        id: userMessageId,
        role: "user",
        content: body.message,
        proposal: null,
        appliedPlanId: null,
      },
    ];
  }

  const prompt = buildCoachPrompt({
    profile,
    weekday: body.weekday,
    plan,
    catalog,
    pendingProposal: plan === null ? null : findPending(recent, plan),
    history: conversation,
  });
  const modelRequest: ChatModelRequest = {
    model: AI_MODELS[profile.aiModel].id,
    systemInstruction: COACH_SYSTEM_PROMPT,
    prompt,
    tools: plan === null ? [] : [PROPOSE_PLAN_CHANGE],
  };
  const context: ProposalContext | null = plan === null
    ? null
    : { plan, catalog, aiModel: profile.aiModel };

  return sseResponse(async (send, signal) => {
    send({ type: "started", user_message_id: userMessageId });
    try {
      await reply({
        send,
        signal,
        store,
        model,
        userId,
        modelRequest,
        context,
      });
    } catch (error) {
      if (signal.aborted) return;
      console.error("Gemini request failed", error);
      send({ type: "error", code: "ai_unavailable" });
    }
  });
}

interface ReplyInput {
  send: SseSend;
  signal: AbortSignal;
  store: CoachStore;
  model: ChatModel;
  userId: string;
  modelRequest: ChatModelRequest;
  context: ProposalContext | null;
}

async function reply(input: ReplyInput): Promise<void> {
  const { send, signal, store, model, userId, modelRequest, context } = input;
  const first = await collect(
    model,
    { ...modelRequest, signal },
    (text) => send({ type: "delta", text }),
  );
  if (signal.aborted) return;

  const resolution = await resolveProposal(
    first,
    context,
    (errors) =>
      collect(model, {
        ...modelRequest,
        prompt: buildProposalRetryPrompt(
          modelRequest.prompt,
          first.text,
          errors,
        ),
        forceTool: true,
        signal,
      }),
  );
  if (signal.aborted) return;

  let content = first.text;
  if (resolution.failed) {
    const note = content.length > 0
      ? `${NOTE_SEPARATOR}${FAILURE_NOTE}`
      : FAILURE_NOTE;
    send({ type: "delta", text: note });
    content += note;
  } else if (content.trim() === "") {
    if (resolution.proposal === null) {
      send({ type: "error", code: "ai_invalid_output" });
      return;
    }
    content = FALLBACK_TEXT;
  }

  let messageId: string;
  try {
    messageId = await store.saveAssistantMessage(
      userId,
      content,
      resolution.proposal,
    );
  } catch (error) {
    console.error("Saving the coach reply failed", error);
    send({ type: "error", code: "save_failed" });
    return;
  }
  send({
    type: "done",
    message_id: messageId,
    proposal: resolution.proposal,
    user_confirmed: resolution.userConfirmed,
  });
}

async function resolveProposal(
  first: Collected,
  context: ProposalContext | null,
  retry: (errors: string[]) => Promise<Collected>,
): Promise<Resolution> {
  const none: Resolution = {
    proposal: null,
    userConfirmed: false,
    failed: false,
  };
  if (context === null || !first.hasToolCall) return none;

  const attempt = buildProposal(first.toolArgs, context);
  if (attempt.ok) {
    return {
      proposal: attempt.proposal,
      userConfirmed: attempt.userConfirmed,
      failed: false,
    };
  }
  console.warn("Proposal attempt 1 was invalid", attempt.errors);

  const second = await retry(attempt.errors);
  const secondAttempt = second.hasToolCall
    ? buildProposal(second.toolArgs, context)
    : { ok: false as const, errors: ["propose_plan_change was not called"] };
  if (secondAttempt.ok) {
    return {
      proposal: secondAttempt.proposal,
      userConfirmed: secondAttempt.userConfirmed,
      failed: false,
    };
  }
  console.warn("Proposal attempt 2 was invalid", secondAttempt.errors);
  return { proposal: null, userConfirmed: false, failed: true };
}

async function collect(
  model: ChatModel,
  request: ChatModelRequest,
  forward?: (text: string) => void,
): Promise<Collected> {
  const collected: Collected = { text: "", toolArgs: null, hasToolCall: false };
  for await (const event of model.stream(request)) {
    if (request.signal?.aborted) break;
    handleEvent(event, collected, forward);
  }
  return collected;
}

function handleEvent(
  event: ChatEvent,
  collected: Collected,
  forward?: (text: string) => void,
): void {
  if (event.type === "tool_call") {
    if (!collected.hasToolCall && event.name === PROPOSE_PLAN_CHANGE.name) {
      collected.hasToolCall = true;
      collected.toolArgs = event.args;
    }
    return;
  }
  if (forward === undefined) return;
  const room = TEXT_BUDGET - collected.text.length;
  if (room <= 0) return;
  const piece = fit(event.text, room);
  if (piece.length === 0) return;
  collected.text += piece;
  forward(piece);
}

function fit(text: string, room: number): string {
  if (text.length <= room) return text;
  const cut = text.slice(0, room);
  const last = cut.charCodeAt(cut.length - 1);
  return last >= 0xd800 && last <= 0xdbff ? cut.slice(0, -1) : cut;
}

function findPending(
  messages: ChatHistoryMessage[],
  plan: CoachPlan,
): PlanProposal | null {
  const latest = messages.findLast((message) => message.proposal !== null);
  if (
    latest === undefined || latest.proposal === null ||
    latest.appliedPlanId !== null ||
    latest.proposal.based_on_plan_id !== plan.id
  ) {
    return null;
  }
  return latest.proposal;
}
