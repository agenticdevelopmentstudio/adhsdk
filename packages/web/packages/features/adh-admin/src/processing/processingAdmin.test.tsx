// @vitest-environment jsdom
// Conformance vectors processing-admin-001..008 (cookbook/adh/hub/admin/processing-admin).
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import type { WorkerToken } from "../api/processing";

const { authedJson, authedRequest, listAllV1 } = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listAllV1: vi.fn(),
}));
vi.mock("../api/http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../api/http")>()),
  authedJson,
  authedRequest,
  listAllV1,
}));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));

import { AiNodesPane } from "../panes/AiNodesPane";
import { ADMIN_TOPICS } from "../adminTopics";

const DEAD_URL = "/api/v1/processing/jobs?status=dead";

const token = (over: Partial<WorkerToken> = {}): WorkerToken => ({
  id: "tok-1",
  name: "edge-0",
  prefix: "tmp_ab12",
  created: 1792454400,
  expires_at: null,
  last_used_at: null,
  nodes: [],
  pool: false,
  ...over,
});

/** A dead row as the /v1 gateway serves it (declared fields snake_cased, the rest as written). */
const deadRow = (id: string, failedAt: string, over: Record<string, unknown> = {}) => ({
  object: "processing.job",
  id,
  ecosystemId: "eco-1",
  job_type: "jobs.step.ai",
  attempts: 3,
  lastError: "model timed out",
  failedAt,
  target_kind: "jobs.step_run",
  target_id: `sr-${id}`,
  created: 1792454400,
  ...over,
});

let deadRows: unknown[];

beforeEach(() => {
  deadRows = [];
  authedRequest.mockReset();
  listAllV1.mockReset();
  listAllV1.mockImplementation(async (url: string) => {
    if (url === DEAD_URL) return deadRows;
    if (url === "/api/v1/processing/worker_tokens") return [token(), token({ id: "tok-p", name: "hub-pool", pool: true })];
    return [];
  });
  authedJson.mockReset();
  authedJson.mockImplementation(async (url: string, init?: RequestInit) => {
    if (url === "/api/v1/processing/settings") return { log_retention_days: 14 };
    if (url === "/api/v1/processing/worker_tokens" && init?.method === "POST") {
      return { ...token({ id: "tok-new" }), token: "tmp_secret" };
    }
    return {};
  });
});
afterEach(cleanup);

function mount() {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  render(
    <QueryClientProvider client={client}>
      <AiNodesPane />
    </QueryClientProvider>,
  );
}

const deadSection = () => screen.findByRole("region", { name: "Dead jobs" });

describe("worker tokens: the Pool checkbox", () => {
  it("processing-admin-001: the create dialog offers an unchecked Pool checkbox", async () => {
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "New worker token" }));
    const pool = screen.getByRole("checkbox", { name: "Pool" });
    expect(pool.getAttribute("aria-checked")).toBe("false");
    // The box's own description, which the section intro above it also paraphrases.
    const description = document.getElementById(pool.getAttribute("aria-describedby") ?? "");
    expect(description?.textContent).toMatch(/claim the AI steps of jobs from every product/);
  });

  it("processing-admin-002: a checked Pool sends pool: true", async () => {
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "New worker token" }));
    fireEvent.change(screen.getByLabelText("Name"), { target: { value: "edge-1" } });
    fireEvent.click(screen.getByRole("checkbox", { name: "Pool" }));
    fireEvent.click(screen.getByRole("button", { name: "Create token" }));
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/v1/processing/worker_tokens", {
        method: "POST",
        body: JSON.stringify({ name: "edge-1", pool: true }),
      }),
    );
  });

  it("processing-admin-003: an unchecked Pool sends pool: false and a trimmed name", async () => {
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "New worker token" }));
    fireEvent.change(screen.getByLabelText("Name"), { target: { value: "  edge-2 " } });
    fireEvent.click(screen.getByRole("button", { name: "Create token" }));
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/v1/processing/worker_tokens", {
        method: "POST",
        body: JSON.stringify({ name: "edge-2", pool: false }),
      }),
    );
  });

  it("lists whether each token is a pool token, old tokens as not", async () => {
    mount();
    const section = await screen.findByRole("region", { name: "Worker tokens" });
    await within(section).findByText("hub-pool");
    expect(within(section).getAllByText("Pool").length).toBeGreaterThan(0);
    expect(within(section).getByText("Worker")).toBeTruthy();
  });
});

describe("dead jobs", () => {
  it("processing-admin-004: lists the dead rows newest first", async () => {
    deadRows = [
      deadRow("job-old", "2026-11-20 10:00:00"),
      deadRow("job-new", "2026-11-22 10:00:00", { job_type: "categorize_and_tag" }),
    ];
    mount();
    const section = await deadSection();
    const buttons = await within(section).findAllByRole("button", { name: /^Retry / });
    expect(buttons.map((b) => b.getAttribute("aria-label"))).toEqual([
      "Retry categorize_and_tag job-new",
      "Retry jobs.step.ai job-old",
    ]);
    expect(within(section).getAllByText("eco-1")).toHaveLength(2);
    expect(within(section).getAllByText("model timed out")).toHaveLength(2);
  });

  it("processing-admin-005: a successful retry calls retryDeadJob and drops the row", async () => {
    deadRows = [deadRow("job-1", "2026-11-22 10:00:00")];
    authedJson.mockImplementation(async (url: string) => {
      if (url === "/api/v1/processing/jobs/job-1/retry") {
        deadRows = [];
        return { object: "processing.job", id: "job-1", status: "queued" };
      }
      return url === "/api/v1/processing/settings" ? { log_retention_days: 14 } : {};
    });
    mount();
    const section = await deadSection();
    fireEvent.click(await within(section).findByRole("button", { name: "Retry jobs.step.ai job-1" }));
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/v1/processing/jobs/job-1/retry", { method: "POST" }),
    );
    await waitFor(() =>
      expect(within(section).queryByRole("button", { name: "Retry jobs.step.ai job-1" })).toBeNull(),
    );
  });

  it("processing-admin-006: a failed retry is shown and the row stays", async () => {
    deadRows = [deadRow("job-1", "2026-11-22 10:00:00")];
    authedJson.mockImplementation(async (url: string) => {
      if (url === "/api/v1/processing/jobs/job-1/retry") throw new Error("job is not dead");
      return url === "/api/v1/processing/settings" ? { log_retention_days: 14 } : {};
    });
    mount();
    const section = await deadSection();
    fireEvent.click(await within(section).findByRole("button", { name: "Retry jobs.step.ai job-1" }));
    expect(await within(section).findByText(/job is not dead/)).toBeTruthy();
    expect(within(section).getByRole("button", { name: "Retry jobs.step.ai job-1" })).toBeTruthy();
  });

  it("processing-admin-007: no dead rows says so", async () => {
    mount();
    const section = await deadSection();
    expect(await within(section).findByText("No dead jobs.")).toBeTruthy();
  });

  it("a row with no last error shows an em dash", async () => {
    deadRows = [deadRow("job-1", "2026-11-22 10:00:00", { lastError: null })];
    mount();
    const section = await deadSection();
    expect(await within(section).findByText("—")).toBeTruthy();
  });

  it("a failed read says it couldn't load dead jobs", async () => {
    listAllV1.mockImplementation(async (url: string) => {
      if (url === DEAD_URL) throw new Error("forbidden");
      return [];
    });
    mount();
    const section = await deadSection();
    expect(await within(section).findByText(/Couldn't load dead jobs/)).toBeTruthy();
  });
});

describe("operator admin topics", () => {
  it("processing-admin-008: no topic is labelled Jobs or Queue", () => {
    const labels = ADMIN_TOPICS.map((t) => t.label);
    expect(labels).not.toContain("Jobs");
    expect(labels).not.toContain("Queue");
  });
});
