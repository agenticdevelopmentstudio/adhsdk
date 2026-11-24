// @vitest-environment jsdom
// JobPane: an inbound trigger's secret shown once, with a confirmation on a close without copying
// (vector jobs-011), and a save refused because a step needs the hub naming that step (jobs-012).
// Mocks the jobs data client.
import { cleanup, fireEvent, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { AuthHttpError } from "@adh-sdk/auth/client";
import type { JobTrigger } from "@adh-sdk/data/jobs";

const api = vi.hoisted(() => ({
  get: vi.fn(),
  catalog: vi.fn(),
  environments: vi.fn(),
  triggers: vi.fn(),
  runs: vi.fn(),
  createTrigger: vi.fn(),
  update: vi.fn(),
}));

vi.mock("@adh-sdk/data/jobs", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@adh-sdk/data/jobs")>();
  return { ...actual, jobsApi: { ...actual.jobsApi, ...api } };
});

import { JobPane } from "../JobPane";
import { job, renderWithQuery } from "./fixtures";

const SECRET = "jtrg_once_only_secret_value";

function inbound(over: Partial<JobTrigger> = {}): JobTrigger {
  return {
    id: "trg-1",
    instanceId: "job-1",
    kind: "inbound",
    cron: null,
    timeZone: null,
    eventTypes: [],
    enabled: true,
    nextFireAt: null,
    lastFiredAt: null,
    createdAt: "2026-11-23T09:00:00.000Z",
    updatedAt: "2026-11-23T09:00:00.000Z",
    ...over,
  };
}

const ENV = {
  id: "env-1",
  name: "Studio Mac",
  kind: "machine" as const,
  capabilities: { local: true },
  lastSeenAt: null,
  createdAt: "2026-11-23T09:00:00.000Z",
  updatedAt: "2026-11-23T09:00:00.000Z",
};

beforeEach(() => {
  api.get.mockReset().mockResolvedValue(
    job({ templateId: null, templateVersion: null, steps: [{ id: "summarize", name: "Summarize", kind: "ai" }] as never }),
  );
  api.catalog.mockReset().mockResolvedValue([]);
  api.environments.mockReset().mockResolvedValue([ENV]);
  api.triggers.mockReset().mockResolvedValue([]);
  api.runs.mockReset().mockResolvedValue({ runs: [], nextBefore: null });
  api.createTrigger.mockReset();
  api.update.mockReset();
});
afterEach(cleanup);

describe("JobPane", () => {
  it("shows an inbound trigger's secret once and asks before closing it uncopied (vector jobs-011)", async () => {
    api.createTrigger.mockResolvedValue({ trigger: inbound(), secret: SECRET });
    renderWithQuery(<JobPane jobId="job-1" />);
    fireEvent.change(await screen.findByLabelText("Trigger kind"), { target: { value: "inbound" } });
    // The list read after the create carries no secret.
    api.triggers.mockResolvedValue([inbound()]);
    fireEvent.click(screen.getByRole("button", { name: "Add trigger" }));

    const field = (await screen.findByLabelText("Trigger secret")) as HTMLInputElement;
    expect(field.value).toBe(SECRET);
    expect(api.createTrigger).toHaveBeenCalledWith("job-1", { kind: "inbound" }, { workspace: undefined });

    fireEvent.click(screen.getByRole("button", { name: "Done" }));
    expect(await screen.findByText("Close without copying?")).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: "Close" }));
    await waitFor(() => expect(screen.queryByLabelText("Trigger secret")).toBeNull());
    // Shown once: nothing on the page carries it any more.
    expect(document.body.innerHTML).not.toContain(SECRET);
  });

  it("names the step a machine cannot run when the save is refused (vector jobs-012)", async () => {
    api.update.mockRejectedValue(
      new AuthHttpError(422, "A step needs the hub.", "step_needs_hub", {
        error: {
          code: "step_needs_hub",
          message: "A step needs the hub.",
          details: [{ code: "step_needs_hub", stepId: "summarize", message: "uses a provider connection" }],
        },
      }),
    );
    renderWithQuery(<JobPane jobId="job-1" />);
    await screen.findByRole("option", { name: "Studio Mac" });
    fireEvent.change(screen.getByLabelText("Runs on"), { target: { value: "env-1" } });
    fireEvent.click(screen.getByRole("button", { name: "Save" }));

    await waitFor(() =>
      expect(api.update).toHaveBeenCalledWith(
        "job-1",
        expect.objectContaining({ environmentId: "env-1" }),
        { workspace: undefined },
      ),
    );
    const refusal = await screen.findByText(/Step "summarize" needs the hub/);
    expect(refusal.textContent).toContain("summarize");
  });
});
