import { AI_MODELS } from "../_shared/ai_models.ts";
import { errorResponse, jsonResponse } from "../_shared/http.ts";
import type { JsonModel, JsonModelRequest } from "../_shared/json_model.ts";
import {
  buildTipPrompt,
  buildTipRetryPrompt,
  TIP_SYSTEM_PROMPT,
} from "./prompt.ts";
import { parseCoachTipRequest } from "./request.ts";
import { parseTip, tipSchema, toGeminiSchema } from "./tip_schema.ts";
import type { TipStore } from "./types.ts";

const MAX_ATTEMPTS = 2;

export interface CoachTipDeps {
  store: TipStore;
  model: JsonModel;
}

type GenerationOutcome =
  | { kind: "valid"; tip: string }
  | { kind: "invalid" }
  | { kind: "unavailable" };

export async function handleCoachTip(
  request: Request,
  deps: CoachTipDeps,
): Promise<Response> {
  if (request.method !== "POST") {
    return errorResponse(405, "method_not_allowed");
  }
  const body = await parseCoachTipRequest(request);
  if (body === null) return errorResponse(400, "invalid_request");

  const { store, model } = deps;
  const userId = await store.userId();
  if (userId === null) return errorResponse(401, "unauthorized");

  const profile = await store.profile(userId);
  if (profile === null) return errorResponse(409, "profile_incomplete");

  const plan = await store.activePlan(userId);
  if (plan === null) return errorResponse(409, "no_plan");

  const existing = await store.existingTip(userId, plan.id, body.date);
  if (existing !== null) return jsonResponse(200, { tip: existing });

  const outcome = await generateValidTip(model, {
    model: AI_MODELS[profile.aiModel].id,
    systemInstruction: TIP_SYSTEM_PROMPT,
    prompt: buildTipPrompt({ profile, weekday: body.weekday, plan }),
    schema: toGeminiSchema(tipSchema),
  });
  if (outcome.kind === "unavailable") {
    return errorResponse(502, "ai_unavailable");
  }
  if (outcome.kind === "invalid") {
    return errorResponse(502, "ai_invalid_output");
  }

  await store.saveTip(userId, plan.id, body.date, outcome.tip);
  const saved = await store.existingTip(userId, plan.id, body.date);
  if (saved === null) throw new Error("The coach tip is missing after saving");
  return jsonResponse(200, { tip: saved });
}

async function generateValidTip(
  model: JsonModel,
  request: JsonModelRequest,
): Promise<GenerationOutcome> {
  let prompt = request.prompt;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    let text: string;
    try {
      text = await model.generateJson({ ...request, prompt });
    } catch (error) {
      console.error("Gemini request failed", error);
      return { kind: "unavailable" };
    }
    const result = parseTip(text);
    if (result.ok) return { kind: "valid", tip: result.tip };
    console.warn(`Tip attempt ${attempt} was invalid`, result.errors);
    prompt = buildTipRetryPrompt(request.prompt, result.errors);
  }
  return { kind: "invalid" };
}
