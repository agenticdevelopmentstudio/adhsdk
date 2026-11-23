"use client";

// Consented support access (phase 7): the four clients and their hooks. The backend owns every
// rule (who may ask, how long a grant runs, what the viewer reads, what the log records); this
// file builds requests, maps rows and wraps each call in a React Query hook.
//
// Routes (every one a /v1 path, all 404 while the backend's `consented_access` switch is off):
//   the person      /api/v1/{customer|account}/support/grants                    list
//                   /api/v1/{customer|account}/support/grants/{id}/approve|deny|revoke   POST
//                   /api/v1/{customer|account}/support/access?grant_id=&cursor=  the read log
//   product admin   /api/v1/support/grants?ecosystem=                            list, request (POST)
//                   /api/v1/support/grants/{id}/revoke?ecosystem=                POST
//                   /api/v1/support/grants/{id}/data/{schema}/{table}[/{row_id}] the viewer (GET only)
//   operator        /api/v1/system/support_grants?status=&consent=&cursor=       list, request (POST)
//                   /api/v1/system/support_grants/break_glass                    POST
//                   /api/v1/system/support_grants/{id}/revoke                    POST
//                   /api/v1/system/support_access?grant_id=&cursor=              the read log
//   emailed link    /api/v1/public/support/grants/{id}?token=                    no session
//                   /api/v1/public/support/grants/{id}/deny|revoke|approve/code|approve   POST
//
// The log pages by the legacy `cursor` (the last read's id), which the gateway passes through;
// the viewer's table pages by `starting_after`. Neither client pages by itself.
//
// Not the operator-access log in @adh-sdk/adh-admin (`/v1/system/operator_access`): that one
// records an operator's own actions across ecosystems; this one records reads under a grant.

import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { responseError } from "@adh-sdk/auth/client";
import { authedJson, authedRequest, httpStatus, listV1Page, withV1Query, type V1List } from "../http";
import { enc } from "../client-helpers";
import {
  toSupportAccessRow,
  toSupportAdminGrant,
  toSupportGrant,
  toSupportRead,
  type SupportAccess,
  type SupportAccessPage,
  type SupportAccessRowWire,
  type SupportAdminGrant,
  type SupportGrant,
  type SupportGrantStatus,
  type SupportGrantWire,
  type SupportLinkGrantWire,
  type SupportReadWire,
  type SupportSide,
} from "./wire";

/** A request undecided this long has lapsed (the backend's `support:lapsed`). */
export const SUPPORT_LAPSE_DAYS = 7;

/** How many log rows, or viewer rows, one page asks for. */
export const SUPPORT_PAGE_SIZE = 50;

/**
 * The limits 0309's definer functions enforce (answered 422), so a form can say so before it
 * sends: a reason of 10 to 500 characters; a consented grant of 1 hour to 7 days; a break-glass
 * grant of 1 to 4 hours with an attestation of at least 40 characters and a reference.
 */
export const SUPPORT_REASON_MIN = 10;
export const SUPPORT_REASON_MAX = 500;
export const SUPPORT_HOURS_MAX = 168;
export const SUPPORT_BREAK_GLASS_HOURS_MAX = 4;
export const SUPPORT_ATTESTATION_MIN = 40;
/** The length a request form starts at. */
export const SUPPORT_HOURS_DEFAULT = 24;

/**
 * What is wrong with a request's reason and length, as one sentence for the form; null when it
 * would pass. `maxHours` is {@link SUPPORT_HOURS_MAX}, or {@link SUPPORT_BREAK_GLASS_HOURS_MAX}
 * for break-glass.
 */
export function supportRequestProblem(
  req: { reason: string; hours: number },
  maxHours: number = SUPPORT_HOURS_MAX,
): string | null {
  const n = req.reason.trim().length;
  if (n < SUPPORT_REASON_MIN) return `Give a reason of at least ${SUPPORT_REASON_MIN} characters.`;
  if (n > SUPPORT_REASON_MAX) return `Keep the reason to ${SUPPORT_REASON_MAX} characters or fewer.`;
  if (!Number.isInteger(req.hours) || req.hours < 1 || req.hours > maxHours) {
    return `Ask for a whole number of hours from 1 to ${maxHours}.`;
  }
  return null;
}

/**
 * The tables the read-only viewer offers, as `schema.table`. A copy of the `content` list in
 * adhbackend's `src/db/rls-forms.json` (read there by `db/content-tables.ts`), which is the
 * authority: a table the backend refuses answers 404 and the viewer shows it as unavailable.
 */
export const SUPPORT_CONTENT_TABLES: readonly string[] = [
  "chat.chat_mentions",
  "chat.chat_messages",
  "chat.chat_participants",
  "chat.chat_rich_content",
  "chat.chats",
  "content.addresses",
  "content.attachments",
  "content.bookmarks",
  "content.categories",
  "content.category_edges",
  "content.category_items",
  "content.contacts",
  "content.counters",
  "content.dates",
  "content.docs",
  "content.events",
  "content.feed",
  "content.feedback",
  "content.key_value_pairs",
  "content.keyword_items",
  "content.keywords",
  "content.list_items",
  "content.lists",
  "content.locations",
  "content.markdown",
  "content.markdown_chunks",
  "content.markdown_versions",
  "content.notes",
  "content.papers",
  "content.poll_options",
  "content.poll_votes",
  "content.polls",
  "content.queue_items",
  "content.queues",
  "content.reactions",
  "content.relationships",
  "content.social_links",
  "content.tags",
  "content.urls",
  "discussion.posts",
  "discussion.topics",
  "document.blocks",
  "document.documents",
  "document.marks",
  "document.operations",
  "document.versions",
  "integration.integration_action_logs",
  "integration.integration_audience_contacts",
  "integration.integration_audiences",
  "integration.integration_bookmarks",
  "integration.integration_calendar_events",
  "integration.integration_campaign_stats",
  "integration.integration_email_labels",
  "integration.integration_email_messages",
  "integration.integration_financial_transactions",
  "integration.integration_items",
  "integration.integration_media_albums",
  "integration.integration_media_items",
  "integration.integration_pages",
  "integration.integration_social_notifications",
  "integration.integration_social_posts",
  "notification.notifications",
  "persona_memory.blocks",
  "persona_memory.facts",
  "persona_memory.links",
  "persona_memory.memories",
  "personal.education",
  "personal.jobs",
  "processing.change_events",
  "processing.jobs",
  "project.activity",
  "project.artifacts",
  "project.comments",
  "project.fields",
  "project.iterations",
  "project.milestones",
  "project.participants",
  "project.programs",
  "project.projects",
  "project.research_projects",
  "project.saved_views",
  "project.status_updates",
  "project.statuses",
  "project.tasks",
  "project.templates",
  "project.work_item_dependencies",
  "project.work_item_field_values",
  "project.work_items",
  "sync.push_ops",
];

// ── Rules the panes read ──────────────────────────────────────────────────────

export type SupportGrantState = "pending" | "live" | "ended";

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Where a grant stands at `now`: `pending` while undecided and not yet lapsed, `live` while
 * approved, unrevoked and before `expiresAt`, `ended` for everything else (denied, revoked,
 * expired, or lapsed after `SUPPORT_LAPSE_DAYS` undecided).
 */
export function grantState(grant: SupportGrant, now: Date = new Date()): SupportGrantState {
  const t = now.getTime();
  if (grant.revokedAt) return "ended";
  if (grant.decision === null) {
    const asked = Date.parse(grant.requestedAt);
    return Number.isFinite(asked) && t - asked >= SUPPORT_LAPSE_DAYS * DAY_MS ? "ended" : "pending";
  }
  if (grant.decision === "approved" && grant.expiresAt && Date.parse(grant.expiresAt) > t) return "live";
  return "ended";
}

/** A path segment decoded, or as logged when its escapes are malformed: one odd log row must
 *  never take the whole log down with a URIError. */
const decodeSegment = (s: string): string => {
  try {
    return decodeURIComponent(s);
  } catch {
    return s;
  }
};

/** The `schema.table` a logged read's path names, from its `/data/{schema}/{table}` segments. */
export function accessTable(row: Pick<SupportAccess, "path">): { schema: string; table: string } | null {
  const m = /\/data\/([^/?#]+)\/([^/?#]+)/.exec(row.path);
  if (!m) return null;
  return { schema: decodeSegment(m[1]!), table: decodeSegment(m[2]!) };
}

/** The reads of one grant on one table on one local calendar day. */
export interface SupportAccessGroup {
  grantId: string;
  granteeName: string | null;
  /** The table name (no schema), or null when the path names none. */
  table: string | null;
  schema: string | null;
  /** The local calendar day, `YYYY-MM-DD`. */
  day: string;
  count: number;
  /** The latest read in the group, ISO. */
  latestAt: string;
}

const localDay = (iso: string): string => {
  const d = new Date(iso);
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${d.getFullYear()}-${mm}-${dd}`;
};

/**
 * Group reads by grant, table and the viewer's local calendar day, with each group's count and
 * latest time, newest group first. The log is shown this way, never one line a read.
 */
export function groupAccess(rows: readonly SupportAccess[]): SupportAccessGroup[] {
  const groups = new Map<string, SupportAccessGroup>();
  for (const row of rows) {
    const where = accessTable(row);
    const day = localDay(row.at);
    const key = `${row.grantId}\u0000${where?.schema ?? ""}.${where?.table ?? ""}\u0000${day}`;
    const g = groups.get(key);
    if (!g) {
      groups.set(key, {
        grantId: row.grantId,
        granteeName: row.granteeName,
        table: where?.table ?? null,
        schema: where?.schema ?? null,
        day,
        count: 1,
        latestAt: row.at,
      });
      continue;
    }
    g.count += 1;
    if (Date.parse(row.at) > Date.parse(g.latestAt)) g.latestAt = row.at;
    if (!g.granteeName) g.granteeName = row.granteeName;
  }
  return [...groups.values()].sort((a, b) => Date.parse(b.latestAt) - Date.parse(a.latestAt));
}

/** True when the support routes answered 404: the `consented_access` switch is off. Apply it to
 *  the grants read alone; on the viewer's paths a 404 means a refused table. */
export function isSupportOff(err: unknown): boolean {
  return httpStatus(err) === 404;
}

/** True for the backend's 403 `step_up_required`: a product admin must sign in again with a
 *  second factor. The client never redirects; the pane does. */
export function isStepUpRequired(err: unknown): boolean {
  if (httpStatus(err) !== 403) return false;
  if ((err as { code?: unknown }).code === "step_up_required") return true;
  const body = (err as { body?: unknown }).body as { error?: { code?: unknown } } | null | undefined;
  return body?.error?.code === "step_up_required";
}

// ── The person: a customer or a hub user ──────────────────────────────────────

const sidePath = (side: SupportSide) => `/api/v1/${side}/support`;

const accessPage = (rows: SupportAccess[], hasMore: boolean): SupportAccessPage => ({
  items: rows,
  nextCursor: hasMore && rows.length > 0 ? rows[rows.length - 1]!.id : null,
});

/** The calls of the person a grant is over. `side` picks the routes and changes nothing else. */
export function supportApi(side: SupportSide) {
  const base = sidePath(side);
  const decide = (verb: "approve" | "deny" | "revoke") => async (id: string): Promise<void> => {
    await authedRequest(`${base}/grants/${enc(id)}/${verb}`, { method: "POST" });
  };
  return {
    /** Every grant over the caller. A 404 is rethrown unchanged (`isSupportOff`). */
    async grants(): Promise<SupportGrant[]> {
      const page = await authedJson<V1List<SupportGrantWire>>(withV1Query(`${base}/grants`, { limit: 100 }));
      return (page?.data ?? []).map(toSupportGrant);
    },
    approve: decide("approve"),
    deny: decide("deny"),
    revoke: decide("revoke"),
    /** One page of the read log, newest first; `grantId` narrows it to one grant. */
    async access(opts: { grantId?: string; cursor?: string } = {}): Promise<SupportAccessPage> {
      const { data, hasMore } = await listV1Page<SupportReadWire>(
        withV1Query(`${base}/access`, {
          grant_id: opts.grantId || undefined,
          cursor: opts.cursor || undefined,
          limit: SUPPORT_PAGE_SIZE,
        }),
      );
      return accessPage(data.map(toSupportRead), hasMore);
    },
  };
}

// ── A product admin ───────────────────────────────────────────────────────────

const ADMIN_GRANTS_PATH = "/api/v1/support/grants";

export interface SupportGrantRequest {
  targetId: string;
  reason: string;
  hours?: number;
}

/** One page of a content table, as the viewer reads it. */
export interface SupportDataPage {
  rows: Record<string, unknown>[];
  nextCursor: string | null;
}

const rowCursor = (rows: Record<string, unknown>[], hasMore: boolean): string | null => {
  if (!hasMore || rows.length === 0) return null;
  const id = rows[rows.length - 1]!.id;
  return typeof id === "string" || typeof id === "number" ? String(id) : null;
};

/** A product admin's calls, always naming the product by its ecosystem uuid. The viewer's two
 *  reads are GETs; there is no function that writes to the viewer's paths. */
export const supportAdminApi = {
  async list(ecosystemId: string): Promise<SupportAdminGrant[]> {
    const page = await authedJson<V1List<SupportGrantWire>>(
      withV1Query(ADMIN_GRANTS_PATH, { ecosystem: ecosystemId, limit: 100 }),
    );
    return (page?.data ?? []).map(toSupportAdminGrant);
  },

  /** Ask for a grant. The reason and length are checked by the pane and the backend (422). */
  async request(ecosystemId: string, req: SupportGrantRequest): Promise<SupportAdminGrant> {
    const w = await authedJson<SupportGrantWire>(withV1Query(ADMIN_GRANTS_PATH, { ecosystem: ecosystemId }), {
      method: "POST",
      body: JSON.stringify({ target_id: req.targetId, reason: req.reason, hours: req.hours }),
    });
    return toSupportAdminGrant(w);
  },

  async revoke(ecosystemId: string, id: string): Promise<void> {
    await authedRequest(withV1Query(`${ADMIN_GRANTS_PATH}/${enc(id)}/revoke`, { ecosystem: ecosystemId }), {
      method: "POST",
    });
  },

  /** One page of a content table under a live grant, newest first. */
  async data(id: string, schema: string, table: string, opts: { cursor?: string } = {}): Promise<SupportDataPage> {
    const { data, hasMore } = await listV1Page<Record<string, unknown>>(
      withV1Query(`${ADMIN_GRANTS_PATH}/${enc(id)}/data/${enc(schema)}/${enc(table)}`, {
        starting_after: opts.cursor || undefined,
        limit: SUPPORT_PAGE_SIZE,
      }),
    );
    return { rows: data, nextCursor: rowCursor(data, hasMore) };
  },

  /** One row of a content table under a live grant. */
  async row(id: string, schema: string, table: string, rowId: string): Promise<Record<string, unknown>> {
    return authedJson<Record<string, unknown>>(
      `${ADMIN_GRANTS_PATH}/${enc(id)}/data/${enc(schema)}/${enc(table)}/${enc(rowId)}`,
    );
  },
};

// ── An operator ───────────────────────────────────────────────────────────────

const SYSTEM_GRANTS_PATH = "/api/v1/system/support_grants";
const SYSTEM_ACCESS_PATH = "/api/v1/system/support_access";

export interface OperatorGrantFilters {
  status?: SupportGrantStatus;
  consent?: "customer" | "break_glass";
  cursor?: string;
}

export interface OperatorGrantPage {
  items: SupportAdminGrant[];
  nextCursor: string | null;
}

export interface OperatorGrantRequest {
  targetKind: "customer" | "account";
  targetId: string;
  /** Required for a customer; a hub user's grant names no product. */
  ecosystemId?: string;
  reason: string;
  hours?: number;
}

export interface BreakGlassRequest extends OperatorGrantRequest {
  /** At least 40 characters; the pane checks, the backend refuses a shorter one. */
  attestation: string;
  /** The case or ticket reference. */
  attestationRef: string;
}

export interface OperatorSupportAccessFilters {
  grantId: string;
  cursor?: string;
}

const operatorBody = (b: OperatorGrantRequest) => ({
  target_kind: b.targetKind,
  target_id: b.targetId,
  ecosystem_id: b.ecosystemId,
  reason: b.reason,
  hours: b.hours,
});

export const operatorSupportApi = {
  async list(filters: OperatorGrantFilters = {}): Promise<OperatorGrantPage> {
    const { data, hasMore } = await listV1Page<SupportGrantWire>(
      withV1Query(SYSTEM_GRANTS_PATH, {
        status: filters.status || undefined,
        consent: filters.consent || undefined,
        cursor: filters.cursor || undefined,
        limit: SUPPORT_PAGE_SIZE,
      }),
    );
    const items = data.map(toSupportAdminGrant);
    return { items, nextCursor: hasMore && items.length > 0 ? items[items.length - 1]!.id : null };
  },

  async request(body: OperatorGrantRequest): Promise<SupportAdminGrant> {
    const w = await authedJson<SupportGrantWire>(SYSTEM_GRANTS_PATH, {
      method: "POST",
      body: JSON.stringify(operatorBody(body)),
    });
    return toSupportAdminGrant(w);
  },

  /** A grant with no consent, for an emergency: 1 to 4 hours, an attestation and a reference. */
  async breakGlass(body: BreakGlassRequest): Promise<SupportAdminGrant> {
    const w = await authedJson<SupportGrantWire>(`${SYSTEM_GRANTS_PATH}/break_glass`, {
      method: "POST",
      body: JSON.stringify({
        ...operatorBody(body),
        attestation: body.attestation,
        attestation_ref: body.attestationRef,
      }),
    });
    return toSupportAdminGrant(w);
  },

  async revoke(id: string): Promise<void> {
    await authedRequest(`${SYSTEM_GRANTS_PATH}/${enc(id)}/revoke`, { method: "POST" });
  },

  /** One page of one grant's read log, newest first. */
  async access(filters: OperatorSupportAccessFilters): Promise<SupportAccessPage> {
    const { data, hasMore } = await listV1Page<SupportAccessRowWire>(
      withV1Query(SYSTEM_ACCESS_PATH, {
        grant_id: filters.grantId,
        cursor: filters.cursor || undefined,
        limit: SUPPORT_PAGE_SIZE,
      }),
    );
    return accessPage(data.map(toSupportAccessRow), hasMore);
  },
};

// ── The emailed link: no session, the token alone ────────────────────────────

const PUBLIC_PATH = "/api/v1/public/support/grants";

/** What the emailed link shows: the grant and its latest reads, newest first. */
export interface SupportLinkGrant {
  grant: SupportAdminGrant;
  reads: SupportAccess[];
}

async function publicJson<T>(url: string, init: RequestInit = {}): Promise<T> {
  const res = await fetch(url, {
    ...init,
    cache: "no-store",
    headers: init.body != null ? { "content-type": "application/json" } : undefined,
  });
  if (!res.ok) throw await responseError(res, `HTTP ${res.status}`);
  return (await res.json()) as T;
}

const publicPost = <T>(id: string, tail: string, body: Record<string, string>) =>
  publicJson<T>(`${PUBLIC_PATH}/${enc(id)}${tail}`, { method: "POST", body: JSON.stringify(body) });

/** The emailed link's calls. They send no authorization; the token is the credential, and the
 *  client never stores it. */
export const publicSupportApi = {
  async get(id: string, token: string): Promise<SupportLinkGrant> {
    const w = await publicJson<SupportLinkGrantWire>(withV1Query(`${PUBLIC_PATH}/${enc(id)}`, { token }));
    return { grant: toSupportAdminGrant(w.grant), reads: (w.reads ?? []).map(toSupportRead) };
  },

  async deny(id: string, token: string): Promise<SupportAdminGrant> {
    return toSupportAdminGrant(await publicPost<SupportGrantWire>(id, "/deny", { token }));
  },

  async revoke(id: string, token: string): Promise<SupportAdminGrant> {
    return toSupportAdminGrant(await publicPost<SupportGrantWire>(id, "/revoke", { token }));
  },

  /** Email the person a code to confirm the approval with. */
  async sendCode(id: string, token: string): Promise<{ ok: boolean }> {
    const r = await publicPost<{ ok: boolean }>(id, "/approve/code", { token });
    return { ok: r.ok === true };
  },

  async approve(id: string, token: string, code: string): Promise<SupportAdminGrant> {
    return toSupportAdminGrant(await publicPost<SupportGrantWire>(id, "/approve", { token, code }));
  },
};

// ── Hooks ─────────────────────────────────────────────────────────────────────

export const SUPPORT_GRANTS_KEY = (side: SupportSide) => ["support", side, "grants"] as const;
export const SUPPORT_ACCESS_KEY = (side: SupportSide, grantId?: string | null) =>
  ["support", side, "access", grantId ?? ""] as const;
export const SUPPORT_ADMIN_KEY = (ecosystemId: string) => ["support", "admin", ecosystemId] as const;
export const SUPPORT_OPERATOR_KEY = ["support", "operator"] as const;

/** The caller's grants. `retry` stops at a 404: the switch is off, and asking again won't help. */
export function useSupportGrants(side: SupportSide | null | undefined) {
  return useQuery({
    queryKey: SUPPORT_GRANTS_KEY(side ?? "customer"),
    queryFn: () => supportApi(side as SupportSide).grants(),
    enabled: Boolean(side),
    retry: (count, err) => !isSupportOff(err) && count < 2,
  });
}

/** The read log, a page at a time (`fetchNextPage` follows `nextCursor`). */
export function useSupportAccess(side: SupportSide | null | undefined, grantId?: string | null) {
  return useInfiniteQuery({
    queryKey: SUPPORT_ACCESS_KEY(side ?? "customer", grantId),
    queryFn: ({ pageParam }) =>
      supportApi(side as SupportSide).access({ grantId: grantId || undefined, cursor: pageParam || undefined }),
    initialPageParam: "",
    getNextPageParam: (last: SupportAccessPage) => last.nextCursor ?? undefined,
    enabled: Boolean(side),
  });
}

/** Approve, deny or revoke; refreshes the side's grants and its log. */
export function useDecideSupportGrant(side: SupportSide) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, action }: { id: string; action: "approve" | "deny" | "revoke" }) =>
      supportApi(side)[action](id),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: SUPPORT_GRANTS_KEY(side) });
      void qc.invalidateQueries({ queryKey: ["support", side, "access"] });
    },
  });
}

export function useAdminSupportGrants(ecosystemId: string | null | undefined) {
  return useQuery({
    queryKey: [...SUPPORT_ADMIN_KEY(ecosystemId ?? ""), "grants"],
    queryFn: () => supportAdminApi.list(ecosystemId as string),
    enabled: Boolean(ecosystemId),
  });
}

function useAdminMutation<V>(ecosystemId: string | null | undefined, fn: (eco: string, v: V) => Promise<unknown>) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (v: V) => fn(ecosystemId as string, v),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: SUPPORT_ADMIN_KEY(ecosystemId ?? "") });
    },
  });
}

export const useRequestSupportGrant = (ecosystemId: string | null | undefined) =>
  useAdminMutation(ecosystemId, (eco, req: SupportGrantRequest) => supportAdminApi.request(eco, req));

export const useRevokeAdminGrant = (ecosystemId: string | null | undefined) =>
  useAdminMutation(ecosystemId, (eco, id: string) => supportAdminApi.revoke(eco, id));

/** One page of a content table in the viewer. Never retried: a 404 is a refused table and a 403
 *  an ended grant, and both are answers. The rows stay in memory only. */
export function useSupportData(
  grantId: string | null | undefined,
  schema: string | null | undefined,
  table: string | null | undefined,
  cursor?: string,
) {
  return useQuery({
    queryKey: ["support", "admin", "data", grantId ?? "", schema ?? "", table ?? "", cursor ?? ""],
    queryFn: () => supportAdminApi.data(grantId as string, schema as string, table as string, { cursor }),
    enabled: Boolean(grantId) && Boolean(schema) && Boolean(table),
    retry: false,
  });
}

export function useOperatorSupportGrants(filters: OperatorGrantFilters = {}) {
  return useQuery({
    queryKey: [...SUPPORT_OPERATOR_KEY, "grants", filters.status ?? "", filters.consent ?? "", filters.cursor ?? ""],
    queryFn: () => operatorSupportApi.list(filters),
  });
}

export function useOperatorSupportAccess(filters: Partial<OperatorSupportAccessFilters>) {
  return useQuery({
    queryKey: [...SUPPORT_OPERATOR_KEY, "access", filters.grantId ?? "", filters.cursor ?? ""],
    queryFn: () => operatorSupportApi.access(filters as OperatorSupportAccessFilters),
    enabled: Boolean(filters.grantId),
  });
}

function useOperatorMutation<V, R>(fn: (v: V) => Promise<R>) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: fn,
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: SUPPORT_OPERATOR_KEY });
    },
  });
}

export const useOperatorRequestGrant = () =>
  useOperatorMutation((body: OperatorGrantRequest) => operatorSupportApi.request(body));

export const useOperatorRevokeGrant = () => useOperatorMutation((id: string) => operatorSupportApi.revoke(id));

export const useBreakGlass = () => useOperatorMutation((body: BreakGlassRequest) => operatorSupportApi.breakGlass(body));

/** The emailed link's grant. Disabled until both the id and the token are there. */
export function usePublicSupportGrant(id: string | null | undefined, token: string | null | undefined) {
  return useQuery({
    queryKey: ["support", "public", id ?? ""],
    queryFn: () => publicSupportApi.get(id as string, token as string),
    enabled: Boolean(id) && Boolean(token),
    retry: false,
  });
}
