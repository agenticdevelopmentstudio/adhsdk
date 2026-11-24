import { describe, it, expect } from "vitest";
import {
  uptimePercent,
  dayStatus,
  overallUptimePercent,
  type Counts,
  UPTIME_GOOD_PCT,
  UPTIME_WARN_PCT,
  SLOW_RESPONSE_MS,
  uptimeTone,
  isSlowResponse,
} from "../src/monitor/uptime";
import { isRealEnvDeploy, isRealEnvDeployRow } from "../src/monitor/deploy-view";
import type { DeploymentDTO } from "../src/monitor/types";

// Thresholds `/uptime` (`uptimeTone`, `overallUptimeTone`) and `/status` + `/live`
// (`slow`) publish. They used to be inlined in status-web's OverviewStats, DetailPanel and
// StatusMatrix, each with its own copy of the numbers.

describe("uptimeTone", () => {
  it("reads good at and above the good threshold", () => {
    expect(uptimeTone(100)).toBe("good");
    expect(uptimeTone(UPTIME_GOOD_PCT)).toBe("good");
  });

  it("reads warn between the warn and good thresholds", () => {
    expect(uptimeTone(UPTIME_GOOD_PCT - 0.01)).toBe("warn");
    expect(uptimeTone(UPTIME_WARN_PCT)).toBe("warn");
  });

  it("reads bad below the warn threshold", () => {
    expect(uptimeTone(UPTIME_WARN_PCT - 0.01)).toBe("bad");
    expect(uptimeTone(0)).toBe("bad");
  });

  it("no figure is unknown — never good", () => {
    expect(uptimeTone(null)).toBe("unknown");
  });

  it("keeps the dashboard's long-standing numbers", () => {
    expect([UPTIME_GOOD_PCT, UPTIME_WARN_PCT]).toEqual([99, 95]);
  });
});

describe("isSlowResponse", () => {
  it("flags a response strictly slower than the threshold", () => {
    expect(isSlowResponse(SLOW_RESPONSE_MS + 1)).toBe(true);
    expect(isSlowResponse(SLOW_RESPONSE_MS)).toBe(false);
    expect(isSlowResponse(12)).toBe(false);
  });

  it("a probe with no response time is not slow — it has no time to judge", () => {
    expect(isSlowResponse(null)).toBe(false);
  });
});

// Ported from status-web's overview.test.ts, whose copy of the rule was deleted in favour
// of this one (`monitor/deploy-view.ts`).
describe("isRealEnvDeploy", () => {
  const deploy = (o: Partial<DeploymentDTO>): DeploymentDTO =>
    ({ id: "d", platform: "vercel", environment: "production", ...o }) as DeploymentDTO;

  it("drops Vercel preview builds (environment=null) but keeps real env deploys", () => {
    expect(isRealEnvDeploy(deploy({ environment: null }))).toBe(false);
    expect(isRealEnvDeploy(deploy({ environment: "production" }))).toBe(true);
  });

  it("keeps non-Vercel deploys even with a null environment", () => {
    expect(isRealEnvDeploy(deploy({ platform: "cloudflare-pages", environment: null }))).toBe(true);
  });

  it("isRealEnvDeployRow (raw form) drops Vercel preview rows incl. empty-string env", () => {
    expect(isRealEnvDeployRow("vercel", null)).toBe(false);
    expect(isRealEnvDeployRow("vercel", "")).toBe(false);
    expect(isRealEnvDeployRow("vercel", "production")).toBe(true);
    expect(isRealEnvDeployRow("railway", null)).toBe(true);
    expect(isRealEnvDeployRow("cloudflare-pages", null)).toBe(true);
  });
});

// Conformance vectors for monitor/uptime.ts (status-server-monitor-uptime-001..015).
// Vector 013 is the existing `/uptime` route test in reads.int.test.ts, titled with its id.
const tally = (total: number, healthy: number, degraded: number, down: number): Counts => ({ total, healthy, degraded, down });

describe("uptime.ts conformance vectors", () => {
  it("status-server-monitor-uptime-001: degraded counts as up — 90 healthy + 5 degraded of 100 is 95", () => {
    expect(uptimePercent(tally(100, 90, 5, 5))).toBe(95);
  });

  it("status-server-monitor-uptime-002: a tally with no checks has no percentage (null)", () => {
    expect(uptimePercent(tally(0, 0, 0, 0))).toBeNull();
  });

  it("status-server-monitor-uptime-003: 2 of 3 up rounds to two decimals (66.67)", () => {
    expect(uptimePercent(tally(3, 1, 1, 1))).toBe(66.67);
  });

  it("status-server-monitor-uptime-004: a majority of down checks makes the day down", () => {
    expect(dayStatus(tally(10, 2, 0, 8))).toBe("down");
  });

  it("status-server-monitor-uptime-005: a minority of down checks makes the day degraded", () => {
    expect(dayStatus(tally(10, 7, 0, 3))).toBe("degraded");
  });

  it("status-server-monitor-uptime-006: degraded checks without any down make the day degraded", () => {
    expect(dayStatus(tally(10, 8, 2, 0))).toBe("degraded");
  });

  it("status-server-monitor-uptime-007: all healthy is healthy", () => {
    expect(dayStatus(tally(10, 10, 0, 0))).toBe("healthy");
  });

  it("status-server-monitor-uptime-008: dayStatus has no zero-total guard — an empty day falls through to healthy while uptimePercent says null", () => {
    const empty = tally(0, 0, 0, 0);
    expect(dayStatus(empty)).toBe("healthy");
    expect(uptimePercent(empty)).toBeNull();
  });

  it("status-server-monitor-uptime-009: overall uptime is the simple mean of the services' percentages", () => {
    expect(overallUptimePercent([{ uptimePercent: 100 }, { uptimePercent: 90 }])).toBe(95);
  });

  it("status-server-monitor-uptime-010: a service with no data is excluded from the mean, not counted as zero", () => {
    expect(overallUptimePercent([{ uptimePercent: 99 }, { uptimePercent: null }, { uptimePercent: 95 }])).toBe(97);
  });

  it("status-server-monitor-uptime-011: no services means no overall figure", () => {
    expect(overallUptimePercent([])).toBeNull();
  });

  it("status-server-monitor-uptime-012: only data-less services means no overall figure", () => {
    expect(overallUptimePercent([{ uptimePercent: null }])).toBeNull();
  });

  it("status-server-monitor-uptime-014: both calculations are pure — same answer every call, input never mutated", () => {
    const input = tally(10, 10, 0, 0);
    const other = tally(10, 2, 0, 8);
    for (let i = 0; i < 5; i++) {
      expect(uptimePercent(input)).toBe(100);
      expect(dayStatus(other)).toBe("down");
      expect(dayStatus(input)).toBe("healthy");
      expect(uptimePercent(other)).toBe(20);
    }
    expect(input).toEqual(tally(10, 10, 0, 0));
    expect(other).toEqual(tally(10, 2, 0, 8));
  });

  it("status-server-monitor-uptime-015: dayStatus only ever returns healthy, degraded or down", () => {
    const results = [tally(10, 2, 0, 8), tally(10, 7, 0, 3), tally(10, 8, 2, 0), tally(10, 10, 0, 0), tally(0, 0, 0, 0)].map(dayStatus);
    expect(results).toEqual(["down", "degraded", "degraded", "healthy", "healthy"]);
    for (const r of results) expect(["healthy", "degraded", "down"]).toContain(r);
  });
});
