export interface JsonModelRequest {
  model: string;
  systemInstruction: string;
  prompt: string;
  schema: Record<string, unknown>;
}

export interface JsonModel {
  generateJson(request: JsonModelRequest): Promise<string>;
}
