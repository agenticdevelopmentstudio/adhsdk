"use client";

import type { ReactElement } from "react";

// The fields an operator's support grant names, shared by the Support Grants pane's request form
// and the Break Glass pane: whose content (a product's customer or a hub user), the product for a
// customer, the reason and the length. The limits are 0309's (supportRequestProblem); the backend
// answers 422 for anything these let through.

import {
  isStepUpRequired,
  SUPPORT_REASON_MAX,
  supportRequestProblem,
  type OperatorGrantRequest,
} from "@adh-sdk/data/support";
import { Input } from "@adh-sdk/ui/components/input";
import { Label } from "@adh-sdk/ui/components/label";
import { Select } from "@adh-sdk/ui/components/select";
import { Textarea } from "@adh-sdk/ui/components/textarea";

/** 8-4-4-4-12 hex, as the routes check a target and an ecosystem (adhbackend lib/uuid.ts). */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const isUuidText = (v: string): boolean => UUID_RE.test(v.trim());

/** What the form holds while the operator fills it. */
export interface SupportTargetDraft {
  targetKind: "customer" | "account";
  targetId: string;
  ecosystemId: string;
  reason: string;
  hours: string;
}

export const emptySupportTarget = (hours: number): SupportTargetDraft => ({
  targetKind: "customer",
  targetId: "",
  ecosystemId: "",
  reason: "",
  hours: String(hours),
});

/** What is wrong with the draft, as one sentence; null when it can be sent. */
export function supportTargetProblem(d: SupportTargetDraft, maxHours: number): string | null {
  if (!isUuidText(d.targetId)) return "The target id must be a uuid.";
  if (d.targetKind === "customer" && !isUuidText(d.ecosystemId)) {
    return "A customer's grant needs the product's ecosystem id, a uuid.";
  }
  return supportRequestProblem({ reason: d.reason, hours: Number(d.hours) }, maxHours);
}

/** The draft as the request body. A hub user's grant names no product. */
export function toOperatorGrantRequest(d: SupportTargetDraft): OperatorGrantRequest {
  return {
    targetKind: d.targetKind,
    targetId: d.targetId.trim(),
    ecosystemId: d.targetKind === "customer" ? d.ecosystemId.trim() : undefined,
    reason: d.reason.trim(),
    hours: Number(d.hours),
  };
}

/**
 * A refusal, in words. A 403 `step_up_required` is a session without a second factor from a
 * sign-in in the last ten minutes; the operator console has no step-up redirect, so it says what
 * to do. Anything else is the backend's own message.
 */
export function supportRefusalText(err: unknown): string {
  if (isStepUpRequired(err)) {
    return "This needs a second factor from a sign-in in the last ten minutes. Sign out, sign in again with your second factor, then try again.";
  }
  return err instanceof Error && err.message ? err.message : "Something went wrong.";
}

export function SupportTargetFields({
  idPrefix,
  draft,
  onChange,
  maxHours,
}: {
  idPrefix: string;
  draft: SupportTargetDraft;
  onChange: (next: SupportTargetDraft) => void;
  maxHours: number;
}): ReactElement {
  const set = (patch: Partial<SupportTargetDraft>) => onChange({ ...draft, ...patch });
  return (
    <>
      <div className="flex flex-col gap-1">
        <Label htmlFor={`${idPrefix}-kind`}>Whose content</Label>
        <Select
          id={`${idPrefix}-kind`}
          value={draft.targetKind}
          onChange={(e) => set({ targetKind: e.target.value as SupportTargetDraft["targetKind"] })}
        >
          <option value="customer">A product&apos;s customer</option>
          <option value="account">A hub user</option>
        </Select>
      </div>
      <div className="flex flex-col gap-1">
        <Label htmlFor={`${idPrefix}-target`}>Target id</Label>
        <Input
          id={`${idPrefix}-target`}
          value={draft.targetId}
          placeholder="uuid"
          onChange={(e) => set({ targetId: e.target.value })}
        />
      </div>
      {draft.targetKind === "customer" && (
        <div className="flex flex-col gap-1">
          <Label htmlFor={`${idPrefix}-ecosystem`}>Product (ecosystem id)</Label>
          <Input
            id={`${idPrefix}-ecosystem`}
            value={draft.ecosystemId}
            placeholder="uuid"
            onChange={(e) => set({ ecosystemId: e.target.value })}
          />
        </div>
      )}
      <div className="flex flex-col gap-1">
        <Label htmlFor={`${idPrefix}-reason`}>Reason</Label>
        <Textarea
          id={`${idPrefix}-reason`}
          value={draft.reason}
          maxLength={SUPPORT_REASON_MAX}
          placeholder="What you need to see, and why. The person reads this."
          onChange={(e) => set({ reason: e.target.value })}
        />
      </div>
      <div className="flex flex-col gap-1">
        <Label htmlFor={`${idPrefix}-hours`}>Hours</Label>
        <Input
          id={`${idPrefix}-hours`}
          type="number"
          min={1}
          max={maxHours}
          step={1}
          value={draft.hours}
          onChange={(e) => set({ hours: e.target.value })}
        />
        <span className="text-xs text-apt-text-muted">From 1 to {maxHours} hours.</span>
      </div>
    </>
  );
}
