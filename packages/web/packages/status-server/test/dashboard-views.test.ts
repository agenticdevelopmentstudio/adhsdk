import { describe, expect, it } from "vitest";
import type { DashboardSection, DashboardSections } from "../src/telemetry/dashboard/sectioned-dashboard";
import type {
  AnalyticsSectionData,
  ErrorsSectionData,
  SiteErrorDetailSection,
  SiteErrorRow,
  SiteFailedRequestRow,
  SiteHealthRow,
  TrafficSection,
  VercelProjectTraffic,
  VercelTrafficSection,
} from "../src/telemetry/dashboard/types";
import {
  analyticsSites,
  analyticsViews,
  breakdownTotals,
  countryName,
  dimensionTotals,
  errorsSiteFailures,
  errorsSiteReport,
  errorsSiteRows,
  errorsSites,
  errorsViews,
  isFailureRateHigh,
  joinSites,
  mostErrorSites,
  pageviewSeries,
  pathTotals,
  rateVitals,
  sectionFailures,
  siteKey,
  siteReport,
  vercelTotals,
  vitalRating,
} from "../src/telemetry/dashboard/views";

// The dashboards' views: every join, sort and threshold the Analytics and Errors pages draw.
// Ported from status-web's analytics-model and errors-model tests when the rules moved here.

const BUCKETS = ["2026-11-03T00:00:00.000Z", "2026-11-04T00:00:00.000Z"];

const TRAFFIC: TrafficSection = {
  buckets: BUCKETS,
  totals: { pageviews: 13, sessions: 7 },
  pageviews: [5, 8],
  sessions: [3, 4],
  sites: [
    { host: "www.a.com", pageviews: 3, sessions: 2, series: [1, 2] },
    { host: "a.com", pageviews: 4, sessions: 2, series: [3, 1] },
    { host: "b.com", pageviews: 6, sessions: 3, series: [1, 5] },
  ],
};

function project(over: Partial<VercelProjectTraffic>): VercelProjectTraffic {
  return {
    project: "a-production",
    domain: "a.com",
    pageviews: 10,
    visitors: 5,
    series: [4, 6],
    countries: [],
    referrers: [],
    paths: [],
    devices: [],
    incomplete: false,
    ...over,
  };
}

const VERCEL: VercelTrafficSection = {
  buckets: BUCKETS,
  projectsTotal: 3,
  projectsEnabled: 2,
  failed: 0,
  incomplete: 0,
  roster: [],
  totals: { pageviews: 11, visitors: 6 },
  pageviews: [4, 7],
  visitors: [2, 4],
  projects: [project({}), project({ project: "orphan-production", domain: null, pageviews: 1, visitors: 1, series: [0, 1] })],
};

describe("breakdownTotals", () => {
  it("says a provider has no answer rather than an empty one", () => {
    expect(breakdownTotals("countries", null, null, null, null)).toEqual({ posthog: null, vercel: null });
    expect(breakdownTotals("countries", [], null, [], null)).toEqual({ posthog: [], vercel: [] });
  });
});

describe("siteKey", () => {
  it("treats www and the apex as one site", () => {
    expect(siteKey("WWW.A.com ")).toBe("a.com");
    expect(siteKey("www2.a.com")).toBe("www2.a.com");
  });
});

describe("failure rate", () => {
  it("is high at 5% and above, and never on a site that served nothing", () => {
    expect(isFailureRateHigh(5, 100)).toBe(true);
    expect(isFailureRateHigh(4, 100)).toBe(false);
    expect(isFailureRateHigh(3, 0)).toBe(false);
  });
});

describe("joinSites", () => {
  it("merges a site's hosts and keeps the providers side by side", () => {
    const rows = joinSites(TRAFFIC, VERCEL, null);
    const a = rows.find((r) => r.key === "a.com")!;
    expect(a.posthog).toEqual({ pageviews: 7, sessions: 4, series: [4, 3] });
    expect(a.vercel).toMatchObject({ pageviews: 10, visitors: 5 });
  });

  it("says a provider has not seen a site rather than reporting zero", () => {
    const rows = joinSites(TRAFFIC, VERCEL, null);
    expect(rows.find((r) => r.key === "b.com")!.vercel).toBeNull();
    expect(rows.find((r) => r.key === "orphan-production")!.posthog).toBeNull();
  });

  it("works when one provider has not answered", () => {
    expect(joinSites(null, VERCEL, null).map((r) => r.key)).toEqual(["a.com", "orphan-production"]);
    expect(joinSites(TRAFFIC, null, null).map((r) => r.key)).toEqual(["a.com", "b.com"]);
  });

  it("does not let health data add sites with no traffic", () => {
    const health = [{ host: "api.internal", errors: 9, requests: 90, failures: 9, p95Ms: 10 }];
    expect(joinSites(TRAFFIC, null, health).map((r) => r.key)).toEqual(["a.com", "b.com"]);
  });

  it("adds counts across a site's hosts but takes the worse percentile, and rates the joined rate", () => {
    const health = [
      { host: "a.com", errors: 1, requests: 10, failures: 2, p95Ms: 100 },
      { host: "www.a.com", errors: 2, requests: 20, failures: 1, p95Ms: 300 },
    ];
    const a = joinSites(TRAFFIC, null, health).find((r) => r.key === "a.com")!;
    expect(a.health).toMatchObject({ errors: 3, requests: 30, failures: 3, p95Ms: 300, failureRateHigh: true });
  });
});

describe("pageviewSeries", () => {
  it("gives the aggregate from each provider", () => {
    expect(pageviewSeries(TRAFFIC, VERCEL, null)).toEqual({ labels: BUCKETS, posthog: [5, 8], vercel: [4, 7] });
  });

  it("narrows both to one site", () => {
    expect(pageviewSeries(TRAFFIC, VERCEL, "a.com")).toEqual({ labels: BUCKETS, posthog: [4, 3], vercel: [4, 6] });
  });

  it("drops a provider that has never seen the site", () => {
    expect(pageviewSeries(TRAFFIC, VERCEL, "b.com").vercel).toBeNull();
  });

  it("leaves a gap where the axes differ, never a false zero", () => {
    const later = { ...VERCEL, buckets: [BUCKETS[1]!, "2026-11-05T00:00:00.000Z"], pageviews: [4, 7] };
    const { labels, posthog, vercel } = pageviewSeries(TRAFFIC, later, null);
    expect(labels).toHaveLength(3);
    expect(posthog).toEqual([5, 8, null]);
    expect(vercel).toEqual([null, 4, 7]);
  });
});

describe("breakdowns", () => {
  const ROWS = [
    { host: "a.com", device: "Desktop", browser: "Chrome", country: "US", referrer: "$direct", pageviews: 5 },
    { host: "www.a.com", device: "Mobile", browser: "Chrome", country: "US", referrer: "x.com", pageviews: 2 },
    { host: "b.com", device: "Desktop", browser: "Safari", country: "SG", referrer: "$direct", pageviews: 9 },
  ];

  it("sums one dimension, largest first", () => {
    expect(dimensionTotals(ROWS, "browser", null)).toEqual([
      { name: "Safari", pageviews: 9 },
      { name: "Chrome", pageviews: 7 },
    ]);
  });

  it("narrows to a site, counting its www host", () => {
    expect(dimensionTotals(ROWS, "country", "a.com")).toEqual([{ name: "United States", pageviews: 7 }]);
  });

  it("names direct traffic in words", () => {
    expect(dimensionTotals(ROWS, "referrer", null)[0]).toEqual({ name: "Direct", pageviews: 14 });
  });

  it("keeps the host in a path until one site is chosen", () => {
    const rows = [
      { host: "a.com", path: "/", pageviews: 2 },
      { host: "b.com", path: "/", pageviews: 3 },
    ];
    expect(pathTotals(rows, null).map((p) => p.name)).toEqual(["b.com/", "a.com/"]);
    expect(pathTotals(rows, "a.com")).toEqual([{ name: "/", pageviews: 2 }]);
  });

  it("sums Vercel's per-project breakdowns", () => {
    const projects = [
      project({ countries: [{ name: "US", pageviews: 4 }] }),
      project({ project: "b", domain: "b.com", countries: [{ name: "US", pageviews: 1 }, { name: "DE", pageviews: 2 }] }),
    ];
    expect(vercelTotals(projects, "countries", null)).toEqual([
      { name: "United States", pageviews: 5 },
      { name: "Germany", pageviews: 2 },
    ]);
    expect(vercelTotals(projects, "countries", "b.com")[0]).toEqual({ name: "Germany", pageviews: 2 });
  });

  it("words Vercel's values the way PostHog's panels do", () => {
    const projects = [
      project({
        referrers: [{ name: "(none)", pageviews: 3 }],
        devices: [{ name: "desktop", pageviews: 2 }],
      }),
    ];
    expect(vercelTotals(projects, "referrers", null)).toEqual([{ name: "Direct", pageviews: 3 }]);
    expect(vercelTotals(projects, "devices", null)).toEqual([{ name: "Desktop", pageviews: 2 }]);
  });

  it("shows a value that is not a country code as it came", () => {
    expect(countryName("Unknown")).toBe("Unknown");
    expect(countryName("JP")).toBe("Japan");
  });
});

describe("web vitals", () => {
  it("rates on the published boundaries", () => {
    expect(vitalRating("lcp", 2500)).toBe("good");
    expect(vitalRating("lcp", 2501)).toBe("fair");
    expect(vitalRating("lcp", 4001)).toBe("poor");
    expect(vitalRating("cls", 0.05)).toBe("good");
  });

  it("rates every measured vital of a row and leaves an unmeasured one unrated", () => {
    expect(rateVitals({ host: "www.a.com", samples: 3, lcp: 4500, inp: 300, cls: 0.05, fcp: null })).toEqual({
      host: "www.a.com",
      samples: 3,
      lcp: 4500,
      inp: 300,
      cls: 0.05,
      fcp: null,
      site: "a.com",
      ratings: { lcp: "poor", inp: "fair", cls: "good", fcp: null },
    });
  });
});

const answered = <T,>(data: T | null): { data: T | null; error: null; updatedAt: null } => ({ data, error: null, updatedAt: null });
const sections = (over: Partial<DashboardSections<AnalyticsSectionData>>): DashboardSections<AnalyticsSectionData> => ({
  traffic: answered(null),
  dimensions: answered(null),
  paths: answered(null),
  vitals: answered(null),
  health: answered(null),
  vercel: answered(null),
  ...over,
});
const dimension = (host: string, browser: string, pageviews: number) => ({ host, device: "Desktop", browser, country: "US", referrer: "$direct", pageviews });
const vital = (host: string) => ({ host, samples: 1, lcp: 1, inp: 1, cls: 1, fcp: null });

describe("analyticsSites", () => {
  it("lists every site alphabetically, whichever provider reported it, as one site however it is spelled", () => {
    const traffic = { ...TRAFFIC, sites: [{ host: "www.zeta.example.com", pageviews: 9, sessions: 9, series: [] }, { host: "zeta.example.com", pageviews: 1, sessions: 1, series: [] }] };
    const result = analyticsSites(
      sections({
        traffic: answered(traffic) as never,
        vitals: answered([vital("vitals.example.com")]) as never,
        dimensions: answered({ rows: [dimension("dims.example.com", "Chrome", 1)], truncated: false }) as never,
        paths: answered([{ host: "paths.example.com", path: "/", pageviews: 1 }]) as never,
      }),
    );
    expect(result).toEqual(["dims.example.com", "paths.example.com", "vitals.example.com", "zeta.example.com"]);
  });

  it("includes a project with analytics off and one with no domain, so neither is unfindable", () => {
    const vercel = {
      ...VERCEL,
      projects: [],
      roster: [
        { project: "off-production", domain: "off.example.com", analyticsOn: false, pageviews: null, visitors: null },
        { project: "bare-production", domain: null, analyticsOn: true, pageviews: 0, visitors: 0 },
      ],
    };
    expect(analyticsSites(sections({ vercel: answered(vercel) as never }))).toEqual(["bare-production", "off.example.com"]);
  });

  it("does not add a host that only has health, which would add every API", () => {
    const health = [{ host: "api.example.com", errors: 1, requests: 1, failures: 0, p95Ms: 1 }];
    expect(analyticsSites(sections({ health: answered(health) as never }))).toEqual([]);
  });

  it("has nothing to list before anything has answered", () => {
    expect(analyticsSites(sections({}))).toEqual([]);
  });
});

describe("siteReport", () => {
  const everything = sections({
    traffic: answered(TRAFFIC) as never,
    vercel: answered({ ...VERCEL, projects: [project({ countries: [{ name: "FR", pageviews: 4 }], paths: [{ name: "/x", pageviews: 4 }] })], roster: [{ project: "a-production", domain: "a.com", analyticsOn: true, pageviews: 10, visitors: 5 }] }) as never,
    dimensions: answered({ rows: [dimension("www.a.com", "Chrome", 2), dimension("a.com", "Safari", 1), dimension("b.com", "Chrome", 9)], truncated: false }) as never,
    paths: answered([{ host: "a.com", path: "/p", pageviews: 2 }]) as never,
    vitals: answered([vital("www.a.com"), vital("b.com")]) as never,
    health: answered([
      { host: "www.a.com", errors: 1, requests: 10, failures: 1, p95Ms: 100 },
      { host: "a.com", errors: 2, requests: 10, failures: 0, p95Ms: 300 },
    ]) as never,
  });

  it("gathers one site's figures across its hosts: counts add, and p95 is the worse one", () => {
    const report = siteReport(everything, "a.com");
    expect(report.posthog).toEqual({ pageviews: 7, sessions: 4 });
    expect(report.vercel).toEqual({ pageviews: 10, visitors: 5 });
    expect(report.health).toMatchObject({ errors: 3, requests: 20, failures: 1, p95Ms: 300, failureRateHigh: true });
    expect(report.projects.map((row) => row.project)).toEqual(["a-production"]);
    expect(report.vitals.map((row) => row.host)).toEqual(["www.a.com"]);
    expect(report.vercelIncomplete).toBe(false);
    expect(report.empty).toBe(false);
  });

  it("charts the site from each provider that counted it", () => {
    expect(siteReport(everything, "a.com").pageviews).toEqual({ labels: BUCKETS, posthog: [4, 3], vercel: [4, 6] });
    expect(siteReport(everything, "b.com").pageviews).toEqual({ labels: BUCKETS, posthog: [1, 5], vercel: null });
    expect(siteReport(everything, "gone.example.com").pageviews).toBeNull();
  });

  it("says when this site's Vercel breakdown is short, and not another site's", () => {
    const short = sections({
      vercel: answered({ ...VERCEL, incomplete: 1, projects: [project({ incomplete: true })] }) as never,
    });
    expect(siteReport(short, "a.com").vercelIncomplete).toBe(true);
    expect(siteReport(short, "b.com").vercelIncomplete).toBe(false);
  });

  it("lists breakdowns in page order, with the bare path on Pages and each provider's own list", () => {
    const report = siteReport(everything, "a.com");
    expect(report.breakdowns.map((b) => b.topic)).toEqual(["pages", "countries", "referrers", "devices", "browsers"]);
    expect(report.breakdowns[0]).toEqual({
      topic: "pages",
      posthog: [{ name: "/p", pageviews: 2 }],
      vercel: [{ name: "/x", pageviews: 4 }],
    });
    expect(report.breakdowns[1]).toEqual({
      topic: "countries",
      posthog: [{ name: "United States", pageviews: 3 }],
      vercel: [{ name: "France", pageviews: 4 }],
    });
  });

  it("leaves off a provider's list that is empty, and a card with none", () => {
    const report = siteReport(everything, "b.com");
    expect(report.vercel).toBeNull();
    expect(report.health).toBeNull();
    expect(report.projects).toEqual([]);
    expect(report.breakdowns.map((b) => b.topic)).toEqual(["countries", "referrers", "devices", "browsers"]);
    expect(report.breakdowns.every((b) => b.vercel === null)).toBe(true);
  });

  it("treats a figure of zero as absent", () => {
    const idle = sections({
      traffic: answered({ ...TRAFFIC, sites: [{ host: "idle.com", pageviews: 0, sessions: 0, series: [] }] }) as never,
      health: answered([{ host: "idle.com", errors: 0, requests: 0, failures: 0, p95Ms: null }]) as never,
    });
    const report = siteReport(idle, "idle.com");
    expect(report.posthog).toBeNull();
    expect(report.health).toBeNull();
    expect(report.pageviews).toBeNull();
    expect(report.empty).toBe(true);
  });

  it("keeps zero errors on a site that served requests: that is the finding", () => {
    const clean = sections({ health: answered([{ host: "clean.com", errors: 0, requests: 5, failures: 0, p95Ms: null }]) as never });
    expect(siteReport(clean, "clean.com").health).toMatchObject({ errors: 0, requests: 5, failureRateHigh: false });
  });

  it("is empty for a site nothing knows, and a project with analytics off is not empty", () => {
    expect(siteReport(everything, "gone.example.com").empty).toBe(true);
    const off = sections({
      vercel: answered({ ...VERCEL, projects: [], roster: [{ project: "off-production", domain: "off.com", analyticsOn: false, pageviews: null, visitors: null }] }) as never,
    });
    const report = siteReport(off, "off.com");
    expect(report.projects).toHaveLength(1);
    expect(report.empty).toBe(false);
  });
});

describe("sectionFailures", () => {
  const failed = (error: string) => ({ data: null, error, updatedAt: null });
  const on = { posthog: true, vercel: true };

  it("names what could not be read, one line per source and error", () => {
    const result = sectionFailures(sections({ traffic: failed("boom"), vitals: failed("boom"), health: failed("other"), vercel: failed("boom") }), on);
    expect(result).toEqual([
      { source: "PostHog", what: ["traffic", "web vitals"], error: "boom" },
      { source: "PostHog", what: ["health"], error: "other" },
      { source: "Vercel", what: ["traffic"], error: "boom" },
    ]);
  });

  it("leaves out a section with last-good data, because its card says so, and a provider that is off", () => {
    const stale = { data: [], error: "boom", updatedAt: null };
    expect(sectionFailures(sections({ vitals: stale as never }), on)).toEqual([]);
    expect(sectionFailures(sections({ vercel: failed("boom") }), { posthog: true, vercel: false })).toEqual([]);
  });
});

describe("analyticsViews", () => {
  const all = sections({
    traffic: answered(TRAFFIC) as never,
    vercel: answered({ ...VERCEL, projects: [...VERCEL.projects, project({ project: "idle", domain: "idle.com", pageviews: 0, visitors: 0 })] }) as never,
    paths: answered([{ host: "www.a.com", path: "/", pageviews: 2 }]) as never,
    vitals: answered([vital("www.a.com")]) as never,
    health: answered([{ host: "api.example.com", errors: 1, requests: 2, failures: 1, p95Ms: 5 }]) as never,
  });
  const views = analyticsViews(all, { posthog: true, vercel: true });

  it("draws the overview from the sections: list, table, chart, top lists and rated vitals", () => {
    expect(views.sites).toEqual(["a.com", "b.com", "idle.com", "orphan-production"]);
    expect(views.joined.map((row) => row.key)).toEqual(["a.com", "b.com", "orphan-production", "idle.com"]);
    expect(views.pageviews).toEqual(pageviewSeries(TRAFFIC, all.vercel.data, null));
    expect(views.pages).toEqual([{ name: "a.com/", pageviews: 2 }]);
    expect(views.dimensions).toBeNull();
    expect(views.vitals?.[0]).toMatchObject({ site: "a.com", ratings: { lcp: "good" } });
  });

  it("lists only the Vercel projects that counted pageviews, named by their site", () => {
    expect(views.vercelProjects).toEqual([
      { site: "a.com", project: "a-production", pageviews: 10, visitors: 5 },
      { site: "orphan-production", project: "orphan-production", pageviews: 1, visitors: 1 },
    ]);
    expect(views.vercelBreakdowns).toEqual({ countries: [], referrers: [], paths: [], devices: [] });
  });

  it("has a report for every listed site, and for a host with only health so a deep link to it still draws", () => {
    expect(Object.keys(views.siteReports).sort()).toEqual([...views.sites, "api.example.com"].sort());
    expect(views.siteReports["api.example.com"]!.health).toMatchObject({ errors: 1, failureRateHigh: true });
  });

  it("answers null, not empty, for a provider that has not answered", () => {
    const none = analyticsViews(sections({}), { posthog: true, vercel: true });
    expect(none).toMatchObject({ sites: [], joined: [], pages: null, dimensions: null, vercelProjects: null, vercelBreakdowns: null, vitals: null });
  });
});

// ── Errors ──────────────────────────────────────────────────────────────────

const ok = <T,>(data: T): DashboardSection<T> => ({ data, error: null, updatedAt: "2026-11-04T00:00:00Z" });
const failed = <T,>(error: string): DashboardSection<T> => ({ data: null, error, updatedAt: null });

const health = (host: string, requests: number, errors = 0, failures = 0, p95Ms: number | null = null): SiteHealthRow => ({
  host,
  requests,
  errors,
  failures,
  p95Ms,
});

const error = (host: string, count: number, lastSeen: string | null = null): SiteErrorRow => ({
  host,
  name: "TypeError",
  feature: "checkout",
  step: null,
  boundary: null,
  page: "/pay",
  count,
  lastSeen,
});

const request = (host: string, path: string, count: number, lastSeen: string | null = null): SiteFailedRequestRow => ({
  host,
  status: 0,
  method: "POST",
  path,
  count,
  lastSeen,
});

const NO_DETAIL: SiteErrorDetailSection = { buckets: [], days: [], errors: [], requests: [], truncated: false };

function errorSections(sites: SiteHealthRow[], detail: Partial<SiteErrorDetailSection> = {}): DashboardSections<ErrorsSectionData> {
  return {
    issues: { data: null, error: null, updatedAt: null },
    sites: ok(sites),
    detail: ok({ ...NO_DETAIL, ...detail }),
    runtime: { data: null, error: null, updatedAt: null },
  };
}

describe("errorsSiteRows", () => {
  it("joins www to its site, names the row by its key and puts the busiest first", () => {
    const rows = errorsSiteRows(errorSections([health("www.a.com", 5, 1, 1, 100), health("a.com", 5, 1, 2, 300), health("b.com", 50)]));
    expect(rows.map((row) => row.host)).toEqual(["b.com", "a.com"]);
    expect(rows[1]).toEqual({ host: "a.com", requests: 10, errors: 2, failures: 3, p95Ms: 300, failureRateHigh: true });
  });
});

describe("mostErrorSites", () => {
  it("ranks sites by errors reported, drops the ones with none and stops at the limit", () => {
    const rows = mostErrorSites(
      errorSections([
        health("quiet.com", 900),
        health("www.a.com", 5, 2),
        health("a.com", 5, 2),
        health("b.com", 50, 6),
        health("c.com", 10, 1, 4),
        health("d.com", 10, 1, 1),
      ]),
      3,
    );
    expect(rows.map((row) => [row.host, row.errors])).toEqual([
      ["b.com", 6],
      ["a.com", 4],
      ["c.com", 1],
    ]);
  });
});

describe("errorsSites", () => {
  it("lists every site alphabetically, whichever section reported it", () => {
    expect(
      errorsSites(
        errorSections([health("c.com", 1), health("www.a.com", 1)], {
          errors: [error("b.com", 1)],
          requests: [request("d.com", "/x", 1)],
          days: [{ host: "e.com", errors: [0], failures: [0] }],
        }),
      ),
    ).toEqual(["a.com", "b.com", "c.com", "d.com", "e.com"]);
  });

  it("is empty before anything has loaded", () => {
    expect(errorsSites({ ...errorSections([]), sites: failed("down"), detail: failed("down") })).toEqual([]);
  });
});

describe("errorsSiteReport", () => {
  it("adds a site's hosts together, and leaves other sites out", () => {
    const report = errorsSiteReport(
      errorSections([health("a.com", 10, 3, 2)], {
        buckets: ["d1", "d2"],
        days: [
          { host: "a.com", errors: [1, 0], failures: [0, 1] },
          { host: "www.a.com", errors: [0, 2], failures: [0, 1] },
          { host: "b.com", errors: [9, 9], failures: [9, 9] },
        ],
        errors: [error("a.com", 1, "2026-11-01T00:00:00Z"), error("www.a.com", 2, "2026-11-03T00:00:00Z"), error("b.com", 9)],
        requests: [request("a.com", "/small", 1), request("a.com", "/big", 7), request("b.com", "/other", 9)],
      }),
      "a.com",
    );
    expect(report.chart).toEqual({ buckets: ["d1", "d2"], errors: [1, 2], failures: [0, 2] });
    expect(report.errors).toEqual([
      { ...error("a.com", 3), lastSeen: "2026-11-03T00:00:00Z", id: JSON.stringify(["TypeError", "checkout", null, null, "/pay"]) },
    ]);
    expect(report.requests.map((row) => row.path)).toEqual(["/big", "/small"]);
    expect(report.requests[0]!.id).toBe(JSON.stringify([0, "POST", "/big"]));
  });

  it("keeps a clean site's health but draws no chart or tables for it", () => {
    const report = errorsSiteReport(
      errorSections([health("a.com", 10)], { buckets: ["d1"], days: [{ host: "a.com", errors: [0], failures: [0] }] }),
      "a.com",
    );
    expect(report.health?.requests).toBe(10);
    expect(report.chart).toBeNull();
    expect(report.errors).toEqual([]);
    expect(report.requests).toEqual([]);
    expect(report.empty).toBe(false);
  });

  it("has nothing for a site nothing reported", () => {
    const report = errorsSiteReport(errorSections([health("a.com", 10), health("quiet.com", 0)]), "quiet.com");
    expect(report.health).toBeNull();
    expect(report.empty).toBe(true);
  });
});

describe("errorsSiteFailures", () => {
  it("names what could not be read, one line per error", () => {
    expect(errorsSiteFailures({ ...errorSections([]), sites: failed("down"), detail: failed("down") })).toEqual([
      { source: "PostHog", what: ["site totals", "errors and failed requests"], error: "down" },
    ]);
  });

  it("does not count a section still holding last good data", () => {
    const stale = { ...ok(NO_DETAIL), error: "down" };
    expect(errorsSiteFailures({ ...errorSections([]), detail: stale })).toEqual([]);
  });
});

describe("errorsViews", () => {
  it("lists the sites, ranks the most errors and reports each listed site", () => {
    const views = errorsViews(errorSections([health("a.com", 10, 3), health("b.com", 5)]), { posthog: true });
    expect(views.sites).toEqual(["a.com", "b.com"]);
    expect(views.mostErrors.map((row) => row.host)).toEqual(["a.com"]);
    expect(views.mostErrorsLimit).toBe(10);
    expect(Object.keys(views.siteReports)).toEqual(["a.com", "b.com"]);
    expect(views.siteReports["a.com"]!.health?.errors).toBe(3);
  });

  it("reports no read failures for PostHog when PostHog is not configured", () => {
    const down = { ...errorSections([]), sites: failed<SiteHealthRow[]>("down"), detail: failed<SiteErrorDetailSection>("down") };
    expect(errorsViews(down, { posthog: false }).siteFailures).toEqual([]);
    expect(errorsViews(down, { posthog: true }).siteFailures).toHaveLength(1);
  });
});
