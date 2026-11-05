import { assertEquals } from "jsr:@std/assert@^1";
import { parseCoachChatRequest } from "./request.ts";

const RETRY_ID = "6f1d3c52-9b8e-4c1a-8e2d-0a7b5c9d4e11";

function post(body?: string): Request {
  return new Request("http://localhost/coach-chat", { method: "POST", body });
}

function json(body: unknown): Request {
  return post(JSON.stringify(body));
}

Deno.test("a message is trimmed", async () => {
  assertEquals(
    await parseCoachChatRequest(json({ message: "  Hi  ", weekday: 4 })),
    { kind: "message", message: "Hi", weekday: 4 },
  );
});

Deno.test("a retry carries the message id", async () => {
  assertEquals(
    await parseCoachChatRequest(
      json({ retry_message_id: RETRY_ID, weekday: 4 }),
    ),
    { kind: "retry", retryMessageId: RETRY_ID, weekday: 4 },
  );
});

Deno.test("a message of exactly 1000 characters is accepted", async () => {
  const message = "x".repeat(1000);
  assertEquals(
    await parseCoachChatRequest(json({ message, weekday: 1 })),
    { kind: "message", message, weekday: 1 },
  );
});

Deno.test("invalid bodies are rejected", async () => {
  const bodies = [
    post(
      JSON.stringify({ message: "Hi", retry_message_id: RETRY_ID, weekday: 4 }),
    ),
    json({ weekday: 4 }),
    json({ message: "   ", weekday: 4 }),
    json({ message: "x".repeat(1001), weekday: 4 }),
    json({ message: "Hi", weekday: 0 }),
    json({ message: "Hi", weekday: 8 }),
    json({ message: "Hi", weekday: 2.5 }),
    json({ message: "Hi", weekday: "4" }),
    json({ message: "Hi" }),
    json({ message: 42, weekday: 4 }),
    json({ retry_message_id: "not-a-uuid", weekday: 4 }),
    json(["Hi"]),
    post(),
    post("{not json"),
  ];
  for (const request of bodies) {
    assertEquals(await parseCoachChatRequest(request), null);
  }
});
