// The time axis the Analytics and Errors topics share. Every provider's answer is aligned onto
// these buckets, so a quiet hour reads as a zero rather than a gap, and PostHog's and Vercel's
// series can share one chart.

export const ANALYTICS_RANGES = ["24h", "7d", "30d"] as const;
export type AnalyticsRange = (typeof ANALYTICS_RANGES)[number];

export interface RangeWindow {
  since: Date;
  until: Date;
  unit: "hour" | "day";
  /** Bucket starts, oldest first, as ISO strings. */
  buckets: string[];
}

const HOUR_MS = 3_600_000;
const DAY_MS = 24 * HOUR_MS;
const DAYS: Record<Exclude<AnalyticsRange, "24h">, number> = { "7d": 7, "30d": 30 };

function steps(startMs: number, stepMs: number, count: number): string[] {
  return Array.from({ length: count }, (_, i) => new Date(startMs + i * stepMs).toISOString());
}

/**
 * 24h is hourly, with both the partial hour it starts in and the current one, so 25 buckets.
 * 7d and 30d are that many UTC days including today.
 */
export function rangeWindow(range: AnalyticsRange, nowMs: number): RangeWindow {
  const until = new Date(nowMs);
  if (range === "24h") {
    const sinceMs = Math.floor(nowMs / HOUR_MS) * HOUR_MS - 24 * HOUR_MS;
    return { since: new Date(sinceMs), until, unit: "hour", buckets: steps(sinceMs, HOUR_MS, 25) };
  }
  const days = DAYS[range];
  const sinceMs = Math.floor(nowMs / DAY_MS) * DAY_MS - (days - 1) * DAY_MS;
  return { since: new Date(sinceMs), until, unit: "day", buckets: steps(sinceMs, DAY_MS, days) };
}

/** Sum (timestamp, value) pairs onto `buckets`. Anything off the axis is dropped. */
export function alignToBuckets(buckets: readonly string[], points: Iterable<[unknown, number]>): number[] {
  const index = new Map(buckets.map((b, i) => [b, i]));
  const out = buckets.map(() => 0);
  for (const [at, value] of points) {
    const ms = new Date(typeof at === "string" || typeof at === "number" ? at : Number.NaN).getTime();
    if (Number.isNaN(ms)) continue;
    const i = index.get(new Date(ms).toISOString());
    if (i !== undefined) out[i]! += value;
  }
  return out;
}
