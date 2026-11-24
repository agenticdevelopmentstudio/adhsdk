import { describe, it, expect, vi, beforeEach } from 'vitest'
import { act, renderHook, waitFor } from '@testing-library/react'
import { itemUrl, listUrl, rowKey, useCrudResource } from '../useCrudResource'
import type { CrudTableMeta } from '../types'

vi.mock('@adh-sdk/auth/client', () => ({
  authedJson: vi.fn(),
  listAllV1: vi.fn(),
}))

// Lists walk the whole collection through `listAllV1`; writes go through `authedJson`.
const { authedJson, listAllV1 } = vi.mocked(await import('@adh-sdk/auth/client'))

const tiers: CrudTableMeta = {
  key: 'billing/subscription-tiers',
  schema: 'billing',
  table: 'subscription-tiers',
  basePath: '/v1/billing/subscription_tiers',
  itemPath: '/v1/billing/subscription_tiers/{id}',
  pkParams: ['id'],
  exposure: 'owner',
  columns: [],
}

const links: CrudTableMeta = {
  key: 'persona-memory/links',
  schema: 'persona-memory',
  table: 'links',
  basePath: '/v1/persona_memory/links',
  itemPath: '/v1/persona_memory/links/{src_id}/{dst_id}/{relation}',
  pkParams: ['src_id', 'dst_id', 'relation'],
  exposure: 'owner',
  columns: [],
}

beforeEach(() => {
  authedJson.mockReset()
  listAllV1.mockReset()
})

describe('itemUrl', () => {
  it('substitutes a single id, URL-encoded', () => {
    expect(itemUrl(tiers, { id: 'a b' })).toBe('/api/v1/billing/subscription_tiers/a%20b')
  })
  it('substitutes composite primary keys in order', () => {
    expect(itemUrl(links, { src_id: 's1', dst_id: 'd1', relation: 'rel/x' })).toBe(
      '/api/v1/persona_memory/links/s1/d1/rel%2Fx',
    )
  })
})

describe('rowKey', () => {
  it('joins escaped pk values (same escaping as itemUrl)', () => {
    expect(rowKey(links, { src_id: 's1', dst_id: 'd1', relation: 'rel/x' })).toBe('s1/d1/rel%2Fx')
  })
  it('is empty when a single-pk row carries no value (caller falls back)', () => {
    expect(rowKey(tiers, {})).toBe('')
  })
})

// All Data's has-rows probe builds its URL with this, so it must be the very URL the hook lists.
describe('listUrl', () => {
  it('is the URL the hook lists from, scope first, then the filter', async () => {
    listAllV1.mockResolvedValueOnce([])
    const { result } = renderHook(() =>
      useCrudResource(tiers, { source_provider: 'reddit' }, 'eco-1'),
    )
    await waitFor(() => expect(result.current.loading).toBe(false))
    const url = listUrl(tiers, { source_provider: 'reddit' }, 'eco-1')
    expect(url).toBe('/api/v1/billing/subscription_tiers?ecosystem_id=eco-1&source_provider=reddit')
    expect(listAllV1).toHaveBeenCalledWith(url)
  })
  it('has no query string with neither a filter nor a scope', () => {
    expect(listUrl(tiers, {})).toBe('/api/v1/billing/subscription_tiers')
  })
})

describe('useCrudResource', () => {
  it('lists on mount through the /api proxy', async () => {
    listAllV1.mockResolvedValueOnce([{ id: '1' }])
    const { result } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(listAllV1).toHaveBeenCalledWith('/api/v1/billing/subscription_tiers')
    expect(result.current.rows).toEqual([{ id: '1' }])
    expect(result.current.error).toBeNull()
  })

  it('surfaces the list error message', async () => {
    listAllV1.mockRejectedValueOnce(new Error('Service unavailable'))
    const { result } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(result.current.error).toBe('Service unavailable')
    expect(result.current.rows).toEqual([])
  })

  it('creates with POST + JSON body, then re-lists', async () => {
    listAllV1.mockResolvedValue([])
    authedJson.mockResolvedValue({})
    const { result } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(result.current.loading).toBe(false))
    await act(() => result.current.create({ key: 'pro', name: 'Pro' }))
    expect(authedJson).toHaveBeenCalledWith('/api/v1/billing/subscription_tiers', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key: 'pro', name: 'Pro' }),
    })
    expect(authedJson).toHaveBeenCalledTimes(1) // the POST
    expect(listAllV1).toHaveBeenCalledTimes(2) // mount list + refresh list
  })

  it('updates with POST at the row item path', async () => {
    listAllV1.mockResolvedValue([])
    authedJson.mockResolvedValue({})
    const { result } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(result.current.loading).toBe(false))
    await act(() => result.current.update({ id: 't1' }, { name: 'New name' }))
    expect(authedJson).toHaveBeenCalledWith('/api/v1/billing/subscription_tiers/t1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'New name' }),
    })
  })

  it('deletes with authedJson (200 tombstone), then re-lists', async () => {
    listAllV1.mockResolvedValue([])
    authedJson.mockResolvedValue({})
    const { result } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(result.current.loading).toBe(false))
    await act(() => result.current.remove({ id: 't1' }))
    expect(authedJson).toHaveBeenCalledWith('/api/v1/billing/subscription_tiers/t1', {
      method: 'DELETE',
    })
    expect(listAllV1).toHaveBeenCalledTimes(2) // mount + refresh
  })

  it('keeps rows rendered (loading stays false) on refreshes after the first load', async () => {
    listAllV1.mockResolvedValueOnce([{ id: '1' }])
    const { result } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(result.current.loading).toBe(false))
    let resolveList!: (rows: unknown) => void
    listAllV1.mockImplementationOnce(
      () => new Promise((resolve) => { resolveList = resolve }) as never,
    )
    let refreshing!: Promise<void>
    act(() => {
      refreshing = result.current.refresh()
    })
    // the re-list is in flight, but the table must NOT swap to a spinner
    expect(result.current.loading).toBe(false)
    expect(result.current.rows).toEqual([{ id: '1' }])
    await act(async () => {
      resolveList([{ id: '1' }, { id: '2' }])
      await refreshing
    })
    expect(result.current.rows).toEqual([{ id: '1' }, { id: '2' }])
  })

  it('keeps stale rows visible when a refresh after the first load fails', async () => {
    listAllV1.mockResolvedValueOnce([{ id: '1' }])
    const { result } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(result.current.loading).toBe(false))
    listAllV1.mockRejectedValueOnce(new Error('Service unavailable'))
    await act(() => result.current.refresh())
    expect(result.current.error).toBe('Service unavailable')
    expect(result.current.rows).toEqual([{ id: '1' }])
  })

  it('propagates mutation failures to the caller (no hook-level error)', async () => {
    listAllV1.mockResolvedValueOnce([]) // mount list
    const { result } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(result.current.loading).toBe(false))
    authedJson.mockRejectedValueOnce(new Error('key already exists'))
    await expect(
      act(() => result.current.create({ key: 'dup' })),
    ).rejects.toThrow('key already exists')
    expect(result.current.error).toBeNull()
  })
})

describe('useCrudResource fetching', () => {
  // `loading` deliberately goes quiet after the first list so the table keeps its rows instead of
  // flashing a spinner. That makes it the wrong flag to report a read upward with — a pane that
  // reported it would light the topic list's spinner on the first visit only, and stay silent for
  // every re-list and every table switch after. `fetching` is the flag those need, so these say
  // what it does at exactly the moments `loading` says nothing.

  /** A list call the test resolves by hand. */
  function deferredList(): { resolve: (rows: unknown) => void } {
    const handle = { resolve: (_: unknown) => {} }
    listAllV1.mockImplementationOnce(
      () => new Promise((resolve) => { handle.resolve = resolve }) as never,
    )
    return handle
  }

  it('is true while the first list is open and false once it lands', async () => {
    const first = deferredList()
    const { result } = renderHook(() => useCrudResource(tiers))
    expect(result.current.fetching).toBe(true)
    await act(async () => { first.resolve([{ id: '1' }]) })
    expect(result.current.fetching).toBe(false)
  })

  it('stays true through a re-list, the one `loading` sits out', async () => {
    listAllV1.mockResolvedValueOnce([{ id: '1' }])
    const { result } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(result.current.loading).toBe(false))

    const again = deferredList()
    let refreshing!: Promise<void>
    act(() => { refreshing = result.current.refresh() })
    // The divergence this flag exists for: the rows stay on screen (`loading` false) while a
    // request is genuinely open (`fetching` true).
    expect(result.current.loading).toBe(false)
    expect(result.current.fetching).toBe(true)

    await act(async () => {
      again.resolve([{ id: '1' }, { id: '2' }])
      await refreshing
    })
    expect(result.current.fetching).toBe(false)
  })

  it('goes true again when the table SWITCHES under a live hook', async () => {
    // The switch is the case `loading` is keyed per-list FOR: `loadedFor` holds which list the
    // rows on screen came from, so a different table has loaded nothing and the skeleton is right
    // to come back. (A mount-scoped `hasLoaded` boolean was what left the PREVIOUS table's rows
    // sitting under the new table's header.) `fetching` is true here too — it is true for BOTH
    // this and the re-list above, which is why it is the flag a pane reports upward with.
    listAllV1.mockResolvedValueOnce([{ id: '1' }])
    const { result, rerender } = renderHook(({ meta }) => useCrudResource(meta), {
      initialProps: { meta: tiers },
    })
    await waitFor(() => expect(result.current.fetching).toBe(false))

    const switched = deferredList()
    rerender({ meta: links })
    expect(result.current.loading).toBe(true)
    expect(result.current.fetching).toBe(true)

    await act(async () => { switched.resolve([]) })
    expect(result.current.fetching).toBe(false)
  })

  it('is not cleared by a SUPERSEDED list landing after a newer one started', async () => {
    // Same out-of-order guard the row write has. Without it, a slow first table answering after the
    // user moved on would report the second table's still-open read as finished.
    listAllV1.mockResolvedValueOnce([{ id: '1' }])
    const { result, rerender } = renderHook(({ meta }) => useCrudResource(meta), {
      initialProps: { meta: tiers },
    })
    await waitFor(() => expect(result.current.fetching).toBe(false))

    const stale = deferredList()
    rerender({ meta: links })
    const current = deferredList()
    rerender({ meta: tiers })
    expect(result.current.fetching).toBe(true)

    await act(async () => { stale.resolve([{ id: 'stale' }]) })
    expect(result.current.fetching).toBe(true)
    expect(result.current.rows).toEqual([{ id: '1' }])

    await act(async () => { current.resolve([{ id: 'fresh' }]) })
    expect(result.current.fetching).toBe(false)
    expect(result.current.rows).toEqual([{ id: 'fresh' }])
  })

  it('is false after a list FAILS, so a broken read cannot leave a spinner turning', async () => {
    listAllV1.mockRejectedValueOnce(new Error('Service unavailable'))
    const { result } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(result.current.error).toBe('Service unavailable'))
    expect(result.current.fetching).toBe(false)
  })
})

describe('useCrudResource filter', () => {
  it('appends the filter as a query string to the list call', async () => {
    listAllV1.mockResolvedValueOnce([])
    const { result } = renderHook(() => useCrudResource(tiers, { source_provider: 'reddit' }))
    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(listAllV1).toHaveBeenCalledWith('/api/v1/billing/subscription_tiers?source_provider=reddit')
  })

  it('omits the query string for an empty filter object', async () => {
    listAllV1.mockResolvedValueOnce([])
    const { result } = renderHook(() => useCrudResource(tiers, {}))
    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(listAllV1).toHaveBeenCalledWith('/api/v1/billing/subscription_tiers')
  })

  it('URL-encodes filter keys and values', async () => {
    listAllV1.mockResolvedValueOnce([])
    const { result } = renderHook(() => useCrudResource(tiers, { external_ref: 'a b/c&d' }))
    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(listAllV1).toHaveBeenCalledWith('/api/v1/billing/subscription_tiers?external_ref=a+b%2Fc%26d')
  })

  it('does not add a column filter to mutation URLs (list-only)', async () => {
    listAllV1.mockResolvedValue([])
    authedJson.mockResolvedValue({})
    const { result } = renderHook(() => useCrudResource(tiers, { source_provider: 'reddit' }))
    await waitFor(() => expect(result.current.loading).toBe(false))
    await act(() => result.current.create({ key: 'pro', name: 'Pro' }))
    expect(authedJson).toHaveBeenCalledWith('/api/v1/billing/subscription_tiers', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key: 'pro', name: 'Pro' }),
    })
  })

  // `workspace` is a scope, not a column: the backend stamps a create's owner and allows an edit
  // from it, so sent on the list alone All Data listed an org's rows, then created under the
  // caller and refused edits to rows another member made (Mike, 2026-09-25).
  it('sends the filter\'s workspace on every write, alone and beside the ecosystem scope', async () => {
    listAllV1.mockResolvedValue([])
    authedJson.mockResolvedValue({})
    const { result } = renderHook(() =>
      useCrudResource(tiers, { workspace: 'acme co', source_provider: 'reddit' }, 'eco-1'),
    )
    await waitFor(() => expect(result.current.loading).toBe(false))
    await act(() => result.current.create({ key: 'pro' }))
    expect(authedJson).toHaveBeenCalledWith(
      '/api/v1/billing/subscription_tiers?ecosystem_id=eco-1&workspace=acme%20co',
      expect.objectContaining({ method: 'POST' }),
    )
    await act(() => result.current.update({ id: 't1' }, { name: 'N' }))
    expect(authedJson).toHaveBeenCalledWith(
      '/api/v1/billing/subscription_tiers/t1?ecosystem_id=eco-1&workspace=acme%20co',
      expect.objectContaining({ method: 'POST' }),
    )
    await act(() => result.current.remove({ id: 't1' }))
    expect(authedJson).toHaveBeenCalledWith(
      '/api/v1/billing/subscription_tiers/t1?ecosystem_id=eco-1&workspace=acme%20co',
      { method: 'DELETE' },
    )
  })

  it('sends the workspace on a write with no ecosystem scope', async () => {
    listAllV1.mockResolvedValue([])
    authedJson.mockResolvedValue({})
    const { result } = renderHook(() => useCrudResource(tiers, { workspace: 'acme' }))
    await waitFor(() => expect(result.current.loading).toBe(false))
    await act(() => result.current.create({ key: 'pro' }))
    expect(authedJson).toHaveBeenCalledWith(
      '/api/v1/billing/subscription_tiers?workspace=acme',
      expect.objectContaining({ method: 'POST' }),
    )
  })

  it('does not re-list when an equivalent inline filter object is passed on re-render', async () => {
    listAllV1.mockResolvedValue([])
    authedJson.mockResolvedValue({})
    const { result, rerender } = renderHook(
      ({ filter }) => useCrudResource(tiers, filter),
      { initialProps: { filter: { source_provider: 'reddit' } as Record<string, string> } },
    )
    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(listAllV1).toHaveBeenCalledTimes(1)
    // A brand-new object with identical contents — what an inline `filter={{…}}`
    // literal produces every render. The serialized filterQuery is unchanged, so
    // the list effect must NOT re-fire.
    rerender({ filter: { source_provider: 'reddit' } })
    expect(listAllV1).toHaveBeenCalledTimes(1)
  })
})

describe('useCrudResource scopeEcosystemId', () => {
  const ECO = 'e1c0/5+15'

  it('prefixes the list query with the ecosystem scope, before any filter', async () => {
    listAllV1.mockResolvedValueOnce([])
    const { result } = renderHook(() =>
      useCrudResource(tiers, { source_provider: 'reddit' }, 'eco-1'),
    )
    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(listAllV1).toHaveBeenCalledWith('/api/v1/billing/subscription_tiers?ecosystem_id=eco-1&source_provider=reddit')
  })

  it('rides every mutation URL (POST / POST / DELETE), unlike the list-only filter', async () => {
    listAllV1.mockResolvedValue([])
    authedJson.mockResolvedValue({})
    const { result } = renderHook(() => useCrudResource(tiers, undefined, 'eco-1'))
    await waitFor(() => expect(result.current.loading).toBe(false))
    await act(() => result.current.create({ key: 'pro' }))
    expect(authedJson).toHaveBeenCalledWith('/api/v1/billing/subscription_tiers?ecosystem_id=eco-1', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key: 'pro' }),
    })
    await act(() => result.current.update({ id: 't1' }, { name: 'N' }))
    expect(authedJson).toHaveBeenCalledWith(
      '/api/v1/billing/subscription_tiers/t1?ecosystem_id=eco-1',
      expect.objectContaining({ method: 'POST' }),
    )
    await act(() => result.current.remove({ id: 't1' }))
    expect(authedJson).toHaveBeenCalledWith(
      '/api/v1/billing/subscription_tiers/t1?ecosystem_id=eco-1',
      { method: 'DELETE' },
    )
  })

  it('URL-encodes the scope id and omits it entirely when absent', async () => {
    listAllV1.mockResolvedValueOnce([])
    const { result } = renderHook(() => useCrudResource(tiers, undefined, ECO))
    await waitFor(() => expect(result.current.loading).toBe(false))
    expect(listAllV1).toHaveBeenCalledWith(`/api/v1/billing/subscription_tiers?ecosystem_id=${encodeURIComponent(ECO)}`)
    listAllV1.mockResolvedValueOnce([])
    const { result: bare } = renderHook(() => useCrudResource(tiers))
    await waitFor(() => expect(bare.current.loading).toBe(false))
    expect(listAllV1).toHaveBeenLastCalledWith('/api/v1/billing/subscription_tiers')
  })
})
