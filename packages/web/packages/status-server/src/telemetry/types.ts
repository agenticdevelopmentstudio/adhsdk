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

/**
 * The Errors card's figures, judged by the server (`errorsSummary`): active issues, the
 * backlog behind them, the events all of them carry, and the loudest active issues.
 */
export interface ErrorsSummary {
  active: number;
  backlog: number;
  events: number;
  /** At most five active issues, the most events first. */
  top: ErrorDTO[];
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
  /**
   * The Errors card's figures. Set on the live snapshot only — like `active`, a stored row
   * has no verdict — so a snapshot without it makes no claim about errors at all.
   */
  errorsSummary?: ErrorsSummary;
}

export function emptySnapshot(): TelemetrySnapshot {
  return { generatedAt: "", errors: [], analytics: [] };
}

/**
 * One Vercel runtime event worth keeping, from a production project's production environment:
 * an `error`/`fatal` log line (`vercel.log`) or a 5xx response (`vercel.proxy_response`). The
 * INPUT of the runtime-errors store, which groups one 24-hour read of them into its snapshot.
 */
export interface RuntimeLogEntry {
  project: string;
  deploymentId: string;
  domain: string | null;
  /** Vercel's request id, to look the request up in Vercel's logs. */
  requestId: string | null;
  timestampMs: number;
  /** debug | info | warning | error | fatal | trace, as Vercel sends it; a 5xx response reads `error`. */
  level: string;
  /** function | edge-function | edge-middleware | ... for a log line; `response` for a 5xx. */
  source: string;
  method: string | null;
  /** The request path, query string removed but NOT yet normalized. */
  path: string | null;
  /** Null when the event carries no response status. */
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
  /** The deployment of its newest event. */
  deploymentId: string;
  domain: string | null;
  source: string;
  method: string | null;
  /** Numeric, uuid and hash segments read `:id`. */
  path: string | null;
  status: number | null;
  /** The worst level any of its events carried. */
  level: string;
  /** First line of the message, at most 200 characters. */
  message: string;
  /** Events in the 24 hours before the read that stored it. */
  count: number;
  firstSeen: string; // ISO
  lastSeen: string; // ISO
  /** The request id of its newest event, to look it up in Vercel. */
  sampleRequestId: string | null;
}

/** The last successful runtime-errors read: what the stored groups are a snapshot of. */
export interface RuntimeErrorsRead {
  /** Epoch ms of the read. Its window is the 24 hours before it. */
  readAtMs: number;
  /** False when the read stopped before the start of its window, so counts are a floor. */
  complete: boolean;
}

/** `GET /errors/runtime`, and the errors dashboard's `runtime` section. */
export interface RuntimeErrorsReport {
  generatedAt: string; // ISO
  window: "24h";
  /**
   * When the groups were read: the window is the 24 hours before it. Null before the first
   * successful read. A failed read keeps the last snapshot, so this can fall behind `generatedAt`.
   */
  readAt: string | null; // ISO
  /** False when that read stopped before the start of its window, so counts are a floor. */
  complete: boolean;
  /** Groups the read found; `groups` may be capped below it. */
  total: number;
  /** Worst level first, then most frequent. */
  groups: RuntimeErrorGroup[];
}
