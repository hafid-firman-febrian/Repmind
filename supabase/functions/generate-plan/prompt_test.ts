import { assert, assertEquals, assertStringIncludes } from "jsr:@std/assert@^1";
import { sampleCatalog, sampleProfile } from "./fixtures.ts";
import { buildPlanPrompt, buildRetryPrompt } from "./prompt.ts";
import type { ActivePlanSummary } from "./types.ts";

const activePlan: ActivePlanSummary = {
  title: "2-Day Strength Split",
  version: 1,
  days: [{
    dayNumber: 1,
    title: "Upper Body Push",
    focus: "upper",
    exercises: [{
      exerciseId: "push_up",
      sets: 3,
      reps: "12",
      restSeconds: 60,
    }],
  }],
};

function prompt(instruction: string | null, plan: ActivePlanSummary | null) {
  return buildPlanPrompt({
    profile: sampleProfile,
    weekdays: [1, 4],
    catalog: sampleCatalog,
    activePlan: plan,
    instruction,
  });
}

Deno.test("describes the person, the schedule and every catalog exercise", () => {
  const text = prompt(null, null);
  assertStringIncludes(text, "Goal: build muscle");
  assertStringIncludes(text, "Equipment: dumbbell, bench");
  assertStringIncludes(text, "Day 1 = Monday");
  assertStringIncludes(text, "Day 2 = Thursday");
  for (const exercise of sampleCatalog) {
    assertStringIncludes(text, `${exercise.id} | ${exercise.name}`);
  }
  assertStringIncludes(text, "plank | Plank | core | Core | bodyweight");
});

Deno.test("a fresh plan has no adjustment section", () => {
  assertEquals(prompt(null, activePlan).includes("## Requested change"), false);
});

Deno.test("an adjustment includes the current plan and the request", () => {
  const text = prompt("More core work", activePlan);
  assertStringIncludes(text, "## Current plan");
  assertStringIncludes(text, "Title: 2-Day Strength Split (version 1)");
  assertStringIncludes(text, "push_up 3x12 rest 60s");
  assertStringIncludes(text, "## Requested change\nMore core work");
});

Deno.test("an adjustment without an active plan says so", () => {
  assertStringIncludes(prompt("More core work", null), "None yet.");
});

Deno.test("the retry prompt lists every problem", () => {
  const text = buildRetryPrompt("base", ["first issue", "second issue"]);
  assert(text.startsWith("base\n"));
  assertStringIncludes(text, "- first issue\n- second issue");
});
