import { z } from "npm:zod@4.6.7";

const requestSchema = z.object({
  instruction: z.string().trim().min(3).max(200).optional(),
});

export type GeneratePlanRequest = z.infer<typeof requestSchema>;

export async function parseGeneratePlanRequest(
  request: Request,
): Promise<GeneratePlanRequest | null> {
  const text = await request.text();
  let body: unknown = {};
  if (text.trim().length > 0) {
    try {
      body = JSON.parse(text);
    } catch {
      return null;
    }
  }
  const parsed = requestSchema.safeParse(body);
  return parsed.success ? parsed.data : null;
}
