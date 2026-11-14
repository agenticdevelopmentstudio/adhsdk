// Conformance vectors hub-domain-hooks-001..010 (cookbook adh/hub/messaging/inbox-state):
// the shared wake channel, the unread count and the notification inbox. The HTTP client and
// the SSE transport are mocked; the hooks, the wake channel and the query builder run for real.
import { act } from 'react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { deferred, renderHook, waitFor } from './render-hook'

const mocks = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listV1Page: vi.fn(),
  connectSse: vi.fn(),
}))

vi.mock('@adh-sdk/auth/client', () => ({
  authedJson: mocks.authedJson,
  authedRequest: mocks.authedRequest,
  listV1Page: mocks.listV1Page,
  unixToIso: (n: number) => new Date(n * 1000).toISOString(),
}))
vi.mock('@adh-sdk/data/stream', () => ({ connectSse: mocks.connectSse }))

import { emitLocalChange, subscribeToNotifications, useInbox, useUnreadCount } from '../use-notifications'

const handle = () => ({ close: vi.fn() })
let handles: ReturnType<typeof handle>[]

beforeEach(() => {
  vi.resetAllMocks()
  handles = []
  mocks.connectSse.mockImplementation(() => {
    const h = handle()
    handles.push(h)
    return h
  })
})

const row = (id: string) => ({
  id,
  ecosystem_id: 'eco',
  user_id: 'u',
  category: 'c',
  title: `title ${id}`,
  data: {},
  status: 'inbox',
  is_read: false,
  created: 1767225600,
  updated: 1767225600,
})
const page = (ids: string[], hasMore = false) => ({ data: ids.map(row), hasMore })

describe('shared wake channel', () => {
  it('hub-domain-hooks-001 two subscribers share one stream and one leaving keeps it open', () => {
    const a = subscribeToNotifications(vi.fn())
    const b = subscribeToNotifications(vi.fn())
    expect(mocks.connectSse).toHaveBeenCalledTimes(1)
    a()
    expect(handles[0]!.close).not.toHaveBeenCalled()
    b()
  })

  it('hub-domain-hooks-002 the last unsubscribe closes the stream and the next subscription reopens it', () => {
    const a = subscribeToNotifications(vi.fn())
    const b = subscribeToNotifications(vi.fn())
    a()
    b()
    expect(handles[0]!.close).toHaveBeenCalledTimes(1)
    const c = subscribeToNotifications(vi.fn())
    expect(mocks.connectSse).toHaveBeenCalledTimes(2)
    c()
  })

  it('hub-domain-hooks-003 a local change wakes every subscriber with no arguments', () => {
    const one = vi.fn()
    const two = vi.fn()
    const offs = [subscribeToNotifications(one), subscribeToNotifications(two)]
    emitLocalChange()
    expect(one).toHaveBeenCalledTimes(1)
    expect(one).toHaveBeenCalledWith()
    expect(two).toHaveBeenCalledTimes(1)
    expect(two).toHaveBeenCalledWith()
    offs.forEach((off) => off())
  })
})

describe('useUnreadCount', () => {
  it('hub-domain-hooks-004 fetches the count on mount', async () => {
    mocks.authedJson.mockResolvedValue({ unread_count: { count: 4 } })
    const hook = renderHook(() => useUnreadCount())
    await waitFor(() => expect(hook.result.current.count).toBe(4))
    expect(mocks.authedJson).toHaveBeenCalledWith('/api/v1/notifications?include[]=unread_count&limit=1')
    hook.unmount()
  })

  it('hub-domain-hooks-005 a failed refetch keeps the last known count', async () => {
    mocks.authedJson.mockResolvedValueOnce({ unread_count: { count: 4 } })
    const hook = renderHook(() => useUnreadCount())
    await waitFor(() => expect(hook.result.current.count).toBe(4))
    mocks.authedJson.mockRejectedValueOnce(new Error('blip'))
    act(() => emitLocalChange())
    await waitFor(() => expect(mocks.authedJson).toHaveBeenCalledTimes(2))
    await act(async () => {})
    expect(hook.result.current.count).toBe(4)
    hook.unmount()
  })
})

describe('useInbox', () => {
  it('hub-domain-hooks-006 serializes every filter into the /v1 query', async () => {
    mocks.listV1Page.mockResolvedValue(page([]))
    const hook = renderHook(() =>
      useInbox({ status: 'archived', read: false, limit: 20, startingAfter: 'n9', categories: ['a', 'b'] }),
    )
    await waitFor(() => expect(mocks.listV1Page).toHaveBeenCalled())
    expect(mocks.listV1Page).toHaveBeenCalledWith(
      '/api/v1/notifications?status=archived&read=false&limit=20&starting_after=n9&category=a&category=b',
    )
    hook.unmount()
  })

  it('hub-domain-hooks-007 an empty query sends no status and leaves the default to the backend', async () => {
    mocks.listV1Page.mockResolvedValue(page(['n1'], true))
    const hook = renderHook(() => useInbox())
    await waitFor(() => expect(hook.result.current.items).toHaveLength(1))
    expect(mocks.listV1Page).toHaveBeenCalledWith('/api/v1/notifications')
    expect(hook.result.current.hasMore).toBe(true)
    hook.unmount()
  })

  it('hub-domain-hooks-008 a response for superseded params is never applied', async () => {
    const first = deferred<ReturnType<typeof page>>()
    mocks.listV1Page.mockReturnValueOnce(first.promise).mockResolvedValueOnce(page(['new']))
    const hook = renderHook((p: { status: 'inbox' | 'archived' }) => useInbox(p), { status: 'inbox' })
    hook.rerender({ status: 'archived' })
    await waitFor(() => expect(hook.result.current.items.map((i) => i.id)).toEqual(['new']))
    await act(async () => first.resolve(page(['old'])))
    expect(hook.result.current.items.map((i) => i.id)).toEqual(['new'])

    const failing = deferred<ReturnType<typeof page>>()
    mocks.listV1Page.mockReturnValueOnce(failing.promise).mockResolvedValueOnce(page(['newer']))
    hook.rerender({ status: 'inbox' })
    hook.rerender({ status: 'archived' })
    await waitFor(() => expect(hook.result.current.items.map((i) => i.id)).toEqual(['newer']))
    await act(async () => failing.reject(new Error('late failure')))
    expect(hook.result.current.error).toBeNull()
    hook.unmount()
  })

  it('hub-domain-hooks-009 a mutation POSTs then wakes subscribers exactly once', async () => {
    mocks.listV1Page.mockResolvedValue(page(['n1']))
    mocks.authedRequest.mockResolvedValue(undefined)
    const hook = renderHook(() => useInbox())
    await waitFor(() => expect(hook.result.current.items).toHaveLength(1))
    const woke = vi.fn()
    const off = subscribeToNotifications(woke)
    await act(async () => hook.result.current.markRead('n1'))
    expect(mocks.authedRequest).toHaveBeenCalledWith('/api/v1/notifications/n1/read', { method: 'POST' })
    expect(woke).toHaveBeenCalledTimes(1)
    off()
    hook.unmount()
  })

  it('hub-domain-hooks-010 a failed mutation broadcasts nothing and leaves the list alone', async () => {
    mocks.listV1Page.mockResolvedValue(page(['n1']))
    mocks.authedRequest.mockRejectedValue(new Error('nope'))
    const hook = renderHook(() => useInbox())
    await waitFor(() => expect(hook.result.current.items).toHaveLength(1))
    const woke = vi.fn()
    const off = subscribeToNotifications(woke)
    await act(async () => {
      await expect(hook.result.current.archive('n1')).rejects.toThrow('nope')
    })
    expect(woke).not.toHaveBeenCalled()
    expect(hook.result.current.items.map((i) => i.id)).toEqual(['n1'])
    off()
    hook.unmount()
  })
})
