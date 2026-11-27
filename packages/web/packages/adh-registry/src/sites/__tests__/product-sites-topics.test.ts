// The product admin console's rail (@adh-sdk/product-admin's PRODUCT_ADMIN_TOPICS) against the
// product-sites site's share of the route table, which is generated from its App Router tree.
// The console lives under `/admin` on every product's own site. The two drifting apart is a page
// with no rail entry, or a rail entry with no page.
import { describe, expect, it } from "vitest";
import { PRODUCT_ADMIN_TOPICS } from "@adh-sdk/product-admin/topics";
import { SITE_ROUTES } from "../routes.generated";

// The site's routes that are not rail pages: `/` is the product's own page (its name), `/admin`
// sends a person on to /admin/users, /admin/no-access is where a signed-in person without the
// admin role lands, and /admin/jobs/templates (with a template's own page) is reached from the
// Jobs page (its own topic set, @adh-sdk/jobs' jobsProductAdminTopics), not from the rail.
const NOT_ON_THE_RAIL = new Set([
  "/",
  "/admin",
  "/admin/no-access",
  "/admin/jobs/templates",
  "/admin/jobs/templates/[templateId]",
]);

describe("the product-sites console rail", () => {
  it("has one topic per page route of the product-sites site", () => {
    const pages = (SITE_ROUTES["product-sites"] ?? []).filter((r) => !NOT_ON_THE_RAIL.has(r));
    expect(pages.length).toBeGreaterThan(0);
    expect(PRODUCT_ADMIN_TOPICS.map((t) => t.href).sort()).toEqual([...pages].sort());
  });

  // Phase 7: the Support topic, a product admin's support grants, is a page of the site.
  it("has the Support topic's href in the product-sites share", () => {
    const support = PRODUCT_ADMIN_TOPICS.find((t) => t.id === "support");
    expect(support?.href).toBe("/admin/support");
    expect(SITE_ROUTES["product-sites"]).toContain("/admin/support");
  });

  it("has the operator site's three support pages in the admin share", () => {
    for (const r of ["/support-grants", "/break-glass", "/support-access"]) {
      expect(SITE_ROUTES.admin).toContain(r);
    }
  });

  // site-registry-071: the three Jobs pages, and no Environments page.
  it("has the Jobs pages in the product-sites share, sorted, with no environments", () => {
    const share = SITE_ROUTES["product-sites"] ?? [];
    expect(share).toContain("/admin/jobs");
    expect(share).toContain("/admin/jobs/templates");
    expect(share).toContain("/admin/jobs/templates/[templateId]");
    expect(share.some((r) => r.includes("environments"))).toBe(false);
    expect([...share]).toEqual([...share].sort());
  });

  // The auth route handlers are not pages, so they are in no share. The match is
  // on the /admin/auth segment exactly, so a page like /admin/authors is allowed.
  it("has no page under /admin/auth", () => {
    expect(
      (SITE_ROUTES["product-sites"] ?? []).some((r) => r === "/admin/auth" || r.startsWith("/admin/auth/")),
    ).toBe(false);
  });

  // site-registry-072: the operator's dead jobs are a section of AI Nodes, not a page.
  it("has no /jobs page in the admin share", () => {
    expect(SITE_ROUTES.admin ?? []).not.toContain("/jobs");
  });
});
