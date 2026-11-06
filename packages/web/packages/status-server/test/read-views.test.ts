import { describe, it, expect } from "vitest";
import { selfCheckView } from "../src/monitor/self-check";
import { endpointCounts } from "../src/monitor/overall";
import { dayStatus, overallUptimePercent, uptimePercent } from "../src/monitor/uptime";
import type { IntegrationCheck } from "../src/monitor/types";

// The verdicts the read API publishes beside its raw rows — `GET /integrations` `selfCheck`,
// `GET /status` `counts`, `GET /uptime` `overallUptimePercent`. The self-check and uptime
// cases are ported from status-web, which judged these itself before they moved here.

const check = (c: Partial<IntegrationCheck> & { id: string }): IntegrationCheck => ({
  label: c.id,
  configured: true,
  ok: true,
  state: "ok",
  detail: "",
  ...c,
});

describe("selfCheckView", () => {
  it("is null when everything is ok", () => {
    expect(selfCheckView([check({ id: "stats" }), check({ id: "vercel" })])).toBeNull();
  });

  it("surfaces missing env (deduped) as a non-error warning", () => {
    const view = selfCheckView([
      check({ id: "cloudflare", state: "warn", configured: false, ok: false, missingEnv: ["CLOUDFLARE_ACCOUNT_ID"] }),
      check({ id: "vercel", state: "warn", configured: false, ok: false, missingEnv: ["VERCEL_API_TOKEN"] }),
      check({ id: "railway", state: "warn", configured: false, ok: false, missingEnv: ["VERCEL_API_TOKEN"] }),
    ]);
    expect(view).not.toBeNull();
    expect(view!.missingEnv).toEqual(["CLOUDFLARE_ACCOUNT_ID", "VERCEL_API_TOKEN"]);
    expect(view!.missingEnvError).toBe(false);
    expect(view!.hasError).toBe(false);
    expect(view!.issues).toHaveLength(0);
    expect(view!.issueCount).toBe(2);
  });

  it("an error-severity missing env goes red and counts as an error", () => {
    const view = selfCheckView([check({ id: "cloudflare", state: "error", configured: false, ok: false, missingEnv: ["CLOUDFLARE_ACCOUNT_ID"] })]);
    expect(view!.missingEnvError).toBe(true);
    expect(view!.hasError).toBe(true);
    expect(view!.issues).toHaveLength(0);
  });

  it("keeps reachability issues as chips but excludes the internal cron check", () => {
    const view = selfCheckView([
      check({ id: "cron", state: "warn", ok: false, detail: "first poll pending" }),
      check({ id: "railway", state: "error", configured: true, ok: false, detail: "HTTP 500" }),
    ]);
    expect(view!.missingEnv).toEqual([]);
    expect(view!.issues.map((c) => c.id)).toEqual(["railway"]);
    expect(view!.hasError).toBe(true);
    expect(view!.issueCount).toBe(1);
  });

  it("collapses correlated provider failures into the Connectivity chip only", () => {
    const view = selfCheckView([
      check({ id: "cloudflare", state: "warn", ok: false, correlated: true }),
      check({ id: "posthog", state: "warn", ok: false, correlated: true }),
      check({ id: "connectivity", state: "warn", ok: false, detail: "2 providers unreachable at once" }),
    ]);
    expect(view!.issues.map((c) => c.id)).toEqual(["connectivity"]);
    expect(view!.hasError).toBe(false);
  });

  it("a warning alone is not a red error", () => {
    const view = selfCheckView([check({ id: "railway", state: "warn", ok: false, detail: "slow" })]);
    expect(view!.issues.map((c) => c.id)).toEqual(["railway"]);
    expect(view!.hasError).toBe(false);
  });
});

describe("endpointCounts", () => {
  it("counts healthy as up, and an unprobed endpoint as down — never as up", () => {
    expect(endpointCounts(["healthy", "healthy", "degraded", "down", "unknown"])).toEqual({ up: 2, degraded: 1, down: 2, total: 5 });
    expect(endpointCounts([])).toEqual({ up: 0, degraded: 0, down: 0, total: 0 });
  });
});

describe("uptime math", () => {
  it("counts healthy+degraded as up, and is null with no checks", () => {
    expect(uptimePercent({ total: 100, healthy: 90, degraded: 5, down: 5 })).toBe(95);
    expect(uptimePercent({ total: 0, healthy: 0, degraded: 0, down: 0 })).toBeNull();
  });
  it("calls a day down past 50% down, degraded below it", () => {
    expect(dayStatus({ total: 10, healthy: 2, degraded: 0, down: 8 })).toBe("down");
    expect(dayStatus({ total: 10, healthy: 8, degraded: 0, down: 2 })).toBe("degraded");
    expect(dayStatus({ total: 10, healthy: 10, degraded: 0, down: 0 })).toBe("healthy");
  });
});

describe("overallUptimePercent", () => {
  it("is the simple mean of each service's uptime", () => {
    expect(overallUptimePercent([{ uptimePercent: 100 }, { uptimePercent: 90 }])).toBe(95);
  });
  it("ignores services with no data, averaging the rest", () => {
    expect(overallUptimePercent([{ uptimePercent: 99 }, { uptimePercent: null }, { uptimePercent: 95 }])).toBe(97);
  });
  it("is null when there is no data", () => {
    expect(overallUptimePercent([])).toBeNull();
    expect(overallUptimePercent([{ uptimePercent: null }])).toBeNull();
  });
});
