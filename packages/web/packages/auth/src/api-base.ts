/**
 * Where the browser sends the toolkit's backend API calls: the one place that answer lives.
 *
 * Every data client in the toolkit names its route as a same-origin `/api/...` path
 * (`/api/v1/workspaces`, `/api/jobs/...`), the shape a site's `/api/:path*` rewrite forwards to
 * the backend. That stays the default, so the hub and every site with the rewrite behave exactly
 * as before. A host whose browser calls the backend directly instead (the product site, which has
 * no rewrite: Vercel only hosts it) configures the backend's public origin once at bootstrap, and
 * every `/api/...` path is then sent to `<base>/...`, the same destination the rewrite would have
 * chosen. A path that does not start with `/api/` (an absolute URL, a signed upload URL, a site's
 * own `/admin/auth/...` route) is never touched.
 *
 * Not the authorization server's base (`asBase.ts`, `NEXT_PUBLIC_AUTH_API_URL`): that one names
 * where sign-in happens, this one where the data calls go.
 *
 * Resolved where the requests are made (`rawFetch` and `publicJson`, the SSE transport, the few
 * raw fetches), never at the call sites, so no client carries the base itself. Deliberately
 * import-free, like `asBase.ts`, so every module that makes a request can read it without a cycle.
 */

/** The same-origin prefix a site's rewrite forwards, and the default base. */
const SAME_ORIGIN_PREFIX = '/api'

let base = SAME_ORIGIN_PREFIX

/**
 * Point every toolkit `/api/...` request at `apiBase`: an origin such as
 * `https://api.example.com` (trailing slashes dropped), or `/api` to restore the default.
 * Call it once at bootstrap, before the first request; calling it again with the same value is a
 * no-op, so a component may call it on every render. An empty value restores the default.
 */
export function configureApiBase(apiBase: string | null | undefined): void {
  const trimmed = (apiBase ?? '').trim().replace(/\/+$/, '')
  base = trimmed === '' ? SAME_ORIGIN_PREFIX : trimmed
}

/** The configured base: `/api` unless a host configured another. */
export function apiBase(): string {
  return base
}

/**
 * `path` resolved against the configured base. `/api` and `/api/...` (or `/api?...`) become
 * `<base>` and `<base>/...`; anything else is returned unchanged. Under the default base this is
 * the identity.
 */
export function apiUrl(path: string): string {
  if (base === SAME_ORIGIN_PREFIX || !path.startsWith(SAME_ORIGIN_PREFIX)) return path
  const rest = path.slice(SAME_ORIGIN_PREFIX.length)
  if (rest === '' || rest[0] === '/' || rest[0] === '?') return `${base}${rest}`
  return path
}

/** Test-only: back to the default. */
export function resetApiBaseForTests(): void {
  base = SAME_ORIGIN_PREFIX
}
