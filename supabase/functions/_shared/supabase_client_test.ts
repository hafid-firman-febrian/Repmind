import { assertEquals } from "jsr:@std/assert@^1";
import { bearerToken } from "./supabase_client.ts";

function requestWith(authorization?: string): Request {
  const headers = new Headers();
  if (authorization !== undefined) headers.set("Authorization", authorization);
  return new Request("http://localhost/generate-plan", { headers });
}

Deno.test("bearerToken reads the token from the Authorization header", () => {
  assertEquals(bearerToken(requestWith("Bearer abc.def")), "abc.def");
  assertEquals(bearerToken(requestWith("bearer abc.def")), "abc.def");
});

Deno.test("bearerToken is null without a bearer token", () => {
  assertEquals(bearerToken(requestWith()), null);
  assertEquals(bearerToken(requestWith("Basic abc")), null);
});
