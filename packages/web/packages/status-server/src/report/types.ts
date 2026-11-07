import type { CheckState } from '../monitor/types';
import type { ProviderKey, StaleProdDTO } from '../monitor/live-types';
import type { AnalyticsRange } from '../telemetry/dashboard/ranges';
import type {
  ErrorIssue,
  ErrorsIssuesSection,
  SiteErrorRow,
  SiteFailedRequestRow,
  SiteHealthRow,
  VitalsRow,
} from '../telemetry/dashboard/types';
import type { RuntimeErrorGroup } from '../telemetry/types';

// ---------------------------------------------------------------------------
// The wire shape of `GET /report` and the MCP tool `get_report`: one agent-ready digest of the
// whole fleet. Every judgement in it — verdict, severity, order, staleness, completeness — is
// made on the server (src/report/build.ts); a client formats and lays out, nothing more.
//
// `schema` is versioned: a change a reader must adapt to is a new `status.report/N`.
// ---------------------------------------------------------------------------

export const REPORT_SCHEMA = 'status.report/1' as const;

export const SEVERITIES = ['critical', 'major', 'minor'] as const;
export type Severity = (typeof SEVERITIES)[number];

export type ReportVerdict = 'healthy' | 'attention' | 'degraded' | 'down' | 'unknown';

/** Coverage keys, in the order the report lists them. */
export const REPORT_SOURCES = [
  'monitor',
  'deploys',
  'integrations',
  'errors',
  'runtimeErrors',
  'analytics',
  'uptime',
] as const;
export type ReportSourceId = (typeof REPORT_SOURCES)[number];

export interface SourceCoverage {
  /** The source was read at all. */
  ok: boolean;
  /** Why not, when `!ok`. */
  error?: string;
  /** Read, but partial: a failed section, stale data, still refreshing. Any note clears `complete`. */
  notes?: string[];
  /** Providers with no credentials. Disclosed; does NOT clear `complete`. */
  unconfigured?: string[];
  /** When the data behind the source was fetched, where the source knows. */
  updatedAt?: string | null;
}

export interface Finding {
  severity: Severity;
  /** Where it came from: "monitor:vercel", "provider:railway", "glitchtip", "vercel-runtime", "posthog", ... */
  source: string;
  title: string;
  /** First line only. */
  detail?: string;
  since?: string;
  /** Provider page or live URL. */
  link?: string;
  /** The key `adh-status issues show` accepts, for a finding that is an open board issue. */
  issueKey?: string;
}

export interface MonitorReportSection {
  overall: 'healthy' | 'degraded' | 'down';
  checkedAt: string;
  /** When the monitor loop last completed a cycle (the newest probe when no loop runs here). */
  lastCycleAt: string | null;
  /** The scheduler's own stale rule tripped. */
  stale: boolean;
  services: number;
  byStatus: Record<string, number>;
  openIssues: number;
  /** Services with no probe yet, by name. */
  unprobed: string[];
}

export interface FailingDeploy {
  id: string;
  platform: string;
  project: string;
  tier: string | null;
  branch: string | null;
  createdAt: string;
  /** First line of the commit message. */
  commit: string | null;
  /** First line of the provider's failure text. */
  error: string | null;
  url: string | null;
  /** With `logs=1`: the last lines of the build log. */
  logTail?: string[];
  /** With `logs=1`: how many lines the whole log has. */
  logLines?: number;
  /** With `logs=1`: why there is no tail (no log for this platform, or the read failed). */
  logError?: string;
}

export interface DeploysReportSection {
  /** Deploy targets (platform, project, tier) seen in the monitored feed. */
  deployTargets: number;
  /** Targets whose newest deploy is building or queued. */
  inFlight: number;
  /** Targets whose NEWEST deploy failed, newest first. A failure fixed by a later build is not here. */
  failing: FailingDeploy[];
  staleProd: StaleProdDTO[];
  providers: Record<ProviderKey, { configured: boolean; ok: boolean }>;
}

export interface IntegrationsReportSection {
  overall: CheckState;
  checks: { id: string; label: string; configured: boolean; state: CheckState; detail: string | null }[];
}

export interface ErrorsReportSection {
  /** GlitchTip's issue summary; null when the issue list has never been read. */
  summary: ErrorsIssuesSection['summary'] | null;
  /** Active GlitchTip issues, fatal first, then by event count. */
  active: ErrorIssue[];
  /** PostHog per-site health, most errors+failures first. */
  sites: SiteHealthRow[];
  siteErrors: SiteErrorRow[];
  failedRequests: SiteFailedRequestRow[];
}

export interface RuntimeErrorsReportSection {
  window: '24h';
  /** When the groups were read from Vercel; null before the first read. */
  readAt: string | null;
  /** False when that read was cut short, so there may be more groups. */
  complete: boolean;
  /** Groups seen in the window; `groups` may be capped below it. */
  total: number;
  /** Worst level first, then most frequent. */
  groups: RuntimeErrorGroup[];
}

export interface AnalyticsReportSection {
  range: AnalyticsRange;
  posthog: {
    totals: { pageviews: number; sessions: number } | null;
    /** Most pageviews first. */
    sites: { host: string; pageviews: number; sessions: number }[];
  };
  vercel: {
    totals: { pageviews: number; visitors: number } | null;
    projectsTotal: number | null;
    projectsEnabled: number | null;
    failed: number | null;
    /** Most pageviews first. */
    projects: { project: string; domain: string | null; pageviews: number; visitors: number }[];
  };
  vitals: VitalsRow[];
}

export interface UptimeReportSection {
  days: number;
  /** Percent; a service below it over the window is a finding. */
  floor: number;
  services: { slug: string; name: string; uptimePercent: number | null; totalChecks: number }[];
}

export interface ReportSections {
  monitor: MonitorReportSection | null;
  deploys: DeploysReportSection | null;
  integrations: IntegrationsReportSection | null;
  errors: ErrorsReportSection | null;
  runtimeErrors: RuntimeErrorsReportSection | null;
  analytics: AnalyticsReportSection | null;
  uptime: UptimeReportSection | null;
}

export interface ReportResponse {
  schema: typeof REPORT_SCHEMA;
  /** ISO, server clock. */
  generatedAt: string;
  monitorVersion: string | null;
  /** Worst finding: critical→down, major→degraded, minor→attention; none → healthy if complete, else unknown. */
  verdict: ReportVerdict;
  complete: boolean;
  counts: Record<Severity, number>;
  coverage: Record<ReportSourceId, SourceCoverage>;
  /** Sorted: severity, then source, then title. */
  findings: Finding[];
  /** A section is null exactly when its source could not be read (`coverage[src].ok === false`). */
  sections: ReportSections;
}

/** The query `GET /report` and `get_report` accept, validated. */
export interface ReportParams {
  range: AnalyticsRange;
  /** Uptime window, 1–365. */
  days: number;
  /** Seconds to wait for cold dashboards, 0–60. */
  wait: number;
  /** Attach the build-log tail of failing deploys. */
  logs: boolean;
}
