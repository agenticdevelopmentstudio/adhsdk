import type {
  DashboardSections,
  ErrorsSectionData,
  SiteErrorRow,
  SiteFailedRequestRow,
  SiteHealthRow,
} from "../telemetry/dashboard-types";
import { addSeries, collectFailures, mergeHealth, siteKey, sortSiteNames, type SectionFailure } from "./analytics-model";

// The Errors topic's per-site arithmetic, kept apart from its rendering. The backend answers per
// host; picking a site and joining `www.x.com` to `x.com` happen here, so opening a site costs no
// provider query.

type Sections = DashboardSections<ErrorsSectionData>;

/** One row per site, named by its key so a row can open that site. Busiest first. */
export function errorsSiteRows(sections: Sections): SiteHealthRow[] {
  const bySite = new Map<string, SiteHealthRow>();
  for (const row of sections.sites.data ?? []) {
    const key = siteKey(row.host);
    bySite.set(key, mergeHealth(bySite.get(key) ?? null, { ...row, host: key }));
  }
  return [...bySite.values()].sort((a, b) => b.requests - a.requests || a.host.localeCompare(b.host));
}

/** Every site for Errors' list, alphabetically. */
export function errorsSites(sections: Sections): string[] {
  const keys = new Set<string>();
  for (const row of sections.sites.data ?? []) keys.add(siteKey(row.host));
  for (const row of sections.detail.data?.days ?? []) keys.add(siteKey(row.host));
  for (const row of sections.detail.data?.errors ?? []) keys.add(siteKey(row.host));
  for (const row of sections.detail.data?.requests ?? []) keys.add(siteKey(row.host));
  return sortSiteNames([...keys]);
}

export interface ErrorsSiteChart {
  buckets: string[];
  errors: number[];
  failures: number[];
}

/**
 * One site's page, with everything it does not have left null or empty so the page need not draw it.
 * A site that served requests and reported no errors keeps its health: that zero is the finding.
 */
export interface ErrorsSiteReport {
  health: SiteHealthRow | null;
  chart: ErrorsSiteChart | null;
  errors: SiteErrorRow[];
  requests: SiteFailedRequestRow[];
}

export function errorRowId(row: SiteErrorRow): string {
  return JSON.stringify([row.name, row.feature, row.step, row.boundary, row.page]);
}

export function failedRequestRowId(row: SiteFailedRequestRow): string {
  return JSON.stringify([row.status, row.method, row.path]);
}

function laterOf(a: string | null, b: string | null): string | null {
  if (a === null || b === null) return a ?? b;
  return Date.parse(b) > Date.parse(a) ? b : a;
}

/** The same row from `www.x.com` and `x.com` is one row of one site. Commonest first. */
function mergeRows<T extends { host: string; count: number; lastSeen: string | null }>(
  rows: readonly T[],
  site: string,
  id: (row: T) => string,
): T[] {
  const merged = new Map<string, T>();
  for (const row of rows) {
    if (siteKey(row.host) !== site) continue;
    const key = id(row);
    const seen = merged.get(key);
    merged.set(
      key,
      seen
        ? { ...seen, count: seen.count + row.count, lastSeen: laterOf(seen.lastSeen, row.lastSeen) }
        : { ...row, host: site },
    );
  }
  return [...merged.values()].sort((a, b) => b.count - a.count || id(a).localeCompare(id(b)));
}

function siteChart(sections: Sections, site: string): ErrorsSiteChart | null {
  const detail = sections.detail.data;
  if (!detail) return null;
  let errors: number[] = [];
  let failures: number[] = [];
  for (const row of detail.days) {
    if (siteKey(row.host) !== site) continue;
    errors = addSeries(errors, row.errors);
    failures = addSeries(failures, row.failures);
  }
  const anything = [...errors, ...failures].some((value) => value > 0);
  return anything ? { buckets: detail.buckets, errors, failures } : null;
}

export function errorsSiteReport(sections: Sections, site: string): ErrorsSiteReport {
  const health = errorsSiteRows(sections).find((row) => row.host === site) ?? null;
  return {
    health: health && (health.requests > 0 || health.errors > 0) ? health : null,
    chart: siteChart(sections, site),
    errors: mergeRows(sections.detail.data?.errors ?? [], site, errorRowId),
    requests: mergeRows(sections.detail.data?.requests ?? [], site, failedRequestRowId),
  };
}

export function errorsSiteReportIsEmpty(report: ErrorsSiteReport): boolean {
  return report.health === null && report.chart === null && report.errors.length === 0 && report.requests.length === 0;
}

/** What a site page could not read at all, which must stay visible on a page that hides absences. */
export function errorsSiteFailures(sections: Sections): SectionFailure[] {
  return collectFailures([
    { section: sections.sites, what: "site totals", source: "PostHog" },
    { section: sections.detail, what: "errors and failed requests", source: "PostHog" },
  ]);
}
