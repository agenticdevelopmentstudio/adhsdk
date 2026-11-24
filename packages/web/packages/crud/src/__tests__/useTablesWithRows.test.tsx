import { afterEach, beforeEach, describe, it, expect, vi } from 'vitest'
import { act, renderHook, waitFor } from '@testing-library/react'
import type { CrudTableMeta } from '../types'

// Conformance vectors use-tables-with-rows-001 .. 011, driven through the hook itself.

interface Pending {
  url: string
  signal: AbortSignal | undefined
  resolve: (page: unknown) => void
  reject: (err: unknown) => void
}

// Every probe the hook sends. `auto` answers a probe at once from `answerFor`; with `auto` off a
// probe stays pending until the test settles it.
const probes: Pending[] = []
let auto = true
let answerFor: (url: string) => unknown = () => ({ data: [{ id: 'r1' }] })
let inFlight = 0
let peak = 0

vi.mock('@adh-sdk/auth/client', async (importOriginal) => ({
  ...(await importOriginal<typeof import('@adh-sdk/auth/client')>()),
  authedJson: (url: string, init?: RequestInit): Promise<unknown> => {
    inFlight += 1
    peak = Math.max(peak, inFlight)
    return new Promise((resolve, reject) => {
      const settle = (fn: () => void) => {
        inFlight -= 1
        fn()
      }
      const entry: Pending = {
        url,
        signal: init?.signal ?? undefined,
        resolve: (page) => settle(() => resolve(page)),
        reject: (err) => settle(() => reject(err)),
      }
      probes.push(entry)
      init?.signal?.addEventListener('abort', () => entry.reject(new Error('aborted')))
      if (auto) {
        queueMicrotask(() => {
          try {
            const answer = answerFor(url)
            if (answer instanceof Error) entry.reject(answer)
            else entry.resolve(answer)
          } catch (err) {
            entry.reject(err)
          }
        })
      }
    })
  },
}))

const { AuthHttpError } = await import('@adh-sdk/auth/client')
const { useTablesWithRows, resetTablesWithRows, TABLES_WITH_ROWS_TTL_MS } = await import(
  '../useTablesWithRows'
)

const table = (name: string): CrudTableMeta => ({
  key: `s/${name}`,
  schema: 's',
  table: name,
  basePath: `/v1/s/${name}`,
  itemPath: `/v1/s/${name}/{id}`,
  pkParams: ['id'],
  exposure: 'owner',
  columns: [],
})

const urlOf = (name: string) => `/api/v1/s/${name}?workspace=w&limit=1`
const FILTER = { workspace: 'w' }
const rows = { data: [{ id: 'r1' }] }
const none = { data: [] }

beforeEach(() => {
  probes.length = 0
  auto = true
  answerFor = () => rows
  inFlight = 0
  peak = 0
  localStorage.removeItem('auth_tokens')
  resetTablesWithRows()
})
afterEach(() => {
  vi.restoreAllMocks()
})

const AB = [table('a'), table('b')]

describe('useTablesWithRows', () => {
  it('use-tables-with-rows-001: a null filter sends no request and answers pending', async () => {
    const { result } = renderHook(() => useTablesWithRows(AB, null))
    await act(() => new Promise((resolve) => setTimeout(resolve, 0)))
    expect(probes).toHaveLength(0)
    expect(result.current).toEqual({
      populated: null,
      empty: null,
      unknown: null,
      failed: false,
      firstWithRows: null,
    })
  })

  it('use-tables-with-rows-002: probes the list URL with limit=1 and sorts rows from none', async () => {
    answerFor = (url) => (url === urlOf('b') ? none : rows)
    const { result } = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(result.current.populated).not.toBeNull())
    expect(probes.map((p) => p.url).sort()).toEqual([
      '/api/v1/s/a?workspace=w&limit=1',
      '/api/v1/s/b?workspace=w&limit=1',
    ])
    expect([...result.current.populated!]).toEqual(['s/a'])
    expect([...result.current.empty!]).toEqual(['s/b'])
    expect([...result.current.unknown!]).toEqual([])
    expect(result.current.failed).toBe(false)
  })

  it('use-tables-with-rows-002: a response with no data array counts as empty', async () => {
    answerFor = () => ({ object: 'list' })
    const { result } = renderHook(() => useTablesWithRows([table('a')], FILTER, { principal: 'u1' }))
    await waitFor(() => expect(result.current.empty).not.toBeNull())
    expect([...result.current.empty!]).toEqual(['s/a'])
    expect([...result.current.populated!]).toEqual([])
  })

  it('use-tables-with-rows-003: a 403 and a 404 put the table in no set', async () => {
    answerFor = (url) =>
      url.startsWith('/api/v1/s/a')
        ? new AuthHttpError(403, 'forbidden')
        : new AuthHttpError(404, 'missing')
    const { result } = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(result.current.populated).not.toBeNull())
    expect([...result.current.populated!]).toEqual([])
    expect([...result.current.empty!]).toEqual([])
    expect([...result.current.unknown!]).toEqual([])
    expect(result.current.failed).toBe(false)
  })

  it('use-tables-with-rows-004: any other failure lands in unknown and marks the sweep failed', async () => {
    answerFor = (url) => (url.startsWith('/api/v1/s/a') ? new AuthHttpError(500, 'boom') : rows)
    const { result } = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(result.current.populated).not.toBeNull())
    expect([...result.current.unknown!]).toEqual(['s/a'])
    expect([...result.current.populated!]).toEqual(['s/b'])
    expect(result.current.failed).toBe(true)
  })

  it('use-tables-with-rows-005: no more than 8 probes are outstanding at once', async () => {
    auto = false
    const many = Array.from({ length: 20 }, (_, i) => table(`t${i}`))
    const { result, unmount } = renderHook(() =>
      useTablesWithRows(many, FILTER, { principal: 'u1' }),
    )
    await waitFor(() => expect(probes).toHaveLength(8))
    // Settle probes one at a time; the queue refills but never past the bound.
    for (let settled = 0; settled < 20; settled += 1) {
      await waitFor(() => expect(probes.length).toBeGreaterThan(settled))
      await act(async () => {
        probes[settled]!.resolve(rows)
        await Promise.resolve()
      })
    }
    await waitFor(() => expect(result.current.populated).not.toBeNull())
    expect(probes).toHaveLength(20)
    expect(peak).toBe(8)
    unmount()
  })

  it('use-tables-with-rows-006: probes the open table first and reports it before the sweep ends', async () => {
    auto = false
    const five = ['a', 'b', 'c', 'd', 'e'].map(table)
    const { result, unmount } = renderHook(() =>
      useTablesWithRows(five, FILTER, { principal: 'u1', first: 's/e' }),
    )
    await waitFor(() => expect(probes.length).toBeGreaterThan(0))
    expect(probes[0]!.url).toBe('/api/v1/s/e?workspace=w&limit=1')
    await act(async () => {
      probes[0]!.resolve(rows)
      await Promise.resolve()
    })
    await waitFor(() => expect(result.current.firstWithRows).toBe('s/e'))
    expect(result.current.populated).toBeNull()
    expect(result.current.empty).toBeNull()
    expect(result.current.unknown).toBeNull()
    unmount()
  })

  it('use-tables-with-rows-007: a fresh remembered answer is served on a remount with no probe', async () => {
    const first = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(first.result.current.populated).not.toBeNull())
    first.unmount()
    probes.length = 0
    const again = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    expect([...again.result.current.populated!].sort()).toEqual(['s/a', 's/b'])
    await act(() => new Promise((resolve) => setTimeout(resolve, 0)))
    expect(probes).toHaveLength(0)
  })

  it('use-tables-with-rows-008: a stale remembered answer is shown at once and revalidated behind it', async () => {
    answerFor = (url) => (url === urlOf('a') ? none : rows)
    const first = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(first.result.current.populated).not.toBeNull())
    first.unmount()
    probes.length = 0
    answerFor = () => rows
    vi.spyOn(Date, 'now').mockReturnValue(Date.now() + TABLES_WITH_ROWS_TTL_MS + 1)
    const again = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    // At once, from memory: a is still empty.
    expect([...again.result.current.empty!]).toEqual(['s/a'])
    await waitFor(() => expect([...again.result.current.populated!].sort()).toEqual(['s/a', 's/b']))
    expect(probes).toHaveLength(2)
  })

  it('use-tables-with-rows-009: a failed revalidation keeps the remembered answer', async () => {
    const first = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(first.result.current.populated).not.toBeNull())
    first.unmount()
    probes.length = 0
    answerFor = () => new AuthHttpError(500, 'boom')
    vi.spyOn(Date, 'now').mockReturnValue(Date.now() + TABLES_WITH_ROWS_TTL_MS + 1)
    const again = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(probes).toHaveLength(2))
    await act(() => new Promise((resolve) => setTimeout(resolve, 0)))
    expect(again.result.current.failed).toBe(false)
    expect([...again.result.current.populated!].sort()).toEqual(['s/a', 's/b'])
  })

  it('use-tables-with-rows-009: a failed first sweep is never remembered, so a later mount probes again', async () => {
    answerFor = () => new AuthHttpError(500, 'boom')
    const first = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(first.result.current.failed).toBe(true))
    first.unmount()
    probes.length = 0
    answerFor = () => rows
    const again = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(again.result.current.populated).not.toBeNull())
    expect(probes).toHaveLength(2)
    expect(again.result.current.failed).toBe(false)
  })

  it('use-tables-with-rows-010: a remembered answer is never served to another principal', async () => {
    const first = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(first.result.current.populated).not.toBeNull())
    first.unmount()
    probes.length = 0
    auto = false
    const other = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u2' }))
    expect(other.result.current.populated).toBeNull()
    await waitFor(() => expect(probes).toHaveLength(2))
    other.unmount()
  })

  it('use-tables-with-rows-010: every remembered answer is forgotten when the signed-in subject changes', async () => {
    const first = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(first.result.current.populated).not.toBeNull())
    first.unmount()
    // Another tab signs in as someone else.
    localStorage.setItem(
      'auth_tokens',
      JSON.stringify({ accessToken: 'h.eyJzdWIiOiJ1MiJ9.s', refreshToken: 'r' }),
    )
    window.dispatchEvent(new StorageEvent('storage'))
    probes.length = 0
    auto = false
    const again = renderHook(() => useTablesWithRows(AB, FILTER, { principal: 'u1' }))
    expect(again.result.current.populated).toBeNull()
    await waitFor(() => expect(probes).toHaveLength(2))
    again.unmount()
  })

  it('use-tables-with-rows-011: unmounting aborts probes in flight and sends none of the queued ones', async () => {
    auto = false
    const many = Array.from({ length: 20 }, (_, i) => table(`t${i}`))
    const { unmount } = renderHook(() => useTablesWithRows(many, FILTER, { principal: 'u1' }))
    await waitFor(() => expect(probes).toHaveLength(8))
    unmount()
    await act(() => new Promise((resolve) => setTimeout(resolve, 0)))
    expect(probes.every((p) => p.signal?.aborted)).toBe(true)
    // The aborted probes settled, yet no worker went on to the queue.
    expect(probes).toHaveLength(8)
  })
})
