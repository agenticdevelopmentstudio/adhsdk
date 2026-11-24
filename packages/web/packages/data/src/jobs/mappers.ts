// Jobs wire -> domain mappers. The `/jobs` routes already answer camelCase (see ./wire.ts), so the
// mappers' job is the rest of the contract: every nullable bag becomes a value the panes can read
// without a guard (arrays [], objects {}, usage zeroes), statuses are narrowed to their unions, and
// the token and secret a create answers are split out of the row so nothing keeps them by accident.
// Written field by field: the JSON bags (steps, inputs, options, output) keep their exact keys.
import { narrow } from "../client-helpers";
import type {
  CreatedJobTrigger,
  JobCatalogTemplate,
  JobCatalogTemplateWire,
  JobEnvironment,
  JobEnvironmentWire,
  JobEnvironmentWithToken,
  JobEnvironmentWithTokenWire,
  JobInputSpec,
  JobInstance,
  JobInstanceStatus,
  JobInstanceWire,
  JobOptions,
  JobRun,
  JobRunDetail,
  JobRunDetailWire,
  JobRunPage,
  JobRunListWire,
  JobRunStarted,
  JobRunStartedWire,
  JobRunStatus,
  JobRunStatusListWire,
  JobRunStatusPage,
  JobRunStatusRow,
  JobRunStatusWire,
  JobRunWire,
  JobStep,
  JobStepRun,
  JobStepRunStatus,
  JobStepRunWire,
  JobTemplate,
  JobTemplateDefaults,
  JobTemplateDraft,
  JobTemplateDraftWire,
  JobTemplateStatus,
  JobTemplateVersion,
  JobTemplateVersionWire,
  JobTemplateWire,
  JobTrigger,
  JobTriggerWire,
  JobUsage,
} from "./wire";

const RUN_STATUSES: readonly JobRunStatus[] = [
  "queued",
  "running",
  "succeeded",
  "failed",
  "cancelled",
];
const STEP_RUN_STATUSES: readonly JobStepRunStatus[] = [
  "pending",
  "running",
  "succeeded",
  "failed",
  "skipped",
  "cancelled",
];
const TEMPLATE_STATUSES: readonly JobTemplateStatus[] = ["draft", "published", "retired"];
const INSTANCE_STATUSES: readonly JobInstanceStatus[] = ["active", "paused", "archived"];

/** The run statuses after which nothing changes again. */
export const JOB_RUN_TERMINAL: ReadonlySet<JobRunStatus> = new Set<JobRunStatus>([
  "succeeded",
  "failed",
  "cancelled",
]);

/** Whether a run has ended (its stream closes, its retry is offered for `failed`). */
export function isJobRunFinished(status: JobRunStatus): boolean {
  return JOB_RUN_TERMINAL.has(status);
}

const obj = (v: unknown): Record<string, unknown> =>
  v && typeof v === "object" && !Array.isArray(v) ? (v as Record<string, unknown>) : {};

const list = <T>(v: unknown): T[] => (Array.isArray(v) ? (v as T[]) : []);

const num = (v: unknown): number => (typeof v === "number" && Number.isFinite(v) ? v : 0);

/** Usage totals from a stored usage bag (possibly `{}` or null); missing keys read 0. */
export function toJobUsage(w: Record<string, unknown> | null | undefined): JobUsage {
  const u = obj(w);
  return {
    inputTokens: num(u.inputTokens),
    outputTokens: num(u.outputTokens),
    cacheReadTokens: num(u.cacheReadTokens),
    cacheWriteTokens: num(u.cacheWriteTokens),
    reasoningTokens: num(u.reasoningTokens),
  };
}

/** A step run's log lines: the stored array, or a single string split on newlines. */
export function toJobLog(w: string[] | string | null | undefined): string[] {
  if (Array.isArray(w)) return w.filter((l): l is string => typeof l === "string");
  if (typeof w === "string") return w === "" ? [] : w.split("\n");
  return [];
}

const steps = (v: unknown): JobStep[] => list<JobStep>(v);
const inputs = (v: unknown): JobInputSpec[] => list<JobInputSpec>(v);
const defaults = (v: unknown): JobTemplateDefaults => obj(v) as JobTemplateDefaults;
const options = (v: unknown): JobOptions => obj(v) as JobOptions;

export function toJobTemplateDraft(w: JobTemplateDraftWire | null | undefined): JobTemplateDraft | null {
  if (!w) return null;
  return { steps: steps(w.steps), inputs: inputs(w.inputs), defaults: defaults(w.defaults) };
}

export const toJobTemplate = (w: JobTemplateWire): JobTemplate => ({
  id: w.id,
  key: w.key,
  name: w.name,
  description: w.description ?? "",
  status: narrow(w.status, TEMPLATE_STATUSES, "draft"),
  latestVersion: w.latestVersion ?? null,
  latestHasScript: w.latestHasScript ?? false,
  latestPublishedAt: w.latestPublishedAt ?? null,
  offeredSetIds: w.offeredSetIds ?? [],
  createdAt: w.createdAt,
  updatedAt: w.updatedAt,
  draft: toJobTemplateDraft(w.draft),
});

export const toJobTemplateVersion = (w: JobTemplateVersionWire): JobTemplateVersion => ({
  templateId: w.templateId,
  version: w.version,
  steps: steps(w.steps),
  inputs: inputs(w.inputs),
  defaults: defaults(w.defaults),
  hasScript: w.hasScript,
  publishedBy: w.publishedBy,
  publishedAt: w.publishedAt,
});

export const toJobCatalogTemplate = (w: JobCatalogTemplateWire): JobCatalogTemplate => ({
  id: w.id,
  key: w.key,
  name: w.name,
  description: w.description ?? "",
  version: w.version,
  inputs: inputs(w.inputs),
  defaults: defaults(w.defaults),
  publishedAt: w.publishedAt,
});

export const toJobInstance = (w: JobInstanceWire): JobInstance => ({
  id: w.id,
  name: w.name,
  ownerKind: w.ownerKind,
  ownerId: w.ownerId,
  templateId: w.templateId ?? null,
  templateVersion: w.templateVersion ?? null,
  steps: w.steps == null ? null : steps(w.steps),
  inputs: obj(w.inputs),
  environmentId: w.environmentId ?? null,
  options: options(w.options),
  status: narrow(w.status, INSTANCE_STATUSES, "active"),
  createdAt: w.createdAt,
  updatedAt: w.updatedAt,
});

export const toJobRunStarted = (w: JobRunStartedWire): JobRunStarted => ({
  runId: w.runId,
  status: w.status === "failed" ? "failed" : "running",
  errorCode: w.errorCode ?? null,
  error: w.error ?? null,
});

export const toJobTrigger = (w: JobTriggerWire): JobTrigger => ({
  id: w.id,
  instanceId: w.instanceId,
  kind: w.kind,
  cron: w.cron ?? null,
  timeZone: w.timeZone ?? null,
  eventTypes: w.eventTypes ?? [],
  enabled: w.enabled,
  nextFireAt: w.nextFireAt ?? null,
  lastFiredAt: w.lastFiredAt ?? null,
  createdAt: w.createdAt,
  updatedAt: w.updatedAt,
});

/** A trigger create's answer, with the once-shown inbound secret split from the row. */
export const toCreatedJobTrigger = (w: JobTriggerWire): CreatedJobTrigger => ({
  trigger: toJobTrigger(w),
  secret: typeof w.secret === "string" && w.secret !== "" ? w.secret : null,
});

export const toJobRun = (w: JobRunWire): JobRun => ({
  id: w.id,
  instanceId: w.instanceId,
  triggerId: w.triggerId ?? null,
  status: narrow(w.status, RUN_STATUSES, "queued"),
  currentStep: w.currentStep ?? null,
  usage: toJobUsage(w.usage),
  errorCode: w.errorCode ?? null,
  error: w.error ?? null,
  startedAt: w.startedAt ?? null,
  finishedAt: w.finishedAt ?? null,
  createdAt: w.createdAt,
  updatedAt: w.updatedAt,
});

export const toJobStepRun = (w: JobStepRunWire): JobStepRun => ({
  id: w.id,
  position: w.position,
  stepId: w.stepId,
  kind: w.kind,
  status: narrow(w.status, STEP_RUN_STATUSES, "pending"),
  attempts: w.attempts ?? 0,
  output: w.output ?? null,
  log: toJobLog(w.log),
  usage: toJobUsage(w.usage),
  errorCode: w.errorCode ?? null,
  error: w.error ?? null,
  startedAt: w.startedAt ?? null,
  finishedAt: w.finishedAt ?? null,
});

export const toJobRunDetail = (w: JobRunDetailWire): JobRunDetail => ({
  ...toJobRun(w),
  stepRuns: (w.stepRuns ?? []).map(toJobStepRun).sort((a, b) => a.position - b.position),
});

export const toJobRunPage = (w: JobRunListWire): JobRunPage => ({
  runs: (w.runs ?? []).map(toJobRun),
  nextBefore: w.nextBefore ?? null,
});

export const toJobEnvironment = (w: JobEnvironmentWire): JobEnvironment => ({
  id: w.id,
  name: w.name,
  kind: "machine",
  capabilities: obj(w.capabilities),
  lastSeenAt: w.lastSeenAt ?? null,
  createdAt: w.createdAt,
  updatedAt: w.updatedAt,
});

/** An environment create or mint, with the once-shown token split from the row. */
export const toJobEnvironmentWithToken = (w: JobEnvironmentWithTokenWire): JobEnvironmentWithToken => {
  const { token, ...env } = w;
  return { environment: toJobEnvironment(env), token };
};

export const toJobRunStatusRow = (w: JobRunStatusWire): JobRunStatusRow => ({
  runId: w.runId,
  jobId: w.jobId,
  jobName: w.jobName,
  templateKey: w.templateKey ?? null,
  ownerId: w.ownerId,
  status: narrow(w.status, RUN_STATUSES, "queued"),
  errorCode: w.errorCode ?? null,
  error: w.error ?? null,
  startedAt: w.startedAt ?? null,
  finishedAt: w.finishedAt ?? null,
  createdAt: w.createdAt,
});

export const toJobRunStatusPage = (w: JobRunStatusListWire): JobRunStatusPage => ({
  runs: (w.runs ?? []).map(toJobRunStatusRow),
  nextBefore: w.nextBefore ?? null,
});
