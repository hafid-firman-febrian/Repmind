import type { SupabaseClient } from "jsr:@supabase/supabase-js@2.117.3";
import type {
  CatalogExercise,
  CoachPlan,
  PlanProfile,
} from "../_shared/training.ts";
import {
  readActivePlan,
  readCatalog,
  readProfile,
  readUserId,
} from "../_shared/training_store.ts";
import type { ChatHistoryMessage, CoachStore, PlanProposal } from "./types.ts";

interface ChatMessageRow {
  id: string;
  role: "user" | "assistant";
  content: string;
  proposal: PlanProposal | null;
  applied_plan_id: string | null;
}

export class SupabaseCoachStore implements CoachStore {
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

  catalog(equipment: string[]): Promise<CatalogExercise[]> {
    return readCatalog(this.client, equipment);
  }

  activePlan(userId: string): Promise<CoachPlan | null> {
    return readActivePlan(this.client, userId);
  }

  async recentMessages(
    userId: string,
    limit: number,
  ): Promise<ChatHistoryMessage[]> {
    const { data, error } = await this.client
      .from("chat_messages")
      .select("id, role, content, proposal, applied_plan_id")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(limit);
    if (error) throw error;
    return (data as ChatMessageRow[]).reverse().map((row) => ({
      id: row.id,
      role: row.role,
      content: row.content,
      proposal: row.proposal,
      appliedPlanId: row.applied_plan_id,
    }));
  }

  saveUserMessage(userId: string, content: string): Promise<string> {
    return this.insert({ user_id: userId, role: "user", content });
  }

  saveAssistantMessage(
    userId: string,
    content: string,
    proposal: PlanProposal | null,
  ): Promise<string> {
    return this.insert({
      user_id: userId,
      role: "assistant",
      content,
      proposal,
    });
  }

  private async insert(row: Record<string, unknown>): Promise<string> {
    const { data, error } = await this.client
      .from("chat_messages")
      .insert(row)
      .select("id")
      .single();
    if (error) throw error;
    return (data as { id: string }).id;
  }
}
