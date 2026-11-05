import { assert, assertEquals, assertRejects } from "jsr:@std/assert@^1";
import type { ChatEvent } from "./chat_model.ts";
import { toChatEvents } from "./gemini.ts";

const TOOL_ARGUMENTS_FIRST =
  '{"day_number":2,"changes":[{"to_exercise_id":"dumbbell_lateral_raise",';
const TOOL_ARGUMENTS_SECOND =
  '"from_exercise_id":"dumbbell_shoulder_press","rest_seconds":60,"reps":"12","sets":3}],"user_confirmed":false}';

const EVENTS: Record<string, unknown>[] = [
  {
    event_type: "interaction.created",
    interaction: { object: "interaction", model: "gemini-3.5-flash-lite" },
  },
  { event_type: "interaction.status_update", status: "in_progress" },
  { event_type: "step.start", index: 0, step: { type: "thought" } },
  {
    event_type: "step.delta",
    index: 0,
    delta: { type: "thought_signature", signature: "abc" },
  },
  { event_type: "step.stop", index: 0 },
  { event_type: "step.start", index: 1, step: { type: "model_output" } },
  {
    event_type: "step.delta",
    index: 1,
    delta: { type: "text", text: "Since your" },
  },
  {
    event_type: "step.delta",
    index: 1,
    delta: { type: "text", text: " shoulder feels tight." },
  },
  { event_type: "step.stop", index: 1 },
  {
    event_type: "step.start",
    index: 2,
    step: {
      id: "call_1",
      type: "function_call",
      name: "propose_plan_change",
      arguments: {},
    },
  },
  {
    event_type: "step.delta",
    index: 2,
    delta: { type: "arguments_delta", arguments: TOOL_ARGUMENTS_FIRST },
  },
  {
    event_type: "step.delta",
    index: 2,
    delta: { type: "arguments_delta", arguments: TOOL_ARGUMENTS_SECOND },
  },
  { event_type: "step.stop", index: 2 },
  {
    event_type: "interaction.completed",
    interaction: { status: "requires_action", object: "interaction" },
  },
];

async function* replay(events: unknown[]): AsyncGenerator<unknown> {
  for (const event of events) yield event;
}

async function collect(events: unknown[]): Promise<ChatEvent[]> {
  const result: ChatEvent[] = [];
  for await (const event of toChatEvents(replay(events))) result.push(event);
  return result;
}

Deno.test("toChatEvents maps text deltas", async () => {
  const result = await collect(EVENTS);
  assertEquals(
    result.filter((event) => event.type === "text"),
    [
      { type: "text", text: "Since your" },
      { type: "text", text: " shoulder feels tight." },
    ],
  );
  assertEquals(result[0].type, "text");
});

Deno.test("toChatEvents joins a function call", async () => {
  const calls = (await collect(EVENTS)).filter((event) =>
    event.type === "tool_call"
  );
  assertEquals(calls, [
    {
      type: "tool_call",
      name: "propose_plan_change",
      args: {
        day_number: 2,
        changes: [{
          to_exercise_id: "dumbbell_lateral_raise",
          from_exercise_id: "dumbbell_shoulder_press",
          rest_seconds: 60,
          reps: "12",
          sets: 3,
        }],
        user_confirmed: false,
      },
    },
  ]);
});

Deno.test("toChatEvents emits the raw string when arguments do not parse", async () => {
  const broken = EVENTS.filter((event) =>
    event.event_type !== "step.delta" || event.index !== 2
  );
  broken.splice(10, 0, {
    event_type: "step.delta",
    index: 2,
    delta: { type: "arguments_delta", arguments: '{"day_number":' },
  });
  const calls = (await collect(broken)).filter((event) =>
    event.type === "tool_call"
  );
  assertEquals(calls, [
    { type: "tool_call", name: "propose_plan_change", args: '{"day_number":' },
  ]);
});

Deno.test("toChatEvents throws on an error event", async () => {
  await assertRejects(
    () =>
      collect([
        EVENTS[0],
        { event_type: "error", error: { message: "quota exceeded" } },
      ]),
    Error,
    "quota exceeded",
  );
});

async function collectUntilFailure(
  events: unknown[],
): Promise<{ yielded: ChatEvent[]; error: unknown }> {
  const yielded: ChatEvent[] = [];
  try {
    for await (const event of toChatEvents(replay(events))) {
      yielded.push(event);
    }
  } catch (error) {
    return { yielded, error };
  }
  return { yielded, error: undefined };
}

Deno.test("toChatEvents throws when the stream ends without interaction.completed", async () => {
  const cut = EVENTS.slice(0, 8);
  const { yielded, error } = await collectUntilFailure(cut);

  assertEquals(yielded, [
    { type: "text", text: "Since your" },
    { type: "text", text: " shoulder feels tight." },
  ]);
  assert(error instanceof Error);
  await assertRejects(() => collect(cut), Error);
});

Deno.test("toChatEvents throws when a function call stream is cut", async () => {
  const cut = EVENTS.slice(0, 12);
  const { yielded, error } = await collectUntilFailure(cut);

  assertEquals(yielded.filter((event) => event.type === "tool_call"), []);
  assert(error instanceof Error);
  await assertRejects(() => collect(cut), Error);
});
