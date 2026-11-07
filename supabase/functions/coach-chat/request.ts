import { z } from "npm:zod@4.6.7";

const MAX_MESSAGE_LENGTH = 1000;

const requestSchema = z.object({
  message: z.string().trim().min(1).max(MAX_MESSAGE_LENGTH).optional(),
  retry_message_id: z.guid().optional(),
  weekday: z.number().int().min(1).max(7),
});

export type CoachChatRequest =
  | { kind: "message"; message: string; weekday: number }
  | { kind: "retry"; retryMessageId: string; weekday: number };

export async function parseCoachChatRequest(
  request: Request,
): Promise<CoachChatRequest | null> {
  let body: unknown;
  try {
    body = JSON.parse(await request.text());
  } catch {
    return null;
  }
  const parsed = requestSchema.safeParse(body);
  if (!parsed.success) return null;
  const { message, retry_message_id: retryMessageId, weekday } = parsed.data;
  if (message !== undefined && retryMessageId === undefined) {
    return { kind: "message", message, weekday };
  }
  if (message === undefined && retryMessageId !== undefined) {
    return { kind: "retry", retryMessageId, weekday };
  }
  return null;
}
