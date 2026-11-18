import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { AuthHttpError } from '../client'

// The passkey ceremony itself is the browser's; these tests are about what is POSTed around it.
vi.mock('@simplewebauthn/browser', () => ({
  startAuthentication: vi.fn(async () => ({ id: 'cred' })),
}))

import {
  beginLogin,
  ssoLogout,
  ssoSwitchUrl,
  stripSsoFragment,
  takeReturnTo,
  centralEmailLogin,
  centralPasswordlessPasskey,
  isCentralClientRefusal,
  readCentralParams,
  beginLinkProvider,
  providerSigninUrl,
} from '../sso'

// Mirror of the private key in sso.ts — the stash beginLogin/takeReturnTo share.
const RETURN_TO_KEY = 'adh_sso_return_to'

// beginLogin reads window.location.origin and assigns window.location.href.
// jsdom's real location can't be navigated, so swap in a plain stand-in we can
// read the assigned href back from.
let savedLocation: PropertyDescriptor | undefined
function stubLocation(origin: string): { href: string } {
  const loc = { origin, href: '' }
  Object.defineProperty(window, 'location', { configurable: true, value: loc })
  return loc
}

beforeEach(() => {
  savedLocation = Object.getOwnPropertyDescriptor(window, 'location')
  window.sessionStorage.clear()
  delete process.env.NEXT_PUBLIC_AUTH_API_URL
})

afterEach(() => {
  if (savedLocation) Object.defineProperty(window, 'location', savedLocation)
})

describe('beginLogin', () => {
  it('navigates to the configured AS /authorize with clientId + callback return', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    const loc = stubLocation('https://cookbook.example.com')

    beginLogin({ clientId: 'cookbook' })

    const url = new URL(loc.href)
    expect(url.origin).toBe('https://api.hub.example.com')
    expect(url.pathname).toBe('/oauth/signin/authorize')
    expect(url.searchParams.get('clientId')).toBe('cookbook')
    expect(url.searchParams.get('return')).toBe('https://cookbook.example.com/auth/callback')
  })

  it("defaults clientId to 'adh'", () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    const loc = stubLocation('https://site.example.com')

    beginLogin()

    expect(new URL(loc.href).searchParams.get('clientId')).toBe('adh')
  })

  it('prefers an explicit authApiBase over the env var and trims trailing slashes', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://env.example.com'
    const loc = stubLocation('https://site.example.com')

    beginLogin({ authApiBase: 'https://explicit.example.com///' })

    expect(new URL(loc.href).origin).toBe('https://explicit.example.com')
  })

  it('honors a custom callbackPath in the return URL', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    const loc = stubLocation('https://site.example.com')

    beginLogin({ callbackPath: '/sso/done' })

    expect(new URL(loc.href).searchParams.get('return')).toBe('https://site.example.com/sso/done')
  })

  it('falls back to the same-origin BFF proxy when no AS base is configured', () => {
    const loc = stubLocation('https://site.example.com')

    beginLogin({ clientId: 'adh' })

    // Relative target → resolves against the current origin.
    const url = new URL(loc.href, 'https://site.example.com')
    expect(url.origin).toBe('https://site.example.com')
    expect(url.pathname).toBe('/api/oauth/signin/authorize')
    expect(url.searchParams.get('return')).toBe('https://site.example.com/auth/callback')
  })

  it('stashes returnTo so the callback can restore it', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    stubLocation('https://site.example.com')

    beginLogin({ returnTo: '/settings' })

    expect(window.sessionStorage.getItem(RETURN_TO_KEY)).toBe('/settings')
  })

  it('does not stash anything when returnTo is omitted', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    stubLocation('https://site.example.com')

    beginLogin()

    expect(window.sessionStorage.getItem(RETURN_TO_KEY)).toBeNull()
  })
})

describe('providerSigninUrl', () => {
  // The `/start` contract has two consumers that must not drift: LoginCard's provider
  // buttons and the hub's own signup page. Sign-in and sign-up are the SAME request —
  // the backend JIT-creates the account and enforces `new_user_signups` there — so
  // there is one builder, and these are its terms.
  it('names the AS /oauth/signin/start with clientId, providerId and return', () => {
    const url = new URL(
      providerSigninUrl({
        clientId: 'adh',
        providerId: 'github',
        returnUrl: 'https://hub.example.com/auth/callback',
        authApiBase: 'https://api.hub.example.com',
      }),
    )
    expect(url.origin).toBe('https://api.hub.example.com')
    expect(url.pathname).toBe('/oauth/signin/start')
    expect(url.searchParams.get('clientId')).toBe('adh')
    expect(url.searchParams.get('providerId')).toBe('github')
    expect(url.searchParams.get('return')).toBe('https://hub.example.com/auth/callback')
  })

  it('falls back to the same-origin BFF proxy when no AS base is configured (local dev)', () => {
    const url = new URL(
      providerSigninUrl({ clientId: 'adh', providerId: 'google', returnUrl: 'https://s.example.com/auth/callback' }),
      'https://s.example.com',
    )
    expect(url.pathname).toBe('/api/oauth/signin/start')
  })

  // The rule an OMITTED base follows, and the reason LoginCard's prop is not
  // prop-only: with the env var inlined, no argument still means the AS host, so
  // /start and /callback share it (the OAuth state cookie is host-only). Only a
  // build with NEITHER falls through to the same-origin proxy above.
  it('falls back to the env AS base — not the proxy — when no base is passed', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://env.example.com'
    const url = new URL(
      providerSigninUrl({ clientId: 'adh', providerId: 'github', returnUrl: 'https://s.example.com/auth/callback' }),
    )
    expect(url.origin).toBe('https://env.example.com')
    expect(url.pathname).toBe('/oauth/signin/start')
  })

  it('prefers an explicit authApiBase over the env var and trims trailing slashes', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://env.example.com'
    const url = new URL(
      providerSigninUrl({
        clientId: 'adh',
        providerId: 'gitlab',
        returnUrl: 'https://s.example.com/auth/callback',
        authApiBase: 'https://explicit.example.com///',
      }),
    )
    expect(url.origin).toBe('https://explicit.example.com')
    expect(url.pathname).toBe('/oauth/signin/start')
  })
})

describe('ssoLogout', () => {
  it('navigates to the configured AS /logout with clientId + return on this origin', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    const loc = stubLocation('https://cookbook.example.com')

    ssoLogout({ clientId: 'cookbook' })

    const url = new URL(loc.href)
    expect(url.origin).toBe('https://api.hub.example.com')
    expect(url.pathname).toBe('/oauth/signin/logout')
    expect(url.searchParams.get('clientId')).toBe('cookbook')
    expect(url.searchParams.get('return')).toBe('https://cookbook.example.com/')
  })

  it("defaults clientId to 'adh' and returnTo to the site root", () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    const loc = stubLocation('https://site.example.com')

    ssoLogout()

    const url = new URL(loc.href)
    expect(url.searchParams.get('clientId')).toBe('adh')
    expect(url.searchParams.get('return')).toBe('https://site.example.com/')
  })

  it('honors a custom returnTo on the current origin', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    const loc = stubLocation('https://site.example.com')

    ssoLogout({ returnTo: '/goodbye' })

    expect(new URL(loc.href).searchParams.get('return')).toBe('https://site.example.com/goodbye')
  })

  it('prefers an explicit authApiBase over the env var and trims trailing slashes', () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://env.example.com'
    const loc = stubLocation('https://site.example.com')

    ssoLogout({ authApiBase: 'https://explicit.example.com///' })

    expect(new URL(loc.href).origin).toBe('https://explicit.example.com')
  })

  it('falls back to the same-origin BFF proxy when no AS base is configured', () => {
    const loc = stubLocation('https://site.example.com')

    ssoLogout({ clientId: 'adh' })

    const url = new URL(loc.href, 'https://site.example.com')
    expect(url.origin).toBe('https://site.example.com')
    expect(url.pathname).toBe('/api/oauth/signin/logout')
  })
})

describe('readCentralParams', () => {
  it('reads clientId + returnUrl from the AS-appended query', () => {
    expect(
      readCentralParams('?clientId=admin&return=https%3A%2F%2Fadmin.example.com%2Fauth%2Fcallback'),
    ).toEqual({ clientId: 'admin', returnUrl: 'https://admin.example.com/auth/callback' })
  })

  it("defaults clientId to 'adh' when only return is present", () => {
    expect(readCentralParams('?return=https%3A%2F%2Fx.example.com%2Fcb')).toEqual({
      clientId: 'adh',
      returnUrl: 'https://x.example.com/cb',
    })
  })

  it('returns null without a return — a plain direct (in-site) login', () => {
    expect(readCentralParams('?clientId=adh')).toBeNull()
    expect(readCentralParams('')).toBeNull()
  })
})

describe('centralEmailLogin', () => {
  let savedFetch: typeof globalThis.fetch
  beforeEach(() => {
    savedFetch = globalThis.fetch
  })
  afterEach(() => {
    globalThis.fetch = savedFetch
  })

  function stubFetch(
    body: unknown,
    status = 200,
  ): Array<{ url: string; init?: RequestInit }> {
    const calls: Array<{ url: string; init?: RequestInit }> = []
    globalThis.fetch = (async (url: string, init?: RequestInit) => {
      calls.push({ url, init })
      return new Response(JSON.stringify(body), {
        status,
        headers: { 'content-type': 'application/json' },
      })
    }) as unknown as typeof fetch
    return calls
  }

  it('POSTs the AS /login with clientId+return and navigates to the redirectUrl', async () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    const loc = stubLocation('https://hub.example.com')
    const calls = stubFetch({ redirectUrl: 'https://bitbag.example.com/auth/callback#code=abc' })

    await centralEmailLogin({
      clientId: 'adh',
      returnUrl: 'https://bitbag.example.com/auth/callback',
      identifier: 'a@b.com',
      password: 'pw',
    })

    expect(calls[0]!.url).toBe('https://api.hub.example.com/oauth/signin/login')
    expect(calls[0]!.init?.credentials).toBe('include') // so the central cookie is stored
    expect(JSON.parse(calls[0]!.init!.body as string)).toMatchObject({
      // The generic `identifier` wire key (never the legacy `email`, which would pin the
      // AS lookup to email-only) — the AS classifies email / slug / phone itself.
      identifier: 'a@b.com',
      password: 'pw',
      clientId: 'adh',
      return: 'https://bitbag.example.com/auth/callback',
    })
    // Funnels the exchange code back to the BRAND site, not the hub.
    expect(loc.href).toBe('https://bitbag.example.com/auth/callback#code=abc')
  })

  it('forwards the admin clientId unchanged', async () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    stubLocation('https://hub.example.com')
    const calls = stubFetch({ redirectUrl: 'https://admin.example.com/auth/callback#code=z' })

    await centralEmailLogin({
      clientId: 'admin',
      returnUrl: 'https://admin.example.com/auth/callback',
      identifier: 'root',
      password: 'pw',
    })

    expect(JSON.parse(calls[0]!.init!.body as string).clientId).toBe('admin')
  })

  // This route does NOT take the same-origin `/api` fallback the rest of asEndpoint's
  // callers take, and the difference is the whole point. A relayed central login sends
  // the AS's Set-Cookie back through THIS host, so the host-only central cookie is
  // stored for the brand site instead of the AS: the login looks like it worked — a
  // code is exchanged, this header fills in — while no central session exists, which
  // is a signed-in visitor reading as anonymous on the other 40-odd sites. So the
  // unconfigured build must refuse and say so, not half-succeed.
  it('refuses, rather than posting credentials to the same-origin proxy, with no AS base', async () => {
    const loc = stubLocation('https://hub.example.com')
    const calls = stubFetch({ redirectUrl: 'https://x.example.com/cb#code=1' })

    await expect(
      centralEmailLogin({
        clientId: 'adh',
        returnUrl: 'https://x.example.com/cb',
        identifier: 'a',
        password: 'b',
      }),
    ).rejects.toThrow(/NEXT_PUBLIC_AUTH_API_URL/)

    // The credentials never left the page, and nothing navigated: a thrown message is
    // what LoginCard renders, so the visitor is told instead of silently half-logged-in.
    expect(calls).toHaveLength(0)
    expect(loc.href).toBe('')
  })

  it('throws the server message and does NOT navigate on failure', async () => {
    process.env.NEXT_PUBLIC_AUTH_API_URL = 'https://api.hub.example.com'
    const loc = stubLocation('https://hub.example.com')
    stubFetch({ message: 'invalid credentials' }, 401)

    await expect(
      centralEmailLogin({
        clientId: 'adh',
        returnUrl: 'https://x.example.com/cb',
        identifier: 'a',
        password: 'b',
      }),
    ).rejects.toThrow('invalid credentials')
    expect(loc.href).toBe('') // never navigated
  })
})

describe('centralPasswordlessPasskey', () => {
  let savedFetch: typeof globalThis.fetch
  beforeEach(() => {
    savedFetch = globalThis.fetch
  })
  afterEach(() => {
    globalThis.fetch = savedFetch
  })

  function stubFetchSequence(...bodies: unknown[]): Array<{ url: string; init?: RequestInit }> {
    const calls: Array<{ url: string; init?: RequestInit }> = []
    globalThis.fetch = (async (url: string, init?: RequestInit) => {
      const body = bodies[calls.length]
      calls.push({ url, init })
      return new Response(JSON.stringify(body), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      })
    }) as unknown as typeof fetch
    return calls
  }

  // The options request picks the login REALM from the client: without the client an operator
  // signing in to the admin site got the hub realm's options, so a passkey they hold as an
  // operator was never offered. `client_id` is the /v1 wire name of the route's `clientId`.
  it('names the target client on the passkey options request', async () => {
    stubLocation('https://hub.example.com')
    const calls = stubFetchSequence(
      { options: {}, token: 't2' },
      { redirectUrl: 'https://admin.example.com/auth/callback#code=z' },
    )

    await centralPasswordlessPasskey(
      {
        clientId: 'admin',
        returnUrl: 'https://admin.example.com/auth/callback',
        authApiBase: 'https://api.hub.example.com',
      },
      'root@example.com',
    )

    expect(calls[0]!.url).toBe('https://api.hub.example.com/v1/auth/passkey_challenges')
    expect(JSON.parse(calls[0]!.init!.body as string)).toEqual({
      method: 'passkey',
      identifier: 'root@example.com',
      client_id: 'admin',
    })
    // The completion still carries the same client + return, as every central step does.
    expect(JSON.parse(calls[1]!.init!.body as string)).toMatchObject({
      clientId: 'admin',
      return: 'https://admin.example.com/auth/callback',
    })
  })
})

// The AS decides a client's realm from its ecosystem tag; the browser learns it only from
// these two refusals (adh oauthRedirect.ts centralLoginRealm, routes/auth.ts clientLoginRealm).
describe('isCentralClientRefusal', () => {
  it('recognises the central routes refusing a customer client', () => {
    expect(isCentralClientRefusal(new AuthHttpError(400, 'this client does not use the central sign-in'))).toBe(true)
  })

  it('recognises the passkey options refusing an unknown or customer client', () => {
    expect(isCentralClientRefusal(new AuthHttpError(400, 'client not found'))).toBe(true)
  })

  it('leaves every other failure to be shown as it came', () => {
    expect(isCentralClientRefusal(new AuthHttpError(400, 'Invalid email or password'))).toBe(false)
    expect(isCentralClientRefusal(new AuthHttpError(500, 'client not found'))).toBe(false)
    expect(isCentralClientRefusal(new Error('client not found'))).toBe(false)
  })
})
