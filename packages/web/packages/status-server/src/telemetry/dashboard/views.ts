import type {
  AnalyticsSectionData,
  DimensionRow,
  ErrorsSectionData,
  Marginal,
  PathRow,
  SiteErrorRow,
  SiteFailedRequestRow,
  SiteHealthRow,
  TrafficSection,
  VercelProjectTraffic,
  VercelRosterEntry,
  VercelTrafficSection,
  VitalsRow,
} from './types';
import type { DashboardSection, DashboardSections } from './sectioned-dashboard';

// ---------------------------------------------------------------------------
// The Analytics and Errors dashboards' VIEWS: every join, sort, threshold and per-site cut the
// pages draw, computed here from the sections so the website only renders fields.
//
// The providers answer per host (PostHog) and per project (Vercel). Joining `www.x.com` to `x.com`,
// joining a project to its site, ranking, rating a web vital and calling a failure rate high all
// happen once, here, and ride the dashboard response as `views`. Each site's page is in
// `siteReports`, so opening a site still costs no provider query and no second request.
// ---------------------------------------------------------------------------

/** "www.x.com" and "x.com" are one site. PostHog reports the first, Vercel's domain the second. */
export function siteKey(host: string): string {
  return host.trim().toLowerCase().replace(/^www\./, '');
}

/** A Vercel project's site. A project with no production domain can only be named by itself. */
export function projectKey(project: { project: string; domain: string | null }): string {
  return project.domain ? siteKey(project.domain) : project.project;
}

/** At or above this share of failed requests, a site's failure rate is called out. */
export const FAILURE_RATE_HIGH = 0.05;

export function isFailureRateHigh(failures: number, requests: number): boolean {
  return requests > 0 && failures / requests >= FAILURE_RATE_HIGH;
}

/** A site's health with the server's verdict on its failure rate. */
export interface RatedHealth extends SiteHealthRow {
  /** `failures / requests` is at or above `FAILURE_RATE_HIGH`. */
  failureRateHigh: boolean;
}

function rated(row: SiteHealthRow): RatedHealth {
  return { ...row, failureRateHigh: isFailureRateHigh(row.failures, row.requests) };
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

/** Site names in list order: alphabetical, so a site stays where the reader last found it. */
export function sortSiteNames(sites: readonly string[]): string[] {
  return [...sites].sort((a, b) => a.localeCompare(b));
}

// ── Analytics ───────────────────────────────────────────────────────────────

export interface JoinedSite {
  key: string;
  /** Null where this provider has never seen the site, which is not the same as a zero. */
  posthog: { pageviews: number; sessions: number; series: number[] } | null;
  vercel: { project: string; pageviews: number; visitors: number; series: number[] } | null;
  health: RatedHealth | null;
}

/**
 * One row per site across both providers. Their counts stay side by side and are never summed:
 * they measure different things, and a site reporting to both would count every visit twice.
 * Busiest first (by the larger of the two counts).
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
    // Health alone does not put a site on a traffic table: it would add every API host.
    const target = rows.get(siteKey(site.host));
    if (!target) continue;
    target.health = rated(mergeHealth(target.health, site));
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

/** The summed series of the matching rows; null when none match, so a site's absence shows. */
function sumMatching<T extends { series: number[] }>(rows: readonly T[], match: (row: T) => boolean): number[] | null {
  const matching = rows.filter(match);
  return matching.length === 0 ? null : matching.reduce<number[]>((sum, row) => addSeries(sum, row.series), []);
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
    vercel && (site === null ? vercel.pageviews : sumMatching(vercel.projects, (p) => projectKey(p) === site));
  return {
    labels,
    posthog: traffic && posthogValues ? onAxis(labels, traffic.buckets, posthogValues) : null,
    vercel: vercel && vercelValues ? onAxis(labels, vercel.buckets, vercelValues) : null,
  };
}

export const DIMENSIONS = ['country', 'device', 'browser', 'referrer'] as const;
export type Dimension = (typeof DIMENSIONS)[number];

const REGIONS = new Intl.DisplayNames(['en'], { type: 'region' });

/** Both providers report ISO country codes. Anything else is shown as it came. */
export function countryName(code: string): string {
  return /^[A-Z]{2}$/.test(code) ? (REGIONS.of(code) ?? code) : code;
}

function sortMarginals(totals: ReadonlyMap<string, number>): Marginal[] {
  return [...totals]
    .map(([name, pageviews]) => ({ name, pageviews }))
    .sort((a, b) => b.pageviews - a.pageviews || a.name.localeCompare(b.name));
}

/** One breakdown of the cross-tab, for everything or one site. Largest first. */
export function dimensionTotals(rows: readonly DimensionRow[], dimension: Dimension, site: string | null): Marginal[] {
  const totals = new Map<string, number>();
  for (const row of rows) {
    if (site !== null && siteKey(row.host) !== site) continue;
    const name =
      dimension === 'referrer' && row.referrer === '$direct'
        ? 'Direct'
        : dimension === 'country'
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

export const VERCEL_BREAKDOWNS = ['countries', 'referrers', 'paths', 'devices'] as const;
export type VercelBreakdown = (typeof VERCEL_BREAKDOWNS)[number];

/** Vercel's values in the words PostHog's panels use, so the two read alike side by side. */
function vercelEntryName(breakdown: VercelBreakdown, name: string, siteLabel: string | null): string {
  switch (breakdown) {
    case 'countries':
      return countryName(name);
    case 'referrers':
      return name === '(none)' ? 'Direct' : name;
    case 'devices':
      return name.charAt(0).toUpperCase() + name.slice(1);
    case 'paths':
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

export type BreakdownTopic = 'pages' | 'countries' | 'referrers' | 'devices' | 'browsers';

const DIMENSION_OF: Record<Exclude<BreakdownTopic, 'pages'>, Dimension> = {
  countries: 'country',
  referrers: 'referrer',
  devices: 'device',
  browsers: 'browser',
};

// Vercel reports no browsers, so that topic has only PostHog's side.
const VERCEL_OF: Partial<Record<BreakdownTopic, VercelBreakdown>> = {
  pages: 'paths',
  countries: 'countries',
  referrers: 'referrers',
  devices: 'devices',
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
      topic === 'pages'
        ? pathRows && pathTotals(pathRows, site)
        : dimensionRows && dimensionTotals(dimensionRows, DIMENSION_OF[topic], site),
    vercel: field && projects ? vercelTotals(projects, field, site) : null,
  };
}

export type VitalRating = 'good' | 'fair' | 'poor';
export const VITALS = ['lcp', 'inp', 'cls', 'fcp'] as const;
export type Vital = (typeof VITALS)[number];

/** Google's published Core Web Vitals boundaries: [good up to, fair up to]. */
const VITAL_LIMITS: Record<Vital, [number, number]> = {
  lcp: [2500, 4000],
  inp: [200, 500],
  cls: [0.1, 0.25],
  fcp: [1800, 3000],
};

export function vitalRating(vital: Vital, value: number): VitalRating {
  const [good, fair] = VITAL_LIMITS[vital];
  return value <= good ? 'good' : value <= fair ? 'fair' : 'poor';
}

/** One host's web vitals with the site it belongs to and a rating per vital (null: not measured). */
export interface RatedVitalsRow extends VitalsRow {
  site: string;
  ratings: Record<Vital, VitalRating | null>;
}

export function rateVitals(row: VitalsRow): RatedVitalsRow {
  const ratings = {} as Record<Vital, VitalRating | null>;
  for (const vital of VITALS) {
    const value = row[vital];
    ratings[vital] = value === null ? null : vitalRating(vital, value);
  }
  return { ...row, site: siteKey(row.host), ratings };
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
  health: RatedHealth | null;
  /** The site's pageviews over time from each provider that counted any; null when none did. */
  pageviews: ChartSeries | null;
  breakdowns: SiteBreakdown[];
  projects: VercelRosterEntry[];
  /** One of this site's Vercel breakdowns failed: its pageviews are whole, its chart and lists short. */
  vercelIncomplete: boolean;
  vitals: RatedVitalsRow[];
  /** Nothing above has anything to draw. */
  empty: boolean;
}

const BREAKDOWN_ORDER: readonly BreakdownTopic[] = ['pages', 'countries', 'referrers', 'devices', 'browsers'];

const nonEmpty = (list: Marginal[] | null): Marginal[] | null => (list && list.length > 0 ? list : null);

export function siteReport(sections: DashboardSections<AnalyticsSectionData>, site: string): SiteReport {
  const joined = joinSites(sections.traffic.data, sections.vercel.data, null).find((row) => row.key === site);
  const posthog = joined?.posthog;
  const vercel = joined?.vercel;
  const health = (sections.health.data ?? [])
    .filter((row) => siteKey(row.host) === site)
    .reduce<SiteHealthRow | null>(mergeHealth, null);
  const posthogCharted = (posthog?.pageviews ?? 0) > 0;
  const vercelCharted = (vercel?.pageviews ?? 0) > 0;
  const report: Omit<SiteReport, 'empty'> = {
    posthog: posthog && (posthog.pageviews > 0 || posthog.sessions > 0) ? { pageviews: posthog.pageviews, sessions: posthog.sessions } : null,
    vercel: vercel && (vercel.pageviews > 0 || vercel.visitors > 0) ? { pageviews: vercel.pageviews, visitors: vercel.visitors } : null,
    health: health && (health.requests > 0 || health.errors > 0 || health.p95Ms !== null) ? rated(health) : null,
    pageviews:
      posthogCharted || vercelCharted
        ? pageviewSeries(posthogCharted ? sections.traffic.data : null, vercelCharted ? sections.vercel.data : null, site)
        : null,
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
    vitals: (sections.vitals.data ?? []).filter((row) => siteKey(row.host) === site).map(rateVitals),
  };
  return {
    ...report,
    empty:
      !report.posthog &&
      !report.vercel &&
      !report.health &&
      report.breakdowns.length === 0 &&
      report.projects.length === 0 &&
      report.vitals.length === 0,
  };
}

export interface SectionFailure {
  source: 'PostHog' | 'Vercel';
  what: string[];
  error: string;
}

/** The sections among these that could not be read at all, grouped by source and error. */
export function collectFailures(
  named: readonly { section: DashboardSection<unknown>; what: string; source: SectionFailure['source'] }[],
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

const SECTION_NAMES: { key: keyof AnalyticsSectionData; what: string; source: SectionFailure['source'] }[] = [
  { key: 'traffic', what: 'traffic', source: 'PostHog' },
  { key: 'paths', what: 'pages', source: 'PostHog' },
  { key: 'dimensions', what: 'breakdowns', source: 'PostHog' },
  { key: 'health', what: 'health', source: 'PostHog' },
  { key: 'vitals', what: 'web vitals', source: 'PostHog' },
  { key: 'vercel', what: 'traffic', source: 'Vercel' },
];

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
    SECTION_NAMES.filter(({ source }) => (source === 'PostHog' ? configured.posthog : configured.vercel)).map(
      ({ key, what, source }) => ({ section: sections[key], what, source }),
    ),
  );
}

/** A Vercel project on the overview's Projects list: one that counted any pageviews. */
export interface VercelProjectBar {
  /** The site the project serves, which is what opening its row opens. */
  site: string;
  project: string;
  pageviews: number;
  visitors: number;
}

/** Everything the Analytics pages draw, derived from the sections. */
export interface AnalyticsViews {
  /** Analytics' site list, alphabetically. */
  sites: string[];
  /** The Sites table: one row per site across both providers, busiest first. */
  joined: JoinedSite[];
  /** Pageviews across all sites, per provider. */
  pageviews: ChartSeries;
  /** Top pages across all sites (host kept in the name); null until PostHog's paths answer. */
  pages: Marginal[] | null;
  /** PostHog's breakdowns across all sites; null until its dimensions answer. */
  dimensions: Record<Dimension, Marginal[]> | null;
  /** Vercel projects that counted pageviews, in the order Vercel's section lists them. */
  vercelProjects: VercelProjectBar[] | null;
  /** Vercel's breakdowns across all sites, worded as PostHog's are; null until Vercel answers. */
  vercelBreakdowns: Record<VercelBreakdown, Marginal[]> | null;
  /** Web vitals per host, rated; null until PostHog's vitals answer. */
  vitals: RatedVitalsRow[] | null;
  /** Each site's own page, keyed by site: every listed site and every host with health. */
  siteReports: Record<string, SiteReport>;
  /** Sections of a configured provider that could not be read at all. */
  failures: SectionFailure[];
}

function record<K extends string, V>(keys: readonly K[], value: (key: K) => V): Record<K, V> {
  const out = {} as Record<K, V>;
  for (const key of keys) out[key] = value(key);
  return out;
}

export function analyticsViews(
  sections: DashboardSections<AnalyticsSectionData>,
  configured: { posthog: boolean; vercel: boolean },
): AnalyticsViews {
  const traffic = sections.traffic.data;
  const vercel = sections.vercel.data;
  const dimensions = sections.dimensions.data;
  const sites = analyticsSites(sections);
  // A host with only health is not listed (it would add every API host), but a deep link to it
  // still has a page to show, so it gets a report too.
  const reportKeys = new Set(sites);
  for (const row of sections.health.data ?? []) reportKeys.add(siteKey(row.host));
  return {
    sites,
    joined: joinSites(traffic, vercel, sections.health.data),
    pageviews: pageviewSeries(traffic, vercel, null),
    pages: sections.paths.data && pathTotals(sections.paths.data, null),
    dimensions: dimensions && record(DIMENSIONS, (d) => dimensionTotals(dimensions.rows, d, null)),
    vercelProjects:
      vercel &&
      vercel.projects
        .filter((p) => p.pageviews > 0)
        .map((p) => ({ site: projectKey(p), project: p.project, pageviews: p.pageviews, visitors: p.visitors })),
    vercelBreakdowns: vercel && record(VERCEL_BREAKDOWNS, (b) => vercelTotals(vercel.projects, b, null)),
    vitals: sections.vitals.data && sections.vitals.data.map(rateVitals),
    siteReports: Object.fromEntries([...reportKeys].map((site) => [site, siteReport(sections, site)])),
    failures: sectionFailures(sections, configured),
  };
}

// ── Errors ──────────────────────────────────────────────────────────────────

type ErrorsSections = DashboardSections<ErrorsSectionData>;

/** One row per site, named by its key so a row can open that site. Busiest first. */
export function errorsSiteRows(sections: ErrorsSections): RatedHealth[] {
  const bySite = new Map<string, SiteHealthRow>();
  for (const row of sections.sites.data ?? []) {
    const key = siteKey(row.host);
    bySite.set(key, mergeHealth(bySite.get(key) ?? null, { ...row, host: key }));
  }
  return [...bySite.values()].sort((a, b) => b.requests - a.requests || a.host.localeCompare(b.host)).map(rated);
}

/** How many sites the overview ranks; the rest are a click away in the list. */
export const MOST_ERRORS_LIMIT = 10;

/** The sites that reported the most errors, most first, leaving out any that reported none. */
export function mostErrorSites(sections: ErrorsSections, limit = MOST_ERRORS_LIMIT): RatedHealth[] {
  return errorsSiteRows(sections)
    .filter((row) => row.errors > 0)
    .sort((a, b) => b.errors - a.errors || b.failures - a.failures || a.host.localeCompare(b.host))
    .slice(0, limit);
}

/** Every site for Errors' list, alphabetically. */
export function errorsSites(sections: ErrorsSections): string[] {
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

/** A site's error row, merged across its hosts, with the identity it was merged on. */
export interface SiteErrorView extends SiteErrorRow {
  id: string;
}

/** A site's failed-request row, merged across its hosts, with the identity it was merged on. */
export interface SiteFailedRequestView extends SiteFailedRequestRow {
  id: string;
}

/**
 * One site's page, with everything it does not have left null or empty so the page need not draw it.
 * A site that served requests and reported no errors keeps its health: that zero is the finding.
 */
export interface ErrorsSiteReport {
  health: RatedHealth | null;
  chart: ErrorsSiteChart | null;
  /** Commonest first. */
  errors: SiteErrorView[];
  /** Commonest first. */
  requests: SiteFailedRequestView[];
  /** Nothing above has anything to draw. */
  empty: boolean;
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
): (T & { id: string })[] {
  const merged = new Map<string, T & { id: string }>();
  for (const row of rows) {
    if (siteKey(row.host) !== site) continue;
    const key = id(row);
    const seen = merged.get(key);
    merged.set(
      key,
      seen
        ? { ...seen, count: seen.count + row.count, lastSeen: laterOf(seen.lastSeen, row.lastSeen) }
        : { ...row, host: site, id: key },
    );
  }
  return [...merged.values()].sort((a, b) => b.count - a.count || a.id.localeCompare(b.id));
}

function siteChart(sections: ErrorsSections, site: string): ErrorsSiteChart | null {
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

export function errorsSiteReport(sections: ErrorsSections, site: string): ErrorsSiteReport {
  const health = errorsSiteRows(sections).find((row) => row.host === site) ?? null;
  const report: Omit<ErrorsSiteReport, 'empty'> = {
    health: health && (health.requests > 0 || health.errors > 0) ? health : null,
    chart: siteChart(sections, site),
    errors: mergeRows(sections.detail.data?.errors ?? [], site, errorRowId),
    requests: mergeRows(sections.detail.data?.requests ?? [], site, failedRequestRowId),
  };
  return {
    ...report,
    empty: report.health === null && report.chart === null && report.errors.length === 0 && report.requests.length === 0,
  };
}

/** What a site page could not read at all, which must stay visible on a page that hides absences. */
export function errorsSiteFailures(sections: ErrorsSections): SectionFailure[] {
  return collectFailures([
    { section: sections.sites, what: 'site totals', source: 'PostHog' },
    { section: sections.detail, what: 'errors and failed requests', source: 'PostHog' },
  ]);
}

/** Everything the Errors pages draw from PostHog's per-site sections. */
export interface ErrorsViews {
  /** Errors' site list, alphabetically. */
  sites: string[];
  /** The sites that reported the most errors, at most `mostErrorsLimit`, most first. */
  mostErrors: RatedHealth[];
  mostErrorsLimit: number;
  /** Each listed site's own page, keyed by site. */
  siteReports: Record<string, ErrorsSiteReport>;
  /** PostHog sections a site page could not read at all; empty when PostHog is not configured. */
  siteFailures: SectionFailure[];
}

export function errorsViews(sections: ErrorsSections, configured: { posthog: boolean }): ErrorsViews {
  const sites = errorsSites(sections);
  return {
    sites,
    mostErrors: mostErrorSites(sections),
    mostErrorsLimit: MOST_ERRORS_LIMIT,
    siteReports: Object.fromEntries(sites.map((site) => [site, errorsSiteReport(sections, site)])),
    siteFailures: configured.posthog ? errorsSiteFailures(sections) : [],
  };
}
