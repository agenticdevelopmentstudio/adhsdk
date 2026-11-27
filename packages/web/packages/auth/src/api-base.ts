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
 *
 * Throws on a base that is neither an absolute `http(s)://` URL nor a root-relative path: a
 * schemeless `api.example.com` (a common env-var slip) would otherwise turn every data call into
 * a page-relative URL that 404s far from here. Throws too on a path under `/api/`, the one base
 * that would make `apiUrl` non-idempotent; every accepted base is, so a path already resolved
 * through `apiUrl` can be handed to `authedJson` and resolved again safely.
 */
export function configureApiBase(apiBase: string | null | undefined): void {
  const trimmed = (apiBase ?? '').trim().replace(/\/+$/, '')
  if (trimmed === '') {
    base = SAME_ORIGIN_PREFIX
    return
  }
  if (!isAbsoluteHttpUrl(trimmed) && !isRootRelativePath(trimmed)) {
    throw new Error(
      `configureApiBase: "${trimmed}" is not an absolute http(s) URL or a root-relative path; ` +
        'give the backend origin with its scheme, e.g. https://api.example.com',
    )
  }
  if (trimmed.startsWith(`${SAME_ORIGIN_PREFIX}/`)) {
    // A base under `/api/` would make `apiUrl` rewrite its own output (`/api/backend/v1/x`
    // becomes `/api/backend/backend/v1/x` on a second pass), and the rewrite already forwards
    // every `/api/...` path, so such a base buys nothing.
    throw new Error(
      `configureApiBase: "${trimmed}" is under ${SAME_ORIGIN_PREFIX}/; use ${SAME_ORIGIN_PREFIX} itself or a path outside it`,
    )
  }
  base = trimmed
}

function isAbsoluteHttpUrl(value: string): boolean {
  if (!/^https?:\/\//i.test(value)) return false
  try {
    new URL(value)
    return true
  } catch {
    return false
  }
}

/** `/backend`, never `//host` (scheme-relative, a different host in disguise). */
function isRootRelativePath(value: string): boolean {
  return value.startsWith('/') && !value.startsWith('//')
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

/**
 * The inverse of {@link apiUrl}: a URL the toolkit sent under the configured base, given back in
 * the same-origin `/api/...` shape every client names (`https://api.example.com/v1/x?y` becomes
 * `/api/v1/x?y`). Anything not under the base is returned unchanged, and under the default base
 * this is the identity. For a reader that groups requests by path (the fetch telemetry), so a
 * host with a base and a host with the rewrite record the same call the same way.
 */
export function toolkitPath(url: string): string {
  if (base === SAME_ORIGIN_PREFIX || !url.startsWith(base)) return url
  const rest = url.slice(base.length)
  if (rest === '' || rest[0] === '/' || rest[0] === '?' || rest[0] === '#') return `${SAME_ORIGIN_PREFIX}${rest}`
  return url
}

/** Test-only: back to the default. */
export function resetApiBaseForTests(): void {
  base = SAME_ORIGIN_PREFIX
}
