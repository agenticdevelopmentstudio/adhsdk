"use client";
import type { ReactElement } from "react";
import { BarList } from "@adh-sdk/ui/blocks/bar-list";
import { formatCount, TrendChart, type TrendSeries } from "@adh-sdk/ui/blocks/trend-chart";
import { DataTable, type DataTableColumn } from "@adh-sdk/ui/components/data-table";
import { Stat, StatStrip } from "@adh-sdk/ui/components/stat";
import { StatusDot } from "@adh-sdk/ui/components/status-dot";
import {
  breakdownTotals,
  bucketDetail,
  bucketLabel,
  formatVital,
  pageviewSeries,
  projectKey,
  siteKey,
  vitalRating,
  type BreakdownTopic,
  type JoinedSite,
  type Vital,
  type VitalRating,
} from "../lib/analytics-model";
import { ANALYTICS_SOURCE_COLORS } from "../lib/colors";
import type {
  AnalyticsRange,
  AnalyticsSectionData,
  DashboardSections,
  Marginal,
  TrafficSection,
  VercelTrafficSection,
  VitalsRow,
} from "../telemetry/dashboard-types";
import { ANALYTICS_TOPICS, type AnalyticsTopic } from "./board-views";
import { DashboardPanel, eitherSection, SiteFailureRate, WrappedCell } from "./DashboardParts";
import { ResponseChart } from "./ResponseChart";

// What the Analytics sub-topics hold beyond the overview: the whole of each panel, for one site,
// chosen from the list beside the page. The tables and the chart here are used by the overview too,
// so a panel and its topic can't disagree about what a figure means.

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
      row.health ? <SiteFailureRate failures={row.health.failures} requests={row.health.requests} /> : "—",
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

export function SitesTable({
  rows,
  site,
  onSite,
  sort,
  onSort,
}: {
  rows: readonly JoinedSite[];
  site: string | null;
  onSite: (site: string | null) => void;
  sort: SiteSort;
  onSort: (sort: SiteSort) => void;
}): ReactElement {
  return (
    <DataTable
      ariaLabel="Traffic per site"
      columns={SITE_COLUMNS}
      rows={[...rows]}
      getRowId={(row) => row.key}
      selectedIds={site === null ? new Set<string>() : new Set([site])}
      onSelectionChange={(ids) => {
        const next = [...ids].find((id) => id !== site);
        onSite(next ?? (site !== null && ids.has(site) ? site : null));
      }}
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

function VitalCell({ vital, value }: { vital: Vital; value: number | null }): ReactElement {
  if (value === null) return <>—</>;
  const rating = vitalRating(vital, value);
  return (
    <span className="inline-flex items-center gap-1.5" title={`${vital.toUpperCase()}: ${rating}`}>
      <StatusDot tone={RATING_TONE[rating]} size={7} />
      {formatVital(vital, value)}
      <span className="text-apt-text-dim">{rating}</span>
    </span>
  );
}

const VITALS_COLUMNS: DataTableColumn<VitalsRow>[] = [
  { key: "host", header: "Site", width: "minmax(16rem, 1fr)", render: (row) => <WrappedCell>{siteKey(row.host)}</WrappedCell> },
  { key: "samples", header: "Samples", render: (row) => formatCount(row.samples) },
  { key: "lcp", header: "LCP", render: (row) => <VitalCell vital="lcp" value={row.lcp} /> },
  { key: "inp", header: "INP", render: (row) => <VitalCell vital="inp" value={row.inp} /> },
  { key: "cls", header: "CLS", render: (row) => <VitalCell vital="cls" value={row.cls} /> },
  { key: "fcp", header: "FCP", render: (row) => <VitalCell vital="fcp" value={row.fcp} /> },
];

export const VITALS_NOTE =
  "75th percentile of real page loads, rated against Google's Core Web Vitals limits. Vercel Speed Insights is off on every project.";

export function VitalsTable({ rows, site }: { rows: readonly VitalsRow[]; site: string | null }): ReactElement {
  return (
    <DataTable
      ariaLabel="Web vitals per site"
      columns={VITALS_COLUMNS}
      rows={rows.filter((row) => site === null || siteKey(row.host) === site)}
      getRowId={(row) => row.host}
      autoSizeColumns
      emptyLabel="No vitals were reported in this range."
    />
  );
}

export function PageviewsChart({
  traffic,
  vercel,
  site,
  range,
  height,
}: {
  traffic: TrafficSection | null;
  vercel: VercelTrafficSection | null;
  site: string | null;
  range: AnalyticsRange;
  height: number;
}): ReactElement {
  const series = pageviewSeries(traffic, vercel, site);
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
  return `${vercel.projectsEnabled} of ${vercel.projectsTotal} production sites have Web Analytics on.${failed}`;
}

/** A provider's side of a breakdown. Null means no answer, which must not read as "no traffic". */
function SourceList({
  source,
  color,
  topicLabel,
  site,
  marginals,
}: {
  source: string;
  color: string;
  topicLabel: string;
  site: string;
  marginals: readonly Marginal[] | null;
}): ReactElement {
  return (
    <div className="flex min-w-0 flex-col gap-2">
      <div className="font-mono text-[10px] uppercase tracking-[0.06em] text-apt-text-dim">{source}</div>
      {marginals === null ? (
        <p className="m-0 font-mono text-xs text-apt-text-dim">Not available.</p>
      ) : (
        <BarList
          ariaLabel={`${topicLabel} by pageviews for ${site}, from ${source}`}
          items={toBars(marginals)}
          color={color}
          maxItems={Infinity}
          emptyLabel="No pageviews in this range."
        />
      )}
    </div>
  );
}

function SourceLists({
  topic,
  topicLabel,
  site,
  posthog,
  vercel,
}: {
  topic: BreakdownTopic;
  topicLabel: string;
  site: string;
  posthog: readonly Marginal[] | null;
  vercel: readonly Marginal[] | null;
}): ReactElement {
  const props = { topicLabel, site };
  return (
    <div className="grid grid-cols-1 items-start gap-4 sm:grid-cols-2">
      <SourceList {...props} source="PostHog" color={ANALYTICS_SOURCE_COLORS.posthog} marginals={posthog} />
      {topic !== "browsers" && (
        <SourceList {...props} source="Vercel" color={ANALYTICS_SOURCE_COLORS.vercel} marginals={vercel} />
      )}
    </div>
  );
}

/** A topic with no site to show. With sites to choose from, the list's own nudge says so. */
function NoSites({ message = "No site reported this in this range." }: { message?: string }): ReactElement {
  return <p className="m-0 font-mono text-xs text-apt-text-dim">{message}</p>;
}

function SiteFigures({ row, site, traffic, vercel, range }: {
  row: JoinedSite;
  site: string;
  traffic: TrafficSection | null;
  vercel: VercelTrafficSection | null;
  range: AnalyticsRange;
}): ReactElement {
  const health = row.health;
  return (
    <div className="flex flex-col gap-4">
      <StatStrip>
        <Stat align="start" label="PostHog views" value={countOrDash(row.posthog?.pageviews)} />
        <Stat align="start" label="Sessions" value={countOrDash(row.posthog?.sessions)} />
        <Stat align="start" label="Vercel views" value={countOrDash(row.vercel?.pageviews)} />
        <Stat align="start" label="Visitors" value={countOrDash(row.vercel?.visitors)} />
        <Stat align="start" label="Errors" value={countOrDash(health?.errors)} />
        <Stat
          align="start"
          label="Failed requests"
          value={health ? <SiteFailureRate failures={health.failures} requests={health.requests} /> : "—"}
        />
        <Stat align="start" label="p95" value={health && health.p95Ms !== null ? `${Math.round(health.p95Ms)}ms` : "—"} />
      </StatStrip>
      <PageviewsChart traffic={traffic} vercel={vercel} site={site} range={range} height={160} />
    </div>
  );
}

function SiteProjects({ projects }: { projects: VercelTrafficSection["roster"] }): ReactElement {
  return (
    <div className="flex flex-col gap-4">
      {projects.map((row) => (
        <StatStrip key={row.project}>
          <Stat align="start" label="Project" value={row.project} />
          <Stat align="start" label="Web Analytics" value={row.analyticsOn ? "On" : "Off"} />
          <Stat align="start" label="Pageviews" value={countOrDash(row.pageviews)} />
          <Stat align="start" label="Visitors" value={countOrDash(row.visitors)} />
        </StatStrip>
      ))}
    </div>
  );
}

function SiteVitals({ rows }: { rows: readonly VitalsRow[] }): ReactElement {
  return (
    <div className="flex flex-col gap-4">
      {rows.map((row) => (
        <StatStrip key={row.host}>
          {/* `www.x.com` and `x.com` are one site, but percentiles do not add, so each keeps its own. */}
          {rows.length > 1 && <Stat align="start" label="Host" value={row.host} />}
          <Stat align="start" label="Samples" value={formatCount(row.samples)} />
          <Stat align="start" label="LCP" value={<VitalCell vital="lcp" value={row.lcp} />} />
          <Stat align="start" label="INP" value={<VitalCell vital="inp" value={row.inp} />} />
          <Stat align="start" label="CLS" value={<VitalCell vital="cls" value={row.cls} />} />
          <Stat align="start" label="FCP" value={<VitalCell vital="fcp" value={row.fcp} />} />
        </StatStrip>
      ))}
    </div>
  );
}

export interface AnalyticsTopicBodyProps {
  topic: Exclude<AnalyticsTopic, "overview">;
  range: AnalyticsRange;
  site: string | null;
  sections: DashboardSections<AnalyticsSectionData>;
  /** Every site, busiest first. */
  rows: readonly JoinedSite[];
  posthogOn: boolean;
  vercelOn: boolean;
  refreshing: boolean;
  posthogUrl: string | undefined;
}

function BreakdownBody({
  topic,
  site,
  sections,
  posthogOn,
  vercelOn,
  refreshing,
  posthogUrl,
}: AnalyticsTopicBodyProps & { topic: BreakdownTopic }): ReactElement {
  const topicLabel = ANALYTICS_TOPICS.find((t) => t.id === topic)?.label ?? topic;
  const dimensions = sections.dimensions.data;
  const rowsOfDimensions = dimensions?.rows ?? null;
  const paths = sections.paths.data;
  const projects = sections.vercel.data?.projects ?? null;

  const totals = site === null ? null : breakdownTotals(topic, rowsOfDimensions, paths, projects, site);

  const posthogSection = topic === "pages" ? sections.paths : sections.dimensions;
  const posthogOnly = topic === "browsers";
  const source = posthogOnly ? "PostHog" : "PostHog and Vercel";

  const notes: string[] = [];
  if (topic === "pages") {
    notes.push("Vercel reports at most 100 pages per project, so a busy site's list from Vercel can be short.");
  } else if (dimensions?.truncated) {
    notes.push("PostHog's rarest combinations were cut off, so small rows may be short.");
  }
  if (posthogOnly) notes.push("Vercel does not report browsers.");

  return (
    <DashboardPanel
      title={site ?? topicLabel}
      source={source}
      sourceHref={posthogOnly ? posthogUrl : undefined}
      section={eitherSection(posthogSection, posthogOnly ? posthogSection : sections.vercel)}
      configured={posthogOnly ? posthogOn : posthogOn || vercelOn}
      refreshing={refreshing}
      note={notes.length > 0 ? notes.join(" ") : undefined}
    >
      {() =>
        site === null || totals === null ? (
          <NoSites />
        ) : (
          <SourceLists topic={topic} topicLabel={topicLabel} site={site} posthog={totals.posthog} vercel={totals.vercel} />
        )
      }
    </DashboardPanel>
  );
}

/** One Analytics sub-topic, in full. The toolbar and the selected site belong to the page around it. */
export function AnalyticsTopicBody(props: AnalyticsTopicBodyProps): ReactElement {
  const { topic, range, site, sections, rows, posthogOn, vercelOn, refreshing, posthogUrl } = props;
  const traffic = sections.traffic.data;
  const vercel = sections.vercel.data;
  const trafficSection = eitherSection(sections.traffic, sections.vercel);

  switch (topic) {
    case "pageviews": {
      const chosen = rows.find((row) => row.key === site);
      return (
        <DashboardPanel
          title={site ?? "Pageviews"}
          source="PostHog and Vercel"
          section={trafficSection}
          configured={posthogOn || vercelOn}
          refreshing={refreshing}
          skeletonHeight={240}
          note={
            chosen
              ? `PostHog ${countOrDash(chosen.posthog?.pageviews)} · Vercel ${countOrDash(chosen.vercel?.pageviews)}. ${PAGEVIEWS_NOTE}`
              : PAGEVIEWS_NOTE
          }
        >
          {() =>
            site === null ? <NoSites /> : <PageviewsChart traffic={traffic} vercel={vercel} site={site} range={range} height={240} />
          }
        </DashboardPanel>
      );
    }
    case "sites": {
      const chosen = rows.find((row) => row.key === site);
      return (
        <DashboardPanel
          title={site ?? "Sites"}
          source="PostHog and Vercel"
          section={trafficSection}
          configured={posthogOn || vercelOn}
          refreshing={refreshing}
          skeletonHeight={240}
          note={`A dash means that source has not seen the site. Errors, failed requests and p95 come from PostHog. ${PAGEVIEWS_NOTE}`}
        >
          {() =>
            site === null ? (
              <NoSites />
            ) : chosen ? (
              <SiteFigures row={chosen} site={site} traffic={traffic} vercel={vercel} range={range} />
            ) : (
              <NoSites message="No traffic from this site in this range." />
            )
          }
        </DashboardPanel>
      );
    }
    case "projects":
      return (
        <DashboardPanel
          title={site ?? "Projects"}
          source="Vercel"
          section={sections.vercel}
          configured={vercelOn}
          refreshing={refreshing}
          note={projectsNote(vercel)}
        >
          {(data) => {
            const projects = data.roster.filter((row) => projectKey(row) === site);
            if (site === null) return <NoSites />;
            return projects.length > 0 ? (
              <SiteProjects projects={projects} />
            ) : (
              <NoSites message="No production Vercel project serves this site." />
            );
          }}
        </DashboardPanel>
      );
    case "vitals":
      return (
        <DashboardPanel
          title={site ?? "Web vitals"}
          source="PostHog"
          sourceHref={posthogUrl}
          section={sections.vitals}
          configured={posthogOn}
          refreshing={refreshing}
          note={VITALS_NOTE}
        >
          {(data) => {
            const vitals = data.filter((row) => siteKey(row.host) === site);
            if (site === null) return <NoSites />;
            return vitals.length > 0 ? (
              <SiteVitals rows={vitals} />
            ) : (
              <NoSites message="No vitals were reported for this site in this range." />
            );
          }}
        </DashboardPanel>
      );
    default:
      return <BreakdownBody {...props} topic={topic} />;
  }
}
