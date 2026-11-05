import { describe, expect, it } from "vitest";
import type {
  AnalyticsSectionData,
  DashboardSections,
  TrafficSection,
  VercelProjectTraffic,
  VercelTrafficSection,
} from "../telemetry/dashboard-types";
import {
  analyticsSites,
  breakdownTotals,
  bucketDetail,
  bucketLabel,
  countryName,
  dimensionTotals,
  formatVital,
  joinSites,
  pageviewSeries,
  pathTotals,
  sectionFailures,
  siteKey,
  siteReport,
  siteReportIsEmpty,
  vercelTotals,
  vitalRating,
} from "./analytics-model";

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

  it("adds counts across a site's hosts but takes the worse percentile", () => {
    const health = [
      { host: "a.com", errors: 1, requests: 10, failures: 2, p95Ms: 100 },
      { host: "www.a.com", errors: 2, requests: 20, failures: 1, p95Ms: 300 },
    ];
    const a = joinSites(TRAFFIC, null, health).find((r) => r.key === "a.com")!;
    expect(a.health).toMatchObject({ errors: 3, requests: 30, failures: 3, p95Ms: 300 });
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

describe("bucket labels", () => {
  it("reads in UTC, the zone the buckets are cut in", () => {
    expect(bucketLabel("2026-11-04T00:00:00.000Z", "7d")).toBe("Nov 4");
    expect(bucketLabel("2026-11-04T14:00:00.000Z", "24h")).toBe("14:00");
    expect(bucketDetail("2026-11-04T14:00:00.000Z", "24h")).toBe("Nov 4, 14:00 UTC");
  });
});

describe("web vitals", () => {
  it("rates on the published boundaries", () => {
    expect(vitalRating("lcp", 2500)).toBe("good");
    expect(vitalRating("lcp", 2501)).toBe("fair");
    expect(vitalRating("lcp", 4001)).toBe("poor");
    expect(vitalRating("cls", 0.05)).toBe("good");
  });

  it("prints each in its own unit", () => {
    expect(formatVital("lcp", 2400)).toBe("2.4s");
    expect(formatVital("inp", 180)).toBe("180ms");
    expect(formatVital("cls", 0.1)).toBe("0.10");
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
    expect(report.posthog).toMatchObject({ pageviews: 7, sessions: 4 });
    expect(report.vercel).toMatchObject({ pageviews: 10, visitors: 5 });
    expect(report.health).toMatchObject({ errors: 3, requests: 20, failures: 1, p95Ms: 300 });
    expect(report.projects.map((row) => row.project)).toEqual(["a-production"]);
    expect(report.vitals.map((row) => row.host)).toEqual(["www.a.com"]);
    expect(report.vercelIncomplete).toBe(false);
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
    expect(siteReportIsEmpty(report)).toBe(true);
  });

  it("keeps zero errors on a site that served requests: that is the finding", () => {
    const clean = sections({ health: answered([{ host: "clean.com", errors: 0, requests: 5, failures: 0, p95Ms: null }]) as never });
    expect(siteReport(clean, "clean.com").health).toMatchObject({ errors: 0, requests: 5 });
  });

  it("is empty for a site nothing knows, and a project with analytics off is not empty", () => {
    expect(siteReportIsEmpty(siteReport(everything, "gone.example.com"))).toBe(true);
    const off = sections({
      vercel: answered({ ...VERCEL, projects: [], roster: [{ project: "off-production", domain: "off.com", analyticsOn: false, pageviews: null, visitors: null }] }) as never,
    });
    const report = siteReport(off, "off.com");
    expect(report.projects).toHaveLength(1);
    expect(siteReportIsEmpty(report)).toBe(false);
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
