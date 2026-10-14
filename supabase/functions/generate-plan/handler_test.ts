import { assertEquals, assertStringIncludes } from "jsr:@std/assert@^1";
import type { JsonModel, JsonModelRequest } from "../_shared/json_model.ts";
import { sampleCatalog, samplePlanOutput, sampleProfile } from "./fixtures.ts";
import { handleGeneratePlan } from "./handler.ts";
import type {
  ActivePlanSummary,
  CatalogExercise,
  PlanProfile,
  PlanStore,
  SavePlanPayload,
} from "./types.ts";

interface StoreOptions {
  userId?: string | null;
  profile?: PlanProfile | null;
  activePlan?: ActivePlanSummary | null;
  saveError?: Error;
}

class FakeStore implements PlanStore {
  saved: SavePlanPayload[] = [];
  activePlanReads = 0;

  constructor(private readonly options: StoreOptions = {}) {}

  userId(): Promise<string | null> {
    return Promise.resolve(
      this.options.userId === undefined ? "user-1" : this.options.userId,
    );
  }

  profile(_userId: string): Promise<PlanProfile | null> {
    return Promise.resolve(
      this.options.profile === undefined ? sampleProfile : this.options.profile,
    );
  }

  catalog(_equipment: string[]): Promise<CatalogExercise[]> {
    return Promise.resolve(sampleCatalog);
  }

  activePlan(_userId: string): Promise<ActivePlanSummary | null> {
    this.activePlanReads++;
    return Promise.resolve(this.options.activePlan ?? null);
  }

  savePlan(payload: SavePlanPayload): Promise<string> {
    if (this.options.saveError) return Promise.reject(this.options.saveError);
    this.saved.push(payload);
    return Promise.resolve("plan-1");
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

function post(body: unknown = {}): Request {
  return new Request("http://localhost/generate-plan", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

const validReply = JSON.stringify(samplePlanOutput());

const fourDayPlan: ActivePlanSummary = {
  title: "4-Day Upper / Lower",
  version: 2,
  days: [1, 2, 3, 4].map((dayNumber) => ({
    dayNumber,
    title: `Day ${dayNumber}`,
    focus: "upper" as const,
    exercises: [{
      exerciseId: "push_up",
      sets: 3,
      reps: "12",
      restSeconds: 60,
    }],
  })),
};

Deno.test("saves a valid plan and returns its id", async () => {
  const store = new FakeStore();
  const model = new FakeModel([validReply]);

  const response = await handleGeneratePlan(post(), { store, model });

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { plan_id: "plan-1" });
  assertEquals(model.requests[0].model, "gemini-3.8-flash");
  assertEquals(store.activePlanReads, 0);
  const [payload] = store.saved;
  assertEquals(payload.instruction, null);
  assertEquals(payload.ai_model, "gemini_flash");
  assertEquals(payload.days.map((day) => day.weekday), [1, 4]);
  assertEquals(payload.days[0].exercises.map((e) => e.position), [1, 2, 3]);
});

Deno.test("uses the model chosen in the profile", async () => {
  const store = new FakeStore({
    profile: { ...sampleProfile, aiModel: "gemini_pro" },
  });
  const model = new FakeModel([validReply]);

  await handleGeneratePlan(post(), { store, model });

  assertEquals(model.requests[0].model, "gemini-3.1-pro-preview");
  assertEquals(store.saved[0].ai_model, "gemini_pro");
});

Deno.test("retries once with the problems of the first answer", async () => {
  const store = new FakeStore();
  const model = new FakeModel(["not json", validReply]);

  const response = await handleGeneratePlan(post(), { store, model });

  assertEquals(response.status, 200);
  assertEquals(model.requests.length, 2);
  assertStringIncludes(
    model.requests[1].prompt,
    "## Your previous answer had these problems",
  );
  assertStringIncludes(model.requests[1].prompt, "not valid JSON");
});

Deno.test("gives up after two invalid answers without saving", async () => {
  const store = new FakeStore();
  const fenced = "```json\n" + validReply + "\n```";
  const model = new FakeModel(["", fenced]);

  const response = await handleGeneratePlan(post(), { store, model });

  assertEquals(response.status, 502);
  assertEquals(await response.json(), { error: "ai_invalid_output" });
  assertEquals(model.requests.length, 2);
  assertEquals(store.saved.length, 0);
});

Deno.test("reports ai_unavailable when Gemini fails, without retrying", async () => {
  const store = new FakeStore();
  const model = new FakeModel([new Error("quota exceeded")]);

  const response = await handleGeneratePlan(post(), { store, model });

  assertEquals(response.status, 502);
  assertEquals(await response.json(), { error: "ai_unavailable" });
  assertEquals(model.requests.length, 1);
  assertEquals(store.saved.length, 0);
});

Deno.test("an adjustment sends the active plan and stores the trimmed instruction", async () => {
  const activePlan: ActivePlanSummary = {
    ...fourDayPlan,
    title: "Current Split",
  };
  const store = new FakeStore({ activePlan });
  const model = new FakeModel([validReply]);

  const response = await handleGeneratePlan(
    post({ instruction: "  More core work " }),
    { store, model },
  );

  assertEquals(response.status, 200);
  assertEquals(store.activePlanReads, 1);
  assertStringIncludes(model.requests[0].prompt, "Title: Current Split");
  assertStringIncludes(
    model.requests[0].prompt,
    "## Requested change\nMore core work",
  );
  assertEquals(store.saved[0].instruction, "More core work");
});

Deno.test("follows the profile when days per week changed since the active plan", async () => {
  const store = new FakeStore({
    profile: { ...sampleProfile, daysPerWeek: 3 },
    activePlan: fourDayPlan,
  });
  const model = new FakeModel([JSON.stringify(samplePlanOutput(3))]);

  const response = await handleGeneratePlan(
    post({ instruction: "Three days now" }),
    { store, model },
  );

  assertEquals(response.status, 200);
  const schema = model.requests[0].schema as {
    properties: { days: { minItems: number; maxItems: number } };
  };
  assertEquals(schema.properties.days.minItems, 3);
  assertEquals(schema.properties.days.maxItems, 3);
  assertEquals(store.saved[0].days.map((day) => day.weekday), [1, 3, 5]);
});

Deno.test("rejects an invalid body", async () => {
  const response = await handleGeneratePlan(post({ instruction: "x" }), {
    store: new FakeStore(),
    model: new FakeModel([]),
  });

  assertEquals(response.status, 400);
  assertEquals(await response.json(), { error: "invalid_request" });
});

Deno.test("requires a signed-in user", async () => {
  const response = await handleGeneratePlan(post(), {
    store: new FakeStore({ userId: null }),
    model: new FakeModel([]),
  });

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "unauthorized" });
});

Deno.test("requires a finished onboarding", async () => {
  const response = await handleGeneratePlan(post(), {
    store: new FakeStore({ profile: null }),
    model: new FakeModel([]),
  });

  assertEquals(response.status, 409);
  assertEquals(await response.json(), { error: "profile_incomplete" });
});

Deno.test("only accepts POST", async () => {
  const response = await handleGeneratePlan(
    new Request("http://localhost/generate-plan"),
    { store: new FakeStore(), model: new FakeModel([]) },
  );

  assertEquals(response.status, 405);
  assertEquals(await response.json(), { error: "method_not_allowed" });
});

Deno.test("reports a failed save", async () => {
  const response = await handleGeneratePlan(post(), {
    store: new FakeStore({ saveError: new Error("db down") }),
    model: new FakeModel([validReply]),
  });

  assertEquals(response.status, 500);
  assertEquals(await response.json(), { error: "save_failed" });
});
