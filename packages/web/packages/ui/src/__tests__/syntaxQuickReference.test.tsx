/**
 * Conformance tests for SyntaxQuickReference — the shared cheatsheet popover shell.
 * One `it` per vector in cookbook/ui/components/actions/quick-reference/conformance-test-vectors.md.
 * Uses the real Popover (base-ui); vitest.setup stubs let the floating popup mount.
 */
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { describe, it, expect, afterEach, vi } from 'vitest'
import { SyntaxQuickReference } from '../components/quick-reference'

afterEach(cleanup)

const ENTRIES = [
  { label: 'Bold', syntax: '**text**' },
  { label: 'Italic', syntax: '*text*' },
]

type Props = Partial<React.ComponentProps<typeof SyntaxQuickReference>>

function renderIt(over: Props = {}) {
  return render(
    <SyntaxQuickReference
      title="Markdown Syntax"
      entries={ENTRIES}
      ariaLabel="Markdown quick reference"
      {...over}
    />,
  )
}

const trigger = (name = 'Markdown quick reference'): HTMLElement =>
  screen.getByRole('button', { name })
const popup = (): HTMLElement | null =>
  document.querySelector('[data-slot="popover-content"]')
const grid = (): HTMLElement => document.querySelector('dl') as HTMLElement

async function open(over: Props = {}) {
  renderIt(over)
  fireEvent.click(trigger(over.ariaLabel))
  await waitFor(() => expect(popup()).not.toBeNull())
}

describe('SyntaxQuickReference conformance vectors', () => {
  it('quick-ref-001: trigger is an outline, small button with a book icon at inline start', () => {
    renderIt()
    const btn = trigger()
    expect(btn).toBeVisible()
    // buttonVariants outline/sm: the outline variant draws a border and sm sets the height.
    expect(btn.className).toContain('border')
    expect(btn.className).toContain('h-7')
    const icon = btn.querySelector('svg')
    expect(icon).not.toBeNull()
    expect(icon!.getAttribute('data-icon')).toBe('inline-start')
    expect(icon!.getAttribute('class')).toContain('lucide-book-text')
  })

  it('quick-ref-002: trigger carries the ariaLabel as aria-label', () => {
    renderIt()
    expect(trigger().getAttribute('aria-label')).toBe('Markdown quick reference')
  })

  it('quick-ref-003: clicking the trigger opens the popover', async () => {
    renderIt()
    expect(popup()).toBeNull()
    fireEvent.click(trigger())
    await waitFor(() => expect(popup()).not.toBeNull())
  })

  it('quick-ref-004: the title shows in field-caption style', async () => {
    await open()
    const title = screen.getByText('Markdown Syntax')
    expect(title.className).toContain('font-mono')
    expect(title.className).toContain('uppercase')
    expect(title.className).toContain('tracking-wider')
  })

  it('quick-ref-005: entries render as dt/dd pairs in a two-column grid', async () => {
    await open()
    const dts = Array.from(grid().querySelectorAll('dt')).map((n) => n.textContent)
    const dds = Array.from(grid().querySelectorAll('dd')).map((n) => n.textContent)
    expect(dts).toEqual(['Bold', 'Italic'])
    expect(dds).toEqual(['**text**', '*text*'])
    expect(grid().className).toContain('grid')
    expect(grid().className).toContain('grid-cols-[7rem_1fr]')
  })

  it('quick-ref-006: entry labels are small and muted', async () => {
    await open()
    const dt = screen.getByText('Bold')
    expect(dt.tagName).toBe('DT')
    expect(dt.className).toContain('text-sm')
    expect(dt.className).toContain('text-apt-text-muted')
  })

  it('quick-ref-007: code keeps newlines, monospace, smaller than the label, snug leading', async () => {
    await open({ entries: [{ label: 'Lines', syntax: 'line1\nline2' }] })
    const code = grid().querySelector('dd code') as HTMLElement
    expect(code.textContent).toBe('line1\nline2')
    expect(code.className).toContain('whitespace-pre-wrap')
    expect(code.className).toContain('font-mono')
    expect(code.className).toContain('text-xs')
    expect(code.className).toContain('leading-snug')
    expect(screen.getByText('Lines').className).toContain('text-sm')
  })

  it('quick-ref-008: Escape closes the popover', async () => {
    await open()
    fireEvent.keyDown(document.body, { key: 'Escape' })
    await waitFor(() => expect(popup()).toBeNull())
  })

  it('quick-ref-009: a click outside closes the popover', async () => {
    await open()
    fireEvent.pointerDown(document.body)
    fireEvent.mouseDown(document.body)
    fireEvent.pointerUp(document.body)
    fireEvent.mouseUp(document.body)
    fireEvent.click(document.body)
    await waitFor(() => expect(popup()).toBeNull())
  })

  it('quick-ref-010: Escape from inside the panel returns focus to the trigger', async () => {
    await open()
    const panel = popup()!
    panel.focus()
    fireEvent.keyDown(panel, { key: 'Escape' })
    await waitFor(() => expect(popup()).toBeNull())
    await waitFor(() => expect(document.activeElement).toBe(trigger()))
  })

  it('quick-ref-011: triggerLabel shows beside the icon', () => {
    renderIt({ triggerLabel: 'Syntax' })
    const btn = trigger()
    expect(btn).toHaveTextContent('Syntax')
    expect(btn.querySelector('svg')).not.toBeNull()
  })

  it('quick-ref-012: contentClassName replaces the default w-80 width', async () => {
    await open({ contentClassName: 'w-96' })
    expect(popup()!.className).toContain('w-96')
    expect(popup()!.className).not.toContain('w-80')
  })

  it('quick-ref-013: columnsClassName replaces the default column split', async () => {
    await open({ columnsClassName: 'grid-cols-[10rem_1fr]' })
    expect(grid().className).toContain('grid-cols-[10rem_1fr]')
    expect(grid().className).not.toContain('grid-cols-[7rem_1fr]')
  })

  it('quick-ref-014: side and align reach the positioner', async () => {
    await open({ side: 'top', align: 'start' })
    expect(popup()!.getAttribute('data-side')).toBe('top')
    expect(popup()!.getAttribute('data-align')).toBe('start')
  })

  it('quick-ref-015: className lands on the trigger beside its style classes', () => {
    renderIt({ className: 'custom-trigger-class' })
    const btn = trigger()
    expect(btn.className).toContain('custom-trigger-class')
    expect(btn.className).toContain('border')
    expect(btn.className).toContain('h-7')
  })

  it('quick-ref-016: a native button activates from the keyboard and opens the popover', async () => {
    renderIt()
    const btn = trigger()
    expect(btn.tagName).toBe('BUTTON')
    btn.focus()
    // jsdom does not synthesize click from Enter/Space; a native button fires click on
    // both, which is what the component relies on.
    fireEvent.click(btn)
    await waitFor(() => expect(popup()).not.toBeNull())
  })

  it('quick-ref-017: aria-expanded flips false to true; aria-haspopup is on in both states', async () => {
    renderIt()
    const btn = trigger()
    expect(btn.getAttribute('aria-expanded')).toBe('false')
    expect(btn.hasAttribute('aria-haspopup')).toBe(true)
    fireEvent.click(btn)
    await waitFor(() => expect(btn.getAttribute('aria-expanded')).toBe('true'))
    expect(btn.hasAttribute('aria-haspopup')).toBe(true)
  })

  it('quick-ref-018: no entries gives the title and an empty dl', async () => {
    await open({ entries: [] })
    expect(screen.getByText('Markdown Syntax')).toBeInTheDocument()
    expect(grid()).not.toBeNull()
    expect(grid().querySelectorAll('dt, dd')).toHaveLength(0)
  })

  it('quick-ref-019: ariaLabel containing the triggerLabel text is used as given', () => {
    renderIt({ triggerLabel: 'Syntax', ariaLabel: 'Syntax reference' })
    const btn = trigger('Syntax reference')
    expect(btn.getAttribute('aria-label')).toBe('Syntax reference')
    expect(btn).toHaveTextContent('Syntax')
    expect(btn.getAttribute('aria-label')).toContain('Syntax')
  })

  it('quick-ref-020: a mismatched ariaLabel is kept exactly and does not warn', () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    renderIt({ triggerLabel: 'Syntax', ariaLabel: 'Reference panel' })
    expect(trigger('Reference panel').getAttribute('aria-label')).toBe('Reference panel')
    expect(warn).not.toHaveBeenCalled()
    expect(error).not.toHaveBeenCalled()
    warn.mockRestore()
    error.mockRestore()
  })

  it('quick-ref-021: the code cell keeps left-to-right direction under a dir="rtl" ancestor', async () => {
    render(
      <div dir="rtl">
        <SyntaxQuickReference
          title="Markdown Syntax"
          entries={ENTRIES}
          ariaLabel="Markdown quick reference"
        />
      </div>,
    )
    fireEvent.click(trigger())
    await waitFor(() => expect(popup()).not.toBeNull())
    const code = grid().querySelector('code') as HTMLElement
    expect(code.closest('[dir="ltr"]')).not.toBeNull()
  })
})
