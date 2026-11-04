// What makes a GlitchTip issue a current problem rather than backlog. A mirror of the board's rule
// in status-server's board/derive-problems.ts (error-activity-parity.test.ts holds the two
// together), because the Overview card and the Problems pane have to agree: a card painted red by
// issues the board has already judged old reads as an alert nobody can clear.

const ACTIVE_LEVELS: ReadonlySet<string> = new Set(["error", "fatal"]);

export const ACTIVE_WINDOW_MS = 24 * 60 * 60 * 1000;

/** Error or fatal, and seen in the last 24 hours. An unknown level or time is not a claim of harm. */
export function isActiveError(level: string | null, lastSeen: string | null, nowMs: number): boolean {
  if (!ACTIVE_LEVELS.has((level ?? "").toLowerCase())) return false;
  const seen = lastSeen ? new Date(lastSeen).getTime() : Number.NaN;
  return !Number.isNaN(seen) && nowMs - seen <= ACTIVE_WINDOW_MS;
}

/** Exposed for the parity test. */
export const ACTIVE_LEVEL_NAMES: readonly string[] = [...ACTIVE_LEVELS];
