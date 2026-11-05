// src/__tests__/BitbagInline.test.tsx
import { describe, expect, it, vi } from 'vitest'
import { act, fireEvent, render, screen } from '@testing-library/react'
import type { BitbagChatProps } from '../BitbagChat'

// Same stand-ins as BitbagDock.test.tsx: the chat keeps the props it is handed, so a
// test can read what the inline mounting imposes on it, and renders the composer the
// corner-send submits.
const chat = vi.hoisted(() => ({ props: {} as Partial<BitbagChatProps> }))
const sent = vi.hoisted(() => ({ roots: [] as (HTMLElement | null)[] }))
const pokes = vi.hoisted(() => ({ count: 0 }))
vi.mock('@adh-sdk/chat', async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  submitChatInput: (root: HTMLElement | null) => {
    sent.roots.push(root)
  },
}))
vi.mock('../avatar', () => ({
  Bitbag: ({ handleRef }: { handleRef?: { current: unknown } }) => {
    if (handleRef) handleRef.current = { poke: () => (pokes.count += 1) }
    return <span data-testid="bitbag" />
  },
}))
vi.mock('../BitbagInfo', () => ({ BitbagInfo: () => <span data-testid="info" /> }))
vi.mock('../BitbagChat', () => ({
  BitbagChat: (props: BitbagChatProps) => {
    chat.props = props
    return (
      <div className="persona-chat" data-testid="chat">
        <input className="pc-input" aria-label="Message" />
      </div>
    )
  },
}))

import { BitbagInline } from '../BitbagInline'

describe('BitbagInline', () => {
  it('mounts his dock-variant chat pinned open, with him as the send button', () => {
    const { container } = render(<BitbagInline />)
    expect(chat.props.variant).toBe('dock')
    expect(chat.props.engaged).toBe(true)
    expect(chat.props.sendButton).toBe(false)
    expect(screen.getByRole('button', { name: 'Send to bitbag' })).toBeInTheDocument()
    expect(screen.getByTestId('info')).toBeInTheDocument()
    // None of the fixture's rules may reach it: they are all keyed on `.bb-dock`.
    expect(container.querySelector('.bb-dock')).toBeNull()
  })

  it('stays open when the chat reports a fold', () => {
    render(<BitbagInline />)
    act(() => chat.props.onEngagedChange?.(false))
    expect(chat.props.engaged).toBe(true)
  })

  it('sends the composer and pokes him on a tap or Enter, without taking focus', () => {
    const { container } = render(<BitbagInline />)
    const avatar = screen.getByRole('button', { name: 'Send to bitbag' })
    sent.roots = []
    pokes.count = 0
    fireEvent.click(avatar)
    fireEvent.keyDown(avatar, { key: 'Enter' })
    expect(sent.roots).toEqual([container.querySelector('.bb-inline'), container.querySelector('.bb-inline')])
    expect(pokes.count).toBe(2)
    const down = fireEvent.mouseDown(avatar)
    expect(down).toBe(false) // default prevented
  })

  it("hands a host's backend and voice to his chat", () => {
    const voice = { welcome: 'w', greeting: 'g', placeholders: ['p'], intro: ['i'], seeded: [], fallbacks: ['f'] }
    const backend = { sendMessage: vi.fn() } as unknown as NonNullable<BitbagChatProps['backend']>
    render(<BitbagInline voice={voice} backend={backend} />)
    expect(chat.props.voice).toBe(voice)
    expect(chat.props.backend).toBe(backend)
  })
})
