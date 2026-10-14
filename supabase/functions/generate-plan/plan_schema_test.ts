import { assert, assertEquals } from "jsr:@std/assert@^1";
import { sampleCatalog, samplePlanOutput } from "./fixtures.ts";
import { planOutputSchema, toGeminiSchema } from "./plan_schema.ts";

const ids = sampleCatalog.map((exercise) => exercise.id);

Deno.test("accepts a plan that matches the catalog and day count", () => {
  assert(planOutputSchema(ids, 2).safeParse(samplePlanOutput()).success);
});

Deno.test("rejects unknown exercises, wrong day counts, bad numbers and bad reps", () => {
  const schema = planOutputSchema(ids, 2);
  const unknown = samplePlanOutput();
  unknown.days[0].exercises[0].exercise_id = "made_up_move";
  const tooHeavy = samplePlanOutput();
  tooHeavy.days[0].exercises[0].sets = 9;
  const enDash = samplePlanOutput();
  enDash.days[0].exercises[0].reps = "8–12";

  assertEquals(schema.safeParse(unknown).success, false);
  assertEquals(schema.safeParse(samplePlanOutput(3)).success, false);
  assertEquals(schema.safeParse(tooHeavy).success, false);
  assertEquals(schema.safeParse(enDash).success, false);
});

Deno.test("the Gemini schema locks the day count and leaves a large exercise list to zod", () => {
  const largeCatalogIds = Array.from(
    { length: 42 },
    (_, index) => `exercise_${index}`,
  );
  const geminiSchema = toGeminiSchema(planOutputSchema(largeCatalogIds, 4)) as {
    properties: {
      days: {
        minItems: number;
        maxItems: number;
        items: {
          properties: {
            focus: { enum: string[] };
            exercises: {
              items: { properties: { exercise_id: { enum?: string[] } } };
            };
          };
        };
      };
    };
  };
  const days = geminiSchema.properties.days;
  const largeCatalogPlan = samplePlanOutput();
  largeCatalogPlan.days.forEach((day, dayIndex) =>
    day.exercises.forEach((exercise, exerciseIndex) => {
      exercise.exercise_id = largeCatalogIds[dayIndex * 8 + exerciseIndex];
    })
  );
  const foreignExercise = structuredClone(largeCatalogPlan);
  foreignExercise.days[0].exercises[0].exercise_id = "made_up_move";
  const largeCatalogSchema = planOutputSchema(largeCatalogIds, 2);

  assertEquals(days.minItems, 4);
  assertEquals(days.maxItems, 4);
  assertEquals(
    days.items.properties.exercises.items.properties.exercise_id.enum,
    undefined,
  );
  assertEquals(days.items.properties.focus.enum.length, 4);
  assertEquals(largeCatalogSchema.safeParse(largeCatalogPlan).success, true);
  assertEquals(largeCatalogSchema.safeParse(foreignExercise).success, false);
});

Deno.test("the Gemini schema only uses keywords Gemini supports", () => {
  const text = JSON.stringify(toGeminiSchema(planOutputSchema(ids, 2)));
  for (const keyword of ["pattern", "$schema", "minLength", "maxLength"]) {
    assertEquals(text.includes(`"${keyword}"`), false, keyword);
  }
});
