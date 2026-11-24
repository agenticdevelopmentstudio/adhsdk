"use client";

import { useState, type FormEvent, type ReactElement } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  JOBS_KEY,
  jobsApi,
  jobsErrorCode,
  jobsKeys,
  type JobInputValues,
  type JobInstance,
  type JobInstancePatch,
  type JobTrigger,
  type JobTriggerCreate,
} from "@adh-sdk/data/jobs";
import { Field } from "@adh-sdk/ui/blocks/field";
import { OnceShownSecretDialog } from "@adh-sdk/ui/blocks/once-shown-secret-dialog";
import { AlertModal } from "@adh-sdk/ui/components/alert-modal";
import { Button } from "@adh-sdk/ui/components/button";
import { Checkbox } from "@adh-sdk/ui/components/checkbox";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { Select } from "@adh-sdk/ui/components/select";

import { JobInputsForm } from "./JobInputsForm";
import {
  JobsReadError,
  Loading,
  StatusBadge,
  formatTime,
  refusalText,
  type JobsOpen,
  type JobsOwnerProps,
} from "./job-ui";

export interface JobPaneProps extends JobsOwnerProps {
  jobId: string;
  /** Open a run (one of the list, or the one "Run now" started). */
  onOpenRun?: JobsOpen;
  /** Called once the job is archived, so the host can leave the pane. */
  onDeleted?: () => void;
}

const NOTIFY_ON = ["failed", "succeeded"] as const;
const NOTIFY_CHANNELS = [
  { id: "email", label: "Email" },
  { id: "sms", label: "SMS" },
  { id: "hub", label: "Hub" },
] as const;

/** A job's notifications when it names none: failures, by email. */
const DEFAULT_NOTIFY = { on: ["failed" as const], channels: ["email" as const] };

/**
 * One job: its inputs (exactly the ones its template version declares) or its inline steps, the
 * environment it runs in, its triggers, its notifications and its runs, with Run now, Pause or
 * Resume, and Delete (which archives it and keeps its runs).
 */
export function JobPane({ jobId, workspace, onOpenRun, onDeleted }: JobPaneProps): ReactElement {
  const qc = useQueryClient();
  const scope = { workspace };
  const job = useQuery({
    queryKey: jobsKeys.instance(jobId, workspace),
    queryFn: () => jobsApi.get(jobId, scope),
  });
  const [confirmDelete, setConfirmDelete] = useState(false);

  const invalidate = () => void qc.invalidateQueries({ queryKey: JOBS_KEY });
  const runNow = useMutation({
    mutationFn: () => jobsApi.run(jobId, scope),
    onSuccess: (started) => {
      invalidate();
      onOpenRun?.(started.runId);
    },
  });
  const setStatus = useMutation({
    mutationFn: (status: "active" | "paused") => jobsApi.update(jobId, { status }, scope),
    onSuccess: invalidate,
  });
  const remove = useMutation({
    mutationFn: () => jobsApi.remove(jobId, scope),
    onSuccess: () => {
      setConfirmDelete(false);
      invalidate();
      onDeleted?.();
    },
  });

  if (job.error) return <JobsReadError error={job.error} step="read-job" what="this job" />;
  if (job.isPending) return <Loading />;
  const j = job.data;
  const archived = j.status === "archived";

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center gap-3">
        <h2 className="text-sm font-medium text-apt-text">{j.name}</h2>
        <StatusBadge status={j.status} />
        {archived ? null : (
          <div className="ml-auto flex gap-2">
            <Button type="button" size="sm" disabled={runNow.isPending} onClick={() => runNow.mutate()}>
              {runNow.isPending ? "Starting…" : "Run now"}
            </Button>
            <Button
              type="button"
              size="sm"
              variant="outline"
              disabled={setStatus.isPending}
              onClick={() => setStatus.mutate(j.status === "paused" ? "active" : "paused")}
            >
              {j.status === "paused" ? "Resume" : "Pause"}
            </Button>
            <Button type="button" size="sm" variant="destructive" onClick={() => setConfirmDelete(true)}>
              Delete
            </Button>
          </div>
        )}
      </div>
      {runNow.error ? <ErrorText error={refusalText(runNow.error)} /> : null}
      {setStatus.error ? <ErrorText error={refusalText(setStatus.error)} /> : null}

      <JobSettings job={j} workspace={workspace} disabled={archived} />
      <TriggersSection jobId={jobId} workspace={workspace} disabled={archived} />
      <RunsSection jobId={jobId} workspace={workspace} onOpenRun={onOpenRun} />

      <AlertModal
        open={confirmDelete}
        tone="error"
        title="Delete this job?"
        description={
          <>
            The job is archived and stops running. Its runs are kept.
            {remove.error ? <ErrorText error={refusalText(remove.error)} /> : null}
          </>
        }
        confirmLabel="Delete job"
        confirmVariant="destructive"
        busy={remove.isPending}
        onConfirm={() => remove.mutate()}
        onCancel={() => setConfirmDelete(false)}
      />
    </div>
  );
}

/** Inputs (or inline steps), the environment and the notifications, saved together. */
function JobSettings({
  job,
  workspace,
  disabled,
}: {
  job: JobInstance;
  workspace?: string;
  disabled: boolean;
}): ReactElement {
  const qc = useQueryClient();
  const scope = { workspace };
  const catalog = useQuery({
    queryKey: jobsKeys.catalog(workspace),
    queryFn: () => jobsApi.catalog(scope),
    enabled: job.templateId !== null,
  });
  const environments = useQuery({
    queryKey: jobsKeys.environments(workspace),
    queryFn: () => jobsApi.environments(scope),
  });
  const [inputs, setInputs] = useState<JobInputValues>(job.inputs);
  const [environmentId, setEnvironmentId] = useState<string | null>(job.environmentId);
  const [notify, setNotify] = useState(() => ({
    on: job.options.notify?.on ?? DEFAULT_NOTIFY.on,
    channels: job.options.notify?.channels ?? DEFAULT_NOTIFY.channels,
  }));

  // The inputs and defaults a template job has are its own version's. The catalog holds only each
  // template's latest offered version, so it speaks for this job only when that is the job's version.
  const template = catalog.data?.find((t) => t.id === job.templateId);
  const pinned = template && template.version === job.templateVersion ? template : undefined;
  const inputsLocked = job.templateId !== null && !pinned;

  const save = useMutation({
    mutationFn: () => {
      const patch: JobInstancePatch = { environmentId, options: { ...job.options, notify } };
      if (!inputsLocked) patch.inputs = inputs;
      return jobsApi.update(job.id, patch, scope);
    },
    onSuccess: () => void qc.invalidateQueries({ queryKey: JOBS_KEY }),
  });

  const submit = (e: FormEvent) => {
    e.preventDefault();
    save.mutate();
  };

  const toggle = <T extends string>(list: readonly T[], value: T, on: boolean): T[] =>
    on ? [...new Set([...list, value])] : list.filter((v) => v !== value);

  return (
    <form className="flex flex-col gap-4" aria-label="Job settings" onSubmit={submit}>
      <section aria-label="Inputs" className="flex flex-col gap-2">
        <h3 className="text-sm font-medium text-apt-text">Inputs</h3>
        {job.steps ? (
          <InlineSteps job={job} />
        ) : catalog.error ? (
          <JobsReadError error={catalog.error} step="list-catalog" what="the template's inputs" />
        ) : catalog.isPending ? (
          <Loading />
        ) : inputsLocked ? (
          <PinnedInputs job={job} offered={template?.version} />
        ) : pinned && pinned.inputs.length > 0 ? (
          <JobInputsForm specs={pinned.inputs} values={inputs} onChange={setInputs} disabled={disabled} />
        ) : (
          <p className="text-sm text-apt-text-muted">This job takes no inputs.</p>
        )}
      </section>

      <section aria-label="Environment" className="flex flex-col gap-2">
        <h3 className="text-sm font-medium text-apt-text">Environment</h3>
        {environments.error ? (
          <JobsReadError error={environments.error} step="list-environments" what="your environments" />
        ) : (
          <Field label="Runs on">
            <Select
              aria-label="Runs on"
              value={environmentId ?? ""}
              disabled={disabled}
              onChange={(e) => setEnvironmentId(e.target.value || null)}
            >
              <option value="">Hub</option>
              {(environments.data ?? []).map((env) => (
                <option key={env.id} value={env.id}>
                  {env.name}
                </option>
              ))}
            </Select>
          </Field>
        )}
      </section>

      <section aria-label="Notifications" className="flex flex-col gap-2">
        <h3 className="text-sm font-medium text-apt-text">Notifications</h3>
        <div className="flex flex-wrap gap-4">
          {NOTIFY_ON.map((on) => (
            <label key={on} className="flex items-center gap-2 text-sm text-apt-text">
              <Checkbox
                aria-label={`Notify when a run ${on}`}
                checked={notify.on.includes(on)}
                disabled={disabled}
                onCheckedChange={(c) => setNotify((n) => ({ ...n, on: toggle(n.on, on, c === true) }))}
              />
              When a run {on}
            </label>
          ))}
        </div>
        <div className="flex flex-wrap gap-4">
          {NOTIFY_CHANNELS.map((ch) => (
            <label key={ch.id} className="flex items-center gap-2 text-sm text-apt-text">
              <Checkbox
                aria-label={`Notify by ${ch.label}`}
                checked={notify.channels.includes(ch.id)}
                disabled={disabled}
                onCheckedChange={(c) =>
                  setNotify((n) => ({ ...n, channels: toggle(n.channels, ch.id, c === true) }))
                }
              />
              {ch.label}
            </label>
          ))}
        </div>
      </section>

      {save.error ? <ErrorText error={refusalText(save.error)} /> : null}
      {disabled ? null : (
        <div>
          <Button type="submit" size="sm" disabled={save.isPending}>
            {save.isPending ? "Saving…" : "Save"}
          </Button>
        </div>
      )}
    </form>
  );
}

/**
 * A template job whose version the catalog no longer offers (the template moved on, was retired or
 * left the job's sets). The latest version's inputs are not this job's, so its saved values are
 * shown, not edited.
 */
function PinnedInputs({ job, offered }: { job: JobInstance; offered?: number }): ReactElement {
  const entries = Object.entries(job.inputs);
  return (
    <div className="flex flex-col gap-2">
      <p className="text-sm text-apt-text-muted">
        {offered === undefined
          ? `This job runs version ${job.templateVersion ?? "?"} of a template that is no longer offered, so its inputs can't be edited here.`
          : `This job runs version ${job.templateVersion ?? "?"} of its template, and version ${offered} is the one offered now, so its inputs can't be edited here.`}
      </p>
      {entries.length > 0 ? (
        <dl className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-sm">
          {entries.map(([k, v]) => (
            <div key={k} className="contents">
              <dt className="font-mono text-xs text-apt-text-muted">{k}</dt>
              <dd className="text-apt-text">{typeof v === "string" ? v : JSON.stringify(v)}</dd>
            </div>
          ))}
        </dl>
      ) : null}
    </div>
  );
}

/** A developer job's inline steps. The job routes take no step edits, so they are shown, not edited. */
function InlineSteps({ job }: { job: JobInstance }): ReactElement {
  return (
    <ol className="flex flex-col gap-1 text-sm">
      {(job.steps ?? []).map((s) => (
        <li key={s.id} className="flex gap-2">
          <span className="font-medium text-apt-text">{s.name}</span>
          <span className="text-apt-text-muted">{s.kind}</span>
        </li>
      ))}
    </ol>
  );
}

function defaultTimeZone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
  } catch {
    return "UTC";
  }
}

function TriggersSection({
  jobId,
  workspace,
  disabled,
}: {
  jobId: string;
  workspace?: string;
  disabled: boolean;
}): ReactElement {
  const qc = useQueryClient();
  const scope = { workspace };
  const triggers = useQuery({
    queryKey: jobsKeys.triggers(jobId, workspace),
    queryFn: () => jobsApi.triggers(jobId, scope),
  });
  const [kind, setKind] = useState<JobTriggerCreate["kind"]>("schedule");
  const [cron, setCron] = useState("0 9 * * *");
  const [timeZone, setTimeZone] = useState(defaultTimeZone);
  const [eventTypes, setEventTypes] = useState("");
  const [secret, setSecret] = useState<string | null>(null);

  const invalidate = () => void qc.invalidateQueries({ queryKey: jobsKeys.triggers(jobId, workspace) });
  const create = useMutation({
    mutationFn: (input: JobTriggerCreate) => jobsApi.createTrigger(jobId, input, scope),
    onSuccess: (created) => {
      invalidate();
      // The secret is held only until its reveal closes; the trigger list never carries it.
      if (created.secret) setSecret(created.secret);
    },
  });
  const update = useMutation({
    mutationFn: ({ id, enabled }: { id: string; enabled: boolean }) =>
      jobsApi.updateTrigger(jobId, id, { enabled }, scope),
    onSuccess: invalidate,
  });
  const remove = useMutation({
    mutationFn: (id: string) => jobsApi.deleteTrigger(jobId, id, scope),
    onSuccess: invalidate,
  });

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (kind === "schedule") create.mutate({ kind, cron: cron.trim(), timeZone: timeZone.trim() });
    else if (kind === "event") {
      const types = eventTypes
        .split(",")
        .map((t) => t.trim())
        .filter(Boolean);
      create.mutate({ kind, eventTypes: types });
    } else create.mutate({ kind });
  };

  const createCode = create.error ? jobsErrorCode(create.error) : undefined;
  const scheduleError =
    createCode === "interval_too_short" || createCode === "cron_invalid" || createCode === "limit_interval"
      ? refusalText(create.error)
      : undefined;

  return (
    <section aria-label="Triggers" className="flex flex-col gap-2">
      <h3 className="text-sm font-medium text-apt-text">Triggers</h3>
      {triggers.error ? (
        <JobsReadError error={triggers.error} step="list-triggers" what="the triggers" />
      ) : triggers.isPending ? (
        <Loading />
      ) : triggers.data.length === 0 ? (
        <p className="text-sm text-apt-text-muted">No triggers. The job runs only when you run it.</p>
      ) : (
        <ul className="flex flex-col divide-y divide-apt-border rounded-md border border-apt-border">
          {triggers.data.map((t) => (
            <TriggerRow
              key={t.id}
              trigger={t}
              disabled={disabled || update.isPending || remove.isPending}
              onEnabled={(enabled) => update.mutate({ id: t.id, enabled })}
              onDelete={() => remove.mutate(t.id)}
            />
          ))}
        </ul>
      )}
      {update.error ? <ErrorText error={refusalText(update.error)} /> : null}
      {remove.error ? <ErrorText error={refusalText(remove.error)} /> : null}

      {disabled ? null : (
        <form className="flex flex-col gap-3" aria-label="Add a trigger" onSubmit={submit}>
          <Field label="Kind">
            <Select
              aria-label="Trigger kind"
              value={kind}
              onChange={(e) => {
                create.reset();
                setKind(e.target.value as JobTriggerCreate["kind"]);
              }}
            >
              <option value="schedule">Schedule</option>
              <option value="event">Event</option>
              <option value="inbound">Inbound webhook</option>
            </Select>
          </Field>
          {kind === "schedule" ? (
            <>
              <Field label="Cron" error={scheduleError}>
                <Input aria-label="Cron" value={cron} onChange={(e) => setCron(e.target.value)} />
              </Field>
              <Field label="Time zone">
                <Input aria-label="Time zone" value={timeZone} onChange={(e) => setTimeZone(e.target.value)} />
              </Field>
            </>
          ) : kind === "event" ? (
            <Field label="Event types" hint="Comma separated, such as integration.github.push.">
              <Input
                aria-label="Event types"
                value={eventTypes}
                onChange={(e) => setEventTypes(e.target.value)}
              />
            </Field>
          ) : null}
          {create.error && !scheduleError ? <ErrorText error={refusalText(create.error)} /> : null}
          <div>
            <Button type="submit" size="sm" disabled={create.isPending}>
              {create.isPending ? "Adding…" : "Add trigger"}
            </Button>
          </div>
        </form>
      )}

      {secret ? (
        <OnceShownSecretDialog
          secret={secret}
          title="Inbound trigger secret"
          description="Send it as the X-ADH-Trigger-Secret header. It is shown only now."
          label="Trigger secret"
          onClose={() => {
            // The mutation keeps its result as `data`; resetting it drops the last copy of the secret.
            setSecret(null);
            create.reset();
          }}
        />
      ) : null}
    </section>
  );
}

function TriggerRow({
  trigger,
  disabled,
  onEnabled,
  onDelete,
}: {
  trigger: JobTrigger;
  disabled: boolean;
  onEnabled: (enabled: boolean) => void;
  onDelete: () => void;
}): ReactElement {
  const detail =
    trigger.kind === "schedule"
      ? `${trigger.cron ?? ""} (${trigger.timeZone ?? "UTC"})`
      : trigger.kind === "event"
        ? trigger.eventTypes.join(", ")
        : "Inbound webhook";
  return (
    <li className="flex flex-wrap items-center gap-3 px-3 py-2" data-trigger-id={trigger.id}>
      <span className="w-20 text-sm font-medium text-apt-text">{trigger.kind}</span>
      <span className="min-w-0 flex-1 truncate font-mono text-xs text-apt-text-muted">{detail}</span>
      <label className="flex items-center gap-2 text-sm text-apt-text">
        <Checkbox
          aria-label={`Enabled: ${trigger.kind} trigger`}
          checked={trigger.enabled}
          disabled={disabled}
          onCheckedChange={(c) => onEnabled(c === true)}
        />
        {trigger.enabled ? "Enabled" : "Disabled"}
      </label>
      <Button type="button" size="sm" variant="ghost" disabled={disabled} onClick={onDelete}>
        Remove
      </Button>
    </li>
  );
}

function RunsSection({
  jobId,
  workspace,
  onOpenRun,
}: {
  jobId: string;
  workspace?: string;
  onOpenRun?: JobsOpen;
}): ReactElement {
  const [before, setBefore] = useState<string | undefined>(undefined);
  const [older, setOlder] = useState<Awaited<ReturnType<typeof jobsApi.runs>>["runs"]>([]);
  const query = { instanceId: jobId, before };
  const runs = useQuery({
    queryKey: jobsKeys.runs(query, workspace),
    queryFn: () => jobsApi.runs(query, { workspace }),
  });

  const rows = before ? [...older, ...(runs.data?.runs ?? [])] : (runs.data?.runs ?? []);

  return (
    <section aria-label="Runs" className="flex flex-col gap-2">
      <h3 className="text-sm font-medium text-apt-text">Runs</h3>
      {runs.error ? (
        <JobsReadError error={runs.error} step="list-runs" what="the runs" />
      ) : runs.isPending && rows.length === 0 ? (
        <Loading />
      ) : rows.length === 0 ? (
        <p className="text-sm text-apt-text-muted">No runs yet.</p>
      ) : (
        <ul className="flex flex-col divide-y divide-apt-border rounded-md border border-apt-border">
          {rows.map((r) => {
            const body = (
              <>
                <StatusBadge status={r.status} />
                <span className="flex-1 text-sm text-apt-text">{formatTime(r.startedAt ?? r.createdAt)}</span>
                {r.errorCode ? <span className="text-xs text-apt-text-muted">{r.errorCode}</span> : null}
              </>
            );
            return (
              <li key={r.id}>
                {onOpenRun ? (
                  <button
                    type="button"
                    className="flex w-full items-center gap-3 px-3 py-2 text-left hover:bg-apt-surface-2"
                    onClick={() => onOpenRun(r.id)}
                  >
                    {body}
                  </button>
                ) : (
                  <div className="flex items-center gap-3 px-3 py-2">{body}</div>
                )}
              </li>
            );
          })}
        </ul>
      )}
      {runs.data?.nextBefore ? (
        <div>
          <Button
            type="button"
            size="sm"
            variant="ghost"
            onClick={() => {
              setOlder(rows);
              setBefore(runs.data?.nextBefore ?? undefined);
            }}
          >
            Load more
          </Button>
        </div>
      ) : null}
    </section>
  );
}
