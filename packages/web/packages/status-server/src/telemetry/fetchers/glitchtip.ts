import type { Fetcher, FetchResult } from "../ports";
import type { ErrorDTO } from "../types";

// GlitchTip adapter for the Fetcher port. GlitchTip is Sentry-API-compatible: we
// poll the org-level issues endpoint and map each grouped issue to an ErrorDTO.
// GlitchTip owns the hard parts (source-maps + grouping); we summarize and
// deep-link via `permalink`. PURE w.r.t. storage — returns items, persists
// nothing. No-ops (ok, []) until GLITCHTIP_URL/_API_TOKEN/_ORG are configured.
//
// NOTE: verify the exact response shape against your GlitchTip instance when the
// project is live; the fields below follow the Sentry/GlitchTip issues schema.

export interface GlitchtipEnv {
  GLITCHTIP_URL?: string;
  GLITCHTIP_API_TOKEN?: string;
  GLITCHTIP_ORG?: string;
}

export interface GlitchtipIssue {
  id: string;
  title: string;
  culprit?: string | null;
  level?: string | null;
  count?: string | number | null;
  userCount?: number | null;
  firstSeen?: string | null;
  lastSeen?: string | null;
  permalink?: string | null;
  project?: { slug?: string; name?: string } | string | null;
  shortId?: string | null;
  metadata?: { type?: string | null; value?: string | null; filename?: string | null } | null;
  lastRelease?: { version?: string | null } | null;
}

function projectSlug(p: GlitchtipIssue["project"]): string {
  if (!p) return "unknown";
  if (typeof p === "string") return p;
  return p.slug ?? p.name ?? "unknown";
}

function normalizeIso(s: string | null | undefined): string | null {
  if (!s) return null;
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}

function toCount(c: string | number | null | undefined): number {
  if (typeof c === "number") return c;
  if (typeof c === "string") return Number.parseInt(c, 10) || 0;
  return 0;
}

/** Pure mapping issues → ErrorDTO[] — the testable core, no network. */
export function mapIssues(issues: GlitchtipIssue[]): ErrorDTO[] {
  return issues.map((i) => ({
    id: i.id,
    issueKey: i.id,
    project: projectSlug(i.project),
    title: i.title,
    culprit: i.culprit ?? null,
    level: i.level ?? null,
    count: toCount(i.count),
    userCount: i.userCount ?? 0,
    firstSeen: normalizeIso(i.firstSeen),
    lastSeen: normalizeIso(i.lastSeen),
    permalink: i.permalink ?? null,
  }));
}

// The issue query fans out over source-maps + grouping, so it's usually fast but
// can occasionally stall — give it a generous but BOUNDED budget (no retry: a retry
// just doubles a stalled cycle's wait, which stacked up to wedge the scheduler). The
// budget covers the WHOLE walk, not each page, so more pages can't mean a longer cycle.
const TIMEOUT_MS = 12_000;

/** GlitchTip caps a page at 100. A full page with no way forward is presumed truncated. */
export const PAGE_LIMIT = 100;

/**
 * Hard stop for the walk: 2,000 unresolved issues. Past it the answer is reported
 * `complete: false`, which only delays a resolve — the store just skips its sweep.
 */
export const MAX_PAGES = 20;

/** What a page's `Link` header says about the next one. */
type NextPage = { kind: "cursor"; cursor: string } | { kind: "end" } | { kind: "unknown" };

/**
 * GlitchTip's `Link` value is a stringified Python set, not RFC 8288:
 * `{'<https://…?cursor=abc>; rel="next"; results="true"; cursor="abc"', '<…>; rel="previous"; …'}`.
 * So this matches the `next` entry wherever it sits, and takes only its cursor: the URL
 * around it is provider data and never gets requested — see {@link fetchGlitchtipIssues}.
 */
export function parseNextPage(link: string | null): NextPage {
  const entry = /<[^>]*>;\s*rel="next";\s*results="(true|false)";\s*cursor="([^"]+)"/.exec(link ?? "");
  if (!entry) return { kind: "unknown" };
  return entry[1] === "true" ? { kind: "cursor", cursor: entry[2]! } : { kind: "end" };
}

function isTransient(err: unknown): boolean {
  const name = (err as { name?: string })?.name;
  return name === "AbortError" || name === "TimeoutError";
}

export interface GlitchtipIssuesResult {
  ok: boolean;
  issues: GlitchtipIssue[];
  /** The walk reached the end, so "absent from `issues`" really means absent. */
  complete: boolean;
}

/**
 * Every issue matching `query`, across all pages. Each `errorsStore` sweep and every line on
 * the Errors topic rest on this being the whole set or saying that it is not, so:
 *
 *   - the FIRST page failing fails the poll (`ok: false`): nothing was read;
 *   - a LATER page failing (HTTP error, bad body, timeout) stops with what was read, `ok` but
 *     not `complete`, exactly like a repeated cursor or the page cap. Reporting it `complete`
 *     would resolve every issue on the unread pages; reporting it `failed` would throw away the
 *     pages that did answer and mark a reachable GlitchTip with a large backlog as an outage.
 *
 * A walk of more than one page is not a snapshot: an issue that fires mid-walk moves to the top
 * of the list (newest event first), past the pages still to come, onto one already read. So a
 * multi-page walk claims `complete` only after re-reading page 1 at the end, which is where
 * every such mover (and every new issue) lands. The cursor is value-based, so a resolve
 * mid-walk does not shift the unread pages. If that re-read fails, the walk is not `complete`.
 *
 * The next URL is rebuilt from our own base + the cursor. The bearer token goes on every
 * request, so a header value must not be able to choose where it is sent.
 */
export async function fetchGlitchtipIssues(
  env: GlitchtipEnv,
  query: string,
): Promise<GlitchtipIssuesResult> {
  const { GLITCHTIP_URL, GLITCHTIP_API_TOKEN, GLITCHTIP_ORG } = env;
  if (!GLITCHTIP_URL || !GLITCHTIP_API_TOKEN || !GLITCHTIP_ORG) return { ok: true, issues: [], complete: true };

  const failed: GlitchtipIssuesResult = { ok: false, issues: [], complete: false };
  const first = `${GLITCHTIP_URL.replace(/\/+$/, "")}/api/0/organizations/${GLITCHTIP_ORG}/issues/?query=${query}&limit=${PAGE_LIMIT}`;
  // A SINGLE bounded attempt — no retry. Retrying a stalled provider just doubles the
  // time this cycle waits, and under sustained degradation that stacked up to blow the
  // scheduler's cycle budget (→ container restarts). A stall/HTTP error blanks the errors
  // band for THIS cycle; the next cycle refills it and the GlitchTip self-check surfaces a
  // genuine outage. Logged CONCISELY (no stack).
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  // By id: a cursor walk over a moving list can serve one issue on two pages, and the
  // store's batch upsert shouldn't have to care.
  const byId = new Map<string, GlitchtipIssue>();
  let pagesRead = 0;
  /** What a failure after page 1 returns: the pages that answered, never claimed whole. */
  const stopped = (): GlitchtipIssuesResult =>
    pagesRead === 0 ? failed : { ok: true, issues: [...byId.values()], complete: false };
  /** Page 1 again, merged in; `complete` only if it answered. See the doc comment above. */
  const confirmed = async (): Promise<GlitchtipIssuesResult> => {
    const res = await fetch(first, {
      headers: { Authorization: `Bearer ${GLITCHTIP_API_TOKEN}` },
      signal: controller.signal,
    });
    const issues: unknown = res.ok ? await res.json() : null;
    if (!Array.isArray(issues)) {
      console.warn("[telemetry] GlitchTip issues re-read of page 1 failed — reporting the walk incomplete");
      return stopped();
    }
    for (const issue of issues as GlitchtipIssue[]) byId.set(issue.id, issue);
    return { ok: true, issues: [...byId.values()], complete: true };
  };
  try {
    const seenCursors = new Set<string>();
    let url = first;
    for (let page = 1; page <= MAX_PAGES; page++) {
      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${GLITCHTIP_API_TOKEN}` },
        signal: controller.signal,
      });
      if (!res.ok) {
        console.warn(`[telemetry] GlitchTip issues HTTP ${res.status}`);
        return stopped();
      }
      const issues = (await res.json()) as GlitchtipIssue[];
      if (!Array.isArray(issues)) {
        // A 200 that isn't a list is a FAILED poll, not an empty one. This used to
        // return `ok: true, items: []` and was inert only because the store early-returned
        // on an empty set; against a reconciling store the same value resolves the entire
        // errors table and pages on-call an all-clear during a live incident. Every shape
        // that lands here — an error envelope, a maintenance page, an auth-proxy
        // interstitial, a paginated `{results:[…]}` wrapper — means we did not get the
        // answer we asked for, which is exactly what `ok: false` is for.
        console.warn("[telemetry] GlitchTip issues returned a non-array body — treating as a failed poll");
        return stopped();
      }
      for (const issue of issues) byId.set(issue.id, issue);
      pagesRead = page;

      const next = parseNextPage(res.headers.get("link"));
      const all = [...byId.values()];
      if (next.kind === "end") return page === 1 ? { ok: true, issues: all, complete: true } : await confirmed();
      // No usable header: a short page is the end, a full one is presumed truncated.
      // Errs toward "we may not have seen everything", which costs a delayed resolve;
      // the other way costs a flap.
      if (next.kind === "unknown") return { ok: true, issues: all, complete: issues.length < PAGE_LIMIT };
      if (seenCursors.has(next.cursor) || page === MAX_PAGES) return { ok: true, issues: all, complete: false };
      seenCursors.add(next.cursor);
      url = `${first}&cursor=${encodeURIComponent(next.cursor)}`;
    }
    return failed; // unreachable: the loop's last iteration always returns
  } catch (err) {
    console.warn(
      isTransient(err)
        ? `[telemetry] GlitchTip issues fetch timed out after ${TIMEOUT_MS}ms`
        : `[telemetry] GlitchTip issues fetch failed: ${(err as Error)?.message ?? String(err)}`,
    );
    return stopped();
  } finally {
    clearTimeout(timer);
  }
}

export function glitchtipFetcher(env: GlitchtipEnv): Fetcher<ErrorDTO> {
  return {
    async fetch(): Promise<FetchResult<ErrorDTO>> {
      if (!env.GLITCHTIP_URL || !env.GLITCHTIP_API_TOKEN || !env.GLITCHTIP_ORG) return { ok: true, items: [] };
      const { ok, issues, complete } = await fetchGlitchtipIssues(env, "is:unresolved");
      return ok ? { ok: true, items: mapIssues(issues), complete } : { ok: false, items: [] };
    },
  };
}
