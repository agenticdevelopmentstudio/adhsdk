import { describe, expect, it, vi } from 'vitest'

import type { InteractiveWidget } from '../../contract/attachments/InteractiveWidget'
import type { InboundEvent } from '../../contract/backend/InboundEvent'
import type { ChatUpdate } from '../../contract/chat/ChatUpdate'
import type { CommandInvocation } from '../../contract/commands/CommandInvocation'
import type { CommandResult } from '../../contract/commands/CommandResult'
import type { ChatConfig } from '../../contract/configuration/ChatConfig'
import type { Message } from '../../contract/messages/Message'
import { DefaultOrchestrator } from '../DefaultOrchestrator'
import { InMemoryPermissionStore } from '../InMemoryPermissionStore'
import { ScriptedBackend } from '../ScriptedBackend'

import { createHarness, flush } from './harness'

// ccr-001 through ccr-022 are exercised by the named tests in scenarios.test.ts;
// this file covers ccr-023 through ccr-039.

function msg(senderID: string, id: string, text = 't'): Message {
  return {
    id,
    localID: `l-${id}`,
    senderID,
    text,
    attachments: [],
    timestamp: new Date('2026-01-01T00:00:00Z'),
    deliveryStatus: { kind: 'received' },
  }
}

const widget: InteractiveWidget = {
  id: 'wid-1',
  mediaType: { identifier: 'application/json' },
  source: { kind: 'inline', data: new Uint8Array([0x7b, 0x7d]) },
  presentation: 'inline',
  hasResponse: true,
}

const invocation: CommandInvocation = {
  id: 'inv-1',
  commandName: 'cmd',
  invokerID: 'persona-1',
  invokerKind: 'other',
  argumentsJSON: '{}',
  requestedAt: new Date('2026-01-01T00:00:00Z'),
}

const kinds = (updates: ChatUpdate[]): string[] => updates.map((u) => u.kind)

describe('runtime conformance vectors (unverified set)', () => {
  it('ccr-023 send mints sequential local ids recorded in call order', async () => {
    const backend = new ScriptedBackend()
    const a = await backend.send('one', [])
    const b = await backend.send('two', [])
    expect([a, b]).toEqual(['local-1', 'local-2'])
    expect(backend.sent.map((s) => [s.localID, s.text])).toEqual([
      ['local-1', 'one'],
      ['local-2', 'two'],
    ])
  })

  it('ccr-024 close drains the queue before ending', async () => {
    const backend = new ScriptedBackend()
    const eventA: InboundEvent = { kind: 'transportError', message: 'a' }
    backend.emit(eventA)
    backend.close()
    const it = backend.inboundEvents[Symbol.asyncIterator]()
    const first = await it.next()
    expect(first.done).toBe(false)
    expect(first.value).toEqual(eventA)
    const second = await it.next()
    expect(second.done).toBe(true)
  })

  it('ccr-025 start is idempotent', async () => {
    const h = createHarness()
    h.orchestrator.start()
    h.backend.emit({ kind: 'messageReceived', message: msg(h.persona.id, 'srv-1') })
    await flush()
    expect(h.orchestrator.messages).toHaveLength(1)
    expect(kinds(h.updates).filter((k) => k === 'messagesChanged')).toHaveLength(1)
  })

  it('ccr-026 stop cancels the iterator', async () => {
    const h = createHarness()
    await flush()
    h.orchestrator.stop()
    await flush()
    h.backend.emit({ kind: 'messageReceived', message: msg(h.persona.id, 'srv-1') })
    await flush()
    expect(h.orchestrator.messages).toHaveLength(0)
  })

  it('ccr-027 stop before start locks the loop', async () => {
    const backend = new ScriptedBackend()
    const base = createHarness()
    const config: ChatConfig = {
      conversationID: 'c',
      localParticipantID: base.localUser.id,
      initialParticipants: [base.localUser, base.persona],
      commands: [],
      observingHooks: [],
      gatingHooks: [],
      permissionStore: new InMemoryPermissionStore(),
      backend,
      display: base.orchestrator.displayConfig,
    }
    const orchestrator = new DefaultOrchestrator(config)
    orchestrator.stop()
    orchestrator.start()
    await flush()
    backend.emit({ kind: 'messageReceived', message: msg(base.persona.id, 'srv-1') })
    await flush()
    expect(orchestrator.messages).toHaveLength(0)
  })

  it('ccr-028 a rejected send leaves no echo, rethrows, and notifies an error', async () => {
    const h = createHarness()
    const failure = new Error('offline')
    vi.spyOn(h.backend, 'send').mockRejectedValue(failure)
    await expect(h.orchestrator.submitMessage('hi', [])).rejects.toBe(failure)
    expect(h.orchestrator.messages).toHaveLength(0)
    expect(h.updates).toContainEqual({ kind: 'error', message: 'offline' })
  })

  it('ccr-029 a rejected widget response rolls the widget back', async () => {
    const h = createHarness()
    h.backend.emit({ kind: 'widgetPresented', messageID: 'srv-7', widget })
    await flush()
    const failure = new Error('nope')
    vi.spyOn(h.backend, 'submitWidgetResponse').mockRejectedValue(failure)
    await expect(
      h.orchestrator.respondToWidget({
        widgetID: 'wid-1',
        respondingParticipantID: h.localUser.id,
        payloadJSON: '{}',
      }),
    ).rejects.toBe(failure)
    expect(h.orchestrator.pendingWidgets).toHaveLength(1)
    expect(kinds(h.updates).filter((k) => k === 'pendingWidgetsChanged')).toHaveLength(3)
    // presented (1) + removed (2) + rolled back (3)
    expect(h.updates.filter((u) => u.kind === 'error')).toEqual([{ kind: 'error', message: 'nope' }])
  })

  it('ccr-030 a response for an unknown widget is forwarded without a pendingWidgetsChanged', async () => {
    const h = createHarness()
    await h.orchestrator.respondToWidget({
      widgetID: 'unknown',
      respondingParticipantID: h.localUser.id,
      payloadJSON: '{}',
    })
    expect(h.backend.widgetResponses).toHaveLength(1)
    expect(kinds(h.updates)).not.toContain('pendingWidgetsChanged')
  })

  it('ccr-031 the local cursor does not regress by message position', async () => {
    const h = createHarness()
    h.orchestrator.deliver({ kind: 'messageReceived', message: msg(h.persona.id, 'srv-1') })
    h.orchestrator.deliver({ kind: 'messageReceived', message: msg(h.persona.id, 'srv-2') })
    await h.orchestrator.markRead('srv-2')
    await h.orchestrator.markRead('srv-1')
    expect(h.orchestrator.readMarkers).toHaveLength(1)
    expect(h.orchestrator.readMarkers[0]?.upToMessageID).toBe('srv-2')
  })

  it('ccr-032 a peer cursor does not regress by time when messages are unknown', async () => {
    const h = createHarness()
    const t2 = new Date('2026-01-01T00:00:02Z')
    const t1 = new Date('2026-01-01T00:00:01Z')
    h.backend.emit({ kind: 'readMarkerAdvanced', participantID: h.persona.id, upToMessageID: 'x', at: t2 })
    await flush()
    h.backend.emit({ kind: 'readMarkerAdvanced', participantID: h.persona.id, upToMessageID: 'y', at: t1 })
    await flush()
    expect(h.orchestrator.readMarkers).toHaveLength(1)
    expect(h.orchestrator.readMarkers[0]?.upToMessageID).toBe('x')
    expect(kinds(h.updates).filter((k) => k === 'readMarkersChanged')).toHaveLength(1)
  })

  it('ccr-033 draftCleared also clears the participant commands', async () => {
    const h = createHarness()
    h.backend.emit({ kind: 'commandInvoked', participantID: h.persona.id, invocation })
    h.backend.emit({
      kind: 'draftUpdated',
      participantID: h.persona.id,
      text: 'working',
      attachments: [],
    })
    await flush()
    expect(h.orchestrator.activeDrafts).toHaveLength(1)
    expect(h.orchestrator.activeCommands).toHaveLength(1)
    h.backend.emit({ kind: 'draftCleared', participantID: h.persona.id })
    await flush()
    expect(h.orchestrator.activeDrafts).toEqual([])
    expect(h.orchestrator.activeCommands).toEqual([])
  })

  it('ccr-034 commandInvoked appends an active entry with no result', async () => {
    const h = createHarness()
    h.backend.emit({ kind: 'commandInvoked', participantID: 'p', invocation })
    await flush()
    expect(h.orchestrator.activeCommands).toHaveLength(1)
    const entry = h.orchestrator.activeCommands[0]
    expect(entry?.participantID).toBe('p')
    expect(entry?.invocation).toBe(invocation)
    expect(entry?.result).toBeUndefined()
    expect(kinds(h.updates)).toContain('activeCommandsChanged')
  })

  it('ccr-035 commandCompleted sets the result on the matching entry only', async () => {
    const h = createHarness()
    h.backend.emit({ kind: 'commandInvoked', participantID: 'p', invocation })
    await flush()
    h.updates.length = 0
    const result: CommandResult = {
      invocationID: 'inv-1',
      ok: true,
      resultJSON: '{}',
      completedAt: new Date('2026-01-01T00:00:05Z'),
    }
    h.backend.emit({ kind: 'commandCompleted', result })
    await flush()
    const entry = h.orchestrator.activeCommands[0]
    expect(entry?.result).toEqual(result)
    expect(entry?.participantID).toBe('p')
    expect(entry?.invocation).toBe(invocation)
    expect(kinds(h.updates)).toEqual(['activeCommandsChanged'])
  })

  it('ccr-036 commandCompleted for an unknown invocation changes nothing', async () => {
    const h = createHarness()
    h.backend.emit({ kind: 'commandInvoked', participantID: 'p', invocation })
    await flush()
    h.updates.length = 0
    const before = h.orchestrator.activeCommands
    h.backend.emit({
      kind: 'commandCompleted',
      result: { invocationID: 'nope', ok: true, completedAt: new Date() },
    })
    await flush()
    expect(h.orchestrator.activeCommands).toBe(before)
    expect(h.updates).toEqual([])
  })

  it('ccr-037 responding to an unknown permission prompt is ignored', async () => {
    const h = createHarness()
    const store = vi.spyOn(h.permissionStore, 'remember')
    await h.orchestrator.respondToPermission('missing', 'allowAlways')
    expect(h.orchestrator.pendingPermissions).toEqual([])
    expect(h.updates).toEqual([])
    expect(store).not.toHaveBeenCalled()
  })

  it('ccr-038 deliver bypasses the backend', () => {
    const h = createHarness()
    const message = msg(h.persona.id, 'srv-1')
    h.orchestrator.deliver({ kind: 'messageReceived', message })
    expect(h.orchestrator.messages).toEqual([message])
    expect(h.backend.sent).toEqual([])
    expect(h.backend.typingCalls).toEqual([])
    expect(h.backend.widgetResponses).toEqual([])
  })

  it('ccr-039 iterator return unparks the pending next exactly once', async () => {
    const backend = new ScriptedBackend()
    const it = backend.inboundEvents[Symbol.asyncIterator]()
    const onResolve = vi.fn()
    const parked = it.next().then(onResolve)
    await flush()
    expect(onResolve).not.toHaveBeenCalled()
    await it.return?.()
    await parked
    expect(onResolve).toHaveBeenCalledTimes(1)
    expect(onResolve).toHaveBeenCalledWith({ value: undefined, done: true })
    backend.emit({ kind: 'transportError', message: 'late' })
    backend.close()
    await flush()
    expect(onResolve).toHaveBeenCalledTimes(1)
  })
})

