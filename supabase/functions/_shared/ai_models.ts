export const AI_MODELS = {
  gemini_flash: { id: "gemini-3.8-flash", label: "Gemini 3.8 Flash" },
  gemini_flash_lite: {
    id: "gemini-3.5-flash-lite",
    label: "Gemini 3.5 Flash-Lite",
  },
  gemini_pro: { id: "gemini-3.1-pro-preview", label: "Gemini 3.1 Pro" },
} as const;

export type AiModelKey = keyof typeof AI_MODELS;

export function isAiModelKey(value: string): value is AiModelKey {
  return Object.hasOwn(AI_MODELS, value);
}
