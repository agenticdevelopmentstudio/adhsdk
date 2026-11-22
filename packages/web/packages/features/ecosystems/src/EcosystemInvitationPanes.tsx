"use client";

import type { ReactElement } from "react";
import {
  InvitationRequestsPane,
  InvitationPendingUsersPane,
  InvitationInvitesPane,
} from "@adh-sdk/adh-ui/blocks";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { useOptionalAuth } from "@adh-sdk/auth";
import { FeatureTitle } from "@adh-sdk/resource";
import { NotesAndHistory } from "./NotesAndHistory";
import { AdminNotesModal } from "./AdminNotesModal";
import {
  useEcoInvitationRequests,
  useEcoPendingUsers,
  useEcoInvites,
  useEcoDeleteRow,
  useEcoSendInvitations,
  useEcoAddPendingUsers,
} from "@adh-sdk/data/ecosystems";

// The notes author for staged admin notes: the signed-in owner's email (the handle
// the backend records against each note). Empty until auth resolves — harmless, the
// editor only reads it when composing a new note. Optional auth: the product admin site
// mounts these panes under its own provider, not the hub's, and keeps no notes.
function useNotesAuthor(): string {
  return useOptionalAuth()?.user?.email ?? "";
}

/**
 * Who sees the admin records. `hideAdminRecords` (the product admin site, phase 6): admin notes
 * and entity history are the developer's records and stay at the hub, so the pane gets neither
 * notes slot and shows no notes, no history and no "Admin notes" action.
 */
interface InvitationPaneProps {
  ecosystemRdid: string;
  hideAdminRecords?: boolean;
}

function notesSlots(ecosystemRdid: string, author: string, hideAdminRecords: boolean | undefined) {
  if (hideAdminRecords) return {};
  return {
    renderNotesAndHistory: (s: { subjectTable: string; subjectId: string }) => (
      <NotesAndHistory ecosystemRdid={ecosystemRdid} {...s} />
    ),
    renderNotesModal: (s: { subjectTable: string; subjectId: string; open: boolean; onClose: () => void }) => (
      <AdminNotesModal ecosystemRdid={ecosystemRdid} author={author} {...s} />
    ),
  };
}

/** Invitation requests for the ecosystem. */
export function EcoRequestsPane({ ecosystemRdid, hideAdminRecords }: InvitationPaneProps): ReactElement {
  const author = useNotesAuthor();
  const { data: requests = [], isPending, isError } = useEcoInvitationRequests(ecosystemRdid);
  const deleteRow = useEcoDeleteRow(ecosystemRdid, "request");

  if (isError) return <ErrorText error="Failed to load requests." />;

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle
        title="Requests"
        api={{
          path: "/v1/invitation_requests",
          pathValues: {},
          queryValues: { ecosystem: ecosystemRdid },
          title: "Invitation requests API",
        }}
      />
      <div className="min-h-0 min-w-0 flex-1 overflow-y-auto">
        <InvitationRequestsPane
          rows={requests}
          loading={isPending}
          onDelete={(ids) => { for (const id of ids) deleteRow.mutate(id); }}
          {...notesSlots(ecosystemRdid, author, hideAdminRecords)}
        />
      </div>
    </div>
  );
}

/** Pending users for the ecosystem, with send-invitation + add-users flows. */
export function EcoPendingUsersPane({ ecosystemRdid, hideAdminRecords }: InvitationPaneProps): ReactElement {
  const author = useNotesAuthor();
  const { data: pendingUsers = [], isPending, isError } = useEcoPendingUsers(ecosystemRdid);
  const deleteRow = useEcoDeleteRow(ecosystemRdid, "pending");
  const sendInvitations = useEcoSendInvitations(ecosystemRdid);
  const addPendingUsers = useEcoAddPendingUsers(ecosystemRdid);

  if (isError) return <ErrorText error="Failed to load pending users." />;

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle
        title="Pending users"
        api={{
          path: "/v1/pending_users",
          pathValues: {},
          queryValues: { ecosystem: ecosystemRdid },
          title: "Pending users API",
        }}
      />
      <div className="min-h-0 min-w-0 flex-1 overflow-y-auto">
        <InvitationPendingUsersPane
          rows={pendingUsers}
          loading={isPending}
          onDelete={(ids) => { for (const id of ids) deleteRow.mutate(id); }}
          onSend={(payload) =>
            // mutateAsync: the shared pane closes the send modal only when this promise
            // resolves; a failed POST keeps it open for retry.
            sendInvitations.mutateAsync({
              pendingUserIds: payload.pendingUserIds,
              email: payload.email ? { note: payload.email.note } : undefined,
              sms: payload.sms ? { note: payload.sms.note } : undefined,
            })
          }
          onAdd={(users) =>
            addPendingUsers.mutate(
              // `|| undefined` (not `??`): DraftUser fields default to "", and `"" ?? undefined` keeps the
              // empty string — the backend's `email: z.string().email().optional()` then rejects "" (400),
              // breaking the SMS-only (name+phone, blank email) add. Coerce blanks to omitted instead.
              users.map((u) => ({ name: u.name, email: u.email || undefined, phone: u.phone || undefined, note: u.note || undefined })),
            )
          }
          sendBusy={sendInvitations.isPending}
          addBusy={addPendingUsers.isPending}
          {...notesSlots(ecosystemRdid, author, hideAdminRecords)}
        />
      </div>
    </div>
  );
}

/** Sent invites for the ecosystem. */
export function EcoInvitesPane({ ecosystemRdid, hideAdminRecords }: InvitationPaneProps): ReactElement {
  const author = useNotesAuthor();
  const { data: invites = [], isPending, isError } = useEcoInvites(ecosystemRdid);
  const deleteRow = useEcoDeleteRow(ecosystemRdid, "invite");

  if (isError) return <ErrorText error="Failed to load invites." />;

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle
        title="Invites"
        api={{
          path: "/v1/invitations",
          pathValues: {},
          queryValues: { ecosystem: ecosystemRdid },
          title: "Sent invitations API",
        }}
      />
      <div className="min-h-0 min-w-0 flex-1 overflow-y-auto">
        <InvitationInvitesPane
          rows={invites}
          loading={isPending}
          onDelete={(ids) => { for (const id of ids) deleteRow.mutate(id); }}
          {...notesSlots(ecosystemRdid, author, hideAdminRecords)}
        />
      </div>
    </div>
  );
}
