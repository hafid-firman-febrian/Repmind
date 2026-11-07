import { z } from "npm:zod@4.6.7";

const GEMINI_SCHEMA_KEYWORDS = new Set([
  "type",
  "properties",
  "required",
  "items",
  "enum",
  "minimum",
  "maximum",
  "minItems",
  "maxItems",
  "description",
  "additionalProperties",
]);

export function toGeminiSchema(schema: z.ZodType): Record<string, unknown> {
  return keepSupportedKeywords(z.toJSONSchema(schema)) as Record<
    string,
    unknown
  >;
}

function keepSupportedKeywords(node: unknown): unknown {
  if (Array.isArray(node)) return node.map(keepSupportedKeywords);
  if (node === null || typeof node !== "object") return node;
  const result: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(node)) {
    if (!GEMINI_SCHEMA_KEYWORDS.has(key)) continue;
    result[key] = key === "properties"
      ? Object.fromEntries(
        Object.entries(value as Record<string, unknown>).map((
          [name, property],
        ) => [
          name,
          keepSupportedKeywords(
            name === "exercise_id" ? withoutEnum(property) : property,
          ),
        ]),
      )
      : keepSupportedKeywords(value);
  }
  return result;
}

function withoutEnum(property: unknown): unknown {
  const { enum: _exerciseIds, ...rest } = property as Record<string, unknown>;
  return rest;
}
