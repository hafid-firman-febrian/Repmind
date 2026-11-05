import { assert, assertEquals } from "jsr:@std/assert@^1";
import type { CatalogExercise, CoachPlan } from "../_shared/training.ts";
import { coachCatalog, coachPlan, PLAN_ID } from "./fixtures.ts";
import { buildProposal, namesUnfiledChange } from "./proposal.ts";

const context = {
  plan: coachPlan(),
  catalog: coachCatalog,
  aiModel: "gemini_flash_lite" as const,
};

function swap(overrides: Record<string, unknown> = {}) {
  return {
    from_exercise_id: "dumbbell_shoulder_press",
    to_exercise_id: "dumbbell_lateral_raise",
    sets: 3,
    reps: "12",
    rest_seconds: 60,
    ...overrides,
  };
}

function args(
  changes: unknown[] = [swap()],
  overrides: Record<string, unknown> = {},
) {
  return { day_number: 2, changes, ...overrides };
}

function errorsOf(input: unknown, ctx = context): string[] {
  const result = buildProposal(input, ctx);
  assert(!result.ok);
  return result.errors;
}

function assertMentions(errors: string[], text: string) {
  assert(
    errors.some((error) => error.includes(text)),
    `expected an error mentioning "${text}" in ${JSON.stringify(errors)}`,
  );
}

Deno.test("a valid swap becomes a proposal", () => {
  const result = buildProposal(args(), context);
  assert(result.ok);
  assertEquals(result.userConfirmed, false);
  assertEquals(result.proposal, {
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
  });
});

Deno.test("a dose change keeps the exercise", () => {
  const result = buildProposal(
    args([swap({ to_exercise_id: "dumbbell_shoulder_press", sets: 2 })]),
    context,
  );
  assert(result.ok);
  assertEquals(result.proposal.summary, "Update Dumbbell Shoulder Press");
  assertEquals(
    result.proposal.changes[0].to_exercise_name,
    "Dumbbell Shoulder Press",
  );
});

Deno.test("several changes summarize the day", () => {
  const result = buildProposal(
    args([
      swap(),
      swap({
        from_exercise_id: "plank",
        to_exercise_id: "plank",
        reps: "20-30s",
      }),
    ]),
    context,
  );
  assert(result.ok);
  assertEquals(result.proposal.summary, "Coach updated Full Body B");
  assertEquals(result.proposal.changes.length, 2);
});

Deno.test("three changes are the most allowed", () => {
  const result = buildProposal(
    args([
      swap(),
      swap({
        from_exercise_id: "plank",
        to_exercise_id: "plank",
        reps: "20-30s",
      }),
      swap({
        from_exercise_id: "romanian_deadlift",
        to_exercise_id: "romanian_deadlift",
        sets: 2,
      }),
    ]),
    context,
  );
  assert(result.ok);
});

Deno.test("user_confirmed passes through", () => {
  const result = buildProposal(
    args([swap()], { user_confirmed: true }),
    context,
  );
  assert(result.ok);
  assertEquals(result.userConfirmed, true);
});

Deno.test("a swap too long for the summary falls back to the day title", () => {
  const longName = "A".repeat(180);
  const catalog: CatalogExercise[] = [
    ...coachCatalog,
    { ...coachCatalog[4], id: "long_name", name: longName },
  ];
  const result = buildProposal(
    args([swap({ to_exercise_id: "long_name" })]),
    { ...context, catalog },
  );
  assert(result.ok);
  assertEquals(result.proposal.summary, "Coach updated Full Body B");
});

Deno.test("a summary is never longer than 200 characters", () => {
  const plan = coachPlan();
  plan.days[1].title = "T".repeat(300);
  const result = buildProposal(
    args([
      swap(),
      swap({
        from_exercise_id: "plank",
        to_exercise_id: "plank",
        reps: "20-30s",
      }),
    ]),
    { ...context, plan },
  );
  assert(result.ok);
  assertEquals(result.proposal.summary.length, 200);
});

Deno.test("arguments of the wrong shape are reported", () => {
  for (const input of ["swap it", null, {}, { day_number: 2 }]) {
    assert(errorsOf(input).length > 0);
  }
  assertMentions(errorsOf({ day_number: 2, changes: [] }), "changes");
});

Deno.test("a day that is not in the plan is reported", () => {
  const errors = errorsOf(args([swap()], { day_number: 3 }));
  assertMentions(errors, "Day 3");
  assertMentions(errors, "1, 2");
});

Deno.test("an exercise that is not in the day is reported", () => {
  assertMentions(
    errorsOf(args([swap({ from_exercise_id: "goblet_squat" })])),
    "goblet_squat",
  );
});

Deno.test("an exercise outside the catalog is reported", () => {
  assertMentions(
    errorsOf(args([swap({ to_exercise_id: "made_up_move" })])),
    "made_up_move",
  );
});

Deno.test("an exercise already in the day is reported", () => {
  const errors = errorsOf(args([swap({ to_exercise_id: "plank" })]));
  assertMentions(errors, "plank");
  assertMentions(errors, "already");
});

Deno.test("a change that alters nothing is reported", () => {
  const errors = errorsOf(args([
    swap({
      to_exercise_id: "dumbbell_shoulder_press",
      sets: 3,
      reps: "10",
      rest_seconds: 90,
    }),
  ]));
  assertMentions(errors, "nothing");
});

Deno.test("one change that alters nothing rejects the whole proposal", () => {
  const errors = errorsOf(args([
    swap(),
    swap({
      from_exercise_id: "plank",
      to_exercise_id: "plank",
      sets: 3,
      reps: "30-45s",
      rest_seconds: 45,
    }),
  ]));
  assertMentions(errors, "plank");
  assertMentions(errors, "nothing");
});

Deno.test("the same exercise cannot be changed twice", () => {
  const errors = errorsOf(args([
    swap(),
    swap({ to_exercise_id: "push_up" }),
  ]));
  assertMentions(errors, "dumbbell_shoulder_press");
  assertMentions(errors, "more than once");
});

Deno.test("chained changes are reported", () => {
  const errors = errorsOf(args([
    swap({ to_exercise_id: "plank" }),
    swap({ from_exercise_id: "plank", to_exercise_id: "push_up" }),
  ]));
  assertMentions(errors, "chain");
});

Deno.test("two changes cannot bring in the same exercise", () => {
  const errors = errorsOf(args([
    swap({ to_exercise_id: "push_up" }),
    swap({ from_exercise_id: "plank", to_exercise_id: "push_up" }),
  ]));
  assertMentions(errors, "push_up");
});

Deno.test("four changes are too many", () => {
  assertMentions(
    errorsOf(args([swap(), swap(), swap(), swap()])),
    "changes",
  );
});

Deno.test("out of range doses are reported", () => {
  assertMentions(errorsOf(args([swap({ sets: 9 })])), "sets");
  assertMentions(errorsOf(args([swap({ reps: "abc" })])), "reps");
  assertMentions(errorsOf(args([swap({ rest_seconds: 10 })])), "rest_seconds");
});

Deno.test("every problem is reported together", () => {
  const errors = errorsOf(args([
    swap({ from_exercise_id: "goblet_squat", to_exercise_id: "made_up_move" }),
  ]));
  assertMentions(errors, "goblet_squat");
  assertMentions(errors, "made_up_move");
});

function namedPlan(extraDayThree: string[] = []): CoachPlan {
  const exercise = (name: string) => ({
    exerciseId: name.toLowerCase().replaceAll(" ", "_"),
    name,
    sets: 3,
    reps: "10",
    restSeconds: 60,
  });
  return {
    id: PLAN_ID,
    title: "Split",
    version: 1,
    days: [
      {
        dayNumber: 2,
        weekday: 2,
        title: "Day 2",
        exercises: ["Dumbbell Shoulder Press", "One-arm Dumbbell Row"].map(
          exercise,
        ),
      },
      {
        dayNumber: 3,
        weekday: 4,
        title: "Day 3",
        exercises: [
          "Dumbbell Floor Press",
          "Renegade Row",
          ...extraDayThree,
        ].map(exercise),
      },
    ],
  };
}

function catalogEntry(name: string): CatalogExercise {
  return {
    id: name.toLowerCase().replaceAll(" ", "_"),
    name,
    focus: "upper",
    primaryMuscle: "Chest",
    equipment: [],
  };
}

const namedCatalog = ["Push-up", "Incline Push-up"].map(catalogEntry);

Deno.test("a swap to a catalog-only exercise names an unfiled change", () => {
  assert(namesUnfiledChange(
    "swap Dumbbell Floor Press for Push-up",
    namedPlan(),
    namedCatalog,
  ));
});

Deno.test("a swap across days names an unfiled change", () => {
  assert(namesUnfiledChange(
    "replace Renegade Row with One-arm Dumbbell Row",
    namedPlan(),
    namedCatalog,
  ));
});

Deno.test("a new exercise alone names an unfiled change", () => {
  assert(namesUnfiledChange("Try Push-ups instead", namedPlan(), namedCatalog));
});

Deno.test("naming the exercises of one day is not a change", () => {
  assert(
    !namesUnfiledChange(
      "Today you do Dumbbell Floor Press and then Renegade Row.",
      namedPlan(),
      namedCatalog,
    ),
  );
});

Deno.test("naming no exercise is not a change", () => {
  assert(
    !namesUnfiledChange("Rest and sleep well", namedPlan(), namedCatalog),
  );
});

Deno.test("exercise names match regardless of case", () => {
  assert(namesUnfiledChange(
    "swap dumbbell floor press for push-up",
    namedPlan(),
    namedCatalog,
  ));
});

Deno.test("exercise names match in an Indonesian reply", () => {
  assert(namesUnfiledChange(
    "ganti Dumbbell Floor Press dengan Push-up",
    namedPlan(),
    namedCatalog,
  ));
});

Deno.test("the longest name wins so Incline Push-up is not also Push-up", () => {
  assert(
    !namesUnfiledChange(
      "Dumbbell Floor Press and Incline Push-up",
      namedPlan(["Incline Push-up"]),
      namedCatalog,
    ),
  );
});
