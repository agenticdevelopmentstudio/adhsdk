import type {
  AnalyticsRange,
  AnalyticsSectionData,
  DashboardSection,
  DashboardSections,
  DimensionRow,
  Marginal,
  PathRow,
  SiteHealthRow,
  TrafficSection,
  VercelProjectTraffic,
  VercelTrafficSection,
  VitalsRow,
} from "../telemetry/dashboard-types";

// The Analytics topic's arithmetic, kept apart from its rendering. The backend answers per host
// and per project; picking a site, joining the two providers and summing a breakdown all happen
// here in the browser, so changing the selection never costs a provider query.

/** "www.x.com" and "x.com" are one site. PostHog reports the first, Vercel's domain the second. */
export function siteKey(host: string): string {
  return host.trim().toLowerCase().replace(/^www\./, "");
}

/** A Vercel project's site. A project with no production domain can only be named by itself. */
export function projectKey(project: { project: string; domain: string | null }): string {
  return project.domain ? siteKey(project.domain) : project.project;
}

export interface JoinedSite {
  key: string;
  /** Null where this provider has never seen the site, which is not the same as a zero. */
  posthog: { pageviews: number; sessions: number; series: number[] } | null;
  vercel: { project: string; pageviews: number; visitors: number; series: number[] } | null;
  health: SiteHealthRow | null;
}

export function addSeries(a: readonly number[], b: readonly number[]): number[] {
  return Array.from({ length: Math.max(a.length, b.length) }, (_, i) => (a[i] ?? 0) + (b[i] ?? 0));
}

/** A site's health across its hosts: counts add, but percentiles do not, so p95 is the worse one. */
export function mergeHealth(seen: SiteHealthRow | null, site: SiteHealthRow): SiteHealthRow {
  if (!seen) return { ...site };
  return {
    host: seen.host,
    errors: seen.errors + site.errors,
    requests: seen.requests + site.requests,
    failures: seen.failures + site.failures,
    p95Ms: seen.p95Ms === null || site.p95Ms === null ? (seen.p95Ms ?? site.p95Ms) : Math.max(seen.p95Ms, site.p95Ms),
  };
}

/**
 * One row per site across both providers. Their counts stay side by side and are never summed:
 * they measure different things, and a site reporting to both would count every visit twice.
 */
export function joinSites(
  traffic: TrafficSection | null,
  vercel: VercelTrafficSection | null,
  health: readonly SiteHealthRow[] | null,
): JoinedSite[] {
  const rows = new Map<string, JoinedSite>();
  const row = (key: string): JoinedSite => {
    let found = rows.get(key);
    if (!found) {
      found = { key, posthog: null, vercel: null, health: null };
      rows.set(key, found);
    }
    return found;
  };

  for (const site of traffic?.sites ?? []) {
    const target = row(siteKey(site.host));
    target.posthog = {
      pageviews: (target.posthog?.pageviews ?? 0) + site.pageviews,
      sessions: (target.posthog?.sessions ?? 0) + site.sessions,
      series: addSeries(target.posthog?.series ?? [], site.series),
    };
  }
  for (const project of vercel?.projects ?? []) {
    const target = row(projectKey(project));
    target.vercel = {
      project: project.project,
      pageviews: (target.vercel?.pageviews ?? 0) + project.pageviews,
      visitors: (target.vercel?.visitors ?? 0) + project.visitors,
      series: addSeries(target.vercel?.series ?? [], project.series),
    };
  }
  for (const site of health ?? []) {
    const key = siteKey(site.host);
    // Health alone does not put a site on a traffic table: it would add every API host.
    const target = rows.get(key);
    if (!target) continue;
    target.health = mergeHealth(target.health, site);
  }

  return [...rows.values()].sort(
    (a, b) =>
      Math.max(b.posthog?.pageviews ?? 0, b.vercel?.pageviews ?? 0) -
        Math.max(a.posthog?.pageviews ?? 0, a.vercel?.pageviews ?? 0) || a.key.localeCompare(b.key),
  );
}

export interface ChartSeries {
  labels: string[];
  posthog: (number | null)[] | null;
  vercel: (number | null)[] | null;
}

function onAxis(labels: readonly string[], buckets: readonly string[], values: readonly number[]): (number | null)[] {
  const at = new Map(buckets.map((bucket, i) => [bucket, values[i] ?? 0]));
  return labels.map((label) => at.get(label) ?? null);
}

/**
 * Pageviews over time from each provider, for everything or for one site. The two sections are
 * fetched separately, so around a day boundary their axes can differ by a bucket: they go onto
 * the union of the two, and a bucket one of them has not reached yet is a gap rather than a zero.
 */
export function pageviewSeries(
  traffic: TrafficSection | null,
  vercel: VercelTrafficSection | null,
  site: string | null,
): ChartSeries {
  const labels = [...new Set([...(traffic?.buckets ?? []), ...(vercel?.buckets ?? [])])].sort();
  const posthogValues =
    traffic && (site === null ? traffic.pageviews : sumMatching(traffic.sites, (s) => siteKey(s.host) === site));
  const vercelValues =
    vercel &&
    (site === null
      ? vercel.pageviews
      : sumMatching(vercel.projects, (p) => projectKey(p) === site));
  return {
    labels,
    posthog: traffic && posthogValues ? onAxis(labels, traffic.buckets, posthogValues) : null,
    vercel: vercel && vercelValues ? onAxis(labels, vercel.buckets, vercelValues) : null,
  };
}

/** The summed series of the matching rows; null when none match, so a site's absence shows. */
function sumMatching<T extends { series: number[] }>(rows: readonly T[], match: (row: T) => boolean): number[] | null {
  const matching = rows.filter(match);
  return matching.length === 0 ? null : matching.reduce<number[]>((sum, row) => addSeries(sum, row.series), []);
}

export type Dimension = "country" | "device" | "browser" | "referrer";

const REGIONS = new Intl.DisplayNames(["en"], { type: "region" });

/** Both providers report ISO country codes. Anything else is shown as it came. */
export function countryName(code: string): string {
  return /^[A-Z]{2}$/.test(code) ? (REGIONS.of(code) ?? code) : code;
}

/** One breakdown of the cross-tab: the backend sends the joint rows so any site can be picked. */
export function dimensionTotals(rows: readonly DimensionRow[], dimension: Dimension, site: string | null): Marginal[] {
  const totals = new Map<string, number>();
  for (const row of rows) {
    if (site !== null && siteKey(row.host) !== site) continue;
    const name =
      dimension === "referrer" && row.referrer === "$direct"
        ? "Direct"
        : dimension === "country"
          ? countryName(row.country)
          : row[dimension];
    totals.set(name, (totals.get(name) ?? 0) + row.pageviews);
  }
  return sortMarginals(totals);
}

export function pathTotals(rows: readonly PathRow[], site: string | null): Marginal[] {
  const totals = new Map<string, number>();
  for (const row of rows) {
    if (site !== null && siteKey(row.host) !== site) continue;
    // Across sites "/" is a different page on each, so the host has to stay in the name.
    const name = site === null ? `${siteKey(row.host)}${row.path}` : row.path;
    totals.set(name, (totals.get(name) ?? 0) + row.pageviews);
  }
  return sortMarginals(totals);
}

export type VercelBreakdown = "countries" | "referrers" | "paths" | "devices";

/** Vercel's values in the words PostHog's panels use, so the two read alike side by side. */
function vercelEntryName(breakdown: VercelBreakdown, name: string, siteLabel: string | null): string {
  switch (breakdown) {
    case "countries":
      return countryName(name);
    case "referrers":
      return name === "(none)" ? "Direct" : name;
    case "devices":
      return name.charAt(0).toUpperCase() + name.slice(1);
    case "paths":
      return siteLabel === null ? name : `${siteLabel}${name}`;
  }
}

export function vercelTotals(
  projects: readonly VercelProjectTraffic[],
  breakdown: VercelBreakdown,
  site: string | null,
): Marginal[] {
  const totals = new Map<string, number>();
  for (const project of projects) {
    const key = projectKey(project);
    if (site !== null && key !== site) continue;
    for (const entry of project[breakdown]) {
      const name = vercelEntryName(breakdown, entry.name, site === null ? key : null);
      totals.set(name, (totals.get(name) ?? 0) + entry.pageviews);
    }
  }
  return sortMarginals(totals);
}

export type BreakdownTopic = "pages" | "countries" | "referrers" | "devices" | "browsers";

const DIMENSION_OF: Record<Exclude<BreakdownTopic, "pages">, Dimension> = {
  countries: "country",
  referrers: "referrer",
  devices: "device",
  browsers: "browser",
};

// Vercel reports no browsers, so that topic has only PostHog's side.
const VERCEL_OF: Partial<Record<BreakdownTopic, VercelBreakdown>> = {
  pages: "paths",
  countries: "countries",
  referrers: "referrers",
  devices: "devices",
};

export interface BreakdownTotals {
  /** Null where the provider has no answer, which is not the same as an empty list. */
  posthog: Marginal[] | null;
  vercel: Marginal[] | null;
}

/** One topic's totals from each provider, for everything or for one site. */
export function breakdownTotals(
  topic: BreakdownTopic,
  dimensionRows: readonly DimensionRow[] | null,
  pathRows: readonly PathRow[] | null,
  projects: readonly VercelProjectTraffic[] | null,
  site: string | null,
): BreakdownTotals {
  const field = VERCEL_OF[topic];
  return {
    posthog:
      topic === "pages"
        ? pathRows && pathTotals(pathRows, site)
        : dimensionRows && dimensionTotals(dimensionRows, DIMENSION_OF[topic], site),
    vercel: field && projects ? vercelTotals(projects, field, site) : null,
  };
}

/**
 * Site names in list order: alphabetical, so a site stays where the reader last found it when
 * traffic moves. Analytics' list and any row added to it both go through this.
 */
export function sortSiteNames(sites: readonly string[]): string[] {
  return [...sites].sort((a, b) => a.localeCompare(b));
}

/**
 * Every site for Analytics' list, alphabetically: anything a provider reports traffic for, plus every
 * production project, so a site with analytics off stays findable. Health alone does not add one,
 * because that would add every API host.
 */
export function analyticsSites(sections: DashboardSections<AnalyticsSectionData>): string[] {
  const keys = new Set(joinSites(sections.traffic.data, sections.vercel.data, null).map((row) => row.key));
  for (const row of sections.vercel.data?.roster ?? []) keys.add(projectKey(row));
  for (const row of sections.vitals.data ?? []) keys.add(siteKey(row.host));
  for (const row of sections.dimensions.data?.rows ?? []) keys.add(siteKey(row.host));
  for (const row of sections.paths.data ?? []) keys.add(siteKey(row.host));
  return sortSiteNames([...keys]);
}

export interface SiteBreakdown {
  topic: BreakdownTopic;
  /** Null where this provider has nothing for the site: its list is left off the card. */
  posthog: Marginal[] | null;
  vercel: Marginal[] | null;
}

/**
 * What one site has, and only that. Everything absent is null or empty here, so the page draws what
 * this returns and has no "nothing for this site" states of its own. A figure of zero counts as
 * absent, except errors on a site that served requests, where zero is the finding.
 */
export interface SiteReport {
  posthog: { pageviews: number; sessions: number } | null;
  vercel: { pageviews: number; visitors: number } | null;
  health: SiteHealthRow | null;
  breakdowns: SiteBreakdown[];
  projects: VercelTrafficSection["roster"];
  /** One of this site's Vercel breakdowns failed: its pageviews are whole, its chart and lists short. */
  vercelIncomplete: boolean;
  vitals: VitalsRow[];
}

const BREAKDOWN_ORDER: readonly BreakdownTopic[] = ["pages", "countries", "referrers", "devices", "browsers"];

const nonEmpty = (list: Marginal[] | null): Marginal[] | null => (list && list.length > 0 ? list : null);

export function siteReport(sections: DashboardSections<AnalyticsSectionData>, site: string): SiteReport {
  const joined = joinSites(sections.traffic.data, sections.vercel.data, null).find((row) => row.key === site);
  const posthog = joined?.posthog;
  const vercel = joined?.vercel;
  const health = (sections.health.data ?? [])
    .filter((row) => siteKey(row.host) === site)
    .reduce<SiteHealthRow | null>(mergeHealth, null);
  return {
    posthog: posthog && (posthog.pageviews > 0 || posthog.sessions > 0) ? posthog : null,
    vercel: vercel && (vercel.pageviews > 0 || vercel.visitors > 0) ? vercel : null,
    health: health && (health.requests > 0 || health.errors > 0 || health.p95Ms !== null) ? health : null,
    breakdowns: BREAKDOWN_ORDER.flatMap((topic) => {
      const totals = breakdownTotals(
        topic,
        sections.dimensions.data?.rows ?? null,
        sections.paths.data,
        sections.vercel.data?.projects ?? null,
        site,
      );
      const lists = { posthog: nonEmpty(totals.posthog), vercel: nonEmpty(totals.vercel) };
      return lists.posthog || lists.vercel ? [{ topic, ...lists }] : [];
    }),
    projects: (sections.vercel.data?.roster ?? []).filter((row) => projectKey(row) === site),
    vercelIncomplete: (sections.vercel.data?.projects ?? []).some((p) => p.incomplete && projectKey(p) === site),
    vitals: (sections.vitals.data ?? []).filter((row) => siteKey(row.host) === site),
  };
}

/** Whether a site's report has anything to draw. */
export function siteReportIsEmpty(report: SiteReport): boolean {
  return (
    !report.posthog &&
    !report.vercel &&
    !report.health &&
    report.breakdowns.length === 0 &&
    report.projects.length === 0 &&
    report.vitals.length === 0
  );
}

const SECTION_NAMES: { key: keyof DashboardSections<AnalyticsSectionData>; what: string; source: "PostHog" | "Vercel" }[] = [
  { key: "traffic", what: "traffic", source: "PostHog" },
  { key: "paths", what: "pages", source: "PostHog" },
  { key: "dimensions", what: "breakdowns", source: "PostHog" },
  { key: "health", what: "health", source: "PostHog" },
  { key: "vitals", what: "web vitals", source: "PostHog" },
  { key: "vercel", what: "traffic", source: "Vercel" },
];

export interface SectionFailure {
  source: "PostHog" | "Vercel";
  what: string[];
  error: string;
}

/**
 * What could not be read at all, one entry per source and error. Leaving out what a site does not
 * have must not also leave out what we failed to ask about: a failed provider has to stay visible
 * on a page that hides absences. A section with last-good data is not here, because its card shows.
 */
export function sectionFailures(
  sections: DashboardSections<AnalyticsSectionData>,
  configured: { posthog: boolean; vercel: boolean },
): SectionFailure[] {
  return collectFailures(
    SECTION_NAMES.filter(({ source }) => (source === "PostHog" ? configured.posthog : configured.vercel)).map(
      ({ key, what, source }) => ({ section: sections[key], what, source }),
    ),
  );
}

/** The sections among these that could not be read at all, grouped by source and error. */
export function collectFailures(
  named: readonly { section: DashboardSection<unknown>; what: string; source: SectionFailure["source"] }[],
): SectionFailure[] {
  const failures: SectionFailure[] = [];
  for (const { section, what, source } of named) {
    if (section.data !== null || section.error === null) continue;
    const same = failures.find((f) => f.source === source && f.error === section.error);
    if (same) same.what.push(what);
    else failures.push({ source, what: [what], error: section.error });
  }
  return failures;
}

function sortMarginals(totals: ReadonlyMap<string, number>): Marginal[] {
  return [...totals]
    .map(([name, pageviews]) => ({ name, pageviews }))
    .sort((a, b) => b.pageviews - a.pageviews || a.name.localeCompare(b.name));
}

// Buckets are UTC, so they are labelled in UTC: a local "Nov 3" over a UTC-day bucket would be a
// different day's traffic for anyone west of Greenwich.
const HOUR = new Intl.DateTimeFormat("en", { hour: "2-digit", minute: "2-digit", hourCycle: "h23", timeZone: "UTC" });
const DAY = new Intl.DateTimeFormat("en", { month: "short", day: "numeric", timeZone: "UTC" });

/** A bucket's label on the axis. */
export function bucketLabel(iso: string, range: AnalyticsRange): string {
  return (range === "24h" ? HOUR : DAY).format(new Date(iso));
}

/** A bucket's label in a tooltip or table, where the time zone can be said. */
export function bucketDetail(iso: string, range: AnalyticsRange): string {
  const at = new Date(iso);
  return range === "24h" ? `${DAY.format(at)}, ${HOUR.format(at)} UTC` : `${DAY.format(at)} (UTC)`;
}

export type VitalRating = "good" | "fair" | "poor";
export type Vital = "lcp" | "inp" | "cls" | "fcp";

/** Google's published Core Web Vitals boundaries: [good up to, fair up to]. */
const VITAL_LIMITS: Record<Vital, [number, number]> = {
  lcp: [2500, 4000],
  inp: [200, 500],
  cls: [0.1, 0.25],
  fcp: [1800, 3000],
};

export function vitalRating(vital: Vital, value: number): VitalRating {
  const [good, fair] = VITAL_LIMITS[vital];
  return value <= good ? "good" : value <= fair ? "fair" : "poor";
}

export function formatVital(vital: Vital, value: number): string {
  if (vital === "cls") return value.toFixed(2);
  return value >= 1000 ? `${(value / 1000).toFixed(1)}s` : `${Math.round(value)}ms`;
}
