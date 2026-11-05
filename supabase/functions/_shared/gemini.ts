import { GoogleGenAI } from "npm:@google/genai@2.28.0";
import type { ChatEvent, ChatModel, ChatModelRequest } from "./chat_model.ts";
import type { JsonModel, JsonModelRequest } from "./json_model.ts";

const REQUEST_TIMEOUT_MS = 60_000;

export class GeminiJsonModel implements JsonModel {
  #client: GoogleGenAI;

  constructor(apiKey: string) {
    this.#client = new GoogleGenAI({ apiKey });
  }

  async generateJson(request: JsonModelRequest): Promise<string> {
    const interaction = await this.#client.interactions.create(
      {
        model: request.model,
        system_instruction: request.systemInstruction,
        input: request.prompt,
        response_format: {
          type: "text",
          mime_type: "application/json",
          schema: request.schema,
        },
        generation_config: { thinking_level: "low" },
        store: false,
      },
      { timeout: REQUEST_TIMEOUT_MS, maxRetries: 0 },
    );
    return interaction.output_text ?? "";
  }
}

export class GeminiChatModel implements ChatModel {
  #client: GoogleGenAI;

  constructor(apiKey: string) {
    this.#client = new GoogleGenAI({ apiKey });
  }

  async *stream(request: ChatModelRequest): AsyncGenerator<ChatEvent> {
    const events = await this.#client.interactions.create(
      {
        model: request.model,
        system_instruction: request.systemInstruction,
        input: request.prompt,
        tools: request.tools.map((tool) => ({
          type: "function" as const,
          name: tool.name,
          description: tool.description,
          parameters: tool.parameters,
        })),
        generation_config: request.forceTool === true
          ? { thinking_level: "low", tool_choice: "any" }
          : { thinking_level: "low" },
        stream: true,
        store: false,
      },
      {
        timeout: REQUEST_TIMEOUT_MS,
        maxRetries: 0,
        signal: request.signal,
      },
    );
    yield* toChatEvents(events);
  }
}

interface PendingCall {
  name: string;
  startArguments: unknown;
  buffer: string;
  received: boolean;
}

interface StreamEvent {
  event_type?: string;
  index?: number;
  step?: { type?: string; name?: string; arguments?: unknown };
  delta?: { type?: string; text?: unknown; arguments?: unknown };
  error?: { message?: unknown };
}

export async function* toChatEvents(
  events: AsyncIterable<unknown>,
): AsyncGenerator<ChatEvent> {
  const calls = new Map<number, PendingCall>();
  let completed = false;
  for await (const event of events) {
    const { event_type: type, index, step, delta, error } =
      event as StreamEvent;
    if (type === "error") {
      throw new Error(
        typeof error?.message === "string"
          ? error.message
          : "Gemini stream failed",
      );
    }
    if (type === "interaction.completed") completed = true;
    if (index === undefined) continue;
    if (type === "step.start" && step?.type === "function_call") {
      calls.set(index, {
        name: step.name ?? "",
        startArguments: step.arguments,
        buffer: "",
        received: false,
      });
    } else if (type === "step.delta") {
      if (delta?.type === "text" && typeof delta.text === "string") {
        if (delta.text.length > 0) yield { type: "text", text: delta.text };
      } else if (
        delta?.type === "arguments_delta" &&
        typeof delta.arguments === "string"
      ) {
        const call = calls.get(index);
        if (call !== undefined) {
          call.buffer += delta.arguments;
          call.received = true;
        }
      }
    } else if (type === "step.stop") {
      const call = calls.get(index);
      if (call !== undefined) {
        calls.delete(index);
        yield {
          type: "tool_call",
          name: call.name,
          args: parseArguments(call),
        };
      }
    }
  }
  if (!completed) throw new Error("Gemini stream ended before it completed");
}

function parseArguments(call: PendingCall): unknown {
  if (!call.received) return call.startArguments ?? {};
  try {
    return JSON.parse(call.buffer);
  } catch {
    return call.buffer;
  }
}
