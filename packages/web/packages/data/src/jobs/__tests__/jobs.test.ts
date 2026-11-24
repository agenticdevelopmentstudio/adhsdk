// Recipe: adhsdk.ingredient.adh.hub.jobs (phase 9), the client.
// Only the transport is stubbed, so the URL and body the client puts on the wire are asserted.
import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("../../http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../../http")>()),
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
}));

import { AuthHttpError } from "@adh-sdk/auth/client";
import { jobsApi, jobsDraftProblems, jobsErrorCode, jobStatusApi, jobTemplatesApi } from "..";
import { authedJson, authedRequest } from "../../http";

const mockedJson = vi.mocked(authedJson);
const mockedRequest = vi.mocked(authedRequest);

const T0 = "2026-11-20T10:00:00.000Z";

const templateWire = {
  id: "tpl-1",
  key: "k",
  name: "N",
  description: null,
  status: "draft",
  latestVersion: null,
  latestHasScript: null,
  latestPublishedAt: null,
  offeredSetIds: [],
  createdAt: T0,
  updatedAt: T0,
  draft: null,
};

const instanceWire = {
  id: "inst-1",
  name: "Digest",
  ownerKind: "organization",
  ownerId: "org-1",
  templateId: "tpl-1",
  templateVersion: 1,
  steps: null,
  inputs: {},
  environmentId: null,
  options: {},
  status: "active",
  createdAt: T0,
  updatedAt: T0,
};

beforeEach(() => {
  mockedJson.mockReset();
  mockedRequest.mockReset();
});

describe("authoring", () => {
  it("names the ecosystem on every call", async () => {
    mockedJson.mockResolvedValueOnce({ templates: [templateWire] });
    const list = await jobTemplatesApi.list("eco-1");
    expect(mockedJson.mock.calls[0]![0]).toBe("/api/jobs/templates?ecosystem=eco-1");
    expect(list[0]!.description).toBe("");
  });

  it("puts the offering sets", async () => {
    mockedJson.mockResolvedValueOnce(templateWire);
    await jobTemplatesApi.setOffers("eco-1", "tpl-1", ["s-1"]);
    const [url, init] = mockedJson.mock.calls[0]!;
    expect(url).toBe("/api/jobs/templates/tpl-1/offers?ecosystem=eco-1");
    expect(init).toMatchObject({ method: "PUT", body: JSON.stringify({ setIds: ["s-1"] }) });
  });

  it("reads a refused publish's draft problems", () => {
    const err = new AuthHttpError(422, "draft invalid", "draft_invalid", {
      error: {
        code: "draft_invalid",
        message: "draft invalid",
        details: { steps: [{ path: [0, "prompt"], message: "Required" }] },
      },
    });
    expect(jobsErrorCode(err)).toBe("draft_invalid");
    expect(jobsDraftProblems(err)).toEqual({
      steps: [{ path: [0, "prompt"], message: "Required" }],
      inputs: [],
      defaults: [],
    });
    expect(jobsDraftProblems(new Error("x"))).toBeNull();
  });

  it("pages the status read", async () => {
    mockedJson.mockResolvedValueOnce({ runs: [], nextBefore: null });
    await jobStatusApi.list("eco-1", { before: T0, limit: 25 });
    expect(mockedJson.mock.calls[0]![0]).toBe(
      `/api/jobs/status?ecosystem=eco-1&before=${encodeURIComponent(T0)}&limit=25`,
    );
  });
});

describe("owning", () => {
  it("scopes to a workspace when given and not otherwise", async () => {
    mockedJson.mockResolvedValue({ instances: [instanceWire] });
    await jobsApi.list();
    await jobsApi.list({ workspace: "acme" }, { status: "archived" });
    expect(mockedJson.mock.calls[0]![0]).toBe("/api/jobs/instances");
    expect(mockedJson.mock.calls[1]![0]).toBe("/api/jobs/instances?workspace=acme&status=archived");
  });

  it("archives with DELETE and returns the job", async () => {
    mockedJson.mockResolvedValueOnce({ ...instanceWire, status: "archived" });
    const j = await jobsApi.remove("inst-1");
    expect(mockedJson.mock.calls[0]![1]).toMatchObject({ method: "DELETE" });
    expect(j.status).toBe("archived");
  });

  it("deletes a trigger and an environment without a body", async () => {
    mockedRequest.mockResolvedValue(undefined);
    await jobsApi.deleteTrigger("inst-1", "trg-1");
    await jobsApi.deleteEnvironment("env-1", { workspace: "acme" });
    expect(mockedRequest.mock.calls[0]![0]).toBe("/api/jobs/instances/inst-1/triggers/trg-1");
    expect(mockedRequest.mock.calls[1]![0]).toBe("/api/jobs/environments/env-1?workspace=acme");
  });

  it("queries runs by job, status and cursor", async () => {
    mockedJson.mockResolvedValueOnce({ runs: [], nextBefore: null });
    await jobsApi.runs({ instanceId: "inst-1", status: "failed", limit: 10 });
    expect(mockedJson.mock.calls[0]![0]).toBe(
      "/api/jobs/runs?instanceId=inst-1&status=failed&limit=10",
    );
  });

  it("returns a new environment's token once and the trigger's secret once", async () => {
    mockedJson.mockResolvedValueOnce({
      id: "env-1",
      name: "Laptop",
      kind: "machine",
      capabilities: {},
      lastSeenAt: null,
      createdAt: T0,
      updatedAt: T0,
      token: "jenv_1",
    });
    const env = await jobsApi.createEnvironment("Laptop");
    expect(mockedJson.mock.calls[0]![1]).toMatchObject({
      method: "POST",
      body: JSON.stringify({ name: "Laptop" }),
    });
    expect(env.token).toBe("jenv_1");

    mockedJson.mockResolvedValueOnce({
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
      secret: "s3cret",
    });
    const t = await jobsApi.createTrigger("inst-1", { kind: "inbound" });
    expect(t.secret).toBe("s3cret");
  });
});
