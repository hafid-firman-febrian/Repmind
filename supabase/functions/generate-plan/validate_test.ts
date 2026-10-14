import { assert, assertEquals, assertStringIncludes } from "jsr:@std/assert@^1";
import { sampleCatalog, samplePlanOutput } from "./fixtures.ts";
import { planOutputSchema } from "./plan_schema.ts";
import { parsePlanOutput, validatePlan } from "./validate.ts";

const schema = planOutputSchema(sampleCatalog.map((e) => e.id), 2);

Deno.test("a valid answer parses into a plan", () => {
  const result = parsePlanOutput(JSON.stringify(samplePlanOutput()), schema);
  assert(result.ok);
  assertEquals(result.plan.days.length, 2);
});

Deno.test("empty or fenced answers are invalid output, not crashes", () => {
  const fenced = "```json\n" + JSON.stringify(samplePlanOutput()) + "\n```";
  for (const text of ["", fenced]) {
    const result = parsePlanOutput(text, schema);
    assert(!result.ok);
    assertStringIncludes(result.errors[0], "not valid JSON");
  }
});

Deno.test("schema problems are reported with their path", () => {
  const plan = samplePlanOutput();
  plan.days[0].exercises[0].exercise_id = "made_up_move";
  plan.days[1].exercises[0].reps = "8–12";

  const result = parsePlanOutput(JSON.stringify(plan), schema);

  assert(!result.ok);
  assert(
    result.errors.some((e) => e.startsWith("days.0.exercises.0.exercise_id")),
  );
  assert(result.errors.some((e) => e.startsWith("days.1.exercises.0.reps")));
});

Deno.test("day numbers must run from 1 without gaps", () => {
  const plan = samplePlanOutput();
  plan.days[1].day_number = 1;

  assertEquals(validatePlan(plan), [
    "Day at position 2 has day_number 1; use 2.",
  ]);
});

Deno.test("an exercise may appear only once per day", () => {
  const plan = samplePlanOutput();
  plan.days[0].exercises[1].exercise_id = "dumbbell_bench_press";

  assertEquals(validatePlan(plan), [
    "Day 1 lists dumbbell_bench_press more than once.",
  ]);
});
