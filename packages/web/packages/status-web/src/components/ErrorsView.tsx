"use client";
import { useMemo, useState, type ReactElement } from "react";
import { Bug } from "lucide-react";
import { BarList } from "@agenticdevelopertoolkit/ui/blocks/bar-list";
import { StatCard } from "@agenticdevelopertoolkit/ui/blocks/stat-card";
import { formatCount, TrendChart } from "@agenticdevelopertoolkit/ui/blocks/trend-chart";
import { DataTable, type DataTableColumn } from "@agenticdevelopertoolkit/ui/components/data-table";
import { ExternalLink } from "@agenticdevelopertoolkit/ui/components/external-link";
import { Input } from "@agenticdevelopertoolkit/ui/components/input";
import { StatusDot, type StatusDotTone } from "@agenticdevelopertoolkit/ui/components/status-dot";
import { ToggleGroup, ToggleGroupItem } from "@agenticdevelopertoolkit/ui/components/toggle-group";
import { useErrorsDashboard } from "../hooks/use-dashboards";
import { useNow } from "../hooks/use-now";
import { bucketDetail, bucketLabel } from "../lib/analytics-model";
import { ERROR_CHART_COLOR } from "../lib/colors";
import { MOST_ERRORS_LIMIT, mostErrorSites } from "../lib/errors-model";
import type { DashboardSections, ErrorIssue, ErrorsSectionData } from "../telemetry/dashboard-types";
import { DashboardPanel, formatAge, WrappedCell } from "./DashboardParts";
import { ErrorsSitePage } from "./ErrorsSitePage";
import { useStatusHost } from "./StatusHost";

const EMPTY_SECTIONS: DashboardSections<ErrorsSectionData> = {
  issues: { data: null, error: null, updatedAt: null },
  sites: { data: null, error: null, updatedAt: null },
  detail: { data: null, error: null, updatedAt: null },
};

type IssueView = "active" | "backlog" | "all";
const ISSUE_VIEWS: { id: IssueView; label: string }[] = [
  { id: "active", label: "Active" },
  { id: "backlog", label: "Backlog" },
  { id: "all", label: "All" },
];

function levelTone(level: string | null): StatusDotTone {
  switch (level) {
    case "fatal":
    case "error":
      return "error";
    case "warning":
      return "accent";
    default:
      return "blue";
  }
}

/** Issues on one view, narrowed by a search over every field a person would remember. */
export function filterIssues(issues: readonly ErrorIssue[], view: IssueView, search: string): ErrorIssue[] {
  const needle = search.trim().toLowerCase();
  return issues.filter((issue) => {
    if (view === "active" && !issue.active) return false;
    if (view === "backlog" && issue.active) return false;
    if (needle === "") return true;
    return [issue.title, issue.type, issue.source, issue.shortId, issue.release, issue.project].some((field) =>
      field?.toLowerCase().includes(needle),
    );
  });
}

function issueSortValue(issue: ErrorIssue, key: string): number | string {
  switch (key) {
    case "title":
      return issue.title;
    case "users":
      return issue.userCount;
    case "lastSeen":
      return issue.lastSeen ? Date.parse(issue.lastSeen) : 0;
    case "firstSeen":
      return issue.firstSeen ? Date.parse(issue.firstSeen) : 0;
    default:
      return issue.count;
  }
}

function sortIssues(issues: readonly ErrorIssue[], key: string, dir: "asc" | "desc"): ErrorIssue[] {
  const sign = dir === "asc" ? 1 : -1;
  return [...issues].sort((a, b) => {
    const x = issueSortValue(a, key);
    const y = issueSortValue(b, key);
    const order = typeof x === "string" || typeof y === "string" ? String(x).localeCompare(String(y)) : x - y;
    return sign * order || a.id.localeCompare(b.id);
  });
}

const GLITCHTIP_NOT_PER_SITE =
  "GlitchTip has no per-site split: its stored events have been pruned, so an issue cannot be traced to a site.";

export interface ErrorsViewProps {
  /** The site chosen in the topic list, or null for the overview. */
  site: string | null;
  onSite: (site: string) => void;
}

/**
 * The Errors topic: everything GlitchTip holds, split the way the board judges it. "Active" means
 * error or fatal and seen in the last 24 hours, which is what raises a Problem; the rest is a
 * backlog nobody has resolved, and it is shown as that rather than as an alarm.
 *
 * GlitchTip's stored events have been pruned, so an issue cannot be traced to a site and there is
 * no count of events per day. So the overview holds GlitchTip in full, and each site's own page is
 * PostHog's view of that site, as the panels there say.
 *
 * This stays mounted across the list, so a view or a search on the overview survives a visit to a site.
 */
export function ErrorsView({ site, onSite }: ErrorsViewProps): ReactElement {
  const now = useNow();
  const query = useErrorsDashboard();
  const { glitchtipUrl, posthogUrl } = useStatusHost();
  const [chosenView, setChosenView] = useState<IssueView | null>(null);
  const [search, setSearch] = useState("");
  const [sort, setSort] = useState<{ key: string; dir: "asc" | "desc" }>({ key: "count", dir: "desc" });

  const body = query.data;
  const sections = body?.sections ?? EMPTY_SECTIONS;
  const refreshing = body ? body.refreshing : query.isLoading;
  const glitchtipOn = body?.configured.glitchtip ?? true;
  const posthogOn = body?.configured.posthog ?? true;

  const issues = sections.issues.data;
  const summary = issues?.summary ?? null;
  // Open on what needs attention, until the operator picks a view for themselves.
  const view = chosenView ?? (summary && summary.active === 0 ? "backlog" : "active");

  const issueRows = useMemo(
    () => sortIssues(filterIssues(issues?.issues ?? [], view, search), sort.key, sort.dir),
    [issues, view, search, sort],
  );
  const topSites = useMemo(() => mostErrorSites(sections), [sections]);

  const columns: DataTableColumn<ErrorIssue>[] = [
    {
      key: "title",
      header: "Issue",
      sortable: true,
      width: "minmax(18rem, 1fr)",
      render: (issue) => (
        <span className="flex min-w-0 items-baseline gap-2">
          <StatusDot tone={levelTone(issue.level)} size={7} />
          <WrappedCell>{issue.title}</WrappedCell>
        </span>
      ),
    },
    { key: "level", header: "Level", render: (issue) => issue.level ?? "—" },
    { key: "count", header: "Events", sortable: true, render: (issue) => formatCount(issue.count) },
    { key: "users", header: "Users", sortable: true, render: (issue) => formatCount(issue.userCount) },
    { key: "lastSeen", header: "Last seen", sortable: true, render: (issue) => formatAge(issue.lastSeen, now) },
    { key: "firstSeen", header: "First seen", sortable: true, render: (issue) => formatAge(issue.firstSeen, now) },
    {
      key: "source",
      header: "Source",
      width: "12rem",
      render: (issue) => <WrappedCell>{issue.source ?? "—"}</WrappedCell>,
    },
    { key: "release", header: "Release", width: "7rem", render: (issue) => <WrappedCell>{issue.release ?? "—"}</WrappedCell> },
    { key: "shortId", header: "ID", render: (issue) => issue.shortId ?? "—" },
    {
      key: "open",
      header: "",
      width: "2.5rem",
      resizable: false,
      render: (issue) => {
        const href = issue.permalink ?? glitchtipUrl;
        return href ? <ExternalLink href={href} aria-label={`Open issue "${issue.title}" in GlitchTip`} /> : null;
      },
    },
  ];

  return (
    <div className="min-h-0 flex-1 overflow-y-auto">
      <div className="flex w-full flex-col gap-4 p-4">
        {query.isError && !body && (
          <p role="alert" className="m-0 font-mono text-xs text-apt-red">
            Could not load errors: {query.error.message}
          </p>
        )}

        {site !== null ? (
          <ErrorsSitePage
            key={site}
            site={site}
            sections={sections}
            posthogOn={posthogOn}
            refreshing={refreshing}
            posthogUrl={posthogUrl}
          />
        ) : (
          <>
            {summary && !summary.complete && (
              <p role="alert" className="m-0 font-mono text-xs text-apt-gold">
                GlitchTip&apos;s list could not be read to its end, so the counts below are short.
              </p>
            )}

            <StatCard
              title="Errors"
              className="min-w-0"
              icon={<Bug size={15} className={(summary?.active ?? 0) > 0 ? "text-apt-red" : "text-apt-text-muted"} />}
              link={glitchtipUrl ? { href: glitchtipUrl, label: "GlitchTip" } : undefined}
              statLayout="strip"
              stats={[
                { label: "Active", value: summary ? formatCount(summary.active) : "—", tone: (summary?.active ?? 0) > 0 ? "error" : "neutral" },
                { label: "Backlog", value: summary ? formatCount(summary.backlog) : "—" },
                { label: "Events", value: summary ? formatCount(summary.events) : "—" },
                { label: "Resolved", value: summary?.resolved === null || !summary ? "—" : formatCount(summary.resolved) },
              ]}
              footnote="Active: errors and fatals in the last 24 hours. Backlog: unresolved and gone quiet. Events: across unresolved issues."
            />

            <DashboardPanel
              title="New issues per day"
              source="GlitchTip"
              sourceHref={glitchtipUrl}
              section={sections.issues}
              configured={glitchtipOn}
              refreshing={refreshing}
              skeletonHeight={200}
              note="When each issue that is still unresolved first fired. Issues since resolved are not counted."
            >
              {(data) => (
                <TrendChart
                  ariaLabel="Unresolved GlitchTip issues by the day they first fired, last 30 days"
                  variant="bars"
                  labels={data.buckets}
                  series={[{ name: "New issues", color: ERROR_CHART_COLOR, values: data.summary.newPerDay }]}
                  height={200}
                  formatLabel={(label) => bucketLabel(label, "30d")}
                  formatDetail={(label) => bucketDetail(label, "30d")}
                />
              )}
            </DashboardPanel>

            <DashboardPanel
              title="Issues"
              source="GlitchTip"
              sourceHref={glitchtipUrl}
              section={sections.issues}
              configured={glitchtipOn}
              refreshing={refreshing}
              skeletonHeight={280}
              note={GLITCHTIP_NOT_PER_SITE}
            >
              {() => (
                <div className="flex flex-col gap-3">
                  <div className="flex flex-wrap items-center gap-2">
                    <ToggleGroup
                      aria-label="Which issues"
                      value={[view]}
                      onValueChange={(next: unknown[]) => {
                        const value = next[0] as IssueView | undefined;
                        if (value) setChosenView(value);
                      }}
                    >
                      {ISSUE_VIEWS.map(({ id, label }) => (
                        <ToggleGroupItem key={id} value={id}>
                          {label}
                        </ToggleGroupItem>
                      ))}
                    </ToggleGroup>
                    <Input
                      type="search"
                      aria-label="Search issues"
                      placeholder="Search issues"
                      value={search}
                      onChange={(event) => setSearch(event.target.value)}
                      className="w-full min-w-0 sm:w-64"
                    />
                  </div>
                  <div className="-mx-1">
                    <DataTable
                      ariaLabel="GlitchTip issues"
                      columns={columns}
                      rows={issueRows}
                      getRowId={(issue) => issue.id}
                      sort={sort}
                      onSortChange={setSort}
                      autoSizeColumns
                      emptyLabel={
                        search.trim() !== ""
                          ? "No issue matches that search."
                          : view === "active"
                            ? "✓ No errors in the last 24 hours."
                            : "Nothing here."
                      }
                    />
                  </div>
                </div>
              )}
            </DashboardPanel>

            <div className="grid grid-cols-1 items-start gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]">
              <DashboardPanel
                title="By type"
                source="GlitchTip"
                sourceHref={glitchtipUrl}
                section={sections.issues}
                configured={glitchtipOn}
                refreshing={refreshing}
              >
                {(data) => (
                  <BarList
                    ariaLabel="Unresolved issues by exception type, ranked by events"
                    items={data.summary.byType.map((type) => ({
                      name: type.name,
                      value: type.events,
                      detail: `${formatCount(type.events)} · ${formatCount(type.issues)} ${type.issues === 1 ? "issue" : "issues"}`,
                    }))}
                    color={ERROR_CHART_COLOR}
                    maxItems={Infinity}
                    emptyLabel="Nothing unresolved."
                  />
                )}
              </DashboardPanel>

              <DashboardPanel
                title="Most errors, last 30 days"
                source="PostHog"
                sourceHref={posthogUrl}
                section={sections.sites}
                configured={posthogOn}
                refreshing={refreshing}
                note={`Production only. The ${MOST_ERRORS_LIMIT} sites that reported the most errors to PostHog, not GlitchTip issues: GlitchTip no longer holds the event data to attribute an issue to a site. Open one for its page.`}
              >
                {() => (
                  <BarList
                    ariaLabel="Sites that reported the most errors, from PostHog"
                    items={topSites.map((row) => ({
                      name: row.host,
                      value: row.errors,
                      detail: `${formatCount(row.errors)} ${row.errors === 1 ? "error" : "errors"}`,
                    }))}
                    color={ERROR_CHART_COLOR}
                    maxItems={MOST_ERRORS_LIMIT}
                    onSelect={onSite}
                    emptyLabel="✓ No site reported an error in the last 30 days."
                  />
                )}
              </DashboardPanel>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
