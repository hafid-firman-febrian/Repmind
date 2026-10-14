import { assertEquals } from "jsr:@std/assert@^1";
import { AI_MODELS, isAiModelKey } from "./ai_models.ts";

Deno.test("the allowlist matches the ai_model enum in the database", () => {
  assertEquals(Object.keys(AI_MODELS).sort(), [
    "gemini_flash",
    "gemini_flash_lite",
    "gemini_pro",
  ]);
});

Deno.test("each key maps to a Gemini model id", () => {
  assertEquals(AI_MODELS.gemini_flash.id, "gemini-3.8-flash");
  assertEquals(AI_MODELS.gemini_flash_lite.id, "gemini-3.5-flash-lite");
  assertEquals(AI_MODELS.gemini_pro.id, "gemini-3.1-pro-preview");
});

Deno.test("isAiModelKey only accepts allowlisted keys", () => {
  assertEquals(isAiModelKey("gemini_flash"), true);
  assertEquals(isAiModelKey("gpt-5"), false);
  assertEquals(isAiModelKey("toString"), false);
});
