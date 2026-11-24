import { describe, it, expect, vi } from "vitest";
import { createStatusApiClient } from "./api/client";
import { fetchStatusUser, STATUS_AUTH_QUERY_KEY } from "./header-auth";

// The auth/me semantics that keep a logged-in user logged in across backend
// hiccups: the backend never 401s that route (signed-out is a definitive 200
// { user: null }), so a non-OK response is INFRASTRUCTURE trouble and must throw —
// React Query then keeps the cached session and retries — never read as signed-out.
describe("fetchStatusUser", () => {
  const respond = (body: unknown, status = 200): typeof fetch =>
    (async () => Response.json(body as Record<string, unknown>, { status })) as unknown as typeof fetch;
  const api = createStatusApiClient();

  it("status-web-src-001 resolves the user from a definitive 200", async () => {
    const user = { email: "a@b.c", displayName: "A", role: "admin" as const };
    await expect(fetchStatusUser(api, respond({ user }))).resolves.toEqual(user);
  });

  it("status-web-src-002 resolves null from a definitive signed-out 200 { user: null }", async () => {
    await expect(fetchStatusUser(api, respond({ user: null }))).resolves.toBeNull();
  });

  it("status-web-src-003 THROWS on a 5xx (backend restart / starved proxy) instead of reading it as signed-out", async () => {
    await expect(fetchStatusUser(api, respond({}, 500))).rejects.toThrow(/^auth\/me unavailable \(HTTP 500\)$/);
  });

  it("status-web-src-004 propagates a network failure so the cached session is kept", async () => {
    const error = new TypeError("fetch failed");
    const failing = (async () => {
      throw error;
    }) as unknown as typeof fetch;
    const rejection = await fetchStatusUser(api, failing).catch((e: unknown) => e);
    expect(rejection).toBe(error);
    expect((rejection as Error).message).toBe("fetch failed");
  });

  it("status-web-src-005 reads an absent `user` as signed-out", async () => {
    await expect(fetchStatusUser(api, respond({}))).resolves.toBeNull();
  });

  it("status-web-src-006 a 401 is infrastructure trouble, never signed-out", async () => {
    await expect(fetchStatusUser(api, respond({ user: null }, 401))).rejects.toThrow(
      "auth/me unavailable (HTTP 401)",
    );
  });

  it("status-web-src-007 requests the client-resolved url through the transport with no options", async () => {
    const transport = vi.fn(async () => Response.json({ user: null }));
    const proxied = createStatusApiClient({ basePath: "/proxy" });
    await fetchStatusUser(proxied, transport as unknown as typeof fetch);
    expect(transport).toHaveBeenCalledTimes(1);
    expect(transport.mock.calls[0]).toEqual(["/proxy/auth/me"]);
  });

  it("status-web-src-008 propagates a body-parsing error from an OK response", async () => {
    const bad = (async () => new Response("not json {", { status: 200 })) as unknown as typeof fetch;
    await expect(fetchStatusUser(api, bad)).rejects.toBeInstanceOf(SyntaxError);
  });

  it("status-web-src-009 the session query key is the fixed pair", () => {
    expect(STATUS_AUTH_QUERY_KEY).toEqual(["status-auth-me"]);
  });
});
