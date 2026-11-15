import { afterEach, describe, expect, it, vi } from "vitest";
import { _resetProviderCooldowns, noteRateLimited } from "@adh-sdk/deploy-platform/cooldown";
import { ANALYTICS_RANGES, alignToBuckets, rangeWindow, type RangeWindow } from "../src/telemetry/dashboard/ranges";
import {
  bucketStart,
  loadSiteErrorDetail,
  loadTraffic,
  shapeDimensions,
  shapeErrorDays,
  shapeFailedRequests,
  shapeHealth,
  shapeSiteErrors,
  shapeTraffic,
  shapeVitals,
  since,
} from "../src/telemetry/dashboard/posthog-sections";
import { analyticsEnabled, loadVercelTraffic, shapeMarginal } from "../src/telemetry/dashboard/vercel-section";
import { isProductionProject, productionDomain } from "../src/telemetry/vercel-api";
import { isoMs, loadErrorIssues, resolvedCounter, summarizeIssues, toErrorIssues } from "../src/telemetry/dashboard/errors-sections";

const NOW = Date.parse("2026-11-04T15:30:20.000Z");
const HOUR = 3_600_000;

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  _resetProviderCooldowns();
});

describe("rangeWindow", () => {
  it("ranges-001: the range names are 24h, 7d and 30d", () => {
    expect([...ANALYTICS_RANGES]).toEqual(["24h", "7d", "30d"]);
  });

  it("ranges-002: 24h is 25 hourly buckets ending in the current hour", () => {
    const w = rangeWindow("24h", NOW);
    expect(w.unit).toBe("hour");
    expect(w.buckets).toHaveLength(25);
    expect(w.buckets[0]).toBe("2026-11-03T15:00:00.000Z");
    expect(w.buckets.at(-1)).toBe("2026-11-04T15:00:00.000Z");
  });

  it("ranges-003: 7d and 30d are that many UTC days including today", () => {
    const w = rangeWindow("7d", NOW);
    expect(w.unit).toBe("day");
    expect(w.buckets).toHaveLength(7);
    expect(w.buckets[0]).toBe("2026-10-29T00:00:00.000Z");
    expect(w.buckets.at(-1)).toBe("2026-11-04T00:00:00.000Z");
    expect(rangeWindow("30d", NOW).buckets).toHaveLength(30);
  });

  it("ranges-004: until is the clock and since is the first 7d bucket", () => {
    const w = rangeWindow("7d", NOW);
    expect(w.until).toEqual(new Date(NOW));
    expect(w.since).toEqual(new Date("2026-10-29T00:00:00.000Z"));
  });

  it("ranges-005: 24h buckets ascend one hour apart", () => {
    const ms = rangeWindow("24h", NOW).buckets.map((b) => Date.parse(b));
    for (let i = 1; i < ms.length; i++) expect(ms[i]! - ms[i - 1]!).toBe(HOUR);
  });

  it("ranges-008: day windows do not depend on the local time zone", () => {
    const at = Date.parse("2026-11-04T00:00:00.000Z");
    const saved = process.env.TZ;
    try {
      const results = ["UTC", "Pacific/Chatham"].map((tz) => {
        process.env.TZ = tz;
        return rangeWindow("7d", at).buckets;
      });
      expect(results[1]).toEqual(results[0]);
      expect(results[0]!.at(-1)).toBe("2026-11-04T00:00:00.000Z");
      expect(results[0]![0]).toBe("2026-10-29T00:00:00.000Z");
    } finally {
      if (saved === undefined) delete process.env.TZ;
      else process.env.TZ = saved;
    }
  });

  it("ranges-009: 24h exactly on the hour still starts 24 hours back and ends in the current hour", () => {
    const w = rangeWindow("24h", Date.parse("2026-11-04T15:00:00.000Z"));
    expect(w.buckets).toHaveLength(25);
    expect(w.buckets[0]).toBe("2026-11-03T15:00:00.000Z");
    expect(w.buckets.at(-1)).toBe("2026-11-04T15:00:00.000Z");
  });

  it("ranges-015: 30d is 30 UTC days ending today", () => {
    const w = rangeWindow("30d", NOW);
    expect(w.buckets).toHaveLength(30);
    expect(w.buckets[0]).toBe("2026-10-06T00:00:00.000Z");
    expect(w.buckets.at(-1)).toBe("2026-11-04T00:00:00.000Z");
  });
});

describe("alignToBuckets", () => {
  const buckets = ["2026-11-03T00:00:00.000Z", "2026-11-04T00:00:00.000Z"];

  it("ranges-006: zero-fills, tolerates either timestamp spelling, and sums repeats", () => {
    expect(alignToBuckets(buckets, [["2026-11-04T00:00:00Z", 2], ["2026-11-04T00:00:00.000Z", 3]])).toEqual([0, 5]);
  });

  it("ranges-007: drops what is off the axis or unparseable", () => {
    expect(alignToBuckets(buckets, [["2026-01-01T00:00:00Z", 9], ["nope", 9], [null, 9]])).toEqual([0, 0]);
  });

  it("ranges-010: a point inside a bucket's span is dropped, not rounded", () => {
    expect(alignToBuckets(buckets, [["2026-11-04T06:00:00Z", 4]])).toEqual([0, 0]);
  });

  it("ranges-011: a numeric timestamp is accepted", () => {
    expect(alignToBuckets(buckets, [[Date.parse("2026-11-03T00:00:00.000Z"), 6]])).toEqual([6, 0]);
  });

  it("ranges-012: no buckets gives an empty series", () => {
    expect(alignToBuckets([], [["2026-11-04T00:00:00Z", 1]])).toEqual([]);
  });

  it("ranges-013: points may be any iterable, such as a generator", () => {
    function* points(): Generator<[unknown, number]> {
      yield ["2026-11-04T00:00:00.000Z", 1];
    }
    expect(alignToBuckets(buckets, points())).toEqual([0, 1]);
  });

  it("ranges-014: alignment is pure", () => {
    const before = [...buckets];
    const points: [unknown, number][] = [["2026-11-04T00:00:00Z", 2]];
    expect(alignToBuckets(buckets, points)).toEqual(alignToBuckets(buckets, points));
    expect(buckets).toEqual(before);
  });
});

describe("PostHog shapers", () => {
  const buckets = ["2026-11-03T00:00:00.000Z", "2026-11-04T00:00:00.000Z"];

  it("posthog-sections-001: shapeTraffic rolls up per site and overall, biggest site first", () => {
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

  it("posthog-sections-002: shapeDimensions labels blanks and says when the row cap was hit", () => {
    const d = shapeDimensions([["a.com", null, "", "US", null, 4]], 1);
    expect(d.rows[0]).toEqual({ host: "a.com", device: "Unknown", browser: "Unknown", country: "US", referrer: "$direct", pageviews: 4 });
    expect(d.truncated).toBe(true);
    expect(shapeDimensions([], 1).truncated).toBe(false);
  });

  it("posthog-sections-003: shapeVitals keeps a vital with no samples as null, not zero", () => {
    expect(shapeVitals([["a.com", 3, 1200, null, "0.1", 800]])[0]).toEqual({ host: "a.com", samples: 3, lcp: 1200, inp: null, cls: 0.1, fcp: 800 });
  });

  it("posthog-sections-004: shapeHealth", () => {
    expect(shapeHealth([["a.com", 1, 100, 2, null]])[0]).toEqual({ host: "a.com", errors: 1, requests: 100, failures: 2, p95Ms: null });
  });

  it("posthog-sections-005: shapeErrorDays lines each site up on the buckets, zero-filled", () => {
    expect(
      shapeErrorDays(
        [
          ["a.com", "2026-11-03T00:00:00Z", 1, 0],
          ["a.com", "2026-11-04T00:00:00Z", 0, "2"],
          ["b.com", "2026-11-04T00:00:00Z", 3, 4],
        ],
        buckets,
      ),
    ).toEqual([
      { host: "a.com", errors: [1, 0], failures: [0, 2] },
      { host: "b.com", errors: [0, 3], failures: [0, 4] },
    ]);
  });

  it("posthog-sections-006: shapeSiteErrors keeps what an error did not report as null", () => {
    expect(shapeSiteErrors([["a.com", "TypeError", "checkout", "", null, "/pay", 2, "2026-11-04T01:00:00Z"]])[0]).toEqual({
      host: "a.com",
      name: "TypeError",
      feature: "checkout",
      step: null,
      boundary: null,
      page: "/pay",
      count: 2,
      lastSeen: "2026-11-04T01:00:00Z",
    });
    expect(shapeSiteErrors([["a.com", null, null, null, null, null, 1, null]])[0]?.name).toBe("(unnamed)");
  });

  it("posthog-sections-007: shapeFailedRequests keeps status 0, a request with no response", () => {
    expect(shapeFailedRequests([["a.com", 0, "POST", "/x", "3", "2026-11-04T01:00:00Z"]])[0]).toEqual({
      host: "a.com",
      status: 0,
      method: "POST",
      path: "/x",
      count: 3,
      lastSeen: "2026-11-04T01:00:00Z",
    });
  });

  it("posthog-sections-015: counts coerce '7' to 7, and null and 'abc' to 0", () => {
    const d = shapeDimensions([["a.com", "d", "b", "c", "r", "7"], ["a.com", "d", "b", "c", "r", null], ["a.com", "d", "b", "c", "r", "abc"]]);
    expect(d.rows.map((r) => r.pageviews)).toEqual([7, 0, 0]);
  });

  it("posthog-sections-017: bucketStart names the hour or day in UTC", () => {
    expect(bucketStart("hour")).toBe("toStartOfHour(timestamp, 'UTC')");
    expect(bucketStart("day")).toBe("toStartOfDay(timestamp, 'UTC')");
  });

  it("posthog-sections-018: since is the window start as a UTC instant", () => {
    const w: RangeWindow = { since: new Date("2026-01-02T03:04:05Z"), until: new Date(NOW), unit: "day", buckets: [] };
    expect(since(w)).toBe("timestamp >= toDateTime('2026-01-02 03:04:05', 'UTC')");
  });

  it("posthog-sections-019: an off-axis traffic point is dropped from series and totals, and an empty bucket is 0", () => {
    const t = shapeTraffic(
      [
        ["a.com", "2026-11-03T00:00:00Z", 2, 1],
        ["a.com", "2026-01-01T00:00:00Z", 9, 9],
      ],
      buckets,
    );
    expect(t.pageviews).toEqual([2, 0]);
    expect(t.sessions).toEqual([1, 0]);
    expect(t.totals).toEqual({ pageviews: 2, sessions: 1 });
    expect(t.sites[0]).toMatchObject({ host: "a.com", pageviews: 2, sessions: 1, series: [2, 0] });
  });

  describe("loadSiteErrorDetail", () => {
    const ENV = { POSTHOG_HOST: "https://ph", POSTHOG_API_KEY: "k", POSTHOG_PROJECT_ID: "1" };
    const answer = (results: unknown[][]) => ({ ok: true, status: 200, json: async () => ({ results }) });

    it("posthog-sections-008/009: asks only for production errors and failed requests, and says when a cap was hit", async () => {
      const queries: string[] = [];
      const atCap = Array.from({ length: 5_000 }, () => ["a.com", 500, "GET", "/x", 1, null]);
      vi.stubGlobal("fetch", async (_url: string, init: { body: string }) => {
        const query = (JSON.parse(init.body) as { query: { query: string } }).query.query;
        queries.push(query);
        return answer(query.includes("properties.path") ? atCap : []);
      });

      const detail = await loadSiteErrorDetail(ENV, rangeWindow("30d", NOW));

      expect(detail.buckets).toHaveLength(30);
      expect(detail.requests).toHaveLength(5_000);
      expect(detail.truncated).toBe(true);
      expect(queries).toHaveLength(3);
      for (const query of queries) expect(query).toContain("NOT LIKE 'staging.%'");
      const requests = queries.find((q) => q.includes("properties.path"));
      expect(requests).toContain("toFloat(properties.status) >= 500 OR toFloat(properties.status) = 0");
    });

    it("posthog-sections-010: is not truncated under the cap", async () => {
      vi.stubGlobal("fetch", async () => answer([]));
      expect((await loadSiteErrorDetail(ENV, rangeWindow("30d", NOW))).truncated).toBe(false);
    });

    it("fails the section when any of its queries fails", async () => {
      vi.stubGlobal("fetch", async () => ({ ok: false, status: 504, json: async () => ({}) }));
      await expect(loadSiteErrorDetail(ENV, rangeWindow("30d", NOW))).rejects.toThrow("HTTP 504");
    });

    // Left zone-less, HogQL reads these in the PostHog project's timezone, not the buckets' UTC.
    it("posthog-sections-012: states every bucket and window bound in UTC", async () => {
      const queries: string[] = [];
      vi.stubGlobal("fetch", async (_url: string, init: { body: string }) => {
        queries.push((JSON.parse(init.body) as { query: { query: string } }).query.query);
        return answer([]);
      });
      await loadTraffic(ENV, rangeWindow("24h", NOW));
      await loadTraffic(ENV, rangeWindow("7d", NOW));
      await loadSiteErrorDetail(ENV, rangeWindow("30d", NOW));
      const times = queries.flatMap((q) => q.match(/toStartOf\w+\([^)]*\)|toDateTime\([^)]*\)/g) ?? []);
      expect(times.length).toBeGreaterThanOrEqual(queries.length);
      for (const t of times) expect(t).toMatch(/, 'UTC'\)$/);
    });

    it("posthog-sections-013: stops at the first failed query instead of spending the other scans", async () => {
      const fetch = vi.fn(async () => ({ ok: false, status: 503, json: async () => ({}) }));
      vi.stubGlobal("fetch", fetch);
      await expect(loadSiteErrorDetail(ENV, rangeWindow("30d", NOW))).rejects.toThrow("HTTP 503");
      expect(fetch).toHaveBeenCalledTimes(1);
    });

    // PostHog 503s under concurrent load, and its callers don't know about each other.
    it("posthog-sections-014: never has two HogQL queries in flight, even across sections loading at once", async () => {
      let inFlight = 0;
      let most = 0;
      vi.stubGlobal("fetch", async () => {
        inFlight += 1;
        most = Math.max(most, inFlight);
        await new Promise((r) => setTimeout(r, 2));
        inFlight -= 1;
        return answer([]);
      });
      await Promise.all([loadSiteErrorDetail(ENV, rangeWindow("30d", NOW)), loadTraffic(ENV, rangeWindow("7d", NOW))]);
      expect(most).toBe(1);
    });
  });

  it("posthog-sections-011: a failed query fails the section rather than reading as no traffic", async () => {
    vi.stubGlobal("fetch", async () => ({ ok: false, status: 504, json: async () => ({}) }));
    await expect(
      loadTraffic({ POSTHOG_HOST: "https://ph", POSTHOG_API_KEY: "k", POSTHOG_PROJECT_ID: "1" }, rangeWindow("7d", NOW)),
    ).rejects.toThrow("HTTP 504");
  });
});

describe("Vercel section", () => {
  const ENV = { VERCEL_API_TOKEN: "t", VERCEL_TEAM_ID: "team" };
  const w = rangeWindow("7d", NOW);

  it("vercel-001 only a project with analytics on, and not since disabled, counts", () => {
    expect(analyticsEnabled({ webAnalytics: { enabledAt: 1 } })).toBe(true);
    expect(analyticsEnabled({ webAnalytics: { enabledAt: 1, disabledAt: 2 } })).toBe(false);
    expect(analyticsEnabled({})).toBe(false);
  });

  it("vercel-002 the domain is the first alias that isn't a vercel.app one", () => {
    expect(productionDomain({ targets: { production: { alias: ["x.vercel.app", "x.com"] } } })).toBe("x.com");
    expect(productionDomain({ targets: { production: { alias: ["x.vercel.app"] } } })).toBeNull();
  });

  it("vercel-003 a project is production unless its name ends in staging or testing", () => {
    expect(isProductionProject({ name: "site-production" })).toBe(true);
    expect(isProductionProject({ name: "site-staging" })).toBe(false);
    expect(isProductionProject({ name: "site-testing" })).toBe(false);
    // The production site of a site about testing.
    expect(isProductionProject({ name: "testing-production" })).toBe(true);
    expect(isProductionProject({ name: "x", targets: { production: { alias: ["staging.x.com"] } } })).toBe(false);
  });

  it("vercel-004 staging and testing are neither counted nor queried", async () => {
    const calls = stubVercel((u) => {
      if (u.pathname === "/v9/projects") {
        return {
          body: {
            projects: [
              { id: "prod", name: "a-production", webAnalytics: { enabledAt: 1 } },
              { id: "off", name: "b-production" },
              { id: "stg", name: "a-staging", webAnalytics: { enabledAt: 1 } },
              { id: "tst", name: "a-testing", webAnalytics: { enabledAt: 1 } },
            ],
          },
        };
      }
      return { body: { data: { pageviews: 0, visitors: 0 } } };
    });
    const s = await loadVercelTraffic(ENV, w);
    expect(s.projectsTotal).toBe(2);
    expect(s.projectsEnabled).toBe(1);
    expect(s.roster.map((r) => r.project)).toEqual(["a-production", "b-production"]);
    const queried = calls.filter((u) => u.pathname !== "/v9/projects").map((u) => u.searchParams.get("projectId"));
    expect(new Set(queried)).toEqual(new Set(["prod"]));
  });

  it("vercel-005 the roster lists every production project, busiest first, and a project with no count has none", async () => {
    stubVercel((u) => {
      if (u.pathname === "/v9/projects") return { body: PROJECTS };
      if (u.pathname.endsWith("/count")) {
        return { body: { data: u.searchParams.get("projectId") === "p1" ? { pageviews: 5, visitors: 2 } : { pageviews: 0, visitors: 0 } } };
      }
      return { body: { data: [] } };
    });
    expect((await loadVercelTraffic(ENV, w)).roster).toEqual([
      { project: "one", domain: "one.com", analyticsOn: true, pageviews: 5, visitors: 2 },
      { project: "quiet", domain: null, analyticsOn: true, pageviews: 0, visitors: 0 },
      { project: "off", domain: null, analyticsOn: false, pageviews: null, visitors: null },
    ]);
  });

  it("vercel-006 shapeMarginal drops Vercel's Others rollup, which is no value of the dimension", () => {
    expect(shapeMarginal([{ requestPath: "Others", pageviews: 9 }, { requestPath: "/a", pageviews: 1 }], "requestPath")).toEqual([
      { name: "/a", pageviews: 1 },
    ]);
  });

  it("vercel-007 shapeMarginal reads the value from the `by` column", () => {
    expect(shapeMarginal([{ country: "US", pageviews: 1 }, { country: "FR", pageviews: 2 }, { pageviews: 3 }], "country")).toEqual([
      { name: "(none)", pageviews: 3 },
      { name: "FR", pageviews: 2 },
      { name: "US", pageviews: 1 },
    ]);
  });

  /** Answers every Vercel call through `handler`, and records the analytics ones. A project's domain
   *  lookup is answered but not recorded: it has no `projectId` and is cached for an hour. */
  function stubVercel(handler: (u: URL) => { status?: number; body?: unknown }): URL[] {
    const calls: URL[] = [];
    vi.stubGlobal("fetch", async (input: URL | string) => {
      const url = new URL(String(input));
      if (!url.pathname.endsWith("/domains")) calls.push(url);
      const { status = 200, body = {} } = handler(url);
      return { ok: status < 400, status, headers: new Headers(), json: async () => body };
    });
    return calls;
  }

  /** One project, with `domains` from the domains API, or that API refusing when `domains` is null. */
  function stubDomains(project: { id: string; name: string; alias?: string[] }, domains: { name: string; verified: boolean }[] | null): void {
    stubVercel((u) => {
      if (u.pathname === "/v9/projects") {
        const { alias = [], ...rest } = project;
        return { body: { projects: [{ ...rest, webAnalytics: { enabledAt: 1 }, targets: { production: { alias } } }] } };
      }
      if (u.pathname.endsWith("/domains")) return domains ? { body: { domains } } : { status: 403 };
      return { body: { data: { pageviews: 0, visitors: 0 } } };
    });
  }

  // The domain joins Vercel's numbers to PostHog's, so it can't depend on whether the project happens
  // to be mid-deployment, when its aliases are only `*.vercel.app`. Each case has its own project
  // name because the domains lookup is cached per project.
  it("vercel-008 finds the domain of a project whose latest deployment only has vercel.app aliases", async () => {
    stubDomains({ id: "d1", name: "deploying-production", alias: ["deploying.vercel.app"] }, [{ name: "deploying.example.com", verified: true }]);
    expect((await loadVercelTraffic(ENV, w)).roster.map((r) => r.domain)).toEqual(["deploying.example.com"]);
  });

  it("vercel-009 falls back to the alias when the domains API cannot be read", async () => {
    stubDomains({ id: "d2", name: "aliased-production", alias: ["aliased.example.com"] }, null);
    expect((await loadVercelTraffic(ENV, w)).roster.map((r) => r.domain)).toEqual(["aliased.example.com"]);
  });

  it("vercel-010 drops a project whose real domain turns out to be staging, and does not count it", async () => {
    stubDomains({ id: "d3", name: "odd-name", alias: ["odd.vercel.app"] }, [{ name: "staging.example.com", verified: true }]);
    const s = await loadVercelTraffic(ENV, w);
    expect(s.roster).toEqual([]);
    expect(s.projectsTotal).toBe(0);
  });

  const PROJECTS = {
    projects: [
      { id: "p1", name: "one", webAnalytics: { enabledAt: 1 }, targets: { production: { alias: ["one.com"] } } },
      { id: "p2", name: "quiet", webAnalytics: { enabledAt: 1 } },
      { id: "p3", name: "off" },
    ],
  };

  it("vercel-011 counts every enabled project, breaks down only those with traffic", async () => {
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

  it("vercel-012 asks for hourly buckets with instants, whole days with dates", async () => {
    const calls = stubVercel((u) => (u.pathname === "/v9/projects" ? { body: PROJECTS } : { body: { data: { pageviews: 0 } } }));
    await loadVercelTraffic(ENV, w);
    expect(calls.find((u) => u.pathname.endsWith("/count"))!.searchParams.get("since")).toBe("2026-10-29");
    calls.length = 0;
    await loadVercelTraffic(ENV, rangeWindow("24h", NOW));
    expect(calls.find((u) => u.pathname.endsWith("/count"))!.searchParams.get("since")).toBe(new Date(Date.parse("2026-11-03T15:00:00Z")).toISOString());
  });

  it("vercel-013 a project whose calls fail is counted, not silently zero", async () => {
    stubVercel((u) => {
      if (u.pathname === "/v9/projects") return { body: PROJECTS };
      if (u.searchParams.get("projectId") === "p2") return { status: 503 };
      return { body: { data: { pageviews: 0 } } };
    });
    expect((await loadVercelTraffic(ENV, w)).failed).toBe(1);
  });

  it("vercel-014 a failed breakdown marks the project incomplete, and keeps its count whole", async () => {
    stubVercel((u) => {
      if (u.pathname === "/v9/projects") return { body: PROJECTS };
      if (u.pathname.endsWith("/count")) {
        return { body: { data: u.searchParams.get("projectId") === "p1" ? { pageviews: 5, visitors: 2 } : { pageviews: 0, visitors: 0 } } };
      }
      if (u.searchParams.get("by") === "day") return { status: 504 };
      return { body: { data: [] } };
    });
    const s = await loadVercelTraffic(ENV, w);
    expect(s.failed).toBe(0);
    expect(s.incomplete).toBe(1);
    expect(s.totals.pageviews).toBe(5);
    expect(s.projects[0]).toMatchObject({ project: "one", incomplete: true });
  });

  it("vercel-015 every count failing fails the section", async () => {
    stubVercel((u) => (u.pathname === "/v9/projects" ? { body: PROJECTS } : { status: 503 }));
    await expect(loadVercelTraffic(ENV, w)).rejects.toThrow("every Vercel analytics call failed");
  });

  it("vercel-016 stays off a token that is cooling down", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    noteRateLimited("vercel", "60");
    const calls = stubVercel(() => ({ body: PROJECTS }));
    await expect(loadVercelTraffic(ENV, w)).rejects.toThrow("rate limited");
    expect(calls).toHaveLength(0);
  });

  // More busy projects than workers, so some breakdowns only start after the first 429 is in.
  it("vercel-017 a 429 in a breakdown fails the section and stops the calls not yet made", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    const busy = Array.from({ length: 8 }, (_, i) => ({ id: `b${i}`, name: `busy${i}`, webAnalytics: { enabledAt: 1 } }));
    const calls = stubVercel((u) => {
      if (u.pathname === "/v9/projects") return { body: { projects: busy } };
      if (u.pathname.endsWith("/count")) return { body: { data: { pageviews: 1, visitors: 1 } } };
      if (u.searchParams.get("projectId") === "b0") return { status: 429 };
      return { body: { data: [] } };
    });
    await expect(loadVercelTraffic(ENV, w)).rejects.toThrow("rate limited");
    await new Promise((r) => setTimeout(r, 10)); // let the other workers drain
    const broken = new Set(calls.filter((u) => u.pathname.endsWith("/aggregate")).map((u) => u.searchParams.get("projectId")));
    expect(broken.has("b6")).toBe(false);
    expect(broken.has("b7")).toBe(false);
  });

  it("vercel-018 no enabled project is no failure, and zero totals", async () => {
    stubVercel((u) => (u.pathname === "/v9/projects" ? { body: { projects: [{ id: "n1", name: "idle-one-production" }, { id: "n2", name: "idle-two-production" }] } } : {}));
    const s = await loadVercelTraffic(ENV, w);
    expect(s).toMatchObject({ failed: 0, projectsEnabled: 0, projectsTotal: 2, totals: { pageviews: 0, visitors: 0 } });
  });

  it("vercel-019 breaks a roster tie by project name", async () => {
    stubVercel((u) => {
      if (u.pathname === "/v9/projects") {
        return { body: { projects: [{ id: "tb", name: "tie-b-production", webAnalytics: { enabledAt: 1 } }, { id: "ta", name: "tie-a-production", webAnalytics: { enabledAt: 1 } }] } };
      }
      return { body: { data: { pageviews: 0, visitors: 0 } } };
    });
    expect((await loadVercelTraffic(ENV, w)).roster.map((r) => r.project)).toEqual(["tie-a-production", "tie-b-production"]);
  });

  it("vercel-020 an empty project list is an empty section, not an error", async () => {
    stubVercel(() => ({ body: { projects: [] } }));
    const s = await loadVercelTraffic(ENV, w);
    expect(s.roster).toEqual([]);
    expect(s.projectsTotal).toBe(0);
    expect(s.totals).toEqual({ pageviews: 0, visitors: 0 });
  });
});

describe("errors sections", () => {
  const recent = new Date(NOW - HOUR).toISOString();
  const old = new Date(NOW - 48 * HOUR).toISOString();

  const judging = { nowMs: NOW, frozen: false, allowlist: null };
  const one = (over: Record<string, unknown>, j: Parameters<typeof toErrorIssues>[1] = judging): boolean =>
    toErrorIssues([{ id: "1", title: "t", level: "error", count: 1, lastSeen: recent, project: { slug: "app" }, ...over }], j)[0]!
      .active;

  it("active is the board's rule: error or fatal, and seen in the last 24h", () => {
    expect(one({})).toBe(true);
    expect(one({ level: "FATAL" })).toBe(true);
    expect(one({ level: "warning" })).toBe(false);
    expect(one({ lastSeen: old })).toBe(false);
    expect(one({ lastSeen: null })).toBe(false);
    expect(one({ level: null })).toBe(false);
  });

  describe("the resolved count", () => {
    const GT = { GLITCHTIP_URL: "https://gt", GLITCHTIP_API_TOKEN: "t", GLITCHTIP_ORG: "o" };
    const page = (ok: boolean, n: number) => ({
      ok,
      status: ok ? 200 : 503,
      headers: new Headers(),
      json: async () => Array.from({ length: n }, (_, i) => ({ id: String(i) })),
    });

    it("is walked once per TTL, not on every issue-list refresh", async () => {
      const fetch = vi.fn(async (url: string) => page(true, url.includes("is:resolved") ? 3 : 1));
      vi.stubGlobal("fetch", fetch);
      const count = resolvedCounter(GT);
      const a = await loadErrorIssues(GT, null, count, NOW);
      const b = await loadErrorIssues(GT, null, count, NOW);
      expect(a.summary.resolved).toBe(3);
      expect(b.summary.resolved).toBe(3);
      const resolvedReads = fetch.mock.calls.filter(([url]) => url.includes("is:resolved"));
      expect(resolvedReads).toHaveLength(1);
    });

    it("is read again after a failed read, rather than keeping the failure", async () => {
      let fail = true;
      vi.stubGlobal("fetch", async () => page(!fail, 2));
      const count = resolvedCounter(GT);
      expect(await count()).toBeNull();
      fail = false;
      expect(await count()).toBe(2);
    });
  });

  it("active leaves out a project GLITCHTIP_PROJECTS does not allow, as the board does", () => {
    expect(one({}, { ...judging, allowlist: ["app"] })).toBe(true);
    expect(one({ project: { slug: "scratch" } }, { ...judging, allowlist: ["app"] })).toBe(false);
  });

  it("summarizes a mostly stale backlog as mostly not active, active first", () => {
    const issues = toErrorIssues(
      [
        { id: "1", title: "old big", level: "error", count: "100", lastSeen: old, firstSeen: "2026-11-02T10:00:00Z", metadata: { type: "TypeError" } },
        { id: "2", title: "live", level: "error", count: 3, lastSeen: recent, firstSeen: "2026-11-02T11:00:00Z", shortId: "ADH-2", metadata: { type: "SyntaxError", filename: "/x.js" }, lastRelease: { version: "abc" } },
        { id: "3", title: "typeless", level: "warning", count: 1, lastSeen: recent },
      ],
      judging,
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

describe("errors sections: conformance vectors", () => {
  const recent = new Date(NOW - HOUR).toISOString();
  const old = new Date(NOW - 48 * HOUR).toISOString();
  const judging = { nowMs: NOW, frozen: false, allowlist: null };
  const GT = { GLITCHTIP_URL: "https://gt", GLITCHTIP_API_TOKEN: "t", GLITCHTIP_ORG: "o" };
  const raw = (over: Record<string, unknown> = {}) => ({
    id: "1",
    title: "t",
    level: "error",
    count: 1,
    lastSeen: recent,
    project: { slug: "app" },
    ...over,
  });
  const active = (over: Record<string, unknown>, j: Parameters<typeof toErrorIssues>[1] = judging): boolean =>
    toErrorIssues([raw(over)], j)[0]!.active;
  const reply = (ok: boolean, items: unknown[], link?: string) => ({
    ok,
    status: ok ? 200 : 503,
    headers: new Headers(link ? { link } : {}),
    json: async () => items,
  });
  const items = (n: number, prefix = "i") => Array.from({ length: n }, (_, i) => ({ ...raw({ id: `${prefix}${i}` }) }));

  it("errors-sections-001 an error issue seen now is active", () => {
    expect(active({})).toBe(true);
  });

  it("errors-sections-002 level FATAL is active", () => {
    expect(active({ level: "FATAL" })).toBe(true);
  });

  it("errors-sections-003 a warning, a stale, an unseen and a levelless issue are not active", () => {
    expect(active({ level: "warning" })).toBe(false);
    expect(active({ lastSeen: old })).toBe(false);
    expect(active({ lastSeen: null })).toBe(false);
    expect(active({ level: null })).toBe(false);
  });

  it("errors-sections-004 the allowlist keeps scratch out and app in", () => {
    const j = { ...judging, allowlist: ["app"] };
    expect(active({ project: { slug: "scratch" } }, j)).toBe(false);
    expect(active({ project: { slug: "app" } }, j)).toBe(true);
  });

  const mixed = () =>
    toErrorIssues(
      [
        { id: "1", title: "old big", level: "error", count: "100", lastSeen: old, firstSeen: "2026-11-02T10:00:00Z", metadata: { type: "TypeError" } },
        { id: "2", title: "live", level: "error", count: 3, lastSeen: recent, firstSeen: "2026-11-02T11:00:00Z", shortId: "ADH-2", metadata: { type: "SyntaxError", filename: "/x.js" }, lastRelease: { version: "abc" } },
        { id: "3", title: "typeless", level: "warning", count: 1, lastSeen: recent },
      ],
      judging,
    );

  it("errors-sections-005 counts the summary and orders active first, then by count", () => {
    const input = mixed();
    const before = input.map((i) => i.id);
    const s = summarizeIssues(input, rangeWindow("30d", NOW), { resolved: 7, complete: true });
    expect(s.summary).toMatchObject({ active: 1, backlog: 2, events: 104, resolved: 7, complete: true });
    expect(s.issues.map((i) => i.id)).toEqual(["2", "1", "3"]);
    expect(input.map((i) => i.id)).toEqual(before);
  });

  it("errors-sections-006 groups by type, null as Other, biggest first", () => {
    const s = summarizeIssues(mixed(), rangeWindow("30d", NOW), { resolved: null, complete: true });
    expect(s.summary.byType).toEqual([
      { name: "TypeError", issues: 1, events: 100 },
      { name: "SyntaxError", issues: 1, events: 3 },
      { name: "Other", issues: 1, events: 1 },
    ]);
  });

  it("errors-sections-007 counts new issues per UTC day and skips one with no firstSeen", () => {
    const w = rangeWindow("30d", NOW);
    const issues = toErrorIssues(
      [
        raw({ id: "1", firstSeen: "2026-11-02T01:00:00Z" }),
        raw({ id: "2", firstSeen: "2026-11-02T23:00:00Z" }),
        raw({ id: "3" }),
      ],
      judging,
    );
    const { newPerDay } = summarizeIssues(issues, w, { resolved: null, complete: true }).summary;
    expect(newPerDay.at(-3)).toBe(2);
    expect(newPerDay.reduce((a, b) => a + b, 0)).toBe(2);
  });

  it("errors-sections-008 carries shortId, type, source and release", () => {
    const [row] = toErrorIssues(
      [raw({ shortId: "ADH-2", metadata: { type: "SyntaxError", filename: "/x.js" }, lastRelease: { version: "abc" } })],
      judging,
    );
    expect(row).toMatchObject({ shortId: "ADH-2", type: "SyntaxError", source: "/x.js", release: "abc" });
    const [bare] = toErrorIssues([raw({ metadata: { type: "", filename: "" } })], judging);
    expect(bare).toMatchObject({ shortId: null, type: null, source: null, release: null });
  });

  it("errors-sections-009 reads the resolved list once inside the TTL", async () => {
    const fetch = vi.fn(async (url: string) => reply(true, items(url.includes("is:resolved") ? 3 : 1)));
    vi.stubGlobal("fetch", fetch);
    const count = resolvedCounter(GT);
    const a = await loadErrorIssues(GT, null, count, NOW);
    const b = await loadErrorIssues(GT, null, count, NOW);
    expect(a.summary.resolved).toBe(3);
    expect(b.summary.resolved).toBe(3);
    expect(fetch.mock.calls.filter(([url]) => url.includes("is:resolved"))).toHaveLength(1);
  });

  it("errors-sections-010 a failed resolved read is not kept", async () => {
    let fail = true;
    vi.stubGlobal("fetch", async () => reply(!fail, items(2)));
    const count = resolvedCounter(GT);
    expect(await count()).toBeNull();
    fail = false;
    expect(await count()).toBe(2);
  });

  it("errors-sections-011 loadErrorIssues rejects when the unresolved read fails", async () => {
    vi.stubGlobal("fetch", async () => reply(false, []));
    await expect(loadErrorIssues(GT, null, async () => 0, NOW)).rejects.toThrow("GlitchTip issues could not be read");
  });

  it("errors-sections-012 isoMs is null for null, empty and unreadable input", () => {
    expect(isoMs(null)).toBeNull();
    expect(isoMs("")).toBeNull();
    expect(isoMs("not a date")).toBeNull();
    expect(isoMs("1970-01-01T00:00:01.000Z")).toBe(1000);
  });

  it("errors-sections-013 judges with nowMs, frozen false and the allowlist", async () => {
    const at0 = new Date(0).toISOString();
    vi.stubGlobal("fetch", async () =>
      reply(true, [raw({ id: "a", lastSeen: at0 }), raw({ id: "s", lastSeen: at0, project: { slug: "scratch" } })]),
    );
    const listed = await loadErrorIssues(GT, ["app"], async () => null, 1000);
    expect(Object.fromEntries(listed.issues.map((i) => [i.id, i.active]))).toEqual({ a: true, s: false });
    const open = await loadErrorIssues(GT, null, async () => null, 1000);
    expect(open.issues.every((i) => i.active)).toBe(true);
    // frozen is false: the same issue read a day later is no longer active.
    const later = await loadErrorIssues(GT, null, async () => null, 25 * HOUR);
    expect(later.issues.some((i) => i.active)).toBe(false);
  });

  it("errors-sections-014 the section buckets are the 30d window's", async () => {
    vi.stubGlobal("fetch", async () => reply(true, items(1)));
    const section = await loadErrorIssues(GT, null, async () => null, NOW);
    expect(section.buckets).toEqual(rangeWindow("30d", NOW).buckets);
  });

  it("errors-sections-015 an incomplete unresolved walk makes summary.complete false", async () => {
    vi.stubGlobal("fetch", async () => reply(true, items(100)));
    const section = await loadErrorIssues(GT, null, async () => null, NOW);
    expect(section.summary.complete).toBe(false);
  });

  it("errors-sections-016 a null resolved count still returns the issue list", async () => {
    vi.stubGlobal("fetch", async (url: string) => reply(!url.includes("is:resolved"), items(2)));
    const section = await loadErrorIssues(GT, null, resolvedCounter(GT), NOW);
    expect(section.issues).toHaveLength(2);
    expect(section.summary.resolved).toBeNull();
  });

  it("errors-sections-017 a capped resolved walk is kept as null for the TTL", async () => {
    let calls = 0;
    vi.stubGlobal("fetch", async (url: string) => {
      calls++;
      const n = calls;
      return reply(true, items(100, `p${n}-`), `{'<https://gt/next>; rel="next"; results="true"; cursor="c${n}"'}`);
    });
    const count = resolvedCounter(GT);
    expect(await count()).toBeNull();
    const walked = calls;
    expect(walked).toBe(20);
    expect(await count()).toBeNull();
    expect(calls).toBe(walked);
  });

  it("errors-sections-018 a resolved read that throws resolves null", async () => {
    vi.stubGlobal("fetch", async () => {
      throw new Error("network down");
    });
    vi.spyOn(console, "warn").mockImplementation(() => {});
    await expect(resolvedCounter(GT)()).resolves.toBeNull();
  });
});
