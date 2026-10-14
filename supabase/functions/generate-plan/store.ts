import type { SupabaseClient } from "jsr:@supabase/supabase-js@2.117.3";
import { isAiModelKey } from "../_shared/ai_models.ts";
import type {
  ActivePlanSummary,
  CatalogExercise,
  PlanProfile,
  PlanStore,
  SavePlanPayload,
  WorkoutFocus,
} from "./types.ts";

interface ProfileRow {
  goal: string | null;
  level: string | null;
  days_per_week: number | null;
  equipment: string[];
  ai_model: string;
  onboarded_at: string | null;
}

interface ExerciseRow {
  id: string;
  name: string;
  focus: WorkoutFocus;
  primary_muscle: string;
  equipment: string[];
}

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

  async userId(): Promise<string | null> {
    if (this.accessToken === null) return null;
    const { data, error } = await this.client.auth.getUser(this.accessToken);
    if (error || !data.user) return null;
    return data.user.id;
  }

  async profile(userId: string): Promise<PlanProfile | null> {
    const { data, error } = await this.client
      .from("profiles")
      .select("goal, level, days_per_week, equipment, ai_model, onboarded_at")
      .eq("id", userId)
      .maybeSingle();
    if (error) throw error;
    const row = data as ProfileRow | null;
    if (
      row === null || row.onboarded_at === null || row.goal === null ||
      row.level === null || row.days_per_week === null ||
      !isAiModelKey(row.ai_model)
    ) {
      return null;
    }
    return {
      goal: row.goal,
      level: row.level,
      daysPerWeek: row.days_per_week,
      equipment: row.equipment,
      aiModel: row.ai_model,
    };
  }

  async catalog(equipment: string[]): Promise<CatalogExercise[]> {
    const { data, error } = await this.client
      .from("exercises")
      .select("id, name, focus, primary_muscle, equipment")
      .containedBy("equipment", equipment)
      .order("id");
    if (error) throw error;
    return (data as ExerciseRow[]).map((row) => ({
      id: row.id,
      name: row.name,
      focus: row.focus,
      primaryMuscle: row.primary_muscle,
      equipment: row.equipment,
    }));
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
