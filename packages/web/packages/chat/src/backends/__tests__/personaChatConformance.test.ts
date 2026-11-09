import { describe, expect, it } from 'vitest'

import type { InboundEvent } from '../../contract/backend/InboundEvent'
import { PersonaChatBackend, type TurnStatus } from '../PersonaChatBackend'
import { hangingSse, type ScriptedSse, scriptedSse, sse, truncatedSse } from './sse'

/**
 * Conformance vectors for the `persona-chat-coordinator` ingredient.
 * docs/specs/ingredients/persona-chat-coordinator.md — one `it` per `pcc-*`
 * vector, named for the requirement it holds the coordinator to.
 *
 * These were each observed failing for their stated reason before being
 * trusted. A vector that has never failed has proved nothing.
 */

interface Call {
  readonly path: string
  readonly init: RequestInit
}

interface Fixture {
  readonly backend: PersonaChatBackend
  readonly calls: Call[]
  readonly statuses: Array<TurnStatus | null>
  events(count: number): Promise<InboundEvent[]>
  drained(): Promise<InboundEvent[]>
}

function fixture(
  streamFor: (signal: AbortSignal | null | undefined) => ReadableStream<Uint8Array> | null,
  opts: { conversationOk?: boolean; conversationGate?: Promise<void> } = {},
): Fixture {
  const calls: Call[] = []
  const statuses: Array<TurnStatus | null> = []

  const backend = new PersonaChatBackend({
    personaSlug: 'aria',
    model: 'claude-opus-5',
    authorize: async (path, init) => {
      calls.push({ path, init })
      if (path.endsWith('/v1/chats')) {
        // Held open so a vector can act while the creation POST is still in flight.
        if (opts.conversationGate) await opts.conversationGate
        if (opts.conversationOk === false) return new Response('nope', { status: 500 })
        return new Response(JSON.stringify({ id: 'conv-1' }), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        })
      }
      const body = streamFor(init.signal as AbortSignal | null | undefined)
      return new Response(body, { status: 200, headers: { 'content-type': 'text/event-stream' } })
    },
    onStatus: (s) => statuses.push(s),
  })

  const iterator = backend.inboundEvents[Symbol.asyncIterator]()

  return {
    backend,
    calls,
    statuses,
    async events(count) {
      const out: InboundEvent[] = []
      for (let i = 0; i < count; i++) {
        const next = await iterator.next()
        if (next.done) break
        out.push(next.value)
      }
      return out
    },
    async drained() {
      const out: InboundEvent[] = []
      for (;;) {
        const next = await iterator.next()
        if (next.done) break
        out.push(next.value)
      }
      return out
    },
  }
}

/**
 * Let the turn chain advance. Turns are sequenced on promise resolution, not on timers, so
 * there is nothing for fake timers to advance — draining the microtask queue is the wait.
 */
async function settle(): Promise<void> {
  for (let i = 0; i < 16; i++) await Promise.resolve()
}

const hello: Array<[string, unknown]> = [
  ['open', {}],
  ['token', { text: 'Hel' }],
  ['token', { text: 'lo' }],
  ['done', {}],
]

describe('persona-chat-coordinator conformance', () => {
  it('pcc-001 ci-lazy-conversation: constructing performs no network I/O', async () => {
    const f = fixture(() => sse(hello))
    await Promise.resolve()
    expect(f.calls).toHaveLength(0)
  })

  it('pcc-002 ci-conversation-reuse: two turns share one conversation', async () => {
    const f = fixture(() => sse(hello))
    await f.backend.send('one', [])
    await f.events(4)
    await f.backend.send('two', [])
    await f.events(4)

    const created = f.calls.filter((c) => c.path.endsWith('/v1/chats'))
    const messages = f.calls.filter((c) => c.path.endsWith('/messages'))
    expect(created).toHaveLength(1)
    expect(messages).toHaveLength(2)
  })

  it('pcc-003 ci-no-history: the request body carries only the new message', async () => {
    const f = fixture(() => sse(hello))
    await f.backend.send('just this', [])
    await f.events(4)

    const message = f.calls.find((c) => c.path.endsWith('/messages'))
    expect(JSON.parse(String(message?.init.body))).toEqual({ message: 'just this' })
  })

  it('pcc-004 ci-accumulate: draftUpdated carries the accumulation, not the fragment', async () => {
    const f = fixture(() => sse(hello))
    await f.backend.send('hi', [])
    const events = await f.events(2)

    const texts = events
      .filter((e): e is Extract<InboundEvent, { kind: 'draftUpdated' }> => e.kind === 'draftUpdated')
      .map((e) => e.text)
    expect(texts).toEqual(['Hel', 'Hello'])
  })

  it('pcc-005 ci-commit-once: done commits exactly one message, then clears the draft', async () => {
    const f = fixture(() => sse(hello))
    await f.backend.send('hi', [])
    const events = await f.events(4)

    const received = events.filter((e) => e.kind === 'messageReceived')
    expect(received).toHaveLength(1)
    expect(received[0]).toMatchObject({ message: { text: 'Hello', senderID: 'aria' } })
    expect(events.at(-1)?.kind).toBe('draftCleared')
  })

  it('pcc-005 ci-commit-once: an empty reply still commits, recording that the turn happened', async () => {
    const f = fixture(() => sse([['done', {}]]))
    await f.backend.send('hi', [])
    const events = await f.events(2)

    expect(events[0]).toMatchObject({ kind: 'messageReceived', message: { text: '' } })
  })

  it('pcc-006 ci-no-commit-on-abort: a stream that dies before done does not commit', async () => {
    // Deliberately NOT using destroy() here. destroy() closes the event
    // queue, which would swallow a wrongly-emitted commit and make this
    // vector pass for the wrong reason. A truncated stream leaves the
    // queue open, so a bad commit is observable.
    const f = fixture(() => truncatedSse([['token', { text: 'Hel' }]]))
    const events = await (async () => {
      await f.backend.send('hi', [])
      return f.events(3)
    })()

    expect(events.some((e) => e.kind === 'messageReceived')).toBe(false)
    expect(events.map((e) => e.kind)).toContain('draftCleared')
  })

  it('pcc-006 ci-no-commit-on-abort: destroy mid-stream does not commit', async () => {
    const f = fixture((signal) => hangingSse([['token', { text: 'Hel' }]], signal!))
    await f.backend.send('hi', [])
    await f.events(1)
    f.backend.destroy()

    const rest = await f.drained()
    expect(rest.some((e) => e.kind === 'messageReceived')).toBe(false)
  })

  it('pcc-007 ci-drop-open: the open heartbeat is not a transcript event', async () => {
    const f = fixture(() => sse([['open', {}], ['done', {}]]))
    await f.backend.send('hi', [])
    const events = await f.events(2)

    expect(events.map((e) => e.kind)).toEqual(['messageReceived', 'draftCleared'])
  })

  it('pcc-008 ci-unknown-events: an unknown event is ignored and the stream continues', async () => {
    const f = fixture(() => sse([['quux', { any: 'thing' }], ['token', { text: 'ok' }], ['done', {}]]))
    await f.backend.send('hi', [])
    const events = await f.events(3)

    expect(events.map((e) => e.kind)).toEqual(['draftUpdated', 'messageReceived', 'draftCleared'])
  })

  it('pcc-009 ci-tool-invoked/completed: tool events map to command events with a matching id', async () => {
    const f = fixture(() =>
      sse([
        ['tool_call_started', { name: 'search', arguments: '{"q":"x"}' }],
        ['tool_call_completed', { name: 'search', ok: true, result: '{"hits":1}' }],
        ['done', {}],
      ]),
    )
    await f.backend.send('hi', [])
    const events = await f.events(2)

    const invoked = events[0]
    const completed = events[1]
    expect(invoked).toMatchObject({ kind: 'commandInvoked' })
    expect(completed).toMatchObject({ kind: 'commandCompleted' })
    if (invoked?.kind !== 'commandInvoked' || completed?.kind !== 'commandCompleted') {
      throw new Error('wrong event kinds')
    }
    expect(completed.result.invocationID).toBe(invoked.invocation.id)
    expect(invoked.invocation.argumentsJSON).toBe('{"q":"x"}')
  })

  it('pcc-010 ci-invocation-ids: parallel same-name calls get distinct ids', async () => {
    const f = fixture(() =>
      sse([
        ['tool_call_started', { name: 'search', arguments: '{"q":"a"}' }],
        ['tool_call_started', { name: 'search', arguments: '{"q":"b"}' }],
        ['done', {}],
      ]),
    )
    await f.backend.send('hi', [])
    const events = await f.events(2)

    const ids = events
      .filter((e): e is Extract<InboundEvent, { kind: 'commandInvoked' }> => e.kind === 'commandInvoked')
      .map((e) => e.invocation.id)
    expect(ids).toHaveLength(2)
    expect(new Set(ids).size).toBe(2)
  })

  it('pcc-011 ci-tool-text-separation: tool arguments never land in the draft', async () => {
    const f = fixture(() =>
      sse([
        ['token', { text: 'Look' }],
        ['tool_call_started', { name: 'search', arguments: '{"q":"SECRET"}' }],
        ['tool_call_completed', { name: 'search', ok: true, result: 'RESULTTEXT' }],
        ['token', { text: 'ing' }],
        ['done', {}],
      ]),
    )
    await f.backend.send('hi', [])
    const events = await f.events(6)

    const drafts = events
      .filter((e): e is Extract<InboundEvent, { kind: 'draftUpdated' }> => e.kind === 'draftUpdated')
      .map((e) => e.text)
    expect(drafts).toEqual(['Look', 'Looking'])
    expect(drafts.join()).not.toContain('SECRET')
    expect(drafts.join()).not.toContain('RESULTTEXT')
  })

  it('pcc-012 ci-error-terminal: an error ends the turn without committing', async () => {
    const f = fixture(() =>
      sse([['token', { text: 'partial' }], ['error', { message: 'rate limited' }]]),
    )
    const localID = await f.backend.send('hi', [])
    const events = await f.events(3)

    expect(events.some((e) => e.kind === 'messageReceived')).toBe(false)
    expect(events).toContainEqual(
      expect.objectContaining({ kind: 'messageFailed', localID, reason: 'rate limited' }),
    )
  })

  it('pcc-013 ci-in-band-errors: HTTP 200 with an in-band error is a failure', async () => {
    const f = fixture(() => sse([['error', { message: 'refused' }]]))
    await f.backend.send('hi', [])
    const events = await f.events(2)

    // The response status was 200 throughout; only the event says otherwise.
    expect(events[0]).toMatchObject({ kind: 'messageFailed', reason: 'refused' })
  })

  it('pcc-014 ci-destroy-authoritative: destroy cancels the in-flight request', async () => {
    let seen: AbortSignal | null = null
    const f = fixture((signal) => {
      seen = signal ?? null
      return hangingSse([['token', { text: 'x' }]], signal!)
    })
    await f.backend.send('hi', [])
    await f.events(1)
    expect(seen).not.toBeNull()
    expect(seen!.aborted).toBe(false)

    f.backend.destroy()
    expect(seen!.aborted).toBe(true)

    // The half-written draft is retracted on the way out, and the fragment
    // the persona had produced so far is not committed as its answer.
    const rest = await f.drained()
    expect(rest.map((e) => e.kind)).toEqual(['draftCleared'])
  })

  it('pcc-015 ci-no-reuse-after-destroy: reuse after destroy fails fast', async () => {
    const f = fixture(() => sse(hello))
    f.backend.destroy()
    await expect(f.backend.send('hi', [])).rejects.toThrow(/destroyed/i)
    expect(f.calls).toEqual([])
  })

  it('pcc-017 ci-one-turn-at-a-time: a second send waits for the first turn to finish', async () => {
    // The coordinator keeps ONE cancellation handle and ONE open-invocation map, so two turns
    // running at once corrupt both: the second turn's controller overwrites the first's (leaving
    // `destroy` able to cancel only the newer request), and whichever turn ends first clears the
    // shared invocation map out from under the other. Nothing upstream prevents the overlap —
    // none of the chat surfaces disable the composer while a turn is in flight — so the
    // coordinator has to sequence the turns itself.
    const scripts: ScriptedSse[] = []
    const f = fixture(() => {
      const script = scriptedSse()
      scripts.push(script)
      return script.stream
    })
    const messages = () => f.calls.filter((c) => c.path.endsWith('/messages'))

    await f.backend.send('one', [])
    await f.backend.send('two', [])
    await settle()

    // The second turn is queued, not racing: its request has not been issued at all.
    expect(messages()).toHaveLength(1)
    expect(JSON.parse(String(messages()[0]!.init.body))).toEqual({ message: 'one' })

    scripts[0]!.emit('done', {})
    scripts[0]!.close()
    await f.events(2)
    await settle()

    // And it is not dropped either — it goes out once the first turn is off the wire.
    expect(messages()).toHaveLength(2)
    expect(JSON.parse(String(messages()[1]!.init.body))).toEqual({ message: 'two' })
  })

  it('pcc-018 ci-destroy-authoritative: destroy during conversation creation stops the turn', async () => {
    // The window before a turn has a controller of its own. The creation POST runs on the
    // coordinator's lifetime handle instead, and the turn re-checks after that await: a
    // creation request that had already resolved would otherwise carry straight on and post the
    // user's message into a conversation the caller believes is gone.
    let release!: () => void
    const gate = new Promise<void>((resolve) => {
      release = resolve
    })
    const f = fixture(() => sse(hello), { conversationGate: gate })

    await f.backend.send('hi', [])
    await settle()
    const created = f.calls.filter((c) => c.path.endsWith('/v1/chats'))
    expect(created).toHaveLength(1)
    const signal = created[0]!.init.signal as AbortSignal | null | undefined
    expect(signal?.aborted).toBe(false)

    f.backend.destroy()
    expect(signal?.aborted).toBe(true)

    // Resolved AFTER the destroy, standing in for a request already on its way back when the
    // surface tore down — an abort the transport had no chance to honour.
    release()
    await settle()
    expect(f.calls.filter((c) => c.path.endsWith('/messages'))).toEqual([])
  })

  it('pcc-016 ci-status-out-of-band: a retry drives status, never the transcript', async () => {
    const f = fixture(() =>
      sse([
        ['status', { phase: 'retrying', attempt: 1 }],
        ['token', { text: 'ok' }],
        ['done', {}],
      ]),
    )
    await f.backend.send('hi', [])
    const events = await f.events(3)

    expect(f.statuses).toContain('retrying')
    expect(events.map((e) => e.kind)).toEqual(['draftUpdated', 'messageReceived', 'draftCleared'])
  })

  it('ci-transport-vs-message: a failed conversation create fails the message', async () => {
    const f = fixture(() => sse(hello), { conversationOk: false })
    const localID = await f.backend.send('hi', [])
    const events = await f.events(2)

    expect(events[0]).toMatchObject({ kind: 'messageFailed', localID })
  })

  it('ci-attachments: attachments are refused rather than silently dropped', async () => {
    const f = fixture(() => sse(hello))
    await expect(
      f.backend.send('hi', [{ id: 'a', mediaType: 'image', presentation: 'inline' } as never]),
    ).rejects.toThrow(/attachment/i)
  })

  it('status clears when a turn ends, on success and on failure', async () => {
    const ok = fixture(() => sse(hello))
    await ok.backend.send('hi', [])
    await ok.events(4)
    expect(ok.statuses.at(-1)).toBeNull()

    const bad = fixture(() => sse([['error', { message: 'boom' }]]))
    await bad.backend.send('hi', [])
    await bad.events(2)
    expect(bad.statuses.at(-1)).toBeNull()
  })
})
