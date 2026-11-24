"use client";

import { useMemo, useState, type FormEvent, type ReactElement } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  JOBS_KEY,
  jobsApi,
  jobsKeys,
  type JobCatalogTemplate,
  type JobInputValues,
  type JobInstance,
  type JobRunStatus,
} from "@adh-sdk/data/jobs";
import { Field } from "@adh-sdk/ui/blocks/field";
import { Button } from "@adh-sdk/ui/components/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@adh-sdk/ui/components/dialog";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";

import { JobInputsForm, requiredInputsFilled } from "./JobInputsForm";
import {
  JobsReadError,
  Loading,
  StatusBadge,
  isJobsOff,
  refusalText,
  type JobsOpen,
  type JobsOwnerProps,
} from "./job-ui";

export interface JobsPaneProps extends JobsOwnerProps {
  /** `customer`: a product's customer, who creates jobs from the catalog only. `account`: a hub
   *  user or an organization member in a workspace. */
  side: "customer" | "account";
  /** Open a job (the created one, or a row of the list). */
  onOpenJob?: JobsOpen;
  /** The account side's way to template authoring; never shown on the customer side. */
  onOpenTemplates?: () => void;
}

/** How many recent runs are read to show each job's last run. */
const RECENT_RUNS = 200;

/**
 * The owner's jobs, each with its template (or "Custom"), status and last run, and the catalog of
 * templates offered to the owner at their latest versions. A job is created from a catalog entry in
 * a modal that asks for its name and the template's declared inputs, then opened.
 */
export function JobsPane({ side, workspace, onOpenJob, onOpenTemplates }: JobsPaneProps): ReactElement {
  const scope = { workspace };
  const jobs = useQuery({
    queryKey: jobsKeys.instances(workspace),
    queryFn: () => jobsApi.list(scope),
  });
  const catalog = useQuery({
    queryKey: jobsKeys.catalog(workspace),
    queryFn: () => jobsApi.catalog(scope),
  });
  const runs = useQuery({
    queryKey: jobsKeys.runs({ limit: RECENT_RUNS }, workspace),
    queryFn: () => jobsApi.runs({ limit: RECENT_RUNS }, scope),
    enabled: (jobs.data?.length ?? 0) > 0,
  });
  const [creating, setCreating] = useState<JobCatalogTemplate | null>(null);

  // The runs come newest first, so the first one per job is its last.
  const lastRun = useMemo(() => {
    const out = new Map<string, JobRunStatus>();
    for (const r of runs.data?.runs ?? []) if (!out.has(r.instanceId)) out.set(r.instanceId, r.status);
    return out;
  }, [runs.data]);

  const templateName = useMemo(() => {
    const out = new Map<string, string>();
    for (const t of catalog.data ?? []) out.set(t.id, t.name);
    return out;
  }, [catalog.data]);

  if (isJobsOff(jobs.error) || isJobsOff(catalog.error)) {
    return <JobsReadError error={jobs.error ?? catalog.error} step="list-jobs" what="jobs" />;
  }

  return (
    <div className="flex flex-col gap-6">
      <section aria-label="Your jobs" className="flex flex-col gap-2">
        <div className="flex items-center justify-between gap-2">
          <h2 className="text-sm font-medium text-apt-text">Jobs</h2>
          {side === "account" && onOpenTemplates ? (
            <Button type="button" size="sm" variant="ghost" onClick={onOpenTemplates}>
              Templates
            </Button>
          ) : null}
        </div>
        {jobs.error ? (
          <JobsReadError error={jobs.error} step="list-jobs" what="jobs" />
        ) : jobs.isPending ? (
          <Loading />
        ) : jobs.data.length === 0 ? (
          <p className="text-sm text-apt-text-muted">No jobs yet. Start one from a template below.</p>
        ) : (
          <ul className="flex flex-col divide-y divide-apt-border rounded-md border border-apt-border">
            {jobs.data.map((job) => (
              <JobRow
                key={job.id}
                job={job}
                template={job.templateId ? (templateName.get(job.templateId) ?? "Template") : "Custom"}
                lastRun={lastRun.get(job.id)}
                onOpen={onOpenJob}
              />
            ))}
          </ul>
        )}
      </section>

      <section aria-label="Templates you can use" className="flex flex-col gap-2">
        <h2 className="text-sm font-medium text-apt-text">Start a job</h2>
        {catalog.error ? (
          <JobsReadError error={catalog.error} step="list-catalog" what="the templates" />
        ) : catalog.isPending ? (
          <Loading />
        ) : catalog.data.length === 0 ? (
          <p className="text-sm text-apt-text-muted">No templates are offered to you.</p>
        ) : (
          <ul className="flex flex-col gap-2">
            {catalog.data.map((t) => (
              <li
                key={t.id}
                className="flex items-start justify-between gap-3 rounded-md border border-apt-border p-3"
              >
                <div className="flex min-w-0 flex-col gap-0.5">
                  <span className="font-medium text-apt-text">{t.name}</span>
                  {t.description ? (
                    <span className="text-sm text-apt-text-muted">{t.description}</span>
                  ) : null}
                  <span className="text-xs text-apt-text-muted">Version {t.version}</span>
                </div>
                <Button
                  type="button"
                  size="sm"
                  aria-label={`Create a job from ${t.name}`}
                  onClick={() => setCreating(t)}
                >
                  Create job
                </Button>
              </li>
            ))}
          </ul>
        )}
      </section>

      <CreateJobDialog
        template={creating}
        workspace={workspace}
        onClose={() => setCreating(null)}
        onCreated={(job) => {
          setCreating(null);
          onOpenJob?.(job.id);
        }}
      />
    </div>
  );
}

function JobRow({
  job,
  template,
  lastRun,
  onOpen,
}: {
  job: JobInstance;
  template: string;
  lastRun: JobRunStatus | undefined;
  onOpen?: JobsOpen;
}): ReactElement {
  const body = (
    <>
      <span className="min-w-0 flex-1 truncate font-medium text-apt-text">{job.name}</span>
      <span className="w-40 truncate text-sm text-apt-text-muted">{template}</span>
      <StatusBadge status={job.status} />
      <span className="w-28 text-right text-sm">
        {lastRun ? (
          <span>
            <span className="sr-only">Last run </span>
            <StatusBadge status={lastRun} />
          </span>
        ) : (
          <span className="text-apt-text-muted">No runs</span>
        )}
      </span>
    </>
  );
  return (
    <li>
      {onOpen ? (
        <button
          type="button"
          className="flex w-full items-center gap-3 px-3 py-2 text-left hover:bg-apt-surface-2"
          onClick={() => onOpen(job.id)}
        >
          {body}
        </button>
      ) : (
        <div className="flex items-center gap-3 px-3 py-2">{body}</div>
      )}
    </li>
  );
}

function CreateJobDialog({
  template,
  workspace,
  onClose,
  onCreated,
}: {
  template: JobCatalogTemplate | null;
  workspace?: string;
  onClose: () => void;
  onCreated: (job: JobInstance) => void;
}): ReactElement {
  const qc = useQueryClient();
  const [name, setName] = useState("");
  const [inputs, setInputs] = useState<JobInputValues>({});
  const [forId, setForId] = useState<string | null>(null);

  // A different template opens a fresh form.
  if (template && template.id !== forId) {
    setForId(template.id);
    setName(template.name);
    setInputs({});
  }

  const create = useMutation({
    mutationFn: (t: JobCatalogTemplate) =>
      jobsApi.create(
        { name: name.trim(), templateId: t.id, templateVersion: t.version, inputs },
        { workspace },
      ),
    onSuccess: (job) => {
      void qc.invalidateQueries({ queryKey: JOBS_KEY });
      create.reset();
      setForId(null);
      onCreated(job);
    },
  });

  const canCreate =
    template !== null &&
    name.trim() !== "" &&
    requiredInputsFilled(template.inputs, inputs) &&
    !create.isPending;

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (template && canCreate) create.mutate(template);
  };

  const close = () => {
    if (create.isPending) return;
    create.reset();
    setForId(null);
    onClose();
  };

  return (
    <Dialog open={template !== null} onOpenChange={(open) => !open && close()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>New job</DialogTitle>
          <DialogDescription>
            {template ? `From ${template.name}, version ${template.version}.` : null}
          </DialogDescription>
        </DialogHeader>
        <form className="flex flex-col gap-4" onSubmit={submit}>
          <Field label="Name">
            <Input
              aria-label="Name"
              value={name}
              maxLength={200}
              disabled={create.isPending}
              onChange={(e) => setName(e.target.value)}
            />
          </Field>
          {template ? (
            <JobInputsForm
              specs={template.inputs}
              values={inputs}
              onChange={setInputs}
              disabled={create.isPending}
            />
          ) : null}
          {create.error ? <ErrorText error={refusalText(create.error)} /> : null}
          <DialogFooter>
            <Button type="button" variant="ghost" size="sm" disabled={create.isPending} onClick={close}>
              Cancel
            </Button>
            <Button type="submit" size="sm" disabled={!canCreate}>
              {create.isPending ? "Creating…" : "Create job"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
