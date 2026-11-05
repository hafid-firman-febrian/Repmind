import type { SupabaseClient } from "jsr:@supabase/supabase-js@2.117.3";
import {
  readCatalog,
  readProfile,
  readUserId,
} from "../_shared/training_store.ts";
import type {
  ActivePlanSummary,
  CatalogExercise,
  PlanProfile,
  PlanStore,
  SavePlanPayload,
  WorkoutFocus,
} from "./types.ts";

interface PlanExerciseRow {
  position: number;
  exercise_id: string;
  sets: number;
  reps: string;
  rest_seconds: number;
}

interface PlanDayRow {
  day_number: number;
  title: string;
  focus: WorkoutFocus;
  plan_exercises: PlanExerciseRow[];
}

interface PlanRow {
  title: string;
  version: number;
  plan_days: PlanDayRow[];
}

const ACTIVE_PLAN_QUERY =
  "title, version, plan_days(day_number, title, focus, plan_exercises(position, exercise_id, sets, reps, rest_seconds))";

export class SupabasePlanStore implements PlanStore {
  constructor(
    private readonly client: SupabaseClient,
    private readonly accessToken: string | null,
  ) {}

  userId(): Promise<string | null> {
    return readUserId(this.client, this.accessToken);
  }

  profile(userId: string): Promise<PlanProfile | null> {
    return readProfile(this.client, userId);
  }

  catalog(equipment: string[]): Promise<CatalogExercise[]> {
    return readCatalog(this.client, equipment);
  }

  async activePlan(userId: string): Promise<ActivePlanSummary | null> {
    const { data, error } = await this.client
      .from("workout_plans")
      .select(ACTIVE_PLAN_QUERY)
      .eq("user_id", userId)
      .is("archived_at", null)
      .maybeSingle();
    if (error) throw error;
    const row = data as PlanRow | null;
    if (row === null) return null;
    return {
      title: row.title,
      version: row.version,
      days: [...row.plan_days]
        .sort((a, b) => a.day_number - b.day_number)
        .map((day) => ({
          dayNumber: day.day_number,
          title: day.title,
          focus: day.focus,
          exercises: [...day.plan_exercises]
            .sort((a, b) => a.position - b.position)
            .map((exercise) => ({
              exerciseId: exercise.exercise_id,
              sets: exercise.sets,
              reps: exercise.reps,
              restSeconds: exercise.rest_seconds,
            })),
        })),
    };
  }

  async savePlan(payload: SavePlanPayload): Promise<string> {
    const { data, error } = await this.client.rpc("save_generated_plan", {
      p_plan: payload,
    });
    if (error) throw error;
    return data as string;
  }
}
