// @adh-sdk/data/product-admin: a product's admin site (phase 6). The hub's managers set the site
// up and read the totals; the product's own admins read the totals and the roster and pause,
// re-quota or delete a customer at the site. Hand-written wire types, as every client in this
// package (see ../sets/wire.ts).
export * from "./product-totals";
export * from "./product-customers";
export * from "./admin-site";

/**
 * The most storage a product admin may give one customer: 5 GiB. Mirrors the backend's
 * `DEFAULT_QUOTA_BYTES` (adhbackend `src/lib/storageQuota.ts`), which refuses (403) any quota a
 * product admin writes above it, through a set's `storage.quota_bytes` value or the roster.
 */
export const DEFAULT_QUOTA_BYTES = 5_368_709_120;
