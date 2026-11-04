import { describe, expect, it } from "vitest";
import type {
  DashboardSection,
  DashboardSections,
  ErrorsSectionData,
  SiteErrorDetailSection,
  SiteErrorRow,
  SiteFailedRequestRow,
  SiteHealthRow,
} from "../telemetry/dashboard-types";
import {
  errorsSiteFailures,
  errorsSiteReport,
  errorsSiteReportIsEmpty,
  errorsSiteRows,
  errorsSites,
  mostErrorSites,
} from "./errors-model";

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

function sections(sites: SiteHealthRow[], detail: Partial<SiteErrorDetailSection> = {}): DashboardSections<ErrorsSectionData> {
  return {
    issues: { data: null, error: null, updatedAt: null },
    sites: ok(sites),
    detail: ok({ ...NO_DETAIL, ...detail }),
  };
}

describe("errorsSiteRows", () => {
  it("joins www to its site, names the row by its key and puts the busiest first", () => {
    const rows = errorsSiteRows(sections([health("www.a.com", 5, 1, 1, 100), health("a.com", 5, 1, 2, 300), health("b.com", 50)]));
    expect(rows.map((row) => row.host)).toEqual(["b.com", "a.com"]);
    expect(rows[1]).toEqual({ host: "a.com", requests: 10, errors: 2, failures: 3, p95Ms: 300 });
  });
});

describe("mostErrorSites", () => {
  it("ranks sites by errors reported, drops the ones with none and stops at the limit", () => {
    const rows = mostErrorSites(
      sections([
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
        sections([health("c.com", 1), health("www.a.com", 1)], {
          errors: [error("b.com", 1)],
          requests: [request("d.com", "/x", 1)],
          days: [{ host: "e.com", errors: [0], failures: [0] }],
        }),
      ),
    ).toEqual(["a.com", "b.com", "c.com", "d.com", "e.com"]);
  });

  it("is empty before anything has loaded", () => {
    expect(errorsSites({ ...sections([]), sites: failed("down"), detail: failed("down") })).toEqual([]);
  });
});

describe("errorsSiteReport", () => {
  it("adds a site's hosts together, and leaves other sites out", () => {
    const report = errorsSiteReport(
      sections([health("a.com", 10, 3, 2)], {
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
    expect(report.errors).toEqual([{ ...error("a.com", 3), lastSeen: "2026-11-03T00:00:00Z" }]);
    expect(report.requests.map((row) => row.path)).toEqual(["/big", "/small"]);
  });

  it("keeps a clean site's health but draws no chart or tables for it", () => {
    const report = errorsSiteReport(
      sections([health("a.com", 10)], { buckets: ["d1"], days: [{ host: "a.com", errors: [0], failures: [0] }] }),
      "a.com",
    );
    expect(report.health?.requests).toBe(10);
    expect(report.chart).toBeNull();
    expect(report.errors).toEqual([]);
    expect(report.requests).toEqual([]);
    expect(errorsSiteReportIsEmpty(report)).toBe(false);
  });

  it("has nothing for a site nothing reported", () => {
    const report = errorsSiteReport(sections([health("a.com", 10), health("quiet.com", 0)]), "quiet.com");
    expect(report.health).toBeNull();
    expect(errorsSiteReportIsEmpty(report)).toBe(true);
  });
});

describe("errorsSiteFailures", () => {
  it("names what could not be read, one line per error", () => {
    expect(errorsSiteFailures({ ...sections([]), sites: failed("down"), detail: failed("down") })).toEqual([
      { source: "PostHog", what: ["site totals", "errors and failed requests"], error: "down" },
    ]);
  });

  it("does not count a section still holding last good data", () => {
    const stale = { ...ok(NO_DETAIL), error: "down" };
    expect(errorsSiteFailures({ ...sections([]), detail: stale })).toEqual([]);
  });
});
