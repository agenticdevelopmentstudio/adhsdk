import { describe, expect, it } from "vitest";
import { errorMessage } from "./client";

const res = (body: unknown): Response => new Response(typeof body === "string" ? body : JSON.stringify(body), { status: 500 });

describe("errorMessage", () => {
  // The backend's error handler (and requireAuth's 401) nest the message; a route's own c.json does not.
  it("reads the nested shape the error handler sends", async () => {
    expect(await errorMessage(res({ error: { message: "Unauthorized" } }))).toBe("Unauthorized");
  });

  it("reads a route's flat error", async () => {
    expect(await errorMessage(res({ error: "invalid range" }))).toBe("invalid range");
  });

  it("is null for a body with no message, or no JSON at all", async () => {
    expect(await errorMessage(res({ error: {} }))).toBeNull();
    expect(await errorMessage(res("<html>Bad Gateway</html>"))).toBeNull();
  });
});
