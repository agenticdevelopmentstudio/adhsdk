// The product admin site's rail (@adh-sdk/product-admin's PRODUCT_ADMIN_TOPICS) against the
// site's share of the route table, which is generated from its App Router tree. The two drifting
// apart is a page with no rail entry, or a rail entry with no page.
import { describe, expect, it } from "vitest";
import { PRODUCT_ADMIN_TOPICS } from "@adh-sdk/product-admin/topics";
import { SITE_ROUTES } from "../routes.generated";

// The site's routes that are not rail pages: the root sends a person on to /users, and
// /no-access is where a signed-in person without the admin role lands.
const NOT_ON_THE_RAIL = new Set(["/", "/no-access"]);

describe("the product-admin rail", () => {
  it("has one topic per page route of the product-admin site", () => {
    const pages = (SITE_ROUTES["product-admin"] ?? []).filter((r) => !NOT_ON_THE_RAIL.has(r));
    expect(pages.length).toBeGreaterThan(0);
    expect(PRODUCT_ADMIN_TOPICS.map((t) => t.href).sort()).toEqual([...pages].sort());
  });
});
