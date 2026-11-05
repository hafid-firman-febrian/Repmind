import { assertEquals } from "jsr:@std/assert@^1";
import { sseResponse, type SseSend } from "./sse.ts";

Deno.test("sseResponse writes data lines and closes", async () => {
  const response = sseResponse((send) => {
    send({ type: "delta", text: "Hi" });
    return Promise.resolve();
  });
  assertEquals(response.headers.get("Content-Type"), "text/event-stream");
  assertEquals(response.headers.get("Cache-Control"), "no-cache");
  assertEquals(await response.text(), 'data: {"type":"delta","text":"Hi"}\n\n');
});

Deno.test("cancelling the body aborts the signal", async () => {
  let captured: { send: SseSend; signal: AbortSignal } | null = null;
  const release = Promise.withResolvers<void>();
  const response = sseResponse((send, signal) => {
    captured = { send, signal };
    return release.promise;
  });
  const reader = response.body!.getReader();
  assertEquals(captured!.signal.aborted, false);
  await reader.cancel();
  assertEquals(captured!.signal.aborted, true);
  captured!.send({ type: "delta", text: "late" });
  release.resolve();
  await release.promise;
});

Deno.test("a rejected run closes the stream", async () => {
  const original = console.error;
  const logged: unknown[][] = [];
  console.error = (...args: unknown[]) => {
    logged.push(args);
  };
  try {
    const response = sseResponse((send) => {
      send({ type: "delta", text: "partial" });
      return Promise.reject(new Error("boom"));
    });
    assertEquals(
      await response.text(),
      'data: {"type":"delta","text":"partial"}\n\n',
    );
    assertEquals(logged.length, 1);
  } finally {
    console.error = original;
  }
});
