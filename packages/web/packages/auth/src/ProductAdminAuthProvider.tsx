'use client'

// The session for a PRODUCT ADMIN SITE (phase 6): a product's own admins, signed in with the
// product's customer login, managing that product at its own host.
//
// It is not AuthProvider. The site's refresh token is an HttpOnly cookie (`pa_refresh`) on the
// site's own origin, set and rotated by the site's auth route handlers (mounted at the `authBase`
// prop, e.g. `/admin/auth`), and the access token is held here, in memory, never in storage or a
// URL. On mount it asks `POST <authBase>/session` for an access token; a 401 there means no
// session, and the browser goes to `<authBase>/signin?return=<path>`.
// Every request that spends the refresh cookie holds a Web Lock, so the site's tabs take turns.
// It refreshes a minute before the token expires, then reads `GET /api/v1/account`: an account
// without the product's `admin` role is `no-access`.
//
// It supplies the bearer to every `authedJson` caller (so every `@adh-sdk/data` client) through
// the package's AccessTokenSource seam, which is how AuthProvider's storage-held token reaches
// them too: AuthProvider is unchanged, and a page under this provider must not also mount it.

import {
  createContext,
  useCallback,
  useContext,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  type ReactElement,
  type ReactNode,
} from 'react'
import { authedJson } from './client'
import { announceSessionChange, decodeBase64UrlJson, setAccessTokenSource, accessTokenSource, type AccessTokenSource } from './tokens'

/** `GET /api/v1/account` for a customer, mapped. */
export interface ProductAdminAccount {
  user: { id: string; email: string | null; name: string | null; avatarUrl: string | null }
  /** The product (ecosystem) uuid the session belongs to. */
  ecosystemId: string
  /** The product role slugs held product-wide. */
  roles: string[]
}

interface ProductAdminAccountWire {
  user: { id: string; email?: string | null; name?: string | null; avatar_url?: string | null }
  ecosystem_id: string
  realm?: string
  roles?: string[]
}

export type ProductAdminAuthStatus = 'loading' | 'ready' | 'no-access'

export interface ProductAdminAuthValue {
  status: ProductAdminAuthStatus
  account: ProductAdminAccount | null
  accessToken: string | null
  signOut: () => Promise<void>
  /**
   * Send the browser through sign-in again with a fresh second factor (phase 7 step-up): an
   * answer of 403 `step_up_required` means the session is not aal 2 or its sign-in is more than
   * ten minutes old. `returnPath` defaults to the current page.
   */
  stepUp: (returnPath?: string) => void
}

/** `authBase` without its trailing slashes, so `/admin/auth/` builds `/admin/auth/session`, never
 *  `/admin/auth//session`. Every URL built from an auth base goes through this. */
function normalizeAuthBase(authBase: string): string {
  return authBase.replace(/\/+$/, '')
}

/**
 * The sign-in URL for a step-up: `prompt=login` makes the login ask again even with a live
 * session, and `max_age=600` matches the backend's ten-minute window. A trailing slash on
 * `authBase` is dropped.
 */
export function stepUpSigninUrl(authBase: string, returnPath: string): string {
  return `${normalizeAuthBase(authBase)}/signin?return=${encodeURIComponent(returnPath)}&prompt=login&max_age=600`
}

export interface ProductAdminAuthProviderProps {
  children: ReactNode
  /**
   * Where the site's auth route handlers are mounted, e.g. `/admin/auth`. A trailing slash is
   * dropped, so `/admin/auth/` means the same.
   * Required, not defaulted, so a host that forgets it fails to compile rather than calling the
   * wrong path.
   */
  authBase: string
  /** Where the browser goes; a seam for tests. Defaults to `window.location.assign`. */
  navigate?: (url: string) => void
}

/** How long before `exp` the token is refreshed. */
export const PRODUCT_ADMIN_REFRESH_LEAD_MS = 60_000
/** The shortest wait between refreshes, so a token that is already near expiry cannot spin. */
const MIN_REFRESH_DELAY_MS = 5_000

const ProductAdminAuthContext = createContext<ProductAdminAuthValue | null>(null)

/** The `<authBase>/session` answer's `expiresAt` in ms: unix seconds, unix ms or ISO 8601; else the
 *  token's own `exp`; else null (no scheduled refresh; a 401 still refreshes on demand). */
function expiryMs(expiresAt: unknown, token: string): number | null {
  if (typeof expiresAt === 'number' && Number.isFinite(expiresAt)) {
    return expiresAt < 1e12 ? expiresAt * 1000 : expiresAt
  }
  if (typeof expiresAt === 'string') {
    const t = Date.parse(expiresAt)
    if (!Number.isNaN(t)) return t
  }
  const claims = decodeBase64UrlJson(token.split('.')[1] ?? '') as { exp?: unknown } | null
  return typeof claims?.exp === 'number' ? claims.exp * 1000 : null
}

function toAccount(w: ProductAdminAccountWire): ProductAdminAccount {
  return {
    user: {
      id: w.user.id,
      email: w.user.email ?? null,
      name: w.user.name ?? null,
      avatarUrl: w.user.avatar_url || null,
    },
    ecosystemId: w.ecosystem_id,
    roles: w.roles ?? [],
  }
}

/** A session from `POST <authBase>/session`; null is its 401, no session. */
type SessionAnswer = { accessToken: string; expiresAt: unknown } | null

// The `POST <authBase>/session` in flight in this page, keyed by its URL and shared by every
// caller for that URL until it answers. It lives at module scope, not in a mount, because the
// site's auth handlers ROTATE the refresh cookie: a second POST sent before the first answers
// presents a cookie that has just been spent, and the server takes that as a lost session. A
// StrictMode remount, or an unmount and a new provider while a request is out, therefore joins
// this request; each mount decides for itself (by its generation) whether to adopt what comes
// back. A provider with a different auth base never joins another base's request: it sends its
// own, after that one answers.
const sessionRequests = new Map<string, Promise<SessionAnswer>>()

/** The Web Lock every tab of the site takes around a request that spends the refresh cookie. */
const PRODUCT_ADMIN_SESSION_LOCK = 'adh-product-admin-session'

/**
 * Run `fn` holding {@link PRODUCT_ADMIN_SESSION_LOCK}, so no two TABS of the site have a
 * cookie-spending request out at once. Two tabs that refresh together (a restored browser session,
 * two pages opened at once) would otherwise both present the same refresh cookie, and the loser's
 * refusal signs the admin out. Serialised, the second tab's POST leaves after the first's answer
 * has set the rotated cookie, so it presents that one. Sign-out takes the lock too, so it never
 * revokes a cookie another tab is in the middle of rotating. A browser without Web Locks runs `fn`
 * unguarded; the site's `<authBase>/session` route is the other half of this guard.
 */
function withSessionLock<T>(fn: () => Promise<T>): Promise<T> {
  const locks = typeof navigator !== 'undefined' ? navigator.locks : undefined
  if (!locks) return fn()
  // lib.dom types `request` as resolving to the callback's return, here itself a promise; the
  // lock manager resolves with that promise's value.
  return locks.request(PRODUCT_ADMIN_SESSION_LOCK, fn) as unknown as Promise<T>
}

function requestSession(authBase: string): Promise<SessionAnswer> {
  const url = `${authBase}/session`
  const joined = sessionRequests.get(url)
  if (joined) return joined
  // Another base's request still out is waited for, so even without Web Locks no two
  // cookie-spending requests from this page overlap. With none out, nothing is awaited, so the
  // POST leaves during the mount that asked for it rather than a turn later: a StrictMode remount
  // in that turn finds it in the map and joins it instead of sending a second one.
  const others = [...sessionRequests.values()].map((p) => p.catch(() => undefined))
  const req = (async (): Promise<SessionAnswer> => {
    if (others.length > 0) await Promise.all(others)
    const res = await withSessionLock(() =>
      fetch(url, { method: 'POST', credentials: 'include' }),
    )
    if (res.status === 401) return null
    if (!res.ok) throw new Error(`HTTP ${res.status} from ${url}`)
    const body = (await res.json()) as { accessToken?: unknown; expiresAt?: unknown }
    if (typeof body.accessToken !== 'string' || !body.accessToken) {
      throw new Error(`${url} answered without an accessToken`)
    }
    return { accessToken: body.accessToken, expiresAt: body.expiresAt }
  })().finally(() => {
    if (sessionRequests.get(url) === req) sessionRequests.delete(url)
  })
  sessionRequests.set(url, req)
  return req
}

function currentPath(): string {
  if (typeof window === 'undefined') return '/'
  return `${window.location.pathname}${window.location.search}`
}

export function ProductAdminAuthProvider({ children, authBase: rawAuthBase, navigate }: ProductAdminAuthProviderProps): ReactElement {
  // Normalised once; every URL below is built from this. A string, so it is a stable dependency.
  const authBase = normalizeAuthBase(rawAuthBase)
  // `navigate` is read through a ref, never as a dependency: a host that passes an inline arrow
  // hands in a new function every render, and since every refresh re-renders (it adopts a
  // token), a dependency on it would re-run the mount effect and refresh again, forever.
  const navigateRef = useRef(navigate)
  useLayoutEffect(() => {
    navigateRef.current = navigate
  })
  const go = useCallback((url: string) => {
    const nav = navigateRef.current
    if (nav) nav(url)
    else window.location.assign(url)
  }, [])
  const [status, setStatus] = useState<ProductAdminAuthStatus>('loading')
  const [account, setAccount] = useState<ProductAdminAccount | null>(null)
  const [accessToken, setAccessToken] = useState<string | null>(null)
  // The token lives in a ref so the source's `read` is synchronous and always current; the state
  // copy above is only for consumers that render from it.
  const tokenRef = useRef<string | null>(null)
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const inFlightRef = useRef<Promise<string | null> | null>(null)
  // Bumped on every mount and unmount: an answer that lands for an older mount is dropped, so a
  // StrictMode remount or an unmount mid-request never adopts a token or navigates. The request
  // itself is shared across mounts (`requestSession`), so dropping an answer never costs a POST.
  const genRef = useRef(0)

  const adopt = useCallback((token: string | null) => {
    tokenRef.current = token
    setAccessToken(token)
    announceSessionChange()
  }, [])

  const refresh = useCallback((): Promise<string | null> => {
    if (inFlightRef.current) return inFlightRef.current
    const gen = genRef.current
    const run = (async (): Promise<string | null> => {
      const answer = await requestSession(authBase)
      if (gen !== genRef.current) return null
      if (!answer) {
        adopt(null)
        go(`${authBase}/signin?return=${encodeURIComponent(currentPath())}`)
        return null
      }
      adopt(answer.accessToken)
      const exp = expiryMs(answer.expiresAt, answer.accessToken)
      if (timerRef.current) clearTimeout(timerRef.current)
      timerRef.current = null
      if (exp !== null) {
        const wait = Math.max(exp - Date.now() - PRODUCT_ADMIN_REFRESH_LEAD_MS, MIN_REFRESH_DELAY_MS)
        timerRef.current = setTimeout(() => {
          void refresh().catch(() => undefined)
        }, wait)
      }
      return answer.accessToken
    })().finally(() => {
      if (inFlightRef.current === run) inFlightRef.current = null
    })
    inFlightRef.current = run
    return run
  }, [adopt, go, authBase])

  // A LAYOUT effect, so the token source is in place before any child's passive effect runs: React
  // runs a child's effects before its parent's, so from a plain effect a page's first queries went
  // out before the source existed, with no bearer, or with another session's token from storage.
  // With the source in, a query sent while the session loads carries no bearer, and its 401 joins
  // the refresh already in flight rather than starting one.
  useLayoutEffect(() => {
    genRef.current += 1
    inFlightRef.current = null
    const source: AccessTokenSource = { read: () => tokenRef.current, refresh }
    setAccessTokenSource(source)
    let cancelled = false
    void (async () => {
      try {
        const token = await refresh()
        if (!token || cancelled) return
        const me = toAccount(await authedJson<ProductAdminAccountWire>('/api/v1/account'))
        if (cancelled) return
        setAccount(me)
        setStatus(me.roles.includes('admin') ? 'ready' : 'no-access')
      } catch {
        // A session or account read that fails for any reason but a 401 leaves no usable session:
        // start the sign-in again rather than render a page that cannot load anything.
        if (!cancelled) go(`${authBase}/signin?return=${encodeURIComponent(currentPath())}`)
      }
    })()
    return () => {
      cancelled = true
      genRef.current += 1
      inFlightRef.current = null
      if (timerRef.current) clearTimeout(timerRef.current)
      timerRef.current = null
      if (accessTokenSource() === source) setAccessTokenSource(null)
    }
  }, [refresh, go, authBase])

  const signOut = useCallback(async () => {
    // A refresh already out (the timer's, or a 401 retry's) must not land after sign-out and bring
    // the bearer and its timer back: a new generation drops its answer.
    genRef.current += 1
    inFlightRef.current = null
    if (timerRef.current) clearTimeout(timerRef.current)
    timerRef.current = null
    try {
      // Let that refresh finish at the server first, so <authBase>/signout revokes the refresh
      // cookie it rotated to rather than the one it spent.
      await sessionRequests.get(`${authBase}/session`)?.catch(() => undefined)
      await withSessionLock(() => fetch(`${authBase}/signout`, { method: 'POST', credentials: 'include' }))
    } finally {
      adopt(null)
      setAccount(null)
      go(`${authBase}/signin`)
    }
  }, [adopt, go, authBase])

  const stepUp = useCallback(
    (returnPath?: string) => go(stepUpSigninUrl(authBase, returnPath ?? currentPath())),
    [go, authBase],
  )

  const value = useMemo<ProductAdminAuthValue>(
    () => ({ status, account, accessToken, signOut, stepUp }),
    [status, account, accessToken, signOut, stepUp],
  )
  return <ProductAdminAuthContext.Provider value={value}>{children}</ProductAdminAuthContext.Provider>
}

/** The product admin session. Throws outside a {@link ProductAdminAuthProvider}. */
export function useProductAdminAuth(): ProductAdminAuthValue {
  const v = useContext(ProductAdminAuthContext)
  if (!v) throw new Error('useProductAdminAuth must be used inside a ProductAdminAuthProvider')
  return v
}

/** The product admin session, or null outside a {@link ProductAdminAuthProvider}: for a pane that
 *  also mounts on a site without one (it then takes its step-up from a prop instead). */
export function useOptionalProductAdminAuth(): ProductAdminAuthValue | null {
  return useContext(ProductAdminAuthContext)
}
