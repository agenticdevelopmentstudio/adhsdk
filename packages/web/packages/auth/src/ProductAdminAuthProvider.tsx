'use client'

// The session for a PRODUCT ADMIN SITE (phase 6): a product's own admins, signed in with the
// product's customer login, managing that product at its own host.
//
// It is not AuthProvider. The site's refresh token is an HttpOnly cookie (`pa_refresh`) on the
// site's own origin, set and rotated by the site's `/auth/*` route handlers, and the access token
// is held here, in memory, never in storage or a URL. On mount it asks `POST /auth/session` for an
// access token; a 401 there means no session, and the browser goes to `/auth/signin?return=<path>`.
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
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
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
}

export interface ProductAdminAuthProviderProps {
  children: ReactNode
  /** Where the browser goes; a seam for tests. Defaults to `window.location.assign`. */
  navigate?: (url: string) => void
}

/** How long before `exp` the token is refreshed. */
export const PRODUCT_ADMIN_REFRESH_LEAD_MS = 60_000
/** The shortest wait between refreshes, so a token that is already near expiry cannot spin. */
const MIN_REFRESH_DELAY_MS = 5_000

const ProductAdminAuthContext = createContext<ProductAdminAuthValue | null>(null)

/** The `/auth/session` answer's `expiresAt` in ms: unix seconds, unix ms or ISO 8601; else the
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

/** A session from `POST /auth/session`; null is its 401, no session. */
type SessionAnswer = { accessToken: string; expiresAt: unknown } | null

// The one `POST /auth/session` in flight in this page, shared by every caller until it answers.
// It lives at module scope, not in a mount, because the site's `/auth/*` handlers ROTATE the
// refresh cookie: a second POST sent before the first answers presents a cookie that has just
// been spent, and the server takes that as a lost session. A StrictMode remount, or an unmount
// and a new provider while a request is out, therefore joins this request; each mount decides for
// itself (by its generation) whether to adopt what comes back.
let sessionRequest: Promise<SessionAnswer> | null = null

function requestSession(): Promise<SessionAnswer> {
  if (sessionRequest) return sessionRequest
  const req = (async (): Promise<SessionAnswer> => {
    const res = await fetch('/auth/session', { method: 'POST', credentials: 'include' })
    if (res.status === 401) return null
    if (!res.ok) throw new Error(`HTTP ${res.status} from /auth/session`)
    const body = (await res.json()) as { accessToken?: unknown; expiresAt?: unknown }
    if (typeof body.accessToken !== 'string' || !body.accessToken) {
      throw new Error('/auth/session answered without an accessToken')
    }
    return { accessToken: body.accessToken, expiresAt: body.expiresAt }
  })().finally(() => {
    if (sessionRequest === req) sessionRequest = null
  })
  sessionRequest = req
  return req
}

function currentPath(): string {
  if (typeof window === 'undefined') return '/'
  return `${window.location.pathname}${window.location.search}`
}

export function ProductAdminAuthProvider({ children, navigate }: ProductAdminAuthProviderProps) {
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
      const answer = await requestSession()
      if (gen !== genRef.current) return null
      if (!answer) {
        adopt(null)
        go(`/auth/signin?return=${encodeURIComponent(currentPath())}`)
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
  }, [adopt, go])

  useEffect(() => {
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
        if (!cancelled) go(`/auth/signin?return=${encodeURIComponent(currentPath())}`)
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
  }, [refresh, go])

  const signOut = useCallback(async () => {
    if (timerRef.current) clearTimeout(timerRef.current)
    timerRef.current = null
    try {
      await fetch('/auth/signout', { method: 'POST', credentials: 'include' })
    } finally {
      adopt(null)
      setAccount(null)
      go('/auth/signin')
    }
  }, [adopt, go])

  const value = useMemo<ProductAdminAuthValue>(
    () => ({ status, account, accessToken, signOut }),
    [status, account, accessToken, signOut],
  )
  return <ProductAdminAuthContext.Provider value={value}>{children}</ProductAdminAuthContext.Provider>
}

/** The product admin session. Throws outside a {@link ProductAdminAuthProvider}. */
export function useProductAdminAuth(): ProductAdminAuthValue {
  const v = useContext(ProductAdminAuthContext)
  if (!v) throw new Error('useProductAdminAuth must be used inside a ProductAdminAuthProvider')
  return v
}
