"use client";

import { useState, type FormEvent, type ReactElement } from "react";

import { useOptionalProductAdminAuth } from "@adh-sdk/auth";
import { useProductCustomers } from "@adh-sdk/data/product-admin";
import {
  grantState,
  isStepUpRequired,
  isSupportOff,
  SUPPORT_HOURS_DEFAULT,
  SUPPORT_HOURS_MAX,
  SUPPORT_REASON_MAX,
  supportRequestProblem,
  useAdminSupportGrants,
  useRequestSupportGrant,
  useRevokeAdminGrant,
  type SupportAdminGrant,
  type SupportGrantState,
} from "@adh-sdk/data/support";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { Label } from "@adh-sdk/ui/components/label";
import { Select } from "@adh-sdk/ui/components/select";
import { Textarea } from "@adh-sdk/ui/components/textarea";

import { AdminGrantCard } from "./AdminGrantCard";
import { SupportViewer } from "./SupportViewer";

const ORDER: Record<SupportGrantState, number> = { live: 0, pending: 1, ended: 2 };

/** Live first, then pending, then ended; newest request first within each. */
function ordered(grants: readonly SupportAdminGrant[], now: Date) {
  return grants
    .map((grant) => ({ grant, state: grantState(grant, now) }))
    .sort(
      (a, b) =>
        ORDER[a.state] - ORDER[b.state] || Date.parse(b.grant.requestedAt) - Date.parse(a.grant.requestedAt),
    );
}

const message = (err: unknown) => (err instanceof Error && err.message ? err.message : "Something went wrong.");

export interface SupportGrantsPaneProps {
  /** The product (ecosystem) uuid. */
  ecosystemId: string;
  /** Where a step-up sign-in comes back to. Defaults to `/support`, the page this pane is. */
  returnPath?: string;
  /** Overrides the step-up; by default the pane calls the ProductAdminAuthProvider's `stepUp`. */
  onStepUp?: (returnPath: string) => void;
}

/**
 * A product admin's support grants (phase 7): ask a customer for consent to view their content,
 * see each grant's state, open a live grant in the read-only viewer, and revoke it. Asking needs a
 * second factor from a recent sign-in, so an answer of 403 `step_up_required` sends the admin
 * through sign-in again and back to `returnPath`. While the backend's `consented_access` switch is
 * off the grants read answers 404 and the pane says support access is not on.
 */
export function SupportGrantsPane({
  ecosystemId,
  returnPath = "/support",
  onStepUp,
}: SupportGrantsPaneProps): ReactElement {
  const auth = useOptionalProductAdminAuth();
  const stepUp = onStepUp ?? auth?.stepUp;

  const grants = useAdminSupportGrants(ecosystemId);
  const request = useRequestSupportGrant(ecosystemId);
  const revoke = useRevokeAdminGrant(ecosystemId);

  const [q, setQ] = useState("");
  const customers = useProductCustomers(ecosystemId, { q: q.trim() || undefined });
  const [targetId, setTargetId] = useState("");
  const [reason, setReason] = useState("");
  const [hours, setHours] = useState(String(SUPPORT_HOURS_DEFAULT));
  const [formError, setFormError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  const [openId, setOpenId] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [listError, setListError] = useState<string | null>(null);

  if (grants.error && isSupportOff(grants.error)) {
    return <p className="text-sm text-apt-text-muted">Support access is not turned on for this product.</p>;
  }

  /** A refusal for a stale or single-factor sign-in goes to step-up; anything else is shown. */
  const refused = (err: unknown, show: (m: string) => void) => {
    if (isStepUpRequired(err) && stepUp) {
      stepUp(returnPath);
      return;
    }
    show(isStepUpRequired(err) ? "Sign in again with your second factor, then try again." : message(err));
  };

  const roster = customers.data?.items ?? [];
  // The customer the request goes to is only ever one the admin can see in the list: a search
  // that filters the chosen customer out leaves the Select on "Choose a customer", so the form
  // must not quietly send to the hidden one.
  const chosenId = roster.some((c) => c.id === targetId) ? targetId : "";

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (request.isPending) return;
    setFormError(null);
    setSent(false);
    if (!chosenId) {
      setFormError("Choose a customer.");
      return;
    }
    const h = Number(hours);
    const problem = supportRequestProblem({ reason, hours: h });
    if (problem) {
      setFormError(problem);
      return;
    }
    try {
      await request.mutateAsync({ targetId: chosenId, reason: reason.trim(), hours: h });
      setReason("");
      setSent(true);
    } catch (err) {
      refused(err, setFormError);
    }
  };

  const end = async (grant: SupportAdminGrant) => {
    if (busyId) return;
    setBusyId(grant.id);
    setListError(null);
    try {
      await revoke.mutateAsync(grant.id);
      if (openId === grant.id) setOpenId(null);
    } catch (err) {
      refused(err, setListError);
    } finally {
      setBusyId(null);
    }
  };

  const rows = ordered(grants.data ?? [], new Date());

  return (
    <div className="flex flex-col gap-8">
      <form aria-label="Ask a customer for access" noValidate onSubmit={submit} className="flex max-w-xl flex-col gap-3">
        <h2 className="text-base font-medium text-apt-text">Ask a customer for access</h2>
        <p className="text-sm text-apt-text-muted">
          The customer is asked to approve. Once they do, you can view their content, read only, until the time
          runs out or either of you revokes it. Asking needs a second factor from a recent sign-in.
        </p>

        <div className="flex flex-col gap-1">
          <Label htmlFor="support-customer-search">Find a customer</Label>
          <Input
            id="support-customer-search"
            type="search"
            value={q}
            placeholder="Name or email"
            onChange={(e) => setQ(e.target.value)}
          />
        </div>
        <div className="flex flex-col gap-1">
          <Label htmlFor="support-customer">Customer</Label>
          <Select id="support-customer" value={chosenId} onChange={(e) => setTargetId(e.target.value)}>
            <option value="">Choose a customer</option>
            {roster.map((c) => (
              <option key={c.id} value={c.id}>
                {c.displayName && c.email ? `${c.displayName} (${c.email})` : (c.displayName ?? c.email ?? c.id)}
              </option>
            ))}
          </Select>
        </div>
        <div className="flex flex-col gap-1">
          <Label htmlFor="support-reason">Reason</Label>
          <Textarea
            id="support-reason"
            value={reason}
            maxLength={SUPPORT_REASON_MAX}
            placeholder="What you need to see, and why. The customer reads this."
            onChange={(e) => setReason(e.target.value)}
          />
        </div>
        <div className="flex flex-col gap-1">
          <Label htmlFor="support-hours">Hours</Label>
          <Input
            id="support-hours"
            type="number"
            min={1}
            max={SUPPORT_HOURS_MAX}
            step={1}
            value={hours}
            onChange={(e) => setHours(e.target.value)}
          />
          <span className="text-xs text-apt-text-muted">From 1 hour to 7 days ({SUPPORT_HOURS_MAX} hours).</span>
        </div>
        <ErrorText error={formError} />
        {sent && <p className="text-sm text-apt-green">Asked. The customer has been sent the request.</p>}
        <div>
          <Button type="submit" disabled={request.isPending}>
            Ask for access
          </Button>
        </div>
      </form>

      <section aria-label="Support grants" className="flex flex-col gap-3">
        <h2 className="text-base font-medium text-apt-text">Grants</h2>
        <ErrorText error={listError} />
        {grants.error && !isSupportOff(grants.error) && <ErrorText error={message(grants.error)} />}
        {grants.isLoading && <p className="text-sm text-apt-text-muted">Loading…</p>}
        {grants.data && rows.length === 0 && <p className="text-sm text-apt-text-muted">No grants yet.</p>}
        {rows.map(({ grant, state }) => (
          <AdminGrantCard key={grant.id} grant={grant} state={state}>
            {state === "live" && (
              <div className="flex flex-col gap-3">
                <div className="flex items-center gap-2">
                  <Button
                    size="sm"
                    variant="outline"
                    aria-expanded={openId === grant.id}
                    onClick={() => setOpenId(openId === grant.id ? null : grant.id)}
                  >
                    {openId === grant.id ? "Close" : "Open"}
                  </Button>
                  <Button
                    size="sm"
                    variant="destructive-ghost"
                    disabled={busyId === grant.id}
                    aria-label={`Revoke access to ${grant.targetName ?? grant.targetId}`}
                    onClick={() => void end(grant)}
                  >
                    Revoke
                  </Button>
                </div>
                {openId === grant.id && <SupportViewer grantId={grant.id} />}
              </div>
            )}
          </AdminGrantCard>
        ))}
      </section>
    </div>
  );
}
