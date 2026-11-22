// The product admin site's rail (phase 6): one entry per page, in rail order. Each `href` is a
// page route of the `product-admin` site (adh-registry's `SITE_ROUTES['product-admin']`, Task 10's
// share); the topics test holds the two equal. Plain data, no React, so the site's console layout
// can import it from a server component (`@adh-sdk/product-admin/topics`).

export interface ProductAdminTopic {
  id: string;
  label: string;
  href: string;
}

export const PRODUCT_ADMIN_TOPICS: readonly ProductAdminTopic[] = [
  { id: "users", label: "Users", href: "/users" },
  { id: "requests", label: "Requests", href: "/requests" },
  { id: "pending", label: "Pending users", href: "/pending" },
  { id: "invites", label: "Invites", href: "/invites" },
  { id: "roles", label: "Roles", href: "/roles" },
  { id: "signup-list", label: "Sign-up list", href: "/signup-list" },
  { id: "sets", label: "Sets", href: "/sets" },
  { id: "totals", label: "Totals", href: "/totals" },
];
