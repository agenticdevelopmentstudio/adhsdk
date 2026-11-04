"use client";
import { useMemo, type ReactElement } from "react";
import { BarList } from "@agenticdevelopertoolkit/ui/blocks/bar-list";
import { formatCount } from "@agenticdevelopertoolkit/ui/blocks/trend-chart";
import { Stat, StatStrip } from "@agenticdevelopertoolkit/ui/components/stat";
import {
  sectionFailures,
  siteReport,
  siteReportIsEmpty,
  type BreakdownTopic,
  type SiteBreakdown,
  type SiteReport,
  type Vital,
} from "../lib/analytics-model";
import { ANALYTICS_SOURCE_COLORS } from "../lib/colors";
import type { AnalyticsRange, AnalyticsSectionData, DashboardSections, Marginal } from "../telemetry/dashboard-types";
import { PAGEVIEWS_NOTE, PageviewsChart, toBars, VITALS_NOTE, VitalCell } from "./AnalyticsParts";
import { DashboardPanel, eitherSection, SiteFailureRate } from "./DashboardParts";

const BREAKDOWN_TITLE: Record<BreakdownTopic, string> = {
  pages: "Pages",
  countries: "Countries",
  referrers: "Referrers",
  devices: "Devices",
  browsers: "Browsers",
};

const VITALS: { vital: Vital; label: string }[] = [
  { vital: "lcp", label: "LCP" },
  { vital: "inp", label: "INP" },
  { vital: "cls", label: "CLS" },
  { vital: "fcp", label: "FCP" },
];

export interface AnalyticsSitePageProps {
  site: string;
  range: AnalyticsRange;
  sections: DashboardSections<AnalyticsSectionData>;
  posthogOn: boolean;
  vercelOn: boolean;
  refreshing: boolean;
  posthogUrl: string | undefined;
}

function SourceList({
  source,
  color,
  label,
  items,
  named,
}: {
  source: string;
  color: string;
  label: string;
  items: readonly Marginal[];
  /** A card with one list says its source in the header, so this line would repeat it. */
  named: boolean;
}): ReactElement {
  return (
    <div className="flex min-w-0 flex-col gap-2">
      {named && <div className="font-mono text-[10px] uppercase tracking-[0.06em] text-apt-text-dim">{source}</div>}
      <BarList ariaLabel={`${label}, from ${source}`} items={toBars(items)} color={color} maxItems={Infinity} />
    </div>
  );
}

function BreakdownCard({
  breakdown,
  site,
  sections,
  refreshing,
  posthogUrl,
}: {
  breakdown: SiteBreakdown;
  site: string;
  sections: DashboardSections<AnalyticsSectionData>;
  refreshing: boolean;
  posthogUrl: string | undefined;
}): ReactElement {
  const { topic, posthog, vercel } = breakdown;
  const title = BREAKDOWN_TITLE[topic];
  const label = `${title} by pageviews for ${site}`;
  const posthogSection = topic === "pages" ? sections.paths : sections.dimensions;
  const both = posthog !== null && vercel !== null;
  const notes: string[] = [];
  if (topic === "pages" && vercel) {
    notes.push("Vercel reports at most 100 pages per project, so a busy site's list from Vercel can be short.");
  } else if (topic !== "pages" && posthog && sections.dimensions.data?.truncated) {
    notes.push("PostHog's rarest combinations were cut off, so small rows may be short.");
  }
  return (
    <DashboardPanel
      title={title}
      source={both ? "PostHog and Vercel" : posthog ? "PostHog" : "Vercel"}
      sourceHref={posthog && !vercel ? posthogUrl : undefined}
      section={eitherSection(posthog ? posthogSection : sections.vercel, vercel ? sections.vercel : posthogSection)}
      configured
      refreshing={refreshing}
      note={notes.length > 0 ? notes.join(" ") : undefined}
    >
      {() => (
        <div className="flex flex-col gap-4">
          {posthog && (
            <SourceList source="PostHog" color={ANALYTICS_SOURCE_COLORS.posthog} label={label} items={posthog} named={both} />
          )}
          {vercel && (
            <SourceList source="Vercel" color={ANALYTICS_SOURCE_COLORS.vercel} label={label} items={vercel} named={both} />
          )}
        </div>
      )}
    </DashboardPanel>
  );
}

function ProjectsCard({
  report,
  sections,
  refreshing,
}: {
  report: SiteReport;
  sections: DashboardSections<AnalyticsSectionData>;
  refreshing: boolean;
}): ReactElement {
  const failed = sections.vercel.data?.failed ?? 0;
  return (
    <DashboardPanel
      title={report.projects.length === 1 ? "Project" : "Projects"}
      source="Vercel"
      section={sections.vercel}
      configured
      refreshing={refreshing}
      note={failed > 0 ? `${failed} Vercel projects could not be read, so these figures may be short.` : undefined}
    >
      {() => (
        <div className="flex flex-col gap-4">
          {report.projects.map((row) => (
            <StatStrip key={row.project}>
              <Stat align="start" label="Project" value={row.project} />
              <Stat align="start" label="Web Analytics" value={row.analyticsOn ? "On" : "Off"} />
              {row.pageviews ? <Stat align="start" label="Pageviews" value={formatCount(row.pageviews)} /> : null}
              {row.visitors ? <Stat align="start" label="Visitors" value={formatCount(row.visitors)} /> : null}
            </StatStrip>
          ))}
        </div>
      )}
    </DashboardPanel>
  );
}

/**
 * Everything one site has, as one scrolling page of the shared panels. What it does not have is not
 * drawn: `siteReport` decides, so no card has an empty state of its own. What could not be READ is a
 * different thing and stays on the page, or a failed provider would look like a quiet one.
 */
export function AnalyticsSitePage({
  site,
  range,
  sections,
  posthogOn,
  vercelOn,
  refreshing,
  posthogUrl,
}: AnalyticsSitePageProps): ReactElement {
  const report = useMemo(() => siteReport(sections, site), [sections, site]);
  const failures = useMemo(
    () => sectionFailures(sections, { posthog: posthogOn, vercel: vercelOn }),
    [sections, posthogOn, vercelOn],
  );
  const { posthog, vercel, health, breakdowns, projects, vitals } = report;
  const empty = siteReportIsEmpty(report);
  const charted = (posthog?.pageviews ?? 0) > 0 || (vercel?.pageviews ?? 0) > 0;
  const bothCharted = (posthog?.pageviews ?? 0) > 0 && (vercel?.pageviews ?? 0) > 0;

  return (
    <>
      {failures.map((failure) => (
        <p key={`${failure.source}:${failure.error}`} role="alert" className="m-0 font-mono text-xs text-apt-red">
          Could not load {failure.what.join(", ")} from {failure.source}: {failure.error}
        </p>
      ))}

      {empty && refreshing && (
        <DashboardPanel
          title={site}
          source="PostHog and Vercel"
          section={{ data: null, error: null, updatedAt: null }}
          configured
          refreshing
          skeletonHeight={240}
        >
          {() => null}
        </DashboardPanel>
      )}

      {empty && !refreshing && failures.length === 0 && (
        <p className="m-0 font-mono text-xs text-apt-text-dim">Nothing reported for this site in this range.</p>
      )}

      {(posthog || vercel || health) && (
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-2 xl:grid-cols-3">
          {posthog && (
            <DashboardPanel
              title="PostHog"
              source="PostHog"
              sourceHref={posthogUrl}
              section={sections.traffic}
              configured
              refreshing={refreshing}
              note="A session is about one page load"
            >
              {() => (
                <StatStrip>
                  <Stat align="start" label="Pageviews" value={formatCount(posthog.pageviews)} />
                  <Stat align="start" label="Sessions" value={formatCount(posthog.sessions)} />
                </StatStrip>
              )}
            </DashboardPanel>
          )}
          {vercel && (
            <DashboardPanel
              title="Vercel"
              source="Web Analytics"
              section={sections.vercel}
              configured
              refreshing={refreshing}
            >
              {() => (
                <StatStrip>
                  <Stat align="start" label="Pageviews" value={formatCount(vercel.pageviews)} />
                  <Stat align="start" label="Visitors" value={formatCount(vercel.visitors)} />
                </StatStrip>
              )}
            </DashboardPanel>
          )}
          {health && (
            <DashboardPanel
              title="Errors and requests"
              source="PostHog"
              sourceHref={posthogUrl}
              section={sections.health}
              configured
              refreshing={refreshing}
            >
              {() => (
                <StatStrip>
                  <Stat align="start" label="Errors" value={formatCount(health.errors)} />
                  {health.requests > 0 && (
                    <Stat
                      align="start"
                      label="Failed requests"
                      value={<SiteFailureRate failures={health.failures} requests={health.requests} />}
                    />
                  )}
                  {health.p95Ms !== null && <Stat align="start" label="p95" value={`${Math.round(health.p95Ms)}ms`} />}
                </StatStrip>
              )}
            </DashboardPanel>
          )}
        </div>
      )}

      {charted && (
        <DashboardPanel
          title="Pageviews"
          source={bothCharted ? "PostHog and Vercel" : (posthog?.pageviews ?? 0) > 0 ? "PostHog" : "Vercel"}
          section={eitherSection(sections.traffic, sections.vercel)}
          configured
          refreshing={refreshing}
          note={bothCharted ? PAGEVIEWS_NOTE : undefined}
        >
          {() => (
            <PageviewsChart
              traffic={(posthog?.pageviews ?? 0) > 0 ? sections.traffic.data : null}
              vercel={(vercel?.pageviews ?? 0) > 0 ? sections.vercel.data : null}
              site={site}
              range={range}
              height={240}
            />
          )}
        </DashboardPanel>
      )}

      {breakdowns.length > 0 && (
        <div className="grid grid-cols-1 items-start gap-4 lg:grid-cols-2 xl:grid-cols-3">
          {breakdowns.map((breakdown) => (
            <BreakdownCard
              key={breakdown.topic}
              breakdown={breakdown}
              site={site}
              sections={sections}
              refreshing={refreshing}
              posthogUrl={posthogUrl}
            />
          ))}
        </div>
      )}

      {projects.length > 0 && <ProjectsCard report={report} sections={sections} refreshing={refreshing} />}

      {vitals.length > 0 && (
        <DashboardPanel
          title="Web vitals"
          source="PostHog"
          sourceHref={posthogUrl}
          section={sections.vitals}
          configured
          refreshing={refreshing}
          note={VITALS_NOTE}
        >
          {() => (
            <div className="flex flex-col gap-4">
              {vitals.map((row) => (
                <StatStrip key={row.host}>
                  {/* `www.x.com` and `x.com` are one site, but percentiles do not add, so each keeps its own. */}
                  {vitals.length > 1 && <Stat align="start" label="Host" value={row.host} />}
                  <Stat align="start" label="Samples" value={formatCount(row.samples)} />
                  {VITALS.map(({ vital, label }) =>
                    row[vital] === null ? null : (
                      <Stat
                        key={vital}
                        align="start"
                        label={label}
                        value={<VitalCell vital={vital} value={row[vital]} />}
                      />
                    ),
                  )}
                </StatStrip>
              ))}
            </div>
          )}
        </DashboardPanel>
      )}
    </>
  );
}
