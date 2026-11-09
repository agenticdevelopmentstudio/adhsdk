// The processing-admin API layer at the `authedJson` boundary: every call builds the documented
// URL, method and body, and the query keys all sit under the `processing-admin` prefix.
import { beforeEach, describe, expect, it, vi } from "vitest";

const { authedJson, authedRequest, listAllV1 } = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listAllV1: vi.fn(),
}));
vi.mock("../http", () => ({ authedJson, authedRequest, listAllV1 }));

import {
  PROCESSING_ADMIN_KEY,
  clearDefaultConfigSet,
  createConfigSet,
  createWorkerToken,
  deleteConfigSet,
  deleteNode,
  getNode,
  getProcessingSettings,
  listConfigSets,
  listNodeLogs,
  listNodes,
  listWorkerTokens,
  processingKeys,
  putProcessingSettings,
  revokeWorkerToken,
  setDefaultConfigSet,
  updateConfigSet,
} from "../processing";

const BASE = "/api/v1/processing";

beforeEach(() => {
  authedJson.mockReset();
  authedRequest.mockReset();
  listAllV1.mockReset();
  listAllV1.mockResolvedValue([]);
  authedJson.mockResolvedValue({});
});

describe("config sets", () => {
  it("lists, walking the /v1 list envelope", async () => {
    await listConfigSets();
    expect(listAllV1).toHaveBeenCalledWith(`${BASE}/config_sets`);
  });

  it("creates with a POST body", async () => {
    await createConfigSet({ name: "n", model: "m", service_id: null });
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/config_sets`, {
      method: "POST",
      body: JSON.stringify({ name: "n", model: "m", service_id: null }),
    });
  });

  it("updates with a POST body", async () => {
    await updateConfigSet("abc", { name: "n", model: "m" });
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/config_sets/abc`, {
      method: "POST",
      body: JSON.stringify({ name: "n", model: "m" }),
    });
  });

  it("deletes", async () => {
    // A DELETE answers a tombstone the caller ignores, so deletes go through authedRequest.
    await deleteConfigSet("abc");
    expect(authedRequest).toHaveBeenCalledWith(`${BASE}/config_sets/abc`, { method: "DELETE" });
  });

  it("makes a set the default, and clears the default", async () => {
    await setDefaultConfigSet("abc");
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/config_sets/abc/make_default`, { method: "POST" });
    await clearDefaultConfigSet();
    expect(authedRequest).toHaveBeenCalledWith(`${BASE}/config_sets/default`, { method: "DELETE" });
  });
});

describe("nodes", () => {
  it("lists, gets and deletes", async () => {
    await listNodes();
    expect(listAllV1).toHaveBeenCalledWith(`${BASE}/nodes`);
    await getNode("n 1");
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/nodes/n%201`);
    await deleteNode("n 1");
    expect(authedRequest).toHaveBeenCalledWith(`${BASE}/nodes/n%201`, { method: "DELETE" });
  });

  it("pages logs with only the filters given", async () => {
    await listNodeLogs("n1");
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/nodes/n1/logs`);
    await listNodeLogs("n1", { level: "error", before: 40, limit: 50 });
    expect(authedJson).toHaveBeenLastCalledWith(
      `${BASE}/nodes/n1/logs?level=error&before=40&limit=50`,
    );
  });
});

describe("settings", () => {
  it("reads and writes the retention", async () => {
    await getProcessingSettings();
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/settings`);
    await putProcessingSettings({ log_retention_days: 30 });
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/settings`, {
      method: "POST",
      body: JSON.stringify({ log_retention_days: 30 }),
    });
  });
});

describe("query keys", () => {
  it("all sit under the processing-admin prefix", () => {
    const keys = [
      processingKeys.configSets(),
      processingKeys.nodes(),
      processingKeys.node("n1"),
      processingKeys.logs("n1", { level: "warn" }),
      processingKeys.settings(),
    ];
    for (const k of keys) expect(k[0]).toBe(PROCESSING_ADMIN_KEY[0]);
  });
});

describe("worker tokens", () => {
  it("lists", async () => {
    await listWorkerTokens();
    expect(listAllV1).toHaveBeenCalledWith(`${BASE}/worker_tokens`);
  });

  it("creates with a POST body", async () => {
    await createWorkerToken({ name: "railway-staging" });
    expect(authedJson).toHaveBeenCalledWith(`${BASE}/worker_tokens`, {
      method: "POST",
      body: JSON.stringify({ name: "railway-staging" }),
    });
  });

  it("revokes through authedRequest, encoding the id", async () => {
    await revokeWorkerToken("a/b");
    expect(authedRequest).toHaveBeenCalledWith(`${BASE}/worker_tokens/a%2Fb`, { method: "DELETE" });
    expect(authedJson).not.toHaveBeenCalled();
  });

  it("keys under the processing-admin prefix", () => {
    expect(processingKeys.workerTokens().slice(0, 1)).toEqual([...PROCESSING_ADMIN_KEY]);
  });
});
