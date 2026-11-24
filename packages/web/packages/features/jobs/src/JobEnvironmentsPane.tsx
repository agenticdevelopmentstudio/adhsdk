"use client";

import { useState, type FormEvent, type ReactElement } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { JOBS_KEY, jobsApi, jobsKeys, type JobEnvironment } from "@adh-sdk/data/jobs";
import { Field } from "@adh-sdk/ui/blocks/field";
import { OnceShownSecretDialog } from "@adh-sdk/ui/blocks/once-shown-secret-dialog";
import { AlertModal } from "@adh-sdk/ui/components/alert-modal";
import { Button } from "@adh-sdk/ui/components/button";
import { ErrorText } from "@adh-sdk/ui/components/error-text";
import { Input } from "@adh-sdk/ui/components/input";

import { JobsReadError, Loading, formatTime, refusalText, type JobsOwnerProps } from "./job-ui";

export type JobEnvironmentsPaneProps = JobsOwnerProps;

/** A machine's reported capabilities as one line: the keys it reports true, or its values. */
function capabilitiesText(caps: Record<string, unknown>): string {
  const parts = Object.entries(caps).map(([k, v]) =>
    v === true ? k : Array.isArray(v) ? `${k}: ${v.join(", ")}` : `${k}: ${String(v)}`,
  );
  return parts.length > 0 ? parts.join("; ") : "None reported";
}

/**
 * The owner's machines: each with its reported capabilities and when it was last seen. Creating
 * one, and minting a new token, shows the `jenv_` token once; minting first says the old token
 * stops working, and Delete says the jobs that used the machine fall back to the hub.
 */
export function JobEnvironmentsPane({ workspace }: JobEnvironmentsPaneProps): ReactElement {
  const qc = useQueryClient();
  const scope = { workspace };
  const envs = useQuery({
    queryKey: jobsKeys.environments(workspace),
    queryFn: () => jobsApi.environments(scope),
  });
  const [name, setName] = useState("");
  const [token, setToken] = useState<string | null>(null);
  const [minting, setMinting] = useState<JobEnvironment | null>(null);
  const [deleting, setDeleting] = useState<JobEnvironment | null>(null);

  const invalidate = () => void qc.invalidateQueries({ queryKey: JOBS_KEY });
  const create = useMutation({
    mutationFn: () => jobsApi.createEnvironment(name.trim(), scope),
    onSuccess: (r) => {
      setName("");
      invalidate();
      setToken(r.token);
    },
  });
  const mint = useMutation({
    mutationFn: (id: string) => jobsApi.mintEnvironmentToken(id, scope),
    onSuccess: (r) => {
      setMinting(null);
      invalidate();
      setToken(r.token);
    },
  });
  const remove = useMutation({
    mutationFn: (id: string) => jobsApi.deleteEnvironment(id, scope),
    onSuccess: () => {
      setDeleting(null);
      invalidate();
    },
  });

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (name.trim() !== "") create.mutate();
  };

  return (
    <div className="flex flex-col gap-4">
      <h2 className="text-sm font-medium text-apt-text">Environments</h2>
      <p className="text-sm text-apt-text-muted">
        A machine of yours that runs the steps of the jobs set to it, with its own models and scripts.
      </p>
      {envs.error ? (
        <JobsReadError error={envs.error} step="list-environments" what="your environments" />
      ) : envs.isPending ? (
        <Loading />
      ) : envs.data.length === 0 ? (
        <p className="text-sm text-apt-text-muted">No machines yet. Every job runs on the hub.</p>
      ) : (
        <ul className="flex flex-col divide-y divide-apt-border rounded-md border border-apt-border">
          {envs.data.map((env) => (
            <li key={env.id} className="flex flex-wrap items-center gap-3 px-3 py-2" data-environment-id={env.id}>
              <span className="flex min-w-0 flex-1 flex-col">
                <span className="truncate font-medium text-apt-text">{env.name}</span>
                <span className="truncate text-xs text-apt-text-muted">{capabilitiesText(env.capabilities)}</span>
              </span>
              <span className="text-sm text-apt-text-muted">
                Last seen {env.lastSeenAt ? formatTime(env.lastSeenAt) : "Never"}
              </span>
              <Button type="button" size="sm" variant="outline" onClick={() => setMinting(env)}>
                New token
              </Button>
              <Button type="button" size="sm" variant="ghost" onClick={() => setDeleting(env)}>
                Delete
              </Button>
            </li>
          ))}
        </ul>
      )}

      <form className="flex items-end gap-2" aria-label="Add a machine" onSubmit={submit}>
        <Field label="Machine name">
          <Input
            aria-label="Machine name"
            value={name}
            maxLength={200}
            disabled={create.isPending}
            onChange={(e) => setName(e.target.value)}
          />
        </Field>
        <Button type="submit" size="sm" disabled={create.isPending || name.trim() === ""}>
          {create.isPending ? "Adding…" : "Add machine"}
        </Button>
      </form>
      {create.error ? <ErrorText error={refusalText(create.error)} /> : null}

      <AlertModal
        open={minting !== null}
        tone="info"
        title="Mint a new token?"
        description={
          <>
            The old token for {minting?.name} stops working at once. The machine needs the new one.
            {mint.error ? <ErrorText error={refusalText(mint.error)} /> : null}
          </>
        }
        confirmLabel="Mint token"
        busy={mint.isPending}
        onConfirm={() => minting && mint.mutate(minting.id)}
        onCancel={() => {
          mint.reset();
          setMinting(null);
        }}
      />
      <AlertModal
        open={deleting !== null}
        tone="error"
        title="Delete this machine?"
        description={
          <>
            Jobs that run on {deleting?.name} fall back to the hub.
            {remove.error ? <ErrorText error={refusalText(remove.error)} /> : null}
          </>
        }
        confirmLabel="Delete machine"
        confirmVariant="destructive"
        busy={remove.isPending}
        onConfirm={() => deleting && remove.mutate(deleting.id)}
        onCancel={() => {
          remove.reset();
          setDeleting(null);
        }}
      />
      {token ? (
        <OnceShownSecretDialog
          secret={token}
          title="Machine token"
          description="Set it as AI_NODE_ENVIRONMENT_TOKEN on the machine. It is shown only now."
          label="Environment token"
          onClose={() => {
            // Each mutation keeps its result as `data`; resetting them drops the last copy of the token.
            setToken(null);
            create.reset();
            mint.reset();
          }}
        />
      ) : null}
    </div>
  );
}
