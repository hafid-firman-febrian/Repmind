import { assertEquals } from "jsr:@std/assert@^1";
import { parseGeneratePlanRequest } from "./request.ts";

function post(body?: string): Request {
  return new Request("http://localhost/generate-plan", {
    method: "POST",
    body,
  });
}

Deno.test("an empty body or empty object means a fresh plan", async () => {
  assertEquals(await parseGeneratePlanRequest(post()), {});
  assertEquals(await parseGeneratePlanRequest(post("{}")), {});
});

Deno.test("the instruction is trimmed", async () => {
  assertEquals(
    await parseGeneratePlanRequest(
      post(JSON.stringify({ instruction: "  More core work  " })),
    ),
    { instruction: "More core work" },
  );
});

Deno.test("short, long, non-text or malformed instructions are rejected", async () => {
  const bodies = [
    JSON.stringify({ instruction: "  a " }),
    JSON.stringify({ instruction: "x".repeat(201) }),
    JSON.stringify({ instruction: 42 }),
    "{not json",
  ];
  for (const body of bodies) {
    assertEquals(await parseGeneratePlanRequest(post(body)), null);
  }
});
