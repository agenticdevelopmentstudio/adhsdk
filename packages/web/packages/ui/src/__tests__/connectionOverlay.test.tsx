/**
 * Conformance vectors for the ConnectionOverlay recipe (overlay-001 .. overlay-025).
 *
 * Fake timers drive the 1200ms show-delay debounce, the 1s tick, the 15s retry cycle and the
 * 90s deploy-grace clock. jsdom evaluates no media queries, so overlay-023 asserts the
 * reduced-motion utility class rather than a stopped animation.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, fireEvent, act, cleanup } from '@testing-library/react'
import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'

import { ConnectionOverlay } from '../components/connection-overlay'

const SHOW_DELAY = 1_200

function advance(ms: number) {
  act(() => {
    vi.advanceTimersByTime(ms)
  })
}

/** Render active and let the debounce elapse so the card is on screen. */
function renderShown(props: Partial<React.ComponentProps<typeof ConnectionOverlay>> = {}) {
  const onRetry = props.onRetry ?? vi.fn()
  const utils = render(<ConnectionOverlay active onRetry={onRetry} {...props} />)
  advance(SHOW_DELAY)
  return { ...utils, onRetry }
}

const heading = () => screen.queryByText(/^Backend (deploying|unreachable)$/)

describe('ConnectionOverlay conformance vectors', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })
  afterEach(() => {
    cleanup()
    vi.useRealTimers()
  })

  it('overlay-001 returns null when inactive', () => {
    const { container } = render(<ConnectionOverlay active={false} onRetry={vi.fn()} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('overlay-002 renders after the 1200ms delay', () => {
    const { container } = render(<ConnectionOverlay active onRetry={vi.fn()} />)
    advance(SHOW_DELAY)
    expect(container.querySelector('[role="status"]')).not.toBeNull()
  })

  it('overlay-003 does not render before 1200ms', () => {
    const { container } = render(<ConnectionOverlay active onRetry={vi.fn()} />)
    advance(500)
    expect(container).toBeEmptyDOMElement()
    advance(SHOW_DELAY - 500 - 1)
    expect(container).toBeEmptyDOMElement()
  })

  it('overlay-004 hides immediately on recovery without waiting out the debounce', () => {
    const onRetry = vi.fn()
    const { container, rerender } = render(<ConnectionOverlay active onRetry={onRetry} />)
    advance(SHOW_DELAY)
    expect(container.querySelector('[role="status"]')).not.toBeNull()
    rerender(<ConnectionOverlay active={false} onRetry={onRetry} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('overlay-005 shows "Backend deploying" within the grace period', () => {
    renderShown()
    advance(1_000)
    expect(heading()).toHaveTextContent('Backend deploying')
  })

  it('overlay-006 shows "Backend unreachable" after the grace period', () => {
    renderShown()
    advance(90_000)
    expect(heading()).toHaveTextContent('Backend unreachable')
  })

  it('overlay-007 shows the deploying subtext while deploying', () => {
    renderShown()
    advance(1_000)
    expect(
      screen.getByText(
        'The backend is restarting — reconnecting automatically. This usually takes a moment.',
      ),
    ).toBeInTheDocument()
  })

  it('overlay-008 shows the unreachable subtext when unreachable', () => {
    renderShown()
    advance(90_000)
    expect(screen.getByText("Still can't reach the backend. Retrying automatically.")).toBeInTheDocument()
  })

  it('overlay-009 counts down from 15 to 1 and never renders 0', () => {
    renderShown()
    expect(screen.getByText('Retrying in 15s')).toBeInTheDocument()
    for (let expected = 14; expected >= 1; expected--) {
      advance(1_000)
      expect(screen.getByText(`Retrying in ${expected}s`)).toBeInTheDocument()
      expect(screen.queryByText('Retrying in 0s')).toBeNull()
    }
  })

  it('overlay-010 auto-retries once when the countdown runs out and resets to 15', () => {
    const { onRetry } = renderShown()
    advance(14_000)
    expect(screen.getByText('Retrying in 1s')).toBeInTheDocument()
    expect(onRetry).not.toHaveBeenCalled()
    advance(1_000)
    expect(onRetry).toHaveBeenCalledTimes(1)
    expect(screen.getByText('Retrying in 15s')).toBeInTheDocument()
    expect(screen.queryByText('Retrying in 0s')).toBeNull()
  })

  it('overlay-011 renders the "Try again now" button', () => {
    renderShown()
    const button = screen.getByRole('button', { name: 'Try again now' })
    expect(button).toBeEnabled()
  })

  it('overlay-012 manual retry calls onRetry and resets the countdown to 15', () => {
    const { onRetry } = renderShown()
    advance(5_000)
    expect(screen.getByText('Retrying in 10s')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Try again now' }))
    expect(onRetry).toHaveBeenCalledTimes(1)
    expect(screen.getByText('Retrying in 15s')).toBeInTheDocument()
  })

  it('overlay-013 shows the detail text after the grace period', () => {
    renderShown({ detail: 'Network timeout' })
    advance(90_000)
    expect(screen.getByText('Network timeout')).toBeInTheDocument()
  })

  it('overlay-014 hides the detail text while deploying', () => {
    renderShown({ detail: 'Error' })
    advance(1_000)
    expect(screen.queryByText('Error')).toBeNull()
  })

  it('overlay-015 renders no detail element when detail is null', () => {
    const { container } = renderShown({ detail: null })
    advance(90_000)
    // card children: spinner, heading, sub, countdown, button — and nothing after the button
    const card = container.querySelector('[role="status"] > div') as HTMLElement
    expect(card.lastElementChild).toBe(screen.getByRole('button', { name: 'Try again now' }))
  })

  it('overlay-016 is a polite status live region', () => {
    const { container } = renderShown()
    const root = container.firstElementChild as HTMLElement
    expect(root).toHaveAttribute('role', 'status')
    expect(root).toHaveAttribute('aria-live', 'polite')
  })

  it('overlay-017 hides the countdown from screen readers', () => {
    renderShown()
    expect(screen.getByText('Retrying in 15s')).toHaveAttribute('aria-hidden', 'true')
  })

  it.skip('overlay-018 covers the parent and captures pointer events (jsdom has no layout or hit-testing)', () => {})

  it('overlay-019 renders a 34px aria-hidden Loader2 spinner in var(--color-apt-blue)', () => {
    const { container } = renderShown()
    const svg = container.querySelector('svg') as SVGElement
    expect(svg).toHaveClass('lucide-loader-circle')
    expect(svg).toHaveAttribute('width', '34')
    expect(svg).toHaveAttribute('height', '34')
    expect(svg).toHaveAttribute('stroke', 'var(--color-apt-blue)')
    expect(svg).toHaveAttribute('aria-hidden', 'true')
  })

  it('overlay-020 button sets no outline override and is keyboard focusable', () => {
    renderShown()
    const button = screen.getByRole('button', { name: 'Try again now' })
    expect(button.style.outline).toBe('')
    expect(window.getComputedStyle(button).outline).not.toBe('none')
    button.focus()
    expect(button).toHaveFocus()
  })

  it('overlay-021 the heading switch at 90s does not reset the countdown cycle', () => {
    const { onRetry } = renderShown()
    advance(89_000)
    expect(heading()).toHaveTextContent('Backend deploying')
    expect(screen.getByText('Retrying in 1s')).toBeInTheDocument()
    advance(1_000)
    expect(heading()).toHaveTextContent('Backend unreachable')
    expect(onRetry).toHaveBeenCalledTimes(6)
    // the countdown keeps its own 15s cycle: 7 ticks into the next cycle it shows 8
    advance(7_000)
    expect(screen.getByText('Retrying in 8s')).toBeInTheDocument()
    expect(heading()).toHaveTextContent('Backend unreachable')
  })

  it('overlay-022 a rapid active toggle cancels the first debounce timer', () => {
    const onRetry = vi.fn()
    const { container, rerender } = render(<ConnectionOverlay active onRetry={onRetry} />)
    advance(250)
    rerender(<ConnectionOverlay active={false} onRetry={onRetry} />)
    advance(250)
    rerender(<ConnectionOverlay active onRetry={onRetry} />)
    // original 1200ms mark (700ms into the second wait): still hidden
    advance(SHOW_DELAY - 500)
    expect(container).toBeEmptyDOMElement()
    // 1199ms after the second `true`: still hidden; at 1200ms: shown
    advance(SHOW_DELAY - (SHOW_DELAY - 500) - 1)
    expect(container).toBeEmptyDOMElement()
    advance(1)
    expect(container.querySelector('[role="status"]')).not.toBeNull()
  })

  it('overlay-023 stops the spinner rotation under prefers-reduced-motion', () => {
    const { container } = renderShown()
    const spinner = container.querySelector('svg')
    expect(spinner).toHaveClass('animate-spin', 'motion-reduce:animate-none')
  })

  it('overlay-024 does not call onRetry after recovery', () => {
    // Capture the tick callback so it can be run once after the interval is cleared,
    // the way a tick already dequeued when active flips to false would run.
    const ticks: Array<() => void> = []
    const realSetInterval = globalThis.setInterval
    const spy = vi.spyOn(globalThis, 'setInterval').mockImplementation(((fn: () => void, ms?: number) => {
      ticks.push(fn)
      return realSetInterval(fn, ms)
    }) as typeof setInterval)
    const onRetry = vi.fn()
    const { rerender } = renderShown({ onRetry })
    // 14 ticks: the countdown sits at 1, so the next tick would retry
    advance(14_000)
    expect(onRetry).not.toHaveBeenCalled()
    rerender(<ConnectionOverlay active={false} onRetry={onRetry} />)
    act(() => {
      ticks[ticks.length - 1]!()
    })
    expect(onRetry).not.toHaveBeenCalled()
    spy.mockRestore()
  })

  it('overlay-025 contains focus inside the card and restores it on hide', () => {
    const onRetry = vi.fn()
    const { rerender } = render(
      <>
        <button type="button">behind</button>
        <ConnectionOverlay active onRetry={onRetry} />
      </>,
    )
    const behind = screen.getByText('behind')
    behind.focus()
    advance(SHOW_DELAY)
    const retry = screen.getByText('Try again now')
    expect(retry).toHaveFocus()
    // Tab and Shift+Tab wrap inside the card instead of leaving for the panels behind it
    expect(fireEvent.keyDown(retry, { key: 'Tab' })).toBe(false)
    expect(retry).toHaveFocus()
    expect(fireEvent.keyDown(retry, { key: 'Tab', shiftKey: true })).toBe(false)
    expect(retry).toHaveFocus()
    rerender(
      <>
        <button type="button">behind</button>
        <ConnectionOverlay active={false} onRetry={onRetry} />
      </>,
    )
    expect(behind).toHaveFocus()
  })
})
