"use client";

import { useState, type ReactElement } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { setsApi } from "@adh-sdk/data/sets";
import {
  JOBS_KEY,
  jobTemplatesApi,
  jobsDraftProblems,
  jobsErrorCode,
  jobsKeys,
  type JobDraftIssue,
  type JobInputSpec,
  type JobStep,
  type JobTemplate,
} from "@adh-sdk/data/jobs";
import { Field } from "@adh-sdk/ui/blocks/field";
import { AlertModal } from "@adh-sdk/ui/components/alert-modal";
import { Button } from "@adh-sdk/ui/components/button";
import { Checkbox } from "@adh-sdk/ui/components/checkbox";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";
import { Textarea } from "@adh-sdk/ui/components/textarea";

import { AddStepPicker, JobInputSpecsEditor, JobStepEditor } from "./JobStepEditor";
import { JobsReadError, Loading, StatusBadge, refusalText } from "./job-ui";

export interface JobTemplatePaneProps {
  ecosystemId: string;
  templateId: string;
}

/** Each step's issues by its index in the draft, from the issue paths (`[index, ...field]`). */
function issuesByStep(issues: readonly JobDraftIssue[]): Map<number, string[]> {
  const out = new Map<number, string[]>();
  for (const i of issues) {
    const [head, ...rest] = i.path;
    const index = typeof head === "number" ? head : Number(head);
    if (!Number.isInteger(index)) continue;
    const field = rest.length > 0 ? `${rest.join(".")}: ` : "";
    out.set(index, [...(out.get(index) ?? []), `${field}${i.message}`]);
  }
  return out;
}

const issueText = (issues: readonly JobDraftIssue[]): string[] =>
  issues.map((i) => (i.path.length > 0 ? `${i.path.join(".")}: ${i.message}` : i.message));

/**
 * One template: its draft's steps (one editor per kind) and declared inputs, saved to the draft;
 * Publish, which writes the next version or shows the validation errors beside the steps they
 * name; the sets that offer it; and Retire.
 */
export function JobTemplatePane({ ecosystemId, templateId }: JobTemplatePaneProps): ReactElement {
  const template = useQuery({
    queryKey: jobsKeys.template(ecosystemId, templateId),
    queryFn: () => jobTemplatesApi.get(ecosystemId, templateId),
  });
  if (template.error) return <JobsReadError error={template.error} step="read-template" what="this template" />;
  if (template.isPending) return <Loading />;
  // Keyed by the edit time, so a saved or published template starts a fresh draft form.
  return <TemplateEditor key={template.data.updatedAt} ecosystemId={ecosystemId} template={template.data} />;
}

function TemplateEditor({ ecosystemId, template: t }: { ecosystemId: string; template: JobTemplate }): ReactElement {
  const qc = useQueryClient();
  const retired = t.status === "retired";
  const [name, setName] = useState(t.name);
  const [description, setDescription] = useState(t.description);
  const [steps, setSteps] = useState<JobStep[]>(t.draft?.steps ?? []);
  const [inputs, setInputs] = useState<JobInputSpec[]>(t.draft?.inputs ?? []);
  const [published, setPublished] = useState<number | null>(null);
  const [confirmRetire, setConfirmRetire] = useState(false);

  const invalidate = () => void qc.invalidateQueries({ queryKey: JOBS_KEY });
  const saveDraft = () =>
    jobTemplatesApi.update(ecosystemId, t.id, {
      name: name.trim(),
      description: description.trim() || null,
      steps,
      inputs,
      defaults: t.draft?.defaults ?? {},
    });
  const save = useMutation({ mutationFn: saveDraft, onSuccess: invalidate });
  // Publish validates the stored draft, so the edits are saved first.
  const publish = useMutation({
    mutationFn: async () => {
      await saveDraft();
      return jobTemplatesApi.publish(ecosystemId, t.id);
    },
    onSuccess: (v) => {
      setPublished(v.version);
      invalidate();
    },
  });
  const retire = useMutation({
    mutationFn: () => jobTemplatesApi.retire(ecosystemId, t.id),
    onSuccess: () => {
      setConfirmRetire(false);
      invalidate();
    },
  });

  const problems = jobsDraftProblems(publish.error);
  const stepProblems = problems ? issuesByStep(problems.steps) : new Map<number, string[]>();
  const busy = save.isPending || publish.isPending;

  const moveStep = (i: number, delta: -1 | 1) =>
    setSteps((s) => {
      const next = [...s];
      const [moved] = next.splice(i, 1);
      if (moved) next.splice(i + delta, 0, moved);
      return next;
    });

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center gap-3">
        <h2 className="text-sm font-medium text-apt-text">{t.name}</h2>
        <StatusBadge status={t.status} />
        <span className="text-sm text-apt-text-muted">
          {t.latestVersion === null ? "Never published" : `Latest version ${t.latestVersion}`}
        </span>
        {retired ? null : (
          <div className="ml-auto flex gap-2">
            <Button type="button" size="sm" variant="outline" disabled={busy} onClick={() => save.mutate()}>
              {save.isPending ? "Saving…" : "Save draft"}
            </Button>
            <Button type="button" size="sm" disabled={busy} onClick={() => publish.mutate()}>
              {publish.isPending ? "Publishing…" : "Publish"}
            </Button>
            <Button type="button" size="sm" variant="destructive" onClick={() => setConfirmRetire(true)}>
              Retire
            </Button>
          </div>
        )}
      </div>
      {published !== null ? (
        <p role="status" className="text-sm text-apt-green">
          Published version {published}.
        </p>
      ) : null}
      {save.error ? <ErrorText error={refusalText(save.error)} /> : null}
      {publish.error && !problems ? <ErrorText error={refusalText(publish.error)} /> : null}
      {problems ? (
        <ErrorText error="The draft could not be published. The problems are shown beside the steps and inputs." />
      ) : null}

      <section aria-label="Details" className="flex flex-col gap-3">
        <Field label="Name">
          <Input aria-label="Template name" value={name} disabled={retired} onChange={(e) => setName(e.target.value)} />
        </Field>
        <Field label="Description">
          <Textarea
            aria-label="Template description"
            rows={2}
            value={description}
            disabled={retired}
            onChange={(e) => setDescription(e.target.value)}
          />
        </Field>
      </section>

      <section aria-label="Steps" className="flex flex-col gap-2">
        <h3 className="text-sm font-medium text-apt-text">Steps</h3>
        {steps.length === 0 ? <p className="text-sm text-apt-text-muted">No steps yet.</p> : null}
        <ol className="flex flex-col gap-2">
          {steps.map((s, i) => (
            <JobStepEditor
              key={i}
              step={s}
              index={i}
              count={steps.length}
              problems={stepProblems.get(i)}
              disabled={retired}
              onChange={(next) => setSteps((all) => all.map((x, j) => (j === i ? next : x)))}
              onMove={(d) => moveStep(i, d)}
              onRemove={() => setSteps((all) => all.filter((_, j) => j !== i))}
            />
          ))}
        </ol>
        {retired ? null : (
          <AddStepPicker taken={steps.map((s) => s.id)} onAdd={(s) => setSteps((all) => [...all, s])} />
        )}
      </section>

      <section aria-label="Inputs" className="flex flex-col gap-2">
        <h3 className="text-sm font-medium text-apt-text">Inputs</h3>
        <JobInputSpecsEditor
          specs={inputs}
          problems={problems ? issueText(problems.inputs) : undefined}
          disabled={retired}
          onChange={setInputs}
        />
      </section>

      <OffersSection ecosystemId={ecosystemId} template={t} />

      <AlertModal
        open={confirmRetire}
        tone="error"
        title="Retire this template?"
        description={
          <>
            No new job can be made from it. Existing jobs keep running their version.
            {retire.error ? <ErrorText error={refusalText(retire.error)} /> : null}
          </>
        }
        confirmLabel="Retire"
        confirmVariant="destructive"
        busy={retire.isPending}
        onConfirm={() => retire.mutate()}
        onCancel={() => setConfirmRetire(false)}
      />
    </div>
  );
}

function OffersSection({ ecosystemId, template: t }: { ecosystemId: string; template: JobTemplate }): ReactElement {
  const qc = useQueryClient();
  const sets = useQuery({
    queryKey: ["jobs", "offer-sets", ecosystemId],
    queryFn: () => setsApi.list(ecosystemId),
  });
  const [chosen, setChosen] = useState<string[]>(t.offeredSetIds);
  const write = useMutation({
    mutationFn: () => jobTemplatesApi.setOffers(ecosystemId, t.id, chosen),
    onSuccess: () => void qc.invalidateQueries({ queryKey: JOBS_KEY }),
  });

  const code = write.error ? jobsErrorCode(write.error) : undefined;
  const message =
    code === "script_not_offerable"
      ? "The latest version has a script step, so it cannot be offered to customers."
      : write.error
        ? refusalText(write.error)
        : undefined;
  const locked = t.status === "retired";

  return (
    <section aria-label="Offers" className="flex flex-col gap-2">
      <h3 className="text-sm font-medium text-apt-text">Offered by</h3>
      {locked ? (
        <p className="text-sm text-apt-text-muted">A retired template is not offered.</p>
      ) : sets.error ? (
        <JobsReadError error={sets.error} step="list-sets" what="the sets" />
      ) : sets.isPending ? (
        <Loading />
      ) : sets.data.length === 0 ? (
        <p className="text-sm text-apt-text-muted">This ecosystem has no sets.</p>
      ) : (
        <>
          <ul className="flex flex-col gap-1">
            {sets.data.map((s) => (
              <li key={s.id}>
                <label className="flex items-center gap-2 text-sm text-apt-text">
                  <Checkbox
                    aria-label={`Offered by ${s.name}`}
                    checked={chosen.includes(s.id)}
                    disabled={write.isPending}
                    onCheckedChange={(c) =>
                      setChosen((all) => (c === true ? [...new Set([...all, s.id])] : all.filter((x) => x !== s.id)))
                    }
                  />
                  {s.name}
                </label>
              </li>
            ))}
          </ul>
          {message ? <ErrorText error={message} /> : null}
          <div>
            <Button type="button" size="sm" variant="outline" disabled={write.isPending} onClick={() => write.mutate()}>
              {write.isPending ? "Saving…" : "Save offers"}
            </Button>
          </div>
        </>
      )}
    </section>
  );
}
