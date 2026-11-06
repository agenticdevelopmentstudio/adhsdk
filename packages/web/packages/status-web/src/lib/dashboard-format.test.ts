import { describe, expect, it } from "vitest";
import { bucketDetail, bucketLabel, formatVital, withSite } from "./dashboard-format";

describe("bucket labels", () => {
  it("label in UTC: a day on long ranges, an hour on 24h", () => {
    expect(bucketLabel("2026-11-04T00:00:00.000Z", "7d")).toBe("Nov 4");
    expect(bucketLabel("2026-11-04T14:00:00.000Z", "24h")).toBe("14:00");
    expect(bucketDetail("2026-11-04T14:00:00.000Z", "24h")).toBe("Nov 4, 14:00 UTC");
    expect(bucketDetail("2026-11-04T00:00:00.000Z", "30d")).toBe("Nov 4 (UTC)");
  });
});

describe("formatVital", () => {
  it("writes each vital in its unit", () => {
    expect(formatVital("lcp", 2400)).toBe("2.4s");
    expect(formatVital("inp", 180)).toBe("180ms");
    expect(formatVital("cls", 0.1)).toBe("0.10");
  });
});

describe("withSite", () => {
  it("keeps the server's list as it came when the site is on it or none is chosen", () => {
    expect(withSite(["a.com", "c.com"], "c.com")).toEqual(["a.com", "c.com"]);
    expect(withSite(["a.com"], null)).toEqual(["a.com"]);
  });

  it("puts a deep-linked site the server does not list in its alphabetical place", () => {
    expect(withSite(["a.com", "c.com"], "b.com")).toEqual(["a.com", "b.com", "c.com"]);
  });
});
