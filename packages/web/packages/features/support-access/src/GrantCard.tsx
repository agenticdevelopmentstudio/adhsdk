"use client";

import type { ReactNode } from "react";

import type { SupportGrant, SupportGrantState } from "@adh-sdk/data/support";
import { Badge } from "@adh-sdk/ui/components/badge";
import { Button } from "@adh-sdk/ui/components/button";

export type GrantAction = "approve" | "deny" | "revoke";

/** "1 hour", "24 hours", "2 days", "1 day and 12 hours". */
export function hoursPhrase(hours: number): string {
  const h = Math.max(0, Math.round(hours));
  const plural = (n: number, w: string) => `${n} ${w}${n === 1 ? "" : "s"}`;
  if (h <= 24) return plural(h, "hour");
  const days = Math.floor(h / 24);
  const rest = h % 24;
  return rest === 0 ? plural(days, "day") : `${plural(days, "day")} and ${plural(rest, "hour")}`;
}

const when = (iso: string | null) => {
  if (!iso) return "";
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? ""
    : d.toLocaleString(undefined, { weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit" });
};

/** Why an ended grant ended, from its own fields. */
function endedLabel(g: SupportGrant): string {
  if (g.revokedAt) return "Revoked";
  if (g.decision === "denied") return "Denied";
  if (g.decision === null) return "Lapsed";
  return "Expired";
}

/**
 * One grant over the person: who asked, why, for how long and where it stands. A pending grant
 * offers approve and deny, a live one revoke, an ended one nothing and is greyed. A break-glass
 * grant is marked: it was opened without asking, in an emergency, and the person can still end it.
 */
export function GrantCard({
  grant,
  state,
  busy,
  onAction,
  children,
}: {
  grant: SupportGrant;
  state: SupportGrantState;
  busy?: boolean;
  onAction: (action: GrantAction) => void;
  /** The read log, shown under the grant. */
  children?: ReactNode;
}) {
  const name = grant.granteeName;
  const breakGlass = grant.consent === "break_glass";
  return (
    <article
      aria-label={`${name}, ${grant.granteeRole}`}
      data-state={state}
      className={`flex flex-col gap-3 rounded-md border border-apt-border p-4 ${state === "ended" ? "opacity-60" : ""}`}
    >
      <header className="flex flex-wrap items-center gap-2">
        <span className="text-sm font-medium text-apt-text">{name}</span>
        <span className="text-xs text-apt-text-muted">{grant.granteeRole}</span>
        {state === "pending" && <Badge variant="accent">Waiting for you</Badge>}
        {state === "live" && <Badge variant="success">Can view now</Badge>}
        {state === "ended" && <Badge>{endedLabel(grant)}</Badge>}
        {breakGlass && <Badge variant="error">Emergency access</Badge>}
      </header>

      <p className="text-sm text-apt-text">{grant.reason}</p>

      <p className="text-xs text-apt-text-muted">
        {breakGlass
          ? `Opened without asking you, in an emergency, for ${hoursPhrase(grant.requestedFor)}.`
          : `Asked ${when(grant.requestedAt)} to view your content for ${hoursPhrase(grant.requestedFor)}.`}
        {state === "live" && grant.expiresAt ? ` Ends ${when(grant.expiresAt)}.` : ""}
      </p>

      {state === "pending" && (
        <div className="flex items-center gap-2">
          <Button size="sm" disabled={busy} aria-label={`Approve ${name}'s request`} onClick={() => onAction("approve")}>
            Approve
          </Button>
          <Button
            size="sm"
            variant="ghost"
            disabled={busy}
            aria-label={`Deny ${name}'s request`}
            onClick={() => onAction("deny")}
          >
            Deny
          </Button>
        </div>
      )}
      {state === "live" && (
        <div className="flex items-center gap-2">
          <Button
            size="sm"
            variant="destructive-ghost"
            disabled={busy}
            aria-label={`Revoke ${name}'s access`}
            onClick={() => onAction("revoke")}
          >
            Revoke
          </Button>
        </div>
      )}

      {children}
    </article>
  );
}
