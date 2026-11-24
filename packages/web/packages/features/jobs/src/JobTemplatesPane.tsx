"use client";

import { useState, type FormEvent, type ReactElement } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { JOBS_KEY, jobTemplatesApi, jobsKeys, type JobTemplate } from "@adh-sdk/data/jobs";
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
import { Textarea } from "@adh-sdk/ui/components/textarea";

import { JobsReadError, Loading, StatusBadge, refusalText, type JobsOpen } from "./job-ui";

export interface JobTemplatesPaneProps {
  /** The ecosystem whose templates are authored. */
  ecosystemId: string;
  /** Open a template (a row of the list, or the draft just created). */
  onOpenTemplate?: JobsOpen;
}

/**
 * The ecosystem's job templates, each with its status, latest version and number of offering
 * sets. A template is created in a modal and the new draft opened.
 */
export function JobTemplatesPane({ ecosystemId, onOpenTemplate }: JobTemplatesPaneProps): ReactElement {
  const templates = useQuery({
    queryKey: jobsKeys.templates(ecosystemId),
    queryFn: () => jobTemplatesApi.list(ecosystemId),
  });
  const [creating, setCreating] = useState(false);

  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-center justify-between gap-2">
        <h2 className="text-sm font-medium text-apt-text">Job templates</h2>
        <Button type="button" size="sm" onClick={() => setCreating(true)}>
          New template
        </Button>
      </div>
      {templates.error ? (
        <JobsReadError error={templates.error} step="list-templates" what="the templates" />
      ) : templates.isPending ? (
        <Loading />
      ) : templates.data.length === 0 ? (
        <p className="text-sm text-apt-text-muted">No templates yet.</p>
      ) : (
        <ul className="flex flex-col divide-y divide-apt-border rounded-md border border-apt-border">
          {templates.data.map((t) => (
            <TemplateRow key={t.id} template={t} onOpen={onOpenTemplate} />
          ))}
        </ul>
      )}
      <CreateTemplateDialog
        open={creating}
        ecosystemId={ecosystemId}
        onClose={() => setCreating(false)}
        onCreated={(t) => {
          setCreating(false);
          onOpenTemplate?.(t.id);
        }}
      />
    </div>
  );
}

function TemplateRow({ template: t, onOpen }: { template: JobTemplate; onOpen?: JobsOpen }): ReactElement {
  const sets = t.offeredSetIds.length;
  const body = (
    <>
      <span className="flex min-w-0 flex-1 flex-col">
        <span className="truncate font-medium text-apt-text">{t.name}</span>
        <span className="truncate font-mono text-xs text-apt-text-muted">{t.key}</span>
      </span>
      <StatusBadge status={t.status} />
      <span className="w-24 text-sm text-apt-text-muted">
        {t.latestVersion === null ? "Unpublished" : `Version ${t.latestVersion}`}
      </span>
      <span className="w-24 text-right text-sm text-apt-text-muted">
        {sets === 1 ? "1 set" : `${sets} sets`}
      </span>
    </>
  );
  return (
    <li>
      {onOpen ? (
        <button
          type="button"
          className="flex w-full items-center gap-3 px-3 py-2 text-left hover:bg-apt-surface-2"
          onClick={() => onOpen(t.id)}
        >
          {body}
        </button>
      ) : (
        <div className="flex items-center gap-3 px-3 py-2">{body}</div>
      )}
    </li>
  );
}

const KEY_RE = /^[a-z0-9-]{1,64}$/;

function CreateTemplateDialog({
  open,
  ecosystemId,
  onClose,
  onCreated,
}: {
  open: boolean;
  ecosystemId: string;
  onClose: () => void;
  onCreated: (t: JobTemplate) => void;
}): ReactElement {
  const qc = useQueryClient();
  const [key, setKey] = useState("");
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");

  const reset = () => {
    setKey("");
    setName("");
    setDescription("");
  };

  const create = useMutation({
    mutationFn: () =>
      jobTemplatesApi.create(ecosystemId, {
        key: key.trim(),
        name: name.trim(),
        description: description.trim() || null,
      }),
    onSuccess: (t) => {
      void qc.invalidateQueries({ queryKey: JOBS_KEY });
      create.reset();
      reset();
      onCreated(t);
    },
  });

  const keyOk = KEY_RE.test(key.trim());
  const canCreate = keyOk && name.trim() !== "" && !create.isPending;

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (canCreate) create.mutate();
  };
  const close = () => {
    if (create.isPending) return;
    create.reset();
    reset();
    onClose();
  };

  return (
    <Dialog open={open} onOpenChange={(o) => !o && close()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>New job template</DialogTitle>
          <DialogDescription>The template starts as a draft. Publish it to offer it.</DialogDescription>
        </DialogHeader>
        <form className="flex flex-col gap-4" onSubmit={submit}>
          <Field
            label="Key"
            hint="Lowercase letters, digits and -. It cannot change."
            error={key.trim() !== "" && !keyOk ? "Use lowercase letters, digits and -." : undefined}
          >
            <Input aria-label="Key" value={key} disabled={create.isPending} onChange={(e) => setKey(e.target.value)} />
          </Field>
          <Field label="Name">
            <Input aria-label="Name" value={name} disabled={create.isPending} onChange={(e) => setName(e.target.value)} />
          </Field>
          <Field label="Description">
            <Textarea
              aria-label="Description"
              rows={2}
              value={description}
              disabled={create.isPending}
              onChange={(e) => setDescription(e.target.value)}
            />
          </Field>
          {create.error ? <ErrorText error={refusalText(create.error)} /> : null}
          <DialogFooter>
            <Button type="button" variant="ghost" size="sm" disabled={create.isPending} onClick={close}>
              Cancel
            </Button>
            <Button type="submit" size="sm" disabled={!canCreate}>
              {create.isPending ? "Creating…" : "Create template"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
