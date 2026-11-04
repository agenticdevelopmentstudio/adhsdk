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
import { bucketDetail, bucketLabel, siteKey } from "../lib/analytics-model";
import { ERROR_CHART_COLOR } from "../lib/colors";
import { timeAgo } from "../lib/time-ago";
import type {
  DashboardSections,
  ErrorIssue,
  ErrorsSectionData,
  SiteHealthRow,
} from "../telemetry/dashboard-types";
import type { ErrorsTopic } from "./board-views";
import { DashboardPanel, formatRate, SeeAll, SiteFailureRate, WrappedCell } from "./DashboardParts";
import { useStatusHost } from "./StatusHost";

const EMPTY_SECTIONS: DashboardSections<ErrorsSectionData> = {
  issues: { data: null, error: null, updatedAt: null },
  sites: { data: null, error: null, updatedAt: null },
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

function age(iso: string | null, now: number): string {
  if (!iso) return "—";
  const text = timeAgo(iso, now);
  return text === "just now" ? text : `${text} ago`;
}

const SITE_COLUMNS: DataTableColumn<SiteHealthRow>[] = [
  { key: "host", header: "Site", width: "minmax(16rem, 1fr)", render: (row) => <WrappedCell>{siteKey(row.host)}</WrappedCell> },
  { key: "errors", header: "Errors reported", render: (row) => formatCount(row.errors) },
  { key: "requests", header: "Requests", render: (row) => formatCount(row.requests) },
  {
    key: "failures",
    header: "Failed",
    render: (row) => <SiteFailureRate failures={row.failures} requests={row.requests} />,
  },
  { key: "p95", header: "p95", render: (row) => (row.p95Ms === null ? "—" : `${Math.round(row.p95Ms)}ms`) },
];

const DAY_COLUMNS: DataTableColumn<{ day: string; count: number }>[] = [
  { key: "day", header: "Day", width: "minmax(10rem, 1fr)", render: (row) => bucketDetail(row.day, "30d") },
  { key: "count", header: "New issues", render: (row) => formatCount(row.count) },
];

const GLITCHTIP_NOT_PER_SITE =
  "GlitchTip has no per-site split: its stored events have been pruned, so an issue cannot be traced to a site.";

/**
 * The Errors topic: everything GlitchTip holds, split the way the board judges it. "Active" means
 * error or fatal and seen in the last 24 hours, which is what raises a Problem; the rest is a
 * backlog nobody has resolved, and it is shown as that rather than as an alarm.
 *
 * GlitchTip's stored events have been pruned, so an issue cannot be traced to a site and there is
 * no count of events per day. The per-site panel is PostHog's view of the same fleet and says so.
 *
 * Overview holds every panel, each with a way to its own sub-topic, where nothing is held back.
 * This stays mounted across sub-topics, so a view or a search carries from one to the next.
 */
export function ErrorsView({ topic }: { topic: ErrorsTopic }): ReactElement {
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
    { key: "lastSeen", header: "Last seen", sortable: true, render: (issue) => age(issue.lastSeen, now) },
    { key: "firstSeen", header: "First seen", sortable: true, render: (issue) => age(issue.firstSeen, now) },
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

  const newIssuesPanel = (seeAll: boolean): ReactElement => (
    <DashboardPanel
      title="New issues per day"
      source="GlitchTip"
      sourceHref={glitchtipUrl}
      section={sections.issues}
      configured={glitchtipOn}
      refreshing={refreshing}
      skeletonHeight={200}
      actions={seeAll ? <SeeAll href="/errors/new-issues" what="new issues per day" /> : undefined}
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
  );

  const issuesPanel = (capped: boolean): ReactElement => (
    <DashboardPanel
      title="Issues"
      source="GlitchTip"
      sourceHref={glitchtipUrl}
      section={sections.issues}
      configured={glitchtipOn}
      refreshing={refreshing}
      skeletonHeight={280}
      actions={capped ? <SeeAll href="/errors/issues" what="issues" /> : undefined}
      note={capped ? undefined : GLITCHTIP_NOT_PER_SITE}
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
          <div className={capped ? "-mx-1 max-h-[520px] overflow-auto" : "-mx-1"}>
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
  );

  const byTypePanel = (capped: boolean): ReactElement => (
    <DashboardPanel
      title="By type"
      source="GlitchTip"
      sourceHref={glitchtipUrl}
      section={sections.issues}
      configured={glitchtipOn}
      refreshing={refreshing}
      actions={capped ? <SeeAll href="/errors/by-type" what="issue types" /> : undefined}
      note={capped ? undefined : GLITCHTIP_NOT_PER_SITE}
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
          maxItems={capped ? undefined : Infinity}
          emptyLabel="Nothing unresolved."
        />
      )}
    </DashboardPanel>
  );

  const perSitePanel = (capped: boolean): ReactElement => (
    <DashboardPanel
      title="Per site, last 30 days"
      source="PostHog"
      sourceHref={posthogUrl}
      section={sections.sites}
      configured={posthogOn}
      refreshing={refreshing}
      actions={capped ? <SeeAll href="/errors/per-site" what="sites" /> : undefined}
      note={`Production only. These are PostHog's own error and request events, not GlitchTip issues: GlitchTip no longer holds the event data to attribute an issue to a site. Failure rates are failed requests over all requests${
        sections.sites.data ? `, ${formatRate(
          sections.sites.data.reduce((sum, row) => sum + row.failures, 0),
          sections.sites.data.reduce((sum, row) => sum + row.requests, 0),
        )} across the fleet` : ""
      }.`}
    >
      {(rows) => (
        <div className={capped ? "-mx-1 max-h-[360px] overflow-auto" : "-mx-1"}>
          <DataTable
            ariaLabel="Errors and failed requests per site, from PostHog"
            columns={SITE_COLUMNS}
            rows={rows}
            getRowId={(row) => row.host}
            autoSizeColumns
            emptyLabel="No site reported requests in this range."
          />
        </div>
      )}
    </DashboardPanel>
  );

  return (
    <div className="min-h-0 flex-1 overflow-y-auto">
      <div className="flex w-full flex-col gap-4 p-4">
        {query.isError && !body && (
          <p role="alert" className="m-0 font-mono text-xs text-apt-red">
            Could not load errors: {query.error.message}
          </p>
        )}

        {summary && !summary.complete && (
          <p role="alert" className="m-0 font-mono text-xs text-apt-gold">
            GlitchTip&apos;s list could not be read to its end, so the counts below are short.
          </p>
        )}

        {topic === "overview" && (
          <>
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
            {newIssuesPanel(true)}
            {issuesPanel(true)}
            <div className="grid grid-cols-1 gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]">
              {byTypePanel(true)}
              {perSitePanel(true)}
            </div>
          </>
        )}

        {topic === "new-issues" && (
          <>
            {newIssuesPanel(false)}
            <DashboardPanel
              title="Day by day"
              source="GlitchTip"
              sourceHref={glitchtipUrl}
              section={sections.issues}
              configured={glitchtipOn}
              refreshing={refreshing}
            >
              {(data) => (
                <div className="-mx-1">
                  <DataTable
                    ariaLabel="New issues per day, newest first"
                    columns={DAY_COLUMNS}
                    rows={data.buckets
                      .map((day, i) => ({ day, count: data.summary.newPerDay[i] ?? 0 }))
                      .reverse()}
                    getRowId={(row) => row.day}
                    autoSizeColumns
                    emptyLabel="No days to show."
                  />
                </div>
              )}
            </DashboardPanel>
          </>
        )}

        {topic === "issues" && issuesPanel(false)}
        {topic === "by-type" && byTypePanel(false)}
        {topic === "per-site" && perSitePanel(false)}
      </div>
    </div>
  );
}
