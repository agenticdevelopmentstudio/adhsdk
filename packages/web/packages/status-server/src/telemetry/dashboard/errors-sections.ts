import { ERROR_JUDGED_LEVELS, ERROR_RECENT_MS } from "../../board/derive-problems";
import { fetchGlitchtipIssues, mapIssues, type GlitchtipEnv, type GlitchtipIssue } from "../fetchers/glitchtip";
import { alignToBuckets, rangeWindow, type RangeWindow } from "./ranges";
import type { ErrorIssue, ErrorsEventsSection, ErrorsIssuesSection } from "./types";

// The GlitchTip half of the Errors topic: every unresolved issue, read as the board reads it.

const STATS_TIMEOUT_MS = 12_000;
const DAY_MS = 24 * 3_600_000;

/** The board's rule for an error being a current Problem, on an API row. */
export function isActiveIssue(level: string | null, lastSeen: string | null, nowMs: number): boolean {
  if (!ERROR_JUDGED_LEVELS.has((level ?? "").toLowerCase())) return false;
  const seen = lastSeen ? new Date(lastSeen).getTime() : Number.NaN;
  return !Number.isNaN(seen) && nowMs - seen <= ERROR_RECENT_MS;
}

export function toErrorIssues(raw: GlitchtipIssue[], nowMs: number): ErrorIssue[] {
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
      active: isActiveIssue(dto.level, dto.lastSeen, nowMs),
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
  return {
    buckets: w.buckets,
    issues: [...issues].sort(compareIssues),
    summary: {
      active: issues.filter((i) => i.active).length,
      backlog: issues.length,
      events: issues.reduce((a, i) => a + i.count, 0),
      resolved: extra.resolved,
      complete: extra.complete,
      byType: [...byType.values()].sort((a, b) => b.events - a.events),
      newPerDay: alignToBuckets(w.buckets, firstSeenDays),
    },
  };
}

export async function loadErrorIssues(env: GlitchtipEnv, nowMs: number = Date.now()): Promise<ErrorsIssuesSection> {
  const unresolved = await fetchGlitchtipIssues(env, "is:unresolved");
  if (!unresolved.ok) throw new Error("GlitchTip issues could not be read");
  // A nice-to-have on the KPI row: losing it must not cost the issue list.
  const resolved = await fetchGlitchtipIssues(env, "is:resolved");
  return summarizeIssues(toErrorIssues(unresolved.issues, nowMs), rangeWindow("30d", nowMs), {
    resolved: resolved.ok && resolved.complete ? resolved.issues.length : null,
    complete: unresolved.complete,
  });
}

interface StatsBody {
  intervals?: unknown[];
  groups?: { series?: Record<string, (number | null)[]> }[];
}

/** stats_v2 → a value per bucket; its null intervals are days with nothing to report. */
export function shapeEventStats(body: StatsBody, buckets: string[]): ErrorsEventsSection {
  const values = body.groups?.[0]?.series?.["sum(quantity)"] ?? [];
  const points = (body.intervals ?? []).map((at, i): [unknown, number] => [at, values[i] ?? 0]);
  return { buckets, events: alignToBuckets(buckets, points) };
}

export async function loadErrorEvents(env: GlitchtipEnv, nowMs: number = Date.now()): Promise<ErrorsEventsSection> {
  const w = rangeWindow("30d", nowMs);
  const base = `${(env.GLITCHTIP_URL ?? "").replace(/\/+$/, "")}/api/0/organizations/${env.GLITCHTIP_ORG}/stats_v2/`;
  const url = new URL(base);
  url.searchParams.set("category", "error");
  url.searchParams.set("interval", "1d");
  url.searchParams.set("field", "sum(quantity)");
  url.searchParams.set("start", `${w.since.toISOString().slice(0, 19)}Z`);
  url.searchParams.set("end", `${w.until.toISOString().slice(0, 19)}Z`);
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${env.GLITCHTIP_API_TOKEN}` },
    signal: AbortSignal.timeout(STATS_TIMEOUT_MS),
  });
  if (!res.ok) throw new Error(`GlitchTip stats HTTP ${res.status}`);
  return shapeEventStats((await res.json()) as StatsBody, w.buckets);
}
