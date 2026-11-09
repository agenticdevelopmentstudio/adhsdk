import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { configureAuth } from '../config'
import { invalidateRefresh } from '../refresh'
import { isoToUnix, listAllV1, listV1Page, unixToIso, withV1Query } from '../v1'

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
  it('appends, replaces, repeats arrays and drops nullish values', () => {
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

describe('listAllV1', () => {
  it('walks starting_after while has_more and keeps the caller filters', async () => {
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

  it('throws rather than truncating when the last row has no id to page from', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(page([{ scope: 'x' }], true))
    await expect(listAllV1('/api/v1/usage/counters')).rejects.toThrow(/no id to page from/)
  })
})

describe('listV1Page', () => {
  it('unwraps one page', async () => {
    vi.spyOn(globalThis, 'fetch').mockResolvedValueOnce(page([{ id: 'a' }], true))
    expect(await listV1Page('/api/v1/teams?limit=1')).toEqual({ data: [{ id: 'a' }], hasMore: true })
  })
})

describe('unix timestamps', () => {
  it('round-trips unix seconds and ISO strings', () => {
    expect(unixToIso(0)).toBe('1970-01-01T00:00:00.000Z')
    expect(unixToIso(null)).toBeNull()
    expect(isoToUnix('2026-01-01T00:00:00.000Z')).toBe(1767225600)
  })
})
