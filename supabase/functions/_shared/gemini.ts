import { GoogleGenAI } from "npm:@google/genai@2.28.0";
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
