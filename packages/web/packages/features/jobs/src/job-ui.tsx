"use client";

// The pieces every Jobs pane shares: the switch-off read of a 404, a failed read shown and
// reported once, the status labels and badges, and the step placement refusals.

import { useEffect, type ReactElement } from "react";

import { reportUnexpectedAuthError } from "@adh-sdk/auth";
import { httpStatus } from "@adh-sdk/data";
import {
  jobsErrorCode,
  jobsErrorDetails,
  type JobInstanceStatus,
  type JobRunStatus,
  type JobStepRunStatus,
  type JobTemplateStatus,
} from "@adh-sdk/data/jobs";
import { Badge } from "@adh-sdk/ui/components/badge";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { errorMessage } from "@adh-sdk/ui/lib/errors";

/** A pane's `onOpen…` callback: the host navigates to the record. */
export type JobsOpen = (id: string) => void;

/** The owner of the jobs a hub pane shows: the caller, or an organization by its workspace slug. */
export interface JobsOwnerProps {
  /** An organization workspace's slug; omitted for the caller's own jobs. */
  workspace?: string;
}

/**
 * True for the 404 every `/jobs` route answers while the `jobs_feature` switch is off. That one
 * carries the generic `not_found` code; a missing record names itself (`job_not_found`,
 * `template_not_found`), so it is not read as the feature being off.
 */
export function isJobsOff(err: unknown): boolean {
  if (httpStatus(err) !== 404) return false;
  const code = jobsErrorCode(err);
  return code === undefined || code === "not_found";
}

export function JobsUnavailable(): ReactElement {
  return <p className="text-sm text-apt-text-muted">Jobs is not available.</p>;
}

/**
 * A read that failed: shown, and reported once with the feature `jobs` and the step that failed.
 * The switch-off 404 reads as the feature being unavailable and is not reported.
 */
export function JobsReadError({
  error,
  step,
  what,
}: {
  error: unknown;
  /** The read that failed, as the report's step (`list-jobs`, `read-run`). */
  step: string;
  /** What could not be loaded, for the message ("jobs", "this run"). */
  what: string;
}): ReactElement {
  const off = isJobsOff(error);
  useEffect(() => {
    if (!off) reportUnexpectedAuthError(error, { feature: "jobs", step });
  }, [error, off, step]);
  if (off) return <JobsUnavailable />;
  return <ErrorText error={`Couldn't load ${what}: ${errorMessage(error)}`} />;
}

export function Loading(): ReactElement {
  return <p className="text-sm text-apt-text-muted">Loading…</p>;
}

type BadgeVariant = "neutral" | "accent" | "orange" | "blue" | "success" | "error";

const STATUS_VARIANT: Record<string, BadgeVariant> = {
  queued: "neutral",
  pending: "neutral",
  running: "blue",
  succeeded: "success",
  failed: "error",
  cancelled: "neutral",
  skipped: "neutral",
  active: "success",
  paused: "orange",
  archived: "neutral",
  draft: "orange",
  published: "success",
  retired: "neutral",
};

/** A status as text (never colour alone), in a badge tinted by its kind. */
export function StatusBadge({
  status,
}: {
  status: JobRunStatus | JobStepRunStatus | JobInstanceStatus | JobTemplateStatus;
}): ReactElement {
  return <Badge variant={STATUS_VARIANT[status] ?? "neutral"}>{status}</Badge>;
}

export function formatTime(iso: string | null): string {
  if (!iso) return "";
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? iso : d.toLocaleString();
}

/** One step a save was refused for: which step, and what it needs. */
export interface StepPlacementProblem {
  stepId: string;
  code: string;
  message: string;
}

const NEEDS: Record<string, string> = {
  step_needs_hub: "needs the hub (it uses a provider connection)",
  step_needs_machine: "needs a machine",
  script_not_allowed: "is a script, which this job may not run",
  persona_not_allowed: "names a persona this job may not use",
};

/**
 * A save refused with a step rule (`step_needs_hub`, `step_needs_machine`, ...): one line per step
 * the backend named, read from the refusal's details. Null for any other failure.
 */
export function stepPlacementProblems(err: unknown): StepPlacementProblem[] | null {
  const code = jobsErrorCode(err);
  if (!code || !(code in NEEDS)) return null;
  const details = jobsErrorDetails(err);
  const rows = Array.isArray(details) ? details : [];
  const out = rows
    .map((d) => d as { stepId?: unknown; code?: unknown; message?: unknown })
    .filter((d) => typeof d.stepId === "string")
    .map((d) => ({
      stepId: d.stepId as string,
      code: typeof d.code === "string" ? d.code : code,
      message: typeof d.message === "string" ? d.message : "",
    }));
  return out.length > 0 ? out : [{ stepId: "", code, message: errorMessage(err) }];
}

export function describeStepProblem(p: StepPlacementProblem): string {
  const needs = NEEDS[p.code] ?? p.message;
  return p.stepId ? `Step "${p.stepId}" ${needs}.` : `A step ${needs}.`;
}

/** A refused write's message: a step rule names its steps; anything else shows the backend's. */
export function refusalText(err: unknown): string {
  const steps = stepPlacementProblems(err);
  if (steps) return steps.map(describeStepProblem).join(" ");
  if (isJobsOff(err)) return "Jobs is not available.";
  return errorMessage(err) || "Something went wrong.";
}
