import {
  assert,
  assertEquals,
  assertRejects,
  assertStringIncludes,
} from "jsr:@std/assert@^1";
import type {
  ChatEvent,
  ChatModel,
  ChatModelRequest,
} from "../_shared/chat_model.ts";
import type {
  CatalogExercise,
  CoachPlan,
  PlanProfile,
} from "../_shared/training.ts";
import {
  coachCatalog,
  coachPlan,
  coachProfile,
  pendingProposal,
  PLAN_ID,
} from "./fixtures.ts";
import { handleCoachChat } from "./handler.ts";
import type { ChatHistoryMessage, CoachStore, PlanProposal } from "./types.ts";

const FAILURE_NOTE = "I couldn't prepare that change. Try asking again.";
const FALLBACK_TEXT = "Here's the change I suggest.";
const RETRY_ID = "8a1f0c52-6f0e-4d7e-9a53-2f4a1f0b9c02";
const ANSWER_ID = "9b2f0c52-6f0e-4d7e-9a53-2f4a1f0b9c03";

interface StoreOptions {
  userId?: string | null;
  profile?: PlanProfile | null;
  plan?: CoachPlan | null;
  messages?: ChatHistoryMessage[];
  activePlanError?: Error;
  assistantSaveError?: Error;
}

class FakeStore implements CoachStore {
  userMessages: string[] = [];
  assistantSaves: {
    content: string;
    proposal: PlanProposal | null;
  }[] = [];
  recentLimits: number[] = [];

  constructor(private readonly options: StoreOptions = {}) {}

  userId(): Promise<string | null> {
    return Promise.resolve(
      this.options.userId === undefined ? "user-1" : this.options.userId,
    );
  }

  profile(_userId: string): Promise<PlanProfile | null> {
    return Promise.resolve(
      this.options.profile === undefined ? coachProfile : this.options.profile,
    );
  }

  catalog(_equipment: string[]): Promise<CatalogExercise[]> {
    return Promise.resolve(coachCatalog);
  }

  activePlan(_userId: string): Promise<CoachPlan | null> {
    if (this.options.activePlanError) {
      return Promise.reject(this.options.activePlanError);
    }
    return Promise.resolve(
      this.options.plan === undefined ? coachPlan() : this.options.plan,
    );
  }

  recentMessages(
    _userId: string,
    limit: number,
  ): Promise<ChatHistoryMessage[]> {
    this.recentLimits.push(limit);
    return Promise.resolve(this.options.messages ?? []);
  }

  saveUserMessage(_userId: string, content: string): Promise<string> {
    this.userMessages.push(content);
    return Promise.resolve("user-msg-1");
  }

  saveAssistantMessage(
    _userId: string,
    content: string,
    proposal: PlanProposal | null,
  ): Promise<string> {
    if (this.options.assistantSaveError) {
      return Promise.reject(this.options.assistantSaveError);
    }
    this.assistantSaves.push({ content, proposal });
    return Promise.resolve("assistant-msg-1");
  }
}

type Script = Array<ChatEvent | Error>;

class FakeModel implements ChatModel {
  requests: ChatModelRequest[] = [];

  constructor(private readonly scripts: Script[]) {}

  async *stream(request: ChatModelRequest): AsyncGenerator<ChatEvent> {
    this.requests.push(request);
    const script = this.scripts.shift();
    if (script === undefined) throw new Error("no script left");
    for (const item of script) {
      if (item instanceof Error) throw item;
      yield await Promise.resolve(item);
    }
  }
}

class HangingModel implements ChatModel {
  requests: ChatModelRequest[] = [];
  parked: Promise<void>;
  finished: Promise<void>;
  #markParked!: () => void;
  #markFinished!: () => void;

  constructor() {
    this.parked = new Promise((resolve) => this.#markParked = resolve);
    this.finished = new Promise((resolve) => this.#markFinished = resolve);
  }

  async *stream(request: ChatModelRequest): AsyncGenerator<ChatEvent> {
    this.requests.push(request);
    try {
      yield { type: "text", text: "Hello" };
      const aborted = new Promise<void>((resolve) => {
        request.signal?.addEventListener("abort", () => resolve());
      });
      this.#markParked();
      await aborted;
    } finally {
      this.#markFinished();
    }
  }
}

function text(value: string): ChatEvent {
  return { type: "text", text: value };
}

function toolCall(args: unknown): ChatEvent {
  return { type: "tool_call", name: "propose_plan_change", args };
}

const validArgs = {
  day_number: 2,
  changes: [{
    from_exercise_id: "dumbbell_shoulder_press",
    to_exercise_id: "dumbbell_lateral_raise",
    sets: 3,
    reps: "12",
    rest_seconds: 60,
  }],
};

const invalidArgs = {
  day_number: 6,
  changes: validArgs.changes,
};

function post(body: unknown): Request {
  return new Request("http://localhost/coach-chat", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

const newMessage = { message: "My shoulder feels tight today", weekday: 4 };

async function readEvents(response: Response): Promise<
  Array<Record<string, unknown>>
> {
  const body = await response.text();
  return body.split("\n\n").filter((chunk) => chunk.length > 0).map((chunk) => {
    assert(chunk.startsWith("data: "));
    return JSON.parse(chunk.slice("data: ".length));
  });
}

function types(events: Array<Record<string, unknown>>): unknown[] {
  return events.map((event) => event.type);
}

function deltas(events: Array<Record<string, unknown>>): string[] {
  return events.filter((event) => event.type === "delta").map((event) =>
    event.text as string
  );
}

function history(
  role: "user" | "assistant",
  content: string,
  extra: Partial<ChatHistoryMessage> = {},
): ChatHistoryMessage {
  return {
    id: `msg-${content}`,
    role,
    content,
    proposal: null,
    appliedPlanId: null,
    ...extra,
  };
}

async function converse(
  store: CoachStore,
  model: ChatModel,
  body: unknown = newMessage,
  expectedLogs = 0,
): Promise<Array<Record<string, unknown>>> {
  const logs: unknown[][] = [];
  const originalError = console.error;
  const originalWarn = console.warn;
  console.error = (...args: unknown[]) => void logs.push(args);
  console.warn = (...args: unknown[]) => void logs.push(args);
  let events: Array<Record<string, unknown>>;
  try {
    const response = await handleCoachChat(post(body), { store, model });
    events = await readEvents(response);
  } finally {
    console.error = originalError;
    console.warn = originalWarn;
  }
  assertEquals(logs.length, expectedLogs);
  return events;
}

Deno.test("only accepts POST", async () => {
  const response = await handleCoachChat(
    new Request("http://localhost/coach-chat"),
    { store: new FakeStore(), model: new FakeModel([]) },
  );

  assertEquals(response.status, 405);
  assertEquals(await response.json(), { error: "method_not_allowed" });
});

Deno.test("rejects an invalid body", async () => {
  const response = await handleCoachChat(post({ weekday: 4 }), {
    store: new FakeStore(),
    model: new FakeModel([]),
  });

  assertEquals(response.status, 400);
  assertEquals(await response.json(), { error: "invalid_request" });
});

Deno.test("requires a signed-in user", async () => {
  const response = await handleCoachChat(post(newMessage), {
    store: new FakeStore({ userId: null }),
    model: new FakeModel([]),
  });

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "unauthorized" });
});

Deno.test("requires a finished onboarding", async () => {
  const response = await handleCoachChat(post(newMessage), {
    store: new FakeStore({ profile: null }),
    model: new FakeModel([]),
  });

  assertEquals(response.status, 409);
  assertEquals(await response.json(), { error: "profile_incomplete" });
});

Deno.test("a retry of a message that is not the last is not available", async () => {
  const store = new FakeStore({
    messages: [
      history("user", "first", { id: RETRY_ID }),
      history("assistant", "answer"),
      history("user", "second"),
    ],
  });

  const response = await handleCoachChat(
    post({ retry_message_id: RETRY_ID, weekday: 4 }),
    { store, model: new FakeModel([]) },
  );

  assertEquals(response.status, 409);
  assertEquals(await response.json(), { error: "retry_not_available" });
});

Deno.test("a retry of a message that already has an answer is not available", async () => {
  const store = new FakeStore({
    messages: [
      history("user", "first", { id: RETRY_ID }),
      history("assistant", "answer", { id: ANSWER_ID }),
    ],
  });

  const unknown = await handleCoachChat(
    post({ retry_message_id: ANSWER_ID, weekday: 4 }),
    { store, model: new FakeModel([]) },
  );
  const answered = await handleCoachChat(
    post({ retry_message_id: RETRY_ID, weekday: 4 }),
    { store, model: new FakeModel([]) },
  );

  assertEquals(unknown.status, 409);
  assertEquals(answered.status, 409);
  assertEquals(await answered.json(), { error: "retry_not_available" });
});

Deno.test("a failing plan read throws and saves no user message", async () => {
  const store = new FakeStore({ activePlanError: new Error("db down") });

  await assertRejects(
    () =>
      handleCoachChat(post(newMessage), {
        store,
        model: new FakeModel([]),
      }),
    Error,
    "db down",
  );
  assertEquals(store.userMessages, []);
});

Deno.test("streams and saves a plain reply", async () => {
  const store = new FakeStore();
  const model = new FakeModel([[text("Ease "), text("off today.")]]);

  const response = await handleCoachChat(post(newMessage), { store, model });

  assertEquals(response.status, 200);
  assertEquals(response.headers.get("Content-Type"), "text/event-stream");
  const events = await readEvents(response);
  assertEquals(types(events), ["started", "delta", "delta", "done"]);
  assertEquals(events[0].user_message_id, "user-msg-1");
  assertEquals(deltas(events), ["Ease ", "off today."]);
  assertEquals(events[3], {
    type: "done",
    message_id: "assistant-msg-1",
    proposal: null,
    user_confirmed: false,
  });
  assertEquals(store.userMessages, [newMessage.message]);
  assertEquals(store.assistantSaves, [{
    content: "Ease off today.",
    proposal: null,
  }]);
});

Deno.test("uses the model from the allowlist", async () => {
  const model = new FakeModel([[text("Hi")]]);

  await converse(new FakeStore(), model);

  assertEquals(model.requests[0].model, "gemini-3.5-flash-lite");
  assertEquals(model.requests[0].tools.length, 1);
  assertEquals(model.requests[0].tools[0].name, "propose_plan_change");
});

Deno.test("reads the last 20 messages and puts the new one at the end", async () => {
  const store = new FakeStore({
    messages: [history("user", "older question"), history("assistant", "ok")],
  });
  const model = new FakeModel([[text("Hi")]]);

  await converse(store, model);

  assertEquals(store.recentLimits, [20]);
  const prompt = model.requests[0].prompt;
  assertStringIncludes(prompt, "User: older question");
  assertStringIncludes(
    prompt,
    `## Latest message (answer this one)\n${newMessage.message}`,
  );
  assert(prompt.endsWith(newMessage.message));
});

Deno.test("keeps the prompt history to 20 messages with the new one included", async () => {
  const messages = Array.from(
    { length: 20 },
    (_, index) => history("user", `question ${index}`),
  );
  const model = new FakeModel([[text("Hi")]]);

  await converse(new FakeStore({ messages }), model);

  const prompt = model.requests[0].prompt;
  assert(!prompt.includes("question 0"));
  assertStringIncludes(prompt, "question 1");
  assertStringIncludes(prompt, "question 19");
});

Deno.test("a valid tool call is saved and returned", async () => {
  const store = new FakeStore();
  const model = new FakeModel([[
    text("Swap it for a lateral raise."),
    toolCall(validArgs),
  ]]);

  const events = await converse(store, model);

  const done = events.at(-1)!;
  assertEquals(done.type, "done");
  const proposal = done.proposal as PlanProposal;
  assertEquals(
    proposal.summary,
    "Swap Dumbbell Shoulder Press for Dumbbell Lateral Raise",
  );
  assertEquals(proposal.based_on_plan_id, PLAN_ID);
  assertEquals(done.user_confirmed, false);
  assertEquals(store.assistantSaves[0].proposal, proposal);
  assertEquals(model.requests.length, 1);
});

Deno.test("a confirmed tool call sets user_confirmed", async () => {
  const messages = [
    history("user", "My shoulder hurts"),
    history("assistant", "Swap the press?", {
      proposal: pendingProposal(),
    }),
  ];
  const model = new FakeModel([[
    text("Here it is, take a look."),
    toolCall({ ...validArgs, user_confirmed: true }),
  ]]);

  const events = await converse(
    new FakeStore({ messages }),
    model,
    { message: "yes please", weekday: 4 },
  );

  assertEquals(events.at(-1)!.user_confirmed, true);
  assertStringIncludes(
    model.requests[0].prompt,
    "## Suggestion waiting for an answer",
  );
});

Deno.test("an applied or outdated suggestion is not waiting for an answer", async () => {
  const applied = [
    history("assistant", "Swap?", {
      proposal: pendingProposal(),
      appliedPlanId: "plan-2",
    }),
  ];
  const outdated = [
    history("assistant", "Swap?", {
      proposal: { ...pendingProposal(), based_on_plan_id: "old-plan" },
    }),
  ];

  for (const messages of [applied, outdated]) {
    const model = new FakeModel([[text("Hi")]]);
    await converse(new FakeStore({ messages }), model);
    assert(
      !model.requests[0].prompt.includes("## Suggestion waiting for an answer"),
    );
  }
});

Deno.test("an invalid tool call retries once without forwarding text", async () => {
  const model = new FakeModel([
    [text("Swap it for a lateral raise."), toolCall(invalidArgs)],
    [text("this text is not forwarded"), toolCall(validArgs)],
  ]);
  const store = new FakeStore();

  const events = await converse(store, model, newMessage, 1);

  assertEquals(model.requests.length, 2);
  assertEquals(model.requests[0].forceTool, undefined);
  assertEquals(model.requests[1].forceTool, true);
  assertStringIncludes(
    model.requests[1].prompt,
    "Swap it for a lateral raise.",
  );
  assertStringIncludes(model.requests[1].prompt, "Day 6 is not in the plan");
  assertEquals(deltas(events), ["Swap it for a lateral raise."]);
  const done = events.at(-1)!;
  assertEquals(done.type, "done");
  assertEquals((done.proposal as PlanProposal).day_number, 2);
  assertEquals(store.assistantSaves[0].content, "Swap it for a lateral raise.");
});

Deno.test("a second invalid tool call appends the note", async () => {
  const model = new FakeModel([
    [text("Swap it."), toolCall(invalidArgs)],
    [toolCall(invalidArgs)],
  ]);
  const store = new FakeStore();

  const events = await converse(store, model, newMessage, 2);

  assertStringIncludes(deltas(events).at(-1)!, FAILURE_NOTE);
  assertEquals(events.at(-1)!.type, "done");
  assertEquals(events.at(-1)!.proposal, null);
  assert(store.assistantSaves[0].content.endsWith(FAILURE_NOTE));
  assertStringIncludes(store.assistantSaves[0].content, "Swap it.");
  assertEquals(store.assistantSaves[0].proposal, null);
  assertEquals(model.requests.length, 2);
});

Deno.test("a retry that makes no tool call appends the note", async () => {
  const model = new FakeModel([
    [text("Swap it."), toolCall(invalidArgs)],
    [text("sorry")],
  ]);
  const store = new FakeStore();

  await converse(store, model, newMessage, 2);

  assert(store.assistantSaves[0].content.endsWith(FAILURE_NOTE));
  assertEquals(store.assistantSaves[0].proposal, null);
});

Deno.test("no plan sends no tools", async () => {
  const store = new FakeStore({ plan: null });
  const model = new FakeModel([[
    text("Generate a plan first."),
    toolCall(
      validArgs,
    ),
  ]]);

  const events = await converse(store, model);

  assertEquals(model.requests[0].tools.length, 0);
  assertEquals(model.requests.length, 1);
  assertEquals(events.at(-1)!.type, "done");
  assertEquals(events.at(-1)!.proposal, null);
  assertEquals(store.assistantSaves[0].content, "Generate a plan first.");
});

Deno.test("empty text with a valid proposal uses the fallback", async () => {
  const store = new FakeStore();
  const model = new FakeModel([[toolCall(validArgs)]]);

  const events = await converse(store, model);

  assertEquals(deltas(events), [FALLBACK_TEXT]);
  assertEquals(store.assistantSaves[0].content, FALLBACK_TEXT);
  assertEquals(events.at(-1)!.type, "done");
  assertEquals(events.at(-1)!.proposal !== null, true);
});

Deno.test("whitespace-only text with a valid proposal uses the fallback", async () => {
  const store = new FakeStore();
  const model = new FakeModel([[text("  \n"), toolCall(validArgs)]]);

  const events = await converse(store, model);

  assertEquals(deltas(events).at(-1), FALLBACK_TEXT);
  assertEquals(store.assistantSaves[0].content, FALLBACK_TEXT);
  assertEquals(events.at(-1)!.type, "done");
  assertEquals(events.at(-1)!.proposal !== null, true);
});

Deno.test("empty text without a proposal fails", async () => {
  const store = new FakeStore();
  const model = new FakeModel([[]]);

  const events = await converse(store, model);

  assertEquals(events.at(-1), { type: "error", code: "ai_invalid_output" });
  assertEquals(store.assistantSaves, []);
});

Deno.test("a model error before text", async () => {
  const store = new FakeStore();
  const model = new FakeModel([[new Error("quota exceeded")]]);

  const events = await converse(store, model, newMessage, 1);

  assertEquals(types(events), ["started", "error"]);
  assertEquals(events.at(-1), { type: "error", code: "ai_unavailable" });
  assertEquals(store.assistantSaves, []);
  assertEquals(store.userMessages, [newMessage.message]);
});

Deno.test("a model error mid stream", async () => {
  const store = new FakeStore();
  const model = new FakeModel([[text("Half an ans"), new Error("dropped")]]);

  const events = await converse(store, model, newMessage, 1);

  assertEquals(types(events), ["started", "delta", "error"]);
  assertEquals(events.at(-1), { type: "error", code: "ai_unavailable" });
  assertEquals(store.assistantSaves, []);
  assertEquals(store.userMessages, [newMessage.message]);
});

Deno.test("a model error on the proposal retry", async () => {
  const store = new FakeStore();
  const model = new FakeModel([
    [text("Swap it."), toolCall(invalidArgs)],
    [new Error("timeout")],
  ]);

  const events = await converse(store, model, newMessage, 2);

  assertEquals(events.at(-1), { type: "error", code: "ai_unavailable" });
  assertEquals(store.assistantSaves, []);
});

Deno.test("a failed assistant save reports save_failed", async () => {
  const store = new FakeStore({ assistantSaveError: new Error("db down") });
  const model = new FakeModel([[text("Hi")]]);

  const events = await converse(store, model, newMessage, 1);

  assertEquals(types(events), ["started", "delta", "error"]);
  assertEquals(events.at(-1), { type: "error", code: "save_failed" });
});

Deno.test("a retry does not save the user message again", async () => {
  const store = new FakeStore({
    messages: [
      history("assistant", "welcome"),
      history("user", "Is my shoulder ok?", { id: RETRY_ID }),
    ],
  });
  const model = new FakeModel([[text("Probably.")]]);

  const events = await converse(store, model, {
    retry_message_id: RETRY_ID,
    weekday: 4,
  });

  assertEquals(store.userMessages, []);
  assertEquals(events[0], { type: "started", user_message_id: RETRY_ID });
  const prompt = model.requests[0].prompt;
  assertEquals(prompt.split("Is my shoulder ok?").length - 1, 1);
  assert(prompt.endsWith("Is my shoulder ok?"));
  assertEquals(events.at(-1)!.type, "done");
});

Deno.test("a reply over 8000 characters is cut and saved", async () => {
  const store = new FakeStore();
  const model = new FakeModel([[
    text("a".repeat(5000)),
    text("b".repeat(4000)),
  ]]);

  const events = await converse(store, model);

  assertEquals(events.at(-1)!.type, "done");
  assertEquals(store.assistantSaves.length, 1);
  const saved = store.assistantSaves[0].content;
  assert(saved.length <= 8000);
  assert(saved.length > 7000);
  assertEquals(deltas(events).join(""), saved);
});

Deno.test("a tool call after a very long reply is still handled", async () => {
  const store = new FakeStore();
  const model = new FakeModel([[text("a".repeat(9000)), toolCall(validArgs)]]);

  const events = await converse(store, model);

  assertEquals(events.at(-1)!.type, "done");
  assert(events.at(-1)!.proposal !== null);
  assert(store.assistantSaves[0].content.length <= 8000);
});

Deno.test("an invalid tool call after a very long reply still fits in 8000 characters", async () => {
  const store = new FakeStore();
  const model = new FakeModel([
    [text("a".repeat(9000)), toolCall(invalidArgs)],
    [toolCall(invalidArgs)],
  ]);

  await converse(store, model, newMessage, 2);

  const saved = store.assistantSaves[0].content;
  assert(saved.length <= 8000);
  assert(saved.endsWith(FAILURE_NOTE));
});

Deno.test("cancelling stops the model and saves nothing", async () => {
  const store = new FakeStore();
  const model = new HangingModel();

  const response = await handleCoachChat(post(newMessage), { store, model });
  await model.parked;
  await response.body!.cancel();
  await model.finished;
  await new Promise((resolve) => setTimeout(resolve, 0));

  assertEquals(model.requests[0].signal?.aborted, true);
  assertEquals(store.assistantSaves, []);
  assertEquals(store.userMessages, [newMessage.message]);
});
