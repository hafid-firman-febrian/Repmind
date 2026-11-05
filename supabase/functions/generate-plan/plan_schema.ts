import { z } from "npm:zod@4.6.7";
import { REPS_PATTERN, WORKOUT_FOCUSES } from "../_shared/training.ts";

export { toGeminiSchema } from "../_shared/gemini_schema.ts";
export { REPS_PATTERN };

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
