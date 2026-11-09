/**
 * Stable, locale-light date label (e.g. "Jun 24, 2026") shared by the markdown result
 * row and preview header (mirrors the research site's papers-api.formatUpdated).
 * An unparseable input yields `''` — callers render nothing rather than "Invalid Date".
 */
export function formatDate(iso: string): string {
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  return d.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
}

/** A /v1 unix-second timestamp as an ISO string (`''` when it is not a finite number). This
 *  package has no auth dependency, so it carries its own copy of `@adh-sdk/auth/client`'s
 *  `unixToIso` rather than import an authed HTTP client into a marketing bundle. */
export function unixToIso(seconds: number | null | undefined): string {
  if (seconds === null || seconds === undefined || !Number.isFinite(seconds)) return ''
  return new Date(seconds * 1000).toISOString()
}
