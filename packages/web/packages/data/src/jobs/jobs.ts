"use client";

// Jobs (phase 9): the client for the backend's `/jobs` routes. These are unversioned routes (none
// is in /v1 this phase, design call C18), reached through the site's `/api/:path*` rewrite.
//
// Authoring and status (an ecosystem's managers and product admins; every call names the ecosystem
// as `?ecosystem=<id>`):
//   /api/jobs/templates                          list (GET), create (POST)
//   /api/jobs/templates/{id}                     read (GET), edit the draft (PATCH)
//   /api/jobs/templates/{id}/publish             write the next version (POST)
//   /api/jobs/templates/{id}/retire              retire (POST)
//   /api/jobs/templates/{id}/versions/{version}  one version (GET)
//   /api/jobs/templates/{id}/offers              the sets that offer it (PUT `{ setIds }`)
//   /api/jobs/status                             the product's runs, status only (GET)
//
// Owning (the caller's own jobs, or an organization's with `?workspace=<slug>`):
//   /api/jobs/catalog                            templates offered to the caller (GET)
//   /api/jobs/instances                          list (GET), create (POST)
//   /api/jobs/instances/{id}                     read (GET), edit (PATCH), archive (DELETE)
//   /api/jobs/instances/{id}/version             its pinned version: inputs, defaults, steps (GET)
//   /api/jobs/instances/{id}/run                 manual run (POST, 202)
//   /api/jobs/instances/{id}/triggers            list (GET), create (POST)
//   /api/jobs/instances/{id}/triggers/{tid}      edit (PATCH), delete (DELETE)
//   /api/jobs/runs                               runs, newest first (GET)
//   /api/jobs/runs/{id}                          the run with its step runs (GET)
//   /api/jobs/runs/{id}/stream                   SSE `run` events (see streamJobRun)
//   /api/jobs/runs/{id}/retry, /cancel           (POST)
//   /api/jobs/environments                       list (GET), create (POST)
//   /api/jobs/environments/{id}                  revoke (DELETE)
//   /api/jobs/environments/{id}/token            mint a new token, revoking the old (POST)
//
// Refusals are the house `{ error: { code, message, details? } }`, surfaced as the auth client's
// status-carrying error; {@link jobsErrorCode} and {@link jobsDraftProblems} read them. Every route
// answers 404 while the `jobs_feature` switch is off. Secrets (an inbound trigger's, an
// environment's token) are returned once in the call's result and never kept here.

import { authedJson, authedRequest, httpStatus, withV1Query } from "../http";
import { enc } from "../client-helpers";
import { connectSse } from "../stream";
import {
  isJobRunFinished,
  toCreatedJobTrigger,
  toJobCatalogTemplate,
  toJobEnvironment,
  toJobEnvironmentWithToken,
  toJobInstance,
  toJobPinnedVersion,
  toJobRun,
  toJobRunDetail,
  toJobRunPage,
  toJobRunStarted,
  toJobRunStatusPage,
  toJobTemplate,
  toJobTemplateVersion,
  toJobTrigger,
} from "./mappers";
import type {
  CreatedJobTrigger,
  JobCatalogTemplate,
  JobCatalogTemplateWire,
  JobEnvironment,
  JobEnvironmentWire,
  JobEnvironmentWithToken,
  JobEnvironmentWithTokenWire,
  JobInstance,
  JobInstanceCreate,
  JobInstancePatch,
  JobInstanceStatus,
  JobInstanceWire,
  JobPinnedVersion,
  JobPinnedVersionWire,
  JobRun,
  JobRunDetail,
  JobRunDetailWire,
  JobRunListWire,
  JobRunPage,
  JobRunStarted,
  JobRunStartedWire,
  JobRunStatusListWire,
  JobRunStatusPage,
  JobRunsQuery,
  JobRunWire,
  JobsOwnerScope,
  JobStatusQuery,
  JobTemplate,
  JobTemplateCreate,
  JobTemplatePatch,
  JobTemplateVersion,
  JobTemplateVersionWire,
  JobTemplateWire,
  JobTrigger,
  JobTriggerCreate,
  JobTriggerPatch,
  JobTriggerWire,
} from "./wire";

export const JOBS_BASE = "/api/jobs";

const json = (method: string, body?: unknown): RequestInit => ({
  method,
  ...(body === undefined ? {} : { body: JSON.stringify(body) }),
});

const eco = (ecosystemId: string, extra: Record<string, string | number | undefined> = {}) => ({
  ecosystem: ecosystemId,
  ...extra,
});

const own = (scope: JobsOwnerScope = {}, extra: Record<string, string | number | undefined> = {}) => ({
  workspace: scope.workspace || undefined,
  ...extra,
});

const ownerUrl = (path: string, scope?: JobsOwnerScope, extra?: Record<string, string | number | undefined>) =>
  withV1Query(`${JOBS_BASE}${path}`, own(scope, extra));

const ecoUrl = (path: string, ecosystemId: string, extra?: Record<string, string | number | undefined>) =>
  withV1Query(`${JOBS_BASE}${path}`, eco(ecosystemId, extra));

// ─── errors ──────────────────────────────────────────────────────────────────

/** The house refusal's `error.code` (e.g. `template_key_taken`, `step_needs_hub`), when present. */
export function jobsErrorCode(err: unknown): string | undefined {
  if (httpStatus(err) === undefined) return undefined;
  const code = (err as { code?: unknown }).code;
  if (typeof code === "string" && code) return code;
  const body = (err as { body?: unknown }).body as { error?: { code?: unknown } } | undefined;
  return typeof body?.error?.code === "string" ? body.error.code : undefined;
}

/** The refusal's `error.details`, when present (shape is route-specific). */
export function jobsErrorDetails(err: unknown): unknown {
  if (httpStatus(err) === undefined) return undefined;
  const body = (err as { body?: unknown }).body as { error?: { details?: unknown } } | undefined;
  return body?.error?.details;
}

/** One validation issue of a draft the publish refused, as zod reports it. */
export interface JobDraftIssue {
  path: (string | number)[];
  message: string;
}

/** A publish refused with 422 `draft_invalid`: the issues per part of the draft. */
export interface JobDraftProblems {
  steps: JobDraftIssue[];
  inputs: JobDraftIssue[];
  defaults: JobDraftIssue[];
}

const issues = (v: unknown): JobDraftIssue[] =>
  Array.isArray(v)
    ? v.map((i) => ({
        path: Array.isArray((i as { path?: unknown }).path)
          ? ((i as { path: (string | number)[] }).path)
          : [],
        message: String((i as { message?: unknown }).message ?? ""),
      }))
    : [];

/** The draft's problems when `err` is a 422 `draft_invalid`; else null. */
export function jobsDraftProblems(err: unknown): JobDraftProblems | null {
  if (httpStatus(err) !== 422 || jobsErrorCode(err) !== "draft_invalid") return null;
  const d = (jobsErrorDetails(err) ?? {}) as Record<string, unknown>;
  return { steps: issues(d.steps), inputs: issues(d.inputs), defaults: issues(d.defaults) };
}

// ─── authoring ───────────────────────────────────────────────────────────────

export const jobTemplatesApi = {
  /** The ecosystem's templates, each with its latest version's facts and offering set ids. */
  async list(ecosystemId: string): Promise<JobTemplate[]> {
    const r = await authedJson<{ templates: JobTemplateWire[] }>(ecoUrl("/templates", ecosystemId));
    return (r.templates ?? []).map(toJobTemplate);
  },

  /** A new draft. 409 `template_key_taken` when the key is in use in the ecosystem. */
  async create(ecosystemId: string, input: JobTemplateCreate): Promise<JobTemplate> {
    return toJobTemplate(
      await authedJson<JobTemplateWire>(ecoUrl("/templates", ecosystemId), json("POST", input)),
    );
  },

  /** One template, with its draft. */
  async get(ecosystemId: string, templateId: string): Promise<JobTemplate> {
    return toJobTemplate(
      await authedJson<JobTemplateWire>(ecoUrl(`/templates/${enc(templateId)}`, ecosystemId)),
    );
  },

  /** Edit the name, description and draft. 409 `template_retired` for a retired template. */
  async update(ecosystemId: string, templateId: string, patch: JobTemplatePatch): Promise<JobTemplate> {
    return toJobTemplate(
      await authedJson<JobTemplateWire>(
        ecoUrl(`/templates/${enc(templateId)}`, ecosystemId),
        json("PATCH", patch),
      ),
    );
  },

  /** Validate the draft and write the next version. A 422 `draft_invalid` reads through
   *  {@link jobsDraftProblems}. */
  async publish(ecosystemId: string, templateId: string): Promise<JobTemplateVersion> {
    return toJobTemplateVersion(
      await authedJson<JobTemplateVersionWire>(
        ecoUrl(`/templates/${enc(templateId)}/publish`, ecosystemId),
        json("POST"),
      ),
    );
  },

  /** Retire; existing jobs keep running their version. */
  async retire(ecosystemId: string, templateId: string): Promise<JobTemplate> {
    return toJobTemplate(
      await authedJson<JobTemplateWire>(
        ecoUrl(`/templates/${enc(templateId)}/retire`, ecosystemId),
        json("POST"),
      ),
    );
  },

  async version(ecosystemId: string, templateId: string, version: number): Promise<JobTemplateVersion> {
    return toJobTemplateVersion(
      await authedJson<JobTemplateVersionWire>(
        ecoUrl(`/templates/${enc(templateId)}/versions/${enc(String(version))}`, ecosystemId),
      ),
    );
  },

  /** Replace the sets that offer the template. 422 `script_not_offerable` when the latest version
   *  has a script step; `unknown_set` for a set not in the ecosystem. */
  async setOffers(ecosystemId: string, templateId: string, setIds: string[]): Promise<JobTemplate> {
    return toJobTemplate(
      await authedJson<JobTemplateWire>(
        ecoUrl(`/templates/${enc(templateId)}/offers`, ecosystemId),
        json("PUT", { setIds }),
      ),
    );
  },
};

// ─── the product admin's status read ─────────────────────────────────────────

export const jobStatusApi = {
  /** The product's customers' runs, newest first: status and a short error, never content. */
  async list(ecosystemId: string, query: JobStatusQuery = {}): Promise<JobRunStatusPage> {
    return toJobRunStatusPage(
      await authedJson<JobRunStatusListWire>(
        ecoUrl("/status", ecosystemId, { before: query.before, limit: query.limit }),
      ),
    );
  },
};

// ─── owning ──────────────────────────────────────────────────────────────────

export const jobsApi = {
  /** The templates offered to the caller, at their latest versions. */
  async catalog(scope?: JobsOwnerScope): Promise<JobCatalogTemplate[]> {
    const r = await authedJson<{ templates: JobCatalogTemplateWire[] }>(ownerUrl("/catalog", scope));
    return (r.templates ?? []).map(toJobCatalogTemplate);
  },

  /** The owner's jobs; archived ones only when asked for by status. */
  async list(scope?: JobsOwnerScope, query: { status?: JobInstanceStatus } = {}): Promise<JobInstance[]> {
    const r = await authedJson<{ instances: JobInstanceWire[] }>(
      ownerUrl("/instances", scope, { status: query.status }),
    );
    return (r.instances ?? []).map(toJobInstance);
  },

  /** A job from a template version, or (a manager only) with inline steps. */
  async create(input: JobInstanceCreate, scope?: JobsOwnerScope): Promise<JobInstance> {
    return toJobInstance(
      await authedJson<JobInstanceWire>(ownerUrl("/instances", scope), json("POST", input)),
    );
  },

  async get(instanceId: string, scope?: JobsOwnerScope): Promise<JobInstance> {
    return toJobInstance(
      await authedJson<JobInstanceWire>(ownerUrl(`/instances/${enc(instanceId)}`, scope)),
    );
  },

  /**
   * The version the job is pinned to: its declared inputs and defaults, and its steps' names. A job
   * with inline steps answers its own steps and no inputs. 409 `template_missing` when the version
   * is not in the job's ecosystem.
   */
  async pinnedVersion(instanceId: string, scope?: JobsOwnerScope): Promise<JobPinnedVersion> {
    return toJobPinnedVersion(
      await authedJson<JobPinnedVersionWire>(ownerUrl(`/instances/${enc(instanceId)}/version`, scope)),
    );
  },

  /** Inputs, environment, options, name, or pause and resume. */
  async update(instanceId: string, patch: JobInstancePatch, scope?: JobsOwnerScope): Promise<JobInstance> {
    return toJobInstance(
      await authedJson<JobInstanceWire>(
        ownerUrl(`/instances/${enc(instanceId)}`, scope),
        json("PATCH", patch),
      ),
    );
  },

  /** Archive the job; the answer is the archived job. */
  async remove(instanceId: string, scope?: JobsOwnerScope): Promise<JobInstance> {
    return toJobInstance(
      await authedJson<JobInstanceWire>(ownerUrl(`/instances/${enc(instanceId)}`, scope), json("DELETE")),
    );
  },

  /** Start a manual run. A run refused at start comes back `failed` with its error code. */
  async run(instanceId: string, scope?: JobsOwnerScope): Promise<JobRunStarted> {
    return toJobRunStarted(
      await authedJson<JobRunStartedWire>(ownerUrl(`/instances/${enc(instanceId)}/run`, scope), json("POST")),
    );
  },

  async triggers(instanceId: string, scope?: JobsOwnerScope): Promise<JobTrigger[]> {
    const r = await authedJson<{ triggers: JobTriggerWire[] }>(
      ownerUrl(`/instances/${enc(instanceId)}/triggers`, scope),
    );
    return (r.triggers ?? []).map(toJobTrigger);
  },

  /** A new trigger. An inbound trigger's secret is in the result this once. */
  async createTrigger(
    instanceId: string,
    input: JobTriggerCreate,
    scope?: JobsOwnerScope,
  ): Promise<CreatedJobTrigger> {
    return toCreatedJobTrigger(
      await authedJson<JobTriggerWire>(
        ownerUrl(`/instances/${enc(instanceId)}/triggers`, scope),
        json("POST", input),
      ),
    );
  },

  async updateTrigger(
    instanceId: string,
    triggerId: string,
    patch: JobTriggerPatch,
    scope?: JobsOwnerScope,
  ): Promise<JobTrigger> {
    return toJobTrigger(
      await authedJson<JobTriggerWire>(
        ownerUrl(`/instances/${enc(instanceId)}/triggers/${enc(triggerId)}`, scope),
        json("PATCH", patch),
      ),
    );
  },

  async deleteTrigger(instanceId: string, triggerId: string, scope?: JobsOwnerScope): Promise<void> {
    await authedRequest(
      ownerUrl(`/instances/${enc(instanceId)}/triggers/${enc(triggerId)}`, scope),
      json("DELETE"),
    );
  },

  /** Runs, newest first, as the route answers them; page with `nextBefore`. */
  async runs(query: JobRunsQuery = {}, scope?: JobsOwnerScope): Promise<JobRunPage> {
    return toJobRunPage(
      await authedJson<JobRunListWire>(
        ownerUrl("/runs", scope, {
          instanceId: query.instanceId,
          status: query.status,
          before: query.before,
          limit: query.limit,
        }),
      ),
    );
  },

  /** The run with its step runs (outputs, logs, usage), in position order. */
  async getRun(runId: string, scope?: JobsOwnerScope): Promise<JobRunDetail> {
    return toJobRunDetail(await authedJson<JobRunDetailWire>(ownerUrl(`/runs/${enc(runId)}`, scope)));
  },

  async retryRun(runId: string, scope?: JobsOwnerScope): Promise<JobRun> {
    return toJobRun(await authedJson<JobRunWire>(ownerUrl(`/runs/${enc(runId)}/retry`, scope), json("POST")));
  },

  async cancelRun(runId: string, scope?: JobsOwnerScope): Promise<JobRun> {
    return toJobRun(await authedJson<JobRunWire>(ownerUrl(`/runs/${enc(runId)}/cancel`, scope), json("POST")));
  },

  async environments(scope?: JobsOwnerScope): Promise<JobEnvironment[]> {
    const r = await authedJson<{ environments: JobEnvironmentWire[] }>(ownerUrl("/environments", scope));
    return (r.environments ?? []).map(toJobEnvironment);
  },

  /** A new machine; its `jenv_` token is in the result this once. */
  async createEnvironment(name: string, scope?: JobsOwnerScope): Promise<JobEnvironmentWithToken> {
    return toJobEnvironmentWithToken(
      await authedJson<JobEnvironmentWithTokenWire>(ownerUrl("/environments", scope), json("POST", { name })),
    );
  },

  /** Revoke a machine. 409 `environment_in_use` while a job names it. */
  async deleteEnvironment(environmentId: string, scope?: JobsOwnerScope): Promise<void> {
    await authedRequest(ownerUrl(`/environments/${enc(environmentId)}`, scope), json("DELETE"));
  },

  /** Mint a new token, revoking the old one; the token is in the result this once. */
  async mintEnvironmentToken(environmentId: string, scope?: JobsOwnerScope): Promise<JobEnvironmentWithToken> {
    return toJobEnvironmentWithToken(
      await authedJson<JobEnvironmentWithTokenWire>(
        ownerUrl(`/environments/${enc(environmentId)}/token`, scope),
        json("POST"),
      ),
    );
  },
};

// ─── the run stream ──────────────────────────────────────────────────────────

export interface StreamJobRunOptions extends JobsOwnerScope {
  /** Each state of the run the stream (or its poll fallback) reports, in order. */
  onRun: (run: JobRun) => void;
  /** A poll fallback that failed, or a frame that did not parse. The stream carries on. */
  onError?: (err: unknown) => void;
  /** Poll cadence while the live stream is unavailable (ms). */
  pollIntervalMs?: number;
}

/**
 * Follow a run through `GET /jobs/runs/:id/stream`. Every `run` event is mapped and handed to
 * `onRun`. The server closes the stream after 60 s; the browser's EventSource reconnects on its
 * own, and a hard close (an expired token) drops to polling {@link jobsApi.getRun} until the
 * stream can reopen. Once a run arrives finished (succeeded, failed or cancelled) the stream is
 * closed for good, after `onRun` has seen it. Returns a function that closes it early.
 */
export function streamJobRun(runId: string, opts: StreamJobRunOptions): () => void {
  const scope: JobsOwnerScope = { workspace: opts.workspace };
  let done = false;
  let close = () => {};

  const deliver = (run: JobRun) => {
    if (done) return;
    opts.onRun(run);
    if (isJobRunFinished(run.status)) {
      done = true;
      close();
    }
  };

  const handle = connectSse({
    url: ownerUrl(`/runs/${enc(runId)}/stream`, scope),
    event: "run",
    onEvent: (data) => {
      let wire: JobRunWire;
      try {
        wire = JSON.parse(data) as JobRunWire;
      } catch (err) {
        opts.onError?.(err);
        return;
      }
      deliver(toJobRun(wire));
    },
    onPoll: () => {
      if (done) return;
      jobsApi.getRun(runId, scope).then(deliver, (err) => opts.onError?.(err));
    },
    ...(opts.pollIntervalMs !== undefined ? { pollIntervalMs: opts.pollIntervalMs } : {}),
  });
  close = () => handle.close();
  // A finished frame delivered synchronously during connect has nothing to close yet.
  if (done) handle.close();

  return () => {
    done = true;
    handle.close();
  };
}

// ─── query keys ──────────────────────────────────────────────────────────────

/** Every jobs read keys under this prefix. */
export const JOBS_KEY = ["jobs"] as const;

export const jobsKeys = {
  templates: (ecosystemId: string) => [...JOBS_KEY, "templates", ecosystemId] as const,
  template: (ecosystemId: string, templateId: string) =>
    [...JOBS_KEY, "template", ecosystemId, templateId] as const,
  version: (ecosystemId: string, templateId: string, version: number) =>
    [...JOBS_KEY, "version", ecosystemId, templateId, version] as const,
  status: (ecosystemId: string, query: JobStatusQuery = {}) =>
    [...JOBS_KEY, "status", ecosystemId, query] as const,
  catalog: (workspace?: string) => [...JOBS_KEY, "catalog", workspace ?? ""] as const,
  instances: (workspace?: string, status?: JobInstanceStatus) =>
    [...JOBS_KEY, "instances", workspace ?? "", status ?? ""] as const,
  instance: (instanceId: string, workspace?: string) =>
    [...JOBS_KEY, "instance", workspace ?? "", instanceId] as const,
  pinnedVersion: (instanceId: string, workspace?: string) =>
    [...JOBS_KEY, "pinned-version", workspace ?? "", instanceId] as const,
  triggers: (instanceId: string, workspace?: string) =>
    [...JOBS_KEY, "triggers", workspace ?? "", instanceId] as const,
  runs: (query: JobRunsQuery = {}, workspace?: string) =>
    [...JOBS_KEY, "runs", workspace ?? "", query] as const,
  run: (runId: string, workspace?: string) => [...JOBS_KEY, "run", workspace ?? "", runId] as const,
  environments: (workspace?: string) => [...JOBS_KEY, "environments", workspace ?? ""] as const,
};
