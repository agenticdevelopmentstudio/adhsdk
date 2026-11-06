"use client";
import type { ReactElement } from "react";
import { formatCount, TrendChart, type TrendSeries } from "@adh-sdk/ui/blocks/trend-chart";
import { DataTable, type DataTableColumn } from "@adh-sdk/ui/components/data-table";
import { StatusDot } from "@adh-sdk/ui/components/status-dot";
import { ANALYTICS_SOURCE_COLORS } from "../lib/colors";
import { bucketDetail, bucketLabel, formatVital } from "../lib/dashboard-format";
import type {
  AnalyticsRange,
  ChartSeries,
  JoinedSite,
  Marginal,
  RatedVitalsRow,
  VercelTrafficSection,
  Vital,
  VitalRating,
} from "../telemetry/dashboard-types";
import { OpenOnClickTable, SiteFailureRate, WrappedCell } from "./DashboardParts";
import { ResponseChart } from "./ResponseChart";

// What Analytics' overview and its site pages share, so the two can't disagree about what a figure
// means.

export function toBars(marginals: readonly Marginal[]): { name: string; value: number }[] {
  return marginals.map((m) => ({ name: m.name, value: m.pageviews }));
}

export function countOrDash(value: number | null | undefined): string {
  return value === null || value === undefined ? "—" : formatCount(value);
}

const SITE_COLUMNS: DataTableColumn<JoinedSite>[] = [
  {
    key: "site",
    header: "Site",
    sortable: true,
    width: "minmax(16rem, 1fr)",
    render: (row) => <WrappedCell>{row.key}</WrappedCell>,
  },
  {
    key: "trend",
    header: "Trend",
    width: "6.5rem",
    resizable: false,
    render: (row) => (
      <ResponseChart
        points={row.posthog?.series ?? row.vercel?.series ?? []}
        color={row.posthog ? ANALYTICS_SOURCE_COLORS.posthog : ANALYTICS_SOURCE_COLORS.vercel}
        height={20}
      />
    ),
  },
  { key: "phViews", header: "PostHog views", sortable: true, render: (row) => countOrDash(row.posthog?.pageviews) },
  { key: "phSessions", header: "Sessions", sortable: true, render: (row) => countOrDash(row.posthog?.sessions) },
  { key: "vcViews", header: "Vercel views", sortable: true, render: (row) => countOrDash(row.vercel?.pageviews) },
  { key: "vcVisitors", header: "Visitors", sortable: true, render: (row) => countOrDash(row.vercel?.visitors) },
  { key: "errors", header: "Errors", sortable: true, render: (row) => countOrDash(row.health?.errors) },
  {
    key: "failures",
    header: "Failed requests",
    sortable: true,
    render: (row) =>
      row.health ? (
        <SiteFailureRate failures={row.health.failures} requests={row.health.requests} high={row.health.failureRateHigh} />
      ) : (
        "—"
      ),
  },
  {
    key: "p95",
    header: "p95",
    sortable: true,
    render: (row) => (row.health?.p95Ms === null || !row.health ? "—" : `${Math.round(row.health.p95Ms)}ms`),
  },
];

export interface SiteSort {
  key: string;
  dir: "asc" | "desc";
}

/** Every site on one table. Choosing a row opens that site: its page is where the row's detail is. */
export function SitesTable({
  rows,
  onSite,
  sort,
  onSort,
}: {
  rows: readonly JoinedSite[];
  onSite: (site: string) => void;
  sort: SiteSort;
  onSort: (sort: SiteSort) => void;
}): ReactElement {
  return (
    <OpenOnClickTable
      ariaLabel="Traffic per site"
      columns={SITE_COLUMNS}
      rows={[...rows]}
      getRowId={(row) => row.key}
      onOpen={onSite}
      sort={sort}
      onSortChange={onSort}
      autoSizeColumns
      emptyLabel="No site reported traffic in this range."
      describeRow={(row) => row.key}
    />
  );
}

const RATING_TONE: Record<VitalRating, "success" | "accent" | "error"> = {
  good: "success",
  fair: "accent",
  poor: "error",
};

/** A vital's value with the server's rating of it. */
export function VitalCell({
  vital,
  value,
  rating,
}: {
  vital: Vital;
  value: number | null;
  rating: VitalRating | null;
}): ReactElement {
  if (value === null || rating === null) return <>—</>;
  return (
    <span className="inline-flex items-center gap-1.5" title={`${vital.toUpperCase()}: ${rating}`}>
      <StatusDot tone={RATING_TONE[rating]} size={7} />
      {formatVital(vital, value)}
      <span className="text-apt-text-dim">{rating}</span>
    </span>
  );
}

const vitalColumn = (vital: Vital): DataTableColumn<RatedVitalsRow> => ({
  key: vital,
  header: vital.toUpperCase(),
  render: (row) => <VitalCell vital={vital} value={row[vital]} rating={row.ratings[vital]} />,
});

const VITALS_COLUMNS: DataTableColumn<RatedVitalsRow>[] = [
  { key: "host", header: "Site", width: "minmax(16rem, 1fr)", render: (row) => <WrappedCell>{row.site}</WrappedCell> },
  { key: "samples", header: "Samples", render: (row) => formatCount(row.samples) },
  vitalColumn("lcp"),
  vitalColumn("inp"),
  vitalColumn("cls"),
  vitalColumn("fcp"),
];

export const VITALS_NOTE =
  "75th percentile of real page loads, rated against Google's Core Web Vitals limits. Vercel Speed Insights is off on every project.";

export function VitalsTable({ rows }: { rows: readonly RatedVitalsRow[] }): ReactElement {
  return (
    <DataTable
      ariaLabel="Web vitals per site"
      columns={VITALS_COLUMNS}
      rows={[...rows]}
      getRowId={(row) => row.host}
      autoSizeColumns
      emptyLabel="No vitals were reported in this range."
    />
  );
}

/** The server's pageview series, one line per provider that has one. */
export function PageviewsChart({
  series,
  site,
  range,
  height,
}: {
  series: ChartSeries;
  site: string | null;
  range: AnalyticsRange;
  height: number;
}): ReactElement {
  const lines: TrendSeries[] = [];
  if (series.posthog) lines.push({ name: "PostHog", color: ANALYTICS_SOURCE_COLORS.posthog, values: series.posthog });
  if (series.vercel) lines.push({ name: "Vercel", color: ANALYTICS_SOURCE_COLORS.vercel, values: series.vercel });
  return (
    <TrendChart
      ariaLabel={site === null ? "Pageviews across all sites over time, by source" : `Pageviews for ${site} over time, by source`}
      labels={series.labels}
      series={lines}
      height={height}
      formatLabel={(label) => bucketLabel(label, range)}
      formatDetail={(label) => bucketDetail(label, range)}
    />
  );
}

export const PAGEVIEWS_NOTE =
  "Two separate measurements, compared rather than added. Sites reporting to both appear in both lines.";

/** "63 of 68 production sites have Web Analytics on", and what could not be read. */
export function projectsNote(vercel: VercelTrafficSection | null): string | undefined {
  if (!vercel) return undefined;
  const failed = vercel.failed > 0 ? ` ${vercel.failed} could not be read, so totals may be short.` : "";
  const incomplete =
    vercel.incomplete > 0 ? ` ${vercel.incomplete} could not be read in full, so the charts and top lists may be short.` : "";
  return `${vercel.projectsEnabled} of ${vercel.projectsTotal} production sites have Web Analytics on.${failed}${incomplete}`;
}
