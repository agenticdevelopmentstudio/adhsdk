"use client";
import { useMemo, type ReactElement } from "react";
import { formatCount, TrendChart } from "@adh-sdk/ui/blocks/trend-chart";
import { DataTable, type DataTableColumn } from "@adh-sdk/ui/components/data-table";
import { Stat, StatStrip } from "@adh-sdk/ui/components/stat";
import { useNow } from "../hooks/use-now";
import { bucketDetail, bucketLabel } from "../lib/analytics-model";
import { SITE_ERROR_SERIES_COLORS } from "../lib/colors";
import {
  errorRowId,
  errorsSiteFailures,
  errorsSiteReport,
  errorsSiteReportIsEmpty,
  failedRequestRowId,
} from "../lib/errors-model";
import type {
  DashboardSections,
  ErrorsSectionData,
  SiteErrorRow,
  SiteFailedRequestRow,
} from "../telemetry/dashboard-types";
import { DashboardPanel, formatAge, SiteFailureRate, WrappedCell } from "./DashboardParts";

const TRUNCATED_NOTE = "PostHog's rarest rows across the fleet were cut off, so this list may be short.";

// Written once, here: a column an error never reported is left out with the rest of what a site lacks.
const ERROR_DETAILS: { key: string; header: string; value: (row: SiteErrorRow) => string | null }[] = [
  { key: "feature", header: "Feature", value: (row) => row.feature },
  { key: "step", header: "Step", value: (row) => row.step },
  { key: "boundary", header: "Boundary", value: (row) => row.boundary },
  { key: "page", header: "Page", value: (row) => row.page },
];

export interface ErrorsSitePageProps {
  site: string;
  sections: DashboardSections<ErrorsSectionData>;
  posthogOn: boolean;
  refreshing: boolean;
  posthogUrl: string | undefined;
}

/**
 * Everything one site reported, as one scrolling page of the shared panels. What it does not have is
 * not drawn: `errorsSiteReport` decides, so no card has an empty state of its own. What could not be
 * READ stays on the page, or a failed provider would look like a quiet site.
 */
export function ErrorsSitePage({ site, sections, posthogOn, refreshing, posthogUrl }: ErrorsSitePageProps): ReactElement {
  const now = useNow();
  const report = useMemo(() => errorsSiteReport(sections, site), [sections, site]);
  const failures = useMemo(() => (posthogOn ? errorsSiteFailures(sections) : []), [sections, posthogOn]);
  const { health, chart, errors, requests } = report;
  const empty = errorsSiteReportIsEmpty(report);
  const truncated = sections.detail.data?.truncated ? TRUNCATED_NOTE : undefined;

  const errorColumns = useMemo((): DataTableColumn<SiteErrorRow>[] => {
    const seen = ERROR_DETAILS.filter(({ value }) => errors.some((row) => value(row) !== null));
    return [
      { key: "name", header: "Error", width: "minmax(12rem, 1fr)", render: (row) => <WrappedCell>{row.name}</WrappedCell> },
      ...seen.map(({ key, header, value }) => ({
        key,
        header,
        render: (row: SiteErrorRow) => <WrappedCell>{value(row) ?? "—"}</WrappedCell>,
      })),
      { key: "count", header: "Count", render: (row) => formatCount(row.count) },
      { key: "lastSeen", header: "Last seen", render: (row) => formatAge(row.lastSeen, now) },
    ];
  }, [errors, now]);

  const requestColumns: DataTableColumn<SiteFailedRequestRow>[] = [
    { key: "path", header: "Path", width: "minmax(14rem, 1fr)", render: (row) => <WrappedCell>{row.path}</WrappedCell> },
    { key: "status", header: "Status", render: (row) => (row.status === 0 ? "No response" : String(row.status)) },
    { key: "method", header: "Method", render: (row) => row.method ?? "—" },
    { key: "count", header: "Count", render: (row) => formatCount(row.count) },
    { key: "lastSeen", header: "Last seen", render: (row) => formatAge(row.lastSeen, now) },
  ];

  if (!posthogOn) {
    return (
      <DashboardPanel title={site} source="PostHog" section={sections.detail} configured={false} refreshing={false}>
        {() => null}
      </DashboardPanel>
    );
  }

  return (
    <>
      {failures.map((failure) => (
        <p key={failure.error} role="alert" className="m-0 font-mono text-xs text-apt-red">
          Could not load {failure.what.join(", ")} from {failure.source}: {failure.error}
        </p>
      ))}

      {empty && refreshing && (
        <DashboardPanel
          title={site}
          source="PostHog"
          section={{ data: null, error: null, updatedAt: null }}
          configured
          refreshing
          skeletonHeight={240}
        >
          {() => null}
        </DashboardPanel>
      )}

      {empty && !refreshing && failures.length === 0 && (
        <p className="m-0 font-mono text-xs text-apt-text-dim">Nothing reported for this site in the last 30 days.</p>
      )}

      {health && (
        <DashboardPanel
          title="Last 30 days"
          source="PostHog"
          sourceHref={posthogUrl}
          section={sections.sites}
          configured
          refreshing={refreshing}
          note="Failed means a 5xx or no response at all."
        >
          {() => (
            <StatStrip>
              <Stat align="start" label="Errors" value={formatCount(health.errors)} />
              {health.requests > 0 && <Stat align="start" label="Requests" value={formatCount(health.requests)} />}
              {health.requests > 0 && (
                <Stat
                  align="start"
                  label="Failed"
                  value={<SiteFailureRate failures={health.failures} requests={health.requests} />}
                />
              )}
              {health.p95Ms !== null && <Stat align="start" label="p95" value={`${Math.round(health.p95Ms)}ms`} />}
            </StatStrip>
          )}
        </DashboardPanel>
      )}

      {chart && (
        <DashboardPanel
          title="Per day"
          source="PostHog"
          sourceHref={posthogUrl}
          section={sections.detail}
          configured
          refreshing={refreshing}
        >
          {() => (
            <TrendChart
              ariaLabel={`Errors and failed requests per day for ${site}, last 30 days`}
              labels={chart.buckets}
              series={[
                { name: "Errors", color: SITE_ERROR_SERIES_COLORS.errors, values: chart.errors },
                { name: "Failed requests", color: SITE_ERROR_SERIES_COLORS.failures, values: chart.failures },
              ]}
              height={240}
              formatLabel={(label) => bucketLabel(label, "30d")}
              formatDetail={(label) => bucketDetail(label, "30d")}
            />
          )}
        </DashboardPanel>
      )}

      {errors.length > 0 && (
        <DashboardPanel
          title="Errors"
          source="PostHog"
          sourceHref={posthogUrl}
          section={sections.detail}
          configured
          refreshing={refreshing}
          note={["PostHog holds an error's name and where it happened, never its message.", truncated].filter(Boolean).join(" ")}
        >
          {() => (
            <div className="-mx-1">
              <DataTable
                ariaLabel={`Errors reported by ${site}`}
                columns={errorColumns}
                rows={errors}
                getRowId={errorRowId}
                autoSizeColumns
                emptyLabel="No errors."
              />
            </div>
          )}
        </DashboardPanel>
      )}

      {requests.length > 0 && (
        <DashboardPanel
          title="Failed requests"
          source="PostHog"
          sourceHref={posthogUrl}
          section={sections.detail}
          configured
          refreshing={refreshing}
          note={truncated}
        >
          {() => (
            <div className="-mx-1">
              <DataTable
                ariaLabel={`Failed requests for ${site}`}
                columns={requestColumns}
                rows={requests}
                getRowId={failedRequestRowId}
                autoSizeColumns
                emptyLabel="No failed requests."
              />
            </div>
          )}
        </DashboardPanel>
      )}
    </>
  );
}
