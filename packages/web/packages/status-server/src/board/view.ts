import { snapshotStaleMs } from "../monitor/live-view";
import { BUILD_VERB, indicatorFor } from "./derive-activity";
import type { ActivityRow, BoardFacts, Indicator, Problem } from "./types";

// ---------------------------------------------------------------------------
// The judgements `GET /board` (and `GET /activity`) publish beside the problems and the
// feed, so the web renders a verdict instead of re-deriving one. Each of these used to
// live in status-web (`board-staleness.ts`; `overview.ts`'s `isUnresolvedActivity`,
// `isActiveBuild`, `deployCounts` and `indicatorFromProblems`; `use-build-progress.ts`'s
// in-flight test) and ran in every browser with its own copy of the rule. Pure: no IO,
// and no clock but the `nowMs` the fold was given.
// ---------------------------------------------------------------------------

/**
 * How often a client re-reads the board when the SSE stream is quiet. A client may read it
 * more often (every stream frame triggers a read); reading it less often would let
 * `staleAt` trip on a board that is merely between polls. Published as
 * `freshness.pollIntervalMs` so the client's poll and this deadline come from one number.
 */
export const BOARD_POLL_INTERVAL_MS = 60_000;

/**
 * How long a board may go without being re-read before it can no longer back a current
 * claim: three poll cycles, so one missed poll (a slow request, a momentary blip) cannot
 * trip it, while a permanently failing `/board` is caught well within a wallboard viewer's
 * attention span.
 */
export const BOARD_STALE_MS = 3 * BOARD_POLL_INTERVAL_MS;

/**
 * How many write cadences of the board's SLOWEST heartbeat fact may pass before its data
 * clock can no longer back a current claim. Must be ≥ 2: the fact is written at the end of
 * a cycle, so its age reaches one whole cadence just before it is rewritten, and a window
 * equal to the cadence is crossed at the tail of every cycle by construction.
 */
export const BOARD_DATA_STALE_CYCLES = 2;

/**
 * How far the board's data clock may lag its derivation clock, for a backend probing at
 * `probeIntervalMs`. Cadence-scaled through `snapshotStaleMs` — the one producer of "how
 * old is too old", the same rule `/live`'s freshness uses — times the headroom above. A
 * fixed window broke the board at `PROBE_INTERVAL_SECONDS=3600` (every fact older than it
 * five minutes after boot) and flapped it once per cycle on a fleet with no HTTP
 * endpoints, where the platform sample on the full-sync cadence is the heartbeat. A
 * missing cadence falls back to the widest window, so it can only delay the verdict.
 */
export function boardDataStaleMs(probeIntervalMs?: number | null): number {
  return snapshotStaleMs(probeIntervalMs) * BOARD_DATA_STALE_CYCLES;
}

/**
 * What the board's data clock says about the board.
 *
 * - `current` — the newest observation is recent enough to back what the board claims.
 * - `frozen`  — observations exist but have stopped arriving: a wedged monitor that keeps
 *               re-stamping `generatedAt` over facts that no longer move.
 * - `no-data` — the board rests on no observation at all. Never health, but not a fault
 *               either: the normal state of a roster with nothing to observe and of a
 *               monitor that has not finished its first cycle.
 */
export type BoardDataFreshness = "current" | "frozen" | "no-data";

/** Judged server clock against server clock, so client clock skew cannot move it. */
export function boardDataFreshness(
  dataAsOfMs: number | null,
  generatedAtMs: number,
  probeIntervalMs?: number | null,
): BoardDataFreshness {
  if (dataAsOfMs === null) return "no-data";
  const lag = generatedAtMs - dataAsOfMs;
  if (!Number.isFinite(lag)) return "frozen";
  return lag > boardDataStaleMs(probeIntervalMs) ? "frozen" : "current";
}

/** `Board.freshness` — both halves of "can this board back a current claim". */
export interface BoardFreshness {
  /** Whether the FACTS behind the board are current (see {@link BoardDataFreshness}). */
  state: BoardDataFreshness;
  /**
   * ISO instant after which THIS READ can no longer back a claim if no newer one has
   * arrived (`generatedAt + BOARD_STALE_MS`). The client compares its own clock to it,
   * because only the receiver can see that reads have stopped arriving; the deadline
   * itself is the server's.
   */
  staleAt: string;
  /** How often a client should re-read the board (`BOARD_POLL_INTERVAL_MS`). */
  pollIntervalMs: number;
}

export function boardFreshness(
  dataAsOfMs: number | null,
  nowMs: number,
  probeIntervalMs?: number | null,
): BoardFreshness {
  return {
    state: boardDataFreshness(dataAsOfMs, nowMs, probeIntervalMs),
    staleAt: new Date(nowMs + BOARD_STALE_MS).toISOString(),
    pollIntervalMs: BOARD_POLL_INTERVAL_MS,
  };
}

/**
 * Is this build or deploy row still happening, or still wrong?
 *
 * Builds and deploys only (`step` set): an issue row is not a build, and while it is open
 * the Problems list already carries it. An in-flight row counts — its phase is the current
 * reading. A FAILED row is a record of an event and stays `bad` forever after the target
 * recovered, so it counts only while a live problem still carries its target and the
 * failure is not older than that problem's onset: an earlier failure followed by a
 * recovery and a new failure is history, not part of the run that is still open.
 */
export function isUnresolvedActivity(a: ActivityRow, problems: readonly Problem[]): boolean {
  if (a.step === null) return false;
  if (a.tone === "progress") return true;
  if (a.tone !== "bad") return false;
  const at = Date.parse(a.at);
  return problems.some((p) => p.target === a.target && Date.parse(p.since) <= at);
}

/**
 * A build or deploy that is actually RUNNING — in flight and past the queue. Queued and
 * building rows share tone `progress`, so the verb is what tells them apart.
 */
export function isRunningActivity(a: ActivityRow): boolean {
  return a.step !== null && a.tone === "progress" && a.verb !== BUILD_VERB.queued;
}

/** A build still in flight (queued or building) — what the build-progress bar counts. */
export function isBuildInFlight(a: ActivityRow): boolean {
  return a.kind === "deploy" && a.step === "build" && a.tone === "progress";
}

/** Stamp each row with the three judgements above, against the current problems. */
export function withAttention(rows: readonly ActivityRow[], problems: readonly Problem[]): ActivityRow[] {
  return rows.map((a) => ({
    ...a,
    unresolved: isUnresolvedActivity(a, problems),
    running: isRunningActivity(a),
    buildInFlight: isBuildInFlight(a),
  }));
}

/** `Board.deployCounts` — the stats strip's figures over the board's activity window. */
export interface DeployCounts {
  builds: number;
  deploys: number;
  failures: number;
}

export function deployCounts(activity: readonly ActivityRow[], sinceMs: number): DeployCounts {
  let builds = 0;
  let deploys = 0;
  let failures = 0;
  for (const a of activity) {
    if (a.kind !== "deploy" || Date.parse(a.at) < sinceMs) continue;
    if (a.step === "build") builds++;
    else if (a.step === "deploy") deploys++;
    if (a.tone === "bad") failures++;
  }
  return { builds, deploys, failures };
}

/**
 * `Board.scope` — the headline over the environments a reader chose to see. Null
 * `environments` is every environment. A problem or endpoint with NO environment is always
 * in scope: an env-agnostic row (a platform-wide outage) must never be hidden by an
 * environment filter.
 */
export interface BoardScope {
  environments: string[] | null;
  indicator: Indicator;
  problemCount: number;
  /** Active endpoints in scope, and how many were last probed healthy. An endpoint never
   *  probed counts in `total` and never in `healthy`. */
  endpoints: { total: number; healthy: number };
}

export function inScope(environments: readonly string[] | null, environment: string | null | undefined): boolean {
  return environments === null || !environment || environments.includes(environment);
}

export function boardScope(
  facts: Pick<BoardFacts, "roster" | "endpoints">,
  problems: readonly Problem[],
  environments: readonly string[] | null,
): BoardScope {
  const scoped = problems.filter((p) => inScope(environments, p.environment));
  const status = new Map(facts.endpoints.map((e) => [e.endpointId, e.status]));
  const endpoints = facts.roster.filter((e) => e.isActive && inScope(environments, e.environment));
  return {
    environments: environments === null ? null : [...environments],
    indicator: indicatorFor(scoped),
    problemCount: scoped.length,
    endpoints: {
      total: endpoints.length,
      healthy: endpoints.filter((e) => status.get(e.endpointId) === "healthy").length,
    },
  };
}

/**
 * Parse `?environments=` — absent is every environment (null), present-but-empty is none,
 * otherwise a comma list with blanks dropped.
 */
export function parseEnvironments(raw: string | undefined): string[] | null {
  if (raw === undefined) return null;
  return raw.split(",").map((s) => s.trim()).filter((s) => s.length > 0);
}
