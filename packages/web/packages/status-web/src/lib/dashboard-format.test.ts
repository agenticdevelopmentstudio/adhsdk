import { describe, expect, it } from "vitest";
import { bucketDetail, bucketLabel, formatVital, listedSites, siteReportFor, withSite } from "./dashboard-format";
import type { AnalyticsRange } from "../telemetry/dashboard-types";

describe("bucket labels", () => {
  it("dfmt-001: labels a UTC day on long ranges", () => {
    expect(bucketLabel("2026-11-04T00:00:00.000Z", "7d")).toBe("Nov 4");
  });
  it("dfmt-002: labels an hour on 24h", () => {
    expect(bucketLabel("2026-11-04T14:00:00.000Z", "24h")).toBe("14:00");
  });
  it("dfmt-003: detail on 24h names the day, hour and UTC", () => {
    expect(bucketDetail("2026-11-04T14:00:00.000Z", "24h")).toBe("Nov 4, 14:00 UTC");
  });
  it("dfmt-004: detail on long ranges names the day and UTC", () => {
    expect(bucketDetail("2026-11-04T00:00:00.000Z", "30d")).toBe("Nov 4 (UTC)");
  });
  it("dfmt-016: an invalid date throws a range error", () => {
    expect(() => bucketLabel("not-a-date", "7d")).toThrow(RangeError);
  });
  it("dfmt-020: an unknown range uses the day format", () => {
    expect(bucketLabel("2026-11-04T00:00:00.000Z", "1y" as AnalyticsRange)).toBe("Nov 4");
  });
  it("dfmt-021: a late-UTC-day instant labels the earlier day", () => {
    expect(bucketLabel("2026-11-04T23:59:59.999Z", "7d")).toBe("Nov 4");
  });
});

describe("formatVital", () => {
  it("dfmt-005: writes each vital in its unit", () => {
    expect(formatVital("lcp", 2400)).toBe("2.4s");
    expect(formatVital("inp", 180)).toBe("180ms");
    expect(formatVital("cls", 0.1)).toBe("0.10");
  });
  it("dfmt-014: the 1000 threshold applies before rounding", () => {
    expect(formatVital("lcp", 999.6)).toBe("1000ms");
    expect(formatVital("lcp", 1000)).toBe("1.0s");
  });
  it("dfmt-015: values are not validated", () => {
    expect(formatVital("inp", -5)).toBe("-5ms");
    expect(formatVital("cls", NaN)).toBe("NaN");
  });
  it("dfmt-019: rounds milliseconds below the threshold", () => {
    expect(formatVital("lcp", 999.4)).toBe("999ms");
  });
});

describe("listedSites", () => {
  it("dfmt-006: is the server's list when the read has one", () => {
    expect(listedSites({ views: { sites: ["a.com", "b.com"] } })).toEqual(["a.com", "b.com"]);
  });
  it("dfmt-007: is null, not a throw, before a read and from a backend older than views", () => {
    expect(listedSites(undefined)).toBeNull();
    expect(listedSites({})).toBeNull();
    expect(listedSites({ views: {} })).toBeNull();
  });
  it("dfmt-013: an empty list is an empty list, not null", () => {
    expect(listedSites({ views: { sites: [] } })).toEqual([]);
  });
});

describe("withSite", () => {
  it("dfmt-008: keeps the server's list when the site is on it or none is chosen", () => {
    expect(withSite(["a.com", "c.com"], "c.com")).toEqual(["a.com", "c.com"]);
    expect(withSite(["a.com"], null)).toEqual(["a.com"]);
  });
  it("dfmt-009: puts a deep-linked site the server does not list in its alphabetical place", () => {
    expect(withSite(["a.com", "c.com"], "b.com")).toEqual(["a.com", "b.com", "c.com"]);
  });
  it("dfmt-012: returns an equal list that is a copy", () => {
    const sites = ["a.com"];
    const out = withSite(sites, "a.com");
    expect(out).toEqual(sites);
    expect(out).not.toBe(sites);
  });
  it("dfmt-017: sorts the whole list", () => {
    expect(withSite(["c.com", "a.com"], "b.com")).toEqual(["a.com", "b.com", "c.com"]);
  });
  it("dfmt-018: the lookup is case-sensitive, so a differently-cased site is added", () => {
    const out = withSite(["a.com"], "A.com");
    expect(out).toHaveLength(2);
    expect([...out].sort()).toEqual(["A.com", "a.com"]);
  });
});

describe("siteReportFor", () => {
  const none = { empty: true };
  const reports: Record<string, { empty: boolean }> = { "example.com": { empty: false } };

  it("dfmt-010: returns the server's report for a site it sent", () => {
    expect(siteReportFor(reports, "example.com", none)).toEqual({ empty: false });
  });
  it.each(["unknown.com", "constructor", "toString", "hasOwnProperty", "__proto__"])(
    "dfmt-011: treats %s, which the server did not send, as no report",
    (site) => {
      expect(siteReportFor(reports, site, none)).toBe(none);
    },
  );
  it("dfmt-022: an empty reports object and empty site give the none value", () => {
    expect(siteReportFor({}, "", none)).toBe(none);
  });
});
