import type { ActivityRow, Indicator as BoardIndicator, Problem } from "./board-types";

// ---------------------------------------------------------------------------
// How the board's verdicts are WORDED and drawn. Every verdict itself is the server's
// (`GET /board`): the indicator and its env-scoped twin (`scope`), which activity rows are
// unresolved or running (`unresolved` / `running` / `buildInFlight` on each row), the
// stats-strip counts (`deployCounts`) and the board's freshness. What is left here maps
// those to the sign's vocabulary and to words.
// ---------------------------------------------------------------------------

export type IndicatorState = "ok" | "warn" | "down";

export interface Indicator {
  state: IndicatorState;
  count: number;
}

/** The wire indicator → the sign's vocabulary. The ONLY translation between the two. */
export const INDICATOR_STATE: Record<BoardIndicator, IndicatorState> = {
  operational: "ok",
  degraded: "warn",
  outage: "down",
};

/**
 * The caption for the activity window the SERVER chose — "24h", "7d" — in the same
 * vocabulary as the span menu's labels.
 *
 * Derived from the board's own boundary rather than written out beside the counts,
 * because a hardcoded "· 24h" beside a count taken over a different window is a label
 * that lies without anything failing: the server owns `ACTIVITY_WINDOW_MS`, and changing
 * it there would have left this caption stating the old figure forever.
 */
export function activityWindowLabel(fromMs: number, toMs: number): string {
  const hours = Math.max(1, Math.round((toMs - fromMs) / 3_600_000));
  return hours >= 48 && hours % 24 === 0 ? `${hours / 24}d` : `${hours}h`;
}

/** The headline the status sign / pill announces, e.g. "4 PROBLEMS" or
 *  "ALL SYSTEMS OPERATIONAL". Shared by the mobile hero sign and the desktop
 *  top-bar pill (as its accessible name) so they can never word it differently. */
export function headlineFor(state: IndicatorState, count: number): string {
  if (state === "ok") return "ALL SYSTEMS OPERATIONAL";
  if (state === "warn") return count === 1 ? "1 SERVICE NEEDS ATTENTION" : `${count} SERVICES NEED ATTENTION`;
  return count === 1 ? "1 PROBLEM" : `${count} PROBLEMS`;
}

/**
 * Whether a feed row is still unresolved against the CURRENT board. The server's `unresolved`
 * verdict was judged against the problems of the read that served the row, and a paged-in or
 * retained history row outlives that read. A failure stays unresolved only while one of the
 * problems the server named as carrying it (`heldOpenBy`: target and onset) is still on the
 * board; this looks them up and judges nothing itself. A row in flight carries no such
 * problems and keeps its verdict, and so does a row from a backend that sends no `heldOpenBy`.
 */
export function stillUnresolved(a: ActivityRow, problems: readonly Pick<Problem, "target" | "since">[]): boolean {
  if (a.unresolved !== true) return false;
  const held = a.heldOpenBy;
  if (held == null || held.length === 0) return true;
  return problems.some((p) => p.target === a.target && held.includes(p.since));
}
