import type { Indicator as BoardIndicator } from "./board-types";

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
