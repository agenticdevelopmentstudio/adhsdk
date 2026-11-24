"use client";
import { useMemo, useState, type ReactElement } from "react";
import { TrendingUp } from "lucide-react";
import { BarList } from "@adh-sdk/ui/blocks/bar-list";
import { StatCard } from "@adh-sdk/ui/blocks/stat-card";
import { formatCount } from "@adh-sdk/ui/blocks/trend-chart";
import { useAnalyticsDashboard } from "../hooks/use-dashboards";
import { ANALYTICS_SOURCE_COLORS } from "../lib/colors";
import {
  ANALYTICS_RANGES,
  type AnalyticsRange,
  type AnalyticsSectionData,
  type AnalyticsViews,
  type DashboardSections,
  type Dimension,
  type JoinedSite,
  type VercelBreakdown,
} from "../telemetry/dashboard-types";
import {
  countOrDash,
  PAGEVIEWS_NOTE,
  PageviewsChart,
  projectsNote,
  SitesTable,
  toBars,
  VITALS_NOTE,
  VitalsTable,
} from "./AnalyticsParts";
import { AnalyticsSitePage } from "./AnalyticsSitePage";
import { DashboardPanel, eitherSection, VIEWS_MISSING, viewsMissing } from "./DashboardParts";
import { OptionSection, OptionsGear, optionRow } from "./OptionsGear";
import { useStatusHost } from "./StatusHost";

const RANGE_LABEL: Record<AnalyticsRange, string> = { "24h": "24 hours", "7d": "7 days", "30d": "30 days" };

export const DEFAULT_ANALYTICS_RANGE: AnalyticsRange = "7d";

/** The range every Analytics topic reads, as the shared options gear. The board puts it on the
 *  breadcrumb bar, because it applies to the whole topic rather than to one panel. */
export function AnalyticsRangeGear({
  range,
  onRange,
}: {
  range: AnalyticsRange;
  onRange: (range: AnalyticsRange) => void;
}): ReactElement {
  return (
    <OptionsGear
      changedCount={range === DEFAULT_ANALYTICS_RANGE ? 0 : 1}
      summary={`Range: last ${RANGE_LABEL[range]}`}
      label="Analytics options"
      menuWidth={140}
    >
      {(close) => (
        <OptionSection title="Range">
          {ANALYTICS_RANGES.map((value) => (
            <label key={value} style={optionRow(value === range)}>
              <input
                className="adh-check"
                type="radio"
                name="analytics-range"
                checked={value === range}
                onChange={() => {
                  onRange(value);
                  close();
                }}
              />
              last {RANGE_LABEL[value]}
            </label>
          ))}
        </OptionSection>
      )}
    </OptionsGear>
  );
}

const EMPTY_SECTIONS: DashboardSections<AnalyticsSectionData> = {
  traffic: { data: null, error: null, updatedAt: null },
  dimensions: { data: null, error: null, updatedAt: null },
  paths: { data: null, error: null, updatedAt: null },
  vitals: { data: null, error: null, updatedAt: null },
  health: { data: null, error: null, updatedAt: null },
  vercel: { data: null, error: null, updatedAt: null },
};

// Before the first answer. Every panel that draws from it is gated on its section having answered,
// so none of this is shown as a finding.
const EMPTY_VIEWS: AnalyticsViews = {
  sites: [],
  joined: [],
  pageviews: { labels: [], posthog: null, vercel: null },
  pages: null,
  dimensions: null,
  vercelProjects: null,
  vercelBreakdowns: null,
  vitals: null,
  siteReports: {},
  failures: [],
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
 * With no site this is the overview: every panel, across every site. With one it is that site's own
 * page. The board holds the range, because its list of sites reads the same dashboard.
 */
export function AnalyticsView({
  range,
  site,
  onSite,
}: {
  range: AnalyticsRange;
  /** The open site, or null for the overview. */
  site: string | null;
  onSite: (site: string) => void;
}): ReactElement {
  const [sort, setSort] = useState<{ key: string; dir: "asc" | "desc" }>({ key: "phViews", dir: "desc" });

  const { posthogUrl } = useStatusHost();
  const query = useAnalyticsDashboard(range);
  const body = query.data;
  const sections = body?.sections ?? EMPTY_SECTIONS;
  const noViews = viewsMissing(body);
  const views = body?.views ?? EMPTY_VIEWS;
  // A failed read keeps the last body (TanStack Query holds on to it), and that body may have
  // been taken mid-refresh: claiming it is still filling in would leave "Refreshing…" and the
  // skeletons up for a refresh nobody can see finish. The alert below says what happened instead.
  const refreshing = query.isError ? false : body ? body.refreshing : query.isLoading;
  const posthogOn = body?.configured.posthog ?? true;
  const vercelOn = body?.configured.vercel ?? true;

  const traffic = sections.traffic.data;
  const vercel = sections.vercel.data;
  const sortedRows = useMemo(() => sortSites(views.joined, sort.key as SiteSortKey, sort.dir), [views.joined, sort]);
  const showRefreshing = refreshing || query.isPlaceholderData;

  return (
    <div className="min-h-0 flex-1 overflow-y-auto">
      <div className="flex w-full flex-col gap-4 p-4">
        {showRefreshing && (
          <span role="status" className="font-mono text-[11px] text-apt-text-dim">
            Refreshing…
          </span>
        )}

        {query.isError && (
          // Shown with a body as well: a refetch that fails keeps the last one on screen, and
          // without this nothing would say it is no longer being kept up to date.
          <p role="alert" className="m-0 font-mono text-xs text-apt-red">
            {body ? "Could not refresh analytics, so this is the last answer" : "Could not load analytics"}:{" "}
            {query.error.message}
          </p>
        )}

        {site !== null ? (
          // With no answer at all there is no report to draw: the alert above is the whole story.
          // The report is drawn from the views, so an answer without them is said to be that.
          noViews ? (
            <p role="alert" className="m-0 font-mono text-xs text-apt-gold">
              {VIEWS_MISSING}
            </p>
          ) : (body || refreshing) && (
            <AnalyticsSitePage
              site={site}
              range={range}
              sections={sections}
              views={views}
              refreshing={refreshing}
              posthogUrl={posthogUrl}
            />
          )
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
                  { label: "Pageviews", value: countOrDash(traffic?.totals.pageviews) },
                  { label: "Sessions", value: countOrDash(traffic?.totals.sessions) },
                ]}
                footnote="A session is about one page load"
              />
              <StatCard
                title="Vercel"
                className="min-w-0"
                icon={<TrendingUp size={15} className="text-apt-orange" />}
                statLayout="strip"
                stats={[
                  { label: "Pageviews", value: countOrDash(vercel?.totals.pageviews) },
                  { label: "Visitors", value: countOrDash(vercel?.totals.visitors) },
                ]}
                footnote="Production Web Analytics"
              />
            </div>

            <DashboardPanel
              title="Pageviews, all sites"
              source="PostHog and Vercel"
              section={eitherSection({ PostHog: sections.traffic, Vercel: sections.vercel })}
              configured={posthogOn || vercelOn}
              refreshing={refreshing}
              unavailable={noViews ? VIEWS_MISSING : undefined}
              skeletonHeight={240}
              note={PAGEVIEWS_NOTE}
            >
              {() => <PageviewsChart series={views.pageviews} site={null} range={range} height={240} />}
            </DashboardPanel>

            <DashboardPanel
              title="Sites"
              source="PostHog and Vercel"
              section={eitherSection({ PostHog: sections.traffic, Vercel: sections.vercel })}
              configured={posthogOn || vercelOn}
              refreshing={refreshing}
              unavailable={noViews ? VIEWS_MISSING : undefined}
              note="Select a site to open it. A dash means that source has not seen the site. Errors, failed requests and p95 come from PostHog."
            >
              {() => (
                <div className="-mx-1 max-h-[420px] overflow-auto">
                  <SitesTable rows={sortedRows} onSite={onSite} sort={sort} onSort={setSort} />
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
                unavailable={noViews ? VIEWS_MISSING : undefined}
              >
                {() => (
                  <BarList
                    ariaLabel="Top pages by pageviews, from PostHog"
                    items={toBars(views.pages ?? [])}
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
                  sourceHref={posthogUrl}
                  section={sections.dimensions}
                  configured={posthogOn}
                  refreshing={refreshing}
                  unavailable={noViews ? VIEWS_MISSING : undefined}
                  note={sections.dimensions.data?.truncated ? "The rarest combinations were cut off, so small rows may be short." : undefined}
                >
                  {() => (
                    <BarList
                      ariaLabel={`${title} by pageviews, from PostHog`}
                      items={toBars(views.dimensions?.[dimension] ?? [])}
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
                unavailable={noViews ? VIEWS_MISSING : undefined}
                note={projectsNote(vercel)}
              >
                {() => (
                  <BarList
                    ariaLabel="Vercel projects by pageviews"
                    items={(views.vercelProjects ?? []).map((p) => ({
                      name: p.site,
                      value: p.pageviews,
                      detail: `${formatCount(p.pageviews)} · ${formatCount(p.visitors)} visitors`,
                    }))}
                    color={ANALYTICS_SOURCE_COLORS.vercel}
                    onSelect={onSite}
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
                  unavailable={noViews ? VIEWS_MISSING : undefined}
                >
                  {() => (
                    <BarList
                      ariaLabel={`${title} by pageviews, from Vercel`}
                      items={toBars(views.vercelBreakdowns?.[breakdown] ?? [])}
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
              unavailable={noViews ? VIEWS_MISSING : undefined}
              note={VITALS_NOTE}
            >
              {() => (
                <div className="-mx-1 max-h-[320px] overflow-auto">
                  <VitalsTable rows={views.vitals ?? []} />
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
