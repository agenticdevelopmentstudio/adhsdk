// Prop-driven invitation panes are fed these frontend view types. They + their
// pure field mappers are shared so every consumer (admin, hub) maps the byte-
// identical backend response shapes the same way. No react-query, no fetching —
// purely types + transforms.

export interface AdminNote { id: string; content: string; author: string; addedDate: string; modifiedDate: string; subjectTable: string; subjectId: string }
export interface HistoryEntry { id: string; actor: string; action: string; timestamp: string }

export interface InvitationRequest {
  id: string; userNumber: number; name: string; phone: string; email: string;
  requestedDate: string; source: string; note: string;
}
export interface PendingUser {
  id: string; name: string; phone: string; email: string;
  invitedCount: number; requestCount: number;
  lastRequestDate: string | null; lastInviteSentDate: string | null; requestedDate: string;
  lastSource: string; lastNote: string | null;
}
export interface Invite {
  id: string; name: string; email: string; sentBy: string; sentDate: string;
}
export type EntityKind = "request" | "pending" | "invite";

// Stable table-name constants that mirror the Phase-3 schema.
export const TABLE_INVITATION_REQUESTS = "invitation_requests" as const;
export const TABLE_PENDING_USERS = "pending_users" as const;
export const TABLE_INVITATIONS = "invitations" as const;

// ── Backend response shapes ───────────────────────────────────────────────────
// The /v1 wire rows: snake_case, `created`/`updated` in unix seconds. The mappers below
// map them field by field to the frontend types (requestedDate = created, lastRequestDate =
// last_request_at, etc.), so the exported view types do not move with the wire.

export interface BackendRequest {
  id: string;
  pending_user_id: string | null;
  name: string;
  email: string | null;
  phone: string | null;
  source: string | null;
  note: string | null;
  created: number;
  user_number: number | null;
}

export interface BackendPendingUser {
  id: string;
  user_number: number;
  name: string;
  email: string | null;
  phone: string | null;
  invited_count: number;
  request_count: number;
  last_request_at: string | null;
  last_invite_sent_at: string | null;
  first_requested_at: string;
  last_source: string | null;
  last_note: string | null;
  status: string;
}

export interface BackendInvite {
  id: string;
  name: string;
  channel: string;
  destination: string;
  sent_by: string;
  sent_at: string;
  status: string;
}

export interface BackendAdminNote {
  id: string;
  content: string;
  created_by: string;
  subject_table: string;
  subject_id: string;
  created: number;
  updated: number;
}

export interface BackendHistoryEntry {
  id: string;
  actor_label: string | null;
  actor_id: string | null;
  action: string;
  created: number;
}

/** The `YYYY-MM-DD` day of a unix-seconds timestamp, in UTC. */
function dayOf(seconds: number): string {
  return new Date(seconds * 1000).toISOString().slice(0, 10);
}

// ── Field mapping helpers ─────────────────────────────────────────────────────

export function toRequest(r: BackendRequest): InvitationRequest {
  return {
    id: r.id,
    userNumber: r.user_number ?? 0,
    name: r.name,
    email: r.email ?? "",
    phone: r.phone ?? "",
    requestedDate: dayOf(r.created),
    source: r.source ?? "",
    note: r.note ?? "",
  };
}

export function toPendingUser(u: BackendPendingUser): PendingUser {
  return {
    id: u.id,
    name: u.name,
    email: u.email ?? "",
    phone: u.phone ?? "",
    invitedCount: u.invited_count,
    requestCount: u.request_count,
    lastRequestDate: u.last_request_at ? u.last_request_at.slice(0, 10) : null,
    lastInviteSentDate: u.last_invite_sent_at ? u.last_invite_sent_at.slice(0, 10) : null,
    requestedDate: u.first_requested_at.slice(0, 10),
    lastSource: u.last_source ?? "",
    lastNote: u.last_note,
  };
}

export function toInvite(i: BackendInvite): Invite {
  return {
    id: i.id,
    name: i.name,
    // The invitations table stores destination (email or phone); use it as email.
    email: i.destination,
    sentBy: i.sent_by,
    sentDate: i.sent_at.slice(0, 10),
  };
}

export function toAdminNote(n: BackendAdminNote): AdminNote {
  return {
    id: n.id,
    content: n.content,
    author: n.created_by,
    addedDate: dayOf(n.created),
    modifiedDate: dayOf(n.updated),
    subjectTable: n.subject_table,
    subjectId: n.subject_id,
  };
}

export function toHistoryEntry(h: BackendHistoryEntry): HistoryEntry {
  return {
    id: h.id,
    actor: h.actor_label ?? h.actor_id ?? "system",
    action: h.action,
    timestamp: dayOf(h.created),
  };
}
