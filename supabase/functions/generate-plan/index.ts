import { requiredEnv } from "../_shared/env.ts";
import { GeminiJsonModel } from "../_shared/gemini.ts";
import { errorResponse } from "../_shared/http.ts";
import { bearerToken, createUserClient } from "../_shared/supabase_client.ts";
import { handleGeneratePlan } from "./handler.ts";
import { SupabasePlanStore } from "./store.ts";

Deno.serve(async (request) => {
  try {
    return await handleGeneratePlan(request, {
      store: new SupabasePlanStore(
        createUserClient(request),
        bearerToken(request),
      ),
      model: new GeminiJsonModel(requiredEnv("GEMINI_API_KEY")),
    });
  } catch (error) {
    console.error("generate-plan failed", error);
    return errorResponse(500, "internal_error");
  }
});
