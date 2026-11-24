/// <reference types="@testing-library/jest-dom/vitest" />
import type * as React from 'react'
import { render, renderHook, screen, waitFor, cleanup, act } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { notifyManager } from '@tanstack/react-query'
import { setAuthErrorReporter } from '@adh-sdk/auth'
import {
  revalidateResourceItems,
  useResourceItemQuery,
  useResourceItemPrefetch,
  useResourceItemWriter,
} from '../use-resource-item'
import { RESOURCE_GC_TIME, getToolkitQueryClient } from '../query'

// Notify observers SYNCHRONOUSLY. react-query's default scheduler is a real `setTimeout(fn, 0)` —
// it batches notifications into a macrotask — and `act(async …)` drains microtasks only, so a
// render driven by a settled query has NOT happened when `await act(…)` returns. Without this the
// assertions below would each have to become a `waitFor`, which is strictly weaker: `waitFor` also
// passes on the value already on screen, so it cannot catch a stale response arriving one tick
// late — the exact defect the out-of-order tests exist to pin. See use-resource-list.test.tsx.
notifyManager.setScheduler((cb) => cb())

const base64url = (json: string) =>
  btoa(json).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
const tokenForTenant = (id: string) => `x.${base64url(JSON.stringify({ ecosystem_id: id }))}.y`
const signInAs = (tenant: string) =>
  localStorage.setItem('auth_tokens', JSON.stringify({ accessToken: tokenForTenant(tenant) }))

afterEach(() => {
  cleanup()
  getToolkitQueryClient().clear()
  localStorage.clear()
})

/** A 404 shaped the way the toolkit's HTTP layer throws them, so `isNotFound` recognises it. */
const notFound = () => Object.assign(new Error('Not found'), { status: 404 })

function Probe({
  id,
  load,
  seedFrom,
}: {
  id: string | null
  load: (id: string) => Promise<{ body: string }>
  seedFrom?: () => { body: string } | undefined
}) {
  const { item, isSettled, isFetching, error } = useResourceItemQuery('/docs', id, load, {
    seedFrom,
  })
  return (
    <div
      data-testid="item"
      data-settled={isSettled}
      data-fetching={isFetching}
      data-error={error ?? ''}
    >
      {item?.body ?? 'none'}
    </div>
  )
}

function MissingProbe(props: React.ComponentProps<typeof Probe>) {
  const { isMissing } = useResourceItemQuery('/docs', props.id, props.load)
  return <div data-testid="missing">{String(isMissing)}</div>
}

describe('useResourceItemQuery', () => {
  it('paints the seed immediately and is NOT settled until the read lands', async () => {
    signInAs('A')
    let resolve!: (v: { body: string }) => void
    render(
      <Probe
        id="d1"
        load={() => new Promise((r) => (resolve = r))}
        seedFrom={() => ({ body: 'from the list' })}
      />,
    )

    // The seed is on screen on the FIRST paint, and the pane knows not to trust it yet.
    expect(screen.getByTestId('item')).toHaveTextContent('from the list')
    expect(screen.getByTestId('item')).toHaveAttribute('data-settled', 'false')

    await act(async () => resolve({ body: 'from the server' }))
    expect(screen.getByTestId('item')).toHaveTextContent('from the server')
    expect(screen.getByTestId('item')).toHaveAttribute('data-settled', 'true')
  })

  // The seed must NEVER be written into the cache: a list row is a PARTIAL item, and a cached
  // partial would be served to every later reader as if it were the server's full answer.
  it('does not leave the seed in the cache', async () => {
    signInAs('A')
    render(
      <Probe id="d2" load={() => new Promise(() => {})} seedFrom={() => ({ body: 'partial' })} />,
    )
    expect(screen.getByTestId('item')).toHaveTextContent('partial')
    expect(getToolkitQueryClient().getQueryData(['resource-item', 'A', '/docs', 'd2'])).toBeUndefined()
  })

  it('settles on a FAILED read too — settled is not the same as successful', async () => {
    signInAs('A')
    render(<Probe id="d3" load={() => Promise.reject(new Error('boom'))} />)
    await waitFor(() =>
      expect(screen.getByTestId('item')).toHaveAttribute('data-settled', 'true'),
    )
    expect(screen.getByTestId('item')).toHaveAttribute('data-error', 'boom')
  })

  it('is settled with nothing to read', () => {
    signInAs('A')
    render(<Probe id={null} load={() => Promise.resolve({ body: 'never' })} />)
    expect(screen.getByTestId('item')).toHaveAttribute('data-settled', 'true')
  })

  it('reports missing on a 404', async () => {
    signInAs('A')
    render(<MissingProbe id="d4" load={() => Promise.reject(notFound())} />)
    await waitFor(() => expect(screen.getByTestId('missing')).toHaveTextContent('true'))
  })

  it('does not report missing for an ordinary failure', async () => {
    signInAs('A')
    render(<MissingProbe id="d6" load={() => Promise.reject(new Error('offline'))} />)
    await waitFor(() => expect(screen.getByTestId('missing')).toHaveTextContent('false'))
  })
})

describe('useResourceItemPrefetch', () => {
  it('warms the cache so the click that follows paints from it', async () => {
    signInAs('A')
    const load = vi.fn((id: string) => Promise.resolve({ body: `body-${id}` }))
    let prefetch!: (id: string) => void
    function Warmer() {
      prefetch = useResourceItemPrefetch('/docs', load)
      return null
    }
    render(<Warmer />)

    await act(async () => {
      prefetch('d7')
    })
    expect(load).toHaveBeenCalledTimes(1)

    // The click: the item is already there, painted with no second read.
    render(<Probe id="d7" load={load} />)
    expect(screen.getAllByTestId('item')[0]).toHaveTextContent('body-d7')
    expect(load).toHaveBeenCalledTimes(1)
  })

  it('swallows a failing warm — a prefetch nobody asked for must not surface', async () => {
    signInAs('A')
    let prefetch!: (id: string) => void
    function Warmer() {
      prefetch = useResourceItemPrefetch('/docs', () => Promise.reject(new Error('nope')))
      return null
    }
    render(<Warmer />)
    await act(async () => {
      expect(() => prefetch('d8')).not.toThrow()
    })
  })
})

describe('useResourceItemWriter', () => {
  function Writer({ onReady }: { onReady: (w: (id: string, next: { body: string } | null) => void) => void }) {
    onReady(useResourceItemWriter<{ body: string }>('/docs'))
    return null
  }
  function renderWriter() {
    let write!: (id: string, next: { body: string } | null) => void
    render(<Writer onReady={(w) => (write = w)} />)
    return write
  }

  // A mutation is holding the server's own answer. Posting it costs nothing; re-reading would spend
  // a request to arrive back at the bytes already in hand.
  it('records a mutation response so the next open needs no read', () => {
    signInAs('A')
    const write = renderWriter()
    const load = vi.fn(() => Promise.resolve({ body: 'from the server' }))

    act(() => write('d9', { body: 'just saved' }))
    render(<Probe id="d9" load={load} />)

    expect(screen.getByTestId('item')).toHaveTextContent('just saved')
    expect(load).not.toHaveBeenCalled()
  })

  // EVICT, not a tombstone. Storing `null` would paint a deleted document on the next visit and
  // then have to take it away again; dropping the entry sends that visit to the server, where the
  // 404 turns into the host's "no longer there" alert.
  it('evicts a deleted item rather than caching its corpse', async () => {
    signInAs('A')
    const write = renderWriter()
    act(() => write('d10', { body: 'doomed' }))
    expect(getToolkitQueryClient().getQueryData(['resource-item', 'A', '/docs', 'd10'])).toEqual({
      body: 'doomed',
    })

    act(() => write('d10', null))
    expect(
      getToolkitQueryClient().getQueryData(['resource-item', 'A', '/docs', 'd10']),
    ).toBeUndefined()

    const load = vi.fn(() => Promise.resolve({ body: 'fresh' }))
    render(<Probe id="d10" load={load} />)
    await waitFor(() => expect(screen.getByTestId('item')).toHaveTextContent('fresh'))
    expect(load).toHaveBeenCalledTimes(1)
  })

  // The tenant is a key SEGMENT (see resourceItemKey), so a write made while signed in as A must
  // be unreachable to B — the same guarantee the list cache gives, and the reason an account
  // switch cannot hand one identity another's document.
  it('writes under the signed-in tenant only', () => {
    signInAs('A')
    const write = renderWriter()
    act(() => write('d11', { body: "A's copy" }))

    expect(getToolkitQueryClient().getQueryData(['resource-item', 'A', '/docs', 'd11'])).toEqual({
      body: "A's copy",
    })
    expect(
      getToolkitQueryClient().getQueryData(['resource-item', 'B', '/docs', 'd11']),
    ).toBeUndefined()
  })
})

// Conformance vectors for resource-data (cookbook/data/services/resource-data).
describe('resource-item conformance', () => {
  type Doc = { body: string }
  const reporter = vi.fn()

  beforeEach(() => {
    reporter.mockReset()
    setAuthErrorReporter(reporter)
    vi.spyOn(console, 'error').mockImplementation(() => {})
  })
  afterEach(() => {
    setAuthErrorReporter(null)
    vi.restoreAllMocks()
  })

  const useItem = (
    id: string | null,
    load: (id: string) => Promise<Doc>,
    opts?: Parameters<typeof useResourceItemQuery<Doc>>[3],
  ) => renderHook(() => useResourceItemQuery<Doc>('projects', id, load, opts))
  const flush = () => act(async () => {})

  it('resource-data-039 the item cache key is ("resource-item", tenant, cacheKey, id)', () => {
    signInAs('t1')
    const { result } = renderHook(() => useResourceItemWriter<Doc>('projects'))
    act(() => result.current('p-1', { body: 'x' }))
    expect(getToolkitQueryClient().getQueryData(['resource-item', 't1', 'projects', 'p-1'])).toEqual({
      body: 'x',
    })
  })

  it('resource-data-040 revalidateResourceItems invalidates every matching entry', async () => {
    signInAs('t1')
    const projects = vi.fn(() => Promise.resolve({ body: 'p' }))
    const other = vi.fn(() => Promise.resolve({ body: 'o' }))
    renderHook(() => useResourceItemQuery<Doc>('projects', 'p-1', projects))
    renderHook(() => useResourceItemQuery<Doc>('projects', 'p-2', projects))
    renderHook(() => useResourceItemQuery<Doc>('docs', 'd-1', other))
    await flush()
    expect(projects).toHaveBeenCalledTimes(2)

    await act(async () => revalidateResourceItems((key) => key === 'projects'))
    expect(projects).toHaveBeenCalledTimes(4)
    expect(other).toHaveBeenCalledTimes(1)
  })

  it('resource-data-041 the read state caches under the tenant-scoped key', async () => {
    signInAs('t1')
    useItem('p-1', () => Promise.resolve({ body: 'x' }))
    await flush()
    expect(getToolkitQueryClient().getQueryData(['resource-item', 't1', 'projects', 'p-1'])).toEqual({
      body: 'x',
    })
  })

  it('resource-data-042 with no item id the load is never invoked', async () => {
    signInAs('t1')
    const load = vi.fn(() => Promise.resolve({ body: 'x' }))
    useItem(null, load)
    await flush()
    expect(load).not.toHaveBeenCalled()
  })

  it('resource-data-043 a failed load is reported by default, naming feature, step and cache key', async () => {
    signInAs('t1')
    const boom = new Error('item load failed 043')
    const { result } = useItem('p-1', () => Promise.reject(boom))
    await flush()
    expect(reporter).toHaveBeenCalledTimes(1)
    expect(reporter).toHaveBeenCalledWith(boom, {
      feature: 'resource-item',
      step: 'load',
      basePath: 'projects',
    })
    expect(result.current.error).toBe('item load failed 043')
  })

  it('resource-data-044 with reportErrors false a failure is not reported but still propagates', async () => {
    signInAs('t1')
    const { result } = useItem('p-1', () => Promise.reject(new Error('item load failed 044')), {
      reportErrors: false,
    })
    await flush()
    expect(reporter).not.toHaveBeenCalled()
    expect(result.current.error).toBe('item load failed 044')
  })

  it('resource-data-045 a failed load is not retried', async () => {
    signInAs('t1')
    const load = vi.fn(() => Promise.reject(new Error('item load failed 045')))
    const { result } = useItem('p-1', load, { reportErrors: false })
    await flush()
    await new Promise((r) => setTimeout(r, 50))
    expect(load).toHaveBeenCalledTimes(1)
    expect(result.current.error).toBe('item load failed 045')
  })

  it('resource-data-046 the entry retains for the 30-minute resource gc time', async () => {
    signInAs('t1')
    useItem('p-1', () => Promise.resolve({ body: 'x' }))
    await flush()
    const query = getToolkitQueryClient()
      .getQueryCache()
      .find({ queryKey: ['resource-item', 't1', 'projects', 'p-1'] })
    expect(RESOURCE_GC_TIME).toBe(1_800_000)
    expect(query?.gcTime).toBe(1_800_000)
  })

  it('resource-data-047 a seed shows while the load is pending and the item is not settled', () => {
    signInAs('t1')
    const { result } = useItem('p-1', () => new Promise(() => {}), { seedFrom: () => ({ body: 'seed' }) })
    expect(result.current.item).toEqual({ body: 'seed' })
    expect(result.current.isSettled).toBe(false)
  })

  it('resource-data-048 settled stays true through a background refresh', async () => {
    signInAs('t1')
    let calls = 0
    let release!: () => void
    const load = () =>
      ++calls === 1
        ? Promise.resolve({ body: 'first' })
        : new Promise<Doc>((r) => (release = () => r({ body: 'second' })))
    const { result } = useItem('p-1', load)
    await flush()
    expect(result.current.isSettled).toBe(true)

    let reloading!: Promise<void>
    act(() => {
      reloading = result.current.reload()
    })
    expect(result.current.isFetching).toBe(true)
    expect(result.current.isSettled).toBe(true)
    await act(async () => {
      release()
      await reloading
    })
    expect(result.current.isSettled).toBe(true)
    expect(result.current.item).toEqual({ body: 'second' })
  })

  it('resource-data-049 a not-found failure sets isMissing', async () => {
    signInAs('t1')
    const { result } = useItem('p-1', () => Promise.reject(notFound()))
    await flush()
    expect(result.current.isMissing).toBe(true)
  })

  it('resource-data-050 a non-Error failure reads as "Failed to load."', async () => {
    signInAs('t1')
    const { result } = useItem('p-1', () => Promise.reject('plain string'), { reportErrors: false })
    await flush()
    expect(result.current.error).toBe('Failed to load.')
  })

  it('resource-data-051 reload with no id re-runs the read and load receives the absent id', async () => {
    signInAs('t1')
    const load = vi.fn((_id: string) => Promise.resolve({ body: 'x' }))
    const { result } = useItem(null, load)
    await flush()
    expect(load).not.toHaveBeenCalled()
    await act(async () => {
      await result.current.reload()
    })
    expect(load).toHaveBeenCalledTimes(1)
    expect(load.mock.calls[0]![0]).toBeNull()
  })

  it('resource-data-052 the writer writes a non-null row into the cache', () => {
    signInAs('t1')
    const { result } = renderHook(() => useResourceItemWriter<Doc>('projects'))
    act(() => result.current('p-1', { body: 'row' }))
    expect(getToolkitQueryClient().getQueryData(['resource-item', 't1', 'projects', 'p-1'])).toEqual({
      body: 'row',
    })
  })

  it('resource-data-053 the writer evicts the entry for a null value', () => {
    signInAs('t1')
    const client = getToolkitQueryClient()
    const { result } = renderHook(() => useResourceItemWriter<Doc>('projects'))
    act(() => result.current('p-1', { body: 'row' }))
    act(() => result.current('p-1', null))
    expect(client.getQueryCache().find({ queryKey: ['resource-item', 't1', 'projects', 'p-1'] })).toBeUndefined()
  })

  it('resource-data-054 prefetch never raises when the load fails', async () => {
    signInAs('t1')
    const { result } = renderHook(() =>
      useResourceItemPrefetch<Doc>('projects', () => Promise.reject(new Error('prefetch failed 054'))),
    )
    let returned: unknown = 'unset'
    expect(() => {
      returned = result.current('p-1')
    }).not.toThrow()
    expect(returned).toBeUndefined()
    await flush()
    await new Promise((r) => setTimeout(r, 20))
  })

  it('resource-data-055 prefetch cleanup leaves an entry that succeeded in the meantime', async () => {
    signInAs('t1')
    const client = getToolkitQueryClient()
    const key = ['resource-item', 't1', 'projects', 'p-1']
    // The instant the prefetch's failure lands in the shared entry, a concurrent reader's
    // successful load writes its answer there; the cleanup that runs a few microtasks later must
    // then find a healthy entry and leave it alone.
    const stop = client.getQueryCache().subscribe((event) => {
      if (event.type === 'updated' && event.action.type === 'error') {
        client.setQueryData(key, { body: 'from the mount' })
      }
    })
    const { result } = renderHook(() =>
      useResourceItemPrefetch<Doc>('projects', () => Promise.reject(new Error('prefetch failed 055'))),
    )
    result.current('p-1')
    await flush()
    await new Promise((r) => setTimeout(r, 20))
    stop()
    expect(client.getQueryState(key)?.status).toBe('success')
    expect(client.getQueryData(key)).toEqual({ body: 'from the mount' })
  })
})
