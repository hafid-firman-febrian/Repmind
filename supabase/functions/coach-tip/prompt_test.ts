import { assert, assertStringIncludes } from "jsr:@std/assert@^1";
import { coachPlan, coachProfile } from "../coach-chat/fixtures.ts";
import {
  buildTipPrompt,
  buildTipRetryPrompt,
  TIP_SYSTEM_PROMPT,
} from "./prompt.ts";

Deno.test("a workout day names the day and its exercises", () => {
  const prompt = buildTipPrompt({
    profile: coachProfile,
    weekday: 4,
    plan: coachPlan(),
  });

  assertStringIncludes(prompt, "Today is Thursday: Day 2 - Full Body B.");
  assertStringIncludes(prompt, "Dumbbell Shoulder Press 3x10");
  assertStringIncludes(prompt, "Plank 3x30-45s");
  assert(!prompt.includes("rest day"));
  assert(!prompt.includes("Goblet Squat"));
});

Deno.test("a rest day names the next workout", () => {
  const prompt = buildTipPrompt({
    profile: coachProfile,
    weekday: 2,
    plan: coachPlan(),
  });

  assertStringIncludes(prompt, "Today is Tuesday: rest day.");
  assertStringIncludes(
    prompt,
    "The next workout is Day 2 - Full Body B on Thursday.",
  );
  assertStringIncludes(prompt, "Dumbbell Romanian Deadlift 3x10");
});

Deno.test("the next workout after the last one wraps to the next week", () => {
  const prompt = buildTipPrompt({
    profile: coachProfile,
    weekday: 6,
    plan: coachPlan(),
  });

  assertStringIncludes(
    prompt,
    "The next workout is Day 1 - Full Body A on Monday.",
  );
});

Deno.test("the prompt carries the profile", () => {
  const prompt = buildTipPrompt({
    profile: coachProfile,
    weekday: 4,
    plan: coachPlan(),
  });

  assertStringIncludes(prompt, "Goal: build muscle");
  assertStringIncludes(prompt, "Equipment: dumbbell, bench");
});

Deno.test("the system prompt fixes the language and the limits", () => {
  assertStringIncludes(TIP_SYSTEM_PROMPT, "Write in English");
  assertStringIncludes(TIP_SYSTEM_PROMPT, "Never give medical advice");
  assertStringIncludes(TIP_SYSTEM_PROMPT, "Never mention past sessions");
});

Deno.test("the retry prompt lists the problems", () => {
  const prompt = buildTipRetryPrompt("base", ["tip: too short"]);

  assertStringIncludes(prompt, "base");
  assertStringIncludes(prompt, "- tip: too short");
});
