import { afterEach, describe, expect, it, vi } from "vitest";
import { hogqlRows, posthogFetcher } from "../src/telemetry/fetchers/posthog";

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
