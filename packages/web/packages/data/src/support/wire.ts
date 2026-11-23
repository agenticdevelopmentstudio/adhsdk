"use client";

// Consented support access (phase 7): the wire shapes /v1 answers and their camel-cased rows.
// Hand-written, as every client in this package (see ../sets/wire.ts); the generated
// `SupportGrant`, `SupportRead` and `SupportAccessRow` in @adh-sdk/adh-api-types are the
// reference. Every timestamp here is ISO on the wire already: the gateway turns only
// `createdAt`/`updatedAt` into unix seconds, and a grant carries neither.

/** Who a grant is over. */
export interface SupportTargetWire {
  kind: "customer" | "account";
  id: string;
  display_name: string | null;
}

/** Who asked. `display_name` and `role_label` are what the person is shown. */
export interface SupportGranteeWire {
  kind: "product_admin" | "operator";
  display_name: string;
  role_label: string;
}

export type SupportGrantStatus = "pending" | "live" | "denied" | "lapsed" | "expired" | "revoked";

export interface SupportGrantWire {
  id: string;
  ecosystem_id: string;
  target: SupportTargetWire;
  grantee: SupportGranteeWire;
  reason: string;
  scope: "read_all";
  consent: "customer" | "break_glass";
  status: SupportGrantStatus;
  requested_hours: number;
  requested_at: string;
  decision: "approved" | "denied" | null;
  decided_at: string | null;
  expires_at: string | null;
  revoked_at: string | null;
  revoked_by_kind?: "target" | "grantee" | "operator" | "manager" | "system" | null;
  /** Operators only. */
  grantee_id?: string;
  attestation?: string | null;
  attestation_ref?: string | null;
}

/** One logged read, as the person (and the emailed link) sees it. */
export interface SupportReadWire {
  id: string;
  grant_id: string;
  grantee: SupportGranteeWire;
  /** The matched route pattern, e.g. `/support/grants/:id/data/:schema/:table`. */
  route: string | null;
  /** The request path, which names the table read. */
  path: string;
  at: string;
}

/** One logged read, as an operator sees it: the actor and method, no grantee name. */
export interface SupportAccessRowWire {
  id: string;
  grant_id: string;
  actor_id: string;
  method: string;
  path: string;
  route: string | null;
  request_id: string | null;
  at: string;
}

/** What the emailed link reads: the grant and its latest 50 reads, newest first. */
export interface SupportLinkGrantWire {
  grant: SupportGrantWire;
  reads: SupportReadWire[];
}

export type SupportSide = "customer" | "account";

/** A grant, for the person it is over. */
export interface SupportGrant {
  id: string;
  ecosystemId: string;
  granteeKind: "product_admin" | "operator";
  granteeName: string;
  granteeRole: string;
  reason: string;
  consent: "customer" | "break_glass";
  /** The length asked for, in hours. */
  requestedFor: number;
  requestedAt: string;
  /** `null` while undecided. */
  decision: "approved" | "denied" | null;
  decidedAt: string | null;
  expiresAt: string | null;
  revokedAt: string | null;
}

/** A grant, for a product admin or an operator: the person it is over as well. */
export interface SupportAdminGrant extends SupportGrant {
  targetId: string;
  targetName: string | null;
}

/** One logged read. `granteeName` is null on an operator's row, `method` on a person's. */
export interface SupportAccess {
  id: string;
  grantId: string;
  granteeName: string | null;
  route: string | null;
  path: string;
  method: string | null;
  at: string;
}

export interface SupportAccessPage {
  items: SupportAccess[];
  /** Pass back as `cursor` for the next page; null on the last. */
  nextCursor: string | null;
}

export const toSupportGrant = (w: SupportGrantWire): SupportGrant => ({
  id: w.id,
  ecosystemId: w.ecosystem_id,
  granteeKind: w.grantee.kind,
  granteeName: w.grantee.display_name,
  granteeRole: w.grantee.role_label,
  reason: w.reason,
  consent: w.consent,
  requestedFor: w.requested_hours,
  requestedAt: w.requested_at,
  decision: w.decision ?? null,
  decidedAt: w.decided_at ?? null,
  expiresAt: w.expires_at ?? null,
  revokedAt: w.revoked_at ?? null,
});

export const toSupportAdminGrant = (w: SupportGrantWire): SupportAdminGrant => ({
  ...toSupportGrant(w),
  targetId: w.target.id,
  targetName: w.target.display_name ?? null,
});

export const toSupportRead = (w: SupportReadWire): SupportAccess => ({
  id: w.id,
  grantId: w.grant_id,
  granteeName: w.grantee?.display_name ?? null,
  route: w.route ?? null,
  path: w.path,
  method: null,
  at: w.at,
});

export const toSupportAccessRow = (w: SupportAccessRowWire): SupportAccess => ({
  id: w.id,
  grantId: w.grant_id,
  granteeName: null,
  route: w.route ?? null,
  path: w.path,
  method: w.method,
  at: w.at,
});
