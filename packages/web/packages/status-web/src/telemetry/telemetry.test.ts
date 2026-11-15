// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach, beforeEach } from "vitest";
import type { StatusApiClient } from "../api/client";
import { emptySnapshot, type AnalyticsMetricDTO, type ErrorDTO, type TelemetrySnapshot } from "./types";
import { parseSnapshot, localCache } from "./stores/local-cache";
import { liveSource } from "./sources/live";
import { tursoSource } from "./sources/turso";
import { cache, source } from "./client";

type Fetch = StatusApiClient["fetch"];

function apiWith(fetchFn: (path: string, init?: RequestInit) => Promise<Response>): {
  api: StatusApiClient;
  fetch: ReturnType<typeof vi.fn>;
} {
  const fetch = vi.fn(fetchFn);
  return { api: { fetch: fetch as unknown as Fetch } as StatusApiClient, fetch };
}

const res = (status: number, body: unknown): Response => new Response(JSON.stringify(body), { status });

const KEY = "adh-telemetry-v1";

const err: ErrorDTO = {
  id: "1",
  issueKey: "1",
  project: "hub",
  title: "boom",
  culprit: null,
  level: "error",
  count: 3,
  userCount: 1,
  firstSeen: null,
  lastSeen: null,
  permalink: null,
};
const metric: AnalyticsMetricDTO = {
  metric: "pageviews",
  window: "24h",
  scope: "all",
  value: 10,
  capturedAt: "2026-06-13T12:00:00.000Z",
};
const snap: TelemetrySnapshot = { generatedAt: "2026-06-13T12:00:00.000Z", errors: [err], analytics: [metric] };

beforeEach(() => {
  window.localStorage.clear();
});

afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe("telemetry conformance", () => {
  it("telemetry-001 emptySnapshot returns a fresh empty snapshot each call", () => {
    const a = emptySnapshot();
    const b = emptySnapshot();
    expect(a).toEqual({ generatedAt: "", errors: [], analytics: [] });
    expect(b).toEqual({ generatedAt: "", errors: [], analytics: [] });
    expect(a).not.toBe(b);
    expect(a.errors).not.toBe(b.errors);
  });

  it("telemetry-002 parseSnapshot round-trips a stored snapshot", () => {
    expect(parseSnapshot(JSON.stringify(snap))).toEqual(snap);
  });

  it("telemetry-003 parseSnapshot returns null for null and empty string", () => {
    expect(parseSnapshot(null)).toBeNull();
    expect(parseSnapshot("")).toBeNull();
  });

  it("telemetry-004 parseSnapshot returns null for malformed JSON", () => {
    expect(parseSnapshot("{not json")).toBeNull();
  });

  it("telemetry-005 parseSnapshot rejects wrong-shape values", () => {
    expect(parseSnapshot(JSON.stringify(null))).toBeNull();
    expect(parseSnapshot(JSON.stringify({ generatedAt: "x" }))).toBeNull();
    expect(parseSnapshot(JSON.stringify({ generatedAt: 1, errors: [], analytics: [] }))).toBeNull();
    expect(parseSnapshot(JSON.stringify({ generatedAt: "x", errors: "nope", analytics: [] }))).toBeNull();
  });

  it("telemetry-006 parseSnapshot projects to the three known keys", () => {
    const out = parseSnapshot('{"generatedAt":"x","errors":[],"analytics":[],"extra":1}');
    expect(out).toEqual({ generatedAt: "x", errors: [], analytics: [] });
    expect(out).not.toHaveProperty("extra");
  });

  it("telemetry-007 localCache.load returns null without touching storage when window is undefined", () => {
    const getItem = vi.spyOn(window.localStorage, "getItem");
    vi.stubGlobal("window", undefined);
    expect(localCache.load()).toBeNull();
    expect(getItem).not.toHaveBeenCalled();
  });

  it("telemetry-008 localCache.save swallows a storage quota error", () => {
    vi.spyOn(window.localStorage, "setItem").mockImplementation(() => {
      throw new DOMException("quota", "QuotaExceededError");
    });
    expect(() => localCache.save(snap)).not.toThrow();
  });

  it("telemetry-009 liveSource.get makes one /telemetry fetch and resolves with the body", async () => {
    const { api, fetch } = apiWith(async () => res(200, snap));
    const out = await liveSource.get(api);
    expect(fetch).toHaveBeenCalledTimes(1);
    expect(fetch.mock.calls[0]![0]).toBe("/telemetry");
    expect(out).toEqual(snap);
  });

  it("telemetry-010 liveSource.get rejects with `telemetry 503` on a 503", async () => {
    const { api } = apiWith(async () => res(503, {}));
    const failure = await liveSource.get(api).then(
      () => null,
      (e: unknown) => e,
    );
    expect(failure).toBeInstanceOf(Error);
    expect((failure as Error).message).toBe("telemetry 503");
  });

  it("telemetry-011 tursoSource.get issues both fetches before either resolves, then projects the bodies", async () => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-09-24T12:00:00.000Z"));
    const pending: Array<(r: Response) => void> = [];
    const { api, fetch } = apiWith(() => new Promise<Response>((resolve) => pending.push(resolve)));
    const done = tursoSource.get(api);
    expect(fetch).toHaveBeenCalledTimes(2);
    expect(fetch.mock.calls.map((c) => c[0])).toEqual(["/errors", "/analytics"]);
    pending[0]!(res(200, { errors: [err] }));
    pending[1]!(res(200, { metrics: [metric] }));
    expect(await done).toEqual({
      generatedAt: "2026-09-24T12:00:00.000Z",
      errors: [err],
      analytics: [metric],
    });
  });

  it("telemetry-012 tursoSource.get rejects `errors 500` when both endpoints fail", async () => {
    const { api } = apiWith(async () => res(500, {}));
    await expect(tursoSource.get(api)).rejects.toThrow(/^errors 500$/);
  });

  it("telemetry-013 tursoSource.get rejects `analytics 502` when only /analytics fails", async () => {
    const { api } = apiWith(async (p) => (p === "/errors" ? res(200, { errors: [] }) : res(502, {})));
    await expect(tursoSource.get(api)).rejects.toThrow(/^analytics 502$/);
  });

  it("telemetry-014 the composition root binds cache to localCache and source to liveSource", () => {
    expect(cache).toBe(localCache);
    expect(source).toBe(liveSource);
  });

  // The Fetcher and Store ports are server-side only; no status-web module consumes a FetchResult.
  it.skip("telemetry-015 a consumer given { ok: false, items: [] } leaves its store unchanged", () => {
    // no consumer of FetchResult exists in status-web (store-port-server-only), so there is nothing to run
    expect(window.localStorage.getItem(KEY)).toBeNull();
  });
});
