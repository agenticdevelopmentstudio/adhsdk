import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { pushDeployEvent, deployEventsSince, clearDeployEvents } from "../src/monitor/live-buffer";
import type { ProviderDeploy } from "../src/monitor/provider-deploy";

// Conformance vectors for status-server-monitor-live-buffer. The buffer is module-scope
// state, so every case starts and ends empty; the clock is the only thing faked.

const base = {
  id: "d",
  platform: "vercel",
  projectName: "docs-production",
} as unknown as ProviderDeploy;

function ev(id: string, over: Record<string, unknown> = {}): ProviderDeploy {
  return { ...base, ...over, id } as ProviderDeploy;
}

/** Push one event per entry of `times`, the clock reading `times[i]` at the i-th push. */
function pushAt(times: number[]): void {
  times.forEach((t, i) => {
    vi.setSystemTime(t);
    pushDeployEvent(ev(`e${i}`));
  });
}

describe("live-buffer", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    clearDeployEvents();
  });
  afterEach(() => {
    clearDeployEvents();
    vi.useRealTimers();
  });

  it("status-server-monitor-live-buffer-001 stamps the push with the clock reading, not the deploy's own time", () => {
    const deployA = ev("a", { createdAt: "2020-01-01T00:00:00.000Z" });
    vi.setSystemTime(1_700_000_000_000);
    pushDeployEvent(deployA);
    expect(deployEventsSince(0)).toEqual([{ deploy: deployA, receivedAt: 1_700_000_000_000 }]);
  });

  it("status-server-monitor-live-buffer-002 evicts the oldest entry past 200", () => {
    vi.setSystemTime(1000);
    for (let i = 0; i <= 200; i++) pushDeployEvent(ev(`d${i}`));
    const ids = deployEventsSince(0).map((b) => b.deploy.id);
    expect(ids).toHaveLength(200);
    expect(ids).toEqual(Array.from({ length: 200 }, (_, i) => `d${i + 1}`));
    expect(ids).not.toContain("d0");
  });

  it("status-server-monitor-live-buffer-003 includes the entry at exactly sinceMs", () => {
    pushAt([100, 200, 300]);
    expect(deployEventsSince(200).map((b) => b.receivedAt)).toEqual([200, 300]);
  });

  it("status-server-monitor-live-buffer-004 returns insertion order and a read does not consume", () => {
    pushAt([100, 200, 300]);
    const first = deployEventsSince(0);
    const second = deployEventsSince(0);
    expect(first.map((b) => b.receivedAt)).toEqual([100, 200, 300]);
    expect(second).toEqual(first);
  });

  it("status-server-monitor-live-buffer-005 clear empties the buffer and is idempotent", () => {
    pushAt([100, 200]);
    clearDeployEvents();
    expect(deployEventsSince(0)).toEqual([]);
    expect(() => clearDeployEvents()).not.toThrow();
    expect(deployEventsSince(0)).toHaveLength(0);
  });

  it("status-server-monitor-live-buffer-006 returns every pushed event without ownership filtering", () => {
    pushDeployEvent(ev("vc_live", { platform: "vercel", projectName: "docs-production" }));
    pushDeployEvent(ev("vc_dead", { platform: "vercel", projectName: "studio-production" }));
    expect(deployEventsSince(0).map((b) => b.deploy.id)).toEqual(["vc_live", "vc_dead"]);
  });
});
