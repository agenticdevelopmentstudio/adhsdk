import { describe, expect, it, vi } from 'vitest'
import { act, renderHook } from '@testing-library/react'

import { PersonaChatBackend, type TurnStatus } from '../backends/PersonaChatBackend'
import { hangingSse, scriptedSse, sse, type ScriptedSse } from '../backends/__tests__/sse'
import { useChatSession, type ChatSession } from '../hooks/useChatSession'
import { DefaultOrchestrator } from '../runtime/DefaultOrchestrator'
import { InMemoryPermissionStore } from '../runtime/InMemoryPermissionStore'
import type { ChatMessage } from '../types'

/**
 * Conformance vectors for the `persona-chat` recipe.
 * docs/specs/recipes/persona-chat.md — one `it` per `pc-*` vector, named for
 * the integration requirement it holds the composition to.
 *
 * Where the ingredient vectors stop at the coordinator's `InboundEvent`s,
 * these run the whole way: an adh SSE body in, rendered `ChatMessage`s out.
 * That is the only place several of these claims are checkable at all — that
 * the draft becomes exactly one message, that tool activity stays out of the
 * reply text, that a 200-with-an-error is not an empty successful turn.
 */

const PERSONA = { name: 'Aria', avatar: 'A' }

interface Call {
  readonly path: string
  readonly init: RequestInit
}

interface Fixture {
  readonly backend: PersonaChatBackend
  readonly calls: Call[]
  readonly statuses: Array<TurnStatus | null>
  readonly conversationPosts: () => number
}

function personaBackend(
  streamFor: (signal: AbortSignal | null | undefined) => ReadableStream<Uint8Array>,
): Fixture {
  const calls: Call[] = []
  const statuses: Array<TurnStatus | null> = []
  const backend = new PersonaChatBackend({
    personaSlug: 'aria',
    authorize: async (path, init) => {
      calls.push({ path, init })
      if (path.endsWith('/v1/chats')) {
        return new Response(JSON.stringify({ id: 'conv-1' }), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        })
      }
      return new Response(streamFor(init.signal as AbortSignal | null | undefined), {
        status: 200,
        headers: { 'content-type': 'text/event-stream' },
      })
    },
    onStatus: (s) => statuses.push(s),
  })
  return {
    backend,
    calls,
    statuses,
    conversationPosts: () =>
      calls.filter((c) => c.path.endsWith('/v1/chats') && c.init.method === 'POST').length,
  }
}

/**
 * Renders the hook and records the transcript at every render, so vectors can
 * assert on what the surface showed WHILE the turn was running and not only on
 * where it ended up. A draft that never appeared and a draft that appeared and
 * committed look identical from the final state alone.
 */
function renderSession(options: Parameters<typeof useChatSession>[0]) {
  const frames: ChatMessage[][] = []
  const view = renderHook(() => {
    const session = useChatSession(options)
    frames.push(session.messages)
    return session
  })
  return { ...view, frames }
}

/** Let the coordinator's stream reader and the orchestrator's loop run out. */
async function settle(): Promise<void> {
  await act(async () => {
    for (let i = 0; i < 40; i++) await Promise.resolve()
  })
}

/**
 * Deliver one SSE event and let the surface render before the next one. The
 * flush has to happen INSIDE `act`, or React batches the whole turn into a
 * single render and the intermediate states stop existing to assert on.
 */
async function emit(script: ScriptedSse, event: string, data: unknown): Promise<void> {
  await act(async () => {
    script.emit(event, data)
    for (let i = 0; i < 40; i++) await Promise.resolve()
  })
}

async function send(result: { current: ChatSession }, text: string): Promise<void> {
  await act(async () => {
    result.current.sendMessage(text)
  })
  await settle()
}

describe('persona-chat recipe', () => {
  // pc-orchestrator-between: the control talks to the orchestrator, and the
  // orchestrator talks to the coordinator. If the control could reach the
  // coordinator it would eventually be tempted to, and the seam that makes
  // this composition portable would quietly stop existing.
  it('pc-001 routes a send through the orchestrator, and hands the control no coordinator', async () => {
    const fixture = personaBackend(() => sse([['token', { text: 'hi' }], ['done', {}]]))
    const { result, unmount } = renderSession({ backend: fixture.backend, persona: PERSONA })

    await send(result, 'hello')

    const messagePost = fixture.calls.find((c) => c.path.includes('/messages'))
    expect(messagePost).toBeDefined()
    expect(JSON.parse(String(messagePost!.init.body))).toMatchObject({ message: 'hello' })
    expect(Object.keys(result.current).sort()).toEqual([
      'isTyping',
      'messages',
      'say',
      'sayStream',
      'selectMessage',
      'selectedIndex',
      'sendMessage',
    ])
    unmount()
  })

  // pc-draft-rendering: the draft is what the user watches arrive. It has to
  // render as it grows and then be REPLACED by the committed message — not
  // joined by it.
  it('pc-002 renders the growing draft, then exactly one committed message', async () => {
    const script = scriptedSse()
    const fixture = personaBackend(() => script.stream)
    const { result, frames, unmount } = renderSession({
      backend: fixture.backend,
      persona: PERSONA,
    })

    await send(result, 'hey')
    await emit(script, 'token', { text: 'Hel' })
    await emit(script, 'token', { text: 'lo' })
    await emit(script, 'done', {})
    script.close()
    await settle()

    const personaTexts = frames.map((f) => f.filter((m) => m.isPersona).map((m) => m.text))
    expect(personaTexts).toContainEqual(['Hel'])
    expect(personaTexts).toContainEqual(['Hello'])

    const persona = result.current.messages.filter((m) => m.isPersona)
    expect(persona).toHaveLength(1)
    expect(persona[0]!.text).toBe('Hello')
    expect(persona[0]!.isStreaming).toBeFalsy()
    unmount()
  })

  it('pc-003 commits an empty reply rather than leaving a draft open', async () => {
    const fixture = personaBackend(() => sse([['done', {}]]))
    const { result, unmount } = renderSession({ backend: fixture.backend, persona: PERSONA })

    await send(result, 'hey')

    const persona = result.current.messages.filter((m) => m.isPersona)
    expect(persona).toHaveLength(1)
    expect(persona[0]!.text).toBe('')
    expect(result.current.messages.some((m) => m.isStreaming)).toBe(false)
    unmount()
  })

  // pc-status-separate: "thinking" is a property of the request, not something
  // that was said. Folding it into the transcript would put words in the
  // persona's mouth that it never produced and that scroll back forever.
  it('pc-004 reports turn phases to the status sink and never into the transcript', async () => {
    const fixture = personaBackend(() => sse([['token', { text: 'sure' }], ['done', {}]]))
    const { result, unmount } = renderSession({ backend: fixture.backend, persona: PERSONA })

    await send(result, 'hey')

    expect(fixture.statuses[0]).toBe('thinking')
    expect(fixture.statuses).toContain('responding')
    expect(fixture.statuses[fixture.statuses.length - 1]).toBeNull()
    const transcript = result.current.messages.map((m) => m.text).join(' ')
    expect(transcript).not.toMatch(/thinking|responding|retrying/)
    unmount()
  })

  it('pc-005 clears the status and surfaces the failure when a turn dies mid-stream', async () => {
    const fixture = personaBackend(() =>
      sse([['token', { text: 'par' }], ['error', { message: 'upstream exploded' }]]),
    )
    const { result, unmount } = renderSession({ backend: fixture.backend, persona: PERSONA })

    await send(result, 'hey')

    expect(fixture.statuses[fixture.statuses.length - 1]).toBeNull()
    const failed = result.current.messages.find((m) => m.failure !== undefined)
    expect(failed?.failure).toContain('upstream exploded')
    expect(result.current.messages.some((m) => m.isStreaming)).toBe(false)
    unmount()
  })

  // pc-single-consumer: two surfaces, one conversation. `inboundEvents` is a
  // single-consumer stream, so a second surface that consumed it directly
  // would not mirror the first — it would STEAL half its events, and the two
  // transcripts would each hold a different subset of the reply.
  it('pc-006 renders identical state on two surfaces sharing one orchestrator', async () => {
    const fixture = personaBackend(() =>
      sse([['token', { text: 'shared' }], ['done', {}]]),
    )
    const orchestrator = new DefaultOrchestrator({
      conversationID: 'conv-shared',
      localParticipantID: 'local',
      initialParticipants: [],
      commands: [],
      observingHooks: [],
      gatingHooks: [],
      permissionStore: new InMemoryPermissionStore(),
      backend: fixture.backend,
      display: {
        showAvatars: true,
        showReadReceipts: false,
        showTypingIndicators: true,
        allowJoining: false,
        allowDeparting: false,
        reducedMotion: false,
      },
    })
    orchestrator.start()

    const a = renderSession({ orchestrator, persona: PERSONA, personaID: 'aria' })
    const b = renderSession({ orchestrator, persona: PERSONA, personaID: 'aria' })

    await send(a.result, 'hey')

    expect(a.result.current.messages.map((m) => m.text)).toEqual(['hey', 'shared'])
    expect(b.result.current.messages.map((m) => m.text)).toEqual(['hey', 'shared'])
    a.unmount()
    b.unmount()
    fixture.backend.destroy()
  })

  // pc-coordinator-stability: a re-render is not a new conversation. Rebuilding
  // the coordinator per render would open a fresh adh conversation on every
  // pass and lose the history behind it, silently — the UI would look fine and
  // the persona would have amnesia.
  it('pc-007 keeps one conversation across re-renders', async () => {
    const fixture = personaBackend(() => sse([['token', { text: 'ok' }], ['done', {}]]))
    const { result, rerender, unmount } = renderSession({
      backend: fixture.backend,
      persona: PERSONA,
    })

    await send(result, 'first')
    act(() => rerender())
    act(() => rerender())
    await send(result, 'second')

    expect(fixture.conversationPosts()).toBe(1)
    unmount()
  })

  it('pc-008 cancels the request and commits nothing when the surface goes away mid-turn', async () => {
    const fixture = personaBackend((signal) =>
      hangingSse([['token', { text: 'half' }]], signal!),
    )
    const { result, unmount } = renderSession({ backend: fixture.backend, persona: PERSONA })

    await act(async () => {
      result.current.sendMessage('hey')
    })
    await settle()
    expect(result.current.messages.some((m) => m.isStreaming)).toBe(true)

    const messagePost = fixture.calls.find((c) => c.path.includes('/messages'))
    const signal = messagePost!.init.signal as AbortSignal
    expect(signal.aborted).toBe(false)

    unmount()
    await settle()

    expect(signal.aborted).toBe(true)
    expect(result.current.messages.filter((m) => m.isPersona && !m.isStreaming)).toHaveLength(0)
  })

  // pc-tool-display: a tool call is something the persona DID, not something it
  // said. Rendering it into the reply text is the failure this pins — it reads
  // as prose, commits into the message, and cannot be styled or hidden.
  it('pc-009 shows tool activity beside the reply, not inside it', async () => {
    const script = scriptedSse()
    const fixture = personaBackend(() => script.stream)
    const { frames, result, unmount } = renderSession({
      backend: fixture.backend,
      persona: PERSONA,
    })

    await send(result, 'find x')
    await emit(script, 'token', { text: 'Looking' })
    await emit(script, 'tool_call_started', { name: 'search', arguments: '{"q":"x"}' })
    const running = result.current.messages.filter((m) => m.toolCalls?.length)
    expect(running[0]?.toolCalls?.[0]).toMatchObject({ name: 'search', status: 'started' })
    await emit(script, 'tool_call_completed', { name: 'search', ok: true, result: '{"hits":2}' })
    await emit(script, 'token', { text: ' — found it.' })
    await emit(script, 'done', {})
    script.close()
    await settle()

    const withTools = frames.flat().filter((m) => m.toolCalls && m.toolCalls.length > 0)
    expect(withTools.length).toBeGreaterThan(0)
    expect(withTools.some((m) => m.toolCalls![0]!.name === 'search')).toBe(true)
    expect(withTools.some((m) => m.toolCalls!.some((c) => c.status === 'completed'))).toBe(true)
    // The reply reads exactly as written. No tool name, no arguments, no result.
    const reply = result.current.messages.find((m) => m.isPersona)
    expect(reply!.text).toBe('Looking — found it.')
    unmount()
  })

  // pc-control-is-passive: adh answers 200 and reports failure in-band, so
  // "the request succeeded" says nothing about whether the turn did. A control
  // that reads the status code shows a blank, cheerful, empty reply.
  it('pc-010 shows a failure for an in-band error under HTTP 200', async () => {
    const fixture = personaBackend(() => sse([['error', { message: 'model refused' }]]))
    const { result, unmount } = renderSession({ backend: fixture.backend, persona: PERSONA })

    await send(result, 'hey')

    const failed = result.current.messages.find((m) => m.failure !== undefined)
    expect(failed?.failure).toContain('model refused')
    expect(result.current.messages.filter((m) => m.isPersona)).toHaveLength(0)
    unmount()
  })

  it('does not open a conversation before the first message', async () => {
    const fixture = personaBackend(() => sse([['done', {}]]))
    const { unmount } = renderSession({ backend: fixture.backend, persona: PERSONA })
    await settle()
    expect(fixture.calls).toHaveLength(0)
    unmount()
  })

  it('types a scripted line into the transcript as a draft, then commits it whole', async () => {
    vi.useFakeTimers()
    try {
      const fixture = personaBackend(() => sse([['done', {}]]))
      const { result, frames, unmount } = renderSession({
        backend: fixture.backend,
        persona: PERSONA,
        personaID: 'aria',
      })

      let settled = false
      act(() => {
        void result.current.say('welcome.').then(() => {
          settled = true
        })
      })
      for (let tick = 0; tick < 16; tick++) {
        await act(async () => {
          vi.advanceTimersByTime(60)
          for (let i = 0; i < 40; i++) await Promise.resolve()
        })
      }

      expect(settled).toBe(true)
      // Asserting on one particular frame ('wel') was flaky, and rightly so:
      // the typing delay is randomised, so which prefixes get their own render
      // is not a property of the code. The claim is that the line was TYPED —
      // every draft frame is a real prefix, and at least one is partial.
      const typed = frames
        .flat()
        .filter((m) => m.isStreaming)
        .map((m) => m.text)
      expect(typed.length).toBeGreaterThan(0)
      expect(typed.every((t) => 'welcome.'.startsWith(t))).toBe(true)
      expect(typed.some((t) => t.length > 0 && t.length < 'welcome.'.length)).toBe(true)
      expect(result.current.messages.map((m) => m.text)).toEqual(['welcome.'])
      expect(result.current.messages[0]!.isStreaming).toBeFalsy()
      unmount()
    } finally {
      vi.useRealTimers()
    }
  })
})
