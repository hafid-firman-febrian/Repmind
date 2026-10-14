import { assertEquals, assertThrows } from "jsr:@std/assert@^1";
import { weekdayName, weekdaysFor } from "./schedule.ts";

Deno.test("spreads training days across the week", () => {
  assertEquals(weekdaysFor(2), [1, 4]);
  assertEquals(weekdaysFor(3), [1, 3, 5]);
  assertEquals(weekdaysFor(4), [1, 2, 4, 6]);
  assertEquals(weekdaysFor(5), [1, 2, 3, 5, 6]);
  assertEquals(weekdaysFor(6), [1, 2, 3, 4, 5, 6]);
});

Deno.test("rejects day counts outside 2 to 6", () => {
  assertThrows(() => weekdaysFor(1), RangeError);
  assertThrows(() => weekdaysFor(7), RangeError);
});

Deno.test("names ISO weekdays", () => {
  assertEquals(weekdayName(1), "Monday");
  assertEquals(weekdayName(7), "Sunday");
});
