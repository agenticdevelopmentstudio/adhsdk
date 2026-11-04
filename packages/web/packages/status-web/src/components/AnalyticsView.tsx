"use client";
import { useMemo, useState, type ReactElement } from "react";
import { X } from "lucide-react";
import { BarList } from "@adh-sdk/ui/blocks/bar-list";
import { formatCount, TrendChart, type TrendSeries } from "@adh-sdk/ui/blocks/trend-chart";
import { DataTable, type DataTableColumn } from "@adh-sdk/ui/components/data-table";
import { StatusDot } from "@adh-sdk/ui/components/status-dot";
import { ToggleGroup, ToggleGroupItem } from "@adh-sdk/ui/components/toggle-group";
import { useAnalyticsDashboard } from "../hooks/use-dashboards";
import {
  bucketDetail,
  bucketLabel,
  dimensionTotals,
  formatVital,
  joinSites,
  pageviewSeries,
  pathTotals,
  siteKey,
  vercelTotals,
  vitalRating,
  type Dimension,
  type JoinedSite,
  type Vital,
  type VercelBreakdown,
  type VitalRating,
} from "../lib/analytics-model";
import { ANALYTICS_SOURCE_COLORS } from "../lib/colors";
import {
  ANALYTICS_ENVIRONMENTS,
  ANALYTICS_RANGES,
  type AnalyticsEnvironment,
  type AnalyticsRange,
  type AnalyticsSectionData,
  type DashboardSections,
  type Marginal,
  type VitalsRow,
} from "../telemetry/dashboard-types";
import { DashboardPanel, FigureTile, SiteFailureRate } from "./DashboardParts";
import { ResponseChart } from "./ResponseChart";

const RANGE_LABEL: Record<AnalyticsRange, string> = { "24h": "24 hours", "7d": "7 days", "30d": "30 days" };
const ENV_LABEL: Record<AnalyticsEnvironment, string> = {
  production: "Production",
  staging: "Staging",
  testing: "Testing",
  all: "All",
};

const EMPTY_SECTIONS: DashboardSections<AnalyticsSectionData> = {
  traffic: { data: null, error: null, updatedAt: null },
  dimensions: { data: null, error: null, updatedAt: null },
  paths: { data: null, error: null, updatedAt: null },
  vitals: { data: null, error: null, updatedAt: null },
  health: { data: null, error: null, updatedAt: null },
  vercel: { data: null, error: null, updatedAt: null },
};

const POSTHOG_BREAKDOWNS: { dimension: Dimension; title: string }[] = [
  { dimension: "country", title: "Countries" },
  { dimension: "referrer", title: "Referrers" },
  { dimension: "device", title: "Devices" },
  { dimension: "browser", title: "Browsers" },
];

const VERCEL_BREAKDOWNS: { breakdown: VercelBreakdown; title: string }[] = [
  { breakdown: "countries", title: "Countries" },
  { breakdown: "referrers", title: "Referrers" },
  { breakdown: "devices", title: "Devices" },
  { breakdown: "paths", title: "Pages" },
];

function toBars(marginals: readonly Marginal[]): { name: string; value: number }[] {
  return marginals.map((m) => ({ name: m.name, value: m.pageviews }));
}

function count(value: number | null | undefined): string {
  return value === null || value === undefined ? "—" : formatCount(value);
}

type SiteSortKey = "site" | "phViews" | "phSessions" | "vcViews" | "vcVisitors" | "errors" | "failures" | "p95";

function siteSortValue(row: JoinedSite, key: SiteSortKey): number | string {
  switch (key) {
    case "site":
      return row.key;
    case "phViews":
      return row.posthog?.pageviews ?? -1;
    case "phSessions":
      return row.posthog?.sessions ?? -1;
    case "vcViews":
      return row.vercel?.pageviews ?? -1;
    case "vcVisitors":
      return row.vercel?.visitors ?? -1;
    case "errors":
      return row.health?.errors ?? -1;
    case "failures":
      return row.health && row.health.requests > 0 ? row.health.failures / row.health.requests : -1;
    case "p95":
      return row.health?.p95Ms ?? -1;
  }
}

function sortSites(rows: readonly JoinedSite[], key: SiteSortKey, dir: "asc" | "desc"): JoinedSite[] {
  const sign = dir === "asc" ? 1 : -1;
  return [...rows].sort((a, b) => {
    const x = siteSortValue(a, key);
    const y = siteSortValue(b, key);
    const order = typeof x === "string" || typeof y === "string" ? String(x).localeCompare(String(y)) : x - y;
    return sign * order || a.key.localeCompare(b.key);
  });
}

const SITE_COLUMNS: DataTableColumn<JoinedSite>[] = [
  {
    key: "site",
    header: "Site",
    sortable: true,
    width: "minmax(11rem, 1fr)",
    render: (row) => <span title={row.key}>{row.key}</span>,
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
  { key: "phViews", header: "PostHog views", sortable: true, align: "end", render: (row) => count(row.posthog?.pageviews) },
  { key: "phSessions", header: "Sessions", sortable: true, align: "end", render: (row) => count(row.posthog?.sessions) },
  { key: "vcViews", header: "Vercel views", sortable: true, align: "end", render: (row) => count(row.vercel?.pageviews) },
  { key: "vcVisitors", header: "Visitors", sortable: true, align: "end", render: (row) => count(row.vercel?.visitors) },
  { key: "errors", header: "Errors", sortable: true, align: "end", render: (row) => count(row.health?.errors) },
  {
    key: "failures",
    header: "Failed requests",
    sortable: true,
    align: "end",
    render: (row) =>
      row.health ? <SiteFailureRate failures={row.health.failures} requests={row.health.requests} /> : "—",
  },
  {
    key: "p95",
    header: "p95",
    sortable: true,
    align: "end",
    render: (row) => (row.health?.p95Ms === null || !row.health ? "—" : `${Math.round(row.health.p95Ms)}ms`),
  },
];

const RATING_TONE: Record<VitalRating, "success" | "accent" | "error"> = {
  good: "success",
  fair: "accent",
  poor: "error",
};

function VitalCell({ vital, value }: { vital: Vital; value: number | null }): ReactElement {
  if (value === null) return <>—</>;
  const rating = vitalRating(vital, value);
  return (
    <span className="inline-flex items-center justify-end gap-1.5" title={`${vital.toUpperCase()}: ${rating}`}>
      <StatusDot tone={RATING_TONE[rating]} size={7} />
      {formatVital(vital, value)}
      <span className="text-apt-text-dim">{rating}</span>
    </span>
  );
}

const VITALS_COLUMNS: DataTableColumn<VitalsRow>[] = [
  { key: "host", header: "Site", width: "minmax(11rem, 1fr)", render: (row) => siteKey(row.host) },
  { key: "samples", header: "Samples", align: "end", render: (row) => formatCount(row.samples) },
  { key: "lcp", header: "LCP", align: "end", render: (row) => <VitalCell vital="lcp" value={row.lcp} /> },
  { key: "inp", header: "INP", align: "end", render: (row) => <VitalCell vital="inp" value={row.inp} /> },
  { key: "cls", header: "CLS", align: "end", render: (row) => <VitalCell vital="cls" value={row.cls} /> },
  { key: "fcp", header: "FCP", align: "end", render: (row) => <VitalCell vital="fcp" value={row.fcp} /> },
];

/**
 * The Analytics topic: traffic per site and in aggregate, from PostHog and from Vercel Web
 * Analytics. The two stay side by side and are never added together. They overlap on the sites
 * reporting to both and count differently, so a sum would describe nothing.
 *
 * Picking a site narrows everything on the page without another request.
 */
export function AnalyticsView(): ReactElement {
  const [range, setRange] = useState<AnalyticsRange>("7d");
  const [env, setEnv] = useState<AnalyticsEnvironment>("production");
  const [site, setSite] = useState<string | null>(null);
  const [sort, setSort] = useState<{ key: string; dir: "asc" | "desc" }>({ key: "phViews", dir: "desc" });

  const query = useAnalyticsDashboard(range, env);
  const body = query.data;
  const sections = body?.sections ?? EMPTY_SECTIONS;
  const refreshing = body ? body.refreshing : query.isLoading;
  const posthogOn = body?.configured.posthog ?? true;
  const vercelOn = body?.configured.vercel ?? true;
  const vercelNote = env === "production" ? null : "Vercel Web Analytics only reports production.";

  const traffic = sections.traffic.data;
  const vercel = sections.vercel.data;
  const health = sections.health.data;

  const rows = useMemo(() => joinSites(traffic, vercel, health), [traffic, vercel, health]);
  const sortedRows = useMemo(() => sortSites(rows, sort.key as SiteSortKey, sort.dir), [rows, sort]);
  const chosen = site === null ? null : (rows.find((row) => row.key === site) ?? null);

  const series = useMemo(() => pageviewSeries(traffic, vercel, site), [traffic, vercel, site]);
  const chartSeries: TrendSeries[] = [];
  if (series.posthog) chartSeries.push({ name: "PostHog", color: ANALYTICS_SOURCE_COLORS.posthog, values: series.posthog });
  if (series.vercel) chartSeries.push({ name: "Vercel", color: ANALYTICS_SOURCE_COLORS.vercel, values: series.vercel });

  const figures =
    site === null
      ? {
          posthogViews: traffic?.totals.pageviews ?? null,
          posthogSessions: traffic?.totals.sessions ?? null,
          vercelViews: vercel?.totals.pageviews ?? null,
          vercelVisitors: vercel?.totals.visitors ?? null,
        }
      : {
          posthogViews: chosen?.posthog?.pageviews ?? null,
          posthogSessions: chosen?.posthog?.sessions ?? null,
          vercelViews: chosen?.vercel?.pageviews ?? null,
          vercelVisitors: chosen?.vercel?.visitors ?? null,
        };

  const vitalsRows = (sections.vitals.data ?? []).filter((row) => site === null || siteKey(row.host) === site);

  return (
    <div className="min-h-0 flex-1 overflow-y-auto">
      <div className="mx-auto flex w-full max-w-[1400px] flex-col gap-4 p-4">
        <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
          <ToggleGroup
            aria-label="Time range"
            value={[range]}
            onValueChange={(next: unknown[]) => {
              const value = next[0] as AnalyticsRange | undefined;
              if (value) setRange(value);
            }}
          >
            {ANALYTICS_RANGES.map((value) => (
              <ToggleGroupItem key={value} value={value} aria-label={RANGE_LABEL[value]}>
                {value}
              </ToggleGroupItem>
            ))}
          </ToggleGroup>
          <ToggleGroup
            aria-label="Environment"
            value={[env]}
            onValueChange={(next: unknown[]) => {
              const value = next[0] as AnalyticsEnvironment | undefined;
              if (value) setEnv(value);
            }}
          >
            {ANALYTICS_ENVIRONMENTS.map((value) => (
              <ToggleGroupItem key={value} value={value}>
                {ENV_LABEL[value]}
              </ToggleGroupItem>
            ))}
          </ToggleGroup>
          {site !== null && (
            <button
              type="button"
              onClick={() => setSite(null)}
              aria-label={`Clear the site filter: ${site}`}
              className="inline-flex max-w-full cursor-pointer items-center gap-1.5 rounded-md border border-apt-border bg-apt-surface px-2.5 py-1.5 font-mono text-xs text-apt-text"
            >
              <span className="truncate">{site}</span>
              <X size={13} aria-hidden className="flex-none" />
            </button>
          )}
          {(refreshing || query.isPlaceholderData) && (
            <span role="status" className="ml-auto font-mono text-[11px] text-apt-text-dim">
              Refreshing…
            </span>
          )}
        </div>

        {query.isError && !body && (
          <p role="alert" className="m-0 font-mono text-xs text-apt-red">
            Could not load analytics: {query.error.message}
          </p>
        )}

        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <FigureTile label="Pageviews" source="PostHog" value={figures.posthogViews === null ? null : count(figures.posthogViews)} />
          <FigureTile label="Sessions" source="PostHog" value={figures.posthogSessions === null ? null : count(figures.posthogSessions)} hint="About one per page load" />
          <FigureTile label="Pageviews" source="Vercel" value={figures.vercelViews === null ? null : count(figures.vercelViews)} />
          <FigureTile label="Visitors" source="Vercel" value={figures.vercelVisitors === null ? null : count(figures.vercelVisitors)} />
        </div>

        <DashboardPanel
          title={site === null ? "Pageviews, all sites" : `Pageviews, ${site}`}
          source="PostHog and Vercel"
          section={{
            data: traffic || vercel ? true : null,
            error: sections.traffic.error ?? sections.vercel.error,
            updatedAt: sections.traffic.updatedAt ?? sections.vercel.updatedAt,
          }}
          configured={posthogOn || vercelOn}
          refreshing={refreshing}
          skeletonHeight={240}
          note="Two separate measurements, compared rather than added. Sites reporting to both appear in both lines."
        >
          {() => (
            <TrendChart
              ariaLabel={site === null ? "Pageviews across all sites over time, by source" : `Pageviews for ${site} over time, by source`}
              labels={series.labels}
              series={chartSeries}
              height={240}
              formatLabel={(label) => bucketLabel(label, range)}
              formatDetail={(label) => bucketDetail(label, range)}
            />
          )}
        </DashboardPanel>

        <DashboardPanel
          title="Sites"
          source="PostHog and Vercel"
          section={{
            data: traffic || vercel ? true : null,
            error: sections.traffic.error ?? sections.vercel.error,
            updatedAt: sections.traffic.updatedAt ?? sections.vercel.updatedAt,
          }}
          configured={posthogOn || vercelOn}
          refreshing={refreshing}
          note="Select a site to narrow the whole page to it. A dash means that source has not seen the site. Errors, failed requests and p95 come from PostHog."
        >
          {() => (
            <div className="-mx-1 max-h-[420px] overflow-auto">
              <DataTable
                ariaLabel="Traffic per site"
                columns={SITE_COLUMNS}
                rows={sortedRows}
                getRowId={(row) => row.key}
                selectedIds={site === null ? new Set<string>() : new Set([site])}
                onSelectionChange={(ids) => {
                  const next = [...ids].find((id) => id !== site);
                  setSite(next ?? (site !== null && ids.has(site) ? site : null));
                }}
                sort={sort}
                onSortChange={setSort}
                autoSizeColumns
                emptyLabel="No site reported traffic in this range."
                describeRow={(row) => row.key}
              />
            </div>
          )}
        </DashboardPanel>

        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
          <DashboardPanel
            title="Top pages"
            source="PostHog"
            section={sections.paths}
            configured={posthogOn}
            refreshing={refreshing}
          >
            {(paths) => (
              <BarList
                ariaLabel="Top pages by pageviews, from PostHog"
                items={toBars(pathTotals(paths, site))}
                color={ANALYTICS_SOURCE_COLORS.posthog}
                emptyLabel="No pageviews in this range."
              />
            )}
          </DashboardPanel>
          {POSTHOG_BREAKDOWNS.map(({ dimension, title }) => (
            <DashboardPanel
              key={dimension}
              title={title}
              source="PostHog"
              section={sections.dimensions}
              configured={posthogOn}
              refreshing={refreshing}
              note={sections.dimensions.data?.truncated ? "The rarest combinations were cut off, so small rows may be short." : undefined}
            >
              {(dimensions) => (
                <BarList
                  ariaLabel={`${title} by pageviews, from PostHog`}
                  items={toBars(dimensionTotals(dimensions.rows, dimension, site))}
                  color={ANALYTICS_SOURCE_COLORS.posthog}
                  emptyLabel="No pageviews in this range."
                />
              )}
            </DashboardPanel>
          ))}
          <DashboardPanel
            title="Projects"
            source="Vercel"
            section={sections.vercel}
            configured={vercelOn}
            refreshing={refreshing}
            notApplicable={vercelNote}
            note={
              vercel
                ? `${vercel.projectsEnabled} of ${vercel.projectsTotal} projects have Web Analytics on.${vercel.failed > 0 ? ` ${vercel.failed} could not be read, so totals may be short.` : ""}`
                : undefined
            }
          >
            {(data) => (
              <BarList
                ariaLabel="Vercel projects by pageviews"
                items={data.projects
                  .filter((p) => p.pageviews > 0)
                  .map((p) => ({ name: p.domain ?? p.project, value: p.pageviews, detail: `${formatCount(p.pageviews)} · ${formatCount(p.visitors)} visitors` }))}
                color={ANALYTICS_SOURCE_COLORS.vercel}
                selected={site}
                onSelect={(name) => setSite(site === siteKey(name) ? null : siteKey(name))}
                emptyLabel="No pageviews in this range."
              />
            )}
          </DashboardPanel>
          {VERCEL_BREAKDOWNS.map(({ breakdown, title }) => (
            <DashboardPanel
              key={breakdown}
              title={title}
              source="Vercel"
              section={sections.vercel}
              configured={vercelOn}
              refreshing={refreshing}
              notApplicable={vercelNote}
            >
              {(data) => (
                <BarList
                  ariaLabel={`${title} by pageviews, from Vercel`}
                  items={toBars(vercelTotals(data.projects, breakdown, site))}
                  color={ANALYTICS_SOURCE_COLORS.vercel}
                  emptyLabel="No pageviews in this range."
                />
              )}
            </DashboardPanel>
          ))}
        </div>

        <DashboardPanel
          title="Web vitals"
          source="PostHog"
          section={sections.vitals}
          configured={posthogOn}
          refreshing={refreshing}
          note="75th percentile of real page loads, rated against Google's Core Web Vitals limits. Vercel Speed Insights is off on every project."
        >
          {() => (
            <div className="-mx-1 max-h-[320px] overflow-auto">
              <DataTable
                ariaLabel="Web vitals per site"
                columns={VITALS_COLUMNS}
                rows={vitalsRows}
                getRowId={(row) => row.host}
                autoSizeColumns
                emptyLabel="No vitals were reported in this range."
              />
            </div>
          )}
        </DashboardPanel>

        <p className="m-0 font-mono text-[10px] leading-relaxed text-apt-text-dim">
          PostHog runs cookieless, so its visitors, sessions and pageviews come out nearly equal: treat sessions as page
          loads, not people. Much of its traffic looks automated. Times are UTC.
        </p>
      </div>
    </div>
  );
}
