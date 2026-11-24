// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import type { StatusApiClient } from "../../api/client";
import { liveSource } from "./live";
import { tursoSource } from "./turso";
import { source } from "../client";

type Fetch = StatusApiClient["fetch"];

function apiWith(fetchFn: (path: string, init?: RequestInit) => Promise<Response>): {
  api: StatusApiClient;
  fetch: ReturnType<typeof vi.fn>;
} {
  const fetch = vi.fn(fetchFn);
  return { api: { fetch: fetch as unknown as Fetch } as StatusApiClient, fetch };
}

const res = (status: number, body: unknown) => new Response(JSON.stringify(body), { status });
const raw = (status: number, body: string) => new Response(body, { status });

const E = { id: "e1", message: "boom" };
const M = { name: "visits", value: 3 };

afterEach(() => {
  vi.useRealTimers();
});

describe("liveSource", () => {
  it("sources-001 issues exactly one request to /telemetry with no options", async () => {
    const { api, fetch } = apiWith(async () => res(200, { generatedAt: "x", errors: [], analytics: [] }));
    await liveSource.get(api);
    expect(fetch).toHaveBeenCalledTimes(1);
    expect(fetch.mock.calls[0]).toEqual(["/telemetry"]);
  });

  it("sources-002 resolves to the parsed body unchanged", async () => {
    const body = { generatedAt: "2026-09-24T00:00:00Z", errors: [], analytics: [] };
    const { api } = apiWith(async () => res(200, body));
    const snap = await liveSource.get(api);
    expect(snap).toEqual(body);
    expect(snap.generatedAt).toBe("2026-09-24T00:00:00Z");
  });

  it("sources-003 rejects `telemetry 503` without reading the body", async () => {
    const r = res(503, { error: "down" });
    const json = vi.spyOn(r, "json");
    const { api } = apiWith(async () => r);
    await expect(liveSource.get(api)).rejects.toThrow(/^telemetry 503$/);
    expect(json).not.toHaveBeenCalled();
  });

  it("sources-004 rejects with the network error itself", async () => {
    const boom = new TypeError("Failed to fetch");
    const { api } = apiWith(() => Promise.reject(boom));
    await expect(liveSource.get(api)).rejects.toBe(boom);
  });

  it("sources-005 rejects with the JSON parse error for a 200 non-JSON body", async () => {
    const { api } = apiWith(async () => raw(200, "not json"));
    await expect(liveSource.get(api)).rejects.toBeInstanceOf(SyntaxError);
  });

  it("sources-014 is stateless: two gets make two requests and two distinct snapshots", async () => {
    const { api, fetch } = apiWith(async () => res(200, { generatedAt: "x", errors: [], analytics: [] }));
    const a = await liveSource.get(api);
    const b = await liveSource.get(api);
    expect(fetch).toHaveBeenCalledTimes(2);
    expect(fetch.mock.calls.map((c) => c[0])).toEqual(["/telemetry", "/telemetry"]);
    expect(a).not.toBe(b);
  });

  it("sources-015 does not retry a failed request", async () => {
    const { api, fetch } = apiWith(async () => res(500, {}));
    await expect(liveSource.get(api)).rejects.toThrow("telemetry 500");
    expect(fetch).toHaveBeenCalledTimes(1);
  });
});

describe("tursoSource", () => {
  it("sources-006 starts /errors and /analytics before either resolves", async () => {
    const { api, fetch } = apiWith(() => new Promise<Response>(() => {}));
    void tursoSource.get(api);
    expect(fetch).toHaveBeenCalledTimes(2);
    expect(fetch.mock.calls.map((c) => c[0])).toEqual(["/errors", "/analytics"]);
    expect(fetch.mock.calls.every((c) => c.length === 1)).toBe(true);
  });

  it("sources-007 projects errors and metrics into exactly generatedAt, errors, analytics", async () => {
    const { api } = apiWith(async (p) => (p === "/errors" ? res(200, { errors: [E], extra: 1 }) : res(200, { metrics: [M] })));
    const snap = await tursoSource.get(api);
    expect(Object.keys(snap).sort()).toEqual(["analytics", "errors", "generatedAt"]);
    expect(snap.errors).toEqual([E]);
    expect(snap.analytics).toEqual([M]);
    expect("extra" in snap).toBe(false);
    expect("metrics" in snap).toBe(false);
  });

  it("sources-008 stamps generatedAt from the client clock", async () => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-09-24T12:00:00.000Z"));
    const { api } = apiWith(async (p) => (p === "/errors" ? res(200, { errors: [] }) : res(200, { metrics: [] })));
    const snap = await tursoSource.get(api);
    expect(snap.generatedAt).toBe("2026-09-24T12:00:00.000Z");
  });

  it("sources-009 rejects `errors 500` when /errors fails", async () => {
    const { api } = apiWith(async (p) => (p === "/errors" ? res(500, {}) : res(200, { metrics: [] })));
    await expect(tursoSource.get(api)).rejects.toThrow(/^errors 500$/);
  });

  it("sources-010 rejects `analytics 404` when only /analytics fails", async () => {
    const { api } = apiWith(async (p) => (p === "/errors" ? res(200, { errors: [] }) : res(404, {})));
    await expect(tursoSource.get(api)).rejects.toThrow(/^analytics 404$/);
  });

  it("sources-011 reports the /errors status when both fail", async () => {
    const { api } = apiWith(async (p) => (p === "/errors" ? res(502, {}) : res(503, {})));
    await expect(tursoSource.get(api)).rejects.toThrow(/^errors 502$/);
  });

  it("sources-012 rejects with the network error while /errors is pending, with no status message", async () => {
    const boom = new TypeError("Failed to fetch");
    const { api } = apiWith((p) => (p === "/errors" ? new Promise<Response>(() => {}) : Promise.reject(boom)));
    await expect(tursoSource.get(api)).rejects.toBe(boom);
  });

  it("sources-013 parses /errors first and never parses /analytics when /errors is invalid JSON", async () => {
    const analytics = res(200, { metrics: [M] });
    const analyticsJson = vi.spyOn(analytics, "json");
    const { api } = apiWith(async (p) => (p === "/errors" ? raw(200, "not json") : analytics));
    await expect(tursoSource.get(api)).rejects.toBeInstanceOf(SyntaxError);
    expect(analyticsJson).not.toHaveBeenCalled();
  });
});

describe("composition root", () => {
  it("sources-016 exports the live source as the active source", () => {
    expect(source).toBe(liveSource);
    expect(source).not.toBe(tursoSource);
  });
});
