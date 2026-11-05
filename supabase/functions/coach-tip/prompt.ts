import type {
  CoachPlan,
  CoachPlanDay,
  PlanProfile,
} from "../_shared/training.ts";
import { humanize, weekdayName } from "../_shared/training.ts";

export const TIP_SYSTEM_PROMPT = [
  "You are Repmind's coach. You write one short tip for the person's Home screen.",
  "Write in English, in one or two sentences of 20 to 160 characters, addressed to the person as 'you'.",
  "On a workout day, give a practical tip for today's workout. On a rest day, talk about recovery or the next workout.",
  "Use only the plan and profile below. Never mention past sessions, progress, streaks or results, because you have not seen any.",
  "Never give medical advice or diagnose anything, and do not mention pain, injuries or health conditions.",
  "Do not use emojis, markdown or quotation marks.",
  'Answer with a JSON object of the form {"tip": "..."} and nothing else.',
].join("\n");

export interface TipPromptInput {
  profile: PlanProfile;
  weekday: number;
  plan: CoachPlan;
}

export function buildTipPrompt(input: TipPromptInput): string {
  const { profile, weekday, plan } = input;
  const equipment = profile.equipment.length > 0
    ? profile.equipment.map(humanize).join(", ")
    : "bodyweight only";
  return [
    "## Person",
    `Goal: ${humanize(profile.goal)}`,
    `Level: ${humanize(profile.level)}`,
    `Training days per week: ${profile.daysPerWeek}`,
    `Equipment: ${equipment}`,
    "",
    "## Plan",
    `Version ${plan.version}: ${plan.title}`,
    ...describeToday(plan, weekday),
  ].join("\n");
}

export function buildTipRetryPrompt(prompt: string, errors: string[]): string {
  return [
    prompt,
    "",
    "## Your previous answer had these problems",
    ...errors.map((error) => `- ${error}`),
    'Answer again with a JSON object of the form {"tip": "..."} that fixes them.',
  ].join("\n");
}

function describeToday(plan: CoachPlan, weekday: number): string[] {
  const name = weekdayName(weekday);
  const today = plan.days.find((day) => day.weekday === weekday);
  if (today !== undefined) {
    return [
      `Today is ${name}: Day ${today.dayNumber} - ${today.title}.`,
      "Today's exercises:",
      ...exerciseLines(today),
    ];
  }
  const next = nextWorkout(plan.days, weekday);
  return [
    `Today is ${name}: rest day.`,
    `The next workout is Day ${next.dayNumber} - ${next.title} on ${
      weekdayName(next.weekday)
    }.`,
    "Next workout's exercises:",
    ...exerciseLines(next),
  ];
}

function exerciseLines(day: CoachPlanDay): string[] {
  return day.exercises.map((exercise) =>
    `- ${exercise.name} ${exercise.sets}x${exercise.reps}`
  );
}

function nextWorkout(days: CoachPlanDay[], weekday: number): CoachPlanDay {
  const distance = (day: CoachPlanDay) => (day.weekday - weekday + 7) % 7;
  return days.reduce((best, day) =>
    distance(day) < distance(best) ? day : best
  );
}
