// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach, beforeEach } from "vitest";
import { cleanup, render, renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactElement, ReactNode } from "react";
import { TELEMETRY_POLL_MS, useTelemetry } from "./use-telemetry";
import { StatusApiProvider, createStatusApiClient } from "../api/client";
import { parseSnapshot } from "../telemetry/stores/local-cache";
import { emptySnapshot, type TelemetrySnapshot } from "../telemetry/types";

const KEY = "adh-telemetry-v1";
const snap = (generatedAt: string): TelemetrySnapshot => ({ generatedAt, errors: [], analytics: [] });
const A = snap("A");
const B = snap("B");
type Transport = (url: string, init?: RequestInit) => Promise<Response>;
const mockFetch = (impl: Transport) => vi.fn(impl as unknown as typeof fetch);
const json = (body: unknown, status = 200) => async (): Promise<Response> => Response.json(body, { status });
const never = (): Promise<Response> => new Promise<Response>(() => {});

function wrapperFor(qc: QueryClient, transport: typeof fetch, basePath?: string) {
  const api = createStatusApiClient({ fetch: transport, ...(basePath ? { basePath } : {}) });
  return function Wrap({ children }: { children: ReactNode }): ReactElement {
    return (
      <QueryClientProvider client={qc}>
        <StatusApiProvider client={api}>{children}</StatusApiProvider>
      </QueryClientProvider>
    );
  };
}
function mount(transport: typeof fetch, qc = new QueryClient(), basePath?: string) {
  const all: TelemetrySnapshot[] = [];
  const view = renderHook(
    () => {
      const v = useTelemetry();
      all.push(v);
      return v;
    },
    { wrapper: wrapperFor(qc, transport, basePath) },
  );
  return { ...view, all, qc };
}

beforeEach(() => localStorage.clear());
afterEach(() => {
  cleanup();
  vi.useRealTimers();
  vi.restoreAllMocks();
  localStorage.clear();
});

describe("useTelemetry", () => {
  it("telemetry-001 exports a 60 s poll interval", () => {
    expect(TELEMETRY_POLL_MS).toBe(60000);
  });

  it("telemetry-002 first render is the empty snapshot while the source never resolves", () => {
    const { result, all } = mount(mockFetch(never));
    expect(all[0]).toEqual({ generatedAt: "", errors: [], analytics: [] });
    expect(result.current).toEqual({ generatedAt: "", errors: [], analytics: [] });
  });

  it("telemetry-003 hydrates the cached snapshot after mount", () => {
    localStorage.setItem(KEY, JSON.stringify(A));
    const { result, all } = mount(mockFetch(never));
    expect(all[0]).toEqual(emptySnapshot());
    expect(result.current).toEqual(A);
  });

  it("telemetry-004 live data wins over the cache and is persisted", async () => {
    localStorage.setItem(KEY, JSON.stringify(A));
    const { result } = mount(mockFetch(json(B)));
    await waitFor(() => expect(result.current).toEqual(B));
    expect(localStorage.getItem(KEY)).toBe(JSON.stringify(B));
  });

  it("telemetry-005 requests /telemetry under the configured base path with no extra options", async () => {
    const f = mockFetch(json(B));
    const { result } = mount(f, new QueryClient(), "/x");
    await waitFor(() => expect(result.current).toEqual(B));
    expect(f).toHaveBeenCalledTimes(1);
    expect(f.mock.calls[0]![0]).toBe("/x/telemetry");
    expect(f.mock.calls[0]![1]).toBeUndefined();
  });

  it("telemetry-006 retries once on a 502, keeps the cached snapshot and does not overwrite it", async () => {
    localStorage.setItem(KEY, JSON.stringify(A));
    const f = mockFetch(json({}, 502));
    const qc = new QueryClient();
    const { result } = mount(f, qc);
    await waitFor(() => expect(qc.getQueryState(["telemetry"])?.status).toBe("error"), { timeout: 5000 });
    expect(f).toHaveBeenCalledTimes(2);
    expect((qc.getQueryState(["telemetry"])?.error as Error).message).toBe("telemetry 502");
    expect(result.current).toEqual(A);
    expect(localStorage.getItem(KEY)).toBe(JSON.stringify(A));
  });

  it("telemetry-007 keeps the last good data when a later poll fails", async () => {
    let calls = 0;
    const f = mockFetch(async () => (++calls === 1 ? Response.json(B) : Response.json({}, { status: 500 })));
    const qc = new QueryClient();
    const { result } = mount(f, qc);
    await waitFor(() => expect(result.current).toEqual(B));
    await qc.refetchQueries({ queryKey: ["telemetry"] });
    expect(calls).toBe(3);
    expect(qc.getQueryState(["telemetry"])?.status).toBe("error");
    expect(result.current).toEqual(B);
  }, 10_000);

  it("telemetry-008 parse returns null for null and an empty string", () => {
    expect(parseSnapshot(null)).toBeNull();
    expect(parseSnapshot("")).toBeNull();
  });

  it("telemetry-009 parse returns null for malformed JSON", () => {
    expect(parseSnapshot("{not json")).toBeNull();
  });

  it("telemetry-010 parse returns null for wrong shapes", () => {
    for (const v of [null, { generatedAt: "x" }, { generatedAt: 1, errors: [], analytics: [] }, { generatedAt: "x", errors: "nope", analytics: [] }]) {
      expect(parseSnapshot(JSON.stringify(v))).toBeNull();
    }
  });

  it("telemetry-011 parse round-trips a snapshot with an error and a metric", () => {
    const full: TelemetrySnapshot = {
      generatedAt: "2026-01-01T00:00:00Z",
      errors: [
        { id: "1", issueKey: "1", project: "p", title: "t", culprit: null, level: "error", count: 2, userCount: 1, firstSeen: null, lastSeen: null, permalink: null },
      ],
      analytics: [{ metric: "pageviews", window: "24h", scope: "all", value: 3, capturedAt: "2026-01-01T00:00:00Z" }],
    };
    expect(parseSnapshot(JSON.stringify(full))).toEqual(full);
  });

  it("telemetry-012 parse drops unknown keys", () => {
    const out = parseSnapshot('{"generatedAt":"t","errors":[],"analytics":[],"extra":1}');
    expect(out).toEqual({ generatedAt: "t", errors: [], analytics: [] });
    expect(out).not.toHaveProperty("extra");
  });

  it("telemetry-013 a throwing cache write never reaches the consumer", async () => {
    vi.spyOn(localStorage, "setItem").mockImplementation(() => {
      throw new Error("QuotaExceededError");
    });
    const { result } = mount(mockFetch(json(B)));
    await waitFor(() => expect(result.current).toEqual(B));
  });

  it("telemetry-014 a throwing cache read leaves the empty snapshot", () => {
    vi.spyOn(localStorage, "getItem").mockImplementation(() => {
      throw new Error("blocked");
    });
    const { result } = mount(mockFetch(never));
    expect(result.current).toEqual(emptySnapshot());
  });

  it("telemetry-015 two consumers share one fetch but each write the cache", async () => {
    const f = mockFetch(json(B));
    const setItem = vi.spyOn(localStorage, "setItem");
    const qc = new QueryClient();
    const seen: TelemetrySnapshot[][] = [[], []];
    const Probe = ({ i }: { i: number }): null => {
      seen[i]!.push(useTelemetry());
      return null;
    };
    const Wrap = wrapperFor(qc, f);
    render(
      <Wrap>
        <Probe i={0} />
        <Probe i={1} />
      </Wrap>,
    );
    await waitFor(() => {
      expect(seen[0]!.at(-1)).toEqual(B);
      expect(seen[1]!.at(-1)).toEqual(B);
    });
    expect(f).toHaveBeenCalledTimes(1);
    const writes = setItem.mock.calls.filter((c) => c[0] === KEY);
    expect(writes).toHaveLength(2);
    expect(writes[0]![1]).toBe(writes[1]![1]);
  });

  it("telemetry-016 polls again after 60 s", async () => {
    vi.useFakeTimers();
    const f = mockFetch(json(B));
    mount(f);
    await vi.advanceTimersByTimeAsync(0);
    expect(f).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(TELEMETRY_POLL_MS);
    expect(f).toHaveBeenCalledTimes(2);
  });

  it("telemetry-017 the empty snapshot is a fresh object each time", () => {
    const a = emptySnapshot();
    const b = emptySnapshot();
    expect(a).not.toBe(b);
    expect(a).toEqual({ generatedAt: "", errors: [], analytics: [] });
    expect(b).toEqual({ generatedAt: "", errors: [], analytics: [] });
  });

  it.skip("telemetry-018 is unavailable in a server-only rendering context (jsdom cannot host a server component boundary)", () => {});
});
