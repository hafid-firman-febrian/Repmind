import { assertEquals } from "jsr:@std/assert@^1";
import { errorResponse, jsonResponse } from "./http.ts";

Deno.test("jsonResponse serializes the body with a JSON content type", async () => {
  const response = jsonResponse(200, { plan_id: "plan-1" });
  assertEquals(response.status, 200);
  assertEquals(response.headers.get("Content-Type"), "application/json");
  assertEquals(await response.json(), { plan_id: "plan-1" });
});

Deno.test("errorResponse wraps the code", async () => {
  const response = errorResponse(409, "profile_incomplete");
  assertEquals(response.status, 409);
  assertEquals(await response.json(), { error: "profile_incomplete" });
});
