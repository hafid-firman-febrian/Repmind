import { weekdayName } from "./schedule.ts";
import type {
  ActivePlanSummary,
  CatalogExercise,
  PlanProfile,
} from "./types.ts";

export const SYSTEM_PROMPT = [
  "You are an expert strength and conditioning coach.",
  "You design a weekly training plan for one person.",
  "Only use exercise_id values from the catalog you are given. Never invent exercises.",
  "Match volume, sets, reps and rest to the person's goal and level.",
  "Balance muscle groups across the week and avoid training the same muscle group on two consecutive calendar days.",
  "Give the plan a short title of at most 40 characters, such as '4-Day Upper / Lower', and never put a version number in it.",
  "Give every day a short, specific title of at most 30 characters, such as 'Upper Body Push'.",
  "Answer with JSON that matches the response schema exactly.",
].join("\n");

export interface PlanPromptInput {
  profile: PlanProfile;
  weekdays: number[];
  catalog: CatalogExercise[];
  activePlan: ActivePlanSummary | null;
  instruction: string | null;
}

export function buildPlanPrompt(input: PlanPromptInput): string {
  const { profile } = input;
  const equipment = profile.equipment.length > 0
    ? profile.equipment.map(humanize).join(", ")
    : "bodyweight only";
  const lines = [
    "## Person",
    `Goal: ${humanize(profile.goal)}`,
    `Level: ${humanize(profile.level)}`,
    `Training days per week: ${profile.daysPerWeek}`,
    `Equipment: ${equipment}`,
    "",
    "## Schedule",
    ...input.weekdays.map((weekday, index) =>
      `Day ${index + 1} = ${weekdayName(weekday)}`
    ),
    "",
    "## Exercise catalog (id | name | focus | primary muscle | equipment)",
    ...input.catalog.map(catalogLine),
  ];
  if (input.instruction !== null) {
    lines.push(
      "",
      "## Current plan",
      ...describePlan(input.activePlan),
      "",
      "## Requested change",
      input.instruction,
      "The requested change takes priority over the person's profile and the current plan.",
      'If the person says they have less equipment or none (in any language), use only exercises that need none of the missing equipment. Exercises listed with equipment "bodyweight" need none. If they have no equipment, every exercise must be listed with equipment "bodyweight".',
      "Keep everything the person did not ask to change.",
    );
  }
  return lines.join("\n");
}

export function buildRetryPrompt(prompt: string, errors: string[]): string {
  return [
    prompt,
    "",
    "## Your previous answer had these problems",
    ...errors.map((error) => `- ${error}`),
    "Fix every problem and answer again with the full plan.",
  ].join("\n");
}

function humanize(value: string): string {
  return value.replaceAll("_", " ");
}

function catalogLine(exercise: CatalogExercise): string {
  const equipment = exercise.equipment.length > 0
    ? exercise.equipment.map(humanize).join(", ")
    : "bodyweight";
  return `${exercise.id} | ${exercise.name} | ${exercise.focus} | ${exercise.primaryMuscle} | ${equipment}`;
}

function describePlan(plan: ActivePlanSummary | null): string[] {
  if (plan === null) return ["None yet."];
  return [
    `Version: ${plan.version}`,
    `Title: ${plan.title}`,
    ...plan.days.map((day) => {
      const exercises = day.exercises
        .map((exercise) =>
          `${exercise.exerciseId} ${exercise.sets}x${exercise.reps} rest ${exercise.restSeconds}s`
        )
        .join("; ");
      return `Day ${day.dayNumber} - ${day.title} [${day.focus}]: ${exercises}`;
    }),
  ];
}
