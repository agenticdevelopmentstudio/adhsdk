// Ecosystem-owner react-query glue for the Invitations topic. Same shapes as the
// platform-admin hooks (@adh-sdk/adh-admin api/invitations.ts), but each hook takes the
// ecosystem's rdid, builds its URLs from ecosystemInvitationEndpoints(rdid) (the /v1
// invitation, note and history routes with `?ecosystem=<rdid>`), maps the backend rows with
// the shared mappers, and namespaces its query keys by rdid so two ecosystems' caches never
// collide. No pane logic here — the panes are prop-driven.
//
// The wire is the admin hooks' wire, ecosystem-scoped: every read is a /v1 LIST
// (`{object:"list", data, has_more}`, paged through listAllV1), and every write is a /v1 POST
// with a snake_case body that names its ecosystem (E.withEcosystem). Reading a list as a bare
// array threw on `.map` and left each pane on "Failed to load".

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { authedJson, authedRequest, listAllV1 } from "../http";
import {
  toRequest,
  toPendingUser,
  toInvite,
  toAdminNote,
  toHistoryEntry,
  type InvitationRequest,
  type PendingUser,
  type Invite,
  type AdminNote,
  type HistoryEntry,
  type EntityKind,
  type BackendRequest,
  type BackendPendingUser,
  type BackendInvite,
  type BackendAdminNote,
  type BackendHistoryEntry,
} from "@adh-sdk/adh-ui/invitations-types";
import { ecosystemInvitationEndpoints } from "@adh-sdk/adh-ui/invitations-endpoints";

// ── Query keys (namespaced by ecosystem rdid) ───────────────────────────────────

const KEYS = {
  requests: (rdid: string) => ["eco-inv", rdid, "requests"] as const,
  pending: (rdid: string) => ["eco-inv", rdid, "pending"] as const,
  invites: (rdid: string) => ["eco-inv", rdid, "invites"] as const,
  notes: (rdid: string, subjectTable: string, subjectId: string) =>
    ["eco-inv", rdid, "notes", subjectTable, subjectId] as const,
  history: (rdid: string, subjectTable: string, subjectId: string) =>
    ["eco-inv", rdid, "history", subjectTable, subjectId] as const,
};

// ── List hooks ────────────────────────────────────────────────────────────────

export function useEcoInvitationRequests(ecosystemRdid: string) {
  const E = ecosystemInvitationEndpoints(ecosystemRdid);
  return useQuery({
    queryKey: KEYS.requests(ecosystemRdid),
    queryFn: async (): Promise<InvitationRequest[]> => {
      const rows = await listAllV1<BackendRequest>(E.requests);
      return rows.map(toRequest);
    },
  });
}

export function useEcoPendingUsers(ecosystemRdid: string) {
  const E = ecosystemInvitationEndpoints(ecosystemRdid);
  return useQuery({
    queryKey: KEYS.pending(ecosystemRdid),
    queryFn: async (): Promise<PendingUser[]> => {
      const rows = await listAllV1<BackendPendingUser>(E.pendingUsers);
      return rows.map(toPendingUser);
    },
  });
}

export function useEcoInvites(ecosystemRdid: string) {
  const E = ecosystemInvitationEndpoints(ecosystemRdid);
  return useQuery({
    queryKey: KEYS.invites(ecosystemRdid),
    queryFn: async (): Promise<Invite[]> => {
      const rows = await listAllV1<BackendInvite>(E.invitations);
      return rows.map(toInvite);
    },
  });
}

// ── Notes + history hooks ─────────────────────────────────────────────────────

export function useEcoRowNotes(ecosystemRdid: string, subjectTable: string, subjectId: string) {
  const E = ecosystemInvitationEndpoints(ecosystemRdid);
  return useQuery({
    queryKey: KEYS.notes(ecosystemRdid, subjectTable, subjectId),
    queryFn: async (): Promise<AdminNote[]> => {
      const rows = await listAllV1<BackendAdminNote>(E.adminNotes(subjectTable, subjectId));
      return rows.map(toAdminNote);
    },
    enabled: !!subjectId,
  });
}

export function useEcoRowHistory(ecosystemRdid: string, subjectTable: string, subjectId: string) {
  const E = ecosystemInvitationEndpoints(ecosystemRdid);
  return useQuery({
    queryKey: KEYS.history(ecosystemRdid, subjectTable, subjectId),
    queryFn: async (): Promise<HistoryEntry[]> => {
      const rows = await listAllV1<BackendHistoryEntry>(E.entityHistory(subjectTable, subjectId));
      return rows.map(toHistoryEntry);
    },
    enabled: !!subjectId,
  });
}

export function useEcoSaveNotes(ecosystemRdid: string) {
  const E = ecosystemInvitationEndpoints(ecosystemRdid);
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      subjectTable,
      subjectId,
      notes,
    }: {
      subjectTable: string;
      subjectId: string;
      notes: { id?: string; content: string }[];
    }) =>
      authedJson(E.adminNotesPut, {
        method: "POST",
        body: JSON.stringify(
          E.withEcosystem({
            subject_table: subjectTable,
            subject_id: subjectId,
            notes: notes.map((n) => ({ id: n.id, content: n.content })),
          }),
        ),
      }),
    onSuccess: (_data, { subjectTable, subjectId }) => {
      void qc.invalidateQueries({ queryKey: KEYS.notes(ecosystemRdid, subjectTable, subjectId) });
      void qc.invalidateQueries({ queryKey: KEYS.history(ecosystemRdid, subjectTable, subjectId) });
    },
  });
}

// ── Mutation hooks ────────────────────────────────────────────────────────────

export function useEcoSendInvitations(ecosystemRdid: string) {
  const E = ecosystemInvitationEndpoints(ecosystemRdid);
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      pendingUserIds,
      email,
      sms,
    }: {
      pendingUserIds: string[];
      email?: { note?: string };
      sms?: { note?: string };
    }) =>
      authedJson(E.invitationsSend, {
        method: "POST",
        body: JSON.stringify(E.withEcosystem({ pending_user_ids: pendingUserIds, email, sms })),
      }),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: KEYS.pending(ecosystemRdid) });
      void qc.invalidateQueries({ queryKey: KEYS.invites(ecosystemRdid) });
    },
  });
}

export function useEcoAddPendingUsers(ecosystemRdid: string) {
  const E = ecosystemInvitationEndpoints(ecosystemRdid);
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (users: Array<{ name: string; email?: string; phone?: string; note?: string }>) =>
      authedJson(E.pendingUsersCreate, {
        method: "POST",
        body: JSON.stringify(E.withEcosystem({ users })),
      }),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: KEYS.pending(ecosystemRdid) });
    },
  });
}

/** Delete one row from a topic. kind = EntityKind mapped to the endpoint. */
export function useEcoDeleteRow(ecosystemRdid: string, kind: EntityKind) {
  const E = ecosystemInvitationEndpoints(ecosystemRdid);
  const qc = useQueryClient();
  const itemUrl =
    kind === "request"
      ? E.requestItem
      : kind === "pending"
        ? E.pendingUserItem
        : E.invitationItem;
  return useMutation({
    mutationFn: (id: string) =>
      authedRequest(itemUrl(id), {
        method: "DELETE",
      }),
    onSuccess: () => {
      if (kind === "request") void qc.invalidateQueries({ queryKey: KEYS.requests(ecosystemRdid) });
      else if (kind === "pending") void qc.invalidateQueries({ queryKey: KEYS.pending(ecosystemRdid) });
      else void qc.invalidateQueries({ queryKey: KEYS.invites(ecosystemRdid) });
    },
  });
}
