// Recipe: adhsdk.ingredient.adh.hub.jobs (phase 9), the mappers.
// Each wire shape is the camelCase, RFC 3339 form the unversioned `/jobs` routes answer.
import { describe, expect, it } from "vitest";

import {
  isJobRunFinished,
  toCreatedJobTrigger,
  toJobCatalogTemplate,
  toJobEnvironmentWithToken,
  toJobInstance,
  toJobLog,
  toJobPinnedVersion,
  toJobRun,
  toJobRunDetail,
  toJobRunPage,
  toJobRunStarted,
  toJobRunStatusPage,
  toJobStepRun,
  toJobTemplate,
  toJobTemplateVersion,
  toJobUsage,
} from "..";
import type {
  JobRunDetailWire,
  JobRunWire,
  JobStepRunWire,
  JobTemplateWire,
  JobTriggerWire,
} from "..";

const T0 = "2026-11-20T10:00:00.000Z";
const T1 = "2026-11-20T10:01:00.000Z";

const runWire = (over: Partial<JobRunWire> = {}): JobRunWire => ({
  id: "run-1",
  instanceId: "inst-1",
  triggerId: null,
  status: "running",
  currentStep: 0,
  usage: {},
  errorCode: null,
  error: null,
  startedAt: T0,
  finishedAt: null,
  createdAt: T0,
  updatedAt: T0,
  ...over,
});

const stepWire = (over: Partial<JobStepRunWire> = {}): JobStepRunWire => ({
  id: "sr-1",
  position: 0,
  stepId: "fetch",
  name: "Fetch",
  kind: "action",
  status: "succeeded",
  attempts: 1,
  output: { count: 2 },
  log: ["started", "done"],
  usage: {},
  errorCode: null,
  error: null,
  startedAt: T0,
  finishedAt: T1,
  ...over,
});

const templateWire = (over: Partial<JobTemplateWire> = {}): JobTemplateWire => ({
  id: "tpl-1",
  key: "daily-digest",
  name: "Daily digest",
  description: null,
  status: "draft",
  latestVersion: null,
  latestHasScript: null,
  latestPublishedAt: null,
  offeredSetIds: [],
  createdAt: T0,
  updatedAt: T0,
  draft: { steps: null, inputs: null, defaults: null },
  ...over,
});

describe("toJobRunDetail (vector jobs-010)", () => {
  it("maps a failed run with its error code and step runs in position order", () => {
    const wire: JobRunDetailWire = {
      ...runWire({
        status: "failed",
        currentStep: 1,
        errorCode: "step_failed",
        error: "the summary step failed",
        finishedAt: T1,
        usage: { inputTokens: 120, outputTokens: 40 },
      }),
      stepRuns: [
        stepWire({
          id: "sr-2",
          position: 1,
          stepId: "summarize",
          kind: "ai",
          status: "failed",
          attempts: 3,
          output: null,
          errorCode: "model_error",
          error: "upstream 500",
          usage: { inputTokens: 120, outputTokens: 40, cacheReadTokens: 8 },
        }),
        stepWire(),
      ],
    };
    const run = toJobRunDetail(wire);
    expect(run.status).toBe("failed");
    expect(run.errorCode).toBe("step_failed");
    expect(run.createdAt).toBe(T0);
    expect(run.finishedAt).toBe(T1);
    expect(run.usage).toEqual({
      inputTokens: 120,
      outputTokens: 40,
      cacheReadTokens: 0,
      cacheWriteTokens: 0,
      reasoningTokens: 0,
    });
    expect(run.stepRuns.map((s) => s.stepId)).toEqual(["fetch", "summarize"]);
    expect(run.stepRuns[1]!).toMatchObject({
      status: "failed",
      attempts: 3,
      errorCode: "model_error",
      usage: { cacheReadTokens: 8 },
    });
    expect(run.stepRuns[0]!.output).toEqual({ count: 2 });
    expect(run.stepRuns[0]!.log).toEqual(["started", "done"]);
  });

  it("reads a missing stepRuns as none", () => {
    expect(toJobRunDetail({ ...runWire(), stepRuns: null }).stepRuns).toEqual([]);
  });
});

describe("toJobStepRun (vector jobs-016)", () => {
  it("keeps the frozen step's name, and reads a step run with no name, step id or kind as such", () => {
    expect(toJobStepRun(stepWire()).name).toBe("Fetch");
    const bare = toJobStepRun(stepWire({ name: null, stepId: null, kind: null }));
    expect(bare).toMatchObject({ name: null, stepId: null, kind: "" });
  });
});

describe("toJobPinnedVersion (vector jobs-014)", () => {
  it("maps a template job's pinned version, and a missing bag as empty", () => {
    const v = toJobPinnedVersion({
      templateId: "tpl-1",
      templateVersion: 2,
      inputs: [{ key: "topic", label: "Topic", type: "string" }],
      defaults: { notify: { on: ["succeeded"] } },
      steps: [{ id: "fetch", name: "Fetch", kind: "action" }],
    });
    expect(v.templateVersion).toBe(2);
    expect(v.inputs.map((i) => i.key)).toEqual(["topic"]);
    expect(v.defaults.notify?.on).toEqual(["succeeded"]);
    expect(v.steps).toEqual([{ id: "fetch", name: "Fetch", kind: "action" }]);
    expect(
      toJobPinnedVersion({ templateId: null, templateVersion: null, inputs: null, defaults: null, steps: null }),
    ).toEqual({ templateId: null, templateVersion: null, inputs: [], defaults: {}, steps: [] });
  });
});

describe("toJobRun", () => {
  it("narrows an unknown status to queued and null bags to defaults", () => {
    const run = toJobRun(runWire({ status: "exploded" as JobRunWire["status"], usage: null }));
    expect(run.status).toBe("queued");
    expect(run.usage.inputTokens).toBe(0);
  });

  it("knows which statuses are finished", () => {
    expect(isJobRunFinished("succeeded")).toBe(true);
    expect(isJobRunFinished("failed")).toBe(true);
    expect(isJobRunFinished("cancelled")).toBe(true);
    expect(isJobRunFinished("running")).toBe(false);
    expect(isJobRunFinished("queued")).toBe(false);
  });
});

describe("toJobRunPage and toJobRunStatusPage", () => {
  it("keeps the cursor and maps each row", () => {
    const page = toJobRunPage({ runs: [runWire()], nextBefore: T0 });
    expect(page.runs).toHaveLength(1);
    expect(page.nextBefore).toBe(T0);

    const status = toJobRunStatusPage({
      runs: [
        {
          runId: "run-1",
          jobId: "inst-1",
          jobName: "Digest",
          templateKey: null,
          ownerId: "cust-1",
          status: "failed",
          errorCode: "step_failed",
          error: "x".repeat(200),
          startedAt: T0,
          finishedAt: T1,
          createdAt: T0,
        },
      ],
      nextBefore: null,
    });
    expect(status.runs[0]).toMatchObject({ jobName: "Digest", status: "failed", templateKey: null });
    expect(status.nextBefore).toBeNull();
  });
});

describe("toJobUsage and toJobLog", () => {
  it("zeroes missing and non-numeric keys", () => {
    expect(toJobUsage({ inputTokens: "3", reasoningTokens: 5 })).toEqual({
      inputTokens: 0,
      outputTokens: 0,
      cacheReadTokens: 0,
      cacheWriteTokens: 0,
      reasoningTokens: 5,
    });
    expect(toJobUsage(null).outputTokens).toBe(0);
  });

  it("reads the log as an array or a newline string", () => {
    expect(toJobLog(["a", "b"])).toEqual(["a", "b"]);
    expect(toJobLog("a\nb")).toEqual(["a", "b"]);
    expect(toJobLog("")).toEqual([]);
    expect(toJobLog(null)).toEqual([]);
  });
});

describe("toJobTemplate and its version", () => {
  it("defaults the nullable facts and the empty draft", () => {
    const t = toJobTemplate(templateWire());
    expect(t.description).toBe("");
    expect(t.latestHasScript).toBe(false);
    expect(t.offeredSetIds).toEqual([]);
    expect(t.draft).toEqual({ steps: [], inputs: [], defaults: {} });
  });

  it("keeps a null draft null", () => {
    expect(toJobTemplate(templateWire({ draft: null, status: "published" })).draft).toBeNull();
  });

  it("keeps the step and input specs as written", () => {
    const steps = [
      { id: "wait", name: "Wait", kind: "wait", delaySeconds: 120 },
      {
        id: "sum",
        name: "Summarize",
        kind: "ai",
        prompt: "Sum {{steps.fetch.output}}",
        model: { source: "connection", serviceId: "svc-1", model: "m" },
      },
    ];
    const v = toJobTemplateVersion({
      templateId: "tpl-1",
      version: 2,
      steps,
      inputs: [{ key: "label", label: "Label", type: "text", required: true }],
      defaults: { priority: 10, minIntervalMinutes: 60 },
      hasScript: false,
      publishedBy: "user-1",
      publishedAt: T1,
    });
    expect(v.steps).toEqual(steps);
    expect(v.inputs[0]!.key).toBe("label");
    expect(v.defaults).toEqual({ priority: 10, minIntervalMinutes: 60 });
  });

  it("maps a catalog template", () => {
    const c = toJobCatalogTemplate({
      id: "tpl-1",
      key: "k",
      name: "N",
      description: null,
      version: 3,
      inputs: null,
      defaults: null,
      publishedAt: T1,
    });
    expect(c).toMatchObject({ description: "", inputs: [], defaults: {}, version: 3 });
  });
});

describe("toJobInstance", () => {
  it("keeps a template job's steps null and fills the bags", () => {
    const j = toJobInstance({
      id: "inst-1",
      name: "Digest",
      ownerKind: "customer",
      ownerId: "cust-1",
      templateId: "tpl-1",
      templateVersion: 2,
      steps: null,
      inputs: null,
      environmentId: null,
      options: null,
      status: "paused",
      createdAt: T0,
      updatedAt: T0,
    });
    expect(j.steps).toBeNull();
    expect(j.inputs).toEqual({});
    expect(j.options).toEqual({});
    expect(j.status).toBe("paused");
  });
});

describe("once-shown secrets", () => {
  const triggerWire = (over: Partial<JobTriggerWire> = {}): JobTriggerWire => ({
    id: "trg-1",
    instanceId: "inst-1",
    kind: "inbound",
    cron: null,
    timeZone: null,
    eventTypes: null,
    enabled: true,
    nextFireAt: null,
    lastFiredAt: null,
    createdAt: T0,
    updatedAt: T0,
    ...over,
  });

  it("splits an inbound trigger's secret from the row", () => {
    const created = toCreatedJobTrigger(triggerWire({ secret: "jtrg_abc" }));
    expect(created.secret).toBe("jtrg_abc");
    expect(created.trigger).not.toHaveProperty("secret");
    expect(created.trigger.eventTypes).toEqual([]);
  });

  it("gives a null secret for a schedule trigger", () => {
    const created = toCreatedJobTrigger(
      triggerWire({ kind: "schedule", cron: "0 9 * * *", timeZone: "UTC" }),
    );
    expect(created.secret).toBeNull();
  });

  it("splits an environment's token from the row", () => {
    const r = toJobEnvironmentWithToken({
      id: "env-1",
      name: "Laptop",
      kind: "machine",
      capabilities: null,
      lastSeenAt: null,
      createdAt: T0,
      updatedAt: T0,
      token: "jenv_xyz",
    });
    expect(r.token).toBe("jenv_xyz");
    expect(r.environment).not.toHaveProperty("token");
    expect(r.environment.capabilities).toEqual({});
  });
});

describe("toJobRunStarted", () => {
  it("keeps a refused start's error code", () => {
    expect(
      toJobRunStarted({ runId: "run-2", status: "failed", errorCode: "step_needs_hub", error: "x" }),
    ).toEqual({ runId: "run-2", status: "failed", errorCode: "step_needs_hub", error: "x" });
  });
});
