import { afterEach, describe, expect, it, vi } from "vitest";
import { _resetProviderCooldowns, noteRateLimited } from "@agentic-toolkit/deploy-platform/cooldown";
import { alignToBuckets, rangeWindow } from "../src/telemetry/dashboard/ranges";
import { loadTraffic, shapeDimensions, shapeHealth, shapeTraffic, shapeVitals } from "../src/telemetry/dashboard/posthog-sections";
import { analyticsEnabled, loadVercelTraffic, productionDomain, shapeMarginal } from "../src/telemetry/dashboard/vercel-section";
import { isActiveIssue, summarizeIssues, toErrorIssues } from "../src/telemetry/dashboard/errors-sections";

const NOW = Date.parse("2026-11-04T15:30:20.000Z");
const HOUR = 3_600_000;

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  _resetProviderCooldowns();
});

describe("rangeWindow", () => {
  it("24h is 25 hourly buckets ending in the current hour", () => {
    const w = rangeWindow("24h", NOW);
    expect(w.unit).toBe("hour");
    expect(w.buckets).toHaveLength(25);
    expect(w.buckets[0]).toBe("2026-11-03T15:00:00.000Z");
    expect(w.buckets.at(-1)).toBe("2026-11-04T15:00:00.000Z");
  });

  it("7d and 30d are that many UTC days including today", () => {
    const w = rangeWindow("7d", NOW);
    expect(w.unit).toBe("day");
    expect(w.buckets).toHaveLength(7);
    expect(w.buckets[0]).toBe("2026-10-29T00:00:00.000Z");
    expect(w.buckets.at(-1)).toBe("2026-11-04T00:00:00.000Z");
    expect(rangeWindow("30d", NOW).buckets).toHaveLength(30);
  });
});

describe("alignToBuckets", () => {
  const buckets = ["2026-11-03T00:00:00.000Z", "2026-11-04T00:00:00.000Z"];

  it("zero-fills, tolerates either timestamp spelling, and sums repeats", () => {
    expect(alignToBuckets(buckets, [["2026-11-04T00:00:00Z", 2], ["2026-11-04T00:00:00.000Z", 3]])).toEqual([0, 5]);
  });

  it("drops what is off the axis or unparseable", () => {
    expect(alignToBuckets(buckets, [["2026-01-01T00:00:00Z", 9], ["nope", 9], [null, 9]])).toEqual([0, 0]);
  });
});

describe("PostHog shapers", () => {
  const buckets = ["2026-11-03T00:00:00.000Z", "2026-11-04T00:00:00.000Z"];

  it("shapeTraffic rolls up per site and overall, biggest site first", () => {
    const t = shapeTraffic(
      [
        ["a.com", "2026-11-03T00:00:00Z", 1, 1],
        ["b.com", "2026-11-03T00:00:00Z", 2, 2],
        ["b.com", "2026-11-04T00:00:00Z", "3", "1"],
      ],
      buckets,
    );
    expect(t.totals).toEqual({ pageviews: 6, sessions: 4 });
    expect(t.pageviews).toEqual([3, 3]);
    expect(t.sites.map((s) => [s.host, s.pageviews, s.series])).toEqual([
      ["b.com", 5, [2, 3]],
      ["a.com", 1, [1, 0]],
    ]);
  });

  it("shapeDimensions labels blanks and says when the row cap was hit", () => {
    const d = shapeDimensions([["a.com", null, "", "US", null, 4]], 1);
    expect(d.rows[0]).toEqual({ host: "a.com", device: "Unknown", browser: "Unknown", country: "US", referrer: "$direct", pageviews: 4 });
    expect(d.truncated).toBe(true);
    expect(shapeDimensions([], 1).truncated).toBe(false);
  });

  it("shapeVitals keeps a vital with no samples as null, not zero", () => {
    expect(shapeVitals([["a.com", 3, 1200, null, "0.1", 800]])[0]).toEqual({ host: "a.com", samples: 3, lcp: 1200, inp: null, cls: 0.1, fcp: 800 });
  });

  it("shapeHealth", () => {
    expect(shapeHealth([["a.com", 1, 100, 2, null]])[0]).toEqual({ host: "a.com", errors: 1, requests: 100, failures: 2, p95Ms: null });
  });

  it("a failed query fails the section rather than reading as no traffic", async () => {
    vi.stubGlobal("fetch", async () => ({ ok: false, status: 504, json: async () => ({}) }));
    await expect(
      loadTraffic({ POSTHOG_HOST: "https://ph", POSTHOG_API_KEY: "k", POSTHOG_PROJECT_ID: "1" }, "production", rangeWindow("7d", NOW)),
    ).rejects.toThrow("HTTP 504");
  });
});

describe("Vercel section", () => {
  const ENV = { VERCEL_API_TOKEN: "t", VERCEL_TEAM_ID: "team" };
  const w = rangeWindow("7d", NOW);

  it("only a project with analytics on, and not since disabled, counts", () => {
    expect(analyticsEnabled({ webAnalytics: { enabledAt: 1 } })).toBe(true);
    expect(analyticsEnabled({ webAnalytics: { enabledAt: 1, disabledAt: 2 } })).toBe(false);
    expect(analyticsEnabled({})).toBe(false);
  });

  it("the domain is the first alias that isn't a vercel.app one", () => {
    expect(productionDomain({ targets: { production: { alias: ["x.vercel.app", "x.com"] } } })).toBe("x.com");
    expect(productionDomain({ targets: { production: { alias: ["x.vercel.app"] } } })).toBeNull();
  });

  it("shapeMarginal drops Vercel's Others rollup, which is no value of the dimension", () => {
    expect(shapeMarginal([{ requestPath: "Others", pageviews: 9 }, { requestPath: "/a", pageviews: 1 }], "requestPath")).toEqual([
      { name: "/a", pageviews: 1 },
    ]);
  });

  it("shapeMarginal reads the value from the `by` column", () => {
    expect(shapeMarginal([{ country: "US", pageviews: 1 }, { country: "FR", pageviews: 2 }, { pageviews: 3 }], "country")).toEqual([
      { name: "(none)", pageviews: 3 },
      { name: "FR", pageviews: 2 },
      { name: "US", pageviews: 1 },
    ]);
  });

  function stubVercel(handler: (u: URL) => { status?: number; body?: unknown }): URL[] {
    const calls: URL[] = [];
    vi.stubGlobal("fetch", async (url: URL) => {
      calls.push(url);
      const { status = 200, body = {} } = handler(url);
      return { ok: status < 400, status, headers: new Headers(), json: async () => body };
    });
    return calls;
  }

  const PROJECTS = {
    projects: [
      { id: "p1", name: "one", webAnalytics: { enabledAt: 1 }, targets: { production: { alias: ["one.com"] } } },
      { id: "p2", name: "quiet", webAnalytics: { enabledAt: 1 } },
      { id: "p3", name: "off" },
    ],
  };

  it("counts every enabled project, breaks down only those with traffic", async () => {
    const calls = stubVercel((u) => {
      if (u.pathname === "/v9/projects") return { body: PROJECTS };
      if (u.pathname.endsWith("/count")) {
        return { body: { data: u.searchParams.get("projectId") === "p1" ? { pageviews: 5, visitors: 2 } : { pageviews: 0, visitors: 0 } } };
      }
      const by = u.searchParams.get("by");
      if (by === "day") return { body: { data: [{ timestamp: "2026-11-04T00:00:00.000Z", pageviews: 5, visitors: 2 }] } };
      return { body: { data: [{ [by!]: "x", pageviews: 5, visitors: 2 }] } };
    });
    const s = await loadVercelTraffic(ENV, w);
    expect(s.projectsTotal).toBe(3);
    expect(s.projectsEnabled).toBe(2);
    expect(s.failed).toBe(0);
    expect(s.totals).toEqual({ pageviews: 5, visitors: 2 });
    expect(s.pageviews.at(-1)).toBe(5);
    expect(s.visitors.at(-1)).toBe(2);
    expect(s.projects).toHaveLength(1);
    expect(s.projects[0]).toMatchObject({ project: "one", domain: "one.com", countries: [{ name: "x", pageviews: 5 }] });
    const aggregates = calls.filter((u) => u.pathname.endsWith("/aggregate"));
    expect(aggregates.every((u) => u.searchParams.get("projectId") === "p1" && u.searchParams.get("limit") === "100")).toBe(true);
    expect(aggregates.map((u) => u.searchParams.get("by")).sort()).toEqual(["country", "day", "deviceType", "referrerHostname", "requestPath"]);
    expect(calls[0]!.searchParams.get("teamId")).toBe("team");
  });

  it("asks for hourly buckets with instants, whole days with dates", async () => {
    const calls = stubVercel((u) => (u.pathname === "/v9/projects" ? { body: PROJECTS } : { body: { data: { pageviews: 0 } } }));
    await loadVercelTraffic(ENV, w);
    expect(calls.find((u) => u.pathname.endsWith("/count"))!.searchParams.get("since")).toBe("2026-10-29");
    calls.length = 0;
    await loadVercelTraffic(ENV, rangeWindow("24h", NOW));
    expect(calls.find((u) => u.pathname.endsWith("/count"))!.searchParams.get("since")).toBe(new Date(Date.parse("2026-11-03T15:00:00Z")).toISOString());
  });

  it("a project whose calls fail is counted, not silently zero", async () => {
    stubVercel((u) => {
      if (u.pathname === "/v9/projects") return { body: PROJECTS };
      if (u.searchParams.get("projectId") === "p2") return { status: 503 };
      return { body: { data: { pageviews: 0 } } };
    });
    expect((await loadVercelTraffic(ENV, w)).failed).toBe(1);
  });

  it("every count failing fails the section", async () => {
    stubVercel((u) => (u.pathname === "/v9/projects" ? { body: PROJECTS } : { status: 503 }));
    await expect(loadVercelTraffic(ENV, w)).rejects.toThrow("every Vercel analytics call failed");
  });

  it("stays off a token that is cooling down", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    noteRateLimited("vercel", "60");
    const calls = stubVercel(() => ({ body: PROJECTS }));
    await expect(loadVercelTraffic(ENV, w)).rejects.toThrow("rate limited");
    expect(calls).toHaveLength(0);
  });
});

describe("errors sections", () => {
  const recent = new Date(NOW - HOUR).toISOString();
  const old = new Date(NOW - 48 * HOUR).toISOString();

  it("active is the board's rule: error or fatal, and seen in the last 24h", () => {
    expect(isActiveIssue("error", recent, NOW)).toBe(true);
    expect(isActiveIssue("FATAL", recent, NOW)).toBe(true);
    expect(isActiveIssue("warning", recent, NOW)).toBe(false);
    expect(isActiveIssue("error", old, NOW)).toBe(false);
    expect(isActiveIssue("error", null, NOW)).toBe(false);
    expect(isActiveIssue(null, recent, NOW)).toBe(false);
  });

  it("summarizes a mostly stale backlog as mostly not active, active first", () => {
    const issues = toErrorIssues(
      [
        { id: "1", title: "old big", level: "error", count: "100", lastSeen: old, firstSeen: "2026-11-02T10:00:00Z", metadata: { type: "TypeError" } },
        { id: "2", title: "live", level: "error", count: 3, lastSeen: recent, firstSeen: "2026-11-02T11:00:00Z", shortId: "ADH-2", metadata: { type: "SyntaxError", filename: "/x.js" }, lastRelease: { version: "abc" } },
        { id: "3", title: "typeless", level: "warning", count: 1, lastSeen: recent },
      ],
      NOW,
    );
    const s = summarizeIssues(issues, rangeWindow("30d", NOW), { resolved: 7, complete: true });
    expect(s.summary).toMatchObject({ active: 1, backlog: 2, events: 104, resolved: 7, complete: true });
    expect(s.summary.byType).toEqual([
      { name: "TypeError", issues: 1, events: 100 },
      { name: "SyntaxError", issues: 1, events: 3 },
      { name: "Other", issues: 1, events: 1 },
    ]);
    expect(s.issues.map((i) => i.id)).toEqual(["2", "1", "3"]);
    expect(s.issues[0]).toMatchObject({ shortId: "ADH-2", type: "SyntaxError", source: "/x.js", release: "abc", active: true });
    expect(s.summary.newPerDay.at(-3)).toBe(2);
    expect(s.summary.newPerDay.reduce((a, b) => a + b, 0)).toBe(2);
  });
});
