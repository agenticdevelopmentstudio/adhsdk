import { describe, expect, it, beforeEach, afterEach, vi } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { createRef } from 'react'
import { useInputFocusReclaim } from '../hooks/useInputFocusReclaim'
import { appendToBody } from './helpers/caretDom'

function mount(): { ref: { current: HTMLDivElement | null }; input: HTMLInputElement } {
  const wrapper = document.createElement('div')
  const input = document.createElement('input')
  input.className = 'pc-input'
  wrapper.appendChild(input)
  appendToBody(wrapper)
  const ref = createRef<HTMLDivElement>()
  Object.assign(ref, { current: wrapper })
  return { ref, input }
}

// Stubs window.getSelection() to report `text` as the current selection, so
// the pointerup handler's drag-to-select guard sees a non-empty selection. The
// stub only supplies toString(), so double-cast through unknown rather than
// pretending the object is a full Selection.
function stubSelection(text: string): void {
  vi.spyOn(window, 'getSelection').mockReturnValue({
    toString: () => text,
  } as unknown as Selection)
}

describe('useInputFocusReclaim', () => {
  beforeEach(() => {
    vi.spyOn(document, 'hasFocus').mockReturnValue(true)
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('claims focus when enabled', () => {
    const { ref, input } = mount()
    renderHook(() => useInputFocusReclaim(ref, true))
    expect(document.activeElement).toBe(input)
  })

  it('does not claim focus while disabled', () => {
    const { ref, input } = mount()
    renderHook(() => useInputFocusReclaim(ref, false))
    expect(document.activeElement).not.toBe(input)
  })

  it('does not claim focus on a disabled input', () => {
    const { ref, input } = mount()
    input.disabled = true
    renderHook(() => useInputFocusReclaim(ref, true))
    expect(document.activeElement).not.toBe(input)
  })

  // A settled click INSIDE the chat (dispatched on the wrapper) is the case
  // reclaim is for; `bubbles: true` carries it to the document-level listener.
  const clickInside = (ref: { current: HTMLDivElement | null }): void => {
    ref.current?.dispatchEvent(new Event('pointerup', { bubbles: true }))
  }

  it('does not reclaim focus synchronously at pointerup — only after the timer fires', () => {
    vi.useFakeTimers()
    const { ref, input } = mount()
    renderHook(() => useInputFocusReclaim(ref, true))
    input.blur()

    act(() => {
      clickInside(ref)
    })
    // setTimeout(refocus, 0) defers past the pointerup tick — not reclaimed yet
    expect(document.activeElement).not.toBe(input)

    act(() => {
      vi.advanceTimersByTime(0)
    })
    expect(document.activeElement).toBe(input)
  })

  it('does not reclaim focus for a click OUTSIDE the wrapper', () => {
    vi.useFakeTimers()
    const { ref, input } = mount()
    renderHook(() => useInputFocusReclaim(ref, true))
    input.blur()

    // A click on the page background (target outside the chat) is the user
    // leaving the composer — a collapsing chat must be allowed to blur, so the
    // reclaim bows out rather than pinning focus back.
    act(() => {
      document.dispatchEvent(new Event('pointerup'))
    })
    act(() => {
      vi.advanceTimersByTime(0)
    })
    expect(document.activeElement).not.toBe(input)
  })

  it('does not reclaim focus on pointerup while text is selected', () => {
    vi.useFakeTimers()
    const { ref, input } = mount()
    renderHook(() => useInputFocusReclaim(ref, true))
    input.blur()
    stubSelection('selected text')

    act(() => {
      clickInside(ref)
    })
    act(() => {
      vi.advanceTimersByTime(0)
    })
    expect(document.activeElement).not.toBe(input)
  })

  it('does not call focus() when document.hasFocus() is false', () => {
    vi.useFakeTimers()
    vi.spyOn(document, 'hasFocus').mockReturnValue(false)
    const { ref, input } = mount()
    const focusSpy = vi.spyOn(input, 'focus')
    renderHook(() => useInputFocusReclaim(ref, true))

    act(() => {
      clickInside(ref)
    })
    act(() => {
      vi.advanceTimersByTime(0)
    })
    expect(focusSpy).not.toHaveBeenCalled()
  })

  it('removes its pointerup listener on unmount', () => {
    vi.useFakeTimers()
    const { ref, input } = mount()
    const { unmount } = renderHook(() => useInputFocusReclaim(ref, true))
    input.blur()
    unmount()

    // With the listener removed, a settled click no longer reclaims focus.
    act(() => {
      clickInside(ref)
    })
    act(() => {
      vi.advanceTimersByTime(0)
    })
    expect(document.activeElement).not.toBe(input)
  })

  it('removes its window focus listener on unmount', () => {
    const { ref, input } = mount()
    const { unmount } = renderHook(() => useInputFocusReclaim(ref, true))
    input.blur()
    unmount()

    // The window-refocus reclaim is synchronous; after cleanup it must not fire.
    act(() => {
      window.dispatchEvent(new Event('focus'))
    })
    expect(document.activeElement).not.toBe(input)
  })

  it('chat-coordinator-hooks-073 focuses nothing and does not throw when no element matches the selector', () => {
    const { ref } = mount()
    const before = document.activeElement
    expect(() => {
      renderHook(() => useInputFocusReclaim(ref, true, '.no-such-input'))
    }).not.toThrow()
    expect(document.activeElement).toBe(before)
  })
})
