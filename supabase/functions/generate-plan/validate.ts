import type { PlanOutput, PlanOutputSchema } from "./plan_schema.ts";

const MAX_REPORTED_ERRORS = 10;

export type ParsedPlan =
  | { ok: true; plan: PlanOutput }
  | { ok: false; errors: string[] };

export function validatePlan(plan: PlanOutput): string[] {
  const errors: string[] = [];
  plan.days.forEach((day, index) => {
    const expected = index + 1;
    if (day.day_number !== expected) {
      errors.push(
        `Day at position ${expected} has day_number ${day.day_number}; use ${expected}.`,
      );
    }
    const seen = new Set<string>();
    for (const exercise of day.exercises) {
      if (seen.has(exercise.exercise_id)) {
        errors.push(
          `Day ${expected} lists ${exercise.exercise_id} more than once.`,
        );
      }
      seen.add(exercise.exercise_id);
    }
  });
  return errors;
}

export function parsePlanOutput(
  text: string,
  schema: PlanOutputSchema,
): ParsedPlan {
  let json: unknown;
  try {
    json = JSON.parse(text);
  } catch {
    return {
      ok: false,
      errors: [
        "The response was not valid JSON. Answer with the JSON object only.",
      ],
    };
  }
  const parsed = schema.safeParse(json);
  if (!parsed.success) {
    return {
      ok: false,
      errors: parsed.error.issues.slice(0, MAX_REPORTED_ERRORS).map((issue) =>
        `${issue.path.join(".") || "response"}: ${issue.message}`
      ),
    };
  }
  const errors = validatePlan(parsed.data);
  return errors.length === 0
    ? { ok: true, plan: parsed.data }
    : { ok: false, errors: errors.slice(0, MAX_REPORTED_ERRORS) };
}
