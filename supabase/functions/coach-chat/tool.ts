import { z } from "npm:zod@4.6.7";
import { toGeminiSchema } from "../_shared/gemini_schema.ts";
import type { ChatTool } from "../_shared/chat_model.ts";
import { REPS_PATTERN } from "../_shared/training.ts";

const SETS_MESSAGE = "must be a whole number from 1 to 8";
const REPS_MESSAGE =
  "must be a number like '10', a range like '8-12', or seconds like '30s' or '30-45s'";
const REST_MESSAGE = "must be a whole number of seconds from 15 to 300";

const changeSchema = z.object({
  from_exercise_id: z.string().min(1).describe(
    "exercise_id of the exercise in the day that is replaced or adjusted.",
  ),
  to_exercise_id: z.string().min(1).describe(
    "exercise_id from the catalog to do instead. Use the same exercise_id as from_exercise_id to only change sets, reps or rest.",
  ),
  sets: z.number({ error: SETS_MESSAGE }).int(SETS_MESSAGE).min(1, SETS_MESSAGE)
    .max(8, SETS_MESSAGE),
  reps: z.string({ error: REPS_MESSAGE }).regex(REPS_PATTERN, REPS_MESSAGE)
    .describe(
      "Reps per set: a number like '10', a range like '8-12', or seconds like '30s' or '30-45s'.",
    ),
  rest_seconds: z.number({ error: REST_MESSAGE }).int(REST_MESSAGE).min(
    15,
    REST_MESSAGE,
  ).max(300, REST_MESSAGE),
});

export const proposePlanChangeSchema = z.object({
  day_number: z.number().int().min(1).max(7).describe(
    "Day number of the one training day to change, as shown in the current plan.",
  ),
  changes: z.array(changeSchema).min(1, "must contain 1 to 3 changes").max(
    3,
    "must contain 1 to 3 changes",
  ).describe("One to three changes, all in the same day."),
  user_confirmed: z.boolean().optional().describe(
    "true only when the person has just agreed to a suggestion that was waiting for an answer.",
  ),
});

export type ProposePlanChangeArgs = z.infer<typeof proposePlanChangeSchema>;

export const PROPOSE_PLAN_CHANGE: ChatTool = {
  name: "propose_plan_change",
  description:
    "Prepare a change to one training day of the person's current plan for them to review. It never changes the plan by itself: the person applies it in the app. Use it every time you suggest a concrete change, after writing your explanation.",
  parameters: toGeminiSchema(proposePlanChangeSchema),
};
