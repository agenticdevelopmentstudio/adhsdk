import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

vi.mock('@simplewebauthn/browser', () => ({
  startAuthentication: vi.fn(async () => ({ id: 'cred' })),
  startRegistration: vi.fn(async () => ({ id: 'reg' })),
}))

import { configureAuth, authConfig } from '../config'
import { asEndpoint, authApiBaseOrEnv } from '../asBase'
import { hasCapability, isAdmin, type AuthTokens, type AuthUser } from '../types'
import {
  clearTokens,
  decodeBase64UrlJson,
  onSessionChange,
  readAccessToken,
  readTokens,
  readTokenSubject,
  readUser,
  tokensFromResponse,
  writeTokens,
  writeUser,
} from '../tokens'
import { invalidateRefresh, refreshAccessToken } from '../refresh'
import {
  AuthHttpError,
  authedFetch,
  authedJson,
  authedRequest,
  exchangeSsoCode,
  extractErrorCode,
  extractErrorMessage,
  linkProvider,
  readErrorMessage,
  setAuthRetryMarker,
} from '../client'
import {
  assertPasswordlessPasskey,
  assertSecondFactor,
  completeLoginCode,
  completeLoginPasskey,
  passwordlessPasskeyLogin,
  requestLoginSms,
} from '../mfa'
import {
  beginLinkProvider,
  beginLogin,
  beginSilentLogin,
  centralCompleteMfaCode,
  centralCompleteMfaPasskey,
  centralEmailLogin,
  centralLoginTarget,
  centralPasswordlessPasskey,
  centralSendMfaSms,
  currentReturnTo,
  markSsoChecked,
  parseInboundSso,
  preflightSsoReturn,
  providerSigninUrl,
  readCentralParams,
  shouldSilentRestore,
  ssoHintPresent,
  ssoLogout,
  ssoSwitchUrl,
  stashReturnTo,
  stripSsoFragment,
  takeReturnTo,
} from '../sso'
import {
  confirmTotp,
  enrollTotp,
  getMfaStatus,
  listWebauthn,
  regenerateRecoveryCodes,
  registerWebauthn,
  removeTotp,
  removeWebauthn,
  setPreferredMethod,
} from '../account-security'
import {
  linkConfirmTitle,
  oauthErrorMessage,
  providerLabel,
} from '../labels'
import { reportAuthError, reportUnexpectedAuthError, setAuthErrorReporter } from '../report'

const AS = 'https://api.example.com'

function res(status: number, body?: unknown): Response {
  return new Response(body === undefined ? null : JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

let fetchMock: ReturnType<typeof vi.fn>
/** Queue the responses the stubbed global fetch answers with, in order. */
function queueFetch(...responses: Array<Response | Error>): void {
  for (const r of responses) {
    if (r instanceof Error) fetchMock.mockRejectedValueOnce(r)
    else fetchMock.mockResolvedValueOnce(r)
  }
}
function call(n: number): [string, RequestInit] {
  const c = fetchMock.mock.calls[n]
  if (!c) throw new Error(`fetch call ${n} never happened`)
  return [c[0] as string, (c[1] ?? {}) as RequestInit]
}
function bodyOf(n: number): unknown {
  return JSON.parse(call(n)[1].body as string)
}
function headerOf(n: number, name: string): string | undefined {
  const h = (call(n)[1].headers ?? {}) as Record<string, string>
  return h[name]
}

let savedLocation: PropertyDescriptor | undefined
function stubLocation(
  origin: string,
  extra: { pathname?: string; search?: string; hash?: string } = {},
): { href: string } {
  const loc = {
    origin,
    hostname: new URL(origin).hostname,
    pathname: extra.pathname ?? '/dashboard',
    search: extra.search ?? '',
    hash: extra.hash ?? '',
    href: '',
  }
  Object.defineProperty(window, 'location', { configurable: true, value: loc })
  return loc
}

function setHint(present: boolean): void {
  document.cookie = present
    ? 'adh_sso_hint=1'
    : 'adh_sso_hint=; expires=Thu, 01 Jan 1970 00:00:00 GMT'
}

function b64url(text: string): string {
  return Buffer.from(text, 'utf8').toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

beforeEach(() => {
  savedLocation = Object.getOwnPropertyDescriptor(window, 'location')
  localStorage.clear()
  window.sessionStorage.clear()
  setHint(false)
  configureAuth({ storageKey: 'test_tokens', refreshPath: '/api/v1/auth/sessions/refresh' })
  invalidateRefresh()
  delete process.env.NEXT_PUBLIC_AUTH_API_URL
  fetchMock = vi.fn()
  vi.stubGlobal('fetch', fetchMock)
  vi.spyOn(console, 'error').mockImplementation(() => {})
})

afterEach(() => {
  vi.unstubAllGlobals()
  if (savedLocation) Object.defineProperty(window, 'location', savedLocation)
  setAuthErrorReporter(null)
  setAuthRetryMarker(null)
  vi.useRealTimers()
  vi.unstubAllGlobals()
  vi.restoreAllMocks()
  setHint(false)
})

describe('auth-client conformance: configuration and shapes', () => {
  it('auth-client-001 default runtime config', async () => {
    vi.resetModules()
    const fresh = await import('../config')
    expect(fresh.authConfig()).toEqual({
      storageKey: 'auth_tokens',
      refreshPath: '/api/v1/auth/sessions/refresh',
    })
  })

  it('auth-client-002 configureAuth merges a partial', () => {
    configureAuth({ storageKey: 'x' })
    expect(authConfig().storageKey).toBe('x')
    expect(authConfig().refreshPath).toBe('/api/v1/auth/sessions/refresh')
  })

  it('auth-client-003 AS base resolution strips the trailing slash', () => {
    expect(authApiBaseOrEnv('https://x.example.com/')).toBe('https://x.example.com')
  })

  it('auth-client-004 AS endpoint falls back to the /api proxy with no base', () => {
    expect(asEndpoint('/a')).toBe('/api/a')
  })

  it('auth-client-005 token bundle holds exactly accessToken and refreshToken', () => {
    const bundle: AuthTokens = { accessToken: 'a', refreshToken: 'b' }
    writeTokens(bundle)
    expect(readTokens()).toEqual({ accessToken: 'a', refreshToken: 'b' })
    expect(Object.keys(readTokens() as object).sort()).toEqual(['accessToken', 'refreshToken'])
  })

  it('auth-client-006 a user record omitting slug is valid', () => {
    const user: AuthUser = {
      id: 'u1',
      email: 'e@x.com',
      name: 'N',
      avatarUrl: '',
      capabilities: [],
      authMethods: [],
      attributes: [],
    }
    writeUser(user)
    expect(readUser()).toEqual(user)
  })

  it('auth-client-007 hasCapability is null-safe', () => {
    expect(hasCapability(null, 'billing')).toBe(false)
    expect(hasCapability(undefined, 'billing')).toBe(false)
  })

  it('auth-client-008 isAdmin is derived from capabilities', () => {
    expect(isAdmin({ capabilities: ['user', 'admin'] })).toBe(true)
    expect(isAdmin({ capabilities: ['user'] })).toBe(false)
  })
})

describe('auth-client conformance: tokens', () => {
  it('auth-client-009 token wins over accessToken (/v1 spelling first)', () => {
    expect(tokensFromResponse({ accessToken: 'A', token: 'T' })).toEqual({ accessToken: 'T', refreshToken: '' })
  })

  it('auth-client-010 refreshToken is blanked even when the body carries one', () => {
    const body = { token: 'T', refreshToken: 'server-rt' } as Parameters<typeof tokensFromResponse>[0]
    expect(tokensFromResponse(body).refreshToken).toBe('')
  })

  it('auth-client-011 throws when no token is present', () => {
    expect(() => tokensFromResponse({})).toThrow(/missing token/i)
  })

  it('auth-client-012 storage key is configurable', () => {
    configureAuth({ storageKey: 'other_key' })
    writeTokens({ accessToken: 'A', refreshToken: '' })
    expect(localStorage.getItem('other_key')).not.toBeNull()
    expect(localStorage.getItem('auth_tokens')).toBeNull()
  })

  it('auth-client-013 reading off-browser returns null', () => {
    vi.stubGlobal('window', undefined)
    expect(readTokens()).toBeNull()
  })

  it('auth-client-014 malformed JSON in storage reads as null', () => {
    localStorage.setItem('test_tokens', 'not json')
    expect(readTokens()).toBeNull()
  })

  it('auth-client-015 writeTokens persists and announces exactly once', () => {
    const fn = vi.fn()
    const off = onSessionChange(fn)
    writeTokens({ accessToken: 'A', refreshToken: '' })
    off()
    expect(fn).toHaveBeenCalledTimes(1)
    expect(localStorage.getItem('test_tokens')).toContain('"accessToken":"A"')
  })

  it('auth-client-016 clearTokens also clears the sibling user key', () => {
    writeTokens({ accessToken: 'A', refreshToken: '' })
    writeUser({ id: 'u', email: '', name: '', avatarUrl: '', capabilities: [], authMethods: [], attributes: [] })
    clearTokens()
    expect(readUser()).toBeNull()
    expect(localStorage.getItem('test_tokens')).toBeNull()
  })

  it('auth-client-017 readAccessToken derives from the stored bundle', () => {
    writeTokens({ accessToken: 'A', refreshToken: '' })
    expect(readAccessToken()).toBe('A')
  })

  it('auth-client-018 an unsubscribed listener is not called', () => {
    const fn = vi.fn()
    const off = onSessionChange(fn)
    off()
    writeTokens({ accessToken: 'A', refreshToken: '' })
    expect(fn).not.toHaveBeenCalled()
  })

  it('auth-client-019 listeners are called with zero arguments', () => {
    const fn = vi.fn()
    const off = onSessionChange(fn)
    writeTokens({ accessToken: 'A', refreshToken: '' })
    off()
    expect(fn.mock.calls[0]).toEqual([])
  })

  it('auth-client-020 announcement iterates a snapshot of the listeners', () => {
    const b = vi.fn()
    let offB = () => {}
    const a = vi.fn(() => offB())
    const offA = onSessionChange(a)
    offB = onSessionChange(b)
    writeTokens({ accessToken: 'A', refreshToken: '' })
    offA()
    expect(a).toHaveBeenCalledTimes(1)
    expect(b).toHaveBeenCalledTimes(1)
  })

  it('auth-client-021 base64url JSON decoding is UTF-8 correct', () => {
    expect(decodeBase64UrlJson(b64url(JSON.stringify({ name: '東京' })))).toEqual({ name: '東京' })
  })

  it('auth-client-022 decoding tolerates missing padding', () => {
    const seg = b64url(JSON.stringify({ sub: 'u', iat: 1 }))
    expect(seg.endsWith('=')).toBe(false)
    expect(decodeBase64UrlJson(seg)).toEqual({ sub: 'u', iat: 1 })
  })

  it('auth-client-023 decoding an invalid byte sequence returns null without throwing', () => {
    const invalid = Buffer.from([0xff, 0xfe, 0xfd]).toString('base64url')
    expect(decodeBase64UrlJson(invalid)).toBeNull()
  })

  it('auth-client-024 readTokenSubject returns the sub claim', () => {
    writeTokens({ accessToken: `h.${b64url(JSON.stringify({ sub: 'user-1' }))}.s`, refreshToken: '' })
    expect(readTokenSubject()).toBe('user-1')
  })

  it('auth-client-025 readUser rejects a wrongly shaped blob', () => {
    localStorage.setItem('test_tokens:user', '{"name":"x"}')
    expect(readUser()).toBeNull()
  })

  it('auth-client-026 writeUser off-browser is a no-op', () => {
    const store = window.localStorage
    const spy = vi.spyOn(store, 'setItem')
    vi.stubGlobal('window', undefined)
    expect(() =>
      writeUser({ id: 'u', email: '', name: '', avatarUrl: '', capabilities: [], authMethods: [], attributes: [] }),
    ).not.toThrow()
    expect(spy).not.toHaveBeenCalled()
  })
})

describe('auth-client conformance: refresh', () => {
  it('auth-client-027 concurrent refreshes share one request', async () => {
    queueFetch(res(200, { token: 'NEW' }))
    const [a, b] = await Promise.all([refreshAccessToken(), refreshAccessToken()])
    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect([a, b]).toEqual(['NEW', 'NEW'])
  })

  it('auth-client-028 refresh request shape', async () => {
    queueFetch(res(200, { token: 'NEW' }))
    await refreshAccessToken()
    const [url, init] = call(0)
    expect(url).toBe('/api/v1/auth/sessions/refresh')
    expect(init.method).toBe('POST')
    expect(init.credentials).toBe('include')
    expect(init.body).toBe('{}')
  })

  it('auth-client-029 invalidateRefresh makes the next call start a fresh attempt', async () => {
    fetchMock.mockImplementation(() => new Promise(() => {}))
    const first = refreshAccessToken()
    invalidateRefresh()
    const second = refreshAccessToken()
    expect(second).not.toBe(first)
    expect(fetchMock).toHaveBeenCalledTimes(2)
  })

  it('auth-client-030 a refresh invalidated mid-flight discards its result', async () => {
    let resolve!: (r: Response) => void
    fetchMock.mockImplementationOnce(() => new Promise<Response>((r) => (resolve = r)))
    const p = refreshAccessToken()
    invalidateRefresh()
    resolve(res(200, { token: 'N' }))
    expect(await p).toBeNull()
    expect(readTokens()).toBeNull()
  })

  it('auth-client-031 a logout during refresh is not resurrected', async () => {
    writeTokens({ accessToken: 'OLD', refreshToken: '' })
    let resolve!: (r: Response) => void
    fetchMock.mockImplementationOnce(() => new Promise<Response>((r) => (resolve = r)))
    const p = refreshAccessToken()
    clearTokens()
    resolve(res(200, { token: 'MINE' }))
    expect(await p).toBeNull()
    expect(readTokens()).toBeNull()
  })

  it('auth-client-032 a concurrent winner is adopted over this attempt', async () => {
    let resolve!: (r: Response) => void
    fetchMock.mockImplementationOnce(() => new Promise<Response>((r) => (resolve = r)))
    const p = refreshAccessToken()
    writeTokens({ accessToken: 'WINNER', refreshToken: '' })
    resolve(res(200, { token: 'MINE' }))
    expect(await p).toBe('WINNER')
    expect(readAccessToken()).toBe('WINNER')
  })

  it('auth-client-033 on a non-OK response a different stored token is adopted without clearing', async () => {
    writeTokens({ accessToken: 'OLD', refreshToken: '' })
    fetchMock.mockImplementationOnce(async () => {
      writeTokens({ accessToken: 'WINNER', refreshToken: '' })
      return res(401, {})
    })
    expect(await refreshAccessToken()).toBe('WINNER')
    expect(readAccessToken()).toBe('WINNER')
  })

  it('auth-client-034 a winner landing during the 300ms wait is adopted', async () => {
    vi.useFakeTimers()
    queueFetch(res(401, {}))
    const p = refreshAccessToken()
    await vi.advanceTimersByTimeAsync(0)
    writeTokens({ accessToken: 'WINNER', refreshToken: '' })
    await vi.advanceTimersByTimeAsync(300)
    expect(await p).toBe('WINNER')
  })

  it('auth-client-035 with no winner the session is cleared after the wait', async () => {
    vi.useFakeTimers()
    writeTokens({ accessToken: 'OLD', refreshToken: '' })
    queueFetch(res(401, {}))
    const p = refreshAccessToken()
    await vi.advanceTimersByTimeAsync(300)
    expect(await p).toBeNull()
    expect(readTokens()).toBeNull()
  })

  it('auth-client-036 a network error is reported unconditionally and clears tokens', async () => {
    const sink = vi.fn()
    setAuthErrorReporter(sink)
    writeTokens({ accessToken: 'OLD', refreshToken: '' })
    const err = new TypeError('network down')
    queueFetch(err)
    expect(await refreshAccessToken()).toBeNull()
    expect(sink).toHaveBeenCalledWith(err, { feature: 'auth', step: 'tokenRefresh' })
    expect(readTokens()).toBeNull()
  })
})

describe('auth-client conformance: authed requests', () => {
  it('auth-client-037 attaches the bearer token', async () => {
    writeTokens({ accessToken: 'TOK', refreshToken: '' })
    queueFetch(res(200, {}))
    await authedFetch('/api/x')
    expect(headerOf(0, 'Authorization')).toBe('Bearer TOK')
  })

  it('auth-client-038 defaults Content-Type to application/json when a body is sent', async () => {
    queueFetch(res(200, {}))
    await authedJson('/api/x', { method: 'POST', body: JSON.stringify({}) })
    expect(headerOf(0, 'Content-Type')).toBe('application/json')
  })

  it('auth-client-039 authedFetch needs no options argument', async () => {
    queueFetch(res(200, {}))
    await expect(authedFetch('/api/x')).resolves.toBeInstanceOf(Response)
  })

  it('auth-client-040 a 401 refreshes once and retries with the new token', async () => {
    writeTokens({ accessToken: 'OLD', refreshToken: '' })
    queueFetch(res(401, {}), res(200, { token: 'NEW' }), res(200, { ok: true }))
    await authedFetch('/api/x')
    expect(fetchMock).toHaveBeenCalledTimes(3)
    expect(headerOf(2, 'Authorization')).toBe('Bearer NEW')
  })

  it('auth-client-041 a non-OK response throws an AuthHttpError with the body message', async () => {
    queueFetch(res(500, { error: 'boom' }))
    const err = await authedFetch('/api/x').catch((e: unknown) => e)
    expect(err).toBeInstanceOf(AuthHttpError)
    expect((err as AuthHttpError).message).toBe('boom')
    expect((err as AuthHttpError).status).toBe(500)
  })

  it('auth-client-042 authedJson rejects a 204', async () => {
    queueFetch(res(204))
    await expect(authedJson('/api/x')).rejects.toThrow(/Unexpected empty response/)
  })

  it('auth-client-043 authedRequest discards the body', async () => {
    queueFetch(res(200, { deleted: true }))
    await expect(authedRequest('/api/x', { method: 'DELETE' })).resolves.toBeUndefined()
  })

  it('auth-client-044 AuthHttpError shape', () => {
    const err = new AuthHttpError(409, 'conflict', 'ALREADY_LINKED')
    expect(err.status).toBe(409)
    expect(err.code).toBe('ALREADY_LINKED')
    expect(err.name).toBe('AuthHttpError')
    expect(err).toBeInstanceOf(Error)
  })

  it('auth-client-045 error message precedence', () => {
    expect(extractErrorMessage({ error: 'E' }, 'fb')).toBe('E')
    expect(extractErrorMessage({ message: 'M' }, 'fb')).toBe('M')
    expect(extractErrorMessage({ title: 'T' }, 'fb')).toBe('T')
    expect(extractErrorMessage({}, 'fb')).toBe('fb')
  })

  it('auth-client-046 RFC 9457 detail wins over title', () => {
    expect(
      extractErrorMessage({ title: 'Bad Request', status: 400, detail: 'no GitHub App is configured' }, 'fb'),
    ).toBe('no GitHub App is configured')
  })

  it('auth-client-047 error code precedence', () => {
    expect(extractErrorCode({ error: { code: 'X' } })).toBe('X')
    expect(extractErrorCode({})).toBeUndefined()
  })

  it('auth-client-048 readErrorMessage parses the body once', async () => {
    const json = vi.fn().mockResolvedValueOnce({ message: 'M' })
    const response = { json } as unknown as Response
    expect(await readErrorMessage(response, 'fb')).toBe('M')
    expect(json).toHaveBeenCalledTimes(1)
  })
})

describe('auth-client conformance: SSO code exchange and provider link', () => {
  it('auth-client-049 exchange request shape', async () => {
    queueFetch(res(200, { token: 'A', user: { id: 'u1' } }))
    await exchangeSsoCode('code-1')
    const [url, init] = call(0)
    expect(url).toBe('/api/oauth/signin/exchange')
    expect(init.method).toBe('POST')
    expect(init.body).toBe('{"code":"code-1"}')
  })

  it('auth-client-050 a network failure is retried once', async () => {
    vi.useFakeTimers()
    queueFetch(new TypeError('net'), res(200, { token: 'A', user: { id: 'u1' } }))
    const p = exchangeSsoCode('code-1')
    await vi.advanceTimersByTimeAsync(750)
    await expect(p).resolves.toMatchObject({ tokens: { accessToken: 'A' } })
    expect(fetchMock).toHaveBeenCalledTimes(2)
  })

  it('auth-client-051 an HTTP error is never retried', async () => {
    queueFetch(res(401, { error: 'x' }))
    await expect(exchangeSsoCode('code-1')).rejects.toBeInstanceOf(AuthHttpError)
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })

  it('auth-client-052 success result', async () => {
    queueFetch(res(200, { token: 'A', user: { id: 'u1' } }))
    expect(await exchangeSsoCode('code-1')).toEqual({
      tokens: { accessToken: 'A', refreshToken: '' },
      user: { id: 'u1' },
    })
  })

  it('auth-client-053 failure throws a typed error with the server message', async () => {
    queueFetch(res(401, { error: { message: 'invalid or expired exchange code' } }))
    const err = await exchangeSsoCode('bad').catch((e: unknown) => e)
    expect(err).toBeInstanceOf(AuthHttpError)
    expect((err as Error).message).toBe('invalid or expired exchange code')
  })

  it('auth-client-054 linkProvider routes to the AS host login_methods endpoint', async () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.example.com'
    queueFetch(res(200, {}))
    await linkProvider({ clientSlug: 'c', providerSlug: 'github', code: 'k', redirectUri: 'r' })
    expect(call(0)[0]).toBe('https://api.example.com/v1/account/login_methods')
  })

  it('auth-client-055 linkProvider is an authed POST with the snake_case wire body', async () => {
    writeTokens({ accessToken: 'at', refreshToken: '' })
    queueFetch(res(200, {}))
    await linkProvider({ clientSlug: 'c', providerSlug: 'github', code: 'k', redirectUri: 'r' })
    expect(headerOf(0, 'Authorization')).toBe('Bearer at')
    expect(call(0)[1].method).toBe('POST')
    expect(bodyOf(0)).toEqual({
      type: 'provider',
      client_slug: 'c',
      provider_slug: 'github',
      code: 'k',
      redirect_uri: 'r',
    })
  })

  it('auth-client-056 the retry marker is called once with the retried request options', async () => {
    const marker = vi.fn()
    setAuthRetryMarker(marker)
    writeTokens({ accessToken: 'OLD', refreshToken: '' })
    queueFetch(res(401, {}), res(200, { token: 'NEW' }), res(200, {}))
    await authedFetch('/api/x')
    expect(marker).toHaveBeenCalledTimes(1)
    expect(marker.mock.calls[0]![0]).toBe(call(2)[1])
  })
})

describe('auth-client conformance: password and MFA login', () => {
  it('auth-client-057 a failed options request throws using the fallback message', async () => {
    queueFetch(res(400, {}))
    await expect(assertSecondFactor('tok', '/api/options')).rejects.toThrow('Could not start the passkey check.')
  })

  it('auth-client-058 second-factor assertion options body', async () => {
    queueFetch(res(200, { options: {}, token: 't2' }))
    const out = await assertSecondFactor('tok', '/api/options')
    expect(bodyOf(0)).toEqual({ method: 'mfa_passkey', token: 'tok' })
    expect(out).toEqual({ token: 't2', response: { id: 'cred' } })
  })

  it('auth-client-059 passwordless assertion options body', async () => {
    queueFetch(res(200, { options: {}, token: 't2' }))
    await assertPasswordlessPasskey('id', '/api/options')
    expect(bodyOf(0)).toEqual({ method: 'passkey', identifier: 'id' })
  })

  it('auth-client-060 requestLoginSms', async () => {
    queueFetch(res(200, {}))
    await requestLoginSms('tok')
    const [url, init] = call(0)
    expect(url).toBe('/api/v1/auth/sms_codes')
    expect(init.method).toBe('POST')
    expect(bodyOf(0)).toEqual({ token: 'tok' })
  })

  it('auth-client-061 completeLoginCode posts to the sessions endpoint and maps the session', async () => {
    queueFetch(res(200, { token: 'T', user: { id: 'u', email: 'e', name: 'n' } }))
    const out = await completeLoginCode('tok', 'totp', '123456')
    expect(call(0)[0]).toBe('/api/v1/auth/sessions')
    expect(bodyOf(0)).toEqual({ token: 'tok', method: 'totp', code: '123456' })
    expect(out.token).toBe('T')
    expect(out.user.id).toBe('u')
  })

  it('auth-client-062 completeLoginPasskey', async () => {
    queueFetch(res(200, { options: {}, token: 't2' }), res(200, { token: 'T', user: { id: 'u', email: '', name: '' } }))
    await completeLoginPasskey('tok')
    expect(call(0)[0]).toBe('/api/v1/auth/passkey_challenges')
    expect(call(1)[0]).toBe('/api/v1/auth/sessions')
    expect(bodyOf(1)).toEqual({ method: 'mfa_passkey', token: 't2', response: { id: 'cred' } })
  })

  it('auth-client-063 passwordlessPasskeyLogin', async () => {
    queueFetch(res(200, { options: {}, token: 't2' }), res(200, { token: 'T', user: { id: 'u', email: '', name: '' } }))
    await passwordlessPasskeyLogin('id')
    expect(call(1)[0]).toBe('/api/v1/auth/sessions')
    expect(bodyOf(1)).toEqual({ method: 'passkey', token: 't2', response: { id: 'cred' } })
  })
})

describe('auth-client conformance: SSO navigation and silent restore', () => {
  it('auth-client-064 beginLogin navigates to the AS authorize endpoint', () => {
    const loc = stubLocation('https://cookbook.example.com')
    beginLogin({ clientId: 'cookbook', authApiBase: 'https://api.hub.example.com' })
    const url = new URL(loc.href)
    expect(url.origin).toBe('https://api.hub.example.com')
    expect(url.pathname).toBe('/oauth/signin/authorize')
    expect(url.searchParams.get('clientId')).toBe('cookbook')
    expect(url.searchParams.get('return')).toBe('https://cookbook.example.com/auth/callback')
  })

  it('auth-client-065 authorize URL shape (built through ssoSwitchUrl)', () => {
    const url = new URL(ssoSwitchUrl('r', { clientId: 'adh', authApiBase: AS }))
    expect(url.pathname).toBe('/oauth/signin/authorize')
    expect(url.searchParams.get('clientId')).toBe('adh')
    expect(url.searchParams.get('return')).toBe('r')
    expect(url.searchParams.get('prompt')).toBe('none')
  })

  it('auth-client-066 provider sign-in URL shape', () => {
    const url = new URL(providerSigninUrl({ clientId: 'adh', providerId: 'github', returnUrl: 'r', authApiBase: AS }))
    expect(url.pathname).toBe('/oauth/signin/start')
    expect(url.searchParams.get('clientId')).toBe('adh')
    expect(url.searchParams.get('providerId')).toBe('github')
    expect(url.searchParams.get('return')).toBe('r')
  })

  it('auth-client-067 the SSO hint cookie is detected', () => {
    expect(ssoHintPresent()).toBe(false)
    setHint(true)
    expect(ssoHintPresent()).toBe(true)
  })

  it('auth-client-068 marking the once-per-tab guard tolerates storage failure', () => {
    vi.spyOn(window.sessionStorage, 'setItem').mockImplementation(() => {
      throw new Error('blocked')
    })
    expect(() => markSsoChecked()).not.toThrow()
  })

  it('auth-client-069 an inbound #code fragment blocks a silent restore regardless of hint', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = AS
    stubLocation('https://cookbook.com')
    setHint(true)
    expect(shouldSilentRestore('#code=abc')).toBe(false)
  })

  it('auth-client-070 no hint on a same-apex site means no silent restore', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = AS
    stubLocation('https://site.example.com')
    expect(shouldSilentRestore('')).toBe(false)
  })

  it('auth-client-071 a cross-apex site restores without a hint', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.agenticdeveloperhub.com'
    stubLocation('https://cookbook.com')
    expect(shouldSilentRestore('')).toBe(true)
  })

  it('auth-client-072 preflight allowed:true returns true', async () => {
    const fetchImpl = vi.fn(async () => res(200, { allowed: true })) as unknown as typeof fetch
    expect(await preflightSsoReturn({ clientId: 'adh', returnUrl: 'r', authApiBase: AS, fetchImpl })).toBe(true)
  })

  it('auth-client-073 a throwing preflight returns false', async () => {
    const fetchImpl = vi.fn(async () => {
      throw new Error('net')
    }) as unknown as typeof fetch
    expect(await preflightSsoReturn({ clientId: 'adh', returnUrl: 'r', authApiBase: AS, fetchImpl })).toBe(false)
  })

  it('auth-client-074 a preflight that never resolves times out to false after about 2000ms', async () => {
    const fetchImpl = ((_url: string, init?: RequestInit) =>
      new Promise((_resolve, reject) => {
        init?.signal?.addEventListener('abort', () => reject(init.signal?.reason))
      })) as unknown as typeof fetch
    const start = Date.now()
    const out = await preflightSsoReturn({ clientId: 'adh', returnUrl: 'r', authApiBase: AS, fetchImpl })
    expect(out).toBe(false)
    expect(Date.now() - start).toBeGreaterThanOrEqual(1900)
  }, 8000)

  it('auth-client-075 silent login without an AS base returns false, marks the guard, and does not navigate', async () => {
    const loc = stubLocation('https://site.example.com')
    expect(await beginSilentLogin()).toBe(false)
    expect(window.sessionStorage.getItem('adh_sso_checked')).toBe('1')
    expect(loc.href).toBe('')
  })

  it('auth-client-076 silent login with an AS base and an allowed preflight navigates with prompt=none', async () => {
    const loc = stubLocation('https://site.example.com')
    const fetchImpl = vi.fn(async () => res(200, { allowed: true })) as unknown as typeof fetch
    expect(await beginSilentLogin({ authApiBase: AS, fetchImpl })).toBe(true)
    const url = new URL(loc.href)
    expect(url.pathname).toBe('/oauth/signin/authorize')
    expect(url.searchParams.get('prompt')).toBe('none')
  })

  it('auth-client-077 parseInboundSso', () => {
    expect(parseInboundSso('#code=abc')).toEqual({ code: 'abc' })
    expect(parseInboundSso('#error=login_required')).toEqual({ error: 'login_required' })
    expect(parseInboundSso('')).toBeNull()
  })

  it('auth-client-078 stripSsoFragment preserves other keys', () => {
    expect(stripSsoFragment('#site-switch&code=abc')).toBe('#site-switch')
  })

  it('auth-client-079 ssoLogout navigates to the logout endpoint', () => {
    const loc = stubLocation('https://cookbook.example.com')
    ssoLogout({ clientId: 'cookbook', authApiBase: 'https://api.hub.example.com' })
    const url = new URL(loc.href)
    expect(url.pathname).toBe('/oauth/signin/logout')
    expect(url.searchParams.get('clientId')).toBe('cookbook')
    expect(url.searchParams.get('return')).toBe('https://cookbook.example.com/')
  })

  it('auth-client-080 ssoSwitchUrl returns the destination unchanged with no AS base', () => {
    expect(ssoSwitchUrl('https://site.example.com/home')).toBe('https://site.example.com/home')
  })

  it('auth-client-081 currentReturnTo', () => {
    stubLocation('https://site.example.com', { pathname: '/a', search: '?b=1', hash: '#c' })
    expect(currentReturnTo()).toBe('/a?b=1#c')
  })

  it('auth-client-082 a cross-origin stashed return-to is rejected and cleared', () => {
    stubLocation('https://site.example.com')
    window.sessionStorage.setItem('adh_sso_return_to', '//evil.com/x')
    expect(takeReturnTo()).toBeNull()
    expect(window.sessionStorage.getItem('adh_sso_return_to')).toBeNull()
  })

  it('auth-client-083 a same-origin absolute stashed return-to becomes a relative path', () => {
    stubLocation('https://site.example.com')
    window.sessionStorage.setItem('adh_sso_return_to', 'https://site.example.com/home?x=1#y')
    expect(takeReturnTo()).toBe('/home?x=1#y')
  })

  it('auth-client-084 the return-to stash is single use', () => {
    stubLocation('https://site.example.com')
    stashReturnTo('/home/x')
    expect(takeReturnTo()).toBe('/home/x')
    expect(takeReturnTo()).toBeNull()
  })

  it('auth-client-085 readCentralParams', () => {
    expect(readCentralParams('?return=https%3A%2F%2Fx.example.com%2Fcb')).toEqual({
      clientId: 'adh',
      returnUrl: 'https://x.example.com/cb',
    })
  })

  it('auth-client-086 readCentralParams without return is null', () => {
    expect(readCentralParams('?clientId=adh')).toBeNull()
  })

  it('auth-client-087 centralLoginTarget prefers the relayed params', () => {
    stubLocation('https://site.example.com', {
      search: '?return=https%3A%2F%2Frelayed.example.com%2Fcb&clientId=relayed',
    })
    expect(centralLoginTarget({ clientId: 'mine', authApiBase: AS })).toEqual({
      clientId: 'relayed',
      returnUrl: 'https://relayed.example.com/cb',
      authApiBase: AS,
    })
  })
})

describe('auth-client conformance: central login', () => {
  const target = { clientId: 'adh', returnUrl: 'https://site.example.com/auth/callback', authApiBase: AS }

  it('auth-client-088 central login refuses without an AS base before any request', async () => {
    await expect(
      centralEmailLogin({ clientId: 'adh', returnUrl: 'r', identifier: 'a@b.com', password: 'p' }),
    ).rejects.toThrow(/misconfigured/)
    expect(fetchMock).not.toHaveBeenCalled()
  })

  it('auth-client-089 a 202 returns the MFA challenge without navigating', async () => {
    const loc = stubLocation('https://site.example.com')
    const challenge = { mfaRequired: true, token: 't', methods: ['totp'] }
    queueFetch(res(202, challenge))
    expect(await centralEmailLogin({ ...target, identifier: 'a@b.com', password: 'p' })).toEqual(challenge)
    expect(loc.href).toBe('')
  })

  it('auth-client-090 a 200 navigates to redirectUrl and returns null', async () => {
    const loc = stubLocation('https://site.example.com')
    queueFetch(res(200, { redirectUrl: 'https://bitbag.example.com/auth/callback#code=abc' }))
    expect(await centralEmailLogin({ ...target, identifier: 'a@b.com', password: 'p' })).toBeNull()
    expect(loc.href).toBe('https://bitbag.example.com/auth/callback#code=abc')
  })

  it('auth-client-091 central login request shape', async () => {
    stubLocation('https://site.example.com')
    queueFetch(res(200, { redirectUrl: 'https://x.example.com/' }))
    await centralEmailLogin({ ...target, identifier: 'a@b.com', password: 'p' })
    expect(call(0)[1].credentials).toBe('include')
    expect(bodyOf(0)).toMatchObject({
      identifier: 'a@b.com',
      password: 'p',
      clientId: 'adh',
      return: 'https://site.example.com/auth/callback',
    })
  })

  it('auth-client-092 central email login posts to the AS login endpoint', async () => {
    stubLocation('https://site.example.com')
    queueFetch(res(200, { redirectUrl: 'https://x.example.com/' }))
    await centralEmailLogin({ identifier: 'a@b.com', password: 'p', clientId: 'adh', returnUrl: 'r', authApiBase: AS })
    const [url, init] = call(0)
    expect(url).toBe(`${AS}/oauth/signin/login`)
    expect(init.method).toBe('POST')
    expect(bodyOf(0)).toEqual({ identifier: 'a@b.com', password: 'p', clientId: 'adh', return: 'r' })
  })

  it('auth-client-093 central SMS send failure uses the fallback message', async () => {
    queueFetch(res(400, {}))
    const err = await centralSendMfaSms(target, 'tok').catch((e: unknown) => e)
    expect(err).toBeInstanceOf(AuthHttpError)
    expect((err as Error).message).toBe('Could not send a code.')
  })

  it('auth-client-094 central MFA code completion', async () => {
    stubLocation('https://site.example.com')
    queueFetch(res(200, { redirectUrl: 'https://x.example.com/' }))
    await centralCompleteMfaCode(target, 'tok', 'sms', '123456')
    expect(call(0)[0]).toBe(`${AS}/oauth/signin/login/mfa`)
    expect(bodyOf(0)).toMatchObject({ token: 'tok', method: 'sms', code: '123456' })
  })

  it('auth-client-095 central MFA passkey completion', async () => {
    stubLocation('https://site.example.com')
    queueFetch(res(200, { options: {}, token: 't2' }), res(200, { redirectUrl: 'https://x.example.com/' }))
    await centralCompleteMfaPasskey(target, 'tok')
    expect(call(0)[0]).toBe(`${AS}/v1/auth/passkey_challenges`)
    expect(call(1)[0]).toBe(`${AS}/oauth/signin/login/mfa/webauthn`)
    expect(bodyOf(1)).toMatchObject({ token: 't2', response: { id: 'cred' } })
  })

  it('auth-client-096 central passwordless passkey', async () => {
    stubLocation('https://site.example.com')
    queueFetch(res(200, { options: {}, token: 't2' }), res(200, { redirectUrl: 'https://x.example.com/' }))
    await centralPasswordlessPasskey(target, 'id')
    expect(call(0)[0]).toBe(`${AS}/v1/auth/passkey_challenges`)
    expect(call(1)[0]).toBe(`${AS}/oauth/signin/login/webauthn`)
  })

  it('auth-client-097 beginLinkProvider stashes a CSRF nonce that matches the query', () => {
    const loc = stubLocation('https://site.example.com')
    expect(beginLinkProvider({ providerId: 'github', returnTo: '/home', authApiBase: AS })).toBe(true)
    const url = new URL(loc.href)
    expect(url.pathname).toBe('/oauth/signin/start')
    expect(url.searchParams.get('link')).toBe('1')
    const nonce = url.searchParams.get('linkNonce')
    expect(nonce).toBeTruthy()
    expect(window.sessionStorage.getItem('adh_link_nonce')).toBe(nonce)
  })

  it('auth-client-098 beginLinkProvider returns false and does not navigate when the nonce cannot be stashed', () => {
    const loc = stubLocation('https://site.example.com')
    vi.spyOn(window.sessionStorage, 'setItem').mockImplementation(() => {
      throw new Error('blocked')
    })
    expect(beginLinkProvider({ providerId: 'github', returnTo: '/home', authApiBase: AS })).toBe(false)
    expect(loc.href).toBe('')
  })
})

describe('auth-client conformance: account security', () => {
  beforeEach(() => {
    writeTokens({ accessToken: 'at', refreshToken: '' })
  })

  it('auth-client-099 getMfaStatus', async () => {
    queueFetch(
      res(200, { sms: true, totp: false, webauthn: false, totp_pending: false, recovery_remaining: 3, preferred_method: 'sms' }),
    )
    expect(await getMfaStatus()).toEqual({
      sms: true,
      totp: false,
      webauthn: false,
      totpPending: false,
      recoveryRemaining: 3,
      preferredMethod: 'sms',
    })
    expect(call(0)[0]).toBe('/api/v1/account/mfa')
    expect(call(0)[1].method).toBeUndefined()
  })

  it('auth-client-100 enrollTotp', async () => {
    queueFetch(res(200, { secret: 's', otpauth_uri: 'otpauth://x' }))
    expect(await enrollTotp()).toEqual({ secret: 's', otpauthUri: 'otpauth://x' })
    expect(call(0)[0]).toBe('/api/v1/account/mfa/totp')
    expect(call(0)[1].method).toBe('POST')
  })

  it('auth-client-101 confirmTotp', async () => {
    queueFetch(res(200, {}))
    await confirmTotp('123456')
    expect(call(0)[0]).toBe('/api/v1/account/mfa/totp/confirm')
    expect(call(0)[1].method).toBe('POST')
    expect(call(0)[1].body).toBe('{"code":"123456"}')
  })

  it('auth-client-102 removeTotp', async () => {
    queueFetch(res(200, {}))
    await removeTotp()
    expect(call(0)[0]).toBe('/api/v1/account/mfa/totp')
    expect(call(0)[1].method).toBe('DELETE')
  })

  it('auth-client-103 listWebauthn', async () => {
    queueFetch(
      res(200, {
        object: 'list',
        has_more: false,
        url: '',
        data: [{ id: 'p1', name: 'Key', kind: 'passkey', created: 0 }],
      }),
    )
    expect(await listWebauthn()).toEqual({
      items: [{ id: 'p1', name: 'Key', kind: 'passkey', createdAt: '1970-01-01T00:00:00.000Z', lastUsedAt: null }],
    })
    expect(call(0)[0]).toMatch(/^\/api\/v1\/account\/mfa\/passkeys\?/)
  })

  it('auth-client-104 registerWebauthn runs options, ceremony, then verify', async () => {
    queueFetch(res(200, { options: {}, token: 'rt' }), res(200, {}))
    await registerWebauthn('passkey', 'My key')
    expect(call(0)[0]).toBe('/api/v1/account/mfa/passkeys/registration_options')
    expect(bodyOf(0)).toEqual({ kind: 'passkey' })
    expect(call(1)[0]).toBe('/api/v1/account/mfa/passkeys')
    expect(bodyOf(1)).toEqual({ token: 'rt', response: { id: 'reg' }, name: 'My key' })
  })

  it('auth-client-105 removeWebauthn percent-encodes the id', async () => {
    queueFetch(res(200, {}))
    await removeWebauthn('cred id/with slash')
    expect(call(0)[0]).toBe('/api/v1/account/mfa/passkeys/cred%20id%2Fwith%20slash')
    expect(call(0)[1].method).toBe('DELETE')
  })

  it('auth-client-106 regenerateRecoveryCodes', async () => {
    queueFetch(res(200, { codes: ['a', 'b'] }))
    expect(await regenerateRecoveryCodes()).toEqual({ codes: ['a', 'b'] })
    expect(call(0)[0]).toBe('/api/v1/account/mfa/recovery_codes/regenerate')
    expect(call(0)[1].method).toBe('POST')
  })

  it('auth-client-107 setPreferredMethod', async () => {
    queueFetch(res(200, { preferred_method: 'totp' }))
    expect(await setPreferredMethod('totp')).toEqual({ preferredMethod: 'totp' })
    expect(call(0)[0]).toBe('/api/v1/account/mfa')
    expect(call(0)[1].method).toBe('POST')
    expect(bodyOf(0)).toEqual({ preference: { method: 'totp' } })
  })

  it('auth-client-108 with no stored token the first request is unauthenticated and a 401 refreshes and retries', async () => {
    clearTokens()
    queueFetch(res(401, {}), res(200, { token: 'NEW' }), res(200, { sms: false, totp: false, webauthn: false }))
    await getMfaStatus()
    expect(headerOf(0, 'Authorization')).toBeUndefined()
    expect(fetchMock).toHaveBeenCalledTimes(3)
    expect(headerOf(2, 'Authorization')).toBe('Bearer NEW')
  })
})

describe('auth-client conformance: error reporting and labels', () => {
  it('auth-client-109 4xx errors never reach the console or sink', () => {
    const sink = vi.fn()
    setAuthErrorReporter(sink)
    reportUnexpectedAuthError(new AuthHttpError(401, 'unauthorized-109'))
    reportUnexpectedAuthError(Object.assign(new Error('forbidden-109'), { status: 403 }))
    expect(sink).not.toHaveBeenCalled()
    expect(console.error).not.toHaveBeenCalled()
  })

  it('auth-client-110 a 5xx reaches both the console and the sink', () => {
    const sink = vi.fn()
    setAuthErrorReporter(sink)
    reportUnexpectedAuthError(new AuthHttpError(503, 'unavailable-110'))
    expect(sink).toHaveBeenCalledTimes(1)
    expect(console.error).toHaveBeenCalledTimes(1)
  })

  it('auth-client-111 an identical report within 60000ms is deduplicated', () => {
    const sink = vi.fn()
    setAuthErrorReporter(sink)
    reportUnexpectedAuthError(new Error('dedupe-111'), { feature: 'x' })
    reportUnexpectedAuthError(new Error('dedupe-111'), { feature: 'x' })
    expect(sink).toHaveBeenCalledTimes(1)
    expect(console.error).toHaveBeenCalledTimes(1)
  })

  it('auth-client-112 reportAuthError is unconditional', () => {
    const sink = vi.fn()
    setAuthErrorReporter(sink)
    reportAuthError(new AuthHttpError(401, 'unconditional-112'))
    expect(sink).toHaveBeenCalledTimes(1)
    expect(console.error).toHaveBeenCalledTimes(1)
  })

  it('auth-client-113 a throwing reporter never breaks the caller', () => {
    setAuthErrorReporter(() => {
      throw new Error('sink down')
    })
    expect(() => reportUnexpectedAuthError(new Error('throwing-113'))).not.toThrow()
    expect(console.error).toHaveBeenCalledTimes(1)
  })

  it('auth-client-114 the registered sink receives the error and context', () => {
    const sink = vi.fn()
    setAuthErrorReporter(sink)
    const err = new Error('hook-114')
    reportUnexpectedAuthError(err, { feature: 'x' })
    expect(sink).toHaveBeenCalledWith(err, { feature: 'x' })
  })

  it('auth-client-115 provider labels', () => {
    expect(providerLabel('github')).toBe('GitHub')
    expect(providerLabel('google')).toBe('Google')
    expect(providerLabel('discord')).toBe('Discord')
  })

  it('auth-client-116 OAuth error messages with fallback', () => {
    expect(oauthErrorMessage('account_exists')).toBe(
      'An account already exists for this email — sign in with your email and password instead.',
    )
    expect(oauthErrorMessage('weird_code')).toBe('Sign-in failed (weird_code)')
  })

  it('auth-client-117 link-confirm title substitutes the provider label', () => {
    expect(linkConfirmTitle('github')).toBe('Add GitHub to your account?')
  })

  it.skip('auth-client-118 documents that no call site passes a token as error context (a static property of the call sites, not a runtime behavior)', () => {})

  it('auth-client-119 the refresh token is never persisted', () => {
    const body = { token: 'T', refreshToken: 'server-side-rt' } as Parameters<typeof tokensFromResponse>[0]
    writeTokens(tokensFromResponse(body))
    const stored = JSON.parse(localStorage.getItem('test_tokens') as string) as AuthTokens
    expect(stored.refreshToken).toBe('')
    expect(localStorage.getItem('test_tokens')).not.toContain('server-side-rt')
  })

  it('auth-client-120 the token subject is returned unverified', () => {
    writeTokens({ accessToken: `forged.${b64url(JSON.stringify({ sub: 'attacker-claimed' }))}.not-a-signature`, refreshToken: '' })
    expect(readTokenSubject()).toBe('attacker-claimed')
  })
})
