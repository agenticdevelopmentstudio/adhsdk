import type {
  AnalyticsRange,
  AnalyticsSectionData,
  DashboardSections,
  DimensionRow,
  Marginal,
  PathRow,
  SiteHealthRow,
  TrafficSection,
  VercelProjectTraffic,
  VercelTrafficSection,
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

function addSeries(a: readonly number[], b: readonly number[]): number[] {
  return Array.from({ length: Math.max(a.length, b.length) }, (_, i) => (a[i] ?? 0) + (b[i] ?? 0));
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
    const seen = target.health;
    target.health = seen
      ? {
          host: seen.host,
          errors: seen.errors + site.errors,
          requests: seen.requests + site.requests,
          failures: seen.failures + site.failures,
          // Percentiles do not add. The worse of the two is the honest summary.
          p95Ms: seen.p95Ms === null || site.p95Ms === null ? (seen.p95Ms ?? site.p95Ms) : Math.max(seen.p95Ms, site.p95Ms),
        }
      : { ...site };
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

export interface SiteBreakdown extends BreakdownTotals {
  key: string;
}

function breakdownSize(row: BreakdownTotals): number {
  const sum = (list: Marginal[] | null): number => (list ?? []).reduce((total, m) => total + m.pageviews, 0);
  return Math.max(sum(row.posthog), sum(row.vercel));
}

/**
 * One topic per site, busiest first. The sites come from the rows themselves rather than from
 * the traffic table, so a site present only in this breakdown is still shown. A site with nothing
 * in the topic from either provider is left out.
 */
export function siteBreakdowns(
  topic: BreakdownTopic,
  dimensionRows: readonly DimensionRow[] | null,
  pathRows: readonly PathRow[] | null,
  projects: readonly VercelProjectTraffic[] | null,
): SiteBreakdown[] {
  const hosts = (topic === "pages" ? pathRows : dimensionRows) ?? [];
  const keys = new Set(hosts.map((row) => siteKey(row.host)));
  if (VERCEL_OF[topic]) for (const project of projects ?? []) keys.add(projectKey(project));
  return [...keys]
    .map((key) => ({ key, ...breakdownTotals(topic, dimensionRows, pathRows, projects, key) }))
    .filter((row) => (row.posthog?.length ?? 0) + (row.vercel?.length ?? 0) > 0)
    .sort((a, b) => breakdownSize(b) - breakdownSize(a) || a.key.localeCompare(b.key));
}

/**
 * Site names in list order: alphabetical, so a site stays where the reader last found it when
 * traffic moves. A stat topic's list and any row added to it both go through this.
 */
export function sortSiteNames(sites: readonly string[]): string[] {
  return [...sites].sort((a, b) => a.localeCompare(b));
}

/**
 * The sites a stat topic can show, alphabetically: the rows of its list. A site with nothing to show
 * in the topic is not offered, so Browsers lists only the sites PostHog has browsers for.
 */
export function topicSites(
  topic: "pageviews" | "sites" | "projects" | "vitals" | BreakdownTopic,
  sections: DashboardSections<AnalyticsSectionData>,
): string[] {
  if (topic === "sites") {
    return sortSiteNames(joinSites(sections.traffic.data, sections.vercel.data, sections.health.data).map((row) => row.key));
  }
  if (topic === "projects") {
    // The whole roster, traffic or not: a site with analytics off has to stay findable.
    return sortSiteNames([...new Set((sections.vercel.data?.roster ?? []).map(projectKey))]);
  }
  if (topic === "vitals") {
    return sortSiteNames([...new Set((sections.vitals.data ?? []).map((row) => siteKey(row.host)))]);
  }
  if (topic === "pageviews") {
    return sortSiteNames(
      joinSites(sections.traffic.data, sections.vercel.data, sections.health.data)
        .filter((row) => (row.posthog?.pageviews ?? 0) + (row.vercel?.pageviews ?? 0) > 0)
        .map((row) => row.key),
    );
  }
  return sortSiteNames(
    siteBreakdowns(
      topic,
      sections.dimensions.data?.rows ?? null,
      sections.paths.data,
      sections.vercel.data?.projects ?? null,
    ).map((row) => row.key),
  );
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
