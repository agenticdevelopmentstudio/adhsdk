"use client";

import { useState, type FormEvent, type ReactElement, type ReactNode } from "react";

import { FeatureTitle } from "@adh-sdk/resource";
import {
  grantState,
  isSupportOff,
  SUPPORT_HOURS_DEFAULT,
  SUPPORT_HOURS_MAX,
  useOperatorRequestGrant,
  useOperatorRevokeGrant,
  useOperatorSupportGrants,
  type OperatorGrantFilters,
  type SupportAdminGrant,
  type SupportGrantStatus,
} from "@adh-sdk/data/support";
import { AdminGrantCard } from "@adh-sdk/support-access";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Label } from "@adh-sdk/ui/components/label";
import { Select } from "@adh-sdk/ui/components/select";

import {
  emptySupportTarget,
  supportRefusalText,
  supportTargetProblem,
  SupportTargetFields,
  toOperatorGrantRequest,
  type SupportTargetDraft,
} from "./supportTarget";

const STATUSES: SupportGrantStatus[] = ["pending", "live", "denied", "lapsed", "expired", "revoked"];

/** One list of grants with revoke on the live ones. */
function GrantList({
  grants,
  busyId,
  onRevoke,
}: {
  grants: readonly SupportAdminGrant[];
  busyId: string | null;
  onRevoke: (g: SupportAdminGrant) => void;
}) {
  const now = new Date();
  return (
    <div className="flex flex-col gap-3">
      {grants.map((g) => {
        const state = grantState(g, now);
        return (
          <AdminGrantCard key={g.id} grant={g} state={state}>
            {state === "live" && (
              <div>
                <Button
                  size="sm"
                  variant="destructive-ghost"
                  disabled={busyId === g.id}
                  aria-label={`Revoke the grant for ${g.targetName ?? g.targetId}`}
                  onClick={() => onRevoke(g)}
                >
                  Revoke
                </Button>
              </div>
            )}
          </AdminGrantCard>
        );
      })}
    </div>
  );
}

/**
 * Every support grant, for an operator (phase 7): filter by status and by consent, ask a customer
 * or a hub user for consent on someone's behalf, and revoke a live grant. Break-glass grants are
 * listed apart from consented ones, and a revoked break-glass grant is drawn in red. Asking needs a
 * second factor from a sign-in in the last ten minutes. While the backend's `consented_access`
 * switch is off the list answers 404 and the pane says so.
 */
export function SupportGrantsAdminPane({ help }: { help?: ReactNode } = {}): ReactElement {
  const [status, setStatus] = useState<OperatorGrantFilters["status"]>(undefined);
  const [consent, setConsent] = useState<OperatorGrantFilters["consent"]>(undefined);
  const [cursors, setCursors] = useState<string[]>([]);
  const cursor = cursors.length > 0 ? cursors[cursors.length - 1] : undefined;
  const list = useOperatorSupportGrants({ status, consent, cursor });
  const request = useOperatorRequestGrant();
  const revoke = useOperatorRevokeGrant();

  const [draft, setDraft] = useState<SupportTargetDraft>(() => emptySupportTarget(SUPPORT_HOURS_DEFAULT));
  const [formError, setFormError] = useState<string | null>(null);
  const [sent, setSent] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [listError, setListError] = useState<string | null>(null);

  const off = list.error && isSupportOff(list.error);
  const items = list.data?.items ?? [];
  const breakGlass = items.filter((g) => g.consent === "break_glass");
  const consented = items.filter((g) => g.consent !== "break_glass");

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (request.isPending) return;
    setFormError(null);
    setSent(false);
    const problem = supportTargetProblem(draft, SUPPORT_HOURS_MAX);
    if (problem) {
      setFormError(problem);
      return;
    }
    try {
      await request.mutateAsync(toOperatorGrantRequest(draft));
      setDraft(emptySupportTarget(SUPPORT_HOURS_DEFAULT));
      setSent(true);
    } catch (err) {
      setFormError(supportRefusalText(err));
    }
  };

  const onRevoke = async (g: SupportAdminGrant) => {
    if (busyId) return;
    setBusyId(g.id);
    setListError(null);
    try {
      await revoke.mutateAsync(g.id);
    } catch (err) {
      setListError(supportRefusalText(err));
    } finally {
      setBusyId(null);
    }
  };

  const refilter = (fn: () => void) => {
    fn();
    setCursors([]);
  };

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle title="Support Grants" help={help} />
      <div className="flex min-h-0 min-w-0 flex-1 flex-col gap-8 overflow-y-auto px-6 pb-8 pt-2">
        {off ? (
          <p className="text-sm text-apt-text-muted">Support access is not turned on.</p>
        ) : (
          <>
            <form
              aria-label="Ask for consent"
              noValidate
              onSubmit={submit}
              className="flex max-w-xl flex-col gap-3"
            >
              <h2 className="text-base font-medium text-apt-text">Ask for consent</h2>
              <p className="text-sm text-apt-text-muted">
                The person is asked to approve. Needs a second factor from a sign-in in the last ten minutes.
              </p>
              <SupportTargetFields idPrefix="support-request" draft={draft} onChange={setDraft} maxHours={SUPPORT_HOURS_MAX} />
              <ErrorText error={formError} />
              {sent && <p className="text-sm text-apt-green">Asked. The person has been sent the request.</p>}
              <div>
                <Button type="submit" disabled={request.isPending}>
                  Ask for consent
                </Button>
              </div>
            </form>

            <section aria-label="Grants" className="flex flex-col gap-4">
              <div className="flex flex-wrap items-end gap-3">
                <div className="flex flex-col gap-1">
                  <Label htmlFor="support-filter-status">Status</Label>
                  <Select
                    id="support-filter-status"
                    value={status ?? ""}
                    onChange={(e) =>
                      refilter(() => setStatus((e.target.value || undefined) as OperatorGrantFilters["status"]))
                    }
                  >
                    <option value="">Any status</option>
                    {STATUSES.map((s) => (
                      <option key={s} value={s}>
                        {s}
                      </option>
                    ))}
                  </Select>
                </div>
                <div className="flex flex-col gap-1">
                  <Label htmlFor="support-filter-consent">Consent</Label>
                  <Select
                    id="support-filter-consent"
                    value={consent ?? ""}
                    onChange={(e) =>
                      refilter(() => setConsent((e.target.value || undefined) as OperatorGrantFilters["consent"]))
                    }
                  >
                    <option value="">Any</option>
                    <option value="customer">Consented</option>
                    <option value="break_glass">Break-glass</option>
                  </Select>
                </div>
              </div>

              <ErrorText error={listError} />
              {list.error && !off && <ErrorText error={supportRefusalText(list.error)} />}
              {list.isLoading && <p className="text-sm text-apt-text-muted">Loading…</p>}
              {list.data && items.length === 0 && <p className="text-sm text-apt-text-muted">No grants.</p>}

              {breakGlass.length > 0 && (
                <section aria-label="Break-glass grants" className="flex flex-col gap-2">
                  <h2 className="text-base font-medium text-apt-red">Break-glass</h2>
                  <GrantList grants={breakGlass} busyId={busyId} onRevoke={(g) => void onRevoke(g)} />
                </section>
              )}
              {consented.length > 0 && (
                <section aria-label="Consented grants" className="flex flex-col gap-2">
                  <h2 className="text-base font-medium text-apt-text">Consented</h2>
                  <GrantList grants={consented} busyId={busyId} onRevoke={(g) => void onRevoke(g)} />
                </section>
              )}

              {(cursors.length > 0 || list.data?.nextCursor) && (
                <div className="flex items-center gap-2">
                  <Button
                    size="sm"
                    variant="ghost"
                    disabled={cursors.length === 0}
                    onClick={() => setCursors((c) => c.slice(0, -1))}
                  >
                    Previous
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    disabled={!list.data?.nextCursor}
                    onClick={() => {
                      const next = list.data?.nextCursor;
                      if (next) setCursors((c) => [...c, next]);
                    }}
                  >
                    Next
                  </Button>
                </div>
              )}
            </section>
          </>
        )}
      </div>
    </div>
  );
}
