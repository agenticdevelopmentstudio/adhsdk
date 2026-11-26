// The product admin console's rail: one topic per page, in rail order, every one under `/admin`
// (the console's place on the product's own site). That every href is a page of the site is
// checked against the route table in @adh-sdk/adh-registry
// (src/sites/__tests__/product-sites-topics.test.ts): this package is portable and may not import
// the registry.
import { describe, expect, it } from "vitest";
import { PRODUCT_ADMIN_TOPICS } from "../product-admin-topics";

describe("PRODUCT_ADMIN_TOPICS", () => {
  it("names the ten pages in rail order, ids unique", () => {
    expect(PRODUCT_ADMIN_TOPICS.map((t) => t.href)).toEqual([
      "/admin/users",
      "/admin/requests",
      "/admin/pending",
      "/admin/invites",
      "/admin/roles",
      "/admin/signup-list",
      "/admin/sets",
      "/admin/jobs",
      "/admin/totals",
      "/admin/support",
    ]);
    expect(new Set(PRODUCT_ADMIN_TOPICS.map((t) => t.id)).size).toBe(PRODUCT_ADMIN_TOPICS.length);
  });

  it("keeps every page under /admin and off the console's auth routes", () => {
    for (const t of PRODUCT_ADMIN_TOPICS) {
      expect(t.href.startsWith("/admin/"), t.href).toBe(true);
      expect(t.href.startsWith("/admin/auth"), t.href).toBe(false);
    }
  });
});
