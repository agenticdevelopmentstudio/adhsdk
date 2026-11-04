import type { AnalyticsRange } from "./ranges";
import type { DashboardSections } from "./sectioned-dashboard";

// The wire shapes of GET /analytics/dashboard and GET /errors/dashboard. status-web keeps a
// parallel copy (status-web does not depend on status-server), as it does for telemetry/types.

export const ANALYTICS_ENVIRONMENTS = ["production", "staging", "testing", "all"] as const;
export type AnalyticsEnvironment = (typeof ANALYTICS_ENVIRONMENTS)[number];

// ── PostHog ────────────────────────────────────────────────────────────────

export interface TrafficSection {
  buckets: string[];
  /** `sessions` sums per-bucket uniques, so a session spanning two buckets counts twice. */
  totals: { pageviews: number; sessions: number };
  /** One value per bucket. */
  pageviews: number[];
  sessions: number[];
  sites: { host: string; pageviews: number; sessions: number; series: number[] }[];
}

export interface DimensionRow {
  host: string;
  device: string;
  browser: string;
  country: string;
  referrer: string;
  pageviews: number;
}

export interface DimensionsSection {
  rows: DimensionRow[];
  /** The row cap was hit, so the tail is missing from every breakdown. */
  truncated: boolean;
}

export interface PathRow {
  host: string;
  path: string;
  pageviews: number;
}

export interface VitalsRow {
  host: string;
  samples: number;
  lcp: number | null;
  inp: number | null;
  cls: number | null;
  fcp: number | null;
}

export interface SiteHealthRow {
  host: string;
  errors: number;
  requests: number;
  failures: number;
  p95Ms: number | null;
}

// ── Vercel Web Analytics ───────────────────────────────────────────────────

export interface Marginal {
  name: string;
  pageviews: number;
}

export interface VercelProjectTraffic {
  project: string;
  domain: string | null;
  pageviews: number;
  visitors: number;
  series: number[];
  countries: Marginal[];
  referrers: Marginal[];
  paths: Marginal[];
  devices: Marginal[];
}

export interface VercelTrafficSection {
  buckets: string[];
  projectsTotal: number;
  projectsEnabled: number;
  /** Projects with at least one call that failed, so their numbers may be short. */
  failed: number;
  totals: { pageviews: number; visitors: number };
  pageviews: number[];
  visitors: number[];
  projects: VercelProjectTraffic[];
}

// ── The two responses ──────────────────────────────────────────────────────

export interface AnalyticsSectionData {
  traffic: TrafficSection;
  dimensions: DimensionsSection;
  paths: PathRow[];
  vitals: VitalsRow[];
  health: SiteHealthRow[];
  vercel: VercelTrafficSection;
}

export interface AnalyticsDashboardResponse {
  generatedAt: string;
  refreshing: boolean;
  range: AnalyticsRange;
  env: AnalyticsEnvironment;
  configured: { posthog: boolean; vercel: boolean };
  sections: DashboardSections<AnalyticsSectionData>;
}

export interface ErrorIssue {
  id: string;
  shortId: string | null;
  title: string;
  /** The exception class, e.g. "SyntaxError". */
  type: string | null;
  /** The file it was raised from, when GlitchTip knows. */
  source: string | null;
  level: string | null;
  count: number;
  userCount: number;
  firstSeen: string | null;
  lastSeen: string | null;
  release: string | null;
  project: string;
  permalink: string | null;
  /** Same test that puts an error on the board: error/fatal, seen in the last 24h. */
  active: boolean;
}

export interface ErrorsIssuesSection {
  buckets: string[];
  issues: ErrorIssue[];
  summary: {
    active: number;
    backlog: number;
    events: number;
    /** Null when the resolved count could not be read. */
    resolved: number | null;
    /** False when GlitchTip's list could not be walked to its end. */
    complete: boolean;
    byType: { name: string; issues: number; events: number }[];
    /** Currently unresolved issues by the day they first fired. */
    newPerDay: number[];
  };
}

export interface ErrorsEventsSection {
  buckets: string[];
  /** Every event GlitchTip accepted, per day, resolved issues included. */
  events: number[];
}

export interface ErrorsSectionData {
  issues: ErrorsIssuesSection;
  events: ErrorsEventsSection;
  sites: SiteHealthRow[];
}

export interface ErrorsDashboardResponse {
  generatedAt: string;
  refreshing: boolean;
  configured: { glitchtip: boolean; posthog: boolean };
  sections: DashboardSections<ErrorsSectionData>;
}
