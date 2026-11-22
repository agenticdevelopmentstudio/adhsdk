"use client";

import { useMemo } from "react";
import {
  useQuery,
  useMutation,
  useQueryClient,
  type UseMutationResult,
  type UseQueryResult,
} from "@tanstack/react-query";
import type { RequestBody, SuccessBody } from "@adh-sdk/adh-api-types";
import {
  authedJson,
  authedRequest,
  listAllV1,
  listV1Page,
  unixToIso,
  withV1Query,
} from "./http";
import { fetchMemberships, type UserEcosystem } from "./memberships";
import { fetchV1WindowPage, useWindowedList, type WindowedList } from "./windowed";

// Every call here targets the `/api/v1` surface (Stripe-style: snake_case bodies,
// `{object:'list', data, has_more}` collections, `created` as unix seconds, update as
// POST on the item path). Where a pane wants the old camelCase / ISO-string shape, the
// adaptation happens here so the consuming pages stay unchanged.

// ── Users ────────────────────────────────────────────────────────────────
//
// Hub accounts (developers and staff) live on the PLATFORM side since phase 3: their rows are in
// `platform.accounts`, served at `GET /api/v1/accounts`. A developer's END-USERS are product users
// and stay on the CUSTOMER side, in `customer.customers` behind `/api/v1/customers` - the product
// panes and the transfer flow (`users/transfer.ts`) keep reading that door. `platform.accounts`
// also holds the Operators ecosystem's accounts, and an admin caller bypasses tenant scoping, so
// the list is filtered to the hub ecosystem to keep this page's meaning: the hub's own accounts.
// The whole list is fetched once and narrowed in the browser - there is no server-side page.
//
// Capabilities for the Roles column come from the admin-gated
// `GET /api/v1/auth/capabilities` (returns every {user_id, capability}); the join
// by id still holds because the collapse preserved each developer's UUID.

export interface AdminUserSummary {
  id: string;
  email: string;
  name: string;
  avatarUrl: string;
  capabilities: string[];
  createdAt: string;
  /** The customer's canonical address, or null when the registry has none for them. */
  rdid: string | null;
  /**
   * Every ecosystem this person is a customer of, hub account first.
   *
   * A SET, not a field: `customer.customers` is per-ecosystem, so the same human has one row per
   * ecosystem joined by email. Empty until the membership lookup lands — the rows themselves
   * arrive first and the column fills in.
   */
  ecosystems: UserEcosystem[];
}

// The raw `platform.accounts` row from `GET /api/v1/accounts`, sourced
// from the OpenAPI spec (@adh-sdk/adh-api-types) rather than hand-written —
// so a backend schema change surfaces here as a type error, not at runtime.
type BackendUser = SuccessBody<"/v1/accounts", "get">["data"][number];

/**
 * Every hub account, from the platform side, walking the /v1 list envelope.
 *
 * Narrowed HERE, not by a query parameter: `/v1/accounts` declares no `ecosystem_id` filter, and
 * the generic list behind it matches a query key against a column's property name
 * (`ecosystemId`), so `?ecosystem_id=` is dropped as a stray param. An admin bypasses tenant
 * scoping, so without this the Operators ecosystem's accounts would be listed as hub users.
 */
export async function fetchHubAccounts(): Promise<BackendUser[]> {
  const rows = await listAllV1<BackendUser>("/api/v1/accounts");
  return rows.filter((row) => row.ecosystem_id === HUB_ECOSYSTEM_ID);
}

/** Delete one hub account. The backend answers 409 `last_operator` rather than remove the last one. */
export function deleteHubAccount(id: string): Promise<void> {
  return authedRequest(`/api/v1/accounts/${encodeURIComponent(id)}`, { method: "DELETE" });
}

/** One `{user_id, capability}` grant from `GET /api/v1/auth/capabilities`. */
export interface CapabilityGrant {
  user_id: string;
  capability: string;
}

// Ecosystem zero — the hub's own ecosystem (`com.agenticdeveloperhub`). Its
// well-known UUID is fixed infra (backend src/lib/ecosystem.ts HUB_ECOSYSTEM_ID);
// hardcoded here because that backend constant isn't importable from the frontend.
const HUB_ECOSYSTEM_ID = "00000000-0000-4000-8000-00000000a001";

/** One row of `GET /v1/identifiers`, in the camelCase shape the pages consume. */
export interface RdidMapping {
  rdid: string;
  entityType: string;
  entityId: string;
}

interface IdentifierWire {
  rdid: string;
  entity_type: string;
  entity_id: string;
}

/** Every identifier matching `params` (`entity_type`, `entity_ids`, `q`, ...), mapped to `RdidMapping`. */
export async function listIdentifiers(
  params: Record<string, string | number | undefined>,
): Promise<RdidMapping[]> {
  const rows = await listAllV1<IdentifierWire>(withV1Query("/api/v1/identifiers", params));
  return rows.map((r) => ({ rdid: r.rdid, entityType: r.entity_type, entityId: r.entity_id }));
}

/**
 * The hub ecosystem's canonical address — the users' SOURCE for a transfer, and the exact string
 * the operator has to type to release one.
 *
 * RESOLVED, never hardcoded, and that is not caution for its own sake: this address has already
 * been renamed once (`com.agenticdeveloperhub` → `ecosystem.agenticdeveloperhub`, migration 0056),
 * and the confirmation gate compares against it CASE-SENSITIVELY. A stale constant would not fail
 * loudly — it would make the Transfer button impossible to enable, with the dialog showing the
 * operator a string that is not the one it is checking.
 *
 * `null` while it is unresolved (or if the hub somehow holds no mapping); the gate stays shut on
 * an empty source rather than treating "nothing typed" as a match.
 */
export function useHubEcosystemRdid() {
  return useQuery({
    queryKey: ["admin", "hub-ecosystem-rdid"],
    // An ecosystem's address changes about once a migration. Refetching it per mount buys nothing
    // and costs a request on every visit to the page.
    staleTime: Infinity,
    queryFn: async (): Promise<string | null> => {
      const found = await listIdentifiers({
        entity_type: "ecosystem",
        entity_ids: HUB_ECOSYSTEM_ID,
      });
      return found[0]?.rdid ?? null;
    },
  });
}

/** entityId → rdid, for joining a page of users to their addresses. */
export function rdidMapFrom(mappings: RdidMapping[]): Map<string, string> {
  return new Map(mappings.map((m) => [m.entityId, m.rdid]));
}

/**
 * The JOIN, and nothing else: one raw customer row plus its capabilities, its address and its
 * ecosystems becomes one `AdminUserSummary`.
 *
 * Searching, filtering, sorting and paging all used to live here, because the page paginated in
 * the browser and every one of them had to run BEFORE the slice or it would arrange page one
 * rather than the list. Nothing pages now — `useEditableList` narrows and orders the whole list on
 * screen — so this is back to being what its name says, and the ordering hazard is gone with the
 * slice that created it.
 */
export function toUserRows(
  rows: BackendUser[],
  caps: CapabilityGrant[],
  // OPTIONAL and last, so a call site that has only the rows still compiles. Absent, every row's
  // rdid is null and its ecosystems empty — which is what a page rendered before those two
  // lookups land should show.
  rdidByUserId?: Map<string, string>,
  ecosystemsByUserId?: Map<string, UserEcosystem[]>,
): AdminUserSummary[] {
  const capsByUser = new Map<string, string[]>();
  for (const { user_id: userId, capability } of caps) {
    const list = capsByUser.get(userId);
    if (list) list.push(capability);
    else capsByUser.set(userId, [capability]);
  }
  return rows.map((u) => ({
    id: u.id,
    email: u.email ?? "",
    name: u.display_name ?? "",
    avatarUrl: u.avatar_url ?? "",
    capabilities: capsByUser.get(u.id) ?? [],
    createdAt: unixToIso(u.created),
    rdid: rdidByUserId?.get(u.id) ?? null,
    ecosystems: ecosystemsByUserId?.get(u.id) ?? [],
  }));
}

/**
 * Every capability grant, unwrapped from the /v1 list envelope.
 *
 * `/api/v1/auth/capabilities` answers `{object:'list', data, has_more}` with 10 rows by default,
 * so it is read through `listAllV1` (100 a page). The gateway pages only by an object `id`, and a
 * grant has none, so a list longer than one page cannot be advanced: `listAllV1` then throws
 * rather than showing a Roles column silently missing grants.
 */
export function fetchCapabilityGrants(): Promise<CapabilityGrant[]> {
  return listAllV1<CapabilityGrant>("/api/v1/auth/capabilities");
}

/** Everything the users page needs from the network, before any of it is arranged. */
export interface AdminUserSource {
  rows: BackendUser[];
  caps: CapabilityGrant[];
  rdidByUserId: Map<string, string>;
  ecosystemsByUserId: Map<string, UserEcosystem[]>;
}

/**
 * The FETCH, keyed by nothing the operator can type.
 *
 * The search box, the role filter, the ecosystem filter and the sort are all applied in the
 * browser, so none of them changes what has to be downloaded — and none of them belongs in the
 * query key. It used to be keyed by page/search/pageSize, which made every keystroke in the search
 * box a fresh miss: two requests plus one per chunk of user ids, against a full list this hook had
 * already fetched and cached under a neighbouring key.
 */
export function useAdminUsersSource() {
  return useQuery({
    queryKey: ["admin", "users", "source"],
    queryFn: async (): Promise<AdminUserSource> => {
      const [rows, caps] = await Promise.all([
        fetchHubAccounts(),
        fetchCapabilityGrants(),
      ]);
      const userIds = rows.map((u) => u.id);
      // Both lookups are keyed on the SAME id list and neither feeds the other, so they run
      // together rather than in series. Both degrade internally, so `Promise.all` here cannot
      // reject and take the rows down with a column.
      const [rdidByUserId, ecosystemsByUserId] = await Promise.all([
        fetchRdids(userIds),
        fetchMemberships(userIds),
      ]);
      return { rows, caps, rdidByUserId, ecosystemsByUserId };
    },
  });
}

/**
 * ONE lookup for the whole set, not one per row. The registry's prefix search cannot answer "what
 * is THIS user's address", so the reverse shape resolves them a batch at a time; a per-row fetch
 * would be a request per visible user against a table with no RLS.
 *
 * Resolved for every user, not just the visible page, because the search matches on the rdid —
 * filtering to the page first would make an address findable only once it was already on screen.
 *
 * ⚠️ CHUNK is bounded by the URL, not by the backend's cap. The backend accepts 500 ids, but 500
 * uuids percent-encode to roughly 19.5 KB of query string and Node's default `maxHeaderSize` is
 * 16 KB — a request that never reaches a handler and fails as a socket error rather than a 431.
 * 200 keeps the line near 8 KB with room for the rest of the URL and the auth header.
 */
async function fetchRdids(userIds: string[]): Promise<Map<string, string>> {
  const CHUNK = 200;
  const mappings: RdidMapping[] = [];
  for (let i = 0; i < userIds.length; i += CHUNK) {
    const ids = userIds.slice(i, i + CHUNK).join(",");
    try {
      mappings.push(...(await listIdentifiers({ entity_type: "customer", entity_ids: ids })));
    } catch (err) {
      // DEGRADE, don't fail. An unguarded await here made the address column's lookup able to
      // take the user list down with it: one chunk erroring left the page with no users at all,
      // reported as a failed query, when the rows themselves had already arrived. A missing
      // address renders as the em dash the column already draws for a user who has none.
      console.warn("admin users: rdid lookup failed for a chunk of users", err);
    }
  }
  return rdidMapFrom(mappings);
}

/**
 * The users page's ONE list, joined — every user, in fetch order.
 *
 * Takes no arguments any more. Narrowing and ordering belong to `useEditableList` on the page,
 * which holds the search text, the role facet, the ecosystem filter and the sort; this hook's job
 * ends at "here is everybody". Recomputed only when the fetch changes, so typing in the search box
 * re-runs the filter and not the join.
 */
export function useAdminUsers() {
  const { data: source, isLoading, isError, error, refetch } = useAdminUsersSource();
  const data = useMemo(
    () =>
      source
        ? toUserRows(source.rows, source.caps, source.rdidByUserId, source.ecosystemsByUserId)
        : undefined,
    [source],
  );
  return { data, isLoading, isError, error, refetch };
}

// ── Operators ────────────────────────────────────────────────────────────
//
// `GET /api/v1/auth/capabilities/operators` (admin-gated): every live account in the Operators
// ecosystem, oldest first, and whether each holds the `admin` capability. Its /v1 row comes from
// the generated adh-api-types schema, like the customers row above, so a backend change surfaces
// as a type error; `toOperator` maps it onto the camelCase shape the pane reads.

/** One operator row as the /v1 gateway serves it (snake_case, `created` in unix seconds). */
export type OperatorWire = SuccessBody<"/v1/auth/capabilities/operators", "get">["data"][number];

/** One operator account, as the Operators pane shows it. */
export interface Operator {
  id: string;
  email: string;
  name: string;
  /** ISO timestamp the account was created. */
  createdAt: string;
  /** Whether the account holds the `admin` capability. */
  holdsAdmin: boolean;
}

function toOperator(w: OperatorWire): Operator {
  return {
    id: w.id,
    email: w.email,
    name: w.name,
    createdAt: unixToIso(w.created),
    holdsAdmin: w.holds_admin,
  };
}

const OPERATORS_KEY = ["admin", "operators"];

/** Every operator account, read whole (the list is a handful of people). */
export function listOperators(): Promise<Operator[]> {
  return listAllV1<OperatorWire>("/api/v1/auth/capabilities/operators").then((rows) =>
    rows.map(toOperator),
  );
}

export function useOperators(): UseQueryResult<Operator[]> {
  return useQuery({ queryKey: OPERATORS_KEY, queryFn: listOperators });
}

// Grant/revoke a capability via the admin-gated capabilities endpoints, which
// target any user (a plain create would stamp the caller). Both the Users and the
// Operators panes show who holds `admin`, so a change refreshes both lists.

function invalidateRoleHolders(qc: ReturnType<typeof useQueryClient>): Promise<void> {
  return Promise.all([
    qc.invalidateQueries({ queryKey: ["admin", "users"] }),
    qc.invalidateQueries({ queryKey: OPERATORS_KEY }),
  ]).then(() => undefined);
}

/** What a grant names: the user, and the capability (`role` is the older spelling of it). */
export interface GrantRoleVars {
  userId: string;
  role?: string;
  capability?: string;
}

export function useGrantRole(): UseMutationResult<unknown, Error, GrantRoleVars> {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: GrantRoleVars) => {
      const capability = data.capability ?? data.role;
      if (!capability) throw new Error("grant requires a capability or role");
      const body: RequestBody<"/v1/auth/capabilities/grant", "post"> = {
        user_id: data.userId,
        capability,
      };
      return authedJson("/api/v1/auth/capabilities/grant", {
        method: "POST",
        body: JSON.stringify(body),
      });
    },
    onSuccess: () => invalidateRoleHolders(qc),
  });
}

/** What a revoke names: the user, and the capability to take away. */
export interface RevokeRoleVars {
  userId: string;
  role: string;
}

export function useRevokeRole(): UseMutationResult<unknown, Error, RevokeRoleVars> {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, role }: RevokeRoleVars) => {
      const body: RequestBody<"/v1/auth/capabilities/revoke", "post"> = {
        user_id: userId,
        capability: role,
      };
      return authedJson("/api/v1/auth/capabilities/revoke", {
        method: "POST",
        body: JSON.stringify(body),
      });
    },
    onSuccess: () => invalidateRoleHolders(qc),
  });
}

export function useDeleteUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => deleteHubAccount(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "users"] }),
  });
}

// ── Feature Flags ────────────────────────────────────────────────────────
//
// `/api/v1/feature_flags` with no `ecosystem` param is the site-wide table
// (system.feature_flags — global, no owner scope; public GET, admin mutations), so this
// management view reads ONLY the system rows without any extra scope switch. The table is
// keyed by a serial `id`, which the row still carries (an undeclared key passes through the
// /v1 shape unchanged), and the item routes take that id in their `{key}` segment, so mutations
// address rows by id — a flag's `key` can't be the row identity because the UI edits it in place.
//
// The exported shape stays the camelCase one the panes consume; `toFlag` is the explicit mapper
// (`created`/`updated` unix seconds → ISO strings).

type FlagWire = SuccessBody<"/v1/feature_flags", "get">["data"][number] & { id: number };

/** A system.feature_flags row (id, key, description, enabled, createdAt, updatedAt). */
export interface FeatureFlag {
  id: number;
  key: string;
  description: string;
  enabled: boolean;
  createdAt: string;
  updatedAt: string;
}
/** The create body: `key` required, `description`/`enabled` optional. */
export type CreateFlagBody = RequestBody<"/v1/feature_flags", "post">;
/** The update body: every field optional (partial patch). */
export type UpdateFlagBody = {
  key?: string;
  description?: string;
  enabled?: boolean;
};

function toFlag(w: FlagWire): FeatureFlag {
  return {
    id: w.id,
    key: w.key,
    description: w.description,
    enabled: w.enabled,
    createdAt: unixToIso(w.created),
    updatedAt: unixToIso(w.updated),
  };
}

export function useAdminFlags() {
  return useQuery({
    queryKey: ["admin", "flags"],
    queryFn: async (): Promise<FeatureFlag[]> =>
      (await listAllV1<FlagWire>("/api/v1/feature_flags")).map(toFlag),
  });
}

export function useCreateFlag() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (data: CreateFlagBody): Promise<FeatureFlag> =>
      toFlag(
        await authedJson<FlagWire>("/api/v1/feature_flags", {
          method: "POST",
          body: JSON.stringify(data),
        }),
      ),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "flags"] }),
  });
}

export function useUpdateFlag() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({
      id,
      changes,
    }: {
      id: number;
      changes: UpdateFlagBody;
    }): Promise<FeatureFlag> =>
      toFlag(
        await authedJson<FlagWire>(`/api/v1/feature_flags/${id}`, {
          method: "POST",
          body: JSON.stringify(changes),
        }),
      ),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "flags"] }),
  });
}

export function useDeleteFlag() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: number) =>
      authedRequest(`/api/v1/feature_flags/${id}`, { method: "DELETE" }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "flags"] }),
  });
}

// ── Server Bag ─────────────────────────────────────────────────────────────
//
// `/api/v1/server_bag` (system.server_bag — global, no owner scope; public GET, admin
// mutations). The sibling of feature flags, but the value is arbitrary JSON instead of a boolean
// toggle. Rows are addressed by their `key` (the table's PK), which — unlike a flag's key — is
// immutable: set once at create, and the update changes only value/description. A row has no
// `id`, so a list walk pages by `key`.

type BagWire = SuccessBody<"/v1/server_bag", "get">["data"][number];

/** A system.server_bag row (key, value, description, createdAt, updatedAt). */
export interface ServerBag {
  key: string;
  value: unknown;
  description: string;
  createdAt: string;
  updatedAt: string;
}
/** The create body: `key` + `value` required, `description` optional. */
export type CreateBagBody = RequestBody<"/v1/server_bag", "post">;
/** The update body: `value`/`description`, both optional (partial patch). */
export type UpdateBagBody = { value?: unknown; description?: string };

function toBag(w: BagWire): ServerBag {
  return {
    key: w.key,
    value: w.value,
    description: w.description,
    createdAt: unixToIso(w.created),
    updatedAt: unixToIso(w.updated),
  };
}

export function useServerBags() {
  return useQuery({
    queryKey: ["admin", "server-bag"],
    queryFn: async (): Promise<ServerBag[]> =>
      (
        await listAllV1<BagWire>("/api/v1/server_bag", {}, {
          cursorOf: (row) => (row as BagWire).key,
        })
      ).map(toBag),
  });
}

export function useCreateBag() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (data: CreateBagBody): Promise<ServerBag> =>
      toBag(
        await authedJson<BagWire>("/api/v1/server_bag", {
          method: "POST",
          body: JSON.stringify(data),
        }),
      ),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "server-bag"] }),
  });
}

export function useUpdateBag() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ key, changes }: { key: string; changes: UpdateBagBody }): Promise<ServerBag> =>
      toBag(
        await authedJson<BagWire>(`/api/v1/server_bag/${encodeURIComponent(key)}`, {
          method: "POST",
          body: JSON.stringify(changes),
        }),
      ),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "server-bag"] }),
  });
}

export function useDeleteBag() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (key: string) =>
      authedRequest(`/api/v1/server_bag/${encodeURIComponent(key)}`, { method: "DELETE" }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "server-bag"] }),
  });
}

// ── Access Audit ───────────────────────────────────────────────────────────
//
// Admin-only READ of the access audit trail via `GET /api/v1/system/access_audit`
// (newest first, paged by `starting_after`). Rows are written by the `/access` mutations (workspace
// role & assignment changes); this is the cross-workspace admin view. The row shape the pane
// consumes is hand-written here and `toAuditEvent` maps the wire row onto it.

/** One `team.access_audit` row, with the acting customer's email resolved server-side. */
export interface AccessAuditEvent {
  id: string;
  ownerKind: string;
  ownerId: string;
  actorKind: string;
  actorId: string;
  /** The acting customer's email; null for a persona actor (or an unresolved id). */
  actorEmail: string | null;
  action: string;
  subjectKind: string;
  subjectId: string;
  targetFeature: string;
  targetItemId: string;
  roleId: string;
  before: string;
  after: string;
  at: string;
}

type AuditWire = SuccessBody<"/v1/system/access_audit", "get">["data"][number];

/** The audit's before/after payloads are action-shaped JSON; the pane shows them as text. */
function auditText(v: unknown): string {
  if (v === null || v === undefined) return "";
  return typeof v === "string" ? v : JSON.stringify(v);
}

function toAuditEvent(w: AuditWire): AccessAuditEvent {
  return {
    id: w.id,
    ownerKind: w.owner_kind,
    ownerId: w.owner_id,
    actorKind: w.actor_kind,
    actorId: w.actor_id,
    actorEmail: w.actor_email ?? null,
    action: w.action,
    subjectKind: w.subject_kind ?? "",
    subjectId: w.subject_id ?? "",
    targetFeature: w.target_feature ?? "",
    targetItemId: w.target_item_id ?? "",
    roleId: w.role_id ?? "",
    before: auditText(w.before),
    after: auditText(w.after),
    at: w.at,
  };
}

/**
 * The audit trail as a GROWING WINDOW rather than a page at a time.
 *
 * The trail is append-only and unbounded, so it is the one admin list that cannot be fetched
 * whole; `useWindowedList` is what lets it still be filtered and sorted like every other one. The
 * step is the widest page `/v1` serves (100).
 */
export function useAccessAudit() {
  return useWindowedList<AccessAuditEvent>({
    key: ["admin", "access-audit"],
    getRowId: (e) => e.id,
    pageSize: 100,
    fetchPage: async (after, pageSize) => {
      const page = await fetchV1WindowPage<AuditWire>("/api/v1/system/access_audit", after, pageSize);
      return { items: page.items.map(toAuditEvent), hasMore: page.hasMore };
    },
  });
}

// ── Operator Access ────────────────────────────────────────────────────────
//
// Admin-only READ of the operator log via `GET /api/v1/system/operator_access`: one row per
// operator-mode transaction (migration 0298), newest first, paged by `starting_after`. The gateway
// pages within the newest 200 rows of each filter set, so an operator after something older
// narrows by time rather than walking further. The legacy `after` cursor is never sent.

/** One `system.operator_access` row: who acted in operator mode, when, on what request. */
export interface OperatorAccessEvent {
  id: string;
  /** Postgres timestamptz text (`2026-11-21 10:00:00.123+00`), as access-audit's `at`. */
  at: string;
  operatorAccountId: string;
  tokenId: string | null;
  method: string;
  path: string;
  /** The matched route pattern, where the request matched one. */
  route: string | null;
  targetEcosystemId: string | null;
  requestId: string | null;
  ip: string | null;
  userAgent: string | null;
}

/** The server-side filters. Ids are uuids; `from` (inclusive) and `to` (exclusive) are ISO text. */
export interface OperatorAccessFilters {
  operatorAccountId?: string;
  targetEcosystemId?: string;
  from?: string;
  to?: string;
}

type OperatorAccessWire = SuccessBody<"/v1/system/operator_access", "get">["data"][number];

function toOperatorAccessEvent(w: OperatorAccessWire): OperatorAccessEvent {
  return {
    id: w.id,
    at: w.at,
    operatorAccountId: w.operator_account_id,
    tokenId: w.token_id ?? null,
    method: w.method,
    path: w.path,
    route: w.route ?? null,
    targetEcosystemId: w.target_ecosystem_id ?? null,
    requestId: w.request_id ?? null,
    ip: w.ip ?? null,
    userAgent: w.user_agent ?? null,
  };
}

/** A filter value, trimmed; blank means "no filter", so it is left off the query entirely. */
function filterValue(v: string | undefined): string | undefined {
  const t = v?.trim();
  return t ? t : undefined;
}

/** The filters with blanks dropped, in one fixed key order (the query key and the URL agree). */
export function normalizeOperatorAccessFilters(f: OperatorAccessFilters): OperatorAccessFilters {
  const out: OperatorAccessFilters = {};
  const operatorAccountId = filterValue(f.operatorAccountId);
  const targetEcosystemId = filterValue(f.targetEcosystemId);
  const from = filterValue(f.from);
  const to = filterValue(f.to);
  if (operatorAccountId) out.operatorAccountId = operatorAccountId;
  if (targetEcosystemId) out.targetEcosystemId = targetEcosystemId;
  if (from) out.from = from;
  if (to) out.to = to;
  return out;
}

/** The collection URL carrying the filters; `fetchV1WindowPage` adds `limit` and `starting_after`. */
export function operatorAccessUrl(filters: OperatorAccessFilters = {}): string {
  const f = normalizeOperatorAccessFilters(filters);
  return withV1Query("/api/v1/system/operator_access", {
    operator_account_id: f.operatorAccountId,
    target_ecosystem_id: f.targetEcosystemId,
    from: f.from,
    to: f.to,
  });
}

/**
 * The operator log as a GROWING WINDOW, one per filter set.
 *
 * The filters are part of the query key, so changing them starts a fresh window. That is why the
 * caller passes the APPLIED filters, never a field's live text: `useWindowedList`'s key must not
 * hold what the operator is still typing, or every keystroke would throw the window away.
 */
export function useOperatorAccess(
  filters: OperatorAccessFilters = {},
): WindowedList<OperatorAccessEvent> {
  const applied = normalizeOperatorAccessFilters(filters);
  return useWindowedList<OperatorAccessEvent>({
    key: ["admin", "operator-access", applied],
    getRowId: (e) => e.id,
    pageSize: 100,
    fetchPage: async (after, pageSize) => {
      const page = await fetchV1WindowPage<OperatorAccessWire>(
        operatorAccessUrl(applied),
        after,
        pageSize,
      );
      return { items: page.items.map(toOperatorAccessEvent), hasMore: page.hasMore };
    },
  });
}

// ── Messaging ────────────────────────────────────────────────────────────
//
// Admin messaging routes under `/api/v1/messaging` gated by isAdmin(): `GET /messages` (the
// log) and `POST /messages` (send), plus `status` and `templates`. The shared MessagingSurface
// still renders a page-numbered log with camelCase rows, so the hooks below adapt to that.

type MessageWire = SuccessBody<"/v1/messaging/messages", "get">["data"][number];

export interface MessageLogEntry {
  id: string;
  channel: string;
  recipient: string;
  subject: string | null;
  body: string;
  templateId: string | null;
  status: string;
  providerId: string | null;
  errorMessage: string | null;
  sentBy: string | null;
  origin: string;
  createdAt: string;
}
export interface MessageLogPage {
  items: MessageLogEntry[];
  page: number;
  pageSize: number;
  /**
   * `/v1` lists carry `has_more`, not a count, so this is the smallest figure that makes the
   * pager honest: exact once the last page is reached, one past this page while more follow.
   */
  total: number;
}
/** What the send form hands back — camelCase, mapped to the snake_case body in `useSendMessage`. */
export interface AdminSendMessageRequest {
  userId: string;
  channel: "email" | "sms";
  recipient?: string;
  subject?: string;
  body?: string;
  templateId?: string;
  templateVars?: Record<string, string>;
}

function toMessage(w: MessageWire): MessageLogEntry {
  return {
    id: w.id,
    channel: w.channel,
    recipient: w.recipient,
    subject: w.subject ?? null,
    body: w.body,
    templateId: w.template_id ?? null,
    status: w.status,
    providerId: w.provider_id ?? null,
    errorMessage: w.error_message ?? null,
    sentBy: w.sent_by ?? null,
    origin: w.origin,
    createdAt: unixToIso(w.created),
  };
}

export function useMessageLog(page = 1, pageSize = 20) {
  return useQuery({
    queryKey: ["admin", "messaging", "log", page, pageSize],
    queryFn: async (): Promise<MessageLogPage> => {
      // Cursor paging has no "page N": walk to it, one request per page.
      let after: string | undefined;
      let current = await listV1Page<MessageWire>(
        withV1Query("/api/v1/messaging/messages", { limit: pageSize }),
      );
      for (let n = 1; n < page && current.hasMore && current.data.length > 0; n++) {
        after = current.data[current.data.length - 1]?.id;
        current = await listV1Page<MessageWire>(
          withV1Query("/api/v1/messaging/messages", { limit: pageSize, starting_after: after }),
        );
      }
      const items = current.data.map(toMessage);
      return {
        items,
        page,
        pageSize,
        total: current.hasMore ? page * pageSize + 1 : (page - 1) * pageSize + items.length,
      };
    },
  });
}

export function useSendMessage() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: AdminSendMessageRequest) => {
      const body: Record<string, unknown> = {
        user_id: data.userId,
        channel: data.channel,
        ...(data.recipient !== undefined ? { recipient: data.recipient } : {}),
        ...(data.subject !== undefined ? { subject: data.subject } : {}),
        ...(data.body !== undefined ? { body: data.body } : {}),
        ...(data.templateId !== undefined ? { template_id: data.templateId } : {}),
        ...(data.templateVars !== undefined ? { template_vars: data.templateVars } : {}),
      };
      return authedJson<SuccessBody<"/v1/messaging/messages", "post", 201>>(
        "/api/v1/messaging/messages",
        { method: "POST", body: JSON.stringify(body) },
      );
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "messaging"] }),
  });
}

// ── Feedback ─────────────────────────────────────────────────────────────
//
// `/api/v1/content/feedback`, fetched whole. The page and status arguments the old hook took
// were applied to an already-complete array, which is a pager that hid rows the caller had
// already paid for. The list filters and sorts client-side.
//
// LIMITATION: content.feedback carries an owner, so the list is owner-scoped to the caller — an
// admin currently sees only their OWN feedback, not every user's. A tenant-wide admin feedback
// panel needs an admin-gated backend endpoint; swap the URL here once it exists.

type FeedbackWire = SuccessBody<"/v1/content/feedback", "get">["data"][number];

/** A `content.feedback` row in the camelCase shape the pane consumes. */
export interface FeedbackSubmission {
  id: string;
  ecosystemId: string;
  userEmail: string;
  category: string;
  subject: string;
  body: string;
  platform: string;
  appVersion: string;
  osVersion: string;
  deviceInfo: string;
  status: string;
  adminNotes: string;
  createdAt: string;
  updatedAt: string;
}

function toFeedback(w: FeedbackWire): FeedbackSubmission {
  return {
    id: w.id,
    ecosystemId: w.ecosystem_id,
    userEmail: w.user_email,
    category: w.category,
    subject: w.subject,
    body: w.body,
    platform: w.platform,
    appVersion: w.app_version,
    osVersion: w.os_version,
    deviceInfo: w.device_info,
    status: w.status,
    adminNotes: w.admin_notes,
    createdAt: unixToIso(w.created),
    updatedAt: unixToIso(w.updated),
  };
}

/** Every submission, newest first. */
export function useFeedback() {
  return useQuery({
    queryKey: ["admin", "feedback"],
    queryFn: async (): Promise<FeedbackSubmission[]> => {
      const rows = (await listAllV1<FeedbackWire>("/api/v1/content/feedback")).map(toFeedback);
      // The mapped array becomes the query cache's own value; it is a fresh array, so sorting
      // in place does not touch anything the fetch handed back.
      return rows.sort((a, b) =>
        a.createdAt < b.createdAt ? 1 : a.createdAt > b.createdAt ? -1 : 0,
      );
    },
  });
}

export function useUpdateFeedback() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      status,
      adminNotes,
    }: {
      id: string;
      status?: string;
      adminNotes?: string;
    }) => {
      // Only send fields the caller explicitly set, so an absent field is never
      // coerced to null by the partial update. Typed against the spec's update body.
      const body: Partial<RequestBody<"/v1/content/feedback/{id}", "post">> = {};
      if (status !== undefined) body.status = status;
      if (adminNotes !== undefined) body.admin_notes = adminNotes;
      return authedJson(
        `/api/v1/content/feedback/${encodeURIComponent(id)}`,
        {
          method: "POST",
          body: JSON.stringify(body),
        },
      );
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "feedback"] }),
  });
}

// ── Messaging status + templates ─────────────────────────────────────────
export type MessagingStatus = SuccessBody<"/v1/messaging/status", "get">;

/** A messaging template in the shape the shared MessagingSurface reads. */
export interface MessagingTemplate {
  id: string;
  name: string;
  subject: string;
  htmlBody: string;
  textBody: string;
  smsBody?: string;
  category: string;
}
export type MessagingTemplateList = MessagingTemplate[];

type TemplateWire = SuccessBody<"/v1/messaging/templates", "get">["data"][number];

export function useMessagingStatus() {
  return useQuery({
    queryKey: ["admin", "messaging", "status"],
    queryFn: () => authedJson<MessagingStatus>("/api/v1/messaging/status"),
  });
}

export function useMessagingTemplates() {
  return useQuery({
    queryKey: ["admin", "messaging", "templates"],
    queryFn: async (): Promise<MessagingTemplateList> =>
      (await listAllV1<TemplateWire>("/api/v1/messaging/templates")).map((t) => ({
        id: t.id,
        name: t.name,
        subject: t.subject,
        htmlBody: t.html_body,
        textBody: t.text_body,
        ...(t.sms_body !== undefined ? { smsBody: t.sms_body } : {}),
        category: t.category,
      })),
  });
}

// ── Messaging providers ──────────────────────────────────────────────────
//
// The platform's own Postmark and Twilio, behind the admin-only `/api/v1/messaging/providers`.
// They are stored under the hub's key, but they are the platform's, not a product's: the hub's
// Settings → Integrations refuses them since phase 3, and this is their one door. Every write
// refreshes the list and the status, because the status is what says whether a channel can send.

/** The two providers the platform sends with, in the order the pane shows them. */
export const MESSAGING_PROVIDER_IDS = ["postmark", "twilio"] as const;
export type MessagingProviderId = (typeof MESSAGING_PROVIDER_IDS)[number];

/** One provider config row as the list serves it (masked: a secret is only `has_secret`). */
export type MessagingProviderWire = SuccessBody<"/v1/messaging/providers", "get">["data"][number];
/** What a test send answers: `sent`, or `failed` with the provider's reason. */
export type MessagingProviderTestResult = SuccessBody<"/v1/messaging/providers/{id}/test", "post">;

/** One config field the pane asks for, mirroring the backend's provider catalog. */
export interface MessagingProviderField {
  key: string;
  label: string;
  secret: boolean;
  required: boolean;
  placeholder?: string;
}

/**
 * The fields each provider takes. A copy of the backend's provider catalog
 * (`src/integration/providers/catalog.ts`), because the catalog is not on the wire for these two;
 * the backend still checks the merged config, so a drifted copy fails loudly on save.
 */
export const MESSAGING_PROVIDER_FIELDS: Record<MessagingProviderId, MessagingProviderField[]> = {
  postmark: [
    { key: "serverToken", label: "Server Token", secret: true, required: true },
    { key: "fromEmail", label: "From Email", secret: false, required: true, placeholder: "noreply@example.com" },
    { key: "broadcastStream", label: "Broadcast message stream", secret: false, required: false, placeholder: "broadcast" },
  ],
  twilio: [
    { key: "accountSid", label: "Account SID", secret: false, required: true },
    { key: "authToken", label: "Auth Token", secret: true, required: true },
    { key: "fromNumber", label: "From Number", secret: false, required: true, placeholder: "+15551234567" },
  ],
};

/** One row of the pane's Providers section: a provider, set or not, and what it can do. */
export interface MessagingProviderRow {
  providerId: MessagingProviderId;
  label: string;
  channel: "email" | "sms";
  /** The active config, or null when the provider is not set. */
  config: MessagingProviderWire | null;
  fields: MessagingProviderField[];
  /** Only Postmark owns an inbound webhook, so only Postmark offers a rotate. */
  canRotateWebhookSecret: boolean;
  /** A Twilio test has no default recipient; Postmark falls back to the caller's own email. */
  testNeedsRecipient: boolean;
}

/**
 * The pane's row model: one row per provider, set or not, built from the list. A provider may
 * have more than one stored row; the write routes act on the active one, so that is the one shown.
 */
export function messagingProviderRows(configs: MessagingProviderWire[]): MessagingProviderRow[] {
  return MESSAGING_PROVIDER_IDS.map((providerId) => {
    const mine = configs.filter((c) => c.provider_id === providerId);
    return {
      providerId,
      label: providerId === "postmark" ? "Postmark" : "Twilio",
      channel: providerId === "postmark" ? "email" : "sms",
      config: mine.find((c) => c.active) ?? null,
      fields: MESSAGING_PROVIDER_FIELDS[providerId],
      canRotateWebhookSecret: providerId === "postmark",
      testNeedsRecipient: providerId === "twilio",
    };
  });
}

export const MESSAGING_PROVIDERS_KEY = ["admin", "messaging", "providers"];
const MESSAGING_PROVIDERS_PATH = "/api/v1/messaging/providers";
const providerPath = (providerId: string) =>
  `${MESSAGING_PROVIDERS_PATH}/${encodeURIComponent(providerId)}`;

function invalidateMessagingProviders(qc: ReturnType<typeof useQueryClient>): Promise<void> {
  return Promise.all([
    qc.invalidateQueries({ queryKey: MESSAGING_PROVIDERS_KEY }),
    qc.invalidateQueries({ queryKey: ["admin", "messaging", "status"] }),
  ]).then(() => undefined);
}

export function useMessagingProviders(): UseQueryResult<MessagingProviderWire[]> {
  return useQuery({
    queryKey: MESSAGING_PROVIDERS_KEY,
    queryFn: () => listAllV1<MessagingProviderWire>(MESSAGING_PROVIDERS_PATH),
  });
}

/** Set or replace a provider. A blank secret keeps the stored one. */
export interface SetMessagingProviderVars {
  providerId: MessagingProviderId;
  fields: Record<string, string>;
  enabled?: boolean;
}

export function useSetMessagingProvider(): UseMutationResult<
  SuccessBody<"/v1/messaging/providers/{id}", "post">,
  Error,
  SetMessagingProviderVars
> {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ providerId, fields, enabled }: SetMessagingProviderVars) => {
      const body: RequestBody<"/v1/messaging/providers/{id}", "post"> = {
        fields,
        ...(enabled !== undefined ? { enabled } : {}),
      };
      // The /v1 surface updates with a POST on the item path; the legacy route is a PUT.
      return authedJson<SuccessBody<"/v1/messaging/providers/{id}", "post">>(providerPath(providerId), {
        method: "POST",
        body: JSON.stringify(body),
      });
    },
    onSuccess: () => invalidateMessagingProviders(qc),
  });
}

export function useRemoveMessagingProvider(): UseMutationResult<void, Error, MessagingProviderId> {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (providerId: MessagingProviderId) =>
      authedRequest(providerPath(providerId), { method: "DELETE" }),
    onSuccess: () => invalidateMessagingProviders(qc),
  });
}

/** Send one fixed test message. `to` is optional for Postmark and required for Twilio. */
export interface TestMessagingProviderVars {
  providerId: MessagingProviderId;
  to?: string;
}

export function useTestMessagingProvider(): UseMutationResult<
  MessagingProviderTestResult,
  Error,
  TestMessagingProviderVars
> {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ providerId, to }: TestMessagingProviderVars) => {
      const body: RequestBody<"/v1/messaging/providers/{id}/test", "post"> = to ? { to } : {};
      return authedJson<MessagingProviderTestResult>(`${providerPath(providerId)}/test`, {
        method: "POST",
        body: JSON.stringify(body),
      });
    },
    // A test send is logged, so the message log refreshes along with the providers.
    onSuccess: () =>
      Promise.all([
        invalidateMessagingProviders(qc),
        qc.invalidateQueries({ queryKey: ["admin", "messaging", "log"] }),
      ]).then(() => undefined),
  });
}

export function useRotateMessagingWebhookSecret(): UseMutationResult<
  SuccessBody<"/v1/messaging/providers/{id}/rotate_webhook_secret", "post">,
  Error,
  MessagingProviderId
> {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (providerId: MessagingProviderId) =>
      authedJson<SuccessBody<"/v1/messaging/providers/{id}/rotate_webhook_secret", "post">>(
        `${providerPath(providerId)}/rotate_webhook_secret`,
        { method: "POST" },
      ),
    onSuccess: () => invalidateMessagingProviders(qc),
  });
}
