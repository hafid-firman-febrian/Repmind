import type { SupabaseClient } from "jsr:@supabase/supabase-js@2.117.3";
import { isAiModelKey } from "./ai_models.ts";
import type {
  CatalogExercise,
  CoachPlan,
  PlanProfile,
  WorkoutFocus,
} from "./training.ts";

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

interface CoachPlanExerciseRow {
  position: number;
  exercise_id: string;
  sets: number;
  reps: string;
  rest_seconds: number;
  exercises: { name: string };
}

interface CoachPlanDayRow {
  day_number: number;
  weekday: number;
  title: string;
  plan_exercises: CoachPlanExerciseRow[];
}

interface CoachPlanRow {
  id: string;
  title: string;
  version: number;
  plan_days: CoachPlanDayRow[];
}

const COACH_PLAN_QUERY =
  "id, title, version, plan_days(day_number, weekday, title, plan_exercises(position, exercise_id, sets, reps, rest_seconds, exercises(name)))";

export async function readUserId(
  client: SupabaseClient,
  accessToken: string | null,
): Promise<string | null> {
  if (accessToken === null) return null;
  const { data, error } = await client.auth.getUser(accessToken);
  if (error || !data.user) return null;
  return data.user.id;
}

export async function readProfile(
  client: SupabaseClient,
  userId: string,
): Promise<PlanProfile | null> {
  const { data, error } = await client
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

export async function readCatalog(
  client: SupabaseClient,
  equipment: string[],
): Promise<CatalogExercise[]> {
  const { data, error } = await client
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

export async function readActivePlan(
  client: SupabaseClient,
  userId: string,
): Promise<CoachPlan | null> {
  const { data, error } = await client
    .from("workout_plans")
    .select(COACH_PLAN_QUERY)
    .eq("user_id", userId)
    .is("archived_at", null)
    .maybeSingle();
  if (error) throw error;
  const row = data as CoachPlanRow | null;
  if (row === null) return null;
  return {
    id: row.id,
    title: row.title,
    version: row.version,
    days: [...row.plan_days]
      .sort((a, b) => a.day_number - b.day_number)
      .map((day) => ({
        dayNumber: day.day_number,
        weekday: day.weekday,
        title: day.title,
        exercises: [...day.plan_exercises]
          .sort((a, b) => a.position - b.position)
          .map((exercise) => ({
            exerciseId: exercise.exercise_id,
            name: exercise.exercises.name,
            sets: exercise.sets,
            reps: exercise.reps,
            restSeconds: exercise.rest_seconds,
          })),
      })),
  };
}
