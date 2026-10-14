import type { PlanOutput } from "./plan_schema.ts";
import type { CatalogExercise, PlanProfile } from "./types.ts";

export const sampleCatalog: CatalogExercise[] = [
  {
    id: "push_up",
    name: "Push-up",
    focus: "upper",
    primaryMuscle: "Chest",
    equipment: [],
  },
  {
    id: "dumbbell_bench_press",
    name: "Dumbbell Bench Press",
    focus: "upper",
    primaryMuscle: "Chest",
    equipment: ["dumbbell", "bench"],
  },
  {
    id: "dumbbell_row",
    name: "One-arm Dumbbell Row",
    focus: "upper",
    primaryMuscle: "Back",
    equipment: ["dumbbell"],
  },
  {
    id: "goblet_squat",
    name: "Goblet Squat",
    focus: "lower",
    primaryMuscle: "Quads",
    equipment: ["dumbbell"],
  },
  {
    id: "reverse_lunge",
    name: "Reverse Lunge",
    focus: "lower",
    primaryMuscle: "Quads",
    equipment: [],
  },
  {
    id: "glute_bridge",
    name: "Glute Bridge",
    focus: "lower",
    primaryMuscle: "Glutes",
    equipment: [],
  },
  {
    id: "plank",
    name: "Plank",
    focus: "core",
    primaryMuscle: "Core",
    equipment: [],
  },
  {
    id: "dead_bug",
    name: "Dead Bug",
    focus: "core",
    primaryMuscle: "Core",
    equipment: [],
  },
  {
    id: "burpee",
    name: "Burpee",
    focus: "full_body",
    primaryMuscle: "Full body",
    equipment: [],
  },
];

export const sampleProfile: PlanProfile = {
  goal: "build_muscle",
  level: "intermediate",
  daysPerWeek: 2,
  equipment: ["dumbbell", "bench"],
  aiModel: "gemini_flash",
};

const sampleDays: PlanOutput["days"] = [
  {
    day_number: 1,
    title: "Upper Body Push",
    focus: "upper",
    estimated_minutes: 45,
    exercises: [
      {
        exercise_id: "dumbbell_bench_press",
        sets: 4,
        reps: "8-10",
        rest_seconds: 90,
      },
      { exercise_id: "dumbbell_row", sets: 3, reps: "10", rest_seconds: 90 },
      { exercise_id: "push_up", sets: 3, reps: "12", rest_seconds: 60 },
    ],
  },
  {
    day_number: 2,
    title: "Lower Body and Core",
    focus: "lower",
    estimated_minutes: 40,
    exercises: [
      { exercise_id: "goblet_squat", sets: 4, reps: "10", rest_seconds: 90 },
      { exercise_id: "reverse_lunge", sets: 3, reps: "12", rest_seconds: 60 },
      { exercise_id: "plank", sets: 3, reps: "30-45s", rest_seconds: 45 },
    ],
  },
  {
    day_number: 3,
    title: "Full Body Burn",
    focus: "full_body",
    estimated_minutes: 35,
    exercises: [
      { exercise_id: "burpee", sets: 3, reps: "10", rest_seconds: 60 },
      { exercise_id: "glute_bridge", sets: 3, reps: "15", rest_seconds: 45 },
      { exercise_id: "dead_bug", sets: 3, reps: "12", rest_seconds: 45 },
    ],
  },
];

export function samplePlanOutput(dayCount = 2): PlanOutput {
  return {
    title: `${dayCount}-Day Strength Split`,
    days: structuredClone(sampleDays.slice(0, dayCount)),
  };
}
