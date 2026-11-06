import type { AnalyticsRange, Vital } from "../telemetry/dashboard-types";

// How the Analytics and Errors pages word what the server derived. Presentation only: every join,
// sort, threshold and rating is in status-server's telemetry/dashboard/views.ts and arrives in the
// response's `views`.

// Buckets are UTC, so they are labelled in UTC: a local "Nov 3" over a UTC-day bucket would be a
// different day's traffic for anyone west of Greenwich.
const HOUR = new Intl.DateTimeFormat("en", { hour: "2-digit", minute: "2-digit", hourCycle: "h23", timeZone: "UTC" });
const DAY = new Intl.DateTimeFormat("en", { month: "short", day: "numeric", timeZone: "UTC" });

/** A bucket's label on the axis. */
export function bucketLabel(iso: string, range: AnalyticsRange): string {
  return (range === "24h" ? HOUR : DAY).format(new Date(iso));
}

/** A bucket's label in a tooltip or table, where the time zone can be said. */
export function bucketDetail(iso: string, range: AnalyticsRange): string {
  const at = new Date(iso);
  return range === "24h" ? `${DAY.format(at)}, ${HOUR.format(at)} UTC` : `${DAY.format(at)} (UTC)`;
}

/** A vital's value in its unit: CLS is unitless, the rest are milliseconds. */
export function formatVital(vital: Vital, value: number): string {
  if (vital === "cls") return value.toFixed(2);
  return value >= 1000 ? `${(value / 1000).toFixed(1)}s` : `${Math.round(value)}ms`;
}

/**
 * Places one name into the server's alphabetical site list. Only for a site the URL names that the
 * server's list does not have (a deep link to a site with no data yet), so the reader still sees
 * it selected; the list itself comes from the server already in order.
 */
export function withSite(sites: readonly string[], site: string | null): string[] {
  if (site === null || sites.includes(site)) return [...sites];
  return [...sites, site].sort((a, b) => a.localeCompare(b));
}
