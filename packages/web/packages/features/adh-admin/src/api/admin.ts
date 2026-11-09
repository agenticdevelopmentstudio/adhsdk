"use client";

import { useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
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
import { fetchV1WindowPage, useWindowedList } from "./windowed";

// Every call here targets the `/api/v1` surface (Stripe-style: snake_case bodies,
// `{object:'list', data, has_more}` collections, `created` as unix seconds, update as
// POST on the item path). Where a pane wants the old camelCase / ISO-string shape, the
// adaptation happens here so the consuming pages stay unchanged.

// ── Users ────────────────────────────────────────────────────────────────
//
// Platform users (hub developers + staff) are customers of ecosystem zero
// (`com.agenticdeveloperhub`) after the identity collapse — the retired
// `auth.users` table is now `customer.customers`. `GET /api/v1/customers`
// is filtered to the hub ecosystem so this page keeps its old
// meaning: a developer's END-USERS are also customers (of their own ecosystem),
// and an admin caller (who bypasses tenant scoping) would otherwise see every
// ecosystem's customers mixed in. The whole list is fetched once and narrowed
// in the browser — there is no server-side page.
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

// The raw `customer.customers` row from `GET /api/v1/customers`, sourced
// from the OpenAPI spec (@adh-sdk/adh-api-types) rather than hand-written —
// so a backend schema change surfaces here as a type error, not at runtime.
type BackendUser = SuccessBody<"/v1/customers", "get">["data"][number];

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
        listAllV1<BackendUser>(`/api/v1/customers?ecosystem_id=${HUB_ECOSYSTEM_ID}`),
        authedJson<CapabilityGrant[]>("/api/v1/auth/capabilities"),
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

// Grant/revoke a capability via the admin-gated capabilities endpoints, which
// target any user (a plain create would stamp the caller).

export function useGrantRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (data: { userId: string; role?: string; capability?: string }) => {
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
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "users"] }),
  });
}

export function useRevokeRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ userId, role }: { userId: string; role: string }) => {
      const body: RequestBody<"/v1/auth/capabilities/revoke", "post"> = {
        user_id: userId,
        capability: role,
      };
      return authedJson("/api/v1/auth/capabilities/revoke", {
        method: "POST",
        body: JSON.stringify(body),
      });
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin", "users"] }),
  });
}

export function useDeleteUser() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) =>
      authedRequest(`/api/v1/customers/${encodeURIComponent(id)}`, { method: "DELETE" }),
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
