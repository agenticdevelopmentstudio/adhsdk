import { createRef } from 'react'
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, act } from '@testing-library/react'
import { ChatInput, submitChatInput } from '../components/ChatInput'

describe('ChatInput', () => {
  it('draws its send button by default', () => {
    render(<ChatInput onSend={() => {}} />)
    expect(screen.getByRole('button', { name: 'Send' })).toBeInTheDocument()
  })

  it('leaves the send button out when told to, and Enter still sends', () => {
    const onSend = vi.fn()
    render(<ChatInput onSend={onSend} sendButton={false} />)
    expect(screen.queryByRole('button', { name: 'Send' })).toBeNull()
    const input = screen.getByRole('textbox', { name: 'Message' })
    fireEvent.change(input, { target: { value: 'hi' } })
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onSend).toHaveBeenCalledWith('hi')
  })
})

describe('submitChatInput', () => {
  it("sends the composer's text through the form and clears it", () => {
    const onSend = vi.fn()
    const { container } = render(<ChatInput onSend={onSend} sendButton={false} />)
    const input = screen.getByRole<HTMLInputElement>('textbox', { name: 'Message' })
    fireEvent.change(input, { target: { value: '  hello  ' } })
    expect(submitChatInput(container)).toBe(true)
    expect(onSend).toHaveBeenCalledWith('hello')
    expect(input.value).toBe('')
  })

  it('sends nothing from an empty or disabled box, or with no composer', () => {
    const onSend = vi.fn()
    const { container, rerender } = render(<ChatInput onSend={onSend} />)
    fireEvent.change(screen.getByRole('textbox'), { target: { value: '   ' } })
    expect(submitChatInput(container)).toBe(false)
    rerender(<ChatInput onSend={onSend} disabled />)
    fireEvent.change(screen.getByRole('textbox'), { target: { value: 'x' } })
    expect(submitChatInput(container)).toBe(false)
    expect(submitChatInput(document.createElement('div'))).toBe(false)
    expect(submitChatInput(null)).toBe(false)
    expect(onSend).not.toHaveBeenCalled()
  })
})

// Conformance vectors: cookbook/agentic-developer-hub-sdk/sdk/sources-ui/macos/chat/chat-input-field/conformance-test-vectors.md
describe('ChatInput conformance vectors', () => {
  const field = () => screen.getByRole<HTMLInputElement>('textbox')
  const sendButton = () => screen.getByRole<HTMLButtonElement>('button', { name: 'Send' })
  const type = (value: string) => fireEvent.change(field(), { target: { value } })

  it('chat-input-001 renders a visible input element', () => {
    render(<ChatInput onSend={() => {}} />)
    expect(field()).toBeVisible()
  })

  it('chat-input-002 shows the default placeholder', () => {
    render(<ChatInput onSend={() => {}} />)
    expect(field()).toHaveAttribute('placeholder', 'Type a message...')
  })

  it('chat-input-003 shows a custom placeholder', () => {
    render(<ChatInput onSend={() => {}} placeholder="Ask me anything" />)
    expect(field()).toHaveAttribute('placeholder', 'Ask me anything')
  })

  it('chat-input-004 disables the send button when empty', () => {
    render(<ChatInput onSend={() => {}} />)
    expect(sendButton()).toBeDisabled()
  })

  it('chat-input-005 enables the send button once text is typed', () => {
    render(<ChatInput onSend={() => {}} />)
    type('Hello')
    expect(sendButton()).toBeEnabled()
  })

  it('chat-input-006 keeps the send button disabled for spaces only', () => {
    render(<ChatInput onSend={() => {}} />)
    type('   ')
    expect(sendButton()).toBeDisabled()
  })

  it('chat-input-007 Enter sends the text and clears the input', () => {
    const onSend = vi.fn()
    render(<ChatInput onSend={onSend} />)
    type('Test')
    fireEvent.keyDown(field(), { key: 'Enter' })
    expect(onSend).toHaveBeenCalledWith('Test')
    expect(field().value).toBe('')
  })

  it.skip('chat-input-008 Shift+Enter falls through to the form submit on web', () => {
    // jsdom does not perform a form's implicit submission on a keydown, so the fall-through cannot be observed.
  })

  it('chat-input-009 trims the text before sending', () => {
    const onSend = vi.fn()
    render(<ChatInput onSend={onSend} />)
    type('  Hello  ')
    fireEvent.keyDown(field(), { key: 'Enter' })
    expect(onSend).toHaveBeenCalledWith('Hello')
  })

  it('chat-input-010 clears the input and disables send after a send', () => {
    render(<ChatInput onSend={() => {}} />)
    type('Hi')
    fireEvent.click(sendButton())
    expect(field().value).toBe('')
    expect(sendButton()).toBeDisabled()
  })

  it('chat-input-011 Enter on whitespace sends nothing and keeps the text', () => {
    const onSend = vi.fn()
    render(<ChatInput onSend={onSend} />)
    type('   ')
    fireEvent.keyDown(field(), { key: 'Enter' })
    expect(onSend).not.toHaveBeenCalled()
    expect(field().value).toBe('   ')
  })

  it('chat-input-012 disabled blocks the input and the send button', () => {
    render(<ChatInput onSend={() => {}} disabled />)
    expect(field()).toBeDisabled()
    expect(sendButton()).toBeDisabled()
    field().focus()
    expect(field()).not.toHaveFocus()
  })

  it('chat-input-013 renders a send button in the same form as the input', () => {
    render(<ChatInput onSend={() => {}} />)
    expect(sendButton().closest('form')).toBe(field().closest('form'))
  })

  it('chat-input-014 autoFocus focuses the input on mount', () => {
    render(<ChatInput onSend={() => {}} autoFocus />)
    expect(field()).toHaveFocus()
  })

  it('chat-input-015 does not focus the input by default', () => {
    render(<ChatInput onSend={() => {}} />)
    expect(field()).not.toHaveFocus()
  })

  it('chat-input-016 opts out of password managers', () => {
    const { container } = render(<ChatInput onSend={() => {}} />)
    expect(container.querySelector('form')).toHaveAttribute('data-form-type', 'other')
    expect(field()).toHaveAttribute('autocomplete', 'off')
    expect(field()).toHaveAttribute('data-form-type', 'other')
    for (const attr of ['data-1p-ignore', 'data-lpignore', 'data-bwignore', 'data-protonpass-ignore']) {
      expect(field()).toHaveAttribute(attr, 'true')
    }
  })

  it('chat-input-017 the form has no name and the input has no semantic autocomplete hint', () => {
    const { container } = render(<ChatInput onSend={() => {}} />)
    expect(container.querySelector('form')).not.toHaveAttribute('name')
    expect(field().getAttribute('autocomplete')).toBe('off')
  })

  it('chat-input-018 the input has aria-label "Message"', () => {
    render(<ChatInput onSend={() => {}} />)
    expect(field()).toHaveAttribute('aria-label', 'Message')
  })

  it('chat-input-019 an external ref reaches the input element', () => {
    const ref = createRef<HTMLInputElement>()
    render(<ChatInput onSend={() => {}} inputRef={ref} />)
    expect(ref.current).toBe(field())
    act(() => ref.current?.focus())
    expect(field()).toHaveFocus()
  })

  it('chat-input-020 setting the ref value without an event leaves the send button disabled', () => {
    const ref = createRef<HTMLInputElement>()
    render(<ChatInput onSend={() => {}} inputRef={ref} />)
    ref.current!.value = 'Hi'
    expect(field().value).toBe('Hi')
    expect(sendButton()).toBeDisabled()
  })

  it('chat-input-021 a programmatic value plus a native input event enables the send button', () => {
    const ref = createRef<HTMLInputElement>()
    render(<ChatInput onSend={() => {}} inputRef={ref} />)
    // The prototype setter bypasses React's value tracker, as a user's typing does.
    const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')!.set!
    setter.call(ref.current, 'Hi')
    ref.current!.dispatchEvent(new Event('input', { bubbles: true }))
    expect(sendButton()).toBeEnabled()
  })

  it('chat-input-022 two sends in a row are delivered separately', () => {
    const onSend = vi.fn()
    render(<ChatInput onSend={onSend} />)
    type('First')
    fireEvent.keyDown(field(), { key: 'Enter' })
    expect(field().value).toBe('')
    type('Second')
    fireEvent.keyDown(field(), { key: 'Enter' })
    expect(field().value).toBe('')
    expect(onSend.mock.calls).toEqual([['First'], ['Second']])
  })

  it('chat-input-023 blur keeps the typed text and the send button state', () => {
    render(<ChatInput onSend={() => {}} />)
    field().focus()
    type('Draft')
    fireEvent.blur(field())
    expect(field().value).toBe('Draft')
    expect(sendButton()).toBeEnabled()
  })

  it('chat-input-024 becoming disabled keeps unsent text and disables send', () => {
    const { rerender } = render(<ChatInput onSend={() => {}} />)
    type('Draft')
    rerender(<ChatInput onSend={() => {}} disabled />)
    expect(field().value).toBe('Draft')
    expect(field()).toBeDisabled()
    expect(sendButton()).toBeDisabled()
  })

  it.skip('chat-input-025 theme change updates the live field editor', () => {
    // macOS-only (NSTextField field editor); no web equivalent.
  })

  it.skip('chat-input-026 block caret stays within bounds', () => {
    // macOS-only (usesBlockCaret caret layer); no web equivalent.
  })

  it('chat-input-027 the send button has aria-label "Send"', () => {
    render(<ChatInput onSend={() => {}} />)
    expect(sendButton()).toHaveAttribute('aria-label', 'Send')
  })

  it('chat-input-028 the input has name "message"', () => {
    render(<ChatInput onSend={() => {}} />)
    expect(field()).toHaveAttribute('name', 'message')
  })

  it.skip('chat-input-032 long text scrolls horizontally inside the input', () => {
    // jsdom has no layout, so horizontal scrolling and caret following cannot be observed.
  })
})
