// @vitest-environment jsdom
// JobPane: an inbound trigger's secret shown once, with a confirmation on a close without copying
// (vector jobs-011), a save refused because a step needs the hub naming that step (jobs-012), a job
// pinned to an older version edited against that version (jobs-014), notify defaults kept on save (jobs-015), and the runs list
// after Load more and Run now (jobs-018).
// Mocks the jobs data client.
import { cleanup, fireEvent, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { AuthHttpError } from "@adh-sdk/auth/client";
import type { JobPinnedVersion, JobTrigger } from "@adh-sdk/data/jobs";

const api = vi.hoisted(() => ({
  get: vi.fn(),
  pinnedVersion: vi.fn(),
  environments: vi.fn(),
  triggers: vi.fn(),
  runs: vi.fn(),
  createTrigger: vi.fn(),
  update: vi.fn(),
  run: vi.fn(),
}));

vi.mock("@adh-sdk/data/jobs", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@adh-sdk/data/jobs")>();
  return { ...actual, jobsApi: { ...actual.jobsApi, ...api } };
});

import { JobPane } from "../JobPane";
import { job, renderWithQuery, runDetail } from "./fixtures";

const SECRET = "jtrg_once_only_secret_value";

/** A job's pinned version, as `jobsApi.pinnedVersion` answers it. */
function pinned(over: Partial<JobPinnedVersion> = {}): JobPinnedVersion {
  return { templateId: "tpl-1", templateVersion: 1, inputs: [], defaults: {}, steps: [], ...over };
}

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
  api.pinnedVersion.mockReset().mockResolvedValue(pinned());
  api.environments.mockReset().mockResolvedValue([ENV]);
  api.triggers.mockReset().mockResolvedValue([]);
  api.runs.mockReset().mockResolvedValue({ runs: [], nextBefore: null });
  api.createTrigger.mockReset();
  api.update.mockReset();
  api.run.mockReset();
});

/** The patch the latest save sent. */
const savedPatch = () => api.update.mock.calls[api.update.mock.calls.length - 1]?.[1] as Record<string, unknown>;

const checkbox = (name: string) => screen.getByRole("checkbox", { name });
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

  it("edits a job pinned to an older version against that version's inputs (vector jobs-014)", async () => {
    api.get.mockResolvedValue(job({ templateVersion: 2, inputs: { topic: "old topic" } }));
    api.pinnedVersion.mockResolvedValue(
      pinned({ templateVersion: 2, inputs: [{ key: "topic", label: "Topic", type: "text" }] }),
    );
    api.update.mockResolvedValue(job());
    renderWithQuery(<JobPane jobId="job-1" />);
    expect(await screen.findByText(/runs version 2 of its template/)).toBeTruthy();
    expect(api.pinnedVersion).toHaveBeenCalledWith("job-1", { workspace: undefined });

    const topic = (await screen.findByRole("textbox", { name: "Topic" })) as HTMLInputElement;
    expect(topic.value).toBe("old topic");
    fireEvent.change(topic, { target: { value: "new topic" } });
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    await waitFor(() => expect(api.update).toHaveBeenCalled());
    expect(savedPatch().inputs).toEqual({ topic: "new topic" });
  });

  it("saves no inputs when the pinned version can't be read", async () => {
    api.get.mockResolvedValue(job({ templateVersion: 2, inputs: { topic: "old topic" } }));
    api.pinnedVersion.mockRejectedValue(
      new AuthHttpError(409, "The job's template version is gone.", "template_missing", {
        error: { code: "template_missing", message: "The job's template version is gone." },
      }),
    );
    api.update.mockResolvedValue(job());
    renderWithQuery(<JobPane jobId="job-1" />);
    await screen.findByRole("option", { name: "Studio Mac" });
    await waitFor(() => expect(screen.queryByRole("textbox", { name: "Topic" })).toBeNull());
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    await waitFor(() => expect(api.update).toHaveBeenCalled());
    expect(savedPatch()).not.toHaveProperty("inputs");
  });

  it("shows the version's notify defaults and saves notify only once changed (vector jobs-015)", async () => {
    api.get.mockResolvedValue(job({ options: {} }));
    api.pinnedVersion.mockResolvedValue(
      pinned({ templateVersion: 2, defaults: { notify: { on: ["succeeded"], channels: ["hub"] } } }),
    );
    api.update.mockResolvedValue(job());
    renderWithQuery(<JobPane jobId="job-1" />);
    await waitFor(() =>
      expect(checkbox("Notify when a run succeeded").getAttribute("aria-checked")).toBe("true"),
    );
    expect(checkbox("Notify when a run failed").getAttribute("aria-checked")).toBe("false");
    expect(checkbox("Notify by Email").getAttribute("aria-checked")).toBe("false");

    // A save that changed no notification leaves the version's defaults in force.
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    await waitFor(() => expect(api.update).toHaveBeenCalledTimes(1));
    expect(savedPatch()).not.toHaveProperty("options");

    fireEvent.click(checkbox("Notify by Email"));
    fireEvent.click(screen.getByRole("button", { name: "Save" }));
    await waitFor(() => expect(api.update).toHaveBeenCalledTimes(2));
    expect(savedPatch().options).toEqual({ notify: { on: ["succeeded"], channels: ["hub", "email"] } });
  });

  it("shows a new run at the top after Load more and Run now (vector jobs-018)", async () => {
    api.runs.mockImplementation(({ before }: { before?: string }) =>
      Promise.resolve(
        before === "c1"
          ? { runs: [runDetail({ id: "run-old", status: "failed" })], nextBefore: null }
          : { runs: [runDetail({ id: "run-mid", status: "succeeded" })], nextBefore: "c1" },
      ),
    );
    renderWithQuery(<JobPane jobId="job-1" />);
    const runs = await screen.findByRole("region", { name: "Runs" });
    fireEvent.click(await within(runs).findByRole("button", { name: "Load more" }));
    await waitFor(() => expect(within(runs).getAllByRole("listitem")).toHaveLength(2));

    // A run is started: the newest page now begins with it, and the list is read again from there.
    api.runs.mockImplementation(({ before }: { before?: string }) =>
      Promise.resolve(
        before === "c1"
          ? { runs: [runDetail({ id: "run-old", status: "failed" })], nextBefore: null }
          : {
              runs: [runDetail({ id: "run-new", status: "queued" }), runDetail({ id: "run-mid", status: "succeeded" })],
              nextBefore: "c1",
            },
      ),
    );
    api.run.mockResolvedValue({ runId: "run-new" });
    fireEvent.click(screen.getByRole("button", { name: "Run now" }));
    await waitFor(() => expect(within(runs).getAllByRole("listitem")).toHaveLength(3));
    const [newest] = within(runs).getAllByRole("listitem");
    expect(within(newest!).getByText("queued")).toBeTruthy();
  });
});
