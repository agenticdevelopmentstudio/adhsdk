import { afterEach, describe, expect, it, vi } from "vitest";
import { _resetProviderCooldowns, noteRateLimited } from "@agentic-toolkit/deploy-platform/cooldown";
import { alignToBuckets, rangeWindow } from "../src/telemetry/dashboard/ranges";
import {
  loadSiteErrorDetail,
  loadTraffic,
  shapeDimensions,
  shapeErrorDays,
  shapeFailedRequests,
  shapeHealth,
  shapeSiteErrors,
  shapeTraffic,
  shapeVitals,
} from "../src/telemetry/dashboard/posthog-sections";
import { analyticsEnabled, isProductionProject, loadVercelTraffic, productionDomain, shapeMarginal } from "../src/telemetry/dashboard/vercel-section";
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

  it("shapeErrorDays lines each site up on the buckets, zero-filled", () => {
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

  it("shapeSiteErrors keeps what an error did not report as null", () => {
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

  it("shapeFailedRequests keeps status 0, a request with no response", () => {
    expect(shapeFailedRequests([["a.com", 0, "POST", "/x", "3", "2026-11-04T01:00:00Z"]])[0]).toEqual({
      host: "a.com",
      status: 0,
      method: "POST",
      path: "/x",
      count: 3,
      lastSeen: "2026-11-04T01:00:00Z",
    });
  });

  describe("loadSiteErrorDetail", () => {
    const ENV = { POSTHOG_HOST: "https://ph", POSTHOG_API_KEY: "k", POSTHOG_PROJECT_ID: "1" };
    const answer = (results: unknown[][]) => ({ ok: true, status: 200, json: async () => ({ results }) });

    it("asks only for production errors and failed requests, and says when a cap was hit", async () => {
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

    it("is not truncated under the cap", async () => {
      vi.stubGlobal("fetch", async () => answer([]));
      expect((await loadSiteErrorDetail(ENV, rangeWindow("30d", NOW))).truncated).toBe(false);
    });

    it("fails the section when any of its queries fails", async () => {
      vi.stubGlobal("fetch", async () => ({ ok: false, status: 504, json: async () => ({}) }));
      await expect(loadSiteErrorDetail(ENV, rangeWindow("30d", NOW))).rejects.toThrow("HTTP 504");
    });
  });

  it("a failed query fails the section rather than reading as no traffic", async () => {
    vi.stubGlobal("fetch", async () => ({ ok: false, status: 504, json: async () => ({}) }));
    await expect(
      loadTraffic({ POSTHOG_HOST: "https://ph", POSTHOG_API_KEY: "k", POSTHOG_PROJECT_ID: "1" }, rangeWindow("7d", NOW)),
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

  it("a project is production unless its name ends in staging or testing", () => {
    expect(isProductionProject({ name: "site-production" })).toBe(true);
    expect(isProductionProject({ name: "site-staging" })).toBe(false);
    expect(isProductionProject({ name: "site-testing" })).toBe(false);
    // The production site of a site about testing.
    expect(isProductionProject({ name: "testing-production" })).toBe(true);
    expect(isProductionProject({ name: "x", targets: { production: { alias: ["staging.x.com"] } } })).toBe(false);
  });

  it("staging and testing are neither counted nor queried", async () => {
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

  it("the roster lists every production project, busiest first, and a project with no count has none", async () => {
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
  it("finds the domain of a project whose latest deployment only has vercel.app aliases", async () => {
    stubDomains({ id: "d1", name: "deploying-production", alias: ["deploying.vercel.app"] }, [{ name: "deploying.example.com", verified: true }]);
    expect((await loadVercelTraffic(ENV, w)).roster.map((r) => r.domain)).toEqual(["deploying.example.com"]);
  });

  it("falls back to the alias when the domains API cannot be read", async () => {
    stubDomains({ id: "d2", name: "aliased-production", alias: ["aliased.example.com"] }, null);
    expect((await loadVercelTraffic(ENV, w)).roster.map((r) => r.domain)).toEqual(["aliased.example.com"]);
  });

  it("drops a project whose real domain turns out to be staging, and does not count it", async () => {
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

  it("a failed breakdown marks the project incomplete, and keeps its count whole", async () => {
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

  // More busy projects than workers, so some breakdowns only start after the first 429 is in.
  it("a 429 in a breakdown fails the section and stops the calls not yet made", async () => {
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
