import { describe, expect, it } from "vitest";
import { toGroup, toSite, toEndpoint } from "../monitored-sites";

describe("monitored-sites mappers", () => {
  it("toSite renames site_group_id→groupId and maps unix timestamps", () => {
    const s = toSite({
      id: "s1",
      slug: "site",
      name: "Site",
      site_group_id: "g1",
      created: 1700000000,
      updated: 1700000060,
    });
    expect(s.groupId).toBe("g1");
    expect(s.createdAt).toBe(new Date(1700000000 * 1000).toISOString());
    expect(s.updatedAt).toBe(new Date(1700000060 * 1000).toISOString());
  });
  it("toGroup carries the retention window through", () => {
    const g = toGroup({
      id: "g1",
      slug: "grp",
      name: "Grp",
      retention_days: 30,
      created: 1700000000,
      updated: 1700000000,
    });
    expect(g.retentionDays).toBe(30);
  });
  it("toEndpoint preserves the check fields", () => {
    const e = toEndpoint({
      id: "e1",
      site_id: "s1",
      url: "https://x",
      kind: "http",
      expected_status: 200,
      check_interval_seconds: 60,
      is_active: true,
      created: 1700000000,
      updated: 1700000000,
    });
    expect(e.siteId).toBe("s1");
    expect(e.expectedStatus).toBe(200);
    expect(e.checkIntervalSeconds).toBe(60);
    expect(e.isActive).toBe(true);
  });
});
