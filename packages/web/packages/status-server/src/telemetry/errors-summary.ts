import type { ErrorDTO, ErrorsSummary } from './types';

/** How many active issues the Errors card lists. */
export const ERRORS_TOP_COUNT = 5;

/**
 * The Errors card's figures, judged once here so no client re-derives them: how many
 * issues are ACTIVE (the board's own verdict, already stamped on each row as `active`),
 * how much backlog sits behind them, how many events all of them carry, and the active
 * issues worth listing — the loudest first, so the list matches its `{count}×` labels
 * (GlitchTip sends them in last-seen order, not by volume).
 *
 * A row with no `active` verdict counts as backlog, never as an incident and never as
 * clear: the summary is only attached where every row was judged.
 */
export function errorsSummary(errors: readonly ErrorDTO[]): ErrorsSummary {
  const active = errors.filter((e) => e.active === true);
  return {
    active: active.length,
    backlog: errors.length - active.length,
    events: errors.reduce((sum, e) => sum + (e.count || 0), 0),
    top: [...active].sort((a, b) => b.count - a.count).slice(0, ERRORS_TOP_COUNT),
  };
}
