// Conformance vectors hub-domain-hooks-011..033 (cookbook adh/hub/messaging/inbox-state):
// the DM conversation list, one DM thread and `startDm`. The HTTP client, the auth context
// and the SSE transport are mocked; the hooks, mappers and the wake channel run for real.
import { act } from 'react'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { deferred, renderHook, waitFor } from './render-hook'

const mocks = vi.hoisted(() => ({
  authedJson: vi.fn(),
  authedRequest: vi.fn(),
  listV1Page: vi.fn(),
  connectSse: vi.fn(),
  auth: { user: { id: 'me' } as { id: string } | null },
}))

vi.mock('@adh-sdk/auth/client', () => {
  class AuthHttpError extends Error {
    status: number
    constructor(status: number, message: string) {
      super(message)
      this.status = status
    }
  }
  return {
    AuthHttpError,
    authedJson: mocks.authedJson,
    authedRequest: mocks.authedRequest,
    listV1Page: mocks.listV1Page,
    unixToIso: (n: number) => new Date(n * 1000).toISOString(),
  }
})
vi.mock('@adh-sdk/auth', () => ({ useAuth: () => ({ user: mocks.auth.user }) }))
vi.mock('@adh-sdk/data/stream', () => ({ connectSse: mocks.connectSse }))

import { AuthHttpError } from '@adh-sdk/auth/client'
import { subscribeToNotifications, emitLocalChange } from '../use-notifications'
import { startDm, useDmConversations, useDmThread } from '../use-dms'

type SseOpts = { url: string; event: string; onEvent: (data: string) => void; onPoll: () => void }
const sseOpts = (n = 0) => mocks.connectSse.mock.calls[n]![0] as SseOpts
let closes: ReturnType<typeof vi.fn>[]

beforeEach(() => {
  vi.resetAllMocks()
  vi.unstubAllGlobals()
  mocks.auth.user = { id: 'me' }
  closes = []
  mocks.connectSse.mockImplementation(() => {
    const close = vi.fn()
    closes.push(close)
    return { close }
  })
})

const summaryWire = (chatId: string, other: string) => ({
  chat_id: chatId,
  other_user_id: other,
  last_message: null,
  unread_count: 0,
})
const presenceWire = (userId: string, online: boolean, last: string | null = null) => ({
  user_id: userId,
  online,
  last_seen_at: last,
})
const msgWire = (id: string, seq: number, sender = 'u1', chat = 'c1') => ({
  id,
  chat_id: chat,
  sender_participant_id: null,
  sender_user_id: sender,
  seq,
  role: 'user',
  body: `body ${id}`,
  state: 'sent',
  date_sent: '2026-01-01T00:00:00Z',
})
const list = (data: unknown[], hasMore = false) => ({ data, hasMore })

/** Route listV1Page by URL: chats from `chats`, presence from `presence`. */
function routeLists(chats: () => Promise<unknown> | unknown, presence: () => Promise<unknown> | unknown = () => list([])) {
  mocks.listV1Page.mockImplementation((url: string) =>
    Promise.resolve(url.startsWith('/api/v1/presence') ? presence() : chats()),
  )
}
const urlsCalled = () => mocks.listV1Page.mock.calls.map((c) => String(c[0]))

describe('useDmConversations', () => {
  it('hub-domain-hooks-011 the first request asks for the 100-row window', async () => {
    routeLists(() => list([]))
    const hook = renderHook(() => useDmConversations())
    await waitFor(() => expect(mocks.listV1Page).toHaveBeenCalled())
    expect(urlsCalled()[0]).toBe('/api/v1/chats?type=direct&limit=100')
    hook.unmount()
  })

  it('hub-domain-hooks-012 the window is capped at one page: loadMore sends no wider request', async () => {
    routeLists(() => list([summaryWire('c1', 'u1')], true))
    const hook = renderHook(() => useDmConversations())
    await waitFor(() => expect(hook.result.current.chats).toHaveLength(1))
    const before = urlsCalled().filter((u) => u.includes('/chats')).length
    act(() => hook.result.current.loadMore())
    await act(async () => {})
    const chatUrls = urlsCalled().filter((u) => u.includes('/chats'))
    expect(chatUrls).toHaveLength(before)
    expect(chatUrls.every((u) => u.endsWith('limit=100'))).toBe(true)
    hook.unmount()
  })

  it('hub-domain-hooks-013 a row with no presence entry is offline with no last-seen', async () => {
    routeLists(() => list([summaryWire('c1', 'u1'), summaryWire('c2', 'u2')]), () => list([presenceWire('u2', true, 'now')]))
    const hook = renderHook(() => useDmConversations())
    await waitFor(() => expect(hook.result.current.chats).toHaveLength(2))
    const [c1, c2] = hook.result.current.chats
    expect(c1).toMatchObject({ otherUserId: 'u1', online: false, lastSeenAt: null })
    expect(c2).toMatchObject({ otherUserId: 'u2', online: true, lastSeenAt: 'now' })
    hook.unmount()
  })

  it('hub-domain-hooks-014 the presence request percent-encodes the whole comma-joined id list', async () => {
    routeLists(() => list([summaryWire('c1', 'a,b'), summaryWire('c2', 'c')]))
    const hook = renderHook(() => useDmConversations())
    await waitFor(() => expect(hook.result.current.chats).toHaveLength(2))
    const presenceUrl = urlsCalled().find((u) => u.startsWith('/api/v1/presence'))
    expect(presenceUrl).toBe(`/api/v1/presence?user_ids=${encodeURIComponent('a,b,c')}&limit=100`)
    expect(presenceUrl).toContain('user_ids=a%2Cb%2Cc')
    hook.unmount()
  })

  it('hub-domain-hooks-015 a failed presence read leaves every row offline and sets no error', async () => {
    mocks.listV1Page.mockImplementation((url: string) =>
      url.startsWith('/api/v1/presence') ? Promise.reject(new Error('presence down')) : Promise.resolve(list([summaryWire('c1', 'u1')])),
    )
    const hook = renderHook(() => useDmConversations())
    await waitFor(() => expect(hook.result.current.chats).toHaveLength(1))
    expect(hook.result.current.chats[0]).toMatchObject({ online: false, lastSeenAt: null })
    expect(hook.result.current.error).toBeNull()
    hook.unmount()
  })

  it('hub-domain-hooks-016 an older load that resolves after a newer one is discarded', async () => {
    const older = deferred<unknown>()
    const newer = deferred<unknown>()
    const queue = [older.promise, newer.promise]
    routeLists(() => queue.shift())
    const hook = renderHook(() => useDmConversations())
    await waitFor(() => expect(mocks.listV1Page).toHaveBeenCalledTimes(1))
    act(() => emitLocalChange())
    await waitFor(() => expect(mocks.listV1Page).toHaveBeenCalledTimes(2))
    await act(async () => newer.resolve(list([summaryWire('new', 'u1')])))
    await waitFor(() => expect(hook.result.current.chats.map((c) => c.chatId)).toEqual(['new']))
    await act(async () => older.resolve(list([summaryWire('old', 'u9')])))
    await act(async () => {})
    expect(hook.result.current.chats.map((c) => c.chatId)).toEqual(['new'])
    hook.unmount()
  })

  it('hub-domain-hooks-017 a failed refetch keeps the last good list and sets an error', async () => {
    let fail = false
    routeLists(() => (fail ? Promise.reject(new Error('boom')) : list([summaryWire('c1', 'u1'), summaryWire('c2', 'u2')])))
    const hook = renderHook(() => useDmConversations())
    await waitFor(() => expect(hook.result.current.chats).toHaveLength(2))
    fail = true
    act(() => hook.result.current.refetch())
    await waitFor(() => expect(hook.result.current.error).toBe('boom'))
    expect(hook.result.current.chats.map((c) => c.chatId)).toEqual(['c1', 'c2'])
    hook.unmount()
  })

  it('hub-domain-hooks-018 hasMore is false once the window is full, even if the server reports more', async () => {
    routeLists(() => list([summaryWire('c1', 'u1')], true))
    const hook = renderHook(() => useDmConversations())
    await waitFor(() => expect(hook.result.current.chats).toHaveLength(1))
    expect(hook.result.current.hasMore).toBe(false)
    hook.unmount()
  })
})

describe('useDmThread', () => {
  it('hub-domain-hooks-019 a null chat id clears the state and issues no request', async () => {
    const hook = renderHook(() => useDmThread(null))
    await act(async () => {})
    expect(hook.result.current.messages).toEqual([])
    expect(hook.result.current.loading).toBe(false)
    expect(mocks.listV1Page).not.toHaveBeenCalled()
    expect(mocks.connectSse).not.toHaveBeenCalled()
    hook.unmount()
  })

  it('hub-domain-hooks-020 history is sorted ascending by seq', async () => {
    mocks.listV1Page.mockResolvedValue(list([msgWire('m3', 3), msgWire('m1', 1), msgWire('m2', 2)]))
    const hook = renderHook(() => useDmThread('c1'))
    await waitFor(() => expect(hook.result.current.messages).toHaveLength(3))
    expect(hook.result.current.messages.map((m) => m.seq)).toEqual([1, 2, 3])
    expect(mocks.listV1Page).toHaveBeenCalledWith('/api/v1/chats/c1/messages?limit=100')
    hook.unmount()
  })

  it('hub-domain-hooks-021 a live message with an existing id is not added twice', async () => {
    mocks.listV1Page.mockResolvedValue(list([msgWire('m1', 1)]))
    const hook = renderHook(() => useDmThread('c1'))
    await waitFor(() => expect(mocks.connectSse).toHaveBeenCalled())
    act(() => sseOpts().onEvent(JSON.stringify({ ...msgWire('m1', 1), body: 'dup' })))
    expect(hook.result.current.messages).toHaveLength(1)
    act(() => sseOpts().onEvent(JSON.stringify({ ...msgWire('m2', 2), chatId: 'c1', senderUserId: 'u1' })))
    expect(hook.result.current.messages).toHaveLength(2)
    hook.unmount()
  })

  it('hub-domain-hooks-022 the live connection starts after the last loaded seq', async () => {
    mocks.listV1Page.mockResolvedValue(list([msgWire('m41', 41), msgWire('m42', 42)]))
    const hook = renderHook(() => useDmThread('c1'))
    await waitFor(() => expect(mocks.connectSse).toHaveBeenCalled())
    expect(sseOpts().url).toBe('/api/v1/chats/c1/stream?after=42')
    expect(sseOpts().event).toBe('message')
    hook.unmount()
  })

  it('hub-domain-hooks-023 a malformed live frame is ignored', async () => {
    mocks.listV1Page.mockResolvedValue(list([msgWire('m1', 1)]))
    const hook = renderHook(() => useDmThread('c1'))
    await waitFor(() => expect(mocks.connectSse).toHaveBeenCalled())
    expect(() => act(() => sseOpts().onEvent('{not json'))).not.toThrow()
    expect(hook.result.current.messages.map((m) => m.id)).toEqual(['m1'])
    hook.unmount()
  })

  it('hub-domain-hooks-024 changing chat or unmounting discards a pending history and closes the connection', async () => {
    const c1 = deferred<unknown>()
    mocks.listV1Page.mockReturnValueOnce(c1.promise).mockResolvedValueOnce(list([msgWire('m2', 1, 'u1', 'c2')]))
    const hook = renderHook((id: string) => useDmThread(id), 'c1')
    hook.rerender('c2')
    await waitFor(() => expect(hook.result.current.messages.map((m) => m.id)).toEqual(['m2']))
    await act(async () => c1.resolve(list([msgWire('m1', 1, 'u1', 'c1')])))
    expect(hook.result.current.messages.map((m) => m.id)).toEqual(['m2'])
    expect(mocks.connectSse).toHaveBeenCalledTimes(1)
    expect(sseOpts().url).toContain('/chats/c2/stream')

    hook.unmount()
    expect(closes[0]).toHaveBeenCalledTimes(1)
  })

  it('hub-domain-hooks-025 sending blank text issues no request', async () => {
    mocks.listV1Page.mockResolvedValue(list([]))
    const hook = renderHook(() => useDmThread('c1'))
    await waitFor(() => expect(hook.result.current.loading).toBe(false))
    const woke = vi.fn()
    const off = subscribeToNotifications(woke)
    await act(async () => hook.result.current.send('   '))
    expect(mocks.authedJson).not.toHaveBeenCalled()
    expect(woke).not.toHaveBeenCalled()
    off()
    hook.unmount()
  })

  it('hub-domain-hooks-026 without crypto.randomUUID the client message id falls back to timestamp-plus-random', async () => {
    vi.stubGlobal('crypto', {})
    mocks.listV1Page.mockResolvedValue(list([]))
    mocks.authedJson.mockResolvedValue(msgWire('m1', 1))
    const hook = renderHook(() => useDmThread('c1'))
    await waitFor(() => expect(hook.result.current.loading).toBe(false))
    await act(async () => hook.result.current.send('hi'))
    const [url, init] = mocks.authedJson.mock.calls[0]!
    expect(url).toBe('/api/v1/chats/c1/messages')
    const body = JSON.parse(String((init as RequestInit).body))
    expect(body.body).toBe('hi')
    expect(body.client_message_id).toMatch(/^\d+-[0-9a-f]*$/)
    expect(body.client_message_id).not.toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-/)
    hook.unmount()
  })

  it('hub-domain-hooks-027 mark-read posts an empty body then wakes subscribers once', async () => {
    mocks.listV1Page.mockResolvedValue(list([]))
    mocks.authedRequest.mockResolvedValue(undefined)
    const hook = renderHook(() => useDmThread('c1'))
    await waitFor(() => expect(hook.result.current.loading).toBe(false))
    const woke = vi.fn()
    const off = subscribeToNotifications(woke)
    await act(async () => hook.result.current.markRead())
    expect(mocks.authedRequest).toHaveBeenCalledWith('/api/v1/chats/c1/read', { method: 'POST', body: '{}' })
    expect(woke).toHaveBeenCalledTimes(1)
    off()
    hook.unmount()
  })

  it('hub-domain-hooks-028 ownership is false when the caller id is null, even for an empty sender id', async () => {
    mocks.auth.user = null
    mocks.listV1Page.mockResolvedValue(list([]))
    const hook = renderHook(() => useDmThread('c1'))
    await act(async () => {})
    const orphan = { id: 'm', chatId: 'c1', senderParticipantId: null, senderUserId: '', seq: 1, role: 'user', body: '', state: 'sent', dateSent: '' }
    expect(hook.result.current.isOwn(orphan)).toBe(false)
    hook.unmount()

    mocks.auth.user = { id: 'me' }
    const signedIn = renderHook(() => useDmThread('c1'))
    await act(async () => {})
    expect(signedIn.result.current.isOwn({ ...orphan, senderUserId: 'me' })).toBe(true)
    expect(signedIn.result.current.isOwn(orphan)).toBe(false)
    signedIn.unmount()
  })

  it('hub-domain-hooks-033 a send resolving after a chat switch does not merge into the new thread', async () => {
    mocks.listV1Page.mockResolvedValueOnce(list([])).mockResolvedValueOnce(list([]))
    const post = deferred<unknown>()
    mocks.authedJson.mockReturnValue(post.promise)
    const hook = renderHook((id: string) => useDmThread(id), 'c1')
    await waitFor(() => expect(hook.result.current.loading).toBe(false))
    let sending!: Promise<void>
    act(() => {
      sending = hook.result.current.send('hi')
    })
    hook.rerender('c2')
    await waitFor(() => expect(hook.result.current.loading).toBe(false))
    await act(async () => {
      post.resolve(msgWire('m1', 1, 'me', 'c1'))
      await sending
    })
    expect(hook.result.current.messages.map((m) => m.chatId)).not.toContain('c1')
    hook.unmount()
  })

  it('hub-domain-hooks-034 a chatId change clears the previous thread before the new one loads', async () => {
    mocks.listV1Page.mockResolvedValueOnce(list([msgWire('m1', 1, 'u1', 'c1')])).mockResolvedValueOnce(list([]))
    const hook = renderHook((id: string) => useDmThread(id), 'c1')
    await waitFor(() => expect(hook.result.current.messages.map((m) => m.id)).toEqual(['m1']))
    hook.rerender('c2')
    await waitFor(() => expect(hook.result.current.loading).toBe(false))
    expect(hook.result.current.messages).toEqual([])
    hook.unmount()
  })

  it.skip('hub-domain-hooks-031 the 401 refresh waterfall belongs to the shared authedFetch in @adh-sdk/auth, not these hooks', () => {})

  it.skip('hub-domain-hooks-032 the access_token query parameter is appended inside the shared connectSse transport (@adh-sdk/data/stream), not by these hooks', () => {})
})

describe('startDm', () => {
  it('hub-domain-hooks-029 a 403 resolves to { forbidden: true }', async () => {
    mocks.authedJson.mockRejectedValue(new AuthHttpError(403, 'blocked'))
    await expect(startDm('u1')).resolves.toEqual({ forbidden: true })
    expect(mocks.authedJson).toHaveBeenCalledWith('/api/v1/chats', {
      method: 'POST',
      body: JSON.stringify({ type: 'direct', recipient_id: 'u1' }),
    })
  })

  it('hub-domain-hooks-030 any other failure rejects with its status', async () => {
    mocks.authedJson.mockRejectedValue(new AuthHttpError(500, 'server'))
    const err = await startDm('u1').catch((e) => e)
    expect(err).toBeInstanceOf(AuthHttpError)
    expect(err.status).toBe(500)
  })

  it('hub-domain-hooks-029 success resolves the chat id', async () => {
    mocks.authedJson.mockResolvedValue({ id: 'chat-9', other_user_id: 'u1', created: true })
    await expect(startDm('u1')).resolves.toEqual({ chatId: 'chat-9' })
  })
})
