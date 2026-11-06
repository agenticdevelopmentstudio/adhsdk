import type { HealthStatus } from "./health";

// Pure uptime arithmetic over per-day check counts — ported from the standalone
// status site (websites/main/status/src/lib/uptime.ts). No DB/IO; shared by the
// /uptime read route so its numbers match the old route exactly.

export interface Counts {
  total: number;
  healthy: number;
  degraded: number;
  down: number;
}

export function uptimePercent(c: Counts): number | null {
  if (c.total <= 0) return null;
  return Math.round(((c.healthy + c.degraded) / c.total) * 10000) / 100;
}

export function dayStatus(c: Counts): HealthStatus {
  if (c.down > 0) return c.down / c.total > 0.5 ? "down" : "degraded";
  if (c.degraded > 0) return "degraded";
  return "healthy";
}

/**
 * Portfolio-wide uptime % — the simple mean of each service's own uptime %, so
 * every service counts equally. Null when there's no data.
 */
export function overallUptimePercent(services: { uptimePercent: number | null }[]): number | null {
  const vals = services.map((s) => s.uptimePercent).filter((p): p is number => p != null);
  if (vals.length === 0) return null;
  const mean = vals.reduce((a, b) => a + b, 0) / vals.length;
  return Math.round(mean * 100) / 100;
}

/** At or above this uptime % a figure reads good. */
export const UPTIME_GOOD_PCT = 99;
/** At or above this (and below good) it reads as a warning; below it, bad. */
export const UPTIME_WARN_PCT = 95;

/** How an uptime figure should read. `unknown` when there is no figure (no checks). */
export type UptimeTone = "good" | "warn" | "bad" | "unknown";

export function uptimeTone(pct: number | null): UptimeTone {
  if (pct == null) return "unknown";
  if (pct >= UPTIME_GOOD_PCT) return "good";
  if (pct >= UPTIME_WARN_PCT) return "warn";
  return "bad";
}

/** A response slower than this is flagged slow on the dashboard. */
export const SLOW_RESPONSE_MS = 1000;

/** Was this probe's response slow? A probe with no response time is not slow — it has no
 *  time to judge (a timeout or a failure already shows as down). */
export function isSlowResponse(responseTimeMs: number | null): boolean {
  return responseTimeMs != null && responseTimeMs > SLOW_RESPONSE_MS;
}
