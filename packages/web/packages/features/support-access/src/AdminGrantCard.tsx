"use client";

import type { ReactNode, ReactElement } from "react";

import type { SupportAdminGrant, SupportGrantState } from "@adh-sdk/data/support";
import { Badge } from "@adh-sdk/ui/components/badge";

import { endedLabel, grantTime, hoursPhrase } from "./GrantCard";

/**
 * One grant as the side that asked for it sees it: a product admin, or an operator. Whose content
 * it covers, who asked, why, for how long and where it stands; the caller's actions go in
 * `children`. An ended grant is greyed, except a revoked break-glass grant, which is drawn in red:
 * an emergency opening that someone had to shut is the one ended grant an operator must not miss.
 * GrantCard is the person's own view of the same grant.
 */
export function AdminGrantCard({
  grant,
  state,
  children,
}: {
  grant: SupportAdminGrant;
  state: SupportGrantState;
  /** The actions: open and revoke on a live grant. */
  children?: ReactNode;
}): ReactElement {
  const breakGlass = grant.consent === "break_glass";
  const revokedBreakGlass = breakGlass && grant.revokedAt !== null;
  const target = grant.targetName ?? grant.targetId;
  const border = revokedBreakGlass ? "border-apt-red" : "border-apt-border";
  const faded = state === "ended" && !revokedBreakGlass ? "opacity-60" : "";
  return (
    <article
      aria-label={`Support grant for ${target}`}
      data-state={state}
      data-revoked-break-glass={revokedBreakGlass ? "true" : undefined}
      className={`flex flex-col gap-2 rounded-md border p-4 ${border} ${faded}`}
    >
      <header className="flex flex-wrap items-center gap-2">
        <span className="text-sm font-medium text-apt-text">{target}</span>
        <span className="text-xs text-apt-text-muted">
          asked by {grant.granteeName}, {grant.granteeRole}
        </span>
        {state === "pending" && <Badge variant="accent">Waiting for consent</Badge>}
        {state === "live" && <Badge variant="success">Live</Badge>}
        {state === "ended" && (
          <Badge variant={revokedBreakGlass ? "error" : "neutral"}>{endedLabel(grant)}</Badge>
        )}
        {breakGlass && <Badge variant="error">Break-glass</Badge>}
      </header>

      <p className="text-sm text-apt-text">{grant.reason}</p>

      <p className={`text-xs ${revokedBreakGlass ? "text-apt-red" : "text-apt-text-muted"}`}>
        {`Asked ${grantTime(grant.requestedAt)} for ${hoursPhrase(grant.requestedFor)}.`}
        {state === "live" && grant.expiresAt ? ` Ends ${grantTime(grant.expiresAt)}.` : ""}
        {grant.revokedAt ? ` Revoked ${grantTime(grant.revokedAt)}.` : ""}
      </p>

      {children}
    </article>
  );
}
