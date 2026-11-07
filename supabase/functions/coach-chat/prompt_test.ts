import { assert, assertEquals, assertStringIncludes } from "jsr:@std/assert@^1";
import {
  coachCatalog,
  coachPlan,
  coachProfile,
  pendingProposal,
} from "./fixtures.ts";
import {
  buildCoachPrompt,
  buildProposalRetryPrompt,
  COACH_SYSTEM_PROMPT,
} from "./prompt.ts";

const history = [
  { role: "user" as const, content: "First question" },
  { role: "assistant" as const, content: "First answer" },
  { role: "user" as const, content: "My shoulder feels tight today" },
];

function prompt(
  overrides: Partial<Parameters<typeof buildCoachPrompt>[0]> = {},
) {
  return buildCoachPrompt({
    profile: coachProfile,
    weekday: 4,
    plan: coachPlan(),
    catalog: coachCatalog,
    pendingProposal: null,
    history,
    ...overrides,
  });
}

Deno.test("the system prompt never lets the coach claim the plan changed", () => {
  assertStringIncludes(COACH_SYSTEM_PROMPT, "Never say the plan has changed");
});

Deno.test("the system prompt demands an explanation and then the tool", () => {
  assertStringIncludes(
    COACH_SYSTEM_PROMPT,
    "Whenever you suggest a concrete change to the plan you must do two things in the same turn, in this order:",
  );
  assertStringIncludes(
    COACH_SYSTEM_PROMPT,
    "A suggestion without this call is useless, because the user can only apply it through the call.",
  );
});

Deno.test("the system prompt sets language, topic, diagnosis and substitute rules", () => {
  assertStringIncludes(
    COACH_SYSTEM_PROMPT,
    "same language as the user's latest message",
  );
  assertStringIncludes(COACH_SYSTEM_PROMPT, "Only discuss training");
  assertStringIncludes(COACH_SYSTEM_PROMPT, "Never diagnose");
  assertStringIncludes(COACH_SYSTEM_PROMPT, "same muscle");
  assertStringIncludes(COACH_SYSTEM_PROMPT, "rest day");
});

Deno.test("describes the person, today, the plan and the catalog", () => {
  const text = prompt();
  assertStringIncludes(text, "Goal: build muscle");
  assertStringIncludes(text, "Equipment: dumbbell, bench");
  assertStringIncludes(text, "Thursday");
  assertStringIncludes(text, "Version 1");
  assertStringIncludes(text, "Day 2 (Thursday) - Full Body B");
  assertStringIncludes(
    text,
    "dumbbell_shoulder_press | Dumbbell Shoulder Press | 3x10 | rest 90s",
  );
  assertStringIncludes(text, "## Exercise catalog");
  for (const exercise of coachCatalog) {
    assertStringIncludes(text, `${exercise.id} | ${exercise.name}`);
  }
});

Deno.test("today's workout is named, and a rest day says so", () => {
  assertStringIncludes(prompt({ weekday: 4 }), "Today is Thursday: Day 2");
  const rest = prompt({ weekday: 2 });
  assertStringIncludes(rest, "Today is Tuesday: rest day");
  assertStringIncludes(rest, "next workout is Day 2");
});

Deno.test("without a plan the prompt says so and has no catalog", () => {
  const text = prompt({ plan: null, catalog: [] });
  assertStringIncludes(text, "no plan yet");
  assertEquals(text.includes("## Exercise catalog"), false);
});

Deno.test("a pending proposal is described with its changes", () => {
  const text = prompt({ pendingProposal: pendingProposal() });
  assertStringIncludes(text, "## Suggestion waiting for an answer");
  assertStringIncludes(
    text,
    "Swap Dumbbell Shoulder Press for Dumbbell Lateral Raise",
  );
  assertStringIncludes(
    text,
    "dumbbell_shoulder_press -> dumbbell_lateral_raise (Dumbbell Lateral Raise) 3x12 rest 60s",
  );
  assertStringIncludes(text, "user_confirmed");
  assertEquals(prompt().includes("## Suggestion waiting"), false);
});

Deno.test("history keeps its order and the latest message is marked", () => {
  const text = prompt();
  const first = text.indexOf("User: First question");
  const answer = text.indexOf("Coach: First answer");
  const latest = text.indexOf("## Latest message");
  assert(first >= 0 && first < answer && answer < latest);
  assert(text.indexOf("My shoulder feels tight today", latest) > latest);
  assertEquals(
    text.indexOf("My shoulder feels tight today") > latest,
    true,
  );
});

Deno.test("a single message has no earlier conversation", () => {
  const text = prompt({ history: [history[2]] });
  assertEquals(text.includes("## Earlier conversation"), false);
  assertStringIncludes(text, "## Latest message");
});

Deno.test("the retry prompt includes the reply and every error", () => {
  const text = buildProposalRetryPrompt(
    "ORIGINAL PROMPT",
    "Try the Lateral Raise instead.",
    ["to_exercise_id made_up_move is not in the catalog", "sets too big"],
  );
  assertStringIncludes(text, "ORIGINAL PROMPT");
  assertStringIncludes(text, "Try the Lateral Raise instead.");
  assertStringIncludes(
    text,
    "- to_exercise_id made_up_move is not in the catalog",
  );
  assertStringIncludes(text, "- sets too big");
});
