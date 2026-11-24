/**
 * Unit tests for MarkdownQuickReference — the toolbar control that opens a
 * dismissible popover of common markdown syntax. Uses the real Popover (base-ui);
 * the rect/getComputedStyle stubs in vitest.setup let the floating popup mount.
 */
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { MarkdownQuickReference } from '../components/markdown-quick-reference'

function trigger(): HTMLElement {
  return screen.getByRole('button', { name: 'Markdown quick reference' })
}

describe('MarkdownQuickReference', () => {
  it('renders a labelled trigger that starts collapsed', () => {
    render(<MarkdownQuickReference />)
    const btn = trigger()
    expect(btn).toBeInTheDocument()
    // No syntax content visible until opened.
    expect(screen.queryByText('Markdown quick reference')).toBeNull()
  })

  it('opens the popover with the common syntax on click', async () => {
    render(<MarkdownQuickReference />)
    fireEvent.click(trigger())
    expect(
      await screen.findByText('Markdown quick reference'),
    ).toBeInTheDocument()
    // A representative spread of the documented syntaxes.
    expect(screen.getByText('Headings')).toBeInTheDocument()
    expect(screen.getByText('Bold')).toBeInTheDocument()
    expect(screen.getByText('Inline code')).toBeInTheDocument()
    expect(screen.getByText('Code block')).toBeInTheDocument()
    expect(screen.getByText('Link')).toBeInTheDocument()
    expect(screen.getByText('Blockquote')).toBeInTheDocument()
  })

  it('dismisses on Escape', async () => {
    render(<MarkdownQuickReference />)
    fireEvent.click(trigger())
    await screen.findByText('Markdown quick reference')
    fireEvent.keyDown(document.body, { key: 'Escape' })
    await waitFor(() =>
      expect(screen.queryByText('Markdown quick reference')).toBeNull(),
    )
  })

  it('reads "Markdown" on its trigger by default', () => {
    render(<MarkdownQuickReference />)
    expect(trigger()).toHaveTextContent('Markdown')
  })

  it('honors a custom trigger label', () => {
    render(<MarkdownQuickReference triggerLabel="Syntax" />)
    // Same aria-label, different visible text.
    expect(trigger()).toHaveTextContent('Syntax')
  })
})

describe('MarkdownQuickReference conformance vectors (recipe ui/components/actions/markdown-quick-reference)', () => {
  const LABELS = [
    'Headings', 'Bold', 'Italic', 'Inline code', 'Code block',
    'Bullet list', 'Numbered list', 'Link', 'Blockquote',
  ]

  it('T1 renders one labelled trigger and no caption while closed', () => {
    render(<MarkdownQuickReference />)
    expect(screen.getAllByRole('button')).toHaveLength(1)
    expect(trigger()).toBeInTheDocument()
    expect(screen.queryByText('Markdown quick reference')).toBeNull()
  })

  it('T2 opening shows the caption and all nine labels', async () => {
    render(<MarkdownQuickReference />)
    fireEvent.click(trigger())
    expect(await screen.findByText('Markdown quick reference')).toBeInTheDocument()
    for (const label of LABELS) expect(screen.getByText(label)).toBeInTheDocument()
  })

  it('T3 Escape removes the popover and returns focus to the trigger', async () => {
    render(<MarkdownQuickReference />)
    fireEvent.click(trigger())
    await screen.findByText('Markdown quick reference')
    fireEvent.keyDown(document.body, { key: 'Escape' })
    await waitFor(() => expect(screen.queryByText('Markdown quick reference')).toBeNull())
    await waitFor(() => expect(trigger()).toHaveFocus())
  })

  it('T4 a custom triggerLabel is the visible text while the accessible name stays fixed', () => {
    render(<MarkdownQuickReference triggerLabel="Syntax" />)
    const btn = screen.getByRole('button', { name: 'Markdown quick reference' })
    expect(btn).toHaveTextContent('Syntax')
  })

  it('T5 an outside click removes the popover and returns focus to the trigger', async () => {
    render(
      <div>
        <button type="button">outside</button>
        <MarkdownQuickReference />
      </div>,
    )
    fireEvent.click(trigger())
    await screen.findByText('Markdown quick reference')
    const outside = screen.getByRole('button', { name: 'outside' })
    fireEvent.pointerDown(outside)
    fireEvent.mouseDown(outside)
    fireEvent.pointerUp(outside)
    fireEvent.mouseUp(outside)
    fireEvent.click(outside)
    await waitFor(() => expect(screen.queryByText('Markdown quick reference')).toBeNull())
    await waitFor(() => expect(trigger()).toHaveFocus())
  })

  it('T6 keyboard activation (Enter then Space) opens the popover', async () => {
    // jsdom does not synthesize a click from a keydown on a native button, so the
    // key press is followed by the click a browser would dispatch for it.
    render(<MarkdownQuickReference />)
    for (const key of ['Enter', ' ']) {
      const btn = trigger()
      btn.focus()
      fireEvent.keyDown(btn, { key })
      fireEvent.keyUp(btn, { key })
      fireEvent.click(btn)
      expect(await screen.findByText('Markdown quick reference')).toBeInTheDocument()
      expect(screen.getByText('Headings')).toBeInTheDocument()
      fireEvent.keyDown(document.body, { key: 'Escape' })
      await waitFor(() => expect(screen.queryByText('Markdown quick reference')).toBeNull())
    }
  })

  it('T7 side and align reach the popover positioner', async () => {
    render(<MarkdownQuickReference side="top" align="start" />)
    fireEvent.click(trigger())
    const caption = await screen.findByText('Markdown quick reference')
    const content = caption.closest('[data-slot="popover-content"]')
    expect(content).not.toBeNull()
    const positioner = content!.closest('[data-side]') as HTMLElement | null
    expect(positioner).not.toBeNull()
    expect(positioner).toHaveAttribute('data-side', 'top')
    expect(positioner).toHaveAttribute('data-align', 'start')
  })
})
