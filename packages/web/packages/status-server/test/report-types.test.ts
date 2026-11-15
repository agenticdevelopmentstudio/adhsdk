import { HTTPException } from "hono/http-exception";
import { describe, expect, it } from "vitest";
import type { Problem } from "../src/board";
import type { LiveSnapshot } from "../src/monitor/live-types";
import type { ServiceStatusDTO, UptimeResponse } from "../src/monitor/types";
import { gatherReport, parseReportParams, type ReportSources } from "../src/report/report-gather";
import { buildReport, type MonitorInput, type ReportInputs, type RuntimeErrorsInput } from "../src/report/report-rules";
import { REPORT_SCHEMA, REPORT_SOURCES, SEVERITIES } from "../src/report/types";
import type { CompactSnapshot } from "../src/routes/reads";
import type { DashboardSection } from "../src/telemetry/dashboard/sectioned-dashboard";
import type {
  AnalyticsDashboardResponse,
  ErrorIssue,
  ErrorsDashboardResponse,
  ErrorsIssuesSection,
  RuntimeErrorGroup,
  RuntimeErrorsReport,
} from "../src/telemetry/dashboard/types";
import { analyticsViews, errorsViews } from "../src/telemetry/dashboard/views";

// The wire shape's invariants (the contract in src/report/types.ts), pinned through the two
// modules that produce it: report-rules (judging) and report-gather (reading and validating).

const NOW = new Date("2026-11-06T12:00:00Z");

const section = <T>(data: T | null, error: string | null = null): DashboardSection<T> => ({
  data,
  error,
  updatedAt: "2026-11-06T11:59:00Z",
});

function service(over: Partial<ServiceStatusDTO>): ServiceStatusDTO {
  return {
    slug: "hub",
    group: "g",
    name: "Hub",
    url: "https://hub.dev",
    environment: "production",
    platform: null,
    deployProject: null,
    status: "healthy",
    responseTimeMs: 10,
    statusCode: 200,
    error: null,
    lastCheckedAt: "2026-11-06T11:59:00Z",
    slow: false,
    ...over,
  };
}

function problem(over: Partial<Problem>): Problem {
  return {
    target: "vercel|prj_1|",
    source: "vercel",
    name: "zork",
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
    branch: null,
    errorText: null,
    since: "2026-11-06T10:00:00Z",
    ...over,
  };
}

const SNAPSHOT: CompactSnapshot = {
  generatedAt: "2026-11-06T11:59:00Z",
  overall: "healthy",
  services: [service({})],
  openIssues: [],
};

const MONITOR: MonitorInput = { snapshot: SNAPSHOT, problems: [], lastCycleAt: "2026-11-06T11:59:00Z", stale: false };

const LIVE: LiveSnapshot = {
  generatedAt: "2026-11-06T12:00:00Z",
  lastCycleAt: "2026-11-06T11:59:00Z",
  probeIntervalMs: 60_000,
  monitorVersion: "abc123",
  services: [],
  deployments: [],
  staleProd: [],
  providers: {
    vercel: { configured: true, ok: true },
    "cloudflare-pages": { configured: false, ok: false },
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

function errorsDashboard(over: Partial<ErrorsDashboardResponse["sections"]> = {}): ErrorsDashboardResponse {
  const sections: ErrorsDashboardResponse["sections"] = {
    issues: section({
      buckets: [],
      issues: [],
      summary: { active: 0, backlog: 0, events: 0, resolved: 0, complete: true, byType: [], newPerDay: [] },
    }),
    sites: section([]),
    detail: section({ buckets: [], days: [], errors: [], requests: [], truncated: false }),
    runtime: section<RuntimeErrorsReport>(null),
    ...over,
  };
  return {
    generatedAt: "x",
    refreshing: false,
    refreshingSources: { glitchtip: false, posthog: false },
    configured: { glitchtip: true, posthog: true, vercel: true },
    sections,
    views: errorsViews(sections, { posthog: true }),
  };
}

function analyticsDashboard(over: Partial<AnalyticsDashboardResponse["sections"]> = {}, range: "24h" | "7d" | "30d" = "24h"): AnalyticsDashboardResponse {
  const sections = {
    traffic: section({
      buckets: [],
      totals: { pageviews: 10, sessions: 4 },
      pageviews: [],
      sessions: [],
      sites: [{ host: "a.dev", pageviews: 10, sessions: 4, series: [] }],
    }),
    dimensions: section({ rows: [], truncated: false }),
    paths: section([]),
    vitals: section([]),
    health: section([]),
    vercel: section({
      buckets: [],
      projectsTotal: 2,
      projectsEnabled: 1,
      failed: 0,
      incomplete: 0,
      roster: [],
      totals: { pageviews: 7, visitors: 3 },
      pageviews: [],
      visitors: [],
      projects: [],
    }),
    ...over,
  } as AnalyticsDashboardResponse["sections"];
  return {
    generatedAt: "x",
    refreshing: false,
    range,
    configured: { posthog: true, vercel: true },
    sections,
    views: analyticsViews(sections, { posthog: true, vercel: true }),
  };
}

const RUNTIME: RuntimeErrorsInput = {
  configured: true,
  report: {
    generatedAt: "2026-11-06T11:59:00Z",
    window: "24h",
    readAt: "2026-11-06T11:50:00Z",
    complete: true,
    total: 0,
    groups: [],
  },
  failing: null,
};

const uptimeRow = (name: string, uptimePercent: number | null) =>
  ({ slug: name.toLowerCase(), name, uptimePercent, totalChecks: 10 }) as UptimeResponse["services"][number];

const uptimeOf = (...services: UptimeResponse["services"]): UptimeResponse => ({
  days: 7,
  overallUptimePercent: null,
  overallUptimeTone: "unknown",
  services,
});

const ok = <T>(data: T) => ({ ok: true as const, data });

function build(over: Partial<ReportInputs> = {}) {
  return buildReport({
    now: NOW,
    monitorVersion: "abc123",
    monitor: ok(MONITOR),
    deploys: ok({ live: LIVE }),
    integrations: ok({ generatedAt: "x", overall: "ok", checks: [], selfCheck: null }),
    errors: ok(errorsDashboard()),
    runtimeErrors: ok(RUNTIME),
    analytics: ok(analyticsDashboard()),
    uptime: ok(uptimeOf(uptimeRow("Hub", 100))),
    ...over,
  });
}

function issue(over: Partial<ErrorIssue>): ErrorIssue {
  return {
    id: "1",
    shortId: null,
    title: "Err",
    type: null,
    source: null,
    level: "error",
    count: 1,
    userCount: 1,
    firstSeen: null,
    lastSeen: null,
    release: null,
    project: "web",
    permalink: null,
    active: true,
    ...over,
  };
}

function group(over: Partial<RuntimeErrorGroup>): RuntimeErrorGroup {
  return {
    key: "k",
    project: "shop",
    deploymentId: "dpl",
    domain: "shop.dev",
    source: "serverless",
    method: "GET",
    path: "/api/cart",
    status: 500,
    level: "error",
    message: "boom",
    count: 1,
    firstSeen: "2026-11-06T10:00:00Z",
    lastSeen: "2026-11-06T11:00:00Z",
    sampleRequestId: null,
    ...over,
  };
}

const failedProblem = (id: string, createdAt: string, over: Partial<Problem> = {}) =>
  problem({ target: `vercel|p-${id}|`, name: id, deployment: { id, createdAt }, ...over });

describe("report types: the verdict, completeness and findings", () => {
  it("report-types-001: every source read with no notes and no findings is healthy and complete", () => {
    const report = build();
    expect(report.verdict).toBe("healthy");
    expect(report.complete).toBe(true);
    expect(report.counts).toEqual({ critical: 0, major: 0, minor: 0 });
  });

  it("report-types-002: a provider with no credentials is listed and does not clear complete", () => {
    const report = build();
    expect(report.coverage.deploys.unconfigured).toEqual(["cloudflare-pages"]);
    expect(report.complete).toBe(true);
  });

  it("report-types-003: a source that fails has a null section, failed coverage and a major finding", () => {
    const report = build({ uptime: { ok: false, error: "db" } });
    expect(report.sections.uptime).toBeNull();
    expect(report.coverage.uptime).toEqual({ ok: false, error: "db" });
    expect(report.findings).toContainEqual(expect.objectContaining({ severity: "major", title: "could not read uptime" }));
    expect(report.verdict).not.toBe("healthy");
  });

  it("report-types-004: a dashboard still refreshing is a coverage note and clears complete", () => {
    const report = build({ errors: ok({ ...errorsDashboard(), refreshing: true }) });
    expect(report.coverage.errors.notes).toContain("errors dashboard still refreshing at the deadline");
    expect(report.complete).toBe(false);
  });

  it("report-types-005: a critical and a minor finding list critical first and give a down verdict", () => {
    const down = problem({ target: "s", source: "http", name: "Shop", severity: "critical", state: "down" });
    const report = build({
      monitor: ok({ ...MONITOR, problems: [down] }),
      uptime: ok(uptimeOf(uptimeRow("Shop", 90))),
    });
    expect(report.findings.map((f) => f.severity)).toEqual(["critical", "minor"]);
    expect(report.verdict).toBe("down");
  });

  it("report-types-006: equal-severity findings order by source, so glitchtip precedes vercel-runtime", () => {
    const base = errorsDashboard();
    const report = build({
      errors: ok(errorsDashboard({ issues: section({ ...base.sections.issues.data!, issues: [issue({})] }) })),
      runtimeErrors: ok({ ...RUNTIME, report: { ...RUNTIME.report, total: 1, groups: [group({ status: 404 })] } }),
    });
    expect(report.findings.map((f) => [f.severity, f.source])).toEqual([
      ["minor", "glitchtip"],
      ["minor", "vercel-runtime"],
    ]);
  });

  it("report-types-014: the schema, severity and source constants, and the report's keys", () => {
    expect(REPORT_SCHEMA).toBe("status.report/1");
    expect([...SEVERITIES]).toEqual(["critical", "major", "minor"]);
    const sources = ["monitor", "deploys", "integrations", "errors", "runtimeErrors", "analytics", "uptime"];
    expect([...REPORT_SOURCES]).toEqual(sources);
    const report = build();
    expect(report.schema).toBe(REPORT_SCHEMA);
    expect(Object.keys(report.coverage)).toEqual(sources);
    expect(Object.keys(report.sections)).toEqual(sources);
  });

  it("report-types-015: a major-only report is degraded and a minor-only report is attention", () => {
    const major = build({ monitor: ok({ ...MONITOR, problems: [problem({ state: "stale", severity: "major" })] }) });
    expect(major.findings.map((f) => f.severity)).toEqual(["major"]);
    expect(major.verdict).toBe("degraded");
    const minor = build({ uptime: ok(uptimeOf(uptimeRow("Shop", 90))) });
    expect(minor.findings.map((f) => f.severity)).toEqual(["minor"]);
    expect(minor.verdict).toBe("attention");
  });

  it("report-types-016: counts total the findings by severity", () => {
    const problems = [
      problem({ target: "s", source: "http", name: "Shop", severity: "critical", state: "down" }),
      problem({ target: "a", name: "a", state: "stale", severity: "major" }),
      problem({ target: "b", name: "b", state: "stale", severity: "major" }),
    ];
    const report = build({
      monitor: ok({ ...MONITOR, problems }),
      uptime: ok(uptimeOf(uptimeRow("A", 90), uptimeRow("B", 91), uptimeRow("C", 92))),
    });
    expect(report.counts).toEqual({ critical: 1, major: 2, minor: 3 });
  });

  it("report-types-017: equal severity and source order by title", () => {
    const report = build({ uptime: ok(uptimeOf(uptimeRow("Shop", 90), uptimeRow("API", 97))) });
    expect(report.findings.map((f) => f.title)).toEqual(["API: 97.00% up over 7d", "Shop: 90.00% up over 7d"]);
  });
});

describe("report types: params", () => {
  const reject = (raw: Parameters<typeof parseReportParams>[0]): HTTPException => {
    try {
      parseReportParams(raw);
    } catch (err) {
      return err as HTTPException;
    }
    throw new Error("expected a rejection");
  };

  it("report-types-007: no params gives the defaults", () => {
    expect(parseReportParams({})).toEqual({ range: "24h", days: 7, wait: 20, logs: false });
  });

  it("report-types-008: the query's own values are read", () => {
    expect(parseReportParams({ range: "30d", days: "14", wait: "0", logs: "1" })).toEqual({
      range: "30d",
      days: 14,
      wait: 0,
      logs: true,
    });
  });

  it("report-types-009: an unknown range is a 400", () => {
    const err = reject({ range: "1y" });
    expect(err).toBeInstanceOf(HTTPException);
    expect(err.status).toBe(400);
    expect(err.message).toBe("range must be one of 24h, 7d, 30d");
  });

  it("report-types-010: logs=true is a 400", () => {
    const err = reject({ logs: "true" });
    expect(err.status).toBe(400);
    expect(err.message).toBe("logs must be 0 or 1");
  });

  it("report-types-011: out-of-range days and wait are a 400 with their own message", () => {
    for (const raw of [{ days: "0" }, { days: "366" }, { days: "1.5" }]) {
      const err = reject(raw);
      expect(err.status).toBe(400);
      expect(err.message).toBe("days must be an integer 1-365");
    }
    const wait = reject({ wait: "61" });
    expect(wait.status).toBe(400);
    expect(wait.message).toBe("wait must be an integer 0-60");
  });

  it("report-types-025: an empty string is an absent param", () => {
    expect(parseReportParams({ days: "" }).days).toBe(7);
  });
});

/** Sources that read a healthy fleet, with `failing` problems on the board. */
function sourcesWith(problems: Problem[], deployLog: ReportSources["deployLog"]): ReportSources {
  const noop = async () => ({ ...errorsDashboard() });
  return {
    monitorVersion: "v1",
    dashboards: {
      analytics: () => analyticsDashboard(),
      errors: noop,
      settleAnalytics: async () => true,
      settleErrors: async () => true,
    },
    monitor: async () => ({ ...MONITOR, problems }),
    live: async () => LIVE,
    deployLog,
    integrations: async () => ({ generatedAt: "x", overall: "ok", checks: [], selfCheck: null }),
    runtimeErrors: async () => RUNTIME,
    uptime: async () => uptimeOf(uptimeRow("Hub", 100)),
  };
}

describe("report types: the log fields on a failing deploy", () => {
  const problems = [
    failedProblem("a", "2026-11-06T10:00:00Z"),
    failedProblem("b", "2026-11-06T09:00:00Z"),
  ];
  const longLog = Array.from({ length: 60 }, (_, n) => `line ${n}`).join("\n");
  const deployLog: ReportSources["deployLog"] = async (id) => {
    if (id === "a") return { tail: longLog.split("\n").slice(-40), lines: 60 };
    return { error: "no build log" };
  };

  it("report-types-012: logs=1 gives each failing deploy a log tail of at most 40 lines or a logError", async () => {
    const report = await gatherReport(sourcesWith(problems, deployLog), { range: "24h", days: 7, wait: 0, logs: true }, () => NOW);
    const [a, b] = report.sections.deploys!.failing;
    expect(a!.logTail!.length).toBeLessThanOrEqual(40);
    expect(a!.logLines).toBe(60);
    expect(a!.logError).toBeUndefined();
    expect(b!.logError).toBe("no build log");
    expect(b!.logTail).toBeUndefined();
  });

  it("report-types-013: without logs no deploy carries a log field", async () => {
    const report = await gatherReport(sourcesWith(problems, deployLog), { range: "24h", days: 7, wait: 0, logs: false }, () => NOW);
    expect(report.sections.deploys!.failing).toHaveLength(2);
    for (const d of report.sections.deploys!.failing) {
      expect(d).not.toHaveProperty("logTail");
      expect(d).not.toHaveProperty("logLines");
      expect(d).not.toHaveProperty("logError");
    }
  });
});

describe("report types: the sections", () => {
  it("report-types-018: a failing deploy's commit and error are first lines", () => {
    const failing = failedProblem("d1", "2026-11-06T10:00:00Z", {
      commitMessage: "fix: thing\nbody line",
      errorText: "Type error\nstack line",
    });
    const report = build({ monitor: ok({ ...MONITOR, problems: [failing] }) });
    expect(report.sections.deploys!.failing[0]).toMatchObject({ commit: "fix: thing", error: "Type error" });
  });

  it("report-types-019: the monitor section counts services by status and names the unprobed", () => {
    const snapshot: CompactSnapshot = {
      ...SNAPSHOT,
      services: [service({ slug: "shop", name: "Shop", status: "down" }), service({ slug: "blog", name: "Blog", status: "unknown" })],
    };
    const report = build({ monitor: ok({ snapshot, problems: [], lastCycleAt: null, stale: false }) });
    expect(report.sections.monitor).toMatchObject({
      services: 2,
      byStatus: { down: 1, unknown: 1 },
      openIssues: 0,
      lastCycleAt: null,
      stale: false,
      unprobed: ["Blog"],
    });
  });

  it("report-types-020: failing deploys list newest first and providers carry their health", () => {
    const problems = [failedProblem("d1", "2026-11-06T09:00:00Z"), failedProblem("d2", "2026-11-06T10:00:00Z")];
    const report = build({ monitor: ok({ ...MONITOR, problems }) });
    expect(report.sections.deploys!.failing.map((d) => d.id)).toEqual(["d2", "d1"]);
    expect(report.sections.deploys!.providers.vercel).toEqual({ configured: true, ok: true });
  });

  it("report-types-021: the runtime-errors section keeps the groups, their total and the cut-short flag", () => {
    const groups = [
      group({ key: "fatal", level: "fatal", status: null }),
      ...Array.from({ length: 22 }, (_, i) => group({ key: `e${i}` })),
    ];
    const report = build({
      runtimeErrors: ok({ ...RUNTIME, report: { ...RUNTIME.report, complete: false, total: 30, groups } }),
    });
    expect(report.sections.runtimeErrors).toMatchObject({ window: "24h", complete: false, total: 30 });
    expect(report.sections.runtimeErrors!.groups).toHaveLength(23);
    expect(report.sections.runtimeErrors!.groups[0]!.level).toBe("fatal");
  });

  it("report-types-022: errors list active issues fatal first, then by count; sites by trouble; no summary when unread", () => {
    const issues = [
      issue({ id: "a", title: "A", level: "error", count: 10 }),
      issue({ id: "b", title: "B", level: "fatal", count: 3 }),
      issue({ id: "c", title: "C", level: "error", count: 50 }),
    ];
    const base = errorsDashboard();
    const sites = [
      { host: "d.dev", errors: 2, requests: 0, failures: 0, p95Ms: null },
      { host: "a.dev", errors: 3, requests: 50, failures: 2, p95Ms: null },
    ];
    const withIssues = build({
      errors: ok(errorsDashboard({ issues: section({ ...base.sections.issues.data!, issues }), sites: section(sites) })),
    });
    expect(withIssues.sections.errors!.active.map((i) => i.count)).toEqual([3, 50, 10]);
    expect(withIssues.sections.errors!.sites.map((s) => s.host)).toEqual(["a.dev", "d.dev"]);

    const unread = build({ errors: ok(errorsDashboard({ issues: section<ErrorsIssuesSection>(null), sites: section(sites) })) });
    expect(unread.sections.errors!.summary).toBeNull();
  });

  it("report-types-023: the analytics section carries the range, sites by pageviews and null vercel totals", () => {
    const traffic = section({
      buckets: [],
      totals: { pageviews: 40, sessions: 9 },
      pageviews: [],
      sessions: [],
      sites: [
        { host: "small.dev", pageviews: 10, sessions: 3, series: [] },
        { host: "big.dev", pageviews: 30, sessions: 6, series: [] },
      ],
    });
    const report = build({
      analytics: ok(analyticsDashboard({ traffic, vercel: section(null, "vercel down") } as never, "7d")),
    });
    expect(report.sections.analytics!.range).toBe("7d");
    expect(report.sections.analytics!.posthog.sites.map((s) => s.host)).toEqual(["big.dev", "small.dev"]);
    expect(report.sections.analytics!.vercel.totals).toBeNull();
  });

  it("report-types-024: the uptime section has the window, the floor and each service's figure", () => {
    const report = build({ uptime: ok(uptimeOf(uptimeRow("Shop", 97.5), uptimeRow("New", null))) });
    expect(report.sections.uptime!.days).toBe(7);
    expect(report.sections.uptime!.floor).toBe(99.5);
    expect(report.sections.uptime!.services.map((s) => s.uptimePercent)).toEqual([97.5, null]);
  });
});
