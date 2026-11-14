import { describe, expect, it } from 'vitest'

import { createHubMailClient } from './hub-mail-client'
import { MESSAGES_RESOURCE } from './snapshot'
import type { HubSyncChange, HubSyncPullPage } from './types'

type Responder = (path: string) => unknown

function httpError(status: number): Error {
  return Object.assign(new Error(`HTTP ${status}`), { status })
}

function fakeFetch(responder: Responder): { fetchJson: (path: string) => Promise<unknown>; calls: string[] } {
  const calls: string[] = []
  return {
    calls,
    fetchJson: async (path: string): Promise<unknown> => {
      calls.push(path)
      const result = responder(path)
      if (result instanceof Error) throw result
      return result
    },
  }
}

function message(id: string, data: Record<string, unknown> = {}): HubSyncChange {
  return {
    resource: MESSAGES_RESOURCE,
    id,
    op: 'upsert',
    syncVersion: '1',
    data: { connection_id: 'conn', subject: `s-${id}`, ...data },
  }
}

function page(changes: HubSyncChange[], cursor = 'c1', hasMore = false): HubSyncPullPage {
  return { changes, cursor, hasMore }
}

function cursorOf(path: string): string | null {
  return new URL(path, 'https://hub.invalid').searchParams.get('cursor')
}

describe('createHubMailClient', () => {
  it('hmw-001: lists only Gmail message connections', async () => {
    const { fetchJson } = fakeFetch(() => ({
      connections: [
        { id: 'g', provider: 'gmail', serviceType: 'messages', status: 'active', username: 'a@x.com' },
        { id: 'h', provider: 'github', serviceType: 'repos', status: 'active', username: 'octo' },
      ],
    }))
    const accounts = await createHubMailClient({ fetchJson }).accounts()
    expect(accounts.map((a) => a.id)).toEqual(['g'])
  })

  it('hmw-002: account email is the username', async () => {
    const { fetchJson } = fakeFetch(() => ({
      connections: [{ id: 'g', provider: 'gmail', serviceType: 'messages', status: 'active', username: 'a@x.com' }],
    }))
    const [account] = await createHubMailClient({ fetchJson }).accounts()
    expect(account).toEqual({ id: 'g', email: 'a@x.com', status: 'active', lastError: null })
  })

  it('hmw-003: an empty username falls back to the display name', async () => {
    const { fetchJson } = fakeFetch(() => ({
      connections: [
        { id: 'g', provider: 'gmail', serviceType: 'messages', status: 'error', username: '', displayName: 'Work', lastError: 'expired' },
      ],
    }))
    const [account] = await createHubMailClient({ fetchJson }).accounts()
    expect(account?.email).toBe('Work')
    expect(account?.lastError).toBe('expired')
  })

  it('hmw-004: pulls every page, carrying the cursor', async () => {
    const { fetchJson, calls } = fakeFetch((path) =>
      cursorOf(path) === '' ? page([message('1')], 'c1', true) : page([message('2')], 'c2', false),
    )
    const list = await createHubMailClient({ fetchJson }).messages('conn')
    expect(calls).toHaveLength(2)
    expect(cursorOf(calls[1] ?? '')).toBe('c1')
    expect(calls[0]).toContain('limit=500')
    expect(list.map((m) => m.id).sort()).toEqual(['1', '2'])
  })

  it('hmw-005: ignores changes for other resources', async () => {
    const { fetchJson } = fakeFetch(() =>
      page([{ resource: 'notes.notes', id: 'n', op: 'upsert', syncVersion: '1', data: { connection_id: 'conn' } }]),
    )
    expect(await createHubMailClient({ fetchJson }).messages('conn')).toEqual([])
  })

  it('hmw-006: a delete removes an upserted message', async () => {
    const { fetchJson } = fakeFetch(() =>
      page([message('1'), { resource: MESSAGES_RESOURCE, id: '1', op: 'delete', syncVersion: '2' }]),
    )
    expect(await createHubMailClient({ fetchJson }).messages('conn')).toEqual([])
  })

  it('hmw-007: newest first, undated last', async () => {
    const { fetchJson } = fakeFetch(() =>
      page([
        message('a', { internal_date: '2026-11-01T00:00:00Z' }),
        message('u'),
        message('b', { internal_date: '2026-11-03T00:00:00Z' }),
      ]),
    )
    const list = await createHubMailClient({ fetchJson }).messages('conn')
    expect(list.map((m) => m.id)).toEqual(['b', 'a', 'u'])
  })

  it('hmw-008: a row marked is_deleted is not listed', async () => {
    const { fetchJson } = fakeFetch(() => page([message('1', { is_deleted: true }), message('2')]))
    const list = await createHubMailClient({ fetchJson }).messages('conn')
    expect(list.map((m) => m.id)).toEqual(['2'])
  })

  it('hmw-009: concurrent reads share one pull', async () => {
    const { fetchJson, calls } = fakeFetch(() => page([message('1')]))
    const client = createHubMailClient({ fetchJson })
    await Promise.all([client.messages('conn'), client.messages('conn')])
    expect(calls).toHaveLength(1)
  })

  it('hmw-010: refresh continues from the last cursor', async () => {
    const { fetchJson, calls } = fakeFetch((path) => (cursorOf(path) === '' ? page([message('1')], 'c9') : page([], 'c10')))
    const client = createHubMailClient({ fetchJson })
    await client.messages('conn')
    await client.refresh()
    expect(cursorOf(calls[1] ?? '')).toBe('c9')
  })

  it('hmw-011: an expired cursor clears the snapshot and pulls from the start', async () => {
    let expired = false
    const { fetchJson, calls } = fakeFetch((path) => {
      const cursor = cursorOf(path)
      if (cursor === 'c1' && expired) return httpError(410)
      return expired ? page([message('2')], 'c2') : page([message('1')], 'c1')
    })
    const client = createHubMailClient({ fetchJson })
    expect((await client.messages('conn')).map((m) => m.id)).toEqual(['1'])
    expired = true
    await client.refresh()
    expect(calls.map(cursorOf)).toEqual(['', 'c1', ''])
    expect((await client.messages('conn')).map((m) => m.id)).toEqual(['2'])
  })

  it('hmw-012: an unknown message is null', async () => {
    const { fetchJson } = fakeFetch(() => page([message('1', { body_text: 'hi' })]))
    const client = createHubMailClient({ fetchJson })
    expect(await client.message('conn', 'missing')).toBeNull()
    expect((await client.message('conn', '1'))?.bodyText).toBe('hi')
    expect(await client.message('other', '1')).toBeNull()
  })

  it('hmw-013: a failed pull rejects and keeps the earlier snapshot', async () => {
    let fail = false
    const { fetchJson } = fakeFetch(() => (fail ? httpError(500) : page([message('1')])))
    const client = createHubMailClient({ fetchJson })
    await client.messages('conn')
    fail = true
    await expect(client.refresh()).rejects.toThrow('HTTP 500')
    expect((await client.messages('conn')).map((m) => m.id)).toEqual(['1'])
  })

  it('reset drops what was held so the next read pulls from the start', async () => {
    const { fetchJson, calls } = fakeFetch(() => page([message('1')], 'c1'))
    const client = createHubMailClient({ fetchJson })
    await client.messages('conn')
    client.reset()
    await client.messages('conn')
    expect(calls.map(cursorOf)).toEqual(['', ''])
  })
})
