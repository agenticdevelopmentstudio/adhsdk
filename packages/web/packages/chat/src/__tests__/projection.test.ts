import { describe, it, expect } from 'vitest'
import {
  RICH_DISPLAY_MEDIA_TYPE,
  decodeRichDisplay,
  encodeRichDisplay,
} from '../projection/richContent'
import { draftMessageID, projectMessages, type ProjectionParticipants } from '../projection/toChatMessages'
import type { Attachment } from '../contract/attachments/Attachment'
import type { Message } from '../contract/messages/Message'
import type { ActiveDraft } from '../contract/chat/ActiveDraft'
import type { ActiveCommand } from '../contract/commands/ActiveCommand'

const D = new Date('2026-01-02T03:04:05Z')
const parts: ProjectionParticipants = {
  persona: { name: 'Persona' },
  user: { name: 'User' },
  localParticipantID: 'local',
}

const msg = (over: Partial<Message> = {}): Message => ({
  localID: 'm1',
  senderID: 'local',
  text: 'hi',
  attachments: [],
  deliveryStatus: { kind: 'sent' },
  ...over,
})
const draft = (over: Partial<ActiveDraft> = {}): ActiveDraft => ({
  participantID: 'bot',
  text: 'typing',
  attachments: [],
  ...over,
})
const command = (over: Partial<ActiveCommand> = {}): ActiveCommand => ({
  participantID: 'bot',
  invocation: {
    id: 'i1',
    commandName: 'search',
    invokerID: 'bot',
    invokerKind: 'participant' as never,
    argumentsJSON: '{}',
    requestedAt: D,
  },
  ...over,
})
const view = (
  messages: Message[] = [],
  activeDrafts: ActiveDraft[] = [],
  activeCommands: ActiveCommand[] = [],
) => ({ messages, activeDrafts, activeCommands })
const stamp = () => D
const rich = (d: Parameters<typeof encodeRichDisplay>[0], id = 'a1') => encodeRichDisplay(d, id)!

describe('chat projection conformance vectors', () => {
  it('ccp-001 an empty display encodes to null', () => {
    expect(encodeRichDisplay({}, 'm1:display')).toBeNull()
  })

  it('ccp-002 a popover encodes to an inline attachment', () => {
    const a = encodeRichDisplay({ popover: { title: 'Info' } } as never, 'm1:display')!
    expect(a.id).toBe('m1:display')
    expect(a.mediaType.identifier).toBe(RICH_DISPLAY_MEDIA_TYPE)
    expect(a.presentation).toBe('inline')
    expect(a.source.kind).toBe('inline')
    const data = (a.source as { data: Uint8Array }).data
    expect(new TextDecoder().decode(data)).toBe('{"popover":{"title":"Info"}}')
  })

  it('ccp-003 decode finds the rich-display attachment among others', () => {
    const png = {
      id: 'p',
      mediaType: { identifier: 'image/png' },
      source: { kind: 'inline', data: new Uint8Array([1]) },
      presentation: 'inline',
    } as Attachment
    const r = rich({ content: [{ type: 'link', url: 'https://x' }] }, 'a2')
    expect(decodeRichDisplay([png, r])).toEqual({ content: [{ type: 'link', url: 'https://x' }] })
  })

  it('ccp-004 a malformed payload decodes to {} without throwing', () => {
    const bad = {
      id: 'b',
      mediaType: { identifier: RICH_DISPLAY_MEDIA_TYPE },
      source: { kind: 'inline', data: new TextEncoder().encode('not json') },
      presentation: 'inline',
    } as Attachment
    expect(() => decodeRichDisplay([bad])).not.toThrow()
    expect(decodeRichDisplay([bad])).toEqual({})
  })

  it('ccp-005 no attachments decode to {}', () => {
    expect(decodeRichDisplay([])).toEqual({})
  })

  it('ccp-006 committed messages come first, then drafts marked streaming', () => {
    const out = projectMessages(view([msg()], [draft()]), parts, stamp)
    expect(out).toHaveLength(2)
    expect(out[0].id).toBe('m1')
    expect(out[0].isStreaming).toBeUndefined()
    expect(out[1].id).toBe('draft:bot')
    expect(out[1].isStreaming).toBe(true)
  })

  it('ccp-007 a message without a timestamp is stamped by key', () => {
    const keys: string[] = []
    const out = projectMessages(view([msg({ id: 'abc' })]), parts, (k) => {
      keys.push(k)
      return D
    })
    expect(out[0].timestamp).toBe(D)
    expect(keys).toEqual(['abc'])
  })

  it('ccp-008 a failed delivery status becomes failure text', () => {
    const out = projectMessages(
      view([msg({ deliveryStatus: { kind: 'failed', reason: 'network error' } })]),
      parts,
      stamp,
    )
    expect(out[0].failure).toBe('network error')
  })

  it('ccp-009 running commands override the draft payload tool calls', () => {
    const old = rich({ toolCalls: [{ name: 'old', arguments: '{}', status: 'completed' }] })
    const out = projectMessages(
      view([], [draft({ attachments: [old] })], [command()]),
      parts,
      stamp,
    )
    expect(out[0].toolCalls).toEqual([{ name: 'search', arguments: '{}', status: 'started' }])
  })

  it('ccp-010 without active commands the decoded tool calls are kept', () => {
    const old = rich({ toolCalls: [{ name: 'old', arguments: '{}', status: 'completed' }] })
    const out = projectMessages(view([], [draft({ attachments: [old] })]), parts, stamp)
    expect(out[0].toolCalls).toEqual([{ name: 'old', arguments: '{}', status: 'completed' }])
  })

  it('ccp-011 a failed command projects as a failed tool call', () => {
    // toToolCallInfo is module-private, so it is exercised through projectMessages.
    const cmd = command({
      invocation: { ...command().invocation, commandName: 'run' },
      result: { invocationID: 'i1', ok: false, errorMessage: 'boom', completedAt: D },
    })
    const out = projectMessages(view([], [draft()], [cmd]), parts, stamp)
    expect(out[0].toolCalls).toEqual([
      { name: 'run', arguments: '{}', status: 'failed', ok: false, result: 'boom' },
    ])
  })

  it('ccp-012 the draft id derives from the participant', () => {
    expect(draftMessageID('bot-42')).toBe('draft:bot-42')
  })

  it('ccp-013 sender and persona flag follow the local participant', () => {
    const out = projectMessages(
      view([msg({ localID: 'a', senderID: 'local' }), msg({ localID: 'b', senderID: 'bot' })]),
      parts,
      stamp,
    )
    expect(out[0].sender).toBe(parts.user)
    expect(out[0].isPersona).toBe(false)
    expect(out[1].sender).toBe(parts.persona)
    expect(out[1].isPersona).toBe(true)
  })

  it('ccp-014 a rich-display attachment surfaces as the popover only', () => {
    const out = projectMessages(
      view([msg({ attachments: [rich({ popover: { title: 'Info' } } as never)] })]),
      parts,
      stamp,
    )
    expect(out[0].popover).toEqual({ title: 'Info' })
    expect(out[0].content).toBeUndefined()
    expect(out[0].toolCalls).toBeUndefined()
  })

  it('ccp-015 non-failed delivery statuses project no failure', () => {
    const kinds = ['sending', 'sent', 'delivered'] as const
    const out = projectMessages(
      view(kinds.map((k, i) => msg({ localID: `m${i}`, deliveryStatus: { kind: k } }))),
      parts,
      stamp,
    )
    expect(out).toHaveLength(3)
    for (const m of out) expect(m.failure).toBeUndefined()
  })

  it('ccp-016 a local draft projects as the user with no failure', () => {
    const out = projectMessages(view([], [draft({ participantID: 'local' })]), parts, stamp)
    expect(out[0].sender).toBe(parts.user)
    expect(out[0].isPersona).toBe(false)
    expect(out[0].failure).toBeUndefined()
  })

  it('ccp-017 projection does not mutate its input', () => {
    const v = view([msg()], [draft()], [command()])
    const copy = structuredClone(v)
    projectMessages(v, parts, stamp)
    expect(v).toEqual(copy)
  })
})
