import { describe, expect, it } from "vitest";
import type { TrafficSection, VercelProjectTraffic, VercelTrafficSection } from "../telemetry/dashboard-types";
import {
  bucketDetail,
  bucketLabel,
  countryName,
  dimensionTotals,
  formatVital,
  joinSites,
  pageviewSeries,
  pathTotals,
  siteKey,
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
    ...over,
  };
}

const VERCEL: VercelTrafficSection = {
  buckets: BUCKETS,
  projectsTotal: 3,
  projectsEnabled: 2,
  failed: 0,
  totals: { pageviews: 11, visitors: 6 },
  pageviews: [4, 7],
  visitors: [2, 4],
  projects: [project({}), project({ project: "orphan-production", domain: null, pageviews: 1, visitors: 1, series: [0, 1] })],
};

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
