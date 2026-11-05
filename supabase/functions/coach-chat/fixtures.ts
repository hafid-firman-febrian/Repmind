import type {
  CatalogExercise,
  CoachPlan,
  PlanProfile,
} from "../_shared/training.ts";
import type { PlanProposal } from "./types.ts";

export const PLAN_ID = "7c1f0c52-6f0e-4d7e-9a53-2f4a1f0b9c01";

export const coachProfile: PlanProfile = {
  goal: "build_muscle",
  level: "intermediate",
  daysPerWeek: 2,
  equipment: ["dumbbell", "bench"],
  aiModel: "gemini_flash_lite",
};

export const coachCatalog: CatalogExercise[] = [
  {
    id: "goblet_squat",
    name: "Goblet Squat",
    focus: "lower",
    primaryMuscle: "Quads",
    equipment: ["dumbbell"],
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
    id: "dumbbell_shoulder_press",
    name: "Dumbbell Shoulder Press",
    focus: "upper",
    primaryMuscle: "Shoulders",
    equipment: ["dumbbell"],
  },
  {
    id: "dumbbell_lateral_raise",
    name: "Dumbbell Lateral Raise",
    focus: "upper",
    primaryMuscle: "Shoulders",
    equipment: ["dumbbell"],
  },
  {
    id: "romanian_deadlift",
    name: "Dumbbell Romanian Deadlift",
    focus: "lower",
    primaryMuscle: "Hamstrings",
    equipment: ["dumbbell"],
  },
  {
    id: "plank",
    name: "Plank",
    focus: "core",
    primaryMuscle: "Core",
    equipment: [],
  },
  {
    id: "push_up",
    name: "Push-up",
    focus: "upper",
    primaryMuscle: "Chest",
    equipment: [],
  },
];

export function coachPlan(): CoachPlan {
  return {
    id: PLAN_ID,
    title: "2-Day Strength Split",
    version: 1,
    days: [
      {
        dayNumber: 1,
        weekday: 1,
        title: "Full Body A",
        exercises: [
          {
            exerciseId: "goblet_squat",
            name: "Goblet Squat",
            sets: 4,
            reps: "10",
            restSeconds: 90,
          },
          {
            exerciseId: "dumbbell_bench_press",
            name: "Dumbbell Bench Press",
            sets: 4,
            reps: "8-10",
            restSeconds: 90,
          },
          {
            exerciseId: "dumbbell_row",
            name: "One-arm Dumbbell Row",
            sets: 3,
            reps: "10",
            restSeconds: 75,
          },
        ],
      },
      {
        dayNumber: 2,
        weekday: 4,
        title: "Full Body B",
        exercises: [
          {
            exerciseId: "dumbbell_shoulder_press",
            name: "Dumbbell Shoulder Press",
            sets: 3,
            reps: "10",
            restSeconds: 90,
          },
          {
            exerciseId: "romanian_deadlift",
            name: "Dumbbell Romanian Deadlift",
            sets: 3,
            reps: "10",
            restSeconds: 90,
          },
          {
            exerciseId: "plank",
            name: "Plank",
            sets: 3,
            reps: "30-45s",
            restSeconds: 45,
          },
        ],
      },
    ],
  };
}

export function pendingProposal(): PlanProposal {
  return {
    based_on_plan_id: PLAN_ID,
    ai_model: "gemini_flash_lite",
    day_number: 2,
    summary: "Swap Dumbbell Shoulder Press for Dumbbell Lateral Raise",
    changes: [{
      from_exercise_id: "dumbbell_shoulder_press",
      to_exercise_id: "dumbbell_lateral_raise",
      to_exercise_name: "Dumbbell Lateral Raise",
      sets: 3,
      reps: "12",
      rest_seconds: 60,
    }],
  };
}
