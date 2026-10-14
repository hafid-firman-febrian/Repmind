import { assert, assertEquals, assertStringIncludes } from "jsr:@std/assert@^1";
import { sampleCatalog, sampleProfile } from "./fixtures.ts";
import { buildPlanPrompt, buildRetryPrompt, SYSTEM_PROMPT } from "./prompt.ts";
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
  assertStringIncludes(text, "Version: 1\nTitle: 2-Day Strength Split\n");
  assertEquals(text.includes("(version"), false);
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

Deno.test("the system prompt states the plan and day title limits", () => {
  assertStringIncludes(SYSTEM_PROMPT, "at most 40 characters");
  assertStringIncludes(SYSTEM_PROMPT, "'4-Day Upper / Lower'");
  assertStringIncludes(SYSTEM_PROMPT, "at most 30 characters");
});

Deno.test("the system prompt forbids a version number in the plan title", () => {
  assertStringIncludes(SYSTEM_PROMPT, "never put a version number in it");
});

const PRIORITY_LINE =
  "The requested change takes priority over the person's profile and the current plan.";
const EQUIPMENT_LINE =
  'If the person says they have less equipment or none (in any language), use only exercises that need none of the missing equipment. Exercises listed with equipment "bodyweight" need none. If they have no equipment, every exercise must be listed with equipment "bodyweight".';
const KEEP_LINE = "Keep everything the person did not ask to change.";

Deno.test("an adjustment lets the request override the profile and equipment", () => {
  const text = prompt("Aku tidak punya alat", activePlan);
  const instructionAt = text.indexOf("Aku tidak punya alat");
  const priorityAt = text.indexOf(PRIORITY_LINE);
  const equipmentAt = text.indexOf(EQUIPMENT_LINE);
  const keepAt = text.indexOf(KEEP_LINE);
  assert(instructionAt >= 0);
  assert(priorityAt > instructionAt);
  assert(equipmentAt > priorityAt);
  assert(keepAt > equipmentAt);
  assert(text.endsWith(KEEP_LINE));
});

Deno.test("a fresh plan does not mention the override rules", () => {
  for (const text of [prompt(null, null), prompt(null, activePlan)]) {
    assertEquals(text.includes(PRIORITY_LINE), false);
    assertEquals(text.includes(EQUIPMENT_LINE), false);
  }
});
