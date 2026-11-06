import { cachedSingleFlight } from "@adh-sdk/deploy-platform/util";
import { errorCountsAsProblem, type ErrorJudging } from "../../board/derive-problems";
import { fetchGlitchtipIssues, mapIssues, type GlitchtipEnv, type GlitchtipIssue } from "../fetchers/glitchtip";
import { alignToBuckets, rangeWindow, type RangeWindow } from "./ranges";
import type { ErrorIssue, ErrorsIssuesSection } from "./types";

// The GlitchTip half of the Errors topic: every unresolved issue, read as the board reads it.
//
// There is deliberately no events-per-day series. GlitchTip's stats_v2 answers 200 with nulls for
// every interval on this instance (both fields, daily and hourly) while issues are firing, so it
// would draw a flat zero beside issues reporting hundreds of events.

const DAY_MS = 24 * 3_600_000;

/** An ISO time as epoch ms, null when absent or unreadable (which the board reads as not current). */
export function isoMs(iso: string | null): number | null {
  const ms = iso ? new Date(iso).getTime() : Number.NaN;
  return Number.isNaN(ms) ? null : ms;
}

/** `active` is the board's whole rule, allowlist and all: see `errorCountsAsProblem`. */
export function toErrorIssues(raw: GlitchtipIssue[], judging: ErrorJudging): ErrorIssue[] {
  const mapped = mapIssues(raw);
  return raw.map((issue, i) => {
    const dto = mapped[i]!;
    return {
      id: dto.id,
      shortId: issue.shortId ?? null,
      title: dto.title,
      type: issue.metadata?.type || null,
      source: issue.metadata?.filename || null,
      level: dto.level,
      count: dto.count,
      userCount: dto.userCount,
      firstSeen: dto.firstSeen,
      lastSeen: dto.lastSeen,
      release: issue.lastRelease?.version || null,
      project: dto.project,
      permalink: dto.permalink,
      active: errorCountsAsProblem({ project: dto.project, level: dto.level, lastSeenMs: isoMs(dto.lastSeen) }, judging),
    };
  });
}

/** Active first, then by how often they fire. */
function compareIssues(a: ErrorIssue, b: ErrorIssue): number {
  return Number(b.active) - Number(a.active) || b.count - a.count;
}

export function summarizeIssues(
  issues: ErrorIssue[],
  w: RangeWindow,
  extra: { resolved: number | null; complete: boolean },
): ErrorsIssuesSection {
  const byType = new Map<string, { name: string; issues: number; events: number }>();
  for (const issue of issues) {
    const name = issue.type ?? "Other";
    const row = byType.get(name) ?? { name, issues: 0, events: 0 };
    row.issues += 1;
    row.events += issue.count;
    byType.set(name, row);
  }
  const firstSeenDays = issues.flatMap((issue): [unknown, number][] =>
    issue.firstSeen
      ? [[new Date(Math.floor(new Date(issue.firstSeen).getTime() / DAY_MS) * DAY_MS).toISOString(), 1]]
      : [],
  );
  const active = issues.filter((i) => i.active).length;
  return {
    buckets: w.buckets,
    issues: [...issues].sort(compareIssues),
    summary: {
      active,
      backlog: issues.length - active,
      events: issues.reduce((a, i) => a + i.count, 0),
      resolved: extra.resolved,
      complete: extra.complete,
      byType: [...byType.values()].sort((a, b) => b.events - a.events),
      newPerDay: alignToBuckets(w.buckets, firstSeenDays),
    },
  };
}

/** How long a resolved count stands. It only grows as issues are closed, and is one KPI figure. */
export const RESOLVED_COUNT_TTL_MS = 60 * 60_000;

/** The number of resolved issues, null when it could not be counted. */
export type ResolvedCount = () => Promise<number | null>;

/**
 * The resolved count, read at most once per `ttlMs`.
 *
 * GlitchTip has no count endpoint, so counting means walking every `is:resolved` page (up to
 * MAX_PAGES) only to take the list's length. Doing that on the issue list's own 60s refresh spent
 * up to twenty requests a minute on one figure that barely moves. A failed read is not kept, so
 * the next refresh tries again, and that includes a walk cut short by a failure after its first
 * page (`interrupted`), which would otherwise stand as "not counted" for the whole TTL. A walk
 * that hit the page cap is kept, since walking it again would hit the cap again.
 */
export function resolvedCounter(env: GlitchtipEnv, ttlMs: number = RESOLVED_COUNT_TTL_MS): ResolvedCount {
  const cached = cachedSingleFlight(ttlMs, async () => {
    const resolved = await fetchGlitchtipIssues(env, "is:resolved");
    if (!resolved.ok || resolved.interrupted) throw new Error("GlitchTip resolved issues could not be read");
    return resolved.complete ? resolved.issues.length : null;
  });
  return () => cached().catch(() => null);
}

export async function loadErrorIssues(
  env: GlitchtipEnv,
  allowlist: readonly string[] | null,
  resolvedCount: ResolvedCount,
  nowMs: number = Date.now(),
): Promise<ErrorsIssuesSection> {
  const unresolved = await fetchGlitchtipIssues(env, "is:unresolved");
  // A failed read throws, so the section keeps its last answer (and its `active` flags, judged
  // when that answer was read) rather than judging anything as a frozen feed.
  if (!unresolved.ok) throw new Error("GlitchTip issues could not be read");
  // A nice-to-have on the KPI row: losing it must not cost the issue list.
  const resolved = await resolvedCount();
  const judging: ErrorJudging = { nowMs, frozen: false, allowlist };
  return summarizeIssues(toErrorIssues(unresolved.issues, judging), rangeWindow("30d", nowMs), {
    resolved,
    complete: unresolved.complete,
  });
}
