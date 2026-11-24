// The product admin site's rail: one topic per page, in rail order. That every href is a page of
// the site is checked against the route table in @adh-sdk/adh-registry
// (src/sites/__tests__/product-admin-topics.test.ts): this package is portable and may not import
// the registry.
import { describe, expect, it } from "vitest";
import { PRODUCT_ADMIN_TOPICS } from "../product-admin-topics";

describe("PRODUCT_ADMIN_TOPICS", () => {
  it("names the ten pages in rail order, ids unique", () => {
    expect(PRODUCT_ADMIN_TOPICS.map((t) => t.href)).toEqual([
      "/users",
      "/requests",
      "/pending",
      "/invites",
      "/roles",
      "/signup-list",
      "/sets",
      "/jobs",
      "/totals",
      "/support",
    ]);
    expect(new Set(PRODUCT_ADMIN_TOPICS.map((t) => t.id)).size).toBe(PRODUCT_ADMIN_TOPICS.length);
  });
});
