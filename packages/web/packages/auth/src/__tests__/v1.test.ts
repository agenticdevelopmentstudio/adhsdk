import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { AuthHttpError } from '../client'
import { configureAuth } from '../config'
import { invalidateRefresh } from '../refresh'
import { writeTokens } from '../tokens'
import {
  V1_PAGE_MAX,
  isoToUnix,
  listAllPublicV1,
  listAllV1,
  listV1Page,
  publicJson,
  unixToIso,
  withV1Query,
} from '../v1'

beforeEach(() => {
  localStorage.clear()
  configureAuth({ storageKey: 'test_tokens', refreshPath: '/api/v1/auth/sessions/refresh' })
  invalidateRefresh()
})

afterEach(() => {
  vi.restoreAllMocks()
})

const page = (data: unknown[], hasMore: boolean) =>
  new Response(JSON.stringify({ object: 'list', data, has_more: hasMore, url: '/v1/teams' }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  })

describe('withV1Query', () => {
  it('v1-001 v1-002 v1-003 appends, replaces, repeats arrays and drops nullish values', () => {
    expect(withV1Query('/api/v1/teams', { limit: 100, starting_after: undefined })).toBe(
      '/api/v1/teams?limit=100',
    )
    expect(withV1Query('/api/v1/teams?ecosystem_id=e1&limit=5', { limit: 100 })).toBe(
      '/api/v1/teams?ecosystem_id=e1&limit=100',
    )
    expect(withV1Query('/api/v1/account', { 'include[]': ['a', 'b'] })).toBe(
      '/api/v1/account?include%5B%5D=a&include%5B%5D=b',
    )
  })
})

describe('withV1Query (more)', () => {
  it('v1-004 keeps the fragment at the end', () => {
    expect(withV1Query('/x?a=1#top', { b: 2 })).toBe('/x?a=1&b=2#top')
  })

  it('v1-005 removes a key for an empty array and stringifies numbers and booleans', () => {
    expect(withV1Query('/x?k=old', { k: [], n: 5, f: false })).toBe('/x?n=5&f=false')
  })
})

describe('listAllV1', () => {
  it('v1-006 walks starting_after while has_more and keeps the caller filters', async () => {
    const fetchMock = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(page([{ id: 'a' }, { id: 'b' }], true))
      .mockResolvedValueOnce(page([{ id: 'c' }], false))
    const rows = await listAllV1<{ id: string }>('/api/v1/teams?ecosystem_id=e1')
    expect(rows.map((r) => r.id)).toEqual(['a', 'b', 'c'])
    const urls = fetchMock.mock.calls.map((c) => String(c[0]))
    expect(urls).toEqual([
      '/api/v1/teams?ecosystem_id=e1&limit=100',
      '/api/v1/teams?ecosystem_id=e1&limit=100&starting_after=b',
    ])
  })

  it('v1-007 throws rather than truncating when the last row has no id to page from', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(page([{ scope: 'x' }], true))
    await expect(listAllV1('/api/v1/usage/counters')).rejects.toThrow(/no id to page from/)
  })
})

describe('listAllV1 (more)', () => {
  const json = (body: unknown) =>
    new Response(JSON.stringify(body), { status: 200, headers: { 'content-type': 'application/json' } })

  it('v1-008 stops on an empty page even when has_more is true', async () => {
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(page([], true))
    expect(await listAllV1('/api/v1/teams')).toEqual([])
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })

  it('v1-009 uses opts.cursorOf for the cursor', async () => {
    const fetchMock = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(page([{ key: 'k1' }], true))
      .mockResolvedValueOnce(page([{ key: 'k2' }], false))
    await listAllV1('/api/v1/things', {}, { cursorOf: (row) => (row as { key: string }).key })
    expect(String(fetchMock.mock.calls[1]![0])).toContain('starting_after=k1')
  })

  it('v1-010 stringifies a numeric id for the default cursor', async () => {
    const fetchMock = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(page([{ id: 7 }], true))
      .mockResolvedValueOnce(page([{ id: 8 }], false))
    await listAllV1('/api/v1/things')
    expect(String(fetchMock.mock.calls[1]![0])).toContain('starting_after=7')
  })

  it('v1-011 reads a non-array data as an empty list', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      json({ object: 'list', data: 'oops', has_more: true }),
    )
    expect(await listAllV1('/api/v1/teams')).toEqual([])
  })

  it('v1-012 rejects with AuthHttpError when a later page fails and drops earlier rows', async () => {
    vi.spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(page([{ id: 'a' }], true))
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ error: { message: 'boom' } }), {
          status: 500,
          headers: { 'content-type': 'application/json' },
        }),
      )
    const err = await listAllV1('/api/v1/teams').catch((e: unknown) => e)
    expect(err).toBeInstanceOf(AuthHttpError)
    expect((err as AuthHttpError).status).toBe(500)
  })
})

describe('listV1Page', () => {
  it('v1-013 unwraps one page', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(page([{ id: 'a' }], true))
    expect(await listV1Page('/api/v1/teams?limit=1')).toEqual({ data: [{ id: 'a' }], hasMore: true })
  })

  it('v1-013 issues one request for the URL as given', async () => {
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(page([{ id: 'a' }], true))
    await listV1Page('/api/v1/teams?limit=1')
    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(String(fetchMock.mock.calls[0]![0])).toBe('/api/v1/teams?limit=1')
  })

  it('v1-011 reads a non-array data as an empty page', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(JSON.stringify({ object: 'list', data: 'oops', has_more: true }), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      }),
    )
    expect(await listV1Page('/api/v1/teams')).toEqual({ data: [], hasMore: true })
  })

  it("v1-014 treats has_more 'true' (a string) as false", async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(JSON.stringify({ object: 'list', data: [{ id: 'a' }], has_more: 'true' }), {
        status: 200,
        headers: { 'content-type': 'application/json' },
      }),
    )
    expect((await listV1Page('/api/v1/teams')).hasMore).toBe(false)
  })
})

describe('unix timestamps', () => {
  it('v1-015 v1-016 v1-018 round-trips unix seconds and ISO strings', () => {
    expect(unixToIso(0)).toBe('1970-01-01T00:00:00.000Z')
    expect(unixToIso(null)).toBeNull()
    expect(isoToUnix('2026-01-01T00:00:00.000Z')).toBe(1767225600)
  })
})

describe('timestamps (more)', () => {
  it('v1-017 unixToIso throws RangeError outside the date range', () => {
    expect(() => unixToIso(1e13)).toThrow(RangeError)
  })

  it('v1-016 unixToIso returns null for undefined and NaN', () => {
    expect(unixToIso(undefined)).toBeNull()
    expect(unixToIso(Number.NaN)).toBeNull()
  })

  it('v1-019 isoToUnix floors sub-second precision', () => {
    expect(isoToUnix('2026-01-01T00:00:00.999Z')).toBe(1767225600)
  })

  it('v1-020 isoToUnix returns NaN for an unparseable string', () => {
    expect(isoToUnix('not a date')).toBeNaN()
  })

  it('v1-021 V1_PAGE_MAX is 100', () => {
    expect(V1_PAGE_MAX).toBe(100)
  })
})

describe('listAllPublicV1 and publicJson', () => {
  const authOf = (init: unknown) => new Headers((init as RequestInit | undefined)?.headers).get('authorization')

  it('v1-022 listAllPublicV1 walks the pages like listAllV1 and sends no token', async () => {
    writeTokens({ accessToken: 'TOK', refreshToken: '' })
    const fetchMock = vi
      .spyOn(globalThis, 'fetch')
      .mockResolvedValueOnce(page([{ id: 'a' }], true))
      .mockResolvedValueOnce(page([{ id: 'b' }], false))
    const rows = await listAllPublicV1<{ id: string }>('/api/v1/feature_flags', { cache: 'no-store' })
    expect(rows.map((r) => r.id)).toEqual(['a', 'b'])
    expect(fetchMock.mock.calls.map((c) => String(c[0]))).toEqual([
      '/api/v1/feature_flags?limit=100',
      '/api/v1/feature_flags?limit=100&starting_after=a',
    ])
    for (const [, init] of fetchMock.mock.calls) {
      expect(authOf(init)).toBeNull()
      expect((init as RequestInit).cache).toBe('no-store')
    }
  })

  it('v1-023 publicJson sends a body as JSON and no token', async () => {
    writeTokens({ accessToken: 'TOK', refreshToken: '' })
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(
      new Response(JSON.stringify({ ok: 1 }), { status: 200, headers: { 'content-type': 'application/json' } }),
    )
    expect(await publicJson('/api/v1/public/x', { method: 'POST', body: '{}' })).toEqual({ ok: 1 })
    const init = fetchMock.mock.calls[0]?.[1]
    expect(authOf(init)).toBeNull()
    expect(new Headers((init as RequestInit).headers).get('content-type')).toBe('application/json')
  })

  it('v1-024 publicJson throws AuthHttpError on a refusal, with no refresh and no retry', async () => {
    const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ error: { message: 'nope' } }), { status: 401 }),
    )
    await expect(publicJson('/api/v1/public/x')).rejects.toBeInstanceOf(AuthHttpError)
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })
})
