import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { ReactionBar, DEFAULT_REACTIONS, type ReactionBarItem } from '../components/reaction-bar'

// The bar is presentational: the caller owns the tallies and the write. So what is worth pinning
// is the part a caller CANNOT see from the props — that a chip is a toggle rather than an "add",
// that the pressed state is announced rather than only coloured, and that the two ways to react
// (a chip, the palette) call the same handler with the same argument.
describe('ReactionBar', () => {
  const bar = (over: Partial<Parameters<typeof ReactionBar>[0]> = {}) => {
    const onToggle = vi.fn()
    render(
      <ReactionBar
        reactions={[
          { emoji: '👍', count: 2, mine: true },
          { emoji: '🎉', count: 1, mine: false },
        ]}
        onToggle={onToggle}
        subjectLabel="Ada’s comment"
        {...over}
      />,
    )
    return onToggle
  }

  it('names each chip by its emoji, its count and its subject', () => {
    bar()
    expect(screen.getByRole('button', { name: '👍 2 on Ada’s comment' })).toBeTruthy()
    expect(screen.getByRole('button', { name: '🎉 1 on Ada’s comment' })).toBeTruthy()
  })

  it('announces the viewer’s own reaction as PRESSED, not merely as coloured', () => {
    bar()
    expect(screen.getByRole('button', { name: /👍/ }).getAttribute('aria-pressed')).toBe('true')
    expect(screen.getByRole('button', { name: /🎉/ }).getAttribute('aria-pressed')).toBe('false')
  })

  it('pressing a chip you are part of asks to TAKE IT BACK, with the same call', () => {
    // One handler, one argument, both directions — the caller decides add-vs-remove from the
    // tally it already holds, so the bar never has to carry two callbacks that can disagree.
    const onToggle = bar()
    fireEvent.click(screen.getByRole('button', { name: /👍/ }))
    expect(onToggle).toHaveBeenCalledWith('👍')
  })

  it('offers the palette’s emoji through the same toggle', () => {
    const onToggle = bar()
    fireEvent.click(screen.getByRole('button', { name: 'React to Ada’s comment' }))
    fireEvent.click(screen.getByRole('button', { name: `React ${DEFAULT_REACTIONS[1]} to Ada’s comment` }))
    expect(onToggle).toHaveBeenCalledWith(DEFAULT_REACTIONS[1])
  })

  it('goes inert while a write is in flight, without hiding or re-ordering anything', () => {
    // A bar that dropped its chips mid-write would move the pointer's target between the press
    // and the result; the counts stay exactly where they were and simply stop responding.
    bar({ busy: true })
    expect((screen.getByRole('button', { name: /👍/ }) as HTMLButtonElement).disabled).toBe(true)
    expect((screen.getByRole('button', { name: /🎉/ }) as HTMLButtonElement).disabled).toBe(true)
    expect(screen.getAllByRole('button', { name: /on Ada’s comment/ })).toHaveLength(2)
  })

  it('still shows the counts to a viewer who may not react, but offers no way in', () => {
    bar({ disabled: true })
    expect(screen.getByRole('button', { name: /👍 2/ })).toBeTruthy()
    expect(screen.queryByRole('button', { name: 'React to Ada’s comment' })).toBeNull()
  })

  it('renders nothing but the palette trigger when a subject has no reactions yet', () => {
    bar({ reactions: [] })
    expect(screen.queryByRole('button', { name: /on Ada’s comment/ })).toBeNull()
    expect(screen.getByRole('button', { name: 'React to Ada’s comment' })).toBeTruthy()
  })
})

// One `it` per vector in cookbook/ui/components/actions/reaction-bar/conformance-test-vectors.md.
describe('ReactionBar conformance vectors', () => {
  afterEach(cleanup)

  const SUBJECT = 'Ada’s comment'
  const TALLIES: ReactionBarItem[] = [
    { emoji: '👍', count: 2, mine: true },
    { emoji: '🎉', count: 1, mine: false },
  ]
  const chip = (emoji: string): HTMLButtonElement =>
    screen.getByRole('button', { name: new RegExp(`^${emoji} \\d+ on`) }) as HTMLButtonElement
  const trigger = (subject = SUBJECT): HTMLButtonElement =>
    screen.getByRole('button', { name: `React to ${subject}` }) as HTMLButtonElement
  const popup = (): HTMLElement | null => document.querySelector('[data-slot="popover-content"]')
  const palette = (): string[] =>
    Array.from(popup()!.querySelectorAll('button')).map((b) => b.textContent ?? '')

  function renderBar(over: Partial<Parameters<typeof ReactionBar>[0]> = {}) {
    const onToggle = vi.fn<(emoji: string) => void>()
    render(<ReactionBar reactions={TALLIES} onToggle={onToggle} subjectLabel={SUBJECT} {...over} />)
    return onToggle
  }

  it('T1: one chip per tally, named by emoji, count and subject', () => {
    renderBar()
    expect(screen.getByRole('button', { name: `👍 2 on ${SUBJECT}` })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: `🎉 1 on ${SUBJECT}` })).toBeInTheDocument()
  })

  it('T2: the viewer’s own chip is aria-pressed true, the other false', () => {
    renderBar()
    expect(chip('👍')).toHaveAttribute('aria-pressed', 'true')
    expect(chip('🎉')).toHaveAttribute('aria-pressed', 'false')
  })

  it('T3: clicking the viewer’s own chip calls onToggle with its emoji', () => {
    const onToggle = renderBar()
    fireEvent.click(chip('👍'))
    expect(onToggle).toHaveBeenCalledTimes(1)
    expect(onToggle).toHaveBeenCalledWith('👍')
  })

  it('T4: without a consumer re-render the chip still reads 2 and pressed', () => {
    renderBar()
    fireEvent.click(chip('👍'))
    expect(chip('👍')).toHaveAttribute('aria-pressed', 'true')
    expect(chip('👍')).toHaveTextContent('2')
    expect(chip('👍').getAttribute('aria-label')).toBe(`👍 2 on ${SUBJECT}`)
  })

  it('T5: picking from the palette toggles that emoji and closes the popover', async () => {
    const onToggle = renderBar()
    fireEvent.click(trigger())
    await waitFor(() => expect(popup()).not.toBeNull())
    fireEvent.click(screen.getByRole('button', { name: `React ${DEFAULT_REACTIONS[1]} to ${SUBJECT}` }))
    expect(onToggle).toHaveBeenCalledWith(DEFAULT_REACTIONS[1])
    await waitFor(() => expect(popup()).toBeNull())
  })

  it('T6: an emoji already on the subject is still offered in the palette', async () => {
    renderBar()
    fireEvent.click(trigger())
    await waitFor(() => expect(popup()).not.toBeNull())
    expect(screen.getByRole('button', { name: `React 👍 to ${SUBJECT}` })).toBeInTheDocument()
  })

  it('T7: busy disables every chip and the trigger, keeping the same chips in order', () => {
    renderBar({ busy: true })
    const chips = screen.getAllByRole('button', { name: new RegExp(`on ${SUBJECT}$`) })
    expect(chips.map((c) => c.getAttribute('aria-label'))).toEqual([
      `👍 2 on ${SUBJECT}`,
      `🎉 1 on ${SUBJECT}`,
    ])
    chips.forEach((c) => expect(c).toBeDisabled())
    expect(trigger()).toBeDisabled()
  })

  it('T8: disabled keeps disabled chips and renders no palette trigger', () => {
    renderBar({ disabled: true })
    expect(chip('👍')).toBeDisabled()
    expect(chip('🎉')).toBeDisabled()
    expect(screen.queryByRole('button', { name: `React to ${SUBJECT}` })).toBeNull()
  })

  it('T9: no reactions renders no chip, only the palette trigger', () => {
    renderBar({ reactions: [] })
    expect(screen.getAllByRole('button')).toHaveLength(1)
    expect(trigger()).toBeInTheDocument()
  })

  it('T10: the emoji glyph span is aria-hidden', () => {
    renderBar()
    const glyph = chip('👍').querySelector('span')!
    expect(glyph).toHaveTextContent('👍')
    expect(glyph).toHaveAttribute('aria-hidden', 'true')
  })

  // Playwright vector: it compares two bars on a real page; no Playwright spec exists in this repo.
  it.skip('T11: two bars with different subjectLabel are addressable by name (Playwright vector)', () => {})

  it('T12: custom choices are exactly what the palette offers, in order', async () => {
    renderBar({ choices: ['🔥', '🚀'] })
    fireEvent.click(trigger())
    await waitFor(() => expect(popup()).not.toBeNull())
    expect(palette()).toEqual(['🔥', '🚀'])
  })

  it('T13: onToggle is not called by a chip under busy or under disabled', () => {
    const busy = renderBar({ busy: true })
    fireEvent.click(chip('👍'))
    expect(busy).not.toHaveBeenCalled()
    cleanup()
    const disabled = renderBar({ disabled: true })
    fireEvent.click(chip('👍'))
    expect(disabled).not.toHaveBeenCalled()
  })
})
