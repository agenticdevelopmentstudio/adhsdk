/** Conformance tests for CopyButton (recipe ui/components/actions/copy-button).
 *  One `it` per conformance vector, titled with the vector id (T1..T13). */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, fireEvent, act } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { CopyButton } from '../components/copy-button'

let writeText: ReturnType<typeof vi.fn>

beforeEach(() => {
  vi.useFakeTimers()
  writeText = vi.fn().mockResolvedValue(undefined)
  Object.defineProperty(navigator, 'clipboard', { value: { writeText }, configurable: true })
})
afterEach(() => {
  vi.useRealTimers()
  vi.restoreAllMocks()
})

const click = async (el: HTMLElement) => {
  await act(async () => {
    fireEvent.click(el)
  })
}
const glyph = (el: HTMLElement) => el.querySelector('svg')!

describe('CopyButton conformance', () => {
  it('T1 copies getText() on click; accessible name is the label', async () => {
    render(<CopyButton getText={() => 'rows'} label="Copy rows" />)
    const el = screen.getByRole('button', { name: 'Copy rows' })
    await click(el)
    expect(writeText).toHaveBeenCalledWith('rows')
  })

  it('T2 flashes Copied! title and the Check glyph after success', async () => {
    render(<CopyButton getText={() => 'rows'} label="Copy rows" />)
    const el = screen.getByRole('button')
    await click(el)
    expect(el).toHaveAttribute('title', 'Copied!')
    expect(glyph(el)).toHaveClass('lucide-check')
  })

  it('T3 empty text is not copied and no success flash', async () => {
    render(<CopyButton getText={() => ''} label="Copy rows" />)
    const el = screen.getByRole('button')
    await click(el)
    expect(writeText).not.toHaveBeenCalled()
    expect(el).toHaveAttribute('title', 'Copy rows')
    expect(glyph(el)).toHaveClass('lucide-copy')
  })

  it('T4 reverts to label and Copy glyph after 1200 ms', async () => {
    render(<CopyButton getText={() => 'rows'} label="Copy rows" />)
    const el = screen.getByRole('button')
    await click(el)
    act(() => {
      vi.advanceTimersByTime(1200)
    })
    expect(el).toHaveAttribute('title', 'Copy rows')
    expect(glyph(el)).toHaveClass('lucide-copy')
  })

  it('T5 a rejected writeText leaves no success state and throws nothing', async () => {
    writeText.mockRejectedValue(new Error('denied'))
    render(<CopyButton getText={() => 'rows'} label="Copy rows" />)
    const el = screen.getByRole('button')
    await expect(click(el)).resolves.toBeUndefined()
    expect(el).toHaveAttribute('title', 'Copy rows')
    expect(glyph(el)).toHaveClass('lucide-copy')
  })

  it('T6 getText is read at click time, not render time', async () => {
    let value = 'at-render'
    render(<CopyButton getText={() => value} label="Copy" />)
    value = 'at-click'
    await click(screen.getByRole('button'))
    expect(writeText).toHaveBeenCalledWith('at-click')
  })

  it('T7 glyph is aria-hidden and the accessible name is the label', () => {
    render(<CopyButton getText={() => 'x'} label="Copy" />)
    const el = screen.getByRole('button', { name: 'Copy' })
    expect(glyph(el)).toHaveAttribute('aria-hidden', 'true')
  })

  it('T8 forwards className', () => {
    render(<CopyButton getText={() => 'x'} label="Copy" className="ml-2" />)
    expect(screen.getByRole('button')).toHaveClass('ml-2')
  })

  it('T9 a second successful click re-arms the revert timer', async () => {
    render(<CopyButton getText={() => 'rows'} label="Copy rows" />)
    const el = screen.getByRole('button')
    await click(el)
    act(() => {
      vi.advanceTimersByTime(1000)
    })
    await click(el)
    act(() => {
      vi.advanceTimersByTime(1199)
    })
    expect(el).toHaveAttribute('title', 'Copied!')
    act(() => {
      vi.advanceTimersByTime(1)
    })
    expect(el).toHaveAttribute('title', 'Copy rows')
  })

  it('T10 unmounting before the timer fires clears it; no update after unmount', async () => {
    const errors = vi.spyOn(console, 'error').mockImplementation(() => {})
    const { unmount } = render(<CopyButton getText={() => 'rows'} label="Copy rows" />)
    await click(screen.getByRole('button'))
    expect(vi.getTimerCount()).toBe(1)
    unmount()
    expect(vi.getTimerCount()).toBe(0)
    act(() => {
      vi.advanceTimersByTime(2000)
    })
    expect(errors).not.toHaveBeenCalled()
  })

  it('T11 consumer size-8 wins over default size-6', () => {
    render(<CopyButton getText={() => 'x'} label="Copy" className="size-8" />)
    const el = screen.getByRole('button')
    expect(el).toHaveClass('size-8')
    expect(el).not.toHaveClass('size-6')
  })

  it('T12 onCopied is called once after a successful copy', async () => {
    const onCopied = vi.fn()
    render(<CopyButton getText={() => 'rows'} label="Copy rows" onCopied={onCopied} />)
    await click(screen.getByRole('button'))
    expect(onCopied).toHaveBeenCalledTimes(1)
  })

  it('T13 onCopied is not called when the write rejects or there is nothing to copy', async () => {
    const onCopied = vi.fn()
    writeText.mockRejectedValue(new Error('denied'))
    const { unmount } = render(<CopyButton getText={() => 'rows'} label="Copy rows" onCopied={onCopied} />)
    await click(screen.getByRole('button'))
    unmount()
    render(<CopyButton getText={() => ''} label="Copy rows" onCopied={onCopied} />)
    await click(screen.getByRole('button'))
    expect(onCopied).not.toHaveBeenCalled()
  })
})
