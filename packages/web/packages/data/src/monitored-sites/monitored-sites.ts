// Status Sites API client — wired to the /v1 monitoring surface:
//   /api/v1/monitoring/site_groups   (groups)
//   /api/v1/monitoring/sites         (sites)
//   /api/v1/monitoring/endpoints     (endpoints)
//
// The wire is snake_case with unix-second timestamps; this client maps rows onto the camelCase
// views and fills the gaps the backend has no filter params for.
//
// MODEL (matches the DB, NOT the old prototype): a site belongs to EXACTLY ONE
// group (`sites.site_group_id`, NOT NULL, FK ON DELETE CASCADE). This is a 1:M
// relationship — the prototype's many-to-many `groupIds[]` is gone. An endpoint
// belongs to exactly one site (same cascade). Deleting a group deletes its sites
// and their endpoints at the DB level; deleting a site deletes its endpoints.
//
// SCOPING: the whole chain is owner-scoped server-side (site_groups by the
// caller's user_id; sites/endpoints INHERIT user_id + owner from their parent at
// create/reparent). An optional `workspace` on every op pins it to the
// WORKSPACE'S owning principal instead (backend `?workspace=<slug>`): list
// returns only that principal's rows, create stamps it as the owner, and item
// update/delete resolve org-owned rows other members created. The client-side
// narrowing in listSites()/listEndpoints() stays as defense-in-depth. Columns
// the UI doesn't model (description, displayOrder, timeoutMs, …) are left to
// their server defaults.

import { authedJson, authedRequest, listAllV1, unixToIso, withV1Query } from "../http";
import { compact, enc, sortByText } from "../client-helpers";
import type {
  GroupRow,
  SiteRow,
  EndpointRow,
  GroupCreateBody,
  GroupPutBody,
  SiteCreateBody,
  SitePutBody,
  EndpointCreateBody,
  EndpointPutBody,
} from "./wire";

export interface SiteGroupView {
  id: string;
  slug: string;
  name: string;
  retentionDays: number;
  createdAt: string;
  updatedAt: string;
}

export interface SiteView {
  id: string;
  slug: string;
  name: string;
  /** The single group this site belongs to (1:M; required). */
  groupId: string;
  createdAt: string;
  updatedAt: string;
}

export interface EndpointView {
  id: string;
  siteId: string;
  url: string;
  kind: string;
  expectedStatus: number;
  checkIntervalSeconds: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateGroupBody {
  name: string;
  slug: string;
  retentionDays?: number;
}

export interface UpdateGroupBody {
  name?: string;
  slug?: string;
  retentionDays?: number;
}

export interface CreateSiteBody {
  name: string;
  slug: string;
  /** Required: a site must belong to a group. */
  groupId: string;
}

export interface UpdateSiteBody {
  name?: string;
  slug?: string;
  groupId?: string;
}

export interface CreateEndpointBody {
  url: string;
  kind: string;
  expectedStatus?: number;
  checkIntervalSeconds?: number;
  isActive?: boolean;
}

export interface UpdateEndpointBody {
  url?: string;
  kind?: string;
  expectedStatus?: number;
  checkIntervalSeconds?: number;
  isActive?: boolean;
}

export const ENDPOINT_KINDS = ["http", "tcp", "icmp"] as const;

const GROUPS = "/api/v1/monitoring/site_groups";
const SITES = "/api/v1/monitoring/sites";
const ENDPOINTS = "/api/v1/monitoring/endpoints";

/** `url` with the optional `?workspace=` pin. */
const scoped = (url: string, opts?: { workspace?: string }): string =>
  withV1Query(url, { workspace: opts?.workspace || undefined });

export function toGroup(r: GroupRow): SiteGroupView {
  return {
    id: r.id,
    slug: r.slug,
    name: r.name,
    retentionDays: r.retention_days,
    createdAt: unixToIso(r.created),
    updatedAt: unixToIso(r.updated),
  };
}

export function toSite(r: SiteRow): SiteView {
  return {
    id: r.id,
    slug: r.slug,
    name: r.name,
    groupId: r.site_group_id,
    createdAt: unixToIso(r.created),
    updatedAt: unixToIso(r.updated),
  };
}

export function toEndpoint(r: EndpointRow): EndpointView {
  return {
    id: r.id,
    siteId: r.site_id,
    url: r.url,
    kind: r.kind,
    expectedStatus: r.expected_status,
    checkIntervalSeconds: r.check_interval_seconds,
    isActive: r.is_active,
    createdAt: unixToIso(r.created),
    updatedAt: unixToIso(r.updated),
  };
}

// --- groups -----------------------------------------------------------------

export async function listGroups(opts?: { workspace?: string }): Promise<SiteGroupView[]> {
  const rows = await listAllV1<GroupRow>(scoped(GROUPS, opts));
  return sortByText(rows.map(toGroup), (g) => g.name);
}

export async function createGroup(
  body: CreateGroupBody,
  opts?: { workspace?: string },
): Promise<SiteGroupView> {
  const row = await authedJson<GroupRow>(scoped(GROUPS, opts), {
    method: "POST",
    body: JSON.stringify(
      compact({
        name: body.name,
        slug: body.slug,
        retention_days: body.retentionDays,
      } satisfies GroupCreateBody),
    ),
  });
  return toGroup(row);
}

export async function updateGroup(
  id: string,
  body: UpdateGroupBody,
  opts?: { workspace?: string },
): Promise<SiteGroupView> {
  const patch = compact({
    name: body.name,
    slug: body.slug,
    retention_days: body.retentionDays,
  } satisfies GroupPutBody);
  const row = await authedJson<GroupRow>(scoped(`${GROUPS}/${enc(id)}`, opts), {
    method: "POST",
    body: JSON.stringify(patch),
  });
  return toGroup(row);
}

export function deleteGroup(id: string, opts?: { workspace?: string }): Promise<void> {
  // FK ON DELETE CASCADE removes the group's sites and their endpoints.
  return authedRequest(scoped(`${GROUPS}/${enc(id)}`, opts), { method: "DELETE" });
}

// --- sites ------------------------------------------------------------------

export async function listSites(opts?: { workspace?: string }): Promise<SiteView[]> {
  // The server owner-scopes `sites` identically to `site_groups` now (both carry the same
  // owner columns and honor `?workspace=`), so a single request suffices. The old code also
  // fetched the groups list and intersected on membership — a second GROUPS round-trip AND a
  // silent-hiding bug: a capped groups list dropped sites whose group fell past the cap even
  // though the server still monitors them. `listAllV1` drains every page.
  const rows = await listAllV1<SiteRow>(scoped(SITES, opts));
  return sortByText(rows.map(toSite), (s) => s.name);
}

export async function createSite(
  body: CreateSiteBody,
  opts?: { workspace?: string },
): Promise<SiteView> {
  const fields: SiteCreateBody = {
    name: body.name,
    slug: body.slug,
    site_group_id: body.groupId,
  };
  const row = await authedJson<SiteRow>(scoped(SITES, opts), {
    method: "POST",
    body: JSON.stringify(fields),
  });
  return toSite(row);
}

export async function updateSite(
  id: string,
  body: UpdateSiteBody,
  opts?: { workspace?: string },
): Promise<SiteView> {
  const patch = compact({
    name: body.name,
    slug: body.slug,
    site_group_id: body.groupId,
  } satisfies SitePutBody);
  const row = await authedJson<SiteRow>(scoped(`${SITES}/${enc(id)}`, opts), {
    method: "POST",
    body: JSON.stringify(patch),
  });
  return toSite(row);
}

export function deleteSite(id: string, opts?: { workspace?: string }): Promise<void> {
  // FK ON DELETE CASCADE removes the site's endpoints.
  return authedRequest(scoped(`${SITES}/${enc(id)}`, opts), { method: "DELETE" });
}

// --- endpoints --------------------------------------------------------------

export async function listEndpoints(
  siteId: string,
  opts?: { workspace?: string },
): Promise<EndpointView[]> {
  // The /v1 collection declares no `site_id` filter, so the narrowing is done here.
  const rows = await listAllV1<EndpointRow>(scoped(ENDPOINTS, opts));
  return sortByText(
    rows.map(toEndpoint).filter((e) => e.siteId === siteId),
    (e) => e.url,
  );
}

export async function createEndpoint(
  siteId: string,
  body: CreateEndpointBody,
  opts?: { workspace?: string },
): Promise<EndpointView> {
  const row = await authedJson<EndpointRow>(scoped(ENDPOINTS, opts), {
    method: "POST",
    body: JSON.stringify(
      compact({
        site_id: siteId,
        url: body.url,
        kind: body.kind,
        expected_status: body.expectedStatus,
        check_interval_seconds: body.checkIntervalSeconds,
        is_active: body.isActive,
      } satisfies EndpointCreateBody),
    ),
  });
  return toEndpoint(row);
}

export async function updateEndpoint(
  id: string,
  body: UpdateEndpointBody,
  opts?: { workspace?: string },
): Promise<EndpointView> {
  const patch = compact({
    url: body.url,
    kind: body.kind,
    expected_status: body.expectedStatus,
    check_interval_seconds: body.checkIntervalSeconds,
    is_active: body.isActive,
  } satisfies EndpointPutBody);
  const row = await authedJson<EndpointRow>(scoped(`${ENDPOINTS}/${enc(id)}`, opts), {
    method: "POST",
    body: JSON.stringify(patch),
  });
  return toEndpoint(row);
}

export function deleteEndpoint(id: string, opts?: { workspace?: string }): Promise<void> {
  return authedRequest(scoped(`${ENDPOINTS}/${enc(id)}`, opts), { method: "DELETE" });
}
