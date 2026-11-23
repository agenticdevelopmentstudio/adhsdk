"use client";

import { useState, type ReactElement } from "react";

import {
  grantState,
  isSupportOff,
  useDecideSupportGrant,
  useSupportGrants,
  type SupportGrant,
  type SupportGrantState,
  type SupportSide,
} from "@adh-sdk/data/support";
import { ErrorText } from "@adh-sdk/ui/components/error-text";

import { AccessLogList } from "./AccessLogList";
import { GrantCard, type GrantAction } from "./GrantCard";

const ORDER: Record<SupportGrantState, number> = { pending: 0, live: 1, ended: 2 };

/** Pending first, then live, then ended; newest request first within each. */
function ordered(grants: readonly SupportGrant[], now: Date) {
  return grants
    .map((grant) => ({ grant, state: grantState(grant, now) }))
    .sort(
      (a, b) =>
        ORDER[a.state] - ORDER[b.state] || Date.parse(b.grant.requestedAt) - Date.parse(a.grant.requestedAt),
    );
}

/**
 * Who has asked to see the person's content, for a customer (`side="customer"`) or a hub user
 * (`side="account"`): every grant over them, pending first with approve and deny, live ones with
 * revoke, ended ones greyed, and under each grant that was opened the reads it made. Renders
 * nothing while the backend's `consented_access` switch is off (the grants read answers 404). A
 * refused action shows the backend's own message.
 */
export function SupportAccessPane({ side }: { side: SupportSide }): ReactElement | null {
  const grants = useSupportGrants(side);
  const decide = useDecideSupportGrant(side);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  if (grants.error && isSupportOff(grants.error)) return null;

  const act = async (grant: SupportGrant, action: GrantAction) => {
    if (busyId) return;
    setBusyId(grant.id);
    setError(null);
    try {
      await decide.mutateAsync({ id: grant.id, action });
    } catch (err) {
      setError(err instanceof Error && err.message ? err.message : "Something went wrong.");
    } finally {
      setBusyId(null);
    }
  };

  const now = new Date();
  const rows = ordered(grants.data ?? [], now);

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-apt-text-muted">
        Support can only see your content when you say yes, for as long as you allow, and every view is listed
        here. You can end access at any time.
      </p>
      <ErrorText error={error} />

      {grants.error ? (
        <ErrorText error={`Couldn't load support access: ${grants.error.message}`} />
      ) : grants.isPending ? (
        <p className="text-sm text-apt-text-muted">Loading…</p>
      ) : rows.length === 0 ? (
        <p className="text-sm text-apt-text-muted">No one has asked to see your content.</p>
      ) : (
        <div className="flex flex-col gap-3">
          {rows.map(({ grant, state }) => (
            <GrantCard
              key={grant.id}
              grant={grant}
              state={state}
              busy={busyId === grant.id}
              onAction={(action) => void act(grant, action)}
            >
              {grant.decision === "approved" && (
                <AccessLogList
                  side={side}
                  grantId={grant.id}
                  granteeName={grant.granteeName}
                  granteeRole={grant.granteeRole}
                />
              )}
            </GrantCard>
          ))}
        </div>
      )}
    </div>
  );
}
