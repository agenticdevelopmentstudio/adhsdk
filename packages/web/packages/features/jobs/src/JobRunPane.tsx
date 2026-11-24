"use client";

import { useEffect, useMemo, useState, type ReactElement } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  JOBS_KEY,
  isJobRunFinished,
  jobsApi,
  jobsKeys,
  streamJobRun,
  type JobRunDetail,
  type JobStepRun,
  type JobUsage,
} from "@adh-sdk/data/jobs";
import { AlertModal } from "@adh-sdk/ui/components/alert-modal";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";

import { JobsReadError, Loading, StatusBadge, formatTime, refusalText, type JobsOwnerProps } from "./job-ui";

export interface JobRunPaneProps extends JobsOwnerProps {
  runId: string;
}

/** The headline a failed step's error code reads as, where the provider's own message would mislead. */
const STEP_ERROR_HEADLINE: Record<string, string> = {
  model_unavailable: "The model was switched off",
};

/**
 * One run: its status (followed live while it is queued or running), and its step runs in order,
 * each with its name, kind and status, and its output, log and usage when it has them. A failed run
 * offers Retry (the failed step again, earlier outputs kept); a queued or running one offers Cancel,
 * behind a confirmation.
 */
export function JobRunPane({ runId, workspace }: JobRunPaneProps): ReactElement {
  const qc = useQueryClient();
  const scope = { workspace };
  const key = jobsKeys.run(runId, workspace);
  const run = useQuery({ queryKey: key, queryFn: () => jobsApi.getRun(runId, scope) });
  const instanceId = run.data?.instanceId;
  const job = useQuery({
    queryKey: jobsKeys.instance(instanceId ?? "", workspace),
    queryFn: () => jobsApi.get(instanceId as string, scope),
    enabled: instanceId !== undefined,
  });
  const [confirmCancel, setConfirmCancel] = useState(false);

  const live = run.data !== undefined && !isJobRunFinished(run.data.status);

  // While the run is queued or running, follow it. Each state the stream reports updates the run,
  // and the detail is read again for its step runs. The stream closes itself once the run arrives
  // finished; the cleanup closes it when the pane unmounts or the run is no longer live.
  useEffect(() => {
    if (!live) return;
    const stop = streamJobRun(runId, {
      workspace,
      onRun: (next) => {
        qc.setQueryData<JobRunDetail>(key, (prev) => (prev ? { ...prev, ...next } : prev));
        void qc.invalidateQueries({ queryKey: key, exact: true });
      },
    });
    return stop;
    // `key` is derived from runId and workspace.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [live, runId, workspace, qc]);

  const retry = useMutation({
    mutationFn: () => jobsApi.retryRun(runId, scope),
    onSuccess: () => void qc.invalidateQueries({ queryKey: JOBS_KEY }),
  });
  const cancel = useMutation({
    mutationFn: () => jobsApi.cancelRun(runId, scope),
    onSuccess: () => {
      setConfirmCancel(false);
      void qc.invalidateQueries({ queryKey: JOBS_KEY });
    },
  });

  const stepNames = useMemo(() => {
    const out = new Map<string, string>();
    for (const s of job.data?.steps ?? []) out.set(s.id, s.name);
    return out;
  }, [job.data]);

  if (run.error) return <JobsReadError error={run.error} step="read-run" what="this run" />;
  if (run.isPending) return <Loading />;
  const r = run.data;
  const canRetry = r.status === "failed";
  const canCancel = r.status === "queued" || r.status === "running";

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center gap-3">
        <h2 className="text-sm font-medium text-apt-text">{job.data?.name ?? "Run"}</h2>
        <span aria-live="polite" className="flex items-center gap-1 text-sm">
          <span className="sr-only">Run status</span>
          <StatusBadge status={r.status} />
        </span>
        <span className="text-xs text-apt-text-muted">{formatTime(r.startedAt ?? r.createdAt)}</span>
        <div className="ml-auto flex gap-2">
          {canRetry ? (
            <Button type="button" size="sm" disabled={retry.isPending} onClick={() => retry.mutate()}>
              {retry.isPending ? "Retrying…" : "Retry"}
            </Button>
          ) : null}
          {canCancel ? (
            <Button type="button" size="sm" variant="destructive" onClick={() => setConfirmCancel(true)}>
              Cancel
            </Button>
          ) : null}
        </div>
      </div>
      {r.status === "failed" && r.error ? (
        <ErrorText error={STEP_ERROR_HEADLINE[r.errorCode ?? ""] ?? r.error} />
      ) : null}
      {retry.error ? <ErrorText error={refusalText(retry.error)} /> : null}
      <UsageLine usage={r.usage} />

      {r.stepRuns.length === 0 ? (
        <p className="text-sm text-apt-text-muted">No steps have run yet.</p>
      ) : (
        <ol aria-label="Steps" className="flex flex-col gap-2">
          {r.stepRuns.map((s) => (
            <StepRunRow key={s.id} step={s} name={stepNames.get(s.stepId) ?? s.stepId} />
          ))}
        </ol>
      )}

      <AlertModal
        open={confirmCancel}
        tone="error"
        title="Cancel this run?"
        description={
          <>
            The step that is running stops, and the steps after it do not run.
            {cancel.error ? <ErrorText error={refusalText(cancel.error)} /> : null}
          </>
        }
        confirmLabel="Cancel run"
        confirmVariant="destructive"
        cancelLabel="Keep running"
        busy={cancel.isPending}
        onConfirm={() => cancel.mutate()}
        onCancel={() => setConfirmCancel(false)}
      />
    </div>
  );
}

function StepRunRow({ step, name }: { step: JobStepRun; name: string }): ReactElement {
  const headline = step.errorCode ? STEP_ERROR_HEADLINE[step.errorCode] : undefined;
  return (
    <li className="flex flex-col gap-2 rounded-md border border-apt-border p-3" data-step-id={step.stepId}>
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-medium text-apt-text">{name}</span>
        <span className="text-xs text-apt-text-muted">{step.kind}</span>
        <StatusBadge status={step.status} />
        {step.attempts > 1 ? (
          <span className="text-xs text-apt-text-muted">{step.attempts} attempts</span>
        ) : null}
      </div>
      {step.status === "failed" ? (
        headline ? (
          <div className="flex flex-col gap-1">
            <ErrorText error={headline} />
            {step.error ? (
              <details className="text-xs text-apt-text-muted">
                <summary>Provider message</summary>
                {step.error}
              </details>
            ) : null}
          </div>
        ) : step.error ? (
          <ErrorText error={step.error} />
        ) : null
      ) : null}
      <StepOutput output={step.output} />
      {step.log.length > 0 ? (
        <details className="text-xs">
          <summary className="text-apt-text-muted">Log</summary>
          <pre className="mt-1 max-h-64 overflow-auto whitespace-pre-wrap font-mono text-apt-text">
            {step.log.join("\n")}
          </pre>
        </details>
      ) : null}
      <UsageLine usage={step.usage} />
    </li>
  );
}

function isTruncated(v: unknown): v is { truncated: true; json: string } {
  return (
    typeof v === "object" &&
    v !== null &&
    (v as { truncated?: unknown }).truncated === true &&
    typeof (v as { json?: unknown }).json === "string"
  );
}

function StepOutput({ output }: { output: unknown }): ReactElement | null {
  if (output === null || output === undefined) return null;
  const truncated = isTruncated(output);
  const text = truncated
    ? output.json
    : typeof output === "string"
      ? output
      : JSON.stringify(output, null, 2);
  return (
    <div className="flex flex-col gap-1 text-xs">
      <span className="text-apt-text-muted">Output</span>
      <pre className="max-h-64 overflow-auto whitespace-pre-wrap font-mono text-apt-text">{text}</pre>
      {truncated ? <span className="text-apt-text-muted">This output was cut short.</span> : null}
    </div>
  );
}

function UsageLine({ usage }: { usage: JobUsage }): ReactElement | null {
  const total = usage.inputTokens + usage.outputTokens;
  if (total === 0) return null;
  return (
    <span className="text-xs text-apt-text-muted">
      {usage.inputTokens.toLocaleString()} input and {usage.outputTokens.toLocaleString()} output tokens
    </span>
  );
}
