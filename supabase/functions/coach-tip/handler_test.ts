import {
  assertEquals,
  assertRejects,
  assertStringIncludes,
} from "jsr:@std/assert@^1";
import type { JsonModel, JsonModelRequest } from "../_shared/json_model.ts";
import type { CoachPlan, PlanProfile } from "../_shared/training.ts";
import { coachPlan, coachProfile } from "../coach-chat/fixtures.ts";
import { handleCoachTip } from "./handler.ts";
import type { TipStore } from "./types.ts";

const TIP = "Brace your core on every press and keep the weights controlled.";
const OTHER_TIP = "Warm up your shoulders first, then add weight slowly.";
const DATE = "2026-11-05";

interface StoreOptions {
  userId?: string | null;
  profile?: PlanProfile | null;
  plan?: CoachPlan | null;
  existing?: string | null;
  raceWinner?: string;
  saveError?: Error;
}

class FakeStore implements TipStore {
  stored: string | null;
  saves: { userId: string; planId: string; date: string; content: string }[] =
    [];
  reads: { planId: string; date: string }[] = [];

  constructor(private readonly options: StoreOptions = {}) {
    this.stored = options.existing ?? null;
  }

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

  activePlan(_userId: string): Promise<CoachPlan | null> {
    return Promise.resolve(
      this.options.plan === undefined ? coachPlan() : this.options.plan,
    );
  }

  existingTip(
    _userId: string,
    planId: string,
    date: string,
  ): Promise<string | null> {
    this.reads.push({ planId, date });
    return Promise.resolve(this.stored);
  }

  saveTip(
    userId: string,
    planId: string,
    date: string,
    content: string,
  ): Promise<void> {
    if (this.options.saveError) return Promise.reject(this.options.saveError);
    this.saves.push({ userId, planId, date, content });
    if (this.options.raceWinner !== undefined) {
      this.stored = this.options.raceWinner;
    } else {
      this.stored = content;
    }
    return Promise.resolve();
  }
}

class FakeModel implements JsonModel {
  requests: JsonModelRequest[] = [];

  constructor(private readonly replies: Array<string | Error>) {}

  generateJson(request: JsonModelRequest): Promise<string> {
    this.requests.push(request);
    const reply = this.replies.shift();
    if (reply === undefined) return Promise.reject(new Error("no reply left"));
    return reply instanceof Error
      ? Promise.reject(reply)
      : Promise.resolve(reply);
  }
}

function post(body: unknown = { date: DATE, weekday: 4 }): Request {
  return new Request("http://localhost/coach-tip", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

function reply(tip: string): string {
  return JSON.stringify({ tip });
}

async function call(
  store: TipStore,
  model: JsonModel,
  body?: unknown,
  expectedLogs = 0,
): Promise<Response> {
  const logs: unknown[][] = [];
  const originalError = console.error;
  const originalWarn = console.warn;
  console.error = (...args: unknown[]) => void logs.push(args);
  console.warn = (...args: unknown[]) => void logs.push(args);
  let response: Response;
  try {
    response = await handleCoachTip(post(body), { store, model });
  } finally {
    console.error = originalError;
    console.warn = originalWarn;
  }
  assertEquals(logs.length, expectedLogs);
  return response;
}

Deno.test("only accepts POST", async () => {
  const response = await handleCoachTip(
    new Request("http://localhost/coach-tip"),
    { store: new FakeStore(), model: new FakeModel([]) },
  );

  assertEquals(response.status, 405);
  assertEquals(await response.json(), { error: "method_not_allowed" });
});

Deno.test("an invalid body returns 400", async () => {
  const model = new FakeModel([]);

  const response = await call(new FakeStore(), model, {
    date: "2026-02-30",
    weekday: 4,
  });

  assertEquals(response.status, 400);
  assertEquals(await response.json(), { error: "invalid_request" });
  assertEquals(model.requests.length, 0);
});

Deno.test("no signed-in user returns 401", async () => {
  const response = await call(
    new FakeStore({ userId: null }),
    new FakeModel([]),
  );

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "unauthorized" });
});

Deno.test("an incomplete profile returns 409 profile_incomplete", async () => {
  const response = await call(
    new FakeStore({ profile: null }),
    new FakeModel([]),
  );

  assertEquals(response.status, 409);
  assertEquals(await response.json(), { error: "profile_incomplete" });
});

Deno.test("no active plan returns 409 no_plan", async () => {
  const model = new FakeModel([]);

  const response = await call(new FakeStore({ plan: null }), model);

  assertEquals(response.status, 409);
  assertEquals(await response.json(), { error: "no_plan" });
  assertEquals(model.requests.length, 0);
});

Deno.test("returns the existing tip without calling the model", async () => {
  const store = new FakeStore({ existing: OTHER_TIP });
  const model = new FakeModel([]);

  const response = await call(store, model);

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { tip: OTHER_TIP });
  assertEquals(model.requests.length, 0);
  assertEquals(store.saves.length, 0);
  assertEquals(store.reads[0], { planId: coachPlan().id, date: DATE });
});

Deno.test("generates, saves and returns a tip", async () => {
  const store = new FakeStore();
  const model = new FakeModel([reply(TIP)]);

  const response = await call(store, model);

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { tip: TIP });
  assertEquals(store.saves, [{
    userId: "user-1",
    planId: coachPlan().id,
    date: DATE,
    content: TIP,
  }]);
  assertEquals(model.requests.length, 1);
  assertEquals(model.requests[0].model, "gemini-3.5-flash-lite");
  assertStringIncludes(model.requests[0].prompt, "Full Body B");
  assertStringIncludes(model.requests[0].systemInstruction, "English");
  assertEquals(model.requests[0].schema.type, "object");
});

Deno.test("the saved tip is trimmed", async () => {
  const store = new FakeStore();

  const response = await call(
    store,
    new FakeModel([reply(`  ${TIP}  `)]),
  );

  assertEquals(await response.json(), { tip: TIP });
  assertEquals(store.saves[0].content, TIP);
});

Deno.test("an invalid answer retries once", async () => {
  const store = new FakeStore();
  const model = new FakeModel([reply("Too short"), reply(TIP)]);

  const response = await call(store, model, undefined, 1);

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { tip: TIP });
  assertEquals(model.requests.length, 2);
  assertStringIncludes(model.requests[1].prompt, "tip:");
  assertEquals(store.saves[0].content, TIP);
});

Deno.test("a reply that is not JSON retries once", async () => {
  const model = new FakeModel(["not json", reply(TIP)]);

  const response = await call(new FakeStore(), model, undefined, 1);

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { tip: TIP });
  assertEquals(model.requests.length, 2);
});

Deno.test("two invalid answers return 502 ai_invalid_output", async () => {
  const store = new FakeStore();
  const model = new FakeModel([reply("Too short"), reply("x".repeat(161))]);

  const response = await call(store, model, undefined, 2);

  assertEquals(response.status, 502);
  assertEquals(await response.json(), { error: "ai_invalid_output" });
  assertEquals(model.requests.length, 2);
  assertEquals(store.saves.length, 0);
});

Deno.test("a model error returns 502 ai_unavailable", async () => {
  const store = new FakeStore();
  const model = new FakeModel([new Error("quota")]);

  const response = await call(store, model, undefined, 1);

  assertEquals(response.status, 502);
  assertEquals(await response.json(), { error: "ai_unavailable" });
  assertEquals(model.requests.length, 1);
  assertEquals(store.saves.length, 0);
});

Deno.test("a lost race reads the saved tip", async () => {
  const store = new FakeStore({ raceWinner: OTHER_TIP });
  const model = new FakeModel([reply(TIP)]);

  const response = await call(store, model);

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { tip: OTHER_TIP });
  assertEquals(store.saves.length, 1);
});

Deno.test("a failed save throws", async () => {
  const store = new FakeStore({ saveError: new Error("db down") });

  await assertRejects(
    () => call(store, new FakeModel([reply(TIP)])),
    Error,
    "db down",
  );
});

Deno.test("a tip that cannot be read after saving throws", async () => {
  const store = new FakeStore();
  store.saveTip = () => Promise.resolve();

  await assertRejects(
    () => call(store, new FakeModel([reply(TIP)])),
    Error,
    "missing after saving",
  );
});
