// @vitest-environment jsdom
// JobRunPane: a switched-off model reads as such (vector jobs-006), Retry and Cancel by status
// (jobs-007), a live run followed until it finishes, then the stream closed (jobs-008), and a
// template job's steps named by place (jobs-016). Mocks
// the jobs data client and its stream.
import { act, cleanup, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import type { JobRun } from "@adh-sdk/data/jobs";

const api = vi.hoisted(() => ({ getRun: vi.fn(), get: vi.fn() }));
const stream = vi.hoisted(() => ({
  open: vi.fn(),
  stop: vi.fn(),
  onRun: undefined as undefined | ((run: JobRun) => void),
}));

vi.mock("@adh-sdk/data/jobs", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@adh-sdk/data/jobs")>();
  return {
    ...actual,
    jobsApi: { ...actual.jobsApi, ...api },
    streamJobRun: (runId: string, opts: { onRun: (run: JobRun) => void }) => {
      stream.open(runId);
      stream.onRun = opts.onRun;
      return stream.stop;
    },
  };
});

import { JobRunPane } from "../JobRunPane";
import { job, renderWithQuery, runDetail, stepRun } from "./fixtures";

const SUMMARIZE = { id: "summarize", name: "Summarize", kind: "ai" };

beforeEach(() => {
  api.getRun.mockReset();
  api.get.mockReset().mockResolvedValue(job({ templateId: null, steps: [SUMMARIZE] as never }));
  stream.open.mockReset();
  stream.stop.mockReset();
  stream.onRun = undefined;
});
afterEach(cleanup);

const stepRow = () => document.querySelector('[data-step-id="summarize"]') as HTMLElement;

describe("JobRunPane", () => {
  it("reads a switched-off model as such, not as the provider's message (vector jobs-006)", async () => {
    api.getRun.mockResolvedValue(
      runDetail({
        status: "failed",
        errorCode: "model_unavailable",
        error: "provider: 404 model not found",
        stepRuns: [
          stepRun({ status: "failed", errorCode: "model_unavailable", error: "provider: 404 model not found" }),
        ],
      }),
    );
    renderWithQuery(<JobRunPane runId="run-1" />);
    await screen.findByText("Summarize");
    const row = stepRow();
    expect(within(row).getByText("The model was switched off")).toBeTruthy();
    // The provider's message is kept, behind a disclosure, and is not the headline.
    const details = row.querySelector("details");
    expect(details?.textContent).toContain("provider: 404 model not found");
    expect(screen.getAllByText("The model was switched off").length).toBeGreaterThan(0);
  });

  it("offers Retry and not Cancel on a failed run (vector jobs-007)", async () => {
    api.getRun.mockResolvedValue(runDetail({ status: "failed", stepRuns: [stepRun({ status: "failed" })] }));
    renderWithQuery(<JobRunPane runId="run-1" />);
    expect(await screen.findByRole("button", { name: "Retry" })).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Cancel" })).toBeNull();
  });

  it("offers Cancel and not Retry on a running run (vector jobs-007)", async () => {
    api.getRun.mockResolvedValue(runDetail({ status: "running" }));
    renderWithQuery(<JobRunPane runId="run-1" />);
    expect(await screen.findByRole("button", { name: "Cancel" })).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Retry" })).toBeNull();
  });

  it("follows a live run, then closes the stream once it finishes (vector jobs-008)", async () => {
    const running = runDetail({ status: "running", stepRuns: [stepRun({ status: "running" })] });
    api.getRun.mockResolvedValue(running);
    renderWithQuery(<JobRunPane runId="run-1" />);
    await screen.findByText("Summarize");
    await waitFor(() => expect(stream.open).toHaveBeenCalledWith("run-1"));
    expect(within(stepRow()).getByText("running")).toBeTruthy();

    // The step succeeds: the stream reports the run, and the detail read again has the step done.
    api.getRun.mockResolvedValue(
      runDetail({ status: "running", stepRuns: [stepRun({ status: "succeeded" })] }),
    );
    act(() => stream.onRun?.(running));
    await waitFor(() => expect(within(stepRow()).getByText("succeeded")).toBeTruthy());
    expect(stream.stop).not.toHaveBeenCalled();

    // The run succeeds: the stream is closed.
    const done = runDetail({ status: "succeeded", stepRuns: [stepRun({ status: "succeeded" })] });
    api.getRun.mockResolvedValue(done);
    act(() => stream.onRun?.(done));
    await waitFor(() => expect(stream.stop).toHaveBeenCalled());
    expect(screen.queryByRole("button", { name: "Cancel" })).toBeNull();
  });

  it("names a template job's step by its place and id, not the id alone (vector jobs-016)", async () => {
    // A template job carries no steps of its own, so the pane has no name for its step runs.
    api.get.mockResolvedValue(job());
    api.getRun.mockResolvedValue(
      runDetail({ status: "succeeded", stepRuns: [stepRun({ position: 1, status: "succeeded" })] }),
    );
    renderWithQuery(<JobRunPane runId="run-1" />);
    await waitFor(() => expect(api.get).toHaveBeenCalled());
    const row = await waitFor(() => {
      const el = stepRow();
      expect(el).toBeTruthy();
      return el;
    });
    expect(within(row).getByText("Step 2")).toBeTruthy();
    expect(within(row).getByText("summarize")).toBeTruthy();
  });
});
