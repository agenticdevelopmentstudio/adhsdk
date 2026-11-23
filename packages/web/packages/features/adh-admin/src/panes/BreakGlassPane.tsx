"use client";

import { useState, type FormEvent, type ReactElement, type ReactNode } from "react";

import { FeatureTitle } from "@adh-sdk/resource";
import {
  SUPPORT_ATTESTATION_MIN,
  SUPPORT_BREAK_GLASS_HOURS_MAX,
  useBreakGlass,
  type SupportAdminGrant,
} from "@adh-sdk/data/support";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { Label } from "@adh-sdk/ui/components/label";
import { Textarea } from "@adh-sdk/ui/components/textarea";

import { formatDateTime } from "../lib/timestamps";
import {
  emptySupportTarget,
  supportRefusalText,
  supportTargetProblem,
  SupportTargetFields,
  toOperatorGrantRequest,
  type SupportTargetDraft,
} from "./supportTarget";

/** The longest reference 0309's route takes. */
const REFERENCE_MAX = 500;

/**
 * Break glass (phase 7, design section 7): an operator opens a support grant at once, without the
 * person's consent, for an emergency. It needs the target, the product for a customer, a reason,
 * an attestation of at least 40 characters, the case or ticket reference, and 1 to 4 hours; and a
 * second factor from a sign-in in the last ten minutes (aal 2), which the pane says up front. The
 * person is told, and can still revoke it.
 */
export function BreakGlassPane({ help }: { help?: ReactNode } = {}): ReactElement {
  const breakGlass = useBreakGlass();
  const [draft, setDraft] = useState<SupportTargetDraft>(() => emptySupportTarget(1));
  const [attestation, setAttestation] = useState("");
  const [reference, setReference] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [opened, setOpened] = useState<SupportAdminGrant | null>(null);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (breakGlass.isPending) return;
    setError(null);
    setOpened(null);
    const problem =
      supportTargetProblem(draft, SUPPORT_BREAK_GLASS_HOURS_MAX) ??
      (attestation.trim().length < SUPPORT_ATTESTATION_MIN
        ? `The attestation must be at least ${SUPPORT_ATTESTATION_MIN} characters.`
        : null) ??
      (reference.trim() ? null : "Give the case or ticket reference.");
    if (problem) {
      setError(problem);
      return;
    }
    try {
      const g = await breakGlass.mutateAsync({
        ...toOperatorGrantRequest(draft),
        attestation: attestation.trim(),
        attestationRef: reference.trim(),
      });
      setOpened(g);
      setDraft(emptySupportTarget(1));
      setAttestation("");
      setReference("");
    } catch (err) {
      setError(supportRefusalText(err));
    }
  };

  return (
    <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <FeatureTitle title="Break Glass" help={help} />
      <div className="flex min-h-0 min-w-0 flex-1 flex-col overflow-y-auto px-6 pb-8 pt-2">
        <form aria-label="Break glass" noValidate onSubmit={submit} className="flex max-w-xl flex-col gap-3">
          <p className="text-sm text-apt-text">
            Opens a support grant at once, without asking, for an emergency. The person is told and can revoke
            it. Every read is logged.
          </p>
          <p className="text-sm font-medium text-apt-red" data-testid="aal-required">
            Requires a second factor (aal 2) from a sign-in in the last ten minutes.
          </p>
          <SupportTargetFields
            idPrefix="break-glass"
            draft={draft}
            onChange={setDraft}
            maxHours={SUPPORT_BREAK_GLASS_HOURS_MAX}
          />
          <div className="flex flex-col gap-1">
            <Label htmlFor="break-glass-attestation">Attestation</Label>
            <Textarea
              id="break-glass-attestation"
              value={attestation}
              placeholder="Why this cannot wait for consent. At least 40 characters."
              onChange={(e) => setAttestation(e.target.value)}
            />
            <span className="text-xs text-apt-text-muted">
              {attestation.trim().length} of at least {SUPPORT_ATTESTATION_MIN} characters.
            </span>
          </div>
          <div className="flex flex-col gap-1">
            <Label htmlFor="break-glass-reference">Reference</Label>
            <Input
              id="break-glass-reference"
              value={reference}
              maxLength={REFERENCE_MAX}
              placeholder="Case or ticket"
              onChange={(e) => setReference(e.target.value)}
            />
          </div>
          <ErrorText error={error} />
          {opened && (
            <p className="text-sm text-apt-green">
              Opened. The grant is live
              {opened.expiresAt ? ` until ${formatDateTime(opened.expiresAt)}` : ""}.
            </p>
          )}
          <div>
            <Button type="submit" variant="destructive" disabled={breakGlass.isPending}>
              Break glass
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
