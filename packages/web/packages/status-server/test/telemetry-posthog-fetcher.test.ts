import { afterEach, describe, expect, it, vi } from "vitest";
import { attachHogqlLockState, hogqlLockState, hogqlRows, posthogFetcher, toMetricValue } from "../src/telemetry/fetchers/posthog";

const ENV = { POSTHOG_HOST: "https://ph.example/", POSTHOG_API_KEY: "k", POSTHOG_PROJECT_ID: "7" };

function stubFetch(body: unknown, init: { status?: number } = {}) {
  const calls: { url: string; body: { query: { query: string } } }[] = [];
  vi.stubGlobal("fetch", async (url: string, req: { body: string }) => {
    calls.push({ url, body: JSON.parse(req.body) });
    const status = init.status ?? 200;
    return { ok: status < 400, status, json: async () => body };
  });
  return calls;
}

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("posthogFetcher", () => {
  it("no-ops green when unconfigured", async () => {
    expect(await posthogFetcher({}).fetch()).toEqual({ ok: true, items: [] });
  });

  // Four sequential queries on a 10s timeout each is what logged `0/4 queries answered`.
  it("gets all four KPIs from ONE query", async () => {
    const calls = stubFetch({ results: [[96, 90, 868, "833"]] });
    const r = await posthogFetcher(ENV).fetch();
    expect(calls).toHaveLength(1);
    expect(calls[0]!.url).toBe("https://ph.example/api/projects/7/query/");
    expect(r.ok).toBe(true);
    expect(r.items.map((m) => [m.metric, m.window, m.value])).toEqual([
      ["pageviews", "24h", 96],
      ["visitors", "24h", 90],
      ["pageviews", "7d", 868],
      ["visitors", "7d", 833],
    ]);
  });

  it("an HTTP error is a failed poll, so good trend data is never overwritten", async () => {
    vi.spyOn(console, "warn").mockImplementation(() => {});
    stubFetch({}, { status: 504 });
    expect(await posthogFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
  });

  it("a row with no usable values is a failed poll", async () => {
    stubFetch({ results: [[null, null, null, null]] });
    expect(await posthogFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
  });
});

describe("hogqlRows", () => {
  it("returns every row", async () => {
    stubFetch({ results: [["a", 1], ["b", 2]] });
    expect(await hogqlRows(ENV, "SELECT 1", 1000)).toEqual({ ok: true, rows: [["a", 1], ["b", 2]] });
  });

  it("reports a body with no results as an error", async () => {
    stubFetch({ detail: "nope" });
    expect(await hogqlRows(ENV, "SELECT 1", 1000)).toMatchObject({ ok: false });
  });

  it("reports a thrown fetch as an error", async () => {
    vi.stubGlobal("fetch", async () => {
      throw new Error("ECONNRESET");
    });
    expect(await hogqlRows(ENV, "SELECT 1", 1000)).toEqual({ ok: false, error: "ECONNRESET" });
  });

  it("refuses to query when unconfigured", async () => {
    expect(await hogqlRows({}, "SELECT 1", 1000)).toMatchObject({ ok: false });
  });
});

// One test per row of the recipe's conformance-test-vectors.md (status/service/telemetry/fetchers).
describe("conformance vectors — posthog", () => {
  const warn = () => vi.spyOn(console, "warn").mockImplementation(() => {});
  const initialLease = hogqlLockState();

  afterEach(() => {
    vi.useRealTimers();
    attachHogqlLockState(initialLease);
  });

  it("status-server-fetchers-010 unconfigured makes no request", async () => {
    const calls = stubFetch({ results: [[1]] });
    expect(await posthogFetcher({}).fetch()).toEqual({ ok: true, items: [] });
    expect(await posthogFetcher({ ...ENV, POSTHOG_API_KEY: undefined }).fetch()).toEqual({ ok: true, items: [] });
    expect(calls).toEqual([]);
  });

  it("status-server-fetchers-011 one POST carries the single KPI query", async () => {
    const seen: { url: string; init: { method: string; headers: Record<string, string>; body: string } }[] = [];
    vi.stubGlobal("fetch", async (url: string, init: { method: string; headers: Record<string, string>; body: string }) => {
      seen.push({ url, init });
      return { ok: true, status: 200, json: async () => ({ results: [[1, 2, 3, 4]] }) };
    });
    await posthogFetcher(ENV).fetch();
    expect(seen).toHaveLength(1);
    const { url, init } = seen[0]!;
    expect(url).toBe("https://ph.example/api/projects/7/query/");
    expect(init.method).toBe("POST");
    expect(init.headers).toEqual({ Authorization: "Bearer k", "Content-Type": "application/json" });
    const q = (JSON.parse(init.body) as { query: { kind: string; query: string } }).query;
    expect(q.kind).toBe("HogQLQuery");
    expect(q.query).toContain("countIf(timestamp > now() - INTERVAL 1 DAY)");
    expect(q.query).toContain("uniqIf(person_id, timestamp > now() - INTERVAL 1 DAY)");
    expect(q.query).toContain("event = '$pageview'");
    expect(q.query).toContain("INTERVAL 7 DAY");
  });

  it("status-server-fetchers-012 the query is aborted at 20,000ms", async () => {
    vi.useFakeTimers();
    const w = warn();
    let signal: AbortSignal | undefined;
    vi.stubGlobal("fetch", (_url: string, init: { signal: AbortSignal }) => {
      signal = init.signal;
      return new Promise((_resolve, reject) => {
        init.signal.addEventListener("abort", () => reject(new Error("The operation was aborted")));
      });
    });
    const pending = posthogFetcher(ENV).fetch();
    await vi.advanceTimersByTimeAsync(19_999);
    expect(signal!.aborted).toBe(false);
    await vi.advanceTimersByTimeAsync(1);
    expect(signal!.aborted).toBe(true);
    expect(await pending).toEqual({ ok: false, items: [] });
    expect(w).toHaveBeenCalledWith(expect.stringContaining("PostHog poll failed (The operation was aborted)"));
  });

  it("status-server-fetchers-013 queries run one at a time, in call order", async () => {
    const order: string[] = [];
    let inFlight = 0;
    let maxInFlight = 0;
    vi.stubGlobal("fetch", async (_url: string, req: { body: string }) => {
      const q = (JSON.parse(req.body) as { query: { query: string } }).query.query;
      order.push(`start ${q}`);
      inFlight += 1;
      maxInFlight = Math.max(maxInFlight, inFlight);
      await new Promise((r) => setTimeout(r, 20));
      inFlight -= 1;
      order.push(`end ${q}`);
      return { ok: true, status: 200, json: async () => ({ results: [[1]] }) };
    });
    await Promise.all([hogqlRows(ENV, "A", 1000), hogqlRows(ENV, "B", 1000), hogqlRows(ENV, "C", 1000)]);
    expect(order).toEqual(["start A", "end A", "start B", "end B", "start C", "end C"]);
    expect(maxInFlight).toBe(1);
  });

  it("status-server-fetchers-014 an HTTP failure fails the poll with one warning", async () => {
    const w = warn();
    stubFetch({}, { status: 503 });
    expect(await posthogFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
    expect(w).toHaveBeenCalledTimes(1);
    expect(w).toHaveBeenCalledWith(expect.stringContaining("PostHog poll failed (HTTP 503)"));
  });

  it("status-server-fetchers-015 a row with no usable value fails the poll", async () => {
    warn();
    stubFetch({ results: [[null, "abc", "", undefined]] });
    expect(await posthogFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
    stubFetch({ results: [] });
    expect(await posthogFetcher(ENV).fetch()).toEqual({ ok: false, items: [] });
  });

  it("status-server-fetchers-016 values coerce from numbers and numeric strings; others are skipped", async () => {
    stubFetch({ results: [["42", "abc", 0, null]] });
    const r = await posthogFetcher(ENV).fetch();
    expect(r.ok).toBe(true);
    expect(r.items.map((m) => [m.metric, m.window, m.value])).toEqual([
      ["pageviews", "24h", 42],
      ["pageviews", "7d", 0],
    ]);
    expect(toMetricValue("42")).toBe(42);
    expect(toMetricValue("abc")).toBeNull();
    expect(toMetricValue(Number.POSITIVE_INFINITY)).toBeNull();
  });

  it("status-server-fetchers-017 one capturedAt per batch and scope all", async () => {
    stubFetch({ results: [[1, 2, 3, 4]] });
    const r = await posthogFetcher(ENV).fetch();
    expect(r.items).toHaveLength(4);
    expect(new Set(r.items.map((m) => m.capturedAt)).size).toBe(1);
    expect(r.items[0]!.capturedAt).toBe(new Date(r.items[0]!.capturedAt).toISOString());
    expect(r.items.every((m) => m.scope === "all")).toBe(true);
  });

  it("status-server-fetchers-018 a result never carries a complete key", async () => {
    stubFetch({ results: [[1, 2, 3, 4]] });
    const r = await posthogFetcher(ENV).fetch();
    expect("complete" in r).toBe(false);
    expect("complete" in (await posthogFetcher({}).fetch())).toBe(false);
  });

  it("status-server-fetchers-025 hogqlRows posts to the host with trailing slashes stripped and returns rows", async () => {
    const calls = stubFetch({ results: [["a", 1]] });
    expect(await hogqlRows({ ...ENV, POSTHOG_HOST: "https://ph.example///" }, "SELECT 1", 1000)).toEqual({
      ok: true,
      rows: [["a", 1]],
    });
    expect(calls[0]!.url).toBe("https://ph.example/api/projects/7/query/");
    expect(calls[0]!.body).toEqual({ query: { kind: "HogQLQuery", query: "SELECT 1" } });
  });

  it("status-server-fetchers-026 hogqlRows returns, not throws, each failure", async () => {
    expect(await hogqlRows({}, "SELECT 1", 1000)).toEqual({ ok: false, error: "PostHog is not configured" });
    stubFetch({}, { status: 500 });
    expect(await hogqlRows(ENV, "SELECT 1", 1000)).toEqual({ ok: false, error: "HTTP 500" });
    stubFetch({ detail: "nope" });
    expect(await hogqlRows(ENV, "SELECT 1", 1000)).toEqual({ ok: false, error: "response had no results" });
    vi.stubGlobal("fetch", async () => {
      throw new Error("ECONNRESET");
    });
    expect(await hogqlRows(ENV, "SELECT 1", 1000)).toEqual({ ok: false, error: "ECONNRESET" });
  });

  it("status-server-fetchers-027 a query waits for a lease held on another thread, then runs once it lapses", async () => {
    vi.useFakeTimers();
    const shared = new SharedArrayBuffer(8);
    new BigInt64Array(shared)[0] = BigInt(Date.now() + 500);
    attachHogqlLockState(shared);
    attachHogqlLockState(undefined);
    expect(hogqlLockState()).toBe(shared);
    const calls = stubFetch({ results: [[1]] });
    const pending = hogqlRows(ENV, "SELECT 1", 1000);
    await vi.advanceTimersByTimeAsync(300);
    expect(calls).toHaveLength(0);
    await vi.advanceTimersByTimeAsync(300);
    expect(await pending).toMatchObject({ ok: true });
    expect(calls).toHaveLength(1);
    expect(new BigInt64Array(shared)[0]).toBe(0n);
  });
});
