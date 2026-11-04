"use client";
import { useMemo, useState, type ReactElement } from "react";
import { TrendingUp, X } from "lucide-react";
import { BarList } from "@adh-sdk/ui/blocks/bar-list";
import { StatCard } from "@adh-sdk/ui/blocks/stat-card";
import { formatCount } from "@adh-sdk/ui/blocks/trend-chart";
import { ToggleGroup, ToggleGroupItem } from "@adh-sdk/ui/components/toggle-group";
import { useAnalyticsDashboard } from "../hooks/use-dashboards";
import {
  dimensionTotals,
  joinSites,
  pathTotals,
  siteKey,
  vercelTotals,
  type Dimension,
  type JoinedSite,
  type VercelBreakdown,
} from "../lib/analytics-model";
import { ANALYTICS_SOURCE_COLORS } from "../lib/colors";
import {
  ANALYTICS_RANGES,
  type AnalyticsRange,
  type AnalyticsSectionData,
  type DashboardSections,
} from "../telemetry/dashboard-types";
import {
  AnalyticsTopicBody,
  countOrDash,
  PAGEVIEWS_NOTE,
  PageviewsChart,
  projectsNote,
  SitesTable,
  toBars,
  VITALS_NOTE,
  VitalsTable,
} from "./AnalyticsTopics";
import type { AnalyticsTopic } from "./board-views";
import { DashboardPanel, eitherSection, SeeAll } from "./DashboardParts";
import { useStatusHost } from "./StatusHost";

const RANGE_LABEL: Record<AnalyticsRange, string> = { "24h": "24 hours", "7d": "7 days", "30d": "30 days" };

const EMPTY_SECTIONS: DashboardSections<AnalyticsSectionData> = {
  traffic: { data: null, error: null, updatedAt: null },
  dimensions: { data: null, error: null, updatedAt: null },
  paths: { data: null, error: null, updatedAt: null },
  vitals: { data: null, error: null, updatedAt: null },
  health: { data: null, error: null, updatedAt: null },
  vercel: { data: null, error: null, updatedAt: null },
};

const POSTHOG_BREAKDOWNS: { dimension: Dimension; title: string; topic: AnalyticsTopic }[] = [
  { dimension: "country", title: "Countries", topic: "countries" },
  { dimension: "referrer", title: "Referrers", topic: "referrers" },
  { dimension: "device", title: "Devices", topic: "devices" },
  { dimension: "browser", title: "Browsers", topic: "browsers" },
];

const VERCEL_BREAKDOWNS: { breakdown: VercelBreakdown; title: string; topic: AnalyticsTopic }[] = [
  { breakdown: "countries", title: "Countries", topic: "countries" },
  { breakdown: "referrers", title: "Referrers", topic: "referrers" },
  { breakdown: "devices", title: "Devices", topic: "devices" },
  { breakdown: "paths", title: "Pages", topic: "pages" },
];

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

/**
 * The Analytics topic: traffic per site and in aggregate, from PostHog and from Vercel Web
 * Analytics. The two stay side by side and are never added together. They overlap on the sites
 * reporting to both and count differently, so a sum would describe nothing. Only production
 * sites report analytics, so that is all this page reads.
 *
 * Picking a site narrows everything without another request. Overview holds every panel, each with
 * a way to its own sub-topic, where nothing is held back and every site gets its own card. This
 * stays mounted across sub-topics, so the range and the site carry from one to the next.
 */
export function AnalyticsView({ topic }: { topic: AnalyticsTopic }): ReactElement {
  const [range, setRange] = useState<AnalyticsRange>("7d");
  const [site, setSite] = useState<string | null>(null);
  const [sort, setSort] = useState<{ key: string; dir: "asc" | "desc" }>({ key: "phViews", dir: "desc" });

  const { posthogUrl } = useStatusHost();
  const query = useAnalyticsDashboard(range);
  const body = query.data;
  const sections = body?.sections ?? EMPTY_SECTIONS;
  const refreshing = body ? body.refreshing : query.isLoading;
  const posthogOn = body?.configured.posthog ?? true;
  const vercelOn = body?.configured.vercel ?? true;

  const traffic = sections.traffic.data;
  const vercel = sections.vercel.data;
  const health = sections.health.data;

  const rows = useMemo(() => joinSites(traffic, vercel, health), [traffic, vercel, health]);
  const sortedRows = useMemo(() => sortSites(rows, sort.key as SiteSortKey, sort.dir), [rows, sort]);
  const chosen = site === null ? null : (rows.find((row) => row.key === site) ?? null);

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

  return (
    <div className="min-h-0 flex-1 overflow-y-auto">
      <div className="flex w-full flex-col gap-4 p-4">
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
            <span role="status" className="font-mono text-[11px] text-apt-text-dim">
              Refreshing…
            </span>
          )}
        </div>

        {query.isError && !body && (
          <p role="alert" className="m-0 font-mono text-xs text-apt-red">
            Could not load analytics: {query.error.message}
          </p>
        )}

        {topic !== "overview" ? (
          <AnalyticsTopicBody
            topic={topic}
            range={range}
            site={site}
            onSite={setSite}
            sections={sections}
            rows={rows}
            sortedRows={sortedRows}
            sort={sort}
            onSort={setSort}
            posthogOn={posthogOn}
            vercelOn={vercelOn}
            refreshing={refreshing}
            posthogUrl={posthogUrl}
          />
        ) : (
          <>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <StatCard
                title="PostHog"
                className="min-w-0"
                icon={<TrendingUp size={15} className="text-apt-blue" />}
                link={posthogUrl ? { href: posthogUrl, label: "PostHog" } : undefined}
                statLayout="strip"
                stats={[
                  { label: "Pageviews", value: countOrDash(figures.posthogViews) },
                  { label: "Sessions", value: countOrDash(figures.posthogSessions) },
                ]}
                footnote="A session is about one page load"
              />
              <StatCard
                title="Vercel"
                className="min-w-0"
                icon={<TrendingUp size={15} className="text-apt-orange" />}
                statLayout="strip"
                stats={[
                  { label: "Pageviews", value: countOrDash(figures.vercelViews) },
                  { label: "Visitors", value: countOrDash(figures.vercelVisitors) },
                ]}
                footnote="Production Web Analytics"
              />
            </div>

            <DashboardPanel
              title={site === null ? "Pageviews, all sites" : `Pageviews, ${site}`}
              source="PostHog and Vercel"
              section={eitherSection(sections.traffic, sections.vercel)}
              configured={posthogOn || vercelOn}
              refreshing={refreshing}
              skeletonHeight={240}
              actions={<SeeAll href="/analytics/pageviews" what="pageviews" />}
              note={PAGEVIEWS_NOTE}
            >
              {() => <PageviewsChart traffic={traffic} vercel={vercel} site={site} range={range} height={240} />}
            </DashboardPanel>

            <DashboardPanel
              title="Sites"
              source="PostHog and Vercel"
              section={eitherSection(sections.traffic, sections.vercel)}
              configured={posthogOn || vercelOn}
              refreshing={refreshing}
              actions={<SeeAll href="/analytics/sites" what="sites" />}
              note="Select a site to narrow every topic to it. A dash means that source has not seen the site. Errors, failed requests and p95 come from PostHog."
            >
              {() => (
                <div className="-mx-1 max-h-[420px] overflow-auto">
                  <SitesTable rows={sortedRows} site={site} onSite={setSite} sort={sort} onSort={setSort} />
                </div>
              )}
            </DashboardPanel>

            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              <DashboardPanel
                title="Top pages"
                source="PostHog"
                sourceHref={posthogUrl}
                section={sections.paths}
                configured={posthogOn}
                refreshing={refreshing}
                actions={<SeeAll href="/analytics/pages" what="pages" />}
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
              {POSTHOG_BREAKDOWNS.map(({ dimension, title, topic: target }) => (
                <DashboardPanel
                  key={dimension}
                  title={title}
                  source="PostHog"
                  sourceHref={posthogUrl}
                  section={sections.dimensions}
                  configured={posthogOn}
                  refreshing={refreshing}
                  actions={<SeeAll href={`/analytics/${target}`} what={`${title.toLowerCase()} from PostHog`} />}
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
                actions={<SeeAll href="/analytics/projects" what="projects" />}
                note={projectsNote(vercel)}
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
              {VERCEL_BREAKDOWNS.map(({ breakdown, title, topic: target }) => (
                <DashboardPanel
                  key={breakdown}
                  title={title}
                  source="Vercel"
                  section={sections.vercel}
                  configured={vercelOn}
                  refreshing={refreshing}
                  actions={<SeeAll href={`/analytics/${target}`} what={`${title.toLowerCase()} from Vercel`} />}
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
              sourceHref={posthogUrl}
              section={sections.vitals}
              configured={posthogOn}
              refreshing={refreshing}
              actions={<SeeAll href="/analytics/vitals" what="web vitals" />}
              note={VITALS_NOTE}
            >
              {(data) => (
                <div className="-mx-1 max-h-[320px] overflow-auto">
                  <VitalsTable rows={data} site={site} />
                </div>
              )}
            </DashboardPanel>
          </>
        )}

        <p className="m-0 font-mono text-[10px] leading-relaxed text-apt-text-dim">
          Production sites only. PostHog runs cookieless, so its visitors, sessions and pageviews come out nearly equal: treat sessions as page
          loads, not people. Much of its traffic looks automated. Times are UTC.
        </p>
      </div>
    </div>
  );
}
