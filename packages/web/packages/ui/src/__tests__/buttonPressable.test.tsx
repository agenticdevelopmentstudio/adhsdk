/** Conformance tests for PressableButton (recipe ui/components/actions/button-pressable).
 *  One `it` per conformance vector, titled with the vector id. Interactions use
 *  fireEvent, matching the other shared/ui component tests. */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import { PressableButton } from '../components/button-pressable'

afterEach(() => {
  vi.restoreAllMocks()
})

function setup(props: Record<string, unknown> = {}) {
  const utils = render(<PressableButton {...props}>Press</PressableButton>)
  const el = screen.getByRole('button')
  return { ...utils, el }
}

describe('PressableButton conformance', () => {
  it('button-pressable-001 forwards variant and aria-label unchanged', () => {
    const { el } = setup({ variant: 'secondary', 'aria-label': 'Save' })
    expect(el).toHaveAttribute('variant', 'secondary')
    expect(el).toHaveAttribute('aria-label', 'Save')
  })

  it('button-pressable-002 renders data-slot="button"', () => {
    const { el } = setup()
    expect(el).toHaveAttribute('data-slot', 'button')
  })

  it('button-pressable-003 has no data-pressed by default', () => {
    const { el } = setup()
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-004 sets data-pressed="" on pointerdown', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    expect(el).toHaveAttribute('data-pressed', '')
  })

  it('button-pressable-005 clears data-pressed on element pointerup', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    fireEvent.pointerUp(el)
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-006 clears data-pressed on pointerleave during a press', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    fireEvent.pointerLeave(el)
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-007 restores data-pressed on pointerenter during a press', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    fireEvent.pointerLeave(el)
    fireEvent.pointerEnter(el)
    expect(el).toHaveAttribute('data-pressed', '')
  })

  it('button-pressable-008 pointerenter without a press leaves data-pressed absent', () => {
    const { el } = setup()
    fireEvent.pointerEnter(el)
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-009 clears data-pressed on element pointercancel', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    fireEvent.pointerCancel(el)
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-010 clears data-pressed on window pointerup', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    fireEvent.pointerUp(window)
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-011 clears data-pressed on window pointercancel', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    fireEvent.pointerCancel(window)
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-012 press survives pointerleave and ends on window pointerup', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    fireEvent.pointerLeave(el)
    expect(el).not.toHaveAttribute('data-pressed')
    fireEvent.pointerUp(window)
    expect(el).not.toHaveAttribute('data-pressed')
    // Proof the hold ended: re-entering no longer restores the press.
    fireEvent.pointerEnter(el)
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-013 window pointerup with no press changes nothing and does not throw', () => {
    const { el } = setup()
    expect(() => fireEvent.pointerUp(window)).not.toThrow()
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-014 a second window pointerup after a completed press changes nothing', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    fireEvent.pointerUp(el)
    expect(() => fireEvent.pointerUp(window)).not.toThrow()
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-015 invokes a forwarded onPointerDown exactly once', () => {
    const spy = vi.fn()
    const { el } = setup({ onPointerDown: spy })
    fireEvent.pointerDown(el)
    expect(spy).toHaveBeenCalledTimes(1)
  })

  it('button-pressable-016 keyboard activation does not set data-pressed', () => {
    const { el } = setup()
    el.focus()
    for (const key of ['Enter', ' ']) {
      fireEvent.keyDown(el, { key })
      expect(el).not.toHaveAttribute('data-pressed')
      fireEvent.keyUp(el, { key })
      expect(el).not.toHaveAttribute('data-pressed')
    }
  })

  it('button-pressable-017 never calls setPointerCapture', () => {
    const spy = vi.fn()
    ;(HTMLElement.prototype as unknown as { setPointerCapture: unknown }).setPointerCapture = spy
    try {
      const { el } = setup()
      fireEvent.pointerDown(el)
      expect(spy).not.toHaveBeenCalled()
    } finally {
      delete (HTMLElement.prototype as unknown as { setPointerCapture?: unknown }).setPointerCapture
    }
  })

  it('button-pressable-018 pointerdown without an onPointerDown prop still sets data-pressed', () => {
    const { el } = setup()
    expect(() => fireEvent.pointerDown(el)).not.toThrow()
    expect(el).toHaveAttribute('data-pressed', '')
  })

  it('button-pressable-019 a second pointerdown keeps data-pressed set', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    expect(() => fireEvent.pointerDown(el)).not.toThrow()
    expect(el).toHaveAttribute('data-pressed', '')
  })

  it('button-pressable-020 pointercancel after a completed press leaves data-pressed absent', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    fireEvent.pointerUp(el)
    expect(() => fireEvent.pointerCancel(el)).not.toThrow()
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-021 window pointerup ends the press regardless of pointerId', () => {
    const { el } = setup()
    fireEvent.pointerDown(el, { pointerId: 1 })
    fireEvent.pointerDown(el, { pointerId: 2 })
    fireEvent.pointerUp(window, { pointerId: 1 })
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-022 pointerenter after a completed press leaves data-pressed absent', () => {
    const { el } = setup()
    fireEvent.pointerDown(el)
    fireEvent.pointerUp(el)
    fireEvent.pointerEnter(el)
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-023 invokes a forwarded onPointerUp exactly once, on pointerup', () => {
    const spy = vi.fn()
    const { el } = setup({ onPointerUp: spy })
    fireEvent.pointerDown(el)
    expect(spy).not.toHaveBeenCalled()
    fireEvent.pointerUp(el)
    expect(spy).toHaveBeenCalledTimes(1)
  })

  it('button-pressable-024 invokes a forwarded onPointerLeave exactly once and clears data-pressed', () => {
    const spy = vi.fn()
    const { el } = setup({ onPointerLeave: spy })
    fireEvent.pointerDown(el)
    expect(spy).not.toHaveBeenCalled()
    fireEvent.pointerLeave(el)
    expect(spy).toHaveBeenCalledTimes(1)
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-025 invokes a forwarded onPointerEnter exactly once and restores data-pressed', () => {
    const spy = vi.fn()
    const { el } = setup({ onPointerEnter: spy })
    fireEvent.pointerDown(el)
    fireEvent.pointerLeave(el)
    expect(spy).not.toHaveBeenCalled()
    fireEvent.pointerEnter(el)
    expect(spy).toHaveBeenCalledTimes(1)
    expect(el).toHaveAttribute('data-pressed', '')
  })

  it('button-pressable-026 invokes a forwarded onPointerCancel exactly once and clears data-pressed', () => {
    const spy = vi.fn()
    const { el } = setup({ onPointerCancel: spy })
    fireEvent.pointerDown(el)
    expect(spy).not.toHaveBeenCalled()
    fireEvent.pointerCancel(el)
    expect(spy).toHaveBeenCalledTimes(1)
    expect(el).not.toHaveAttribute('data-pressed')
  })

  it('button-pressable-027 forwarded onPointerDown and data-pressed both fire', () => {
    const spy = vi.fn()
    const { el } = setup({ onPointerDown: spy })
    fireEvent.pointerDown(el)
    expect(spy).toHaveBeenCalledTimes(1)
    expect(el).toHaveAttribute('data-pressed', '')
  })

  it('button-pressable-028 removes every window pointerup/pointercancel listener on unmount', () => {
    const add = vi.spyOn(window, 'addEventListener')
    const remove = vi.spyOn(window, 'removeEventListener')
    const { el, unmount } = setup()
    fireEvent.pointerDown(el)
    const added = add.mock.calls.filter(([t]) => t === 'pointerup' || t === 'pointercancel')
    expect(added.length).toBeGreaterThan(0)
    unmount()
    for (const [type, handler] of added) {
      expect(remove.mock.calls.some(([t, h]) => t === type && h === handler)).toBe(true)
    }
    const errors = vi.spyOn(console, 'error').mockImplementation(() => {})
    expect(() => fireEvent.pointerUp(window)).not.toThrow()
    expect(errors).not.toHaveBeenCalled()
  })
})
