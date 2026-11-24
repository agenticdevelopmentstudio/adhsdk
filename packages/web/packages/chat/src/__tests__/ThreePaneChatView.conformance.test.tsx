import { useState } from 'react'
import { describe, it, expect } from 'vitest'
import { render, fireEvent, within } from '@testing-library/react'
import { ThreePaneChatView } from '../modes/ThreePaneChat'
import type { ChatSession } from '../hooks/useChatSession'
import type { ChatMessage, PopoverData } from '../types'

// Conformance vectors: cookbook/agentic-developer-hub-sdk/sdk/sources-ui/macos/chat/three-pane-chat-view/conformance-test-vectors.md
// The view is driven through a hand-built ChatSession so each vector controls the messages exactly.

function msg(id: string, text: string, popover?: PopoverData, extra: Partial<ChatMessage> = {}): ChatMessage {
  return {
    id,
    sender: { name: 'Bot' },
    text,
    popover,
    timestamp: new Date('2026-01-01T00:00:00Z'),
    isPersona: true,
    ...extra,
  }
}

function Host({ messages, onSend = () => {} }: { messages: ChatMessage[]; onSend?: (t: string) => void }) {
  const [selectedIndex, setSelectedIndex] = useState(-1)
  const session = {
    messages,
    isTyping: false,
    sendMessage: onSend,
    selectedIndex,
    selectMessage: setSelectedIndex,
  } as unknown as ChatSession
  return <ThreePaneChatView session={session} />
}

const A = { title: 'Alpha', description: 'Alpha description' }
const B = { title: 'Beta', description: 'Beta description' }
const C = { title: 'Gamma', description: 'Gamma description' }

const threePopovers = [msg('m0', 'zero', A), msg('m1', 'one', B), msg('m2', 'two', C)]
const twoPopovers = [msg('m0', 'zero', A), msg('m1', 'one', B)]

const topicButtons = (c: HTMLElement) => Array.from(c.querySelectorAll<HTMLButtonElement>('.pc-topic-item'))
const activeTitles = (c: HTMLElement) =>
  topicButtons(c)
    .filter((b) => b.classList.contains('active'))
    .map((b) => b.textContent)
const panelTitles = (c: HTMLElement) =>
  Array.from(c.querySelectorAll('.pc-panel-stack .pc-detail-title')).map((e) => e.textContent)
const messageEls = (c: HTMLElement) => Array.from(c.querySelectorAll<HTMLElement>('.pc-message'))

describe('ThreePaneChatView conformance vectors', () => {
  it('three-pane-001 derives one topic per popover message', () => {
    const { container } = render(<Host messages={[msg('m0', 'plain'), msg('m1', 'one', A), msg('m2', 'two', B)]} />)
    expect(topicButtons(container).map((b) => b.textContent)).toEqual(['Alpha', 'Beta'])
    expect(container.querySelectorAll('.pc-panel-stack .pc-detail-pane')).toHaveLength(1)
    // The descriptions come from the popover data.
    fireEvent.click(topicButtons(container)[0]!)
    expect(within(container).getByText('Alpha description')).toBeInTheDocument()
    expect(within(container).getByText('Beta description')).toBeInTheDocument()
  })

  it('three-pane-002 selecting a topic makes it, and only it, active', () => {
    const { container } = render(<Host messages={threePopovers} />)
    fireEvent.click(topicButtons(container)[0]!)
    expect(activeTitles(container)).toEqual(['Alpha'])
  })

  it('three-pane-003 the detail pane shows title, description, links and images', () => {
    const messages = [
      msg('m0', 'zero', { ...A, links: [{ label: 'Docs', url: 'https://example.com/docs' }] }, {
        content: [{ type: 'image', src: 'https://example.com/a.png', alt: 'An image' }],
      }),
    ]
    const { container } = render(<Host messages={messages} />)
    const panel = container.querySelector<HTMLElement>('.pc-panel-stack')!
    expect(within(panel).getByText('Alpha')).toBeInTheDocument()
    expect(within(panel).getByText('Alpha description')).toBeInTheDocument()
    expect(within(panel).getByRole('link', { name: 'Docs' })).toHaveAttribute('href', 'https://example.com/docs')
    expect(within(panel).getByAltText('An image')).toHaveAttribute('src', 'https://example.com/a.png')
  })

  it('three-pane-004 selecting a second topic keeps the first in the visible stack', () => {
    const { container } = render(<Host messages={twoPopovers} />)
    // The newest topic (Beta) is active and visible first.
    expect(panelTitles(container)).toEqual(['Beta'])
    fireEvent.click(topicButtons(container)[0]!)
    expect(panelTitles(container)).toEqual(['Beta', 'Alpha'])
  })

  it('three-pane-005 arrow down moves the active topic to the next visible one', () => {
    const { container } = render(<Host messages={threePopovers} />)
    // Build the visible stack [Gamma, Beta, Alpha], then park on the middle entry (Beta).
    fireEvent.click(topicButtons(container)[1]!)
    fireEvent.click(topicButtons(container)[0]!)
    fireEvent.click(topicButtons(container)[1]!)
    expect(panelTitles(container)).toEqual(['Gamma', 'Beta', 'Alpha'])
    expect(activeTitles(container)).toEqual(['Beta'])
    fireEvent.keyDown(document, { key: 'ArrowDown' })
    expect(activeTitles(container)).toEqual(['Alpha'])
  })

  it('three-pane-006 arrow down on the last visible topic clamps instead of wrapping', () => {
    const { container } = render(<Host messages={twoPopovers} />)
    fireEvent.click(topicButtons(container)[0]!)
    expect(panelTitles(container)).toEqual(['Beta', 'Alpha'])
    expect(activeTitles(container)).toEqual(['Alpha'])
    fireEvent.keyDown(document, { key: 'ArrowDown' })
    expect(activeTitles(container)).toEqual(['Alpha'])
  })

  it('three-pane-007 a printable key outside the input moves focus to the chat input', () => {
    // jsdom does not insert the character itself (that is the browser's default action once focus
    // has moved), so this asserts the focus hand-off the handler is responsible for.
    const { container } = render(<Host messages={twoPopovers} />)
    const topic = topicButtons(container)[0]!
    topic.focus()
    expect(topic).toHaveFocus()
    fireEvent.keyDown(topic, { key: 'a' })
    expect(container.querySelector('.pc-input')).toHaveFocus()
  })

  it('three-pane-008 a printable key while the input has focus leaves focus there', () => {
    const { container } = render(<Host messages={twoPopovers} />)
    const input = container.querySelector<HTMLInputElement>('.pc-input')!
    input.focus()
    fireEvent.keyDown(input, { key: 'a' })
    expect(input).toHaveFocus()
    expect(activeTitles(container)).toEqual(['Beta'])
  })

  it('three-pane-009 connectors run topic to message and message to detail panel', () => {
    const { container } = render(<Host messages={twoPopovers} />)
    // Active topic is Beta (messageIndex 1): topic-1 -> msg-1-out, msg-1-out -> panel-1-in.
    for (const id of ['topic-1', 'msg-1-out', 'panel-1-in']) {
      expect(container.querySelector(`[data-connector-anchor="${id}"]`)).not.toBeNull()
    }
    expect(container.querySelectorAll('.pc-connector-svg line')).toHaveLength(2)
  })

  it('three-pane-010 the layout recalculates after a detail image loads', () => {
    const messages = [
      msg('m0', 'zero', A, { content: [{ type: 'image', src: 'https://example.com/a.png', alt: 'Pic' }] }),
    ]
    const { container } = render(<Host messages={messages} />)
    const frame = container.querySelector<HTMLElement>('.pc-three-pane-frame')!
    frame.style.height = ''
    fireEvent.load(container.querySelector('.pc-detail-image')!)
    expect(frame.style.height).not.toBe('')
  })

  it('three-pane-011 clicking a topic activates it and selects its message', () => {
    const { container } = render(<Host messages={[msg('m0', 'plain'), msg('m1', 'one', A), msg('m2', 'two', B)]} />)
    fireEvent.click(topicButtons(container)[0]!)
    expect(activeTitles(container)).toEqual(['Alpha'])
    const els = messageEls(container)
    expect(els[1]).toHaveClass('pc-message-selected')
    expect(els.filter((e) => e.classList.contains('pc-message-selected'))).toHaveLength(1)
  })

  it('three-pane-012 clicking a message with a topic activates that topic', () => {
    const { container } = render(<Host messages={[msg('m0', 'plain'), msg('m1', 'one', A), msg('m2', 'two', B)]} />)
    expect(activeTitles(container)).toEqual(['Beta'])
    fireEvent.click(messageEls(container)[1]!)
    expect(messageEls(container)[1]).toHaveClass('pc-message-selected')
    expect(activeTitles(container)).toEqual(['Alpha'])
  })

  it('three-pane-013 clicking a message without a topic leaves the active topic alone', () => {
    const { container } = render(<Host messages={[msg('m0', 'plain'), msg('m1', 'one', A), msg('m2', 'two', B)]} />)
    fireEvent.click(messageEls(container)[0]!)
    expect(messageEls(container)[0]).toHaveClass('pc-message-selected')
    expect(activeTitles(container)).toEqual(['Beta'])
  })

  it('three-pane-014 removing a popover message drops its topic', () => {
    const { container, rerender } = render(<Host messages={twoPopovers} />)
    expect(topicButtons(container).map((b) => b.textContent)).toEqual(['Alpha', 'Beta'])
    rerender(<Host messages={[twoPopovers[0]!]} />)
    expect(within(container).queryByText('Beta')).toBeNull()
    expect(within(container).queryByText('Beta description')).toBeNull()
    expect(within(container).getAllByText('Alpha').length).toBeGreaterThan(0)
  })

  it('three-pane-015 the transcript shows a detail arrow on a message with a topic', () => {
    const { container } = render(<Host messages={[msg('m0', 'plain'), msg('m1', 'one', A)]} />)
    const els = messageEls(container)
    expect(within(els[1]!).getByLabelText('Show details')).toBeInTheDocument()
    expect(within(els[0]!).queryByLabelText('Show details')).toBeNull()
  })

  it('three-pane-016 swapping in a different conversation with the same popover count keeps the old topics', () => {
    const { container, rerender } = render(<Host messages={twoPopovers} />)
    const swapped = [
      msg('n0', 'new zero', { title: 'Delta', description: 'Delta description' }),
      msg('n1', 'new one', { title: 'Epsilon', description: 'Epsilon description' }),
    ]
    rerender(<Host messages={swapped} />)
    expect(topicButtons(container).map((b) => b.textContent)).toEqual(['Alpha', 'Beta'])
    expect(within(container).queryByText('Delta')).toBeNull()
  })
})
