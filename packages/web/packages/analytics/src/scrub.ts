// URL scrubbing shared by every analytics and error pipeline: what leaves the browser is a
// low-cardinality, PII-free shape, never a raw URL. Pure functions, no browser APIs, so a
// server module can import them too.

// Applied globally (not anchored) so ids EMBEDDED in a segment are redacted too — e.g.
// `user-123456` or an `order_<uuid>` slug, not just a whole-segment id. Neither pattern
// can span a `/`, so running them over the full pathname is safe. The digit threshold is
// 4 so ordinary low-cardinality numbers (ports, small enums, `/items/42`) survive while
// id-/timestamp-shaped runs collapse.
const UUID_ANYWHERE = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi
const DIGIT_RUN = /\d{4,}/g

/**
 * Reduce a URL or path to a low-cardinality, PII-free shape for grouping: keep only the
 * pathname (drop origin + query + hash, which can carry tokens), and replace UUIDs and
 * long-numeric runs — including ones embedded in a segment — with `:id`, so
 * `/api/persona/services/<uuid>` and `/api/users/user-123456` both collapse to `:id`.
 * Non-http(s) URLs (data:/mailto:/blob:/javascript:) carry payload/PII in their
 * "pathname", so they never get emitted.
 */
export function scrubPath(url: string): string {
  let pathname: string
  try {
    // Base lets this accept both absolute URLs and root-relative paths.
    const u = new URL(url, 'http://_')
    if (u.protocol !== 'http:' && u.protocol !== 'https:') return ':non-http'
    pathname = u.pathname
  } catch {
    const cuts = [url.indexOf('?'), url.indexOf('#')].filter((i) => i >= 0)
    pathname = cuts.length ? url.slice(0, Math.min(...cuts)) : url
  }
  return pathname.replace(UUID_ANYWHERE, ':id').replace(DIGIT_RUN, ':id')
}

/** Reduce a URL to origin + a redacted path: drops query/hash (tokens) AND redacts
 *  id-shaped path segments via `scrubPath`, so pageview and web-vitals events don't leak
 *  `/u/<id>`-style ids. */
export function scrubUrl(url: string | undefined): string | undefined {
  if (!url) return url
  try {
    const u = new URL(url)
    return u.origin + scrubPath(u.pathname)
  } catch {
    // Relative or non-URL value — scrub it as a bare path.
    return scrubPath(url)
  }
}
