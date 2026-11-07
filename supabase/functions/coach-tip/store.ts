import type { SupabaseClient } from "jsr:@supabase/supabase-js@2.117.3";
import type { CoachPlan, PlanProfile } from "../_shared/training.ts";
import {
  readActivePlan,
  readProfile,
  readUserId,
} from "../_shared/training_store.ts";
import type { TipStore } from "./types.ts";

export class SupabaseTipStore implements TipStore {
  constructor(
    private readonly client: SupabaseClient,
    private readonly accessToken: string | null,
  ) {}

  userId(): Promise<string | null> {
    return readUserId(this.client, this.accessToken);
  }

  profile(userId: string): Promise<PlanProfile | null> {
    return readProfile(this.client, userId);
  }

  activePlan(userId: string): Promise<CoachPlan | null> {
    return readActivePlan(this.client, userId);
  }

  async existingTip(
    userId: string,
    planId: string,
    date: string,
  ): Promise<string | null> {
    const { data, error } = await this.client
      .from("coach_tips")
      .select("content")
      .eq("user_id", userId)
      .eq("plan_id", planId)
      .eq("tip_date", date)
      .maybeSingle();
    if (error) throw error;
    return (data as { content: string } | null)?.content ?? null;
  }

  async saveTip(
    userId: string,
    planId: string,
    date: string,
    content: string,
  ): Promise<void> {
    const { error } = await this.client
      .from("coach_tips")
      .upsert(
        { user_id: userId, plan_id: planId, tip_date: date, content },
        { onConflict: "user_id,tip_date,plan_id", ignoreDuplicates: true },
      );
    if (error) throw error;
  }
}
