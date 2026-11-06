// The data contract for the telemetry subsystem — pure shapes with ZERO runtime
// dependencies (no db, no fetch, no react). Every fetcher, store, source, route
// and panel speaks in these DTOs, so the shape is defined in exactly one place
// and the same value flows whether it came from a live poll or the database.

/** One grouped error issue, as summarized by GlitchTip (Sentry-API-compatible). */
export interface ErrorDTO {
  /** Stable identity for keying (the GlitchTip issue id live; the DB row id from Turso). */
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
 * The live snapshot, with the analytics a client already knew standing in when the backend
 * has none to give yet (`analyticsPending`). Without this a backend restart blanks the traffic
 * figures, and the empty list is then saved over the good ones in the cache.
 */
export function withKnownAnalytics(live: TelemetrySnapshot, known: TelemetrySnapshot | null): TelemetrySnapshot {
  if (!live.analyticsPending || !known?.analytics.length) return live;
  return { ...live, analytics: known.analytics };
}
