// The product admin console's rail (phase 6): one entry per page, in rail order. Each `href` is a
// page route of the `product-sites` site (adh-registry's `SITE_ROUTES['product-sites']`), where
// the console lives under `/admin`; the topics test holds the two equal. That site is the only
// reader, which is why the prefix is spelled here rather than added by the host. Plain data, no
// React, so the site's console layout can import it from a server component
// (`@adh-sdk/product-admin/topics`).

export interface ProductAdminTopic {
  id: string;
  label: string;
  href: string;
}

export const PRODUCT_ADMIN_TOPICS: readonly ProductAdminTopic[] = [
  { id: "users", label: "Users", href: "/admin/users" },
  { id: "requests", label: "Requests", href: "/admin/requests" },
  { id: "pending", label: "Pending users", href: "/admin/pending" },
  { id: "invites", label: "Invites", href: "/admin/invites" },
  { id: "roles", label: "Roles", href: "/admin/roles" },
  { id: "signup-list", label: "Sign-up list", href: "/admin/signup-list" },
  { id: "sets", label: "Sets", href: "/admin/sets" },
  { id: "jobs", label: "Jobs", href: "/admin/jobs" },
  { id: "totals", label: "Totals", href: "/admin/totals" },
  { id: "support", label: "Support", href: "/admin/support" },
];
