// The data contract for the telemetry subsystem — pure shapes with ZERO runtime
// dependencies (no db, no fetch, no react). Every fetcher, store, source, route
// and panel speaks in these DTOs, so the shape is defined in exactly one place
// and the same value flows whether it came from a live poll or the database.

/** One grouped error issue, as summarized by GlitchTip (Sentry-API-compatible). */
export interface ErrorDTO {
  /** Stable identity for keying (the GlitchTip issue id live; the DB row id from the store). */
  id: string;
  /** GlitchTip issue id — stable across polls, the store's upsert key. */
  issueKey: string;
  project: string;
  title: string;
  culprit: string | null;
  level: string | null;
  count: number;
  userCount: number;
  firstSeen: string | null; // ISO
  lastSeen: string | null; // ISO
  permalink: string | null;
  /**
   * Would this error hold a board Problem open: the board's own rule, allowlist and frozen feed
   * included. Set on the live snapshot only; a stored row has no verdict.
   */
  active?: boolean;
}

/** One headline analytics KPI sample — anonymous + aggregate (from PostHog). */
export interface AnalyticsMetricDTO {
  metric: string; // 'pageviews' | 'visitors'
  window: string; // '24h' | '7d'
  scope: string; // 'all' or a site slug
  value: number;
  capturedAt: string; // ISO
}

/** One self-contained read of everything the production-visibility band shows. */
export interface TelemetrySnapshot {
  generatedAt: string; // ISO
  errors: ErrorDTO[];
  analytics: AnalyticsMetricDTO[];
  /** True when GlitchTip could not be read just now, so `errors` is its last answer. */
  errorsFrozen?: boolean;
  /**
   * True when no analytics have been read since the backend started, so `analytics` is empty
   * for want of an answer, not because there is no traffic. A client keeps what it last knew.
   */
  analyticsPending?: boolean;
}

export function emptySnapshot(): TelemetrySnapshot {
  return { generatedAt: "", errors: [], analytics: [] };
}

/**
 * One Vercel runtime log line worth keeping (an error/fatal line or a 5xx response), read from
 * the current production deployment of a production project. The INPUT of the runtime-errors
 * store: it groups these and counts each `rowId` once per deployment.
 */
export interface RuntimeLogEntry {
  project: string;
  deploymentId: string;
  domain: string | null;
  rowId: string;
  timestampMs: number;
  /** debug | info | warning | error | fatal | trace, as Vercel sends it. */
  level: string;
  /** delimiter | edge-function | edge-middleware | request | serverless. */
  source: string;
  method: string | null;
  /** The request path, query string removed but NOT yet normalized. */
  path: string | null;
  /** Null when the line carries no response status. */
  status: number | null;
  message: string;
}

/**
 * One group of runtime errors: same project, source, method, normalized path, status and first
 * message line. What `GET /errors/runtime` and the errors dashboard's `runtime` section list.
 */
export interface RuntimeErrorGroup {
  /** Stable hash of the grouping fields. */
  key: string;
  project: string;
  /** The deployment the group was LAST seen on. */
  deploymentId: string;
  domain: string | null;
  source: string;
  method: string | null;
  /** Numeric, uuid and hash segments read `:id`. */
  path: string | null;
  status: number | null;
  /** The worst level any of its lines carried. */
  level: string;
  /** First line of the message, at most 200 characters. */
  message: string;
  /** Lines counted since `firstSeen` (within the 7-day retention), each `rowId` once. */
  count: number;
  firstSeen: string; // ISO
  lastSeen: string; // ISO
  /** A `rowId` of the most recent line, to look it up in Vercel. */
  sampleRowId: string | null;
}

/** `GET /errors/runtime`, and the errors dashboard's `runtime` section. */
export interface RuntimeErrorsReport {
  generatedAt: string; // ISO
  window: "24h";
  /** Groups seen in the window; `groups` may be capped below it. */
  total: number;
  /** Seen in the window, worst level first, then most frequent. */
  groups: RuntimeErrorGroup[];
}
