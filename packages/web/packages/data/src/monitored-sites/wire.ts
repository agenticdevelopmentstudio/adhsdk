// Local wire types for the Monitored-Sites clients — the /v1 row + request-body shapes the
// clients read/send (see projects/wire.ts for the pattern: these replace the hub's generated
// `SuccessBody<...>` / `RequestBody<...>` from `@adh-sdk/adh-api-types`, adh product
// vocabulary a generic data client must not take on). Each interface carries exactly
// the fields the mappers/call sites touch. snake_case, with unix-second `created`/`updated`;
// monitored-sites.ts maps them onto the camelCase views.
// Type-only file.

/* ── Site groups ──────────────────────────────────────────────────────── */

/** Row of `GET /v1/monitoring/site_groups` (and a single group). */
export interface GroupRow {
  id: string;
  slug: string;
  name: string;
  retention_days: number;
  created: number;
  updated: number;
}

/* ── Sites ────────────────────────────────────────────────────────────── */

/** Row of `GET /v1/monitoring/sites` (and a single site). */
export interface SiteRow {
  id: string;
  slug: string;
  name: string;
  site_group_id: string;
  created: number;
  updated: number;
}

/** `POST /v1/monitoring/sites` body — the backend's `site_group_id`, named
 *  `groupId` in the client's `CreateSiteBody`. */
export interface SiteCreateBody {
  name: string;
  slug: string;
  site_group_id: string;
}

/** `POST /v1/monitoring/sites/{id}` body — same rename as `SiteCreateBody`. */
export interface SitePutBody {
  name?: string;
  slug?: string;
  site_group_id?: string;
}

/* ── Endpoints ────────────────────────────────────────────────────────── */

/** Row of `GET /v1/monitoring/endpoints` (and a single endpoint). */
export interface EndpointRow {
  id: string;
  site_id: string;
  url: string;
  kind: string;
  expected_status: number;
  check_interval_seconds: number;
  is_active: boolean;
  created: number;
  updated: number;
}

/** `POST /v1/monitoring/endpoints` body — adds the `site_id` the client's
 *  `CreateEndpointBody` doesn't carry (it's a separate function argument). */
export interface EndpointCreateBody {
  site_id: string;
  url: string;
  kind?: string;
  expected_status?: number;
  check_interval_seconds?: number;
  is_active?: boolean;
}

/** `POST /v1/monitoring/site_groups` body (the fields this client sends). */
export interface GroupCreateBody {
  name: string;
  slug: string;
  retention_days?: number;
}

/** `POST /v1/monitoring/site_groups/{id}` body (all-optional partial update). */
export interface GroupPutBody {
  name?: string;
  slug?: string;
  retention_days?: number;
}

/** `POST /v1/monitoring/endpoints/{id}` body (the fields this client sends). */
export interface EndpointPutBody {
  url?: string;
  kind?: string;
  expected_status?: number;
  check_interval_seconds?: number;
  is_active?: boolean;
}
