/**
 * Case-insensitive, token-AND substring match. Every whitespace-separated token
 * in `query` must appear somewhere in `haystack`. An empty query matches all.
 */
export function matchesQuery(haystack: string, query: string): boolean {
  const q = query.trim().toLowerCase();
  if (!q) return true;
  const h = haystack.toLowerCase();
  return q.split(/\s+/).every((t) => h.includes(t));
}

/**
 * Whether the environment filter keeps a row. Mirrors the server's `inScope`
 * (status-server src/board/view.ts), which judges `board.scope` the same way, so the rows on
 * screen and the headline over them agree: every environment selected keeps everything, and a
 * row with NO environment (null, absent, or the empty string) is env-agnostic and always kept,
 * so a platform-wide outage is never hidden by an environment filter.
 */
export function inEnvScope(selected: ReadonlySet<string> | null, environment: string | null | undefined): boolean {
  return selected === null || !environment || selected.has(environment);
}
