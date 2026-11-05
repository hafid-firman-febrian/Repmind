import { z } from "npm:zod@4.6.7";

export { toGeminiSchema } from "../_shared/gemini_schema.ts";

const MAX_REPORTED_ERRORS = 5;

export const tipSchema = z.object({
  tip: z.string().trim().min(20).max(160).describe(
    "One short tip of 20 to 160 characters.",
  ),
});

export type ParsedTip =
  | { ok: true; tip: string }
  | { ok: false; errors: string[] };

export function parseTip(text: string): ParsedTip {
  let json: unknown;
  try {
    json = JSON.parse(text);
  } catch {
    return {
      ok: false,
      errors: [
        "The response was not valid JSON. Answer with the JSON object only.",
      ],
    };
  }
  const parsed = tipSchema.safeParse(json);
  if (!parsed.success) {
    return {
      ok: false,
      errors: parsed.error.issues.slice(0, MAX_REPORTED_ERRORS).map((issue) =>
        `${issue.path.join(".") || "response"}: ${issue.message}`
      ),
    };
  }
  return { ok: true, tip: parsed.data.tip };
}
