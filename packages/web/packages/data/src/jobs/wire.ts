"use client";

// Jobs (phase 9): the wire shapes the backend's unversioned `/jobs` routes answer, and the domain
// shapes the client hands its callers.
//
// Hand-written, as every client in this package is (see ../support/wire.ts). The reference is the
// backend's `openapi.json` (`components.schemas.Job*`), NOT the `Job*` components in
// @adh-sdk/adh-api-types: that package generates from `openapi.v1.json`, whose copies of these
// schemas are the /v1 projection (snake_case keys, `created`/`updated` as unix seconds), and no
// `/jobs` route is in /v1 this phase (design call C18). The `/jobs` routes answer camelCase with
// every time as RFC 3339, which is what is written here. When the routes move into /v1, these
// become aliases of the generated components and `mappers.ts` reads the snake_case.

// ─── steps, inputs, options (lib/jobs/model.ts) ───────────────────────────────

export type JobStepKind = "ai" | "action" | "webhook" | "notify" | "wait" | "script";
export const JOB_STEP_KINDS: readonly JobStepKind[] = [
  "ai",
  "action",
  "webhook",
  "notify",
  "wait",
  "script",
];

export type JobOnError = "fail" | "continue";

/** Fields every step carries. `onError` absent means the job's own, else `fail`. */
export interface JobStepCommon {
  /** Unique in the job, `[a-z0-9_]`. */
  id: string;
  name: string;
  onError?: JobOnError;
  /** 1 to 10, default 3. */
  maxAttempts?: number;
}

/** An AI step's model: a provider connection (hub nodes) or the machine's own (machines). */
export type JobStepModel =
  | { source: "connection"; serviceId: string; model: string }
  | { source: "environment"; provider: "local" | "claude-code"; model?: string | null };

export interface JobAiStep extends JobStepCommon {
  kind: "ai";
  prompt: string;
  instructions?: string | null;
  model: JobStepModel;
  outputSchema?: Record<string, unknown> | null;
  personaId?: string | null;
  saveAs?: { kind: "document"; title: string } | null;
}

export interface JobActionStep extends JobStepCommon {
  kind: "action";
  connectionId: string;
  /** e.g. `gmail:search`. */
  actionType: string;
  payload?: Record<string, unknown>;
}

export interface JobWebhookStep extends JobStepCommon {
  kind: "webhook";
  endpointId: string;
  payload?: unknown;
}

export interface JobNotifyStep extends JobStepCommon {
  kind: "notify";
  subject: string;
  body: string;
}

export interface JobWaitStep extends JobStepCommon {
  kind: "wait";
  /** 60 to 86 400. */
  delaySeconds: number;
}

export interface JobScriptStep extends JobStepCommon {
  kind: "script";
  language: "node" | "python";
  source: string;
  args?: string[];
  /** At most 900. */
  timeoutSeconds: number;
}

/** One step. Values may name `{{inputs.<key>}}` and `{{steps.<id>.output[.<path>]}}`. */
export type JobStep =
  | JobAiStep
  | JobActionStep
  | JobWebhookStep
  | JobNotifyStep
  | JobWaitStep
  | JobScriptStep;

export type JobInputType = "text" | "number" | "boolean" | "connection" | "endpoint" | "choice";

/** A declared input of a template. */
export interface JobInputSpec {
  key: string;
  label: string;
  type: JobInputType;
  required?: boolean;
  /** A `choice` input's allowed values. */
  choices?: string[];
}

/** The values a job gives its declared inputs, by key. */
export type JobInputValues = Record<string, unknown>;

export interface JobNotifyOptions {
  on?: ("failed" | "succeeded")[];
  channels?: ("email" | "sms" | "hub")[];
}

/** A job's options; every field optional, laid over the template version's defaults. */
export interface JobOptions {
  /** 0 to 90. */
  priority?: number;
  onError?: JobOnError;
  notify?: JobNotifyOptions;
}

/** A template version's defaults: a job's options plus the minimum schedule interval. */
export interface JobTemplateDefaults extends JobOptions {
  minIntervalMinutes?: number;
}

// ─── wire ───────────────────────────────────────────────────────────────────

export type JobTemplateStatus = "draft" | "published" | "retired";
export type JobInstanceStatus = "active" | "paused" | "archived";
export type JobRunStatus = "queued" | "running" | "succeeded" | "failed" | "cancelled";
export type JobStepRunStatus =
  | "pending"
  | "running"
  | "succeeded"
  | "failed"
  | "skipped"
  | "cancelled";
export type JobTriggerKind = "schedule" | "event" | "inbound";
export type JobOwnerKind = "customer" | "organization";

export interface JobTemplateDraftWire {
  steps?: unknown[] | null;
  inputs?: unknown[] | null;
  defaults?: Record<string, unknown> | null;
}

export interface JobTemplateWire {
  id: string;
  key: string;
  name: string;
  description: string | null;
  status: JobTemplateStatus;
  latestVersion: number | null;
  latestHasScript: boolean | null;
  latestPublishedAt: string | null;
  offeredSetIds?: string[] | null;
  createdAt: string;
  updatedAt: string;
  draft: JobTemplateDraftWire | null;
}

export interface JobTemplateVersionWire {
  templateId: string;
  version: number;
  steps: unknown[];
  inputs: unknown[] | null;
  defaults: Record<string, unknown> | null;
  hasScript: boolean;
  publishedBy: string;
  publishedAt: string;
}

export interface JobCatalogTemplateWire {
  id: string;
  key: string;
  name: string;
  description: string | null;
  version: number;
  inputs: unknown[] | null;
  defaults: Record<string, unknown> | null;
  publishedAt: string;
}

export interface JobInstanceWire {
  id: string;
  name: string;
  ownerKind: JobOwnerKind;
  ownerId: string;
  templateId: string | null;
  templateVersion: number | null;
  steps: unknown[] | null;
  inputs: Record<string, unknown> | null;
  environmentId: string | null;
  options: Record<string, unknown> | null;
  status: JobInstanceStatus;
  createdAt: string;
  updatedAt: string;
}

/** `GET /jobs/instances/{id}/version`: the version a job is pinned to, as its owner may read it. */
export interface JobPinnedVersionWire {
  /** Null for a job with inline steps. */
  templateId: string | null;
  templateVersion: number | null;
  /** Empty for inline steps. */
  inputs: unknown[] | null;
  defaults: Record<string, unknown> | null;
  steps: { id: string; name: string; kind: string }[] | null;
}

export interface JobRunStartedWire {
  runId: string;
  status: "running" | "failed";
  errorCode: string | null;
  error: string | null;
}

export interface JobTriggerWire {
  id: string;
  instanceId: string;
  kind: JobTriggerKind;
  cron: string | null;
  timeZone: string | null;
  eventTypes: string[] | null;
  enabled: boolean;
  nextFireAt: string | null;
  lastFiredAt: string | null;
  createdAt: string;
  updatedAt: string;
  /** An inbound trigger's secret, only in the create answer. */
  secret?: string;
}

export interface JobRunWire {
  id: string;
  instanceId: string;
  triggerId: string | null;
  status: JobRunStatus;
  currentStep: number | null;
  usage: Record<string, unknown> | null;
  errorCode: string | null;
  error: string | null;
  startedAt: string | null;
  finishedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface JobStepRunWire {
  id: string;
  position: number;
  stepId: string | null;
  /** The step's name in the run's frozen steps (its pinned version's, or the job's inline steps). */
  name: string | null;
  kind: string | null;
  status: string;
  attempts: number;
  output: unknown;
  /** The latest lines the executor wrote. */
  log: string[] | null;
  usage: Record<string, unknown> | null;
  errorCode: string | null;
  error: string | null;
  startedAt: string | null;
  finishedAt: string | null;
}

export interface JobRunDetailWire extends JobRunWire {
  stepRuns: JobStepRunWire[] | null;
}

export interface JobRunListWire {
  runs: JobRunWire[];
  nextBefore: string | null;
}

export interface JobEnvironmentWire {
  id: string;
  name: string;
  kind: "machine";
  capabilities: Record<string, unknown> | null;
  lastSeenAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface JobEnvironmentWithTokenWire extends JobEnvironmentWire {
  /** The `jenv_` token, shown only in this answer. */
  token: string;
}

export interface JobRunStatusWire {
  runId: string;
  jobId: string;
  jobName: string;
  templateKey: string | null;
  ownerId: string;
  status: JobRunStatus;
  errorCode: string | null;
  error: string | null;
  startedAt: string | null;
  finishedAt: string | null;
  createdAt: string;
}

export interface JobRunStatusListWire {
  runs: JobRunStatusWire[];
  nextBefore: string | null;
}

// ─── domain ─────────────────────────────────────────────────────────────────

export interface JobTemplateDraft {
  steps: JobStep[];
  inputs: JobInputSpec[];
  defaults: JobTemplateDefaults;
}

export interface JobTemplate {
  id: string;
  key: string;
  name: string;
  /** "" when none. */
  description: string;
  status: JobTemplateStatus;
  latestVersion: number | null;
  latestHasScript: boolean;
  latestPublishedAt: string | null;
  offeredSetIds: string[];
  createdAt: string;
  updatedAt: string;
  /** Null when the template has no draft (it was never edited since its last publish). */
  draft: JobTemplateDraft | null;
}

export interface JobTemplateVersion {
  templateId: string;
  version: number;
  steps: JobStep[];
  inputs: JobInputSpec[];
  defaults: JobTemplateDefaults;
  hasScript: boolean;
  publishedBy: string;
  publishedAt: string;
}

export interface JobCatalogTemplate {
  id: string;
  key: string;
  name: string;
  description: string;
  version: number;
  inputs: JobInputSpec[];
  defaults: JobTemplateDefaults;
  publishedAt: string;
}

export interface JobInstance {
  id: string;
  name: string;
  ownerKind: JobOwnerKind;
  ownerId: string;
  templateId: string | null;
  templateVersion: number | null;
  /** A developer job's inline steps; null for a job made from a template. */
  steps: JobStep[] | null;
  inputs: JobInputValues;
  /** Null runs AI steps on the hub. */
  environmentId: string | null;
  options: JobOptions;
  status: JobInstanceStatus;
  createdAt: string;
  updatedAt: string;
}

/** A step of a job's pinned version, as the owner reads it. */
export interface JobPinnedStep {
  id: string;
  name: string;
  kind: string;
}

/**
 * The version a job is pinned to: the declared inputs and defaults its settings are edited against,
 * and its steps' names. A job with inline steps has no template, no declared inputs and its own steps.
 */
export interface JobPinnedVersion {
  templateId: string | null;
  templateVersion: number | null;
  inputs: JobInputSpec[];
  defaults: JobTemplateDefaults;
  steps: JobPinnedStep[];
}

export interface JobRunStarted {
  runId: string;
  status: "running" | "failed";
  errorCode: string | null;
  error: string | null;
}

export interface JobTrigger {
  id: string;
  instanceId: string;
  kind: JobTriggerKind;
  cron: string | null;
  timeZone: string | null;
  eventTypes: string[];
  enabled: boolean;
  nextFireAt: string | null;
  lastFiredAt: string | null;
  createdAt: string;
  updatedAt: string;
}

/** A trigger create's answer: an inbound trigger's secret appears here once and nowhere else. */
export interface CreatedJobTrigger {
  trigger: JobTrigger;
  /** Send as `X-ADH-Trigger-Secret` to `POST /public/jobs/hooks/{id}`; null for non-inbound kinds. */
  secret: string | null;
}

/** Token totals, summed per step and per run. Missing keys read 0. */
export interface JobUsage {
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens: number;
  cacheWriteTokens: number;
  reasoningTokens: number;
}

export interface JobRun {
  id: string;
  instanceId: string;
  triggerId: string | null;
  status: JobRunStatus;
  currentStep: number | null;
  usage: JobUsage;
  errorCode: string | null;
  error: string | null;
  startedAt: string | null;
  finishedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface JobStepRun {
  id: string;
  position: number;
  /** Null when the run's step row names no step. */
  stepId: string | null;
  /** The step's name when the run's frozen steps hold it; null otherwise. */
  name: string | null;
  /** "" when the row names none. */
  kind: string;
  status: JobStepRunStatus;
  attempts: number;
  output: unknown;
  log: string[];
  usage: JobUsage;
  errorCode: string | null;
  error: string | null;
  startedAt: string | null;
  finishedAt: string | null;
}

export interface JobRunDetail extends JobRun {
  /** In position order. */
  stepRuns: JobStepRun[];
}

/** A page of runs, newest first; pass `nextBefore` as `before` for the next page. */
export interface JobRunPage {
  runs: JobRun[];
  nextBefore: string | null;
}

export interface JobEnvironment {
  id: string;
  name: string;
  kind: "machine";
  capabilities: Record<string, unknown>;
  lastSeenAt: string | null;
  createdAt: string;
  updatedAt: string;
}

/** An environment create or token mint: the raw `jenv_` token appears here once. */
export interface JobEnvironmentWithToken {
  environment: JobEnvironment;
  token: string;
}

/** One run in the product admin's status table: status only, never content. */
export interface JobRunStatusRow {
  runId: string;
  jobId: string;
  jobName: string;
  templateKey: string | null;
  ownerId: string;
  status: JobRunStatus;
  errorCode: string | null;
  /** The first 200 characters. */
  error: string | null;
  startedAt: string | null;
  finishedAt: string | null;
  createdAt: string;
}

export interface JobRunStatusPage {
  runs: JobRunStatusRow[];
  nextBefore: string | null;
}

// ─── inputs to the calls ────────────────────────────────────────────────────

export interface JobTemplateCreate {
  key: string;
  name: string;
  description?: string | null;
  steps?: JobStep[];
  inputs?: JobInputSpec[];
  defaults?: JobTemplateDefaults;
}

export interface JobTemplatePatch {
  name?: string;
  description?: string | null;
  steps?: JobStep[];
  inputs?: JobInputSpec[];
  defaults?: JobTemplateDefaults;
}

/** From a template (`templateId`, optionally a version) or, for a manager, inline `steps`. */
export interface JobInstanceCreate {
  name: string;
  templateId?: string;
  templateVersion?: number;
  steps?: JobStep[];
  inputs?: JobInputValues;
  environmentId?: string | null;
  options?: JobOptions;
}

export interface JobInstancePatch {
  name?: string;
  inputs?: JobInputValues;
  environmentId?: string | null;
  options?: JobOptions;
  status?: "active" | "paused";
}

export type JobTriggerCreate =
  | { kind: "schedule"; cron: string; timeZone: string; enabled?: boolean }
  | { kind: "event"; eventTypes: string[]; enabled?: boolean }
  | { kind: "inbound"; enabled?: boolean };

export interface JobTriggerPatch {
  enabled?: boolean;
  cron?: string;
  timeZone?: string;
  eventTypes?: string[];
}

export interface JobRunsQuery {
  instanceId?: string;
  status?: JobRunStatus;
  /** RFC 3339: runs created before it (a page's `nextBefore`). */
  before?: string;
  /** 1 to 200, default 50. */
  limit?: number;
}

export interface JobStatusQuery {
  before?: string;
  limit?: number;
}

/** Owner routes act for the caller, or for an organization workspace named by its slug. */
export interface JobsOwnerScope {
  workspace?: string;
}
