// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import type { NodeLog, ProcessingNode, WorkerToken } from "../api/processing";

const { authedJson, authedRequest, listAllV1 } = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listAllV1: vi.fn(),
}));
// Keep the real pure helpers (`unixToIso`, ...); only the network edge is replaced.
vi.mock("../api/http", async (importOriginal) => ({
  ...(await importOriginal<typeof import("../api/http")>()),
  authedJson,
  authedRequest,
  listAllV1,
}));
vi.mock("next/navigation", () => ({ useRouter: () => ({ push: vi.fn() }) }));

import { AiNodesPane } from "./AiNodesPane";

const node = (over: Partial<ProcessingNode>): ProcessingNode => ({
  id: "node-a",
  kind: "typescript",
  version: "1.2.3",
  host: "box-a",
  providers: ["local", "openai"],
  config: { pollIntervalMs: 2000, model: "llama3.2" },
  online: true,
  first_seen_at: "2026-10-01T00:00:00Z",
  last_seen_at: new Date().toISOString(),
  jobs_completed: 12,
  jobs_failed: 3,
  ...over,
});

const log = (id: number, over: Partial<NodeLog> = {}): NodeLog => ({
  id,
  node_id: "node-a",
  occurred_at: "2026-10-21T10:00:00Z",
  received_at: "2026-10-21T10:00:01Z",
  level: "info",
  event: "job.claimed",
  message: `message ${id}`,
  job_id: null,
  data: null,
  ...over,
});

const workerToken = (over: Partial<WorkerToken>): WorkerToken => ({
  id: "tok-1",
  name: "railway-staging",
  prefix: "tmp_ab12",
  created: 1792454400,
  expires_at: null,
  last_used_at: null,
  nodes: [],
  ...over,
});

let logPages: Record<string, { entries: NodeLog[]; next_before: number | null }>;

beforeEach(() => {
  authedJson.mockReset();
  authedRequest.mockReset();
  authedRequest.mockResolvedValue(undefined);
  logPages = {};
  // The two collections walk the /v1 envelope in `listAllV1`; everything else is `authedJson`.
  listAllV1.mockReset();
  listAllV1.mockImplementation(async (url: string) => {
    if (url === "/api/v1/processing/nodes") {
      return [
        node({}),
        node({ id: "node-b", kind: "swift", online: false, providers: ["local"], jobs_failed: 0 }),
      ];
    }
    if (url === "/api/v1/processing/worker_tokens") {
      return [
        workerToken({ nodes: ["node-a"], last_used_at: new Date().toISOString() }),
        workerToken({ id: "tok-2", name: "laptop", prefix: "tmp_cd34" }),
      ];
    }
    return [];
  });
  authedJson.mockImplementation(async (url: string, init?: unknown) => {
    if (url === "/api/v1/processing/settings") return { log_retention_days: 14 };
    if (url === "/api/v1/processing/worker_tokens") {
      if ((init as RequestInit | undefined)?.method === "POST") {
        return { ...workerToken({ id: "tok-new", name: "railway-testing" }), token: "tmp_secretvalue" };
      }
    }
    if (url.includes("/logs")) return logPages[url] ?? { entries: [], next_before: null };
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
  return client;
}

const openNode = async (id: string) =>
  fireEvent.click(await screen.findByRole("checkbox", { name: `Select ${id}` }));

describe("AiNodesPane list", () => {
  it("shows an Online / Offline badge, kind, version, providers and job counts", async () => {
    mount();
    await screen.findByText("node-a");
    expect(screen.getByText("Online")).toBeTruthy();
    expect(screen.getByText("Offline")).toBeTruthy();
    expect(screen.getByText("swift")).toBeTruthy();
    expect(screen.getAllByText("1.2.3")).toHaveLength(2);
    expect(screen.getByText("local, openai")).toBeTruthy();
    expect(screen.getByText("12 / 3")).toBeTruthy();
  });

  it("deletes the selected node after confirmation", async () => {
    mount();
    await openNode("node-b");
    fireEvent.click(screen.getByRole("button", { name: "Delete" }));
    fireEvent.change(await screen.findByLabelText(/Type the word/), { target: { value: "delete" } });
    fireEvent.click(screen.getAllByRole("button", { name: "Delete" }).at(-1)!);
    await waitFor(() =>
      expect(authedRequest).toHaveBeenCalledWith("/api/v1/processing/nodes/node-b", {
        method: "DELETE",
      }),
    );
  });
});

describe("AiNodesPane detail", () => {
  it("shows the reported config as key/value", async () => {
    mount();
    await openNode("node-a");
    const config = await screen.findByRole("region", { name: "Reported config" });
    expect(within(config).getByText("pollIntervalMs")).toBeTruthy();
    expect(within(config).getByText("2000")).toBeTruthy();
    expect(within(config).getByText("llama3.2")).toBeTruthy();
  });

  it("refetches the logs when the level filter changes", async () => {
    mount();
    await openNode("node-a");
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/v1/processing/nodes/node-a/logs?limit=50"),
    );
    fireEvent.change(await screen.findByLabelText("Level"), { target: { value: "error" } });
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith(
        "/api/v1/processing/nodes/node-a/logs?level=error&limit=50",
      ),
    );
  });

  it("Load more pages with nextBefore, appending older entries", async () => {
    logPages["/api/v1/processing/nodes/node-a/logs?limit=50"] = {
      entries: [log(100), log(99)],
      next_before: 99,
    };
    logPages["/api/v1/processing/nodes/node-a/logs?before=99&limit=50"] = {
      entries: [log(98)],
      next_before: null,
    };
    mount();
    await openNode("node-a");
    await screen.findByText("message 100");
    fireEvent.click(screen.getByRole("button", { name: "Load more" }));
    await screen.findByText("message 98");
    expect(screen.getByText("message 100")).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Load more" })).toBeNull();
  });
});

describe("AiNodesPane node delete copy", () => {
  it("says the registry row goes and the logs stay until retention", async () => {
    mount();
    await openNode("node-b");
    fireEvent.click(screen.getByRole("button", { name: "Delete" }));
    expect(await screen.findByText(/removed from the registry/)).toBeTruthy();
    expect(screen.getByText(/logs are kept until the retention window/)).toBeTruthy();
  });
});

describe("AiNodesPane logs level label", () => {
  it("labels the filter as a minimum level", async () => {
    mount();
    await openNode("node-a");
    const level = await screen.findByLabelText("Level");
    expect(within(level).getByRole("option", { name: "warn and above" })).toBeTruthy();
  });
});

describe("AiNodesPane retention", () => {
  it("shows a failed settings read", async () => {
    const base = authedJson.getMockImplementation()!;
    authedJson.mockImplementation(async (url: string, init?: unknown) => {
      if (url === "/api/v1/processing/settings") throw new Error("settings unavailable");
      return base(url, init);
    });
    mount();
    expect(await screen.findByText("settings unavailable")).toBeTruthy();
  });

  it("does not overwrite what the admin is typing when the stored value changes", async () => {
    const client = mount();
    const input = (await screen.findByLabelText("Log retention (days)")) as HTMLInputElement;
    await waitFor(() => expect(input.value).toBe("14"));
    fireEvent.change(input, { target: { value: "99" } });
    expect(input.value).toBe("99");
    // a refetch returning a different stored value must leave the typed text alone
    authedJson.mockImplementation(async (url: string) =>
      url === "/api/v1/processing/settings" ? { log_retention_days: 20 } : {},
    );
    const calls = authedJson.mock.calls.length;
    await client.invalidateQueries({ queryKey: ["processing-admin", "settings"] });
    await waitFor(() => expect(authedJson.mock.calls.length).toBeGreaterThan(calls));
    expect(input.value).toBe("99");
  });

  it("rejects a value outside 1..365 and saves a valid one", async () => {
    mount();
    const input = (await screen.findByLabelText("Log retention (days)")) as HTMLInputElement;
    await waitFor(() => expect(input.value).toBe("14"));
    const saveBtn = screen.getByRole("button", { name: "Save retention" }) as HTMLButtonElement;

    for (const bad of ["0", "366", "1.5", ""]) {
      fireEvent.change(input, { target: { value: bad } });
      expect(saveBtn.disabled).toBe(true);
    }
    fireEvent.change(input, { target: { value: "0" } });
    expect(screen.getByText("Retention must be a whole number of days from 1 to 365.")).toBeTruthy();

    fireEvent.change(input, { target: { value: "30" } });
    expect(saveBtn.disabled).toBe(false);
    fireEvent.click(saveBtn);
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/v1/processing/settings", {
        method: "POST",
        body: JSON.stringify({ log_retention_days: 30 }),
      }),
    );
  });
});

describe("AiNodesPane worker tokens", () => {
  it("lists each token with its prefix and the nodes using it", async () => {
    mount();
    const section = await screen.findByRole("region", { name: "Worker tokens" });
    expect(await within(section).findByText("railway-staging")).toBeTruthy();
    expect(within(section).getByText("tmp_ab12…")).toBeTruthy();
    expect(within(section).getByText("node-a")).toBeTruthy();
    expect(within(section).getByText("No node yet")).toBeTruthy();
    expect(within(section).getByText("Never")).toBeTruthy();
  });

  it("creates a token and shows its value once, with the env var to set", async () => {
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "New worker token" }));
    const create = screen.getByRole("button", { name: "Create token" }) as HTMLButtonElement;
    expect(create.disabled).toBe(true);
    fireEvent.change(screen.getByLabelText("Name"), { target: { value: "  railway-testing " } });
    fireEvent.click(create);
    await waitFor(() =>
      expect(authedJson).toHaveBeenCalledWith("/api/v1/processing/worker_tokens", {
        method: "POST",
        body: JSON.stringify({ name: "railway-testing" }),
      }),
    );
    const value = (await screen.findByLabelText("Worker token")) as HTMLInputElement;
    expect(value.value).toBe("tmp_secretvalue");
    expect(screen.getByText(/Set it as AI_NODE_API_TOKEN on the node/)).toBeTruthy();

    fireEvent.click(screen.getByRole("button", { name: "Done" }));
    await waitFor(() => expect(screen.queryByLabelText("Worker token")).toBeNull());
    fireEvent.click(screen.getByRole("button", { name: "New worker token" }));
    expect(screen.queryByText("tmp_secretvalue")).toBeNull();
    expect(screen.queryByLabelText("Worker token")).toBeNull();
  });

  it("asks before an Escape throws the unseen-again value away", async () => {
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "New worker token" }));
    fireEvent.change(screen.getByLabelText("Name"), { target: { value: "x" } });
    fireEvent.click(screen.getByRole("button", { name: "Create token" }));
    const value = await screen.findByLabelText("Worker token");
    fireEvent.keyDown(value, { key: "Escape" });
    expect(await screen.findByText("Close without copying?")).toBeTruthy();
    fireEvent.click(screen.getByRole("button", { name: "Keep open" }));
    expect(screen.getByLabelText("Worker token")).toBeTruthy();
  });

  it("shows why a create failed", async () => {
    const base = authedJson.getMockImplementation()!;
    authedJson.mockImplementation(async (url: string, init?: unknown) => {
      if ((init as RequestInit | undefined)?.method === "POST") throw new Error("name is required");
      return base(url, init);
    });
    mount();
    fireEvent.click(await screen.findByRole("button", { name: "New worker token" }));
    fireEvent.change(screen.getByLabelText("Name"), { target: { value: "x" } });
    fireEvent.click(screen.getByRole("button", { name: "Create token" }));
    expect(await screen.findByText("name is required")).toBeTruthy();
  });

  it("revokes the selected token after confirmation", async () => {
    mount();
    fireEvent.click(await screen.findByRole("checkbox", { name: "Select laptop" }));
    fireEvent.click(screen.getByRole("button", { name: "Revoke" }));
    expect(await screen.findByText(/Every node using it stops getting jobs/)).toBeTruthy();
    fireEvent.click(screen.getAllByRole("button", { name: "Revoke" }).at(-1)!);
    await waitFor(() =>
      expect(authedRequest).toHaveBeenCalledWith("/api/v1/processing/worker_tokens/tok-2", {
        method: "DELETE",
      }),
    );
  });
});
