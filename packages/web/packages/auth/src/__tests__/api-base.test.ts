import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { configureAuth } from '../config'
import { writeTokens } from '../tokens'
import { invalidateRefresh } from '../refresh'
import { apiBase, apiUrl, configureApiBase, resetApiBaseForTests } from '../api-base'
import { authedJson, linkProvider, publicJson } from '../client'

// The configurable API base (api-base.ts): the default leaves every path as it is, so the hub
// and every site with an `/api` rewrite are unchanged; a configured base sends `/api/...` to
// `<base>/...`, and nothing else moves.

beforeEach(() => {
  localStorage.clear()
  configureAuth({ storageKey: 'test_tokens', refreshPath: '/api/v1/auth/sessions/refresh' })
  invalidateRefresh()
  resetApiBaseForTests()
})

afterEach(() => {
  resetApiBaseForTests()
  vi.restoreAllMocks()
})

describe('apiUrl', () => {
  it('is the identity under the default base', () => {
    expect(apiBase()).toBe('/api')
    expect(apiUrl('/api/v1/workspaces')).toBe('/api/v1/workspaces')
    expect(apiUrl('/api')).toBe('/api')
    expect(apiUrl('/admin/auth/session')).toBe('/admin/auth/session')
  })

  it('sends /api/... to the configured base, with its query, and drops trailing slashes', () => {
    configureApiBase('https://api.example.test/')
    expect(apiBase()).toBe('https://api.example.test')
    expect(apiUrl('/api/v1/workspaces?limit=5')).toBe('https://api.example.test/v1/workspaces?limit=5')
    expect(apiUrl('/api/jobs')).toBe('https://api.example.test/jobs')
    expect(apiUrl('/api')).toBe('https://api.example.test')
    expect(apiUrl('/api?x=1')).toBe('https://api.example.test?x=1')
  })

  it('leaves anything that is not an /api path alone', () => {
    configureApiBase('https://api.example.test')
    expect(apiUrl('/admin/auth/refresh')).toBe('/admin/auth/refresh')
    expect(apiUrl('/apiary/x')).toBe('/apiary/x')
    expect(apiUrl('https://uploads.example.test/put?sig=1')).toBe('https://uploads.example.test/put?sig=1')
    expect(apiUrl('/v1/x')).toBe('/v1/x')
  })

  it('an empty or missing base restores the default', () => {
    configureApiBase('https://api.example.test')
    configureApiBase('')
    expect(apiBase()).toBe('/api')
    configureApiBase('https://api.example.test')
    configureApiBase(undefined)
    expect(apiUrl('/api/v1/x')).toBe('/api/v1/x')
  })
})

describe('requests follow the base', () => {
  it('authedJson sends the Bearer to the configured base', async () => {
    writeTokens({ accessToken: 'tok', refreshToken: '' })
    configureApiBase('https://api.example.test')
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ ok: true }), { status: 200 }),
    )
    await authedJson('/api/v1/account')
    const [url, init] = fetchMock.mock.calls[0]!
    expect(url).toBe('https://api.example.test/v1/account')
    expect((init?.headers as Record<string, string>).Authorization).toBe('Bearer tok')
    expect(init?.credentials).toBeUndefined()
  })

  it('publicJson goes to the configured base too, with no authorization', async () => {
    configureApiBase('https://api.example.test')
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ ok: true }), { status: 200 }),
    )
    await publicJson('/api/v1/public/support/grants/x', { method: 'POST', body: '{}' })
    const [url, init] = fetchMock.mock.calls[0]!
    expect(url).toBe('https://api.example.test/v1/public/support/grants/x')
    expect(new Headers(init?.headers).has('authorization')).toBe(false)
  })

  it('under the default base the same calls stay same-origin', async () => {
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ ok: true }), { status: 200 }),
    )
    await publicJson('/api/v1/public/x')
    expect(fetchMock.mock.calls[0]![0]).toBe('/api/v1/public/x')
  })

  it('linkProvider never follows the base: its same-origin AS fallback is the AS, not the data API', async () => {
    delete process.env.NEXT_PUBLIC_AUTH_API_URL
    writeTokens({ accessToken: 'tok', refreshToken: '' })
    configureApiBase('https://api.example.test')
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(new Response(null, { status: 204 }))
    await linkProvider({ clientSlug: 'adh', providerSlug: 'github', code: 'c', redirectUri: 'https://x.test/cb' })
    expect(fetchMock.mock.calls[0]![0]).toBe('/api/v1/account/login_methods')
  })
})

describe('configureApiBase validates the base', () => {
  it('refuses a schemeless or scheme-relative base and keeps the one it had', () => {
    configureApiBase('https://api.example.test')
    expect(() => configureApiBase('api.example.test')).toThrow(/absolute http\(s\) URL/)
    expect(() => configureApiBase('//api.example.test')).toThrow(/absolute http\(s\) URL/)
    expect(() => configureApiBase('ftp://api.example.test')).toThrow(/absolute http\(s\) URL/)
    expect(apiBase()).toBe('https://api.example.test')
  })

  it('accepts an http(s) origin, one with a path, and a root-relative path', () => {
    configureApiBase('http://localhost:8080')
    expect(apiBase()).toBe('http://localhost:8080')
    configureApiBase('https://api.example.test/prefix/')
    expect(apiBase()).toBe('https://api.example.test/prefix')
    configureApiBase('/backend')
    expect(apiUrl('/api/v1/x')).toBe('/backend/v1/x')
  })
})
