import { AI_MODELS } from "../_shared/ai_models.ts";
import { errorResponse, jsonResponse } from "../_shared/http.ts";
import type { JsonModel, JsonModelRequest } from "../_shared/json_model.ts";
import { toSavePayload } from "./payload.ts";
import {
  type PlanOutput,
  type PlanOutputSchema,
  planOutputSchema,
  toGeminiSchema,
} from "./plan_schema.ts";
import { buildPlanPrompt, buildRetryPrompt, SYSTEM_PROMPT } from "./prompt.ts";
import { parseGeneratePlanRequest } from "./request.ts";
import { weekdaysFor } from "./schedule.ts";
import type { PlanStore } from "./types.ts";
import { parsePlanOutput } from "./validate.ts";

const MAX_ATTEMPTS = 2;

export interface GeneratePlanDeps {
  store: PlanStore;
  model: JsonModel;
}

type GenerationOutcome =
  | { kind: "valid"; plan: PlanOutput }
  | { kind: "invalid" }
  | { kind: "unavailable" };

export async function handleGeneratePlan(
  request: Request,
  deps: GeneratePlanDeps,
): Promise<Response> {
  if (request.method !== "POST") {
    return errorResponse(405, "method_not_allowed");
  }
  const body = await parseGeneratePlanRequest(request);
  if (body === null) return errorResponse(400, "invalid_request");

  const userId = await deps.store.userId();
  if (userId === null) return errorResponse(401, "unauthorized");

  const profile = await deps.store.profile(userId);
  if (profile === null) return errorResponse(409, "profile_incomplete");

  const instruction = body.instruction ?? null;
  const [catalog, activePlan] = await Promise.all([
    deps.store.catalog(profile.equipment),
    instruction === null
      ? Promise.resolve(null)
      : deps.store.activePlan(userId),
  ]);
  const weekdays = weekdaysFor(profile.daysPerWeek);
  const schema = planOutputSchema(
    catalog.map((exercise) => exercise.id),
    profile.daysPerWeek,
  );
  const prompt = buildPlanPrompt({
    profile,
    weekdays,
    catalog,
    activePlan,
    instruction,
  });

  const outcome = await generateValidPlan(deps.model, {
    model: AI_MODELS[profile.aiModel].id,
    systemInstruction: SYSTEM_PROMPT,
    prompt,
    schema: toGeminiSchema(schema),
  }, schema);
  if (outcome.kind === "unavailable") {
    return errorResponse(502, "ai_unavailable");
  }
  if (outcome.kind === "invalid") {
    return errorResponse(502, "ai_invalid_output");
  }

  const payload = toSavePayload(outcome.plan, {
    weekdays,
    aiModel: profile.aiModel,
    instruction,
  });
  try {
    const planId = await deps.store.savePlan(payload);
    return jsonResponse(200, { plan_id: planId });
  } catch (error) {
    console.error("save_generated_plan failed", error);
    return errorResponse(500, "save_failed");
  }
}

async function generateValidPlan(
  model: JsonModel,
  request: JsonModelRequest,
  schema: PlanOutputSchema,
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
    const result = parsePlanOutput(text, schema);
    if (result.ok) return { kind: "valid", plan: result.plan };
    console.warn(`Plan attempt ${attempt} was invalid`, result.errors);
    prompt = buildRetryPrompt(request.prompt, result.errors);
  }
  return { kind: "invalid" };
}
