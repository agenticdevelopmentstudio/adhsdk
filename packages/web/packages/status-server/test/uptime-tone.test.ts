import { describe, it, expect } from "vitest";
import {
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
