import { HTTPException } from "hono/http-exception";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { Problem } from "../src/board";
import type { StatusConfig } from "../src/config/port";
import { fetchDeploymentLog } from "../src/routes/deploy-logs";
import { boardProblems, buildLiveSnapshot, buildSnapshot, buildUptime } from "../src/routes/reads";
import type { Storage } from "../src/storage/ports";
import { loadRuntimeErrorsReport } from "../src/telemetry/runtime-errors";
import { buildReport } from "../src/report/report-rules";
import type { LiveDeploymentDTO, LiveSnapshot } from "../src/monitor/live-types";
import {
  gatherReport,
  LOG_DEPLOY_CAP,
  LOG_TAIL_LINES,
  logTail,
  parseReportParams,
  REPORT_DEFAULTS,
  reportSources,
  type ReportServices,
  type ReportSources,
} from "../src/report/report-gather";
import type { DashboardSet } from "../src/telemetry/dashboard/dashboard-set";
import type { AnalyticsDashboardResponse, ErrorsDashboardResponse } from "../src/telemetry/dashboard/types";
import { analyticsViews, errorsViews } from "../src/telemetry/dashboard/views";

vi.mock("../src/routes/reads", async (orig) => ({
  ...(await orig<typeof import("../src/routes/reads")>()),
  boardProblems: vi.fn(),
  buildLiveSnapshot: vi.fn(),
  buildSnapshot: vi.fn(),
  buildUptime: vi.fn(),
}));
vi.mock("../src/routes/deploy-logs", async (orig) => ({
  ...(await orig<typeof import("../src/routes/deploy-logs")>()),
  fetchDeploymentLog: vi.fn(),
}));
vi.mock("../src/telemetry/runtime-errors", async (orig) => ({
  ...(await orig<typeof import("../src/telemetry/runtime-errors")>()),
  loadRuntimeErrorsReport: vi.fn(),
}));
// A pass-through spy, so a test can read exactly what gatherReport handed to buildReport.
vi.mock("../src/report/report-rules", async (orig) => {
  const actual = await orig<typeof import("../src/report/report-rules")>();
  return { ...actual, buildReport: vi.fn(actual.buildReport) };
});

// The reading half: every source fail-soft, the dashboards given `wait` to settle, and a
// dashboard still refreshing at the deadline disclosed rather than read as healthy.

const NOW = () => new Date("2026-11-06T12:00:00Z");

function errorsDash(refreshing: boolean): ErrorsDashboardResponse {
  const sections = {
    issues: { data: null, error: null, updatedAt: null },
    sites: { data: null, error: null, updatedAt: null },
    detail: { data: null, error: null, updatedAt: null },
    runtime: { data: null, error: null, updatedAt: null },
  };
  return {
    generatedAt: "x",
    refreshing,
    refreshingSources: { glitchtip: refreshing, posthog: false },
    configured: { glitchtip: false, posthog: false, vercel: false },
    sections,
    views: errorsViews(sections, { posthog: false }),
  };
}

function analyticsDash(refreshing: boolean): AnalyticsDashboardResponse {
  const empty = { data: null, error: null, updatedAt: null };
  return {
    generatedAt: "x",
    refreshing,
    range: "24h",
    configured: { posthog: false, vercel: false },
    sections: { traffic: empty, dimensions: empty, paths: empty, vitals: empty, health: empty, vercel: empty },
    views: analyticsViews(
      { traffic: empty, dimensions: empty, paths: empty, vitals: empty, health: empty, vercel: empty },
      { posthog: false, vercel: false },
    ),
  };
}

function failed(id: string, createdAt: string): LiveDeploymentDTO {
  return {
    id,
    platform: "vercel",
    projectName: id,
    providerProjectId: `p-${id}`,
    status: "failed",
    buildPhase: null,
    deployPhase: "failed",
    environment: "production",
    tier: "production",
    commitHash: null,
    commitMessage: null,
    branch: "main",
    commitRepo: null,
    url: null,
    errorText: "boom",
    liveHost: null,
    createdAt,
    phaseConfirmedAt: createdAt,
    effectiveStatus: "failed",
  } as LiveDeploymentDTO;
}

/** The board's failed deploy problem for `failed(id, createdAt)`'s row. */
function failedProblem(id: string, createdAt: string): Problem {
  return {
    target: `vercel|p-${id}|`,
    source: "vercel",
    name: id,
    environment: "production",
    severity: "major",
    state: "failed",
    statusCode: null,
    detail: null,
    sourceUrl: null,
    liveUrl: null,
    commitHash: null,
    commitMessage: null,
    commitRepo: null,
    branch: "main",
    errorText: "boom",
    since: createdAt,
    deployment: { id, createdAt },
  };
}

/** A monitor read whose board holds these problems. */
function monitorWith(problems: Problem[]): ReportSources["monitor"] {
  return async () => ({
    snapshot: { generatedAt: "x", overall: "healthy", services: [], openIssues: [] },
    problems,
    lastCycleAt: "2026-11-06T11:59:00Z",
    stale: false,
  });
}

const LIVE: LiveSnapshot = {
  generatedAt: "x",
  lastCycleAt: "x",
  probeIntervalMs: 60_000,
  monitorVersion: "v",
  services: [],
  deployments: [],
  staleProd: [],
  providers: {
    vercel: { configured: true, ok: true },
    "cloudflare-pages": { configured: true, ok: true },
    railway: { configured: true, ok: true },
    crunchy: { configured: true, ok: true },
  },
  configDegraded: false,
  configReason: null,
  freshness: { state: "fresh", asOf: null },
  blind: false,
  platformSummary: [],
  staleMonitors: { thresholdDays: 7, monitors: [] },
};

function dashboards(over: Partial<DashboardSet> = {}): DashboardSet {
  return {
    analytics: () => analyticsDash(false),
    errors: async () => errorsDash(false),
    settleAnalytics: async () => true,
    settleErrors: async () => true,
    ...over,
  };
}

function sources(over: Partial<ReportSources> = {}): ReportSources {
  return {
    monitorVersion: "v1",
    dashboards: dashboards(),
    monitor: async () => ({
      snapshot: { generatedAt: "x", overall: "healthy", services: [], openIssues: [] },
      problems: [],
      lastCycleAt: "2026-11-06T11:59:00Z",
      stale: false,
    }),
    live: async () => LIVE,
    deployLog: async () => ({ error: "unused" }),
    integrations: async () => ({ generatedAt: "x", overall: "ok", checks: [], selfCheck: null }),
    runtimeErrors: async () => ({
      configured: false,
      report: { generatedAt: "x", window: "24h", readAt: null, complete: true, total: 0, groups: [] },
      failing: null,
    }),
    uptime: async (days) => ({ days, services: [], overallUptimePercent: null, overallUptimeTone: "unknown" }),
    ...over,
  };
}

const params = (over: Partial<typeof REPORT_DEFAULTS> = {}) => ({ ...REPORT_DEFAULTS, wait: 0, ...over });

describe("gatherReport", () => {
  it("report-gather-010: reads every source into a healthy, complete report", async () => {
    const report = await gatherReport(sources(), params(), NOW);
    expect(report.verdict).toBe("healthy");
    expect(report.complete).toBe(true);
    expect(report.monitorVersion).toBe("v1");
    expect(report.generatedAt).toBe("2026-11-06T12:00:00.000Z");
  });

  it("report-gather-011: a source that throws is uncovered, a major finding, and clears complete — the rest still read", async () => {
    const report = await gatherReport(
      sources({
        integrations: async () => {
          throw new Error("integrations exploded");
        },
      }),
      params(),
      NOW,
    );
    expect(report.coverage.integrations).toEqual({ ok: false, error: "integrations exploded" });
    expect(report.sections.integrations).toBeNull();
    expect(report.findings).toContainEqual({
      severity: "major",
      source: "report",
      title: "could not read integrations",
      detail: "integrations exploded",
    });
    expect(report.complete).toBe(false);
    expect(report.verdict).toBe("degraded");
    expect(report.coverage.uptime.ok).toBe(true);
    expect(report.sections.uptime).not.toBeNull();
  });

  it("report-gather-012: a dashboard refreshing on first read is given `wait` to settle, then read again", async () => {
    let settled = false;
    const settleErrors = vi.fn(async (ms: number) => {
      settled = true;
      return ms > 0;
    });
    const settleAnalytics = vi.fn(async () => {
      settled = true;
      return true;
    });
    const report = await gatherReport(
      sources({
        dashboards: dashboards({
          errors: async () => errorsDash(!settled),
          analytics: () => analyticsDash(!settled),
          settleErrors,
          settleAnalytics,
        }),
      }),
      params({ wait: 5, range: "7d" }),
      NOW,
    );
    expect(settleErrors).toHaveBeenCalledWith(5000);
    expect(settleAnalytics).toHaveBeenCalledWith("7d", 5000);
    expect(report.complete).toBe(true);
    expect(report.coverage.errors.notes).toBeUndefined();
  });

  it("report-gather-013: a dashboard still refreshing at the deadline is a coverage note, never silence", async () => {
    const report = await gatherReport(
      sources({
        dashboards: dashboards({ errors: async () => errorsDash(true), settleErrors: async () => false }),
      }),
      params({ wait: 1 }),
      NOW,
    );
    expect(report.coverage.errors.notes).toContain("errors dashboard still refreshing at the deadline");
    expect(report.complete).toBe(false);
    expect(report.verdict).toBe("unknown");
  });

  it("report-gather-014: wait=0 never waits on a refreshing dashboard", async () => {
    const settleAnalytics = vi.fn(async () => true);
    const report = await gatherReport(
      sources({ dashboards: dashboards({ analytics: () => analyticsDash(true), settleAnalytics }) }),
      params({ wait: 0 }),
      NOW,
    );
    expect(settleAnalytics).not.toHaveBeenCalled();
    expect(report.coverage.analytics.notes).toContain("analytics dashboard still refreshing at the deadline");
  });

  it("report-gather-015: passes `days` to the uptime read", async () => {
    const report = await gatherReport(sources(), params({ days: 30 }), NOW);
    expect(report.sections.uptime!.days).toBe(30);
  });

  it("report-gather-016: logs=1 attaches the log tail of at most five failing deploys, newest first", async () => {
    const problems = Array.from({ length: 7 }, (_, i) => failedProblem(`d${i}`, `2026-11-06T0${i}:00:00.000Z`));
    const deployLog = vi.fn(async (id: string) =>
      id === "d6" ? { error: "no build log for vercel (or no token)" } : logTail(Array.from({ length: 60 }, (_, n) => `${id} ${n}`).join("\n")),
    );
    // The feed holds none of them: the logs follow the board, not the feed.
    const report = await gatherReport(sources({ monitor: monitorWith(problems), deployLog }), params({ logs: true }), NOW);
    expect(deployLog).toHaveBeenCalledTimes(LOG_DEPLOY_CAP);
    expect(deployLog.mock.calls.map(([id]) => id)).toEqual(["d6", "d5", "d4", "d3", "d2"]);
    const failing = report.sections.deploys!.failing;
    expect(failing.map((d) => d.id)).toEqual(["d6", "d5", "d4", "d3", "d2", "d1", "d0"]);
    expect(failing[0]).toMatchObject({ logError: "no build log for vercel (or no token)" });
    expect(failing[1]!.logTail).toHaveLength(LOG_TAIL_LINES);
    expect(failing[1]!.logTail!.at(-1)).toBe("d5 59");
    expect(failing[1]!.logLines).toBe(60);
    expect(failing[6]!.logTail).toBeUndefined();
    expect(failing[6]!.logError).toBeUndefined();
  });

  it("report-gather-017: without logs no build log is read", async () => {
    const deployLog = vi.fn(async () => ({ error: "x" }));
    await gatherReport(
      sources({
        monitor: monitorWith([failedProblem("a", "2026-11-06T01:00:00Z")]),
        live: async () => ({ ...LIVE, deployments: [failed("a", "2026-11-06T01:00:00Z")] }),
        deployLog,
      }),
      params(),
      NOW,
    );
    expect(deployLog).not.toHaveBeenCalled();
  });

  it("report-gather-018: a log read that throws becomes that deploy's logError", async () => {
    const report = await gatherReport(
      sources({
        monitor: monitorWith([failedProblem("a", "2026-11-06T01:00:00Z")]),
        deployLog: async () => {
          throw new Error("socket hang up");
        },
      }),
      params({ logs: true }),
      NOW,
    );
    expect(report.sections.deploys!.failing[0]).toMatchObject({ logError: "socket hang up" });
  });
});

describe("gatherReport — deploy logs and deadlines", () => {
  afterEach(() => {
    vi.useRealTimers();
    vi.clearAllMocks();
  });

  it("report-gather-019: a failed deploy feed reads no build log and is the failed deploys read", async () => {
    const deployLog = vi.fn(async () => ({ error: "unused" }));
    vi.mocked(buildReport).mockClear();
    await gatherReport(
      sources({
        monitor: monitorWith([failedProblem("a", "2026-11-06T01:00:00Z")]),
        live: async () => {
          throw new Error("feed exploded");
        },
        deployLog,
      }),
      params({ logs: true }),
      NOW,
    );
    expect(deployLog).not.toHaveBeenCalled();
    expect(vi.mocked(buildReport).mock.calls[0]![0].deploys).toEqual({ ok: false, error: "feed exploded" });
  });

  it("report-gather-020: a source that never settles fails after 20s, a dashboard after wait + 20s", async () => {
    vi.useFakeTimers();
    const never = <T,>(): Promise<T> => new Promise<T>(() => {});
    const first = gatherReport(
      sources({
        monitor: never,
        live: never,
        integrations: never,
        runtimeErrors: never,
        uptime: never,
      }),
      params(),
      NOW,
    );
    await vi.advanceTimersByTimeAsync(20_000);
    const report = await first;
    expect(report.coverage.monitor).toEqual({ ok: false, error: "monitor read timed out after 20s" });
    expect(report.coverage.deploys).toEqual({ ok: false, error: "deploy feed timed out after 20s" });
    expect(report.coverage.integrations).toEqual({ ok: false, error: "integrations check timed out after 20s" });
    expect(report.coverage.runtimeErrors).toEqual({ ok: false, error: "runtime errors read timed out after 20s" });
    expect(report.coverage.uptime).toEqual({ ok: false, error: "uptime read timed out after 20s" });
    expect(report.coverage.analytics.ok).toBe(true);
    expect(report.schema).toBe("status.report/1");

    let done = false;
    const second = gatherReport(sources({ dashboards: dashboards({ errors: never }) }), params({ wait: 5 }), NOW).then((r) => {
      done = true;
      return r;
    });
    await vi.advanceTimersByTimeAsync(24_999);
    expect(done).toBe(false);
    await vi.advanceTimersByTimeAsync(1);
    const built = await second;
    expect(built.coverage.errors).toEqual({ ok: false, error: "errors dashboard timed out after 25s" });
    expect(built.sections.uptime).not.toBeNull();
  });

  it("report-gather-025: with the monitor read failed no build log is read and the feed is still returned", async () => {
    const deployLog = vi.fn(async () => ({ error: "unused" }));
    vi.mocked(buildReport).mockClear();
    await gatherReport(
      sources({
        monitor: async () => {
          throw new Error("monitor down");
        },
        deployLog,
      }),
      params({ logs: true }),
      NOW,
    );
    expect(deployLog).not.toHaveBeenCalled();
    expect(vi.mocked(buildReport).mock.calls[0]![0].deploys).toEqual({ ok: true, data: { live: LIVE, logs: {} } });
  });
});

describe("logTail", () => {
  it("report-gather-008: keeps the last lines and counts them all, ignoring trailing blank lines", () => {
    expect(logTail("a\nb\r\nc\n\n")).toEqual({ tail: ["a", "b", "c"], lines: 3 });
    expect(logTail("")).toEqual({ tail: [], lines: 0 });
  });

  it("report-gather-009: a 60-line log keeps 40 lines ending in the 60th and counts 60", () => {
    const log = Array.from({ length: 60 }, (_, n) => `line ${n + 1}`).join("\n");
    const out = logTail(log);
    expect("tail" in out && out.tail).toHaveLength(40);
    expect(out).toMatchObject({ lines: 60 });
    expect("tail" in out && out.tail.at(-1)).toBe("line 60");
    expect("tail" in out && out.tail[0]).toBe("line 21");
  });

  it("report-gather-027: a whitespace-only log is empty and trailing spaces are trimmed", () => {
    expect(logTail("  \n \t ")).toEqual({ tail: [], lines: 0 });
    expect(logTail("x  ")).toEqual({ tail: ["x"], lines: 1 });
  });
});

type ParamsRaw = Parameters<typeof parseReportParams>[0];

/** The 400 `parseReportParams` throws for `raw`, as [status, message]. */
function rejection(raw: ParamsRaw): [number, string] {
  try {
    parseReportParams(raw);
  } catch (err) {
    expect(err).toBeInstanceOf(HTTPException);
    return [(err as HTTPException).status, (err as HTTPException).message];
  }
  throw new Error("expected parseReportParams to throw");
}

describe("parseReportParams", () => {
  it("report-gather-001: defaults", () => {
    expect(parseReportParams({})).toEqual({ range: "24h", days: 7, wait: 20, logs: false });
    expect(parseReportParams({ range: "", days: "", wait: "", logs: "" })).toMatchObject({ days: 7, wait: 20 });
    expect(REPORT_DEFAULTS).toEqual({ range: "24h", days: 7, wait: 20, logs: false });
  });

  it("report-gather-002: accepts the CLI's query and the MCP tool's typed values", () => {
    expect(parseReportParams({ range: "30d", days: "365", wait: "0", logs: "1" })).toEqual({
      range: "30d",
      days: 365,
      wait: 0,
      logs: true,
    });
    expect(parseReportParams({ range: "7d", days: 1, wait: 60, logs: true })).toEqual({ range: "7d", days: 1, wait: 60, logs: true });
  });

  it.each(["0", "366", "1.5", "seven"])("report-gather-003: days %j is a 400", (days) => {
    expect(rejection({ days })).toEqual([400, "days must be an integer 1-365"]);
  });

  it.each([{ wait: "-1" }, { wait: 61 }])("report-gather-004: %j is a 400", (raw) => {
    expect(rejection(raw)).toEqual([400, "wait must be an integer 0-60"]);
  });

  it("report-gather-005: logs accepts 0 and 1 forms, rejects anything else", () => {
    expect(rejection({ logs: "yes" })).toEqual([400, "logs must be 0 or 1"]);
    expect(rejection({ logs: 2 })).toEqual([400, "logs must be 0 or 1"]);
    expect(parseReportParams({ logs: "0" }).logs).toBe(false);
    expect(parseReportParams({ logs: 0 }).logs).toBe(false);
    expect(parseReportParams({ logs: false }).logs).toBe(false);
    expect(parseReportParams({ logs: 1 }).logs).toBe(true);
    expect(parseReportParams({ logs: true }).logs).toBe(true);
  });

  it("report-gather-006: a range outside the allowlist is a 400", () => {
    expect(rejection({ range: "1y" })).toEqual([400, "range must be one of 24h, 7d, 30d"]);
  });

  it("report-gather-007: the range message wins over the days message", () => {
    expect(rejection({ range: "1y", days: "0" })).toEqual([400, "range must be one of 24h, 7d, 30d"]);
  });

  it("report-gather-026: the first failing field wins, in the order range, logs, days, wait", () => {
    expect(rejection({ range: "1y", logs: "yes", days: "0", wait: "99" })[1]).toBe("range must be one of 24h, 7d, 30d");
    expect(rejection({ logs: "yes", days: "0", wait: "99" })[1]).toBe("logs must be 0 or 1");
    expect(rejection({ days: "0", wait: "99" })[1]).toBe("days must be an integer 1-365");
    expect(rejection({ wait: "99" })[1]).toBe("wait must be an integer 0-60");
  });

  it("report-gather-027: integer forms are plain digits; null fields are defaults", () => {
    for (const days of ["+5", " 5", "1e1"]) {
      expect(rejection({ days })).toEqual([400, "days must be an integer 1-365"]);
    }
    expect(parseReportParams({ days: "007" }).days).toBe(7);
    expect(parseReportParams({ range: null, days: null, wait: null, logs: null })).toEqual({
      range: "24h",
      days: 7,
      wait: 20,
      logs: false,
    });
  });
});

// ---------------------------------------------------------------------------
// The production reads, with the shared reads they delegate to mocked.
// ---------------------------------------------------------------------------

const PROD_CONFIG = {
  gitCommitSha: "sha-1",
  probeIntervalSeconds: 60,
  credentials: { VERCEL_API_TOKEN: "tok" },
} as unknown as StatusConfig;

function prodServices(over: {
  newestCheckAt?: () => Promise<Date | null>;
  facts?: unknown[];
  scheduler?: ReportServices["scheduler"];
  config?: StatusConfig;
  integrations?: ReportServices["integrations"];
}) {
  const newestCheckAt = vi.fn(over.newestCheckAt ?? (async () => null));
  const storage = {
    history: { newestCheckAt },
    board: { readPlatformFacts: vi.fn(async () => over.facts ?? []) },
    telemetry: { runtimeErrors: { load: vi.fn(), lastRead: vi.fn() } },
  } as unknown as Storage;
  const services: ReportServices = {
    storage,
    config: over.config ?? PROD_CONFIG,
    dashboards: dashboards(),
    integrations: over.integrations ?? (async () => ({ generatedAt: "x", overall: "ok", checks: [], selfCheck: null })),
    ...(over.scheduler ? { scheduler: over.scheduler } : {}),
  };
  return { services, storage, newestCheckAt };
}

const SNAP = { generatedAt: "x", overall: "healthy", services: [], openIssues: [] } as never;

describe("reportSources", () => {
  afterEach(() => vi.clearAllMocks());

  it("report-gather-021: with no loop here, staleness is judged from the newest persisted probe", async () => {
    vi.mocked(buildSnapshot).mockResolvedValue(SNAP);
    vi.mocked(boardProblems).mockResolvedValue([]);
    // The probe interval is 60s, so the window is max(5 x 60s, 300s) = 5 minutes.
    const old = new Date(Date.now() - 10 * 60_000);
    const stale = await reportSources(prodServices({ newestCheckAt: async () => old }).services).monitor();
    expect(stale.stale).toBe(true);
    expect(stale.lastCycleAt).toBe(old.toISOString());

    const fresh = new Date(Date.now() - 60_000);
    expect((await reportSources(prodServices({ newestCheckAt: async () => fresh }).services).monitor()).stale).toBe(false);

    const none = await reportSources(prodServices({ newestCheckAt: async () => null }).services).monitor();
    expect(none.lastCycleAt).toBeNull();
    expect(none.stale).toBe(false);
  });

  it("report-gather-022: with a loop here, the scheduler's own rule decides and no probe is read", async () => {
    vi.mocked(buildSnapshot).mockResolvedValue(SNAP);
    vi.mocked(boardProblems).mockResolvedValue([]);
    const { services, newestCheckAt } = prodServices({
      scheduler: { lastCycleAt: () => null, cycleStale: () => true },
    });
    const out = await reportSources(services).monitor();
    expect(out).toMatchObject({ stale: true, lastCycleAt: null, problems: [] });
    expect(newestCheckAt).not.toHaveBeenCalled();

    const at = new Date("2026-11-06T11:00:00Z");
    const timed = prodServices({ scheduler: { lastCycleAt: () => at, cycleStale: () => false } });
    expect(await reportSources(timed.services).monitor()).toMatchObject({ stale: false, lastCycleAt: at.toISOString() });
  });

  it("report-gather-023: deployLog names a missing deployment or log, returns the tail, and never throws", async () => {
    const { services, storage } = prodServices({});
    const src = reportSources(services);
    const find = vi.mocked(fetchDeploymentLog);

    find.mockResolvedValueOnce(null);
    expect(await src.deployLog("d1")).toEqual({ error: "deployment is not in the monitored feed" });
    expect(find).toHaveBeenCalledWith(storage, PROD_CONFIG, "d1", 10_000);

    find.mockResolvedValueOnce({ row: { platform: "vercel" }, log: null } as never);
    expect(await src.deployLog("d1")).toEqual({ error: "no build log for vercel (or no token)" });

    find.mockResolvedValueOnce({ row: { platform: "vercel" }, log: "a\nb\n" } as never);
    expect(await src.deployLog("d1")).toEqual(logTail("a\nb\n"));

    find.mockRejectedValueOnce(new Error("boom"));
    expect(await src.deployLog("d1")).toEqual({ error: "boom" });
  });

  it("report-gather-024: runtimeErrors reports a failing vercel-runtime fact only when configured and not ok", async () => {
    const report = { generatedAt: "x", window: "24h", readAt: null, complete: true, total: 0, groups: [] };
    vi.mocked(loadRuntimeErrorsReport).mockResolvedValue(report as never);
    const fact = (over: object) => ({ source: "vercel-runtime", configured: true, ok: false, streak: 3, sampledAtMs: 99, ...over });

    const failing = await reportSources(prodServices({ facts: [fact({})] }).services).runtimeErrors();
    expect(failing).toEqual({ configured: true, report, failing: { streak: 3, atMs: 99 } });

    expect((await reportSources(prodServices({ facts: [fact({ ok: true })] }).services).runtimeErrors()).failing).toBeNull();
    expect((await reportSources(prodServices({ facts: [fact({ configured: false })] }).services).runtimeErrors()).failing).toBeNull();
    expect((await reportSources(prodServices({ facts: [] }).services).runtimeErrors()).failing).toBeNull();
    expect((await reportSources(prodServices({ facts: [fact({ source: "vercel" })] }).services).runtimeErrors()).failing).toBeNull();

    const noToken = { ...PROD_CONFIG, credentials: {} } as unknown as StatusConfig;
    expect((await reportSources(prodServices({ config: noToken }).services).runtimeErrors()).configured).toBe(false);

    expect(reportSources(prodServices({}).services).monitorVersion).toBe("sha-1");
  });

  it("report-gather-024: live, uptime and integrations are read through the shared reads", async () => {
    const live = { generatedAt: "live" } as never;
    const uptime = { days: 30 } as never;
    const integrations = { generatedAt: "int" } as never;
    vi.mocked(buildLiveSnapshot).mockResolvedValue(live);
    vi.mocked(buildUptime).mockResolvedValue(uptime);
    const { services, storage } = prodServices({ integrations: async () => integrations });
    const src = reportSources(services);
    expect(await src.live()).toBe(live);
    expect(buildLiveSnapshot).toHaveBeenCalledWith(storage, PROD_CONFIG);
    expect(await src.uptime(30)).toBe(uptime);
    expect(buildUptime).toHaveBeenCalledWith(storage, 30);
    expect(await src.integrations()).toBe(integrations);
  });
});
