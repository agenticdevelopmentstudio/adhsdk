"use client";

import { useState } from "react";
import { Label } from "@adh-sdk/ui/components/label";
import { Select } from "@adh-sdk/ui/components/select";
import { Stat } from "@adh-sdk/ui/components/stat";
import { Alert, AlertTitle, AlertDescription } from "@adh-sdk/ui/components/alert";
import { errorMessage } from "@adh-sdk/ui/lib/errors";
import { formatMicros, formatMicrosFloor } from "@adh-sdk/ui/lib/money";
import {
  formatBytes,
  formatCompact,
  formatCount,
  formatDuration,
} from "@adh-sdk/ui/lib/quantities";
import { DateRangePicker } from "@adh-sdk/ui/components/date-range-picker";
import {
  TimeSeriesChart,
  type TimeSeriesPoint,
  type TimeSeriesSeries,
} from "@adh-sdk/adh-ui/components/time-series-chart";
import {
  useInsightOverview,
  type InsightInterval,
  type InsightOverview,
} from "../api/insight";
import { lastDays, todayUtc } from "../costs/days";
import { directTotal, llmTokenTotal } from "../costs/totals";

// The platform's metered usage over time: traffic, the time spent serving it, LLM tokens,
// messaging, and the direct cost it priced out to. The enforcement/tiers console is the separate
// Usage Limits pane; this one only reads.

type OverviewPoint = InsightOverview["points"][number];

const INTERVALS: { value: InsightInterval; label: string }[] = [
  { value: "day", label: "Day" },
  { value: "week", label: "Week" },
  { value: "month", label: "Month" },
];

/** One chart: which point fields it draws, and how its values read. */
interface ChartSpec {
  title: string;
  series: TimeSeriesSeries[];
  format: (n: number) => string;
  value: (p: OverviewPoint) => Record<string, number | null>;
}

// Each chart holds measures on ONE scale — two scales are two charts. Reasoning tokens are
// already inside `output`, so they are not drawn as a kind of their own.
const CHARTS: ChartSpec[] = [
  {
    title: "Requests",
    series: [{ key: "requests", label: "Requests" }],
    format: formatCompact,
    value: (p) => ({ requests: p.requests }),
  },
  {
    title: "Data",
    series: [
      { key: "bytesIn", label: "In" },
      { key: "bytesOut", label: "Out" },
    ],
    format: formatBytes,
    value: (p) => ({ bytesIn: p.bytes_in, bytesOut: p.bytes_out }),
  },
  {
    title: "Server & DB time",
    series: [
      { key: "serverMs", label: "Server" },
      { key: "dbMs", label: "Database" },
    ],
    format: formatDuration,
    value: (p) => ({ serverMs: p.server_ms, dbMs: p.db_ms }),
  },
  {
    title: "LLM tokens",
    series: [
      { key: "input", label: "Input" },
      { key: "output", label: "Output" },
      { key: "cacheRead", label: "Cache read" },
      { key: "cacheWrite", label: "Cache write" },
    ],
    format: formatCompact,
    value: ({ llm_tokens: t }) => ({
      input: t.input,
      output: t.output,
      cacheRead: t.cache_read,
      cacheWrite: t.cache_write,
    }),
  },
  {
    title: "Messaging",
    series: [
      { key: "emails", label: "Emails" },
      { key: "smsSegments", label: "SMS" },
    ],
    format: formatCompact,
    value: (p) => ({ emails: p.emails, smsSegments: p.sms_segments }),
  },
  {
    title: "Direct cost",
    series: [{ key: "directMicros", label: "Direct cost" }],
    // An unpriced bucket is `null`: a gap in the line, never a drop to $0.00.
    format: (n) => formatMicros(Math.round(n)),
    value: (p) => ({ directMicros: p.direct_micros }),
  },
];

export interface OverviewTotals {
  requests: number;
  bytesIn: number;
  bytesOut: number;
  serverMs: number;
  dbMs: number;
  llmTokens: number;
  emails: number;
  smsSegments: number;
  /** `null` when every bucket is unpriced. */
  directMicros: number | null;
  /** Some bucket has an unpriced line, so the direct figure is a floor. */
  directIsFloor: boolean;
}

/** The range's totals over every bucket. Tokens total input + output + cache (reasoning is in output). */
export function overviewTotals(points: readonly OverviewPoint[]): OverviewTotals {
  const sum = (f: (p: OverviewPoint) => number) => points.reduce((n, p) => n + f(p), 0);
  const direct = directTotal(points);
  return {
    requests: sum((p) => p.requests),
    bytesIn: sum((p) => p.bytes_in),
    bytesOut: sum((p) => p.bytes_out),
    serverMs: sum((p) => p.server_ms),
    dbMs: sum((p) => p.db_ms),
    llmTokens: sum((p) => llmTokenTotal(p.llm_tokens)),
    emails: sum((p) => p.emails),
    smsSegments: sum((p) => p.sms_segments),
    directMicros: direct.directMicros,
    directIsFloor: direct.isFloor,
  };
}

function Totals({ totals }: { totals: OverviewTotals }) {
  const direct =
    totals.directMicros === null
      ? "Unpriced"
      : formatMicrosFloor(totals.directMicros, totals.directIsFloor);
  const stats: [string, string][] = [
    ["Requests", formatCount(totals.requests)],
    ["Data in", formatBytes(totals.bytesIn)],
    ["Data out", formatBytes(totals.bytesOut)],
    ["Server time", formatDuration(totals.serverMs)],
    ["DB time", formatDuration(totals.dbMs)],
    ["LLM tokens", formatCount(totals.llmTokens)],
    ["Emails", formatCount(totals.emails)],
    ["SMS", formatCount(totals.smsSegments)],
    ["Direct cost", direct],
  ];
  return (
    <section
      aria-label="Totals"
      className="mb-6 flex flex-wrap gap-6 rounded-lg border border-apt-border bg-apt-surface p-4"
    >
      {stats.map(([label, value]) => (
        <Stat key={label} label={label} value={value} className="items-start" />
      ))}
    </section>
  );
}

export function UsageOverviewPane() {
  const today = todayUtc();
  const [range, setRange] = useState(() => lastDays(30, today));
  const [interval, chooseInterval] = useState<InsightInterval>("day");
  const overview = useInsightOverview(range, interval);
  const points = overview.data?.points ?? [];
  const chartPoints = (spec: ChartSpec): TimeSeriesPoint[] =>
    points.map((p) => ({ x: p.start, ...spec.value(p) }));

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-apt-text">Usage overview</h1>

      <div className="mb-6 flex flex-wrap items-end gap-6">
        <DateRangePicker value={range} onChange={setRange} max={today} />
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="usage-overview-interval">Interval</Label>
          <Select
            id="usage-overview-interval"
            value={interval}
            onChange={(e) => chooseInterval(e.target.value as InsightInterval)}
          >
            {INTERVALS.map((i) => (
              <option key={i.value} value={i.value}>
                {i.label}
              </option>
            ))}
          </Select>
        </div>
      </div>

      {overview.error != null && (
        <Alert variant="error" className="mb-6">
          <AlertTitle>Couldn't load the usage overview</AlertTitle>
          <AlertDescription>{errorMessage(overview.error)}</AlertDescription>
        </Alert>
      )}

      {overview.isLoading && <p className="text-sm text-apt-text-muted">Loading…</p>}

      {overview.data && (
        <>
          <Totals totals={overviewTotals(points)} />
          <div className="grid gap-6 lg:grid-cols-2">
            {CHARTS.map((spec) => (
              <section
                key={spec.title}
                aria-label={spec.title}
                className="rounded-lg border border-apt-border bg-apt-surface p-4"
              >
                <h2 className="mb-2 text-lg font-semibold text-apt-text">{spec.title}</h2>
                <TimeSeriesChart
                  points={chartPoints(spec)}
                  series={spec.series}
                  format={spec.format}
                />
              </section>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
