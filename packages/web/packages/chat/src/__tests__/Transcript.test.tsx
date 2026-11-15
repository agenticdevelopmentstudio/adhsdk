import { describe, it, expect, vi } from 'vitest'
import { act, render, screen, fireEvent } from '@testing-library/react'
import { Transcript } from '../components/Transcript'
import { MessageBubble } from '../components/MessageBubble'
import { TypingIndicator } from '../components/TypingIndicator'
import type { ChatMessage } from '../types'

// Spy on the children the Transcript hands props to, delegating to the real components.
vi.mock('../components/MessageBubble', async (importOriginal) => {
  const real = await importOriginal<typeof import('../components/MessageBubble')>()
  return { ...real, MessageBubble: vi.fn(real.MessageBubble) }
})
vi.mock('../components/TypingIndicator', async (importOriginal) => {
  const real = await importOriginal<typeof import('../components/TypingIndicator')>()
  return { ...real, TypingIndicator: vi.fn(real.TypingIndicator) }
})

const bubbleSpy = vi.mocked(MessageBubble)
const typingSpy = vi.mocked(TypingIndicator)
const lastBubbleProps = (index: number) => {
  const calls = bubbleSpy.mock.calls.map((c) => c[0]).filter((p) => p.index === index)
  return calls[calls.length - 1]
}
const lastTypingProps = () => typingSpy.mock.calls[typingSpy.mock.calls.length - 1][0]

/* jsdom has no layout, so a scroll container is described by hand; scrollHeight
 * grows with the rendered text and child count. */
function describeAsScrollable(el: HTMLElement, clientHeight: number): void {
  let scrollTop = 0
  Object.defineProperty(el, 'clientHeight', { get: () => clientHeight, configurable: true })
  Object.defineProperty(el, 'scrollHeight', {
    get: () => (el.textContent ?? '').length + el.childElementCount * 100,
    configurable: true,
  })
  Object.defineProperty(el, 'scrollTop', {
    get: () => scrollTop,
    set: (v: number) => {
      scrollTop = v
      el.dispatchEvent(new Event('scroll'))
    },
    configurable: true,
  })
}

async function settle(): Promise<void> {
  await act(async () => {
    await new Promise((r) => requestAnimationFrame(() => r(null)))
    await new Promise((r) => requestAnimationFrame(() => r(null)))
    await new Promise((r) => setTimeout(r, 0))
  })
}

const region = (container: HTMLElement) => container.querySelector('.pc-transcript') as HTMLElement

function makeMessage(overrides: Partial<ChatMessage> = {}): ChatMessage {
  return {
    id: crypto.randomUUID(),
    sender: { name: 'Bot' },
    text: 'Test message',
    timestamp: new Date(),
    isPersona: true,
    ...overrides,
  }
}

describe('Transcript', () => {
  it('renders messages', () => {
    const messages = [
      makeMessage({ text: 'Hello' }),
      makeMessage({ text: 'World', isPersona: false }),
    ]
    render(<Transcript messages={messages} isTyping={false} />)
    expect(screen.getByText('Hello')).toBeInTheDocument()
    expect(screen.getByText('World')).toBeInTheDocument()
  })

  it('renders typing indicator when typing', () => {
    const { container } = render(
      <Transcript messages={[]} isTyping={true} />,
    )
    expect(container.querySelector('.pc-typing')).toBeInTheDocument()
  })

  it('does not render typing indicator when not typing', () => {
    const { container } = render(
      <Transcript messages={[]} isTyping={false} />,
    )
    expect(container.querySelector('.pc-typing')).not.toBeInTheDocument()
  })

  it('highlights selected message', () => {
    const messages = [makeMessage({ text: 'First' }), makeMessage({ text: 'Second' })]
    const { container } = render(
      <Transcript messages={messages} isTyping={false} selectedIndex={1} />,
    )
    const selected = container.querySelectorAll('.pc-message-selected')
    expect(selected).toHaveLength(1)
  })

  it('calls onMessageClick with index', () => {
    const onMessageClick = vi.fn()
    const messages = [makeMessage({ text: 'Click me' })]
    render(
      <Transcript
        messages={messages}
        isTyping={false}
        onMessageClick={onMessageClick}
      />,
    )
    fireEvent.click(screen.getByText('Click me'))
    expect(onMessageClick).toHaveBeenCalledWith(0)
  })

  it('renders inline popovers when renderPopover is provided', () => {
    const messages = [
      makeMessage({
        text: 'With popover',
        popover: { title: 'Details', description: 'More info' },
      }),
    ]
    render(
      <Transcript
        messages={messages}
        isTyping={false}
        renderPopover={(msg) => (
          <div data-testid="popover">{msg.popover?.title}</div>
        )}
      />,
    )
    expect(screen.getByTestId('popover')).toHaveTextContent('Details')
  })

  it('does not render popovers when renderPopover is not provided', () => {
    const messages = [
      makeMessage({
        text: 'With popover',
        popover: { title: 'Details' },
      }),
    ]
    render(<Transcript messages={messages} isTyping={false} />)
    expect(screen.queryByText('Details')).not.toBeInTheDocument()
  })

  it('shows detail arrows when enabled', () => {
    const messages = [
      makeMessage({ popover: { title: 'Details' } }),
    ]
    render(
      <Transcript
        messages={messages}
        isTyping={false}
        showDetailArrows
      />,
    )
    expect(screen.getByLabelText('Show details')).toBeInTheDocument()
  })

  it('does not show detail arrows by default', () => {
    const messages = [
      makeMessage({ popover: { title: 'Details' } }),
    ]
    render(<Transcript messages={messages} isTyping={false} />)
    expect(screen.queryByLabelText('Show details')).not.toBeInTheDocument()
  })

  it('applies custom className', () => {
    const { container } = render(
      <Transcript messages={[]} isTyping={false} className="custom" />,
    )
    expect(container.querySelector('.pc-transcript.custom')).toBeInTheDocument()
  })

  describe('conformance vectors', () => {
    const three = () => [
      makeMessage({ id: 'a', text: 'one' }),
      makeMessage({ id: 'b', text: 'two' }),
      makeMessage({ id: 'c', text: 'three' }),
    ]

    it('transcript-001 renders every message in order', () => {
      const { container } = render(<Transcript messages={three().slice(0, 2)} isTyping={false} />)
      const texts = [...container.querySelectorAll('.pc-text')].map((n) => n.textContent)
      expect(texts).toEqual(['one', 'two'])
    })

    it('transcript-002 scrolls to the bottom when a message arrives and the reader is at the bottom', async () => {
      const { container, rerender } = render(<Transcript messages={three()} isTyping={false} />)
      const el = region(container)
      describeAsScrollable(el, 10)
      await settle()
      el.scrollTop = el.scrollHeight
      rerender(<Transcript messages={[...three(), makeMessage({ id: 'd', text: 'four' })]} isTyping={false} />)
      await settle()
      expect(el.scrollTop).toBe(el.scrollHeight)
    })

    it('transcript-003 scrolls to the bottom when isTyping changes, in both directions', async () => {
      const msgs = [1, 2, 3, 4, 5].map((n) => makeMessage({ id: `m${n}`, text: `msg ${n}` }))
      const { container, rerender } = render(<Transcript messages={msgs} isTyping={false} />)
      const el = region(container)
      describeAsScrollable(el, 10)
      await settle()
      el.scrollTop = el.scrollHeight
      rerender(<Transcript messages={msgs} isTyping={true} />)
      await settle()
      expect(container.querySelector('.pc-typing')).toBeInTheDocument()
      expect(el.scrollTop).toBe(el.scrollHeight)
      rerender(<Transcript messages={msgs} isTyping={false} />)
      await settle()
      expect(el.scrollTop).toBe(el.scrollHeight)
    })

    it('transcript-004 renders the typing indicator when typing and not suppressed', () => {
      const { container } = render(
        <Transcript messages={[]} isTyping={true} suppressTypingIndicator={false} />,
      )
      expect(container.querySelector('.pc-typing')).toBeInTheDocument()
    })

    it('transcript-005 omits the typing indicator when suppressed', () => {
      const { container } = render(
        <Transcript messages={[]} isTyping={true} suppressTypingIndicator={true} />,
      )
      expect(container.querySelector('.pc-typing')).not.toBeInTheDocument()
    })

    it('transcript-006 container is in the tab order and takes focus', () => {
      const { container } = render(<Transcript messages={three()} isTyping={false} />)
      const el = region(container)
      expect(el).toHaveAttribute('tabindex', '0')
      el.focus()
      expect(document.activeElement).toBe(el)
    })

    it('transcript-007 exposes a named region landmark', () => {
      render(<Transcript messages={three()} isTyping={false} />)
      expect(screen.getByRole('region', { name: 'Conversation transcript' })).toBeInTheDocument()
    })

    it('transcript-008 defaults the accessible label', () => {
      const { container } = render(<Transcript messages={[]} isTyping={false} />)
      expect(region(container)).toHaveAttribute('aria-label', 'Conversation transcript')
    })

    it('transcript-009 uses the label prop as the accessible name', () => {
      render(<Transcript messages={[]} isTyping={false} label="Chat history" />)
      expect(screen.getByRole('region', { name: 'Chat history' })).toBeInTheDocument()
    })

    it('transcript-010 marks only the selected index', () => {
      render(<Transcript messages={three()} isTyping={false} selectedIndex={1} />)
      expect(lastBubbleProps(0).isSelected).toBe(false)
      expect(lastBubbleProps(1).isSelected).toBe(true)
      expect(lastBubbleProps(2).isSelected).toBe(false)
    })

    it('transcript-011 passes onMessageClick through with the index as its only argument', () => {
      const onMessageClick = vi.fn()
      render(<Transcript messages={three()} isTyping={false} onMessageClick={onMessageClick} />)
      fireEvent.click(screen.getByText('two'))
      expect(onMessageClick).toHaveBeenCalledTimes(1)
      expect(onMessageClick.mock.calls[0]).toEqual([1])
    })

    it('transcript-012 gives MessageBubble no click callback without onMessageClick', () => {
      render(<Transcript messages={three()} isTyping={false} />)
      expect(lastBubbleProps(0).onClick).toBeUndefined()
      expect(() => fireEvent.click(screen.getByText('one'))).not.toThrow()
    })

    it('transcript-013 renders the popover immediately after its bubble', () => {
      const msgs = [makeMessage({ id: 'p', text: 'with', popover: { title: 'Details' } })]
      const renderPopover = vi.fn(() => <div data-testid="pop">pop</div>)
      render(<Transcript messages={msgs} isTyping={false} renderPopover={renderPopover} />)
      const pop = screen.getByTestId('pop')
      expect(renderPopover).toHaveBeenCalledWith(msgs[0])
      expect(pop.previousElementSibling).toHaveClass('pc-message')
    })

    it('transcript-014 renders no popover when popover is falsy or renderPopover is absent', () => {
      const renderPopover = vi.fn(() => <div data-testid="pop">pop</div>)
      const { unmount } = render(
        <Transcript messages={[makeMessage({ text: 'plain' })]} isTyping={false} renderPopover={renderPopover} />,
      )
      expect(screen.queryByTestId('pop')).not.toBeInTheDocument()
      expect(renderPopover).not.toHaveBeenCalled()
      unmount()
      render(<Transcript messages={[makeMessage({ popover: { title: 'D' } })]} isTyping={false} />)
      expect(screen.queryByTestId('pop')).not.toBeInTheDocument()
    })

    it('transcript-015 shows the detail arrow for messages with a popover', () => {
      render(
        <Transcript
          messages={[makeMessage({ popover: { title: 'D' } })]}
          isTyping={false}
          showDetailArrows={true}
        />,
      )
      expect(lastBubbleProps(0).showDetailArrow).toBe(true)
      expect(screen.getByLabelText('Show details')).toBeInTheDocument()
    })

    it('transcript-016 hides arrows when disabled or without a popover but still passes the callback', () => {
      const cb = vi.fn()
      const msgs = [makeMessage({ popover: { title: 'D' } }), makeMessage({ text: 'no popover' })]
      const { unmount } = render(
        <Transcript messages={msgs} isTyping={false} showDetailArrows={false} onDetailArrowClick={cb} />,
      )
      expect(lastBubbleProps(0).showDetailArrow).toBe(false)
      expect(screen.queryByLabelText('Show details')).not.toBeInTheDocument()
      unmount()
      render(<Transcript messages={msgs} isTyping={false} showDetailArrows={true} onDetailArrowClick={cb} />)
      expect(lastBubbleProps(0).showDetailArrow).toBe(true)
      expect(lastBubbleProps(1).showDetailArrow).toBe(false)
      expect(typeof lastBubbleProps(1).onDetailArrowClick).toBe('function')
      lastBubbleProps(1).onDetailArrowClick!()
      expect(cb.mock.calls).toEqual([[1]])
    })

    it('transcript-017 forwards thinkingLabels unchanged', () => {
      const labels = [{ present: 'zeeping', past: 'zeeped' }]
      render(<Transcript messages={[]} isTyping={true} thinkingLabels={labels} />)
      expect(lastTypingProps().labels).toBe(labels)
    })

    it('transcript-018 forwards thinkingFrames unchanged', () => {
      const frames = ['a', 'b']
      render(<Transcript messages={[]} isTyping={true} thinkingFrames={frames} />)
      expect(lastTypingProps().frames).toBe(frames)
    })

    it('transcript-019 forwards thinkingDoneGlyph unchanged', () => {
      render(<Transcript messages={[]} isTyping={true} thinkingDoneGlyph="*" />)
      expect(lastTypingProps().doneGlyph).toBe('*')
    })

    it('transcript-020 forwards thinkingColorful and isTyping', () => {
      render(<Transcript messages={[]} isTyping={true} thinkingColorful={true} />)
      expect(lastTypingProps().colorful).toBe(true)
      expect(lastTypingProps().isTyping).toBe(true)
    })

    it('transcript-021 forwards thinkingTint unchanged', () => {
      const tint = { color: 'red', applies: 'both' as const }
      render(<Transcript messages={[]} isTyping={true} thinkingTint={tint} />)
      expect(lastTypingProps().tint).toBe(tint)
    })

    it('transcript-022 adds the fade class when fadeOlder is true', () => {
      const { container } = render(<Transcript messages={three()} isTyping={false} fadeOlder={true} />)
      expect(region(container)).toHaveClass('pc-transcript--fade')
    })

    it('transcript-023 omits the fade class when fadeOlder is false', () => {
      const { container } = render(<Transcript messages={three()} isTyping={false} fadeOlder={false} />)
      expect(region(container)).not.toHaveClass('pc-transcript--fade')
    })

    it('transcript-024 appends className to the container', () => {
      const { container } = render(<Transcript messages={[]} isTyping={false} className="custom-class" />)
      expect(region(container)).toHaveClass('pc-transcript', 'custom-class')
    })

    it('transcript-025 keeps each message node across a re-render with the same ids', () => {
      const msgs = three()
      const { container, rerender } = render(<Transcript messages={msgs} isTyping={false} />)
      const before = [...container.querySelectorAll('.pc-message')]
      rerender(
        <Transcript
          messages={[makeMessage({ id: 'z', text: 'new first' }), ...msgs.map((m) => ({ ...m, text: m.text + '!' }))]}
          isTyping={false}
        />,
      )
      const after = [...container.querySelectorAll('.pc-message')]
      expect(after).toHaveLength(4)
      expect(after[1]).toBe(before[0])
      expect(after[3]).toBe(before[2])
    })

    it('transcript-026 does not pull a reader who scrolled up back down', async () => {
      const long = (id: string) => makeMessage({ id, text: 'x'.repeat(300) })
      const { container, rerender } = render(<Transcript messages={[long('a')]} isTyping={false} />)
      const el = region(container)
      describeAsScrollable(el, 10)
      await settle()
      el.scrollTop = 0
      rerender(<Transcript messages={[long('a'), long('b')]} isTyping={false} />)
      await settle()
      expect(el.scrollTop).toBe(0)
    })

    it.skip('transcript-027 fade anchors to the viewport (mask-image compositing; jsdom has no layout or masks)', () => {})
    it.skip('transcript-028 fade restores on scroll (mask-image compositing; jsdom has no layout or masks)', () => {})

    it('transcript-029 a negative out-of-range selectedIndex selects nothing and does not throw', () => {
      const { container } = render(<Transcript messages={three()} isTyping={false} selectedIndex={-5} />)
      expect(container.querySelectorAll('.pc-message-selected')).toHaveLength(0)
      for (let i = 0; i < 3; i++) expect(lastBubbleProps(i).isSelected).toBe(false)
    })

    it('transcript-030 starts scrolled to the bottom on first mount', async () => {
      const heightSpy = vi.spyOn(Element.prototype, 'scrollHeight', 'get').mockReturnValue(1000)
      const topSpy = vi.spyOn(Element.prototype, 'scrollTop', 'set')
      try {
        const msgs = Array.from({ length: 10 }, (_, i) => makeMessage({ id: `m${i}`, text: `msg ${i}` }))
        const { container } = render(<Transcript messages={msgs} isTyping={false} />)
        await settle()
        const el = region(container)
        const wrote = topSpy.mock.contexts.some((ctx, i) => ctx === el && topSpy.mock.calls[i][0] === 1000)
        expect(wrote).toBe(true)
      } finally {
        heightSpy.mockRestore()
        topSpy.mockRestore()
      }
    })

    it('transcript-031 follows a last message that grows without the count changing', async () => {
      const grow = (text: string) => [makeMessage({ id: 'draft', text })]
      const { container, rerender } = render(<Transcript messages={grow('a')} isTyping={false} />)
      const el = region(container)
      describeAsScrollable(el, 10)
      await settle()
      el.scrollTop = el.scrollHeight
      rerender(<Transcript messages={grow('a'.repeat(500))} isTyping={false} />)
      await settle()
      expect(el.scrollTop).toBe(el.scrollHeight)
    })
  })
})
