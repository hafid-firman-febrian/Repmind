import type { AiModelKey } from "../_shared/ai_models.ts";
import type { PlanOutput } from "./plan_schema.ts";
import type { SavePlanPayload } from "./types.ts";

export interface PayloadContext {
  weekdays: number[];
  aiModel: AiModelKey;
  instruction: string | null;
}

export function toSavePayload(
  plan: PlanOutput,
  context: PayloadContext,
): SavePlanPayload {
  return {
    title: plan.title,
    ai_model: context.aiModel,
    instruction: context.instruction,
    days: plan.days.map((day) => ({
      day_number: day.day_number,
      weekday: context.weekdays[day.day_number - 1],
      title: day.title,
      focus: day.focus,
      estimated_minutes: day.estimated_minutes,
      exercises: day.exercises.map((exercise, index) => ({
        position: index + 1,
        exercise_id: exercise.exercise_id,
        sets: exercise.sets,
        reps: exercise.reps,
        rest_seconds: exercise.rest_seconds,
      })),
    })),
  };
}
