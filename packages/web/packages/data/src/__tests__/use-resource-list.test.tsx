/// <reference types="@testing-library/jest-dom/vitest" />
import { render, renderHook, screen, waitFor, cleanup, act } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { notifyManager } from '@tanstack/react-query'
import { setAuthErrorReporter } from '@adh-sdk/auth'
import { useResourceList, revalidateResources, makeEntityDeleteHandler } from '../use-resource-list'
import { readLastId, writeLastId } from '../ftd-storage'
import { RESOURCE_GC_TIME, getToolkitQueryClient } from '../query'

// Notify observers SYNCHRONOUSLY. react-query's default scheduler is a real `setTimeout(fn, 0)` —
// it batches notifications into a macrotask — and `act(async …)` drains microtasks only, so a
// render driven by a settled query has NOT happened when `await act(…)` returns. Without this the
// assertions below would each have to become a `waitFor`, which is strictly weaker: `waitFor` also
// passes on the value already on screen, so it cannot catch a stale response arriving one tick
// late — the exact defect the out-of-order tests exist to pin.
notifyManager.setScheduler((cb) => cb())

// Drive the module cache's tenant scoping through the real path: the cache is
// keyed by the current access token's `ecosystem_id`, which useResourceList
// reads via useTenantId → readAccessToken → localStorage['auth_tokens']. Set the
// token, then the cache scope follows.
const base64url = (json: string) =>
  btoa(json).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
const tokenForTenant = (id: string) => `x.${base64url(JSON.stringify({ ecosystem_id: id }))}.y`
const signInAs = (tenant: string) =>
  localStorage.setItem('auth_tokens', JSON.stringify({ accessToken: tokenForTenant(tenant) }))

function Probe({ cacheKey, load }: { cacheKey: string; load: () => Promise<string[]> }) {
  const { items } = useResourceList(cacheKey, load)
  return <div data-testid="items">{items === null ? 'null' : items.join(',')}</div>
}

afterEach(() => {
  cleanup()
  // The cache now outlives a single test (that is the point of it). Clear it so one test's rows
  // can never seed another's first paint.
  getToolkitQueryClient().clear()
  localStorage.clear()
})

describe('useResourceList cache scoping', () => {
  it('seeds a remount from the cache only when the tenant scope matches', async () => {
    const cacheKey = '/scoped-things'

    // Mount 1 (tenant A): resolve rows so the module cache records scope A.
    signInAs('A')
    render(<Probe cacheKey={cacheKey} load={() => Promise.resolve(['a1', 'a2'])} />)
    await waitFor(() => expect(screen.getByTestId('items')).toHaveTextContent('a1,a2'))
    cleanup()

    // Mount 2 (SAME tenant A): the first paint must seed from the cache — assert
    // synchronously before the (pending) refetch could change anything.
    signInAs('A')
    render(<Probe cacheKey={cacheKey} load={() => new Promise<string[]>(() => {})} />)
    expect(screen.getByTestId('items')).toHaveTextContent('a1,a2')
    cleanup()

    // Mount 3 (DIFFERENT tenant B): the cached scope-A rows must be REJECTED —
    // no seed, so the first paint is the loading (null) state, not B reading A's rows.
    signInAs('B')
    render(<Probe cacheKey={cacheKey} load={() => new Promise<string[]>(() => {})} />)
    expect(screen.getByTestId('items')).toHaveTextContent('null')
  })
})

// `isFetching` answers "have I seen the server's answer yet", which `items` cannot: a cache seed
// makes it non-null before any read has landed. A caller that CONCLUDES something from a row being
// absent — the family's shell 404s an unknown workspace — is wrong for exactly as long as that gap
// lasts, so these pin both ends of it.
describe('useResourceList settled flag', () => {
  function FlagProbe({ cacheKey, load }: { cacheKey: string; load: () => Promise<string[]> }) {
    const { items, isFetching } = useResourceList(cacheKey, load)
    return (
      <div data-testid="items" data-fetching={isFetching}>
        {items === null ? 'null' : items.join(',')}
      </div>
    )
  }

  it('is true on a SEEDED first paint whose rows are STALE, so they are not read as the server’s answer', async () => {
    const cacheKey = '/settled-seed'
    signInAs('A')
    render(<FlagProbe cacheKey={cacheKey} load={() => Promise.resolve(['a1'])} />)
    await waitFor(() => expect(screen.getByTestId('items')).toHaveAttribute('data-fetching', 'false'))
    cleanup()

    // Mark the cached rows stale — what a live wake does, and what the passage of `staleTime`
    // does. This step is the behaviour change: rows that are still FRESH now paint with
    // `isFetching` FALSE, because they ARE the server's answer from under five minutes ago, and
    // re-reading them is the round trip this whole change exists to remove.
    revalidateResources(() => true)

    // The remount that matters: rows on screen from the first render, and nothing settled yet.
    signInAs('A')
    render(<FlagProbe cacheKey={cacheKey} load={() => new Promise<string[]>(() => {})} />)
    expect(screen.getByTestId('items')).toHaveTextContent('a1')
    expect(screen.getByTestId('items')).toHaveAttribute('data-fetching', 'true')
  })

  it('clears on a FAILED read too — settled is not the same as successful', async () => {
    signInAs('A')
    render(<FlagProbe cacheKey="/settled-fail" load={() => Promise.reject(new Error('boom'))} />)
    // Left true, a failing list would look permanently in-flight and every caller waiting on it
    // would wait forever — the shell's error branch included.
    await waitFor(() => expect(screen.getByTestId('items')).toHaveAttribute('data-fetching', 'false'))
  })
})

// The reload-after-write pattern (mutate, then `reload()`) routinely has two GETs in flight at
// once, and nothing makes the earlier one land first. These pin the rule that decides who wins:
// the most recently ISSUED request, never the last to arrive.
describe('useResourceList out-of-order responses', () => {
  /** A probe that exposes `reload` so a test can fire overlapping ones. */
  function ReloadProbe({
    cacheKey,
    load,
    onReady,
  }: {
    cacheKey: string
    load: () => Promise<string[]>
    onReady: (reload: () => Promise<void>) => void
  }) {
    const { items, reload } = useResourceList(cacheKey, load)
    onReady(reload)
    return <div data-testid="items">{items === null ? 'null' : items.join(',')}</div>
  }

  /** A load() whose responses are settled by hand, in whatever order a test wants. `settle(n)`
   *  resolves the n-th call (0 = the mount fetch) and names the call if it never happened,
   *  rather than failing as a TypeError on an undefined resolver. */
  function pendingLoads() {
    const resolvers: ((rows: string[]) => void)[] = []
    return {
      load: () => new Promise<string[]>((res) => resolvers.push(res)),
      settle: (n: number, rows: string[]) => {
        const res = resolvers[n]
        if (!res) throw new Error(`load() call #${n} was never made (${resolvers.length} so far)`)
        res(rows)
      },
    }
  }

  it('drops an overtaken response instead of reverting the list', async () => {
    signInAs('A')
    const { load, settle } = pendingLoads()

    let reload!: () => Promise<void>
    render(
      <ReloadProbe cacheKey="/ooo" load={load} onReady={(r) => (reload = r)} />,
    )

    // Settle the mount fetch so the assertions below are about the reloads alone.
    await act(async () => settle(0, ['seed']))
    expect(screen.getByTestId('items')).toHaveTextContent('seed')

    // Two reloads issued in order — the caller's mental model is "after the delete" then
    // "after the second delete".
    const first = reload()
    const second = reload()

    // …resolved out of order: the NEWER request lands first with the true state…
    await act(async () => settle(2, ['final']))
    expect(screen.getByTestId('items')).toHaveTextContent('final')

    // …and the older one lands last, carrying rows the server has already moved past.
    await act(async () => settle(1, ['stale', 'rows']))
    expect(screen.getByTestId('items')).toHaveTextContent('final')

    // Both promises still settle for their own callers.
    await act(async () => {
      await Promise.all([first, second])
    })
  })

  it('does not leave the overtaken rows in the cache for the next mount to seed from', async () => {
    signInAs('A')
    const { load, settle } = pendingLoads()

    let reload!: () => Promise<void>
    render(
      <ReloadProbe cacheKey="/ooo-cache" load={load} onReady={(r) => (reload = r)} />,
    )
    await act(async () => settle(0, ['seed']))

    const first = reload()
    const second = reload()
    await act(async () => settle(2, ['final']))
    await act(async () => settle(1, ['stale']))
    await act(async () => {
      await Promise.all([first, second])
    })
    cleanup()

    // A remount seeds from the module cache. If the losing response had written it, the stale
    // rows would reappear here — the same defect, one navigation later.
    signInAs('A')
    render(<Probe cacheKey="/ooo-cache" load={() => new Promise<string[]>(() => {})} />)
    expect(screen.getByTestId('items')).toHaveTextContent('final')
  })
})

// A new `load` identity is a documented API — "re-read, the fetcher changed" — and it is the only
// way a caller can say so, since the query key names the RESOURCE and does not move when the scope
// the fetcher closes over does. Both shapes below are in the fleet.
describe('useResourceList refetch on fetcher identity change', () => {
  it('re-reads with the NEW fetcher when the first read is still outstanding', async () => {
    // The shape a feature uses to avoid flashing the unscoped set: hold the list in Loading with a
    // promise that never settles until the slug resolves to an id, then swap in the real fetcher.
    // react-query cancels an in-flight read only when the query already HAS data, so left to
    // itself it adopts the promise that never settles and the list loads forever.
    signInAs('A')
    const never = () => new Promise<string[]>(() => {})
    const scoped = vi.fn(() => Promise.resolve(['scoped']))

    const { rerender } = render(<Probe cacheKey="/late-scope" load={never} />)
    expect(screen.getByTestId('items')).toHaveTextContent('null')

    rerender(<Probe cacheKey="/late-scope" load={scoped} />)

    await waitFor(() => expect(screen.getByTestId('items')).toHaveTextContent('scoped'))
    expect(scoped).toHaveBeenCalledTimes(1)
  })

  it('re-reads with the new fetcher after rows have already landed', async () => {
    // The filter swap: rows are on screen, the fetcher changes, and the rows that replace them
    // must come from the NEW one. Nothing else in the hook's surface can express this — the key
    // is the same list either way.
    signInAs('A')
    const unfiltered = vi.fn(() => Promise.resolve(['all']))
    const filtered = vi.fn(() => Promise.resolve(['mine']))

    const { rerender } = render(<Probe cacheKey="/filtered" load={unfiltered} />)
    await waitFor(() => expect(screen.getByTestId('items')).toHaveTextContent('all'))

    rerender(<Probe cacheKey="/filtered" load={filtered} />)

    await waitFor(() => expect(screen.getByTestId('items')).toHaveTextContent('mine'))
    expect(unfiltered).toHaveBeenCalledTimes(1)
    expect(filtered).toHaveBeenCalledTimes(1)
  })

  it('does not re-read when the fetcher identity is unchanged', async () => {
    // The other half of the contract: a re-render alone is not a reason to hit the network, or
    // every parent state change on the page would cost one request per mounted list.
    signInAs('A')
    const load = vi.fn(() => Promise.resolve(['rows']))

    const { rerender } = render(<Probe cacheKey="/stable" load={load} />)
    await waitFor(() => expect(screen.getByTestId('items')).toHaveTextContent('rows'))

    rerender(<Probe cacheKey="/stable" load={load} />)
    rerender(<Probe cacheKey="/stable" load={load} />)

    expect(load).toHaveBeenCalledTimes(1)
  })
})

// `revalidateResources` is how a live stream reaches lists it holds no reference to. What must
// hold: it re-reads exactly the MOUNTED lists whose key the predicate accepts — a pane nobody is
// looking at must not fetch (a wake would otherwise cost a request per list ever rendered), and a
// list the predicate rejects must not either (that is the whole basis for scoping a board's wake
// to the board's own keys).
describe('revalidateResources', () => {
  it('re-reads a matching mounted list, leaves a non-matching one alone', async () => {
    signInAs('A')
    const hit = vi.fn(() => Promise.resolve(['hit']))
    const miss = vi.fn(() => Promise.resolve(['miss']))

    render(
      <>
        <Probe cacheKey="project:p1:work-items" load={hit} />
        <Probe cacheKey="workspace:w:templates" load={miss} />
      </>,
    )
    await waitFor(() => expect(screen.getAllByTestId('items')[0]).toHaveTextContent('hit'))
    expect(hit).toHaveBeenCalledTimes(1)
    expect(miss).toHaveBeenCalledTimes(1)

    await act(async () => {
      revalidateResources((key) => key.startsWith('project:p1:'))
    })

    expect(hit).toHaveBeenCalledTimes(2)
    expect(miss).toHaveBeenCalledTimes(1)
  })

  it('does not fetch for a list that has unmounted', async () => {
    signInAs('A')
    const load = vi.fn(() => Promise.resolve(['rows']))

    render(<Probe cacheKey="project:p2:work-items" load={load} />)
    await waitFor(() => expect(screen.getByTestId('items')).toHaveTextContent('rows'))
    cleanup()

    await act(async () => {
      revalidateResources(() => true)
    })

    expect(load).toHaveBeenCalledTimes(1)
  })

  it('survives a list whose re-read rejects', async () => {
    signInAs('A')
    const boom = vi.fn(() => Promise.reject(new Error('gone')))
    const ok = vi.fn(() => Promise.resolve(['ok']))

    render(
      <>
        <Probe cacheKey="project:p3:a" load={boom} />
        <Probe cacheKey="project:p3:b" load={ok} />
      </>,
    )
    await waitFor(() => expect(ok).toHaveBeenCalledTimes(1))

    // A wake is fire-and-forget: one failing list must neither throw at the caller nor stop the
    // others from re-reading, and must not surface as an unhandled rejection.
    await act(async () => {
      expect(() => revalidateResources((key) => key.startsWith('project:p3:'))).not.toThrow()
    })

    expect(boom).toHaveBeenCalledTimes(2)
    expect(ok).toHaveBeenCalledTimes(2)
  })
})

// Conformance vectors for resource-data (cookbook/data/services/resource-data).
describe('resource-list conformance', () => {
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

  const mountList = <T,>(cacheKey: string, load: () => Promise<T[]>, opts?: { reportErrors?: boolean }) =>
    renderHook((p: { load: () => Promise<T[]> }) => useResourceList<T>(cacheKey, p.load, opts), {
      initialProps: { load },
    })
  const flush = () => act(async () => {})

  it('resource-data-056 the list cache key is ("resource-list", tenant, cacheKey)', async () => {
    signInAs('t1')
    mountList('projects', () => Promise.resolve(['a']))
    await flush()
    expect(getToolkitQueryClient().getQueryData(['resource-list', 't1', 'projects'])).toEqual(['a'])
  })

  it('resource-data-057 revalidateResources invalidates every entry whose key matches', async () => {
    signInAs('t1')
    const workspaces = vi.fn(() => Promise.resolve(['w']))
    const other = vi.fn(() => Promise.resolve(['o']))
    mountList('workspaces', workspaces)
    mountList('organizations', other)
    await flush()
    await act(async () => revalidateResources((key) => key === 'workspaces'))
    expect(workspaces).toHaveBeenCalledTimes(2)
    expect(other).toHaveBeenCalledTimes(1)
  })

  it('resource-data-058 a failed load is reported by default, naming feature, step and cache key', async () => {
    signInAs('t1')
    const boom = new Error('list load failed 058')
    mountList('projects', () => Promise.reject(boom))
    await flush()
    expect(reporter).toHaveBeenCalledTimes(1)
    expect(reporter).toHaveBeenCalledWith(boom, {
      feature: 'resource-list',
      step: 'load',
      basePath: 'projects',
    })
  })

  it('resource-data-059 a failed load is not retried', async () => {
    signInAs('t1')
    const load = vi.fn(() => Promise.reject(new Error('list load failed 059')))
    mountList('projects', load, { reportErrors: false })
    await flush()
    await new Promise((r) => setTimeout(r, 50))
    expect(load).toHaveBeenCalledTimes(1)
  })

  it('resource-data-060 the entry retains for the 30-minute resource gc time', async () => {
    signInAs('t1')
    mountList('projects', () => Promise.resolve(['a']))
    await flush()
    const query = getToolkitQueryClient()
      .getQueryCache()
      .find({ queryKey: ['resource-list', 't1', 'projects'] })
    expect(RESOURCE_GC_TIME).toBe(1_800_000)
    expect(query?.gcTime).toBe(1_800_000)
  })

  it('resource-data-061 the same load identity across renders causes no cancel or refresh', async () => {
    signInAs('t1')
    const load = vi.fn(() => Promise.resolve(['a']))
    const cancel = vi.spyOn(getToolkitQueryClient(), 'cancelQueries')
    const { rerender } = mountList('projects', load)
    await flush()
    rerender({ load })
    rerender({ load })
    await flush()
    expect(cancel).not.toHaveBeenCalled()
    expect(load).toHaveBeenCalledTimes(1)
  })

  it('resource-data-062 a new load identity with the same key and tenant cancels and refreshes', async () => {
    signInAs('t1')
    const first = vi.fn(() => Promise.resolve(['first']))
    const second = vi.fn(() => Promise.resolve(['second']))
    const cancel = vi.spyOn(getToolkitQueryClient(), 'cancelQueries')
    const { result, rerender } = mountList('projects', first)
    await flush()
    rerender({ load: second })
    await flush()
    expect(cancel).toHaveBeenCalledTimes(1)
    expect(second).toHaveBeenCalledTimes(1)
    expect(result.current.items).toEqual(['second'])
  })

  it('resource-data-063 reload rejects with the same error the refresh resolved with', async () => {
    signInAs('t1')
    const boom = new Error('list load failed 063')
    const { result } = mountList('projects', () => Promise.reject(boom), { reportErrors: false })
    await flush()
    await act(async () => {
      await expect(result.current.reload()).rejects.toBe(boom)
    })
  })

  it('resource-data-064 setItems writes the rows straight into the cache', async () => {
    signInAs('t1')
    const { result } = mountList<string>('projects', () => Promise.resolve(['a']))
    await flush()
    act(() => result.current.setItems(['x', 'y']))
    expect(getToolkitQueryClient().getQueryData(['resource-list', 't1', 'projects'])).toEqual(['x', 'y'])
    expect(result.current.items).toEqual(['x', 'y'])
    act(() => result.current.setItems((prev) => [...(prev ?? []), 'z']))
    expect(result.current.items).toEqual(['x', 'y', 'z'])
  })

  it('resource-data-065 isFetching is true while the first read is pending', () => {
    signInAs('t1')
    const { result } = mountList('projects', () => new Promise<string[]>(() => {}))
    expect(result.current.items).toBeNull()
    expect(result.current.isFetching).toBe(true)
  })

  it('resource-data-066 errorStatus carries the status of a conflict failure', async () => {
    signInAs('t1')
    const { result } = mountList(
      'projects',
      () => Promise.reject(Object.assign(new Error('conflict'), { status: 409 })),
      { reportErrors: false },
    )
    await flush()
    expect(result.current.errorStatus).toBe(409)
  })

  it('resource-data-067 a non-Error failure reads as "Failed to load."', async () => {
    signInAs('t1')
    const { result } = mountList('projects', () => Promise.reject({ nope: true }), { reportErrors: false })
    await flush()
    expect(result.current.error).toBe('Failed to load.')
    expect(result.current.errorStatus).toBeNull()
  })
})

describe('makeEntityDeleteHandler', () => {
  const setup = (over: { del?: () => Promise<void>; reload?: () => Promise<void> } = {}) => {
    const order: string[] = []
    const router = { push: vi.fn((href: string) => order.push(`push ${href}`)) }
    const del = vi.fn(over.del ?? (() => Promise.resolve()))
    const reload = vi.fn(
      over.reload ??
        (() => {
          order.push('reload')
          return Promise.resolve()
        }),
    )
    const handler = makeEntityDeleteHandler({ basePath: '/projects', id: 'p-1', router, del, reload })
    return { order, router, del, reload, handler }
  }

  it('resource-data-068 clears the matching last id, then navigates to the all view, then reloads', async () => {
    writeLastId('/projects', 'p-1')
    const { order, router, handler } = setup()
    const origPush = router.push.getMockImplementation()!
    let lastIdAtPush: string | null | undefined
    router.push.mockImplementation((href: string) => {
      lastIdAtPush = readLastId('/projects')
      return origPush(href)
    })
    await handler()
    expect(lastIdAtPush).toBeNull()
    expect(readLastId('/projects')).toBeNull()
    expect(router.push).toHaveBeenCalledWith('/projects/all', { scroll: false })
    expect(order).toEqual(['push /projects/all', 'reload'])
    localStorage.clear()
  })

  it('resource-data-069 leaves a different last id alone; still navigates and reloads', async () => {
    writeLastId('/projects', 'other')
    const { router, reload, handler } = setup()
    await handler()
    expect(readLastId('/projects')).toBe('other')
    expect(router.push).toHaveBeenCalledTimes(1)
    expect(reload).toHaveBeenCalledTimes(1)
    localStorage.clear()
  })

  it('resource-data-070 a failing delete rejects the handler and never navigates', async () => {
    const boom = new Error('delete failed')
    const { router, reload, handler } = setup({ del: () => Promise.reject(boom) })
    await expect(handler()).rejects.toBe(boom)
    expect(router.push).not.toHaveBeenCalled()
    expect(reload).not.toHaveBeenCalled()
  })

  it('resource-data-071 a failing reload is swallowed and the handler resolves', async () => {
    const { router, handler } = setup({ reload: () => Promise.reject(new Error('reload failed')) })
    await expect(handler()).resolves.toBeUndefined()
    expect(router.push).toHaveBeenCalledTimes(1)
  })
})
