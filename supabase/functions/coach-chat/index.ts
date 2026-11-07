import { requiredEnv } from "../_shared/env.ts";
import { GeminiChatModel } from "../_shared/gemini.ts";
import { errorResponse } from "../_shared/http.ts";
import { bearerToken, createUserClient } from "../_shared/supabase_client.ts";
import { handleCoachChat } from "./handler.ts";
import { SupabaseCoachStore } from "./store.ts";

Deno.serve(async (request) => {
  try {
    return await handleCoachChat(request, {
      store: new SupabaseCoachStore(
        createUserClient(request),
        bearerToken(request),
      ),
      model: new GeminiChatModel(requiredEnv("GEMINI_API_KEY")),
    });
  } catch (error) {
    console.error("coach-chat failed", error);
    return errorResponse(500, "internal_error");
  }
});
