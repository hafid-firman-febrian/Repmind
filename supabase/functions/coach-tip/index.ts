import { requiredEnv } from "../_shared/env.ts";
import { GeminiJsonModel } from "../_shared/gemini.ts";
import { errorResponse } from "../_shared/http.ts";
import { bearerToken, createUserClient } from "../_shared/supabase_client.ts";
import { handleCoachTip } from "./handler.ts";
import { SupabaseTipStore } from "./store.ts";

Deno.serve(async (request) => {
  try {
    return await handleCoachTip(request, {
      store: new SupabaseTipStore(
        createUserClient(request),
        bearerToken(request),
      ),
      model: new GeminiJsonModel(requiredEnv("GEMINI_API_KEY")),
    });
  } catch (error) {
    console.error("coach-tip failed", error);
    return errorResponse(500, "internal_error");
  }
});
