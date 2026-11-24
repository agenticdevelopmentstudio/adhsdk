import { afterEach, describe, expect, expectTypeOf, it, vi } from 'vitest'

import type { ChatUpdate } from '../../contract/chat/ChatUpdate'
import type { Attachment } from '../../contract/attachments/Attachment'
import type { CommandInvocation } from '../../contract/commands/CommandInvocation'
import type { Message } from '../../contract/messages/Message'
import { ShuffleBag } from '../../backends/ShuffleBag'
import { ScriptedBackend } from '../ScriptedBackend'

import { createHarness, flush } from './harness'

// Conformance vectors for the cross-platform chat contract
// (cookbook/agentic-developer-hub-sdk/sdk/contract/conformance-test-vectors.md).
// The contract types under `src/contract/` are erased at runtime, so each
// vector is exercised through the reference implementations that bind them:
// `DefaultOrchestrator`, `ScriptedBackend` and `ShuffleBag`.

function invocation(id: string, commandName: string, invokerID: string): CommandInvocation {
  return {
    id,
    commandName,
    invokerID,
    invokerKind: 'other',
    argumentsJSON: '{}',
    requestedAt: new Date('2026-01-01T00:00:00Z'),
  }
}

afterEach(() => {
  vi.restoreAllMocks()
})

describe('chat contract conformance vectors', () => {
  it.skip('chat-contract-001 ScriptedBackend start: .immediately replays at init', () => {
    // apple-only: the web ScriptedBackend has no script or start-timing option; tests drive it with emit().
  })

  it.skip('chat-contract-002 ScriptedBackend start: .onFirstSend replays once on first send', () => {
    // apple-only: the web ScriptedBackend has no script or start-timing option.
  })

  it('chat-contract-003 local ids are prefix-N and sends are recorded in order', async () => {
    const backend = new ScriptedBackend({ localIDPrefix: 'local' })
    expect(await backend.send('a', [])).toBe('local-1')
    expect(await backend.send('b', [])).toBe('local-2')
    expect(backend.sent).toEqual([
      { localID: 'local-1', text: 'a', attachments: [] },
      { localID: 'local-2', text: 'b', attachments: [] },
    ])
  })

  it.skip('chat-contract-004 ScriptedBackend replays two turns serially', () => {
    // apple-only: the web ScriptedBackend has no replay chain; events are emitted by the test.
  })

  it.skip('chat-contract-005 Beat delay leads the event', () => {
    // apple-only: the web ScriptedBackend has no Beat/delay script.
  })

  it('chat-contract-006 draftUpdated replaces the stored text, never appends', async () => {
    const h = createHarness()
    h.backend.emit({ kind: 'draftUpdated', participantID: 'p1', text: 'Hel', attachments: [] })
    h.backend.emit({ kind: 'draftUpdated', participantID: 'p1', text: 'Hello', attachments: [] })
    await flush()
    expect(h.orchestrator.activeDrafts).toHaveLength(1)
    expect(h.orchestrator.activeDrafts[0]?.text).toBe('Hello')
  })

  it('chat-contract-007 an aborted draft disappears and never reaches messages', async () => {
    const h = createHarness()
    h.backend.emit({ kind: 'draftUpdated', participantID: 'p1', text: 'Hi', attachments: [] })
    await flush()
    expect(h.orchestrator.activeDrafts.map((d) => d.participantID)).toEqual(['p1'])
    expect(h.orchestrator.messages).toHaveLength(0)

    h.backend.emit({ kind: 'draftCleared', participantID: 'p1' })
    await flush()
    expect(h.orchestrator.activeDrafts).toHaveLength(0)
    expect(h.orchestrator.messages).toHaveLength(0)
  })

  it('chat-contract-008 a second readMarkerAdvanced replaces the first cursor', async () => {
    const h = createHarness()
    h.backend.emit({ kind: 'readMarkerAdvanced', participantID: 'p1', upToMessageID: 'm1', at: new Date(1000) })
    h.backend.emit({ kind: 'readMarkerAdvanced', participantID: 'p1', upToMessageID: 'm5', at: new Date(2000) })
    await flush()
    const forP1 = h.orchestrator.readMarkers.filter((r) => r.participantID === 'p1')
    expect(forP1).toHaveLength(1)
    expect(forP1[0]?.upToMessageID).toBe('m5')
  })

  it('chat-contract-009 parallel invocations stay distinct; completion fills only its own entry', async () => {
    const h = createHarness()
    h.backend.emit({
      kind: 'commandInvoked',
      participantID: h.persona.id,
      invocation: invocation('inv-1', 'search', h.persona.id),
    })
    h.backend.emit({
      kind: 'commandInvoked',
      participantID: h.persona.id,
      invocation: invocation('inv-2', 'search', h.persona.id),
    })
    h.backend.emit({
      kind: 'commandCompleted',
      participantID: h.persona.id,
      result: { invocationID: 'inv-2', ok: true, resultJSON: '{}', completedAt: new Date() },
    })
    await flush()
    const cmds = h.orchestrator.activeCommands
    expect(cmds.map((c) => c.invocation.id)).toEqual(['inv-1', 'inv-2'])
    expect(cmds[0]?.result).toBeUndefined()
    expect(cmds[1]?.result?.invocationID).toBe('inv-2')
  })

  it('chat-contract-010 a result for an unknown invocation is dropped', async () => {
    const h = createHarness()
    h.backend.emit({
      kind: 'commandCompleted',
      participantID: h.persona.id,
      result: { invocationID: 'inv-unknown', ok: true, completedAt: new Date() },
    })
    await flush()
    expect(h.orchestrator.activeCommands).toHaveLength(0)
    expect(h.updates).toEqual([])
  })

  it.skip('chat-contract-011 statusChanged stays out of band', () => {
    // apple-only: web InboundEvent has no statusChanged event and the web ChatViewModel has no statuses map.
  })

  it('chat-contract-012 messagesChanged carries no payload; observers must re-read messages', async () => {
    const h = createHarness()
    expectTypeOf<Extract<ChatUpdate, { kind: 'messagesChanged' }>>().toEqualTypeOf<{
      readonly kind: 'messagesChanged'
    }>()

    const message: Message = {
      id: 'srv-1',
      localID: 'l-1',
      senderID: h.persona.id,
      text: 'hi',
      attachments: [],
      deliveryStatus: { kind: 'received' },
    }
    h.backend.emit({ kind: 'messageReceived', message })
    await flush()
    const update = h.updates.find((u) => u.kind === 'messagesChanged')
    expect(update).toBeDefined()
    expect(Object.keys(update as object)).toEqual(['kind'])
    expect(h.orchestrator.messages).toEqual([message])
  })

  it('chat-contract-013 ShuffleBag never repeats back to back within a pass', () => {
    // Within one pass every item is distinct, so no adjacent pair is equal.
    const bag = new ShuffleBag(['a', 'b', 'c', 'd'])
    const pass = [bag.next(), bag.next(), bag.next(), bag.next()]
    for (let i = 1; i < pass.length; i += 1) expect(pass[i]).not.toBe(pass[i - 1])
  })

  it('chat-contract-013b ShuffleBag never repeats back to back across a refill', () => {
    // First shuffle: 0.999 keeps the identity order, so the bag draws d,c,b,a (last draw a).
    // Second shuffle: 0 yields [b,c,d,a], which would open with a again without the guard.
    vi.spyOn(Math, 'random').mockReturnValueOnce(0.999).mockReturnValueOnce(0.999).mockReturnValueOnce(0.999).mockReturnValue(0)
    const bag = new ShuffleBag(['a', 'b', 'c', 'd'])
    const draws = Array.from({ length: 8 }, () => bag.next())
    for (let i = 1; i < draws.length; i += 1) expect(draws[i]).not.toBe(draws[i - 1])
  })

  it('chat-contract-014 ShuffleBag draws every element once before any repeat', () => {
    const items = ['a', 'b', 'c', 'd']
    const bag = new ShuffleBag(items)
    const draws = [bag.next(), bag.next(), bag.next(), bag.next()]
    expect([...draws].sort()).toEqual(items)
  })

  it('chat-contract-015 a single-element ShuffleBag returns it every time', () => {
    const bag = new ShuffleBag(['only'])
    expect([bag.next(), bag.next()]).toEqual(['only', 'only'])
  })

  it('chat-contract-016 an empty ShuffleBag is rejected at construction on web', () => {
    // apple returns nil from next(); web throws when constructed (see the vector's divergence note).
    expect(() => new ShuffleBag<string>([])).toThrow('ShuffleBag requires at least one item')
  })

  it.skip('chat-contract-017 ChatStatusKind maps TurnStatus exhaustively', () => {
    // apple-only: ChatStatusKind and TurnStatus exist only in the Swift SDK.
  })

  it('chat-contract-018 web removes an activeCommands entry once the participant turn ends', async () => {
    const h = createHarness()
    h.backend.emit({
      kind: 'commandInvoked',
      participantID: h.persona.id,
      invocation: invocation('inv-1', 'search', h.persona.id),
    })
    h.backend.emit({
      kind: 'commandCompleted',
      participantID: h.persona.id,
      result: { invocationID: 'inv-1', ok: true, completedAt: new Date() },
    })
    await flush()
    expect(h.orchestrator.activeCommands[0]?.result?.invocationID).toBe('inv-1')

    h.backend.emit({ kind: 'draftCleared', participantID: h.persona.id })
    await flush()
    expect(h.orchestrator.activeCommands).toHaveLength(0)
  })

  it('chat-contract-019 setLocalTyping is recorded only and starts nothing', async () => {
    const backend = new ScriptedBackend()
    await backend.setLocalTyping(true)
    expect(backend.typingCalls).toEqual([true])
    expect(backend.sent).toEqual([])
    expect(backend.widgetResponses).toEqual([])
  })

  it('chat-contract-020 markRead advances the local cursor with one entry for the whole range', async () => {
    const h = createHarness()
    for (const n of [1, 2, 3, 4, 5]) {
      h.backend.emit({
        kind: 'messageReceived',
        message: {
          id: `m${n}`,
          localID: `l${n}`,
          senderID: h.persona.id,
          text: `t${n}`,
          attachments: [],
          deliveryStatus: { kind: 'received' },
        },
      })
    }
    await flush()
    await h.orchestrator.markRead('m3')
    const mine = h.orchestrator.readMarkers.filter((r) => r.participantID === h.localUser.id)
    expect(mine).toHaveLength(1)
    expect(mine[0]?.upToMessageID).toBe('m3')
  })

  it('chat-contract-021 web emits no participantsChanged for a departure of an unknown id', async () => {
    const h = createHarness()
    h.backend.emit({ kind: 'participantDeparted', participantID: 'ghost' })
    await flush()
    expect(h.updates.some((u) => u.kind === 'participantsChanged')).toBe(false)
    expect(h.orchestrator.participants.map((p) => p.id)).toEqual([h.localUser.id, h.persona.id])
  })

  it('chat-contract-022 a message with no id/timestamp and an attachment with no name/size are accepted', async () => {
    const h = createHarness()
    const attachment: Attachment = {
      id: 'att-1',
      mediaType: { identifier: 'image/png' },
      source: { kind: 'remote', url: new URL('https://example.com/a.png') },
      presentation: 'attached',
    }
    const message: Message = {
      localID: 'l-1',
      senderID: h.persona.id,
      text: 'look',
      attachments: [attachment],
      deliveryStatus: { kind: 'received' },
    }
    h.backend.emit({ kind: 'messageReceived', message })
    await flush()
    const stored = h.orchestrator.messages[0]
    expect(stored?.id).toBeUndefined()
    expect(stored?.timestamp).toBeUndefined()
    expect(stored?.attachments[0]?.displayName).toBeUndefined()
    expect(stored?.attachments[0]?.byteSize).toBeUndefined()
    expect(h.updates.some((u) => u.kind === 'error')).toBe(false)
  })
})
