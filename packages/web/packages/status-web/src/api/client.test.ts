import { afterEach, describe, expect, it, vi } from "vitest";
import { createStatusApiClient, errorMessage } from "./client";

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

describe("createStatusApiClient", () => {
  afterEach(() => vi.unstubAllGlobals());

  it("status-web-api-001 resolves undefined for a 204 without parsing a body", async () => {
    const jsonSpy = vi.fn();
    const response = { ok: true, status: 204, json: jsonSpy } as unknown as Response;
    const api = createStatusApiClient({ fetch: (async () => response) as typeof fetch });
    await expect(api.json("/x")).resolves.toBeUndefined();
    expect(jsonSpy).not.toHaveBeenCalled();
  });

  it("status-web-api-002 resolves the parsed body for a 200", async () => {
    const api = createStatusApiClient({ fetch: (async () => new Response(JSON.stringify({ a: 1 }), { status: 200 })) as typeof fetch });
    await expect(api.json("/x")).resolves.toEqual({ a: 1 });
  });

  it("status-web-api-005 url joins base path and path by concatenation", () => {
    const api = createStatusApiClient({ basePath: "/api" });
    expect(api.url("/config/peers")).toBe("/api/config/peers");
  });

  it("status-web-api-006 eventSource opens an EventSource at /api/live/stream by default", () => {
    const urls: string[] = [];
    class FakeEventSource {
      constructor(url: string) {
        urls.push(url);
      }
    }
    vi.stubGlobal("EventSource", FakeEventSource);
    const es = createStatusApiClient().eventSource("/live/stream");
    expect(es).toBeInstanceOf(FakeEventSource);
    expect(urls).toEqual(["/api/live/stream"]);
  });
});
