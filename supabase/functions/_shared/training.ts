import type { AiModelKey } from "./ai_models.ts";

export const WORKOUT_FOCUSES = ["upper", "lower", "core", "full_body"] as const;

export type WorkoutFocus = (typeof WORKOUT_FOCUSES)[number];

export const REPS_PATTERN = /^[0-9]{1,3}(-[0-9]{1,3})?s?$/;

export interface PlanProfile {
  goal: string;
  level: string;
  daysPerWeek: number;
  equipment: string[];
  aiModel: AiModelKey;
}

export interface CatalogExercise {
  id: string;
  name: string;
  focus: WorkoutFocus;
  primaryMuscle: string;
  equipment: string[];
}

export interface CoachPlanExercise {
  exerciseId: string;
  name: string;
  sets: number;
  reps: string;
  restSeconds: number;
}

export interface CoachPlanDay {
  dayNumber: number;
  weekday: number;
  title: string;
  exercises: CoachPlanExercise[];
}

export interface CoachPlan {
  id: string;
  title: string;
  version: number;
  days: CoachPlanDay[];
}

const WEEKDAY_NAMES = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

export function weekdayName(weekday: number): string {
  return WEEKDAY_NAMES[weekday - 1];
}

export function humanize(value: string): string {
  return value.replaceAll("_", " ");
}
