// Domain fixtures and a query-client wrapper for the pane tests.
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render } from "@testing-library/react";
import type { ReactElement } from "react";

import type {
  JobCatalogTemplate,
  JobInstance,
  JobRunDetail,
  JobStepRun,
  JobUsage,
} from "@adh-sdk/data/jobs";

export const NO_USAGE: JobUsage = {
  inputTokens: 0,
  outputTokens: 0,
  cacheReadTokens: 0,
  cacheWriteTokens: 0,
  reasoningTokens: 0,
};

export function catalogTemplate(over: Partial<JobCatalogTemplate> = {}): JobCatalogTemplate {
  return {
    id: "tpl-1",
    key: "daily-digest",
    name: "Daily digest",
    description: "A summary each morning.",
    version: 3,
    inputs: [],
    defaults: {},
    publishedAt: "2026-11-20T09:00:00.000Z",
    ...over,
  };
}

export function job(over: Partial<JobInstance> = {}): JobInstance {
  return {
    id: "job-1",
    name: "Morning digest",
    ownerKind: "user",
    ownerId: "user-1",
    templateId: "tpl-1",
    templateVersion: 3,
    steps: null,
    inputs: {},
    environmentId: null,
    options: {},
    status: "active",
    createdAt: "2026-11-20T09:00:00.000Z",
    updatedAt: "2026-11-20T09:00:00.000Z",
    ...over,
  } as JobInstance;
}

export function stepRun(over: Partial<JobStepRun> = {}): JobStepRun {
  return {
    id: "sr-1",
    position: 0,
    stepId: "summarize",
    kind: "ai",
    status: "running",
    attempts: 1,
    output: null,
    log: [],
    usage: NO_USAGE,
    errorCode: null,
    error: null,
    startedAt: "2026-11-23T09:00:00.000Z",
    finishedAt: null,
    ...over,
  };
}

export function runDetail(over: Partial<JobRunDetail> = {}): JobRunDetail {
  return {
    id: "run-1",
    instanceId: "job-1",
    triggerId: null,
    status: "running",
    currentStep: 0,
    usage: NO_USAGE,
    errorCode: null,
    error: null,
    startedAt: "2026-11-23T09:00:00.000Z",
    finishedAt: null,
    createdAt: "2026-11-23T09:00:00.000Z",
    updatedAt: "2026-11-23T09:00:00.000Z",
    stepRuns: [stepRun()],
    ...over,
  };
}

export function renderWithQuery(ui: ReactElement) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false }, mutations: { retry: false } } });
  return render(<QueryClientProvider client={client}>{ui}</QueryClientProvider>);
}
