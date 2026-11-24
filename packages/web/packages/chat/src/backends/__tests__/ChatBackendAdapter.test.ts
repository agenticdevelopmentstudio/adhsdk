import { describe, expect, it } from 'vitest'

import type { InboundEvent } from '../../contract/backend/InboundEvent'
import type { ChatStreamEvent } from '../../types'
import { ChatBackendAdapter } from '../ChatBackendAdapter'
import type { ChatBackend } from '../types'

const options = { personaID: 'aria', history: () => [] }

/** Pull exactly `count` events off the adapter's inbound stream. */
async function take(adapter: ChatBackendAdapter, count: number): Promise<InboundEvent[]> {
  const out: InboundEvent[] = []
  for await (const event of adapter.inboundEvents) {
    out.push(event)
    if (out.length === count) break
  }
  return out
}

describe('ChatBackendAdapter conformance', () => {
  it('ccb-044: an error event commits the accumulated partial text, then clears the draft', async () => {
    const backend: ChatBackend = {
      sendMessage: async () => 'unused',
      async *sendMessageStream(): AsyncGenerator<ChatStreamEvent> {
        yield { type: 'token', text: 'partial' }
        yield { type: 'error', message: 'boom' }
      },
    }
    const adapter = new ChatBackendAdapter(backend, options)
    await adapter.send('hi', [])
    // opened draft, draft after token, messageReceived, draftCleared
    const events = await take(adapter, 4)
    const received = events.filter((e) => e.kind === 'messageReceived')
    expect(received).toHaveLength(1)
    const first = received[0]
    if (first?.kind !== 'messageReceived') throw new Error('unreachable')
    expect(first.message.text).toBe('partial')
    expect(first.message.text).not.toBe('boom')
    expect(events[events.length - 1]?.kind).toBe('draftCleared')
    adapter.destroy()
  })

  it('ccb-045: a rejected sendMessage commits the generic apology', async () => {
    const backend: ChatBackend = {
      sendMessage: async () => {
        throw new Error('network down')
      },
    }
    const adapter = new ChatBackendAdapter(backend, options)
    await adapter.send('hi', [])
    const events = await take(adapter, 2)
    const first = events[0]
    if (first?.kind !== 'messageReceived') throw new Error(`unexpected event ${first?.kind}`)
    expect(first.message.text).toBe("Sorry, something went wrong. Let's try again.")
    expect(first.message.senderID).toBe('aria')
    expect(events[1]?.kind).toBe('draftCleared')
    adapter.destroy()
  })
})
