import type { CoachPlan, PlanProfile } from "../_shared/training.ts";

export interface TipStore {
  userId(): Promise<string | null>;
  profile(userId: string): Promise<PlanProfile | null>;
  activePlan(userId: string): Promise<CoachPlan | null>;
  existingTip(
    userId: string,
    planId: string,
    date: string,
  ): Promise<string | null>;
  saveTip(
    userId: string,
    planId: string,
    date: string,
    content: string,
  ): Promise<void>;
}
