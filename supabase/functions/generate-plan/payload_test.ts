import { assertEquals } from "jsr:@std/assert@^1";
import { samplePlanOutput } from "./fixtures.ts";
import { toSavePayload } from "./payload.ts";

Deno.test("adds weekdays, positions, the model and the instruction", () => {
  const payload = toSavePayload(samplePlanOutput(), {
    weekdays: [1, 4],
    aiModel: "gemini_flash_lite",
    instruction: "More core work",
  });

  assertEquals(payload.ai_model, "gemini_flash_lite");
  assertEquals(payload.instruction, "More core work");
  assertEquals(payload.days.map((day) => day.weekday), [1, 4]);
  assertEquals(payload.days[0].exercises.map((e) => e.position), [1, 2, 3]);
  assertEquals(payload.days[0].exercises[0], {
    position: 1,
    exercise_id: "dumbbell_bench_press",
    sets: 4,
    reps: "8-10",
    rest_seconds: 90,
  });
});
