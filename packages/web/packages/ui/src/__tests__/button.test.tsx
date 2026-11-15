/** Unit tests for the shared Button's pointer-driven pressed state (c8). The
 *  pressed *visual* is CSS (data-[pressed]:* utilities); here we assert the
 *  `data-pressed` reflection that drives it. The real visual dip + DOM focus are
 *  covered by app-level Playwright. Interactions use fireEvent (no userEvent),
 *  matching the other shared/ui component tests. */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { Button } from '../components/button'

describe('Button (pressed state)', () => {
  it('sets data-pressed on pointerdown inside and clears it on pointerup', () => {
    render(<Button>Press me</Button>)
    const button = screen.getByRole('button', { name: 'Press me' })
    expect(button).not.toHaveAttribute('data-pressed')

    fireEvent.pointerDown(button)
    expect(button).toHaveAttribute('data-pressed')

    fireEvent.pointerUp(button)
    expect(button).not.toHaveAttribute('data-pressed')
  })

  it('clears data-pressed when the pointer leaves while held, and restores it on re-enter', () => {
    render(<Button>Hold me</Button>)
    const button = screen.getByRole('button', { name: 'Hold me' })

    fireEvent.pointerDown(button)
    expect(button).toHaveAttribute('data-pressed')

    // Pointer leaves while still held → the pressed visual drops…
    fireEvent.pointerLeave(button)
    expect(button).not.toHaveAttribute('data-pressed')

    // …and is restored if the pointer comes back before release.
    fireEvent.pointerEnter(button)
    expect(button).toHaveAttribute('data-pressed')
  })

  it('forwards a consumer pointer handler alongside the pressed tracking', () => {
    const onPointerDown = vi.fn()
    render(<Button onPointerDown={onPointerDown}>Click</Button>)
    const button = screen.getByRole('button', { name: 'Click' })

    fireEvent.pointerDown(button)
    expect(onPointerDown).toHaveBeenCalledTimes(1)
    expect(button).toHaveAttribute('data-pressed')
  })
})

describe('Button conformance vectors (recipe ui/components/actions/button)', () => {
  it('T1 sets data-pressed on pointerdown', () => {
    render(<Button>T1</Button>)
    const button = screen.getByRole('button')
    fireEvent.pointerDown(button)
    expect(button).toHaveAttribute('data-pressed')
  })

  it('T2 clears data-pressed on pointerup', () => {
    render(<Button>T2</Button>)
    const button = screen.getByRole('button')
    fireEvent.pointerDown(button)
    fireEvent.pointerUp(button)
    expect(button).not.toHaveAttribute('data-pressed')
  })

  it('T3 clears data-pressed on pointerleave during an active press', () => {
    render(<Button>T3</Button>)
    const button = screen.getByRole('button')
    fireEvent.pointerDown(button)
    fireEvent.pointerLeave(button)
    expect(button).not.toHaveAttribute('data-pressed')
  })

  it('T4 restores data-pressed on pointerenter during an active press', () => {
    render(<Button>T4</Button>)
    const button = screen.getByRole('button')
    fireEvent.pointerDown(button)
    fireEvent.pointerLeave(button)
    fireEvent.pointerEnter(button)
    expect(button).toHaveAttribute('data-pressed')
  })

  it('T5 forwards a consumer onPointerDown once and still sets data-pressed', () => {
    const onPointerDown = vi.fn()
    render(<Button onPointerDown={onPointerDown}>T5</Button>)
    const button = screen.getByRole('button')
    fireEvent.pointerDown(button)
    expect(onPointerDown).toHaveBeenCalledTimes(1)
    expect(button).toHaveAttribute('data-pressed')
  })

  it('T6 a window pointerup during a held-outside press ends the hold; a later pointerenter does not re-press', () => {
    render(<Button>T6</Button>)
    const button = screen.getByRole('button')
    fireEvent.pointerDown(button)
    fireEvent.pointerLeave(button)
    fireEvent.pointerUp(window)
    fireEvent.pointerEnter(button)
    expect(button).not.toHaveAttribute('data-pressed')
  })

  it.skip('T7 keyboard activation: click fires with no pointer dip (needs Playwright, real focus and key events)', () => {})

  it.skip('T8 aria-haspopup suppresses the dip (needs Playwright, the dip is a CSS transform)', () => {})

  it('T9 clears data-pressed on pointercancel', () => {
    render(<Button>T9</Button>)
    const button = screen.getByRole('button')
    fireEvent.pointerDown(button)
    fireEvent.pointerCancel(button)
    expect(button).not.toHaveAttribute('data-pressed')
  })

  it('T10 never takes pointer capture on pointerdown', () => {
    render(<Button>T10</Button>)
    const button = screen.getByRole('button')
    const setCapture = vi.fn()
    ;(button as HTMLElement & { setPointerCapture: (id: number) => void }).setPointerCapture = setCapture
    const hasCapture = (button as HTMLElement & { hasPointerCapture?: (id: number) => boolean }).hasPointerCapture
    fireEvent.pointerDown(button, { pointerId: 7 })
    expect(setCapture).not.toHaveBeenCalled()
    if (typeof hasCapture === 'function') expect(hasCapture.call(button, 7)).toBe(false)
    fireEvent.pointerUp(button, { pointerId: 7 })
    expect(setCapture).not.toHaveBeenCalled()
  })

  it('T11 renders data-slot="button" on the root for variant secondary, size lg', () => {
    render(<Button variant="secondary" size="lg" data-testid="b" />)
    expect(screen.getByTestId('b')).toHaveAttribute('data-slot', 'button')
  })

  it('T12 the warning variant carries the apt-orange classes', () => {
    render(<Button variant="warning">W</Button>)
    const button = screen.getByRole('button')
    expect(button).toHaveClass('bg-apt-orange/15')
    expect(button).toHaveClass('text-apt-orange')
  })

  it('T13 defaults to the default variant and size', () => {
    render(<Button>D</Button>)
    const button = screen.getByRole('button')
    expect(button).toHaveClass('bg-primary')
    expect(button).toHaveClass('h-8')
  })

  it.skip('T14 min-height follows --adh-button-min-height (needs real CSS; jsdom has no Tailwind stylesheet)', () => {})

  it.skip('T15 icon size min-width follows --adh-button-min-height (needs real CSS; jsdom has no Tailwind stylesheet)', () => {})

  it.skip('T16 child svg pointer-events none and flex-shrink 0 (needs real CSS; jsdom has no Tailwind stylesheet)', () => {})

  it.skip('T17 unsized svg renders 16x16 in the default size (needs real layout/CSS)', () => {})

  it('T18 a consumer className wins over the variant background', () => {
    render(<Button className="bg-brand-500">C</Button>)
    const button = screen.getByRole('button')
    expect(button).toHaveClass('bg-brand-500')
    expect(button).not.toHaveClass('bg-primary')
  })

  it.skip('T19 min-width follows --adh-button-min-width (needs real CSS; jsdom has no Tailwind stylesheet)', () => {})

  it.skip('T20 :active forces no pressed visual (needs Playwright/CDP forcePseudoState and emitted CSS)', () => {})

  it.skip('T21 unsized svg renders 14x14 in size sm (needs real layout/CSS)', () => {})

  it.skip('T22 unsized svg renders 12x12 in sizes xs and icon-xs (needs real layout/CSS)', () => {})

  it('T23 a window pointercancel during a held-outside press ends the hold; a later pointerenter does not re-press', () => {
    render(<Button>T23</Button>)
    const button = screen.getByRole('button')
    fireEvent.pointerDown(button)
    fireEvent.pointerLeave(button)
    fireEvent.pointerCancel(window)
    fireEvent.pointerEnter(button)
    expect(button).not.toHaveAttribute('data-pressed')
  })

  it('T24 a disabled button never gets data-pressed', () => {
    render(<Button disabled>T24</Button>)
    const button = screen.getByRole('button')
    fireEvent.pointerDown(button)
    expect(button).not.toHaveAttribute('data-pressed')
    // computed pointer-events: none comes from the disabled: utility, which needs real CSS.
    expect(button).toHaveClass('disabled:pointer-events-none')
  })

  it.skip('T25 an explicit size-6 svg renders 24x24 (needs real layout/CSS)', () => {})

  it.skip('T26 default floor is 0px and rendered height 32px (needs real layout/CSS)', () => {})
})
