export type SseSend = (event: Record<string, unknown>) => void;

export function sseResponse(
  run: (send: SseSend, signal: AbortSignal) => Promise<void>,
): Response {
  const abort = new AbortController();
  const encoder = new TextEncoder();
  let open = true;
  const body = new ReadableStream<Uint8Array>({
    start(controller) {
      const send: SseSend = (event) => {
        if (!open) return;
        controller.enqueue(
          encoder.encode(`data: ${JSON.stringify(event)}\n\n`),
        );
      };
      new Promise<void>((resolve) => resolve(run(send, abort.signal)))
        .catch((error) => console.error("sse run failed", error))
        .finally(() => {
          if (!open) return;
          open = false;
          controller.close();
        });
    },
    cancel() {
      open = false;
      abort.abort();
    },
  });
  return new Response(body, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
    },
  });
}
