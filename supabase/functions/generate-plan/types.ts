import type { AiModelKey } from "../_shared/ai_models.ts";
import type {
  CatalogExercise,
  PlanProfile,
  WorkoutFocus,
} from "../_shared/training.ts";

export {
  type CatalogExercise,
  type PlanProfile,
  WORKOUT_FOCUSES,
  type WorkoutFocus,
} from "../_shared/training.ts";

export interface ActivePlanExercise {
  exerciseId: string;
  sets: number;
  reps: string;
  restSeconds: number;
}

export interface ActivePlanDay {
  dayNumber: number;
  title: string;
  focus: WorkoutFocus;
  exercises: ActivePlanExercise[];
}

export interface ActivePlanSummary {
  title: string;
  version: number;
  days: ActivePlanDay[];
}

export interface SavePlanExercise {
  position: number;
  exercise_id: string;
  sets: number;
  reps: string;
  rest_seconds: number;
}

export interface SavePlanDay {
  day_number: number;
  weekday: number;
  title: string;
  focus: WorkoutFocus;
  estimated_minutes: number;
  exercises: SavePlanExercise[];
}

export interface SavePlanPayload {
  title: string;
  ai_model: AiModelKey;
  instruction: string | null;
  days: SavePlanDay[];
}

export interface PlanStore {
  userId(): Promise<string | null>;
  profile(userId: string): Promise<PlanProfile | null>;
  catalog(equipment: string[]): Promise<CatalogExercise[]>;
  activePlan(userId: string): Promise<ActivePlanSummary | null>;
  savePlan(payload: SavePlanPayload): Promise<string>;
}
