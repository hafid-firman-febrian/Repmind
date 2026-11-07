import { assertEquals } from "jsr:@std/assert@^1";
import { parseCoachTipRequest } from "./request.ts";

function post(body?: string): Request {
  return new Request("http://localhost/coach-tip", { method: "POST", body });
}

function json(body: unknown): Request {
  return post(JSON.stringify(body));
}

Deno.test("a date and weekday are accepted", async () => {
  assertEquals(
    await parseCoachTipRequest(json({ date: "2026-11-05", weekday: 4 })),
    { date: "2026-11-05", weekday: 4 },
  );
});

Deno.test("a leap day is accepted", async () => {
  assertEquals(
    await parseCoachTipRequest(json({ date: "2028-02-29", weekday: 2 })),
    { date: "2028-02-29", weekday: 2 },
  );
});

Deno.test("a date that is not on the calendar is rejected", async () => {
  for (const date of ["2026-13-45", "2026-02-30", "2027-02-29", "2026-00-10"]) {
    assertEquals(await parseCoachTipRequest(json({ date, weekday: 4 })), null);
  }
});

Deno.test("a date in another format is rejected", async () => {
  for (const date of ["05/11/2026", "2026-1-5", "2026-11-05T10:00:00Z", ""]) {
    assertEquals(await parseCoachTipRequest(json({ date, weekday: 4 })), null);
  }
});

Deno.test("a missing date is rejected", async () => {
  assertEquals(await parseCoachTipRequest(json({ weekday: 4 })), null);
});

Deno.test("a weekday outside 1 to 7 is rejected", async () => {
  for (const weekday of [0, 8, 1.5, "4"]) {
    assertEquals(
      await parseCoachTipRequest(json({ date: "2026-11-05", weekday })),
      null,
    );
  }
});

Deno.test("a missing weekday is rejected", async () => {
  assertEquals(await parseCoachTipRequest(json({ date: "2026-11-05" })), null);
});

Deno.test("an empty or malformed body is rejected", async () => {
  assertEquals(await parseCoachTipRequest(post()), null);
  assertEquals(await parseCoachTipRequest(post("{nope")), null);
});
