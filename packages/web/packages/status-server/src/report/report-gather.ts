import { HTTPException } from 'hono/http-exception';
import { vercelConfigured, type StatusConfig } from '../config/port';
import type { LiveSnapshot } from '../monitor/live-types';
import type { IntegrationsResponse, UptimeResponse } from '../monitor/types';
import { fetchDeploymentLog } from '../routes/deploy-logs';
import { boardProblems, buildLiveSnapshot, buildSnapshot, buildUptime } from '../routes/reads';
import { defaultStaleAfterMs, type Scheduler } from '../scheduler';
import type { Storage } from '../storage/ports';
import type { DashboardSet } from '../telemetry/dashboard/dashboard-set';
import { ANALYTICS_RANGES } from '../telemetry/dashboard/ranges';
import { loadRuntimeErrorsReport } from '../telemetry/runtime-errors';
import {
  buildReport,
  newestPerTarget,
  type DeployLogTail,
  type MonitorInput,
  type ReportInputs,
  type RuntimeErrorsInput,
  type SourceRead,
} from './report-rules';
import type { ReportParams, ReportResponse } from './types';

// ---------------------------------------------------------------------------
// The report's reading half: every source in parallel, each fail-soft — a source that throws
// or hangs past its deadline becomes `{ ok: false, error }` and the report goes on without it
// (report-rules.ts turns that into coverage and a finding). The two telemetry dashboards are
// given up to `wait` seconds to finish a cold refresh, so the CLI and an MCP agent get a
// finished answer instead of a "poll me" flag; one still refreshing at the deadline is a
// coverage note, never silence.
// ---------------------------------------------------------------------------

/** What the report reads, built once in `createApp` and shared with MCP. */
export interface ReportServices {
  storage: Storage;
  config: StatusConfig;
  /** The app's one set of dashboard caches (shared with the dashboard routes). */
  dashboards: DashboardSet;
  /** The app's one integrations cache (shared with `GET /integrations`). */
  integrations: (fresh?: boolean) => Promise<IntegrationsResponse>;
  /** The monitor loop, when this process runs it. Its stale rule is THE stale rule. */
  scheduler?: Pick<Scheduler, 'lastCycleAt' | 'cycleStale'>;
}

/** The reads behind each source, as a seam: tests swap any of them. */
export interface ReportSources {
  monitorVersion: string | null;
  dashboards: DashboardSet;
  monitor(): Promise<MonitorInput>;
  live(): Promise<LiveSnapshot>;
  deployLog(id: string): Promise<DeployLogTail>;
  integrations(): Promise<IntegrationsResponse>;
  runtimeErrors(): Promise<RuntimeErrorsInput>;
  uptime(days: number): Promise<UptimeResponse>;
}

/** Failing deploys whose log `logs=1` attaches, newest first. */
export const LOG_DEPLOY_CAP = 5;
/** Lines of each log kept: the end, where a build says why it failed. */
export const LOG_TAIL_LINES = 40;
/** Each log read; they run in parallel after the deploy feed is read. */
const LOG_TIMEOUT_MS = 10_000;
/** Any one non-dashboard source. The CLI allows `wait` + 30s for the whole answer. */
const SOURCE_TIMEOUT_MS = 20_000;

export const REPORT_DEFAULTS: ReportParams = { range: '24h', days: 7, wait: 20, logs: false };

/** Validated `/report` / `get_report` params. Throws a 400 on anything out of range. */
export function parseReportParams(raw: {
  range?: string | null;
  days?: string | number | null;
  wait?: string | number | null;
  logs?: string | number | boolean | null;
}): ReportParams {
  const bad = (message: string): never => {
    throw new HTTPException(400, { message });
  };
  const int = (name: string, value: string | number | null | undefined, min: number, max: number, fallback: number): number => {
    if (value === undefined || value === null || value === '') return fallback;
    const n = typeof value === 'number' ? value : /^-?\d+$/.test(value) ? Number(value) : NaN;
    if (!Number.isInteger(n) || n < min || n > max) bad(`${name} must be an integer ${min}-${max}`);
    return n;
  };
  const range = raw.range || REPORT_DEFAULTS.range;
  if (!(ANALYTICS_RANGES as readonly string[]).includes(range)) bad(`range must be one of ${ANALYTICS_RANGES.join(', ')}`);
  let logs = REPORT_DEFAULTS.logs;
  if (raw.logs !== undefined && raw.logs !== null && raw.logs !== '') {
    if (raw.logs === true || raw.logs === 1 || raw.logs === '1') logs = true;
    else if (raw.logs === false || raw.logs === 0 || raw.logs === '0') logs = false;
    else bad('logs must be 0 or 1');
  }
  return {
    range: range as ReportParams['range'],
    days: int('days', raw.days, 1, 365, REPORT_DEFAULTS.days),
    wait: int('wait', raw.wait, 0, 60, REPORT_DEFAULTS.wait),
    logs,
  };
}

/** The last {@link LOG_TAIL_LINES} lines of a log, trailing blank lines dropped. */
export function logTail(log: string): { tail: string[]; lines: number } {
  const lines = log.replace(/\s+$/, '').split(/\r?\n/);
  if (lines.length === 1 && lines[0] === '') return { tail: [], lines: 0 };
  return { tail: lines.slice(-LOG_TAIL_LINES), lines: lines.length };
}

const message = (err: unknown): string => (err instanceof Error ? err.message : String(err));

/** `work`, or a rejection after `ms` naming what timed out. */
async function within<T>(ms: number, what: string, work: () => Promise<T>): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const deadline = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error(`${what} timed out after ${Math.round(ms / 1000)}s`)), ms);
  });
  try {
    return await Promise.race([work(), deadline]);
  } finally {
    clearTimeout(timer);
  }
}

/** A source read that never throws: its payload, or why there is none. */
async function soft<T>(ms: number, what: string, work: () => Promise<T>): Promise<SourceRead<T>> {
  try {
    return { ok: true, data: await within(ms, what, work) };
  } catch (err) {
    return { ok: false, error: message(err) };
  }
}

/** The production reads, from the app's shared services. */
export function reportSources(services: ReportServices): ReportSources {
  const { storage, config, scheduler } = services;
  return {
    monitorVersion: config.gitCommitSha,
    dashboards: services.dashboards,

    async monitor() {
      const [snapshot, problems, newestProbe] = await Promise.all([
        buildSnapshot(storage, config),
        boardProblems(storage, config),
        scheduler ? Promise.resolve(null) : storage.history.newestCheckAt(),
      ]);
      if (scheduler) {
        return { snapshot, problems, lastCycleAt: scheduler.lastCycleAt()?.toISOString() ?? null, stale: scheduler.cycleStale() };
      }
      // No loop in this process (the loop runs elsewhere): judge the newest persisted probe by
      // the same window the loop's own `cycleStale` uses.
      const staleAfterMs = defaultStaleAfterMs(config.probeIntervalSeconds * 1000);
      return {
        snapshot,
        problems,
        lastCycleAt: newestProbe?.toISOString() ?? null,
        stale: newestProbe !== null && Date.now() - newestProbe.getTime() > staleAfterMs,
      };
    },

    live: () => buildLiveSnapshot(storage, config),

    async deployLog(id) {
      try {
        const found = await fetchDeploymentLog(storage, config, id, LOG_TIMEOUT_MS);
        if (!found) return { error: 'deployment is not in the monitored feed' };
        if (found.log === null) return { error: `no build log for ${found.row.platform} (or no token)` };
        return logTail(found.log);
      } catch (err) {
        return { error: message(err) };
      }
    },

    integrations: () => services.integrations(),

    async runtimeErrors() {
      return {
        configured: vercelConfigured(config),
        report: await loadRuntimeErrorsReport(storage.telemetry.runtimeErrors),
      };
    },

    uptime: (days) => buildUptime(storage, days),
  };
}

/** Read a dashboard; if it is refreshing, wait up to `waitMs` for it and read again. */
async function settled<T extends { refreshing: boolean }>(
  read: () => T | Promise<T>,
  settle: (timeoutMs: number) => Promise<boolean>,
  waitMs: number,
): Promise<T> {
  const first = await read();
  if (!first.refreshing || waitMs <= 0) return first;
  await settle(waitMs);
  return read();
}

async function deploysWithLogs(sources: ReportSources, logs: boolean): Promise<ReportInputs['deploys']> {
  const live = await soft(SOURCE_TIMEOUT_MS, 'deploy feed', () => sources.live());
  if (!live.ok || !logs) return live.ok ? { ok: true, data: { live: live.data } } : live;
  const failing = newestPerTarget(live.data.deployments)
    .filter((d) => d.status === 'failed')
    .sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt))
    .slice(0, LOG_DEPLOY_CAP);
  const tails = await Promise.all(
    failing.map(async (d) => {
      try {
        return [d.id, await within(LOG_TIMEOUT_MS + 1_000, 'build log read', () => sources.deployLog(d.id))] as const;
      } catch (err) {
        return [d.id, { error: message(err) }] as const;
      }
    }),
  );
  return { ok: true, data: { live: live.data, logs: Object.fromEntries(tails) } };
}

export async function gatherReport(
  sources: ReportSources,
  params: ReportParams,
  now: () => Date = () => new Date(),
): Promise<ReportResponse> {
  const waitMs = params.wait * 1000;
  const [monitor, deploys, integrations, errors, runtimeErrors, analytics, uptime] = await Promise.all([
    soft(SOURCE_TIMEOUT_MS, 'monitor read', () => sources.monitor()),
    deploysWithLogs(sources, params.logs),
    soft(SOURCE_TIMEOUT_MS, 'integrations check', () => sources.integrations()),
    soft(waitMs + SOURCE_TIMEOUT_MS, 'errors dashboard', () =>
      settled(() => sources.dashboards.errors(), (ms) => sources.dashboards.settleErrors(ms), waitMs),
    ),
    soft(SOURCE_TIMEOUT_MS, 'runtime errors read', () => sources.runtimeErrors()),
    soft(waitMs + SOURCE_TIMEOUT_MS, 'analytics dashboard', () =>
      settled(
        () => sources.dashboards.analytics(params.range),
        (ms) => sources.dashboards.settleAnalytics(params.range, ms),
        waitMs,
      ),
    ),
    soft(SOURCE_TIMEOUT_MS, 'uptime read', () => sources.uptime(params.days)),
  ]);
  return buildReport({
    now: now(),
    monitorVersion: sources.monitorVersion,
    monitor,
    deploys,
    integrations,
    errors,
    runtimeErrors,
    analytics,
    uptime,
  });
}

