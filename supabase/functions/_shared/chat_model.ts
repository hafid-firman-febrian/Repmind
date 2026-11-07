export interface ChatTool {
  name: string;
  description: string;
  parameters: Record<string, unknown>;
}

export interface ChatModelRequest {
  model: string;
  systemInstruction: string;
  prompt: string;
  tools: ChatTool[];
  forceTool?: boolean;
  signal?: AbortSignal;
}

export type ChatEvent =
  | { type: "text"; text: string }
  | { type: "tool_call"; name: string; args: unknown };

export interface ChatModel {
  stream(request: ChatModelRequest): AsyncIterable<ChatEvent>;
}
