import type { AiModelKey } from "../_shared/ai_models.ts";
import type {
  CatalogExercise,
  CoachPlan,
  PlanProfile,
} from "../_shared/training.ts";

export interface ProposalChange {
  from_exercise_id: string;
  to_exercise_id: string;
  to_exercise_name: string;
  sets: number;
  reps: string;
  rest_seconds: number;
}

export interface PlanProposal {
  based_on_plan_id: string;
  ai_model: AiModelKey;
  day_number: number;
  summary: string;
  changes: ProposalChange[];
}

export interface ChatHistoryMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  proposal: PlanProposal | null;
  appliedPlanId: string | null;
}

export interface CoachStore {
  userId(): Promise<string | null>;
  profile(userId: string): Promise<PlanProfile | null>;
  catalog(equipment: string[]): Promise<CatalogExercise[]>;
  activePlan(userId: string): Promise<CoachPlan | null>;
  recentMessages(userId: string, limit: number): Promise<ChatHistoryMessage[]>;
  saveUserMessage(userId: string, content: string): Promise<string>;
  saveAssistantMessage(
    userId: string,
    content: string,
    proposal: PlanProposal | null,
  ): Promise<string>;
}
