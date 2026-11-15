import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest'
import { resolveBackendUrl, proxyToBackend, makeProxyHandlers } from '../server/proxy'

describe('resolveBackendUrl', () => {
  it('auth-client-server-001 returns API_BACKEND_URL verbatim when non-empty', () => {
    expect(
      resolveBackendUrl({ API_BACKEND_URL: 'https://custom.example', NODE_ENV: 'production' }),
    ).toBe('https://custom.example')
  })

  it('auth-client-server-002 ignores an empty API_BACKEND_URL', () => {
    expect(resolveBackendUrl({ API_BACKEND_URL: '', NODE_ENV: 'production' })).toBe(
      'https://api.agenticdeveloperhub.com',
    )
  })

  it('uses explicit API_BACKEND_URL when set', () => {
    expect(
      resolveBackendUrl({ API_BACKEND_URL: 'https://custom.example', NODE_ENV: 'production' }),
    ).toBe('https://custom.example')
  })

  it('defaults to the shared prod data API in production', () => {
    expect(resolveBackendUrl({ NODE_ENV: 'production' })).toBe(
      'https://api.agenticdeveloperhub.com',
    )
  })

  it('defaults to localhost in development', () => {
    expect(resolveBackendUrl({ NODE_ENV: 'development' })).toBe('http://localhost:3000')
  })

  it('defaults to localhost when NODE_ENV is unset', () => {
    expect(resolveBackendUrl({})).toBe('http://localhost:3000')
  })
})

describe('proxyToBackend content negotiation', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  /** Capture the Headers the proxy forwards upstream. */
  async function captureForwardedHeaders(browserAccept: string): Promise<Headers> {
    let seen: Headers | undefined
    vi.stubGlobal(
      'fetch',
      vi.fn((_url: string, init: RequestInit) => {
        seen = init.headers as Headers
        return Promise.resolve(new Response('{}', { status: 200 }))
      }),
    )
    const req = new Request('https://site.example/api/oauth/signin/exchange', {
      method: 'POST',
      headers: { 'accept-encoding': browserAccept, 'content-type': 'application/json' },
      body: '{"code":"x"}',
    })
    await proxyToBackend(req, 'api', ['oauth', 'signin', 'exchange'])
    return seen as Headers
  }

  // Node's undici transparently DECODES a gzip/deflate response body but leaves
  // the upstream `content-encoding: gzip` on the Response it hands back. Since
  // proxyToBackend returns that Response verbatim, forwarding a browser's
  // `Accept-Encoding` makes the proxy declare an encoding the body no longer
  // has — the browser fails to decode it and `fetch` rejects with a TypeError.
  // Asking upstream for `identity` means there is never an encoding to lie
  // about; the CDN compresses on the way out to the browser.
  it('asks the backend for an unencoded body instead of forwarding the browser Accept-Encoding', async () => {
    const headers = await captureForwardedHeaders('gzip, deflate, br, zstd')
    expect(headers.get('accept-encoding')).toBe('identity')
  })

  it('overrides Accept-Encoding even when the browser asks only for gzip', async () => {
    const headers = await captureForwardedHeaders('gzip')
    expect(headers.get('accept-encoding')).toBe('identity')
  })
})

describe('conformance vectors (forwarding)', () => {
  const BACKEND = 'http://localhost:3000'

  beforeEach(() => {
    vi.stubEnv('API_BACKEND_URL', BACKEND)
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.unstubAllEnvs()
  })

  type Call = { url: string; init: RequestInit }

  function stubFetch(response: () => Response = () => new Response('{}', { status: 200 })) {
    const calls: Call[] = []
    vi.stubGlobal(
      'fetch',
      vi.fn((url: string, init: RequestInit) => {
        calls.push({ url, init })
        return Promise.resolve(response())
      }),
    )
    return calls
  }

  it('auth-client-server-003 production default is the shared data API', () => {
    expect(resolveBackendUrl({ NODE_ENV: 'production' })).toBe('https://api.agenticdeveloperhub.com')
  })

  it('auth-client-server-004 development default is localhost', () => {
    expect(resolveBackendUrl({ NODE_ENV: 'development' })).toBe('http://localhost:3000')
  })

  it('auth-client-server-005 empty env defaults to localhost', () => {
    expect(resolveBackendUrl({})).toBe('http://localhost:3000')
  })

  it('auth-client-server-006 api prefix inserts no namespace segment', async () => {
    const calls = stubFetch()
    await proxyToBackend(new Request('https://site.example/api/users/42'), 'api', ['users', '42'])
    expect(calls[0]!.url).toBe('http://localhost:3000/users/42')
  })

  it('auth-client-server-007 auth prefix is preserved', async () => {
    const calls = stubFetch()
    await proxyToBackend(new Request('https://site.example/auth/login'), 'auth', ['login'])
    expect(calls[0]!.url).toBe('http://localhost:3000/auth/login')
  })

  it('auth-client-server-008 path segments are joined with slashes', async () => {
    const calls = stubFetch()
    await proxyToBackend(new Request('https://site.example/api/a/b/c'), 'api', ['a', 'b', 'c'])
    expect(calls[0]!.url).toBe('http://localhost:3000/a/b/c')
  })

  it('auth-client-server-009 query string is forwarded unchanged', async () => {
    const calls = stubFetch()
    await proxyToBackend(new Request('https://site.example/api/foo?x=1&y=2'), 'api', ['foo'])
    expect(calls[0]!.url.endsWith('?x=1&y=2')).toBe(true)
  })

  it('auth-client-server-010 host and content-length headers are removed', async () => {
    const calls = stubFetch()
    const req = new Request('https://site.example/api/foo', {
      method: 'POST',
      headers: { host: 'site.example', 'content-length': '42' },
      body: '{"code":"x"}',
    })
    await proxyToBackend(req, 'api', ['foo'])
    const headers = calls[0]!.init.headers as Headers
    expect(headers.has('host')).toBe(false)
    expect(headers.has('content-length')).toBe(false)
  })

  it('auth-client-server-011 accept-encoding is forced to identity', async () => {
    const calls = stubFetch()
    const req = new Request('https://site.example/api/foo', {
      headers: { 'accept-encoding': 'gzip, deflate, br, zstd' },
    })
    await proxyToBackend(req, 'api', ['foo'])
    expect((calls[0]!.init.headers as Headers).get('accept-encoding')).toBe('identity')
  })

  it('auth-client-server-012 accept-encoding is identity even when only gzip was sent', async () => {
    const calls = stubFetch()
    const req = new Request('https://site.example/api/foo', { headers: { 'accept-encoding': 'gzip' } })
    await proxyToBackend(req, 'api', ['foo'])
    expect((calls[0]!.init.headers as Headers).get('accept-encoding')).toBe('identity')
  })

  it('auth-client-server-013 redirects are not followed and Set-Cookie passes through', async () => {
    const calls = stubFetch(
      () => new Response(null, { status: 302, headers: { 'set-cookie': 'session=abc' } }),
    )
    const res = await proxyToBackend(new Request('https://site.example/auth/cb'), 'auth', ['cb'])
    expect(calls[0]!.init.redirect).toBe('manual')
    expect(calls).toHaveLength(1)
    expect(res.status).toBe(302)
    expect(res.headers.get('set-cookie')).toBe('session=abc')
  })

  it('auth-client-server-014 mutating methods forward the raw body bytes', async () => {
    const calls = stubFetch()
    const req = new Request('https://site.example/api/foo', { method: 'POST', body: '{"code":"x"}' })
    await proxyToBackend(req, 'api', ['foo'])
    const body = calls[0]!.init.body as ArrayBuffer
    expect(new TextDecoder().decode(body)).toBe('{"code":"x"}')
  })

  it('auth-client-server-015 GET sends no body', async () => {
    const calls = stubFetch()
    await proxyToBackend(new Request('https://site.example/api/foo'), 'api', ['foo'])
    expect(calls[0]!.init.body).toBeUndefined()
  })

  it('auth-client-server-016 the backend response is returned verbatim', async () => {
    const backendRes = new Response('{"ok":true}', { status: 200 })
    stubFetch(() => backendRes)
    const res = await proxyToBackend(new Request('https://site.example/api/foo'), 'api', ['foo'])
    expect(res).toBe(backendRes)
    expect(res.status).toBe(200)
    expect(await res.text()).toBe('{"ok":true}')
  })

  it('auth-client-server-017 the factory returns exactly the five method handlers', () => {
    const handlers = makeProxyHandlers('api')
    expect(Object.keys(handlers).sort()).toEqual(['DELETE', 'GET', 'PATCH', 'POST', 'PUT'])
    for (const fn of Object.values(handlers)) expect(typeof fn).toBe('function')
  })

  it('auth-client-server-018 PUT and DELETE behave identically for the auth prefix', async () => {
    const calls = stubFetch()
    const handlers = makeProxyHandlers('auth')
    const ctx = { params: Promise.resolve({ path: ['login'] }) }
    await handlers.PUT(new Request('https://site.example/auth/login', { method: 'PUT', body: 'b' }), ctx)
    await handlers.DELETE(new Request('https://site.example/auth/login', { method: 'DELETE', body: 'b' }), ctx)
    expect(calls).toHaveLength(2)
    expect(calls[0]!.url).toBe('http://localhost:3000/auth/login')
    expect(calls[1]!.url).toBe(calls[0]!.url)
    expect(handlers.PUT).toBe(handlers.DELETE)
  })

  it('auth-client-server-019 params are awaited before forwarding', async () => {
    const calls = stubFetch()
    const params = new Promise<{ path: string[] }>((resolve) => {
      queueMicrotask(() => resolve({ path: ['x'] }))
    })
    await makeProxyHandlers('api').GET(new Request('https://site.example/api/x'), { params })
    expect(calls).toHaveLength(1)
    expect(calls[0]!.url).toBe('http://localhost:3000/x')
  })

  it('auth-client-server-020 Cookie and Authorization headers are forwarded unchanged', async () => {
    const calls = stubFetch()
    const req = new Request('https://site.example/api/foo', {
      headers: { cookie: 'session=abc', authorization: 'Bearer tok' },
    })
    await proxyToBackend(req, 'api', ['foo'])
    const headers = calls[0]!.init.headers as Headers
    expect(headers.get('cookie')).toBe('session=abc')
    expect(headers.get('authorization')).toBe('Bearer tok')
  })

  it('auth-client-server-021 a backend 401 is returned unchanged', async () => {
    stubFetch(() => new Response('{"error":"invalid_token"}', { status: 401 }))
    const res = await proxyToBackend(new Request('https://site.example/api/foo'), 'api', ['foo'])
    expect(res.status).toBe(401)
    expect(await res.text()).toBe('{"error":"invalid_token"}')
  })

  it('auth-client-server-022 no credential is added, decoded or given an expiry', async () => {
    const calls = stubFetch(() => new Response('{}', { status: 200 }))
    const res = await proxyToBackend(new Request('https://site.example/api/foo'), 'api', ['foo'])
    const headers = calls[0]!.init.headers as Headers
    expect(headers.has('cookie')).toBe(false)
    expect(headers.has('authorization')).toBe(false)
    expect(res.headers.has('set-cookie')).toBe(false)
  })
})
