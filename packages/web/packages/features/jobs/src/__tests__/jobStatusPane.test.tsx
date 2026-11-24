// @vitest-environment jsdom
// JobStatusPane: the product admin's table reads only the status route and shows no run content
// (vector jobs-009). Mocks the jobs data client; every other read fails the test if made.
import { cleanup, fireEvent, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import type { JobRunStatusRow } from "@adh-sdk/data/jobs";

const status = vi.hoisted(() => ({ list: vi.fn() }));
const forbidden = vi.hoisted(() => ({
  getRun: vi.fn(),
  runs: vi.fn(),
  get: vi.fn(),
  list: vi.fn(),
}));

vi.mock("@adh-sdk/data/jobs", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@adh-sdk/data/jobs")>();
  return {
    ...actual,
    jobStatusApi: { ...actual.jobStatusApi, ...status },
    jobsApi: { ...actual.jobsApi, ...forbidden },
  };
});

import { JobStatusPane } from "../JobStatusPane";
import { renderWithQuery } from "./fixtures";

const ECO = "22222222-2222-4222-8222-222222222222";

function row(over: Partial<JobRunStatusRow> = {}): JobRunStatusRow {
  return {
    runId: "run-1",
    jobId: "job-1",
    jobName: "Morning digest",
    templateKey: "daily-digest",
    ownerId: "cust-1",
    status: "failed",
    errorCode: "model_unavailable",
    error: "The model was switched off",
    startedAt: "2026-11-23T09:00:00.000Z",
    finishedAt: "2026-11-23T09:01:00.000Z",
    createdAt: "2026-11-23T09:00:00.000Z",
    ...over,
  };
}

beforeEach(() => {
  status.list.mockReset().mockResolvedValue({ runs: [row()], nextBefore: "cursor-1" });
  for (const fn of Object.values(forbidden)) fn.mockReset();
});
afterEach(cleanup);

describe("JobStatusPane (vector jobs-009)", () => {
  it("reads only the status route and shows each run's status facts", async () => {
    renderWithQuery(<JobStatusPane ecosystemId={ECO} />);
    expect(await screen.findByText("Morning digest")).toBeTruthy();
    expect(screen.getByText("daily-digest")).toBeTruthy();
    expect(screen.getByText("cust-1")).toBeTruthy();
    expect(screen.getByText("model_unavailable")).toBeTruthy();
    expect(status.list).toHaveBeenCalledWith(ECO, { before: undefined });
    for (const fn of Object.values(forbidden)) expect(fn).not.toHaveBeenCalled();
  });

  it("shows no inputs, outputs or logs", async () => {
    renderWithQuery(<JobStatusPane ecosystemId={ECO} />);
    await screen.findByText("Morning digest");
    expect(screen.queryByText(/^(Inputs|Output|Log)$/)).toBeNull();
  });

  it("loads older runs with the cursor", async () => {
    renderWithQuery(<JobStatusPane ecosystemId={ECO} />);
    await screen.findByText("Morning digest");
    status.list.mockResolvedValueOnce({ runs: [row({ runId: "run-0", jobName: "Older job" })], nextBefore: null });
    fireEvent.click(screen.getByRole("button", { name: "Load more" }));
    expect(await screen.findByText("Older job")).toBeTruthy();
    expect(screen.getByText("Morning digest")).toBeTruthy();
    await waitFor(() => expect(status.list).toHaveBeenLastCalledWith(ECO, { before: "cursor-1" }));
    for (const fn of Object.values(forbidden)) expect(fn).not.toHaveBeenCalled();
  });
});
