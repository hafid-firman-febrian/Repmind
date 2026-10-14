import { z } from "npm:zod@4.6.7";
import { WORKOUT_FOCUSES } from "./types.ts";

export const REPS_PATTERN = /^[0-9]{1,3}(-[0-9]{1,3})?s?$/;

const GEMINI_SCHEMA_KEYWORDS = new Set([
  "type",
  "properties",
  "required",
  "items",
  "enum",
  "minimum",
  "maximum",
  "minItems",
  "maxItems",
  "description",
  "additionalProperties",
]);

export function planOutputSchema(exerciseIds: string[], daysPerWeek: number) {
  const exercise = z.object({
    exercise_id: z.enum(exerciseIds as [string, ...string[]]),
    sets: z.number().int().min(1).max(8),
    reps: z.string().regex(REPS_PATTERN).describe(
      "Reps per set: a number like '10', a range like '8-12', or seconds like '30s' or '30-45s'.",
    ),
    rest_seconds: z.number().int().min(15).max(300),
  });
  const day = z.object({
    day_number: z.number().int().min(1).max(daysPerWeek),
    title: z.string().min(3).max(40),
    focus: z.enum(WORKOUT_FOCUSES),
    estimated_minutes: z.number().int().min(15).max(120),
    exercises: z.array(exercise).min(3).max(8),
  });
  return z.object({
    title: z.string().min(3).max(60),
    days: z.array(day).length(daysPerWeek),
  });
}

export type PlanOutputSchema = ReturnType<typeof planOutputSchema>;

export type PlanOutput = z.infer<PlanOutputSchema>;

export function toGeminiSchema(
  schema: PlanOutputSchema,
): Record<string, unknown> {
  return keepSupportedKeywords(z.toJSONSchema(schema)) as Record<
    string,
    unknown
  >;
}

function keepSupportedKeywords(node: unknown): unknown {
  if (Array.isArray(node)) return node.map(keepSupportedKeywords);
  if (node === null || typeof node !== "object") return node;
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(node)) {
    if (!GEMINI_SCHEMA_KEYWORDS.has(key)) continue;
    result[key] = key === "properties"
      ? Object.fromEntries(
        Object.entries(value as Record<string, unknown>).map((
          [name, property],
        ) => [
          name,
          keepSupportedKeywords(
            name === "exercise_id" ? withoutEnum(property) : property,
          ),
        ]),
      )
      : keepSupportedKeywords(value);
  }
  return result;
}

function withoutEnum(property: unknown): unknown {
  const { enum: _exerciseIds, ...rest } = property as Record<string, unknown>;
  return rest;
}
