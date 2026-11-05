import { z } from "npm:zod@4.6.7";

const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;

const requestSchema = z.object({
  date: z.string().refine(isCalendarDate),
  weekday: z.number().int().min(1).max(7),
});

export type CoachTipRequest = z.infer<typeof requestSchema>;

export async function parseCoachTipRequest(
  request: Request,
): Promise<CoachTipRequest | null> {
  let body: unknown;
  try {
    body = JSON.parse(await request.text());
  } catch {
    return null;
  }
  const parsed = requestSchema.safeParse(body);
  return parsed.success ? parsed.data : null;
}

function isCalendarDate(value: string): boolean {
  const match = DATE_PATTERN.exec(value);
  if (match === null) return false;
  const [year, month, day] = match.slice(1).map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day;
}
