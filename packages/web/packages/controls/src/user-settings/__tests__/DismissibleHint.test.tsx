import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, act } from '@testing-library/react'
import { DismissibleHint } from '../components/DismissibleHint'

const KEY = 'aws-hint-dismissed:test-hint'

describe('DismissibleHint', () => {
  beforeEach(() => {
    window.localStorage.clear()
  })
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('dismissible-hint-001 renders a note container with the children', () => {
    render(<DismissibleHint id="test-hint">Example hint text</DismissibleHint>)
    const note = screen.getByRole('note')
    expect(note.textContent).toContain('Example hint text')
    expect(screen.getByText('Example hint text')).toBeTruthy()
  })
  it('dismissible-hint-002 renders a labelled close button with the glyph', () => {
    render(<DismissibleHint id="test-hint">text</DismissibleHint>)
    const btn = screen.getByRole('button', { name: 'Dismiss' })
    expect(btn.getAttribute('aria-label')).toBe('Dismiss')
    expect(btn.textContent).toBe('×')
  })
  it('dismissible-hint-003 persists dismissal to localStorage', () => {
    render(<DismissibleHint id="test-hint">text</DismissibleHint>)
    fireEvent.click(screen.getByRole('button', { name: 'Dismiss' }))
    expect(window.localStorage.getItem(KEY)).toBe('1')
  })
  it('dismissible-hint-004 renders null when already dismissed', () => {
    window.localStorage.setItem(KEY, '1')
    const { container } = render(<DismissibleHint id="test-hint">text</DismissibleHint>)
    expect(container.innerHTML).toBe('')
  })
  it('dismissible-hint-005 removes the container immediately on click', () => {
    const { container } = render(<DismissibleHint id="test-hint">text</DismissibleHint>)
    fireEvent.click(screen.getByRole('button', { name: 'Dismiss' }))
    expect(screen.queryByRole('note')).toBeNull()
    expect(container.innerHTML).toBe('')
  })
  it('dismissible-hint-006 merges className with the base class', () => {
    render(<DismissibleHint id="test" className="custom-class">text</DismissibleHint>)
    const note = screen.getByRole('note')
    expect(note.classList.contains('aws-hint')).toBe(true)
    expect(note.classList.contains('custom-class')).toBe(true)
  })
  it('dismissible-hint-007 treats a storage read error as not dismissed', () => {
    const getItem = vi.spyOn(window.localStorage, 'getItem').mockImplementation(() => {
      throw new Error('denied')
    })
    render(<DismissibleHint id="test-hint">text</DismissibleHint>)
    expect(getItem).toHaveBeenCalled()
    expect(screen.getByRole('note')).toBeTruthy()
  })
  it('dismissible-hint-008 hides the hint when the storage write fails', () => {
    const setItem = vi.spyOn(window.localStorage, 'setItem').mockImplementation(() => {
      throw new Error('quota')
    })
    render(<DismissibleHint id="test-hint">text</DismissibleHint>)
    expect(() => fireEvent.click(screen.getByRole('button', { name: 'Dismiss' }))).not.toThrow()
    expect(setItem).toHaveBeenCalled()
    expect(screen.queryByRole('note')).toBeNull()
    expect(window.localStorage.getItem(KEY)).toBeNull()
  })
  it('dismissible-hint-009 container has role note', () => {
    const { container } = render(<DismissibleHint id="test-hint">text</DismissibleHint>)
    const div = container.firstElementChild as HTMLElement
    expect(div.tagName).toBe('DIV')
    expect(div.getAttribute('role')).toBe('note')
  })
  it('dismissible-hint-010 close control is a native button that activates like a click', () => {
    render(<DismissibleHint id="test-hint">text</DismissibleHint>)
    const btn = screen.getByRole('button', { name: 'Dismiss' }) as HTMLButtonElement
    expect(btn.tagName).toBe('BUTTON')
    expect(btn.type).toBe('button')
    // jsdom does not synthesize a click from Enter/Space; a native button's keyboard activation is a click.
    btn.focus()
    expect(document.activeElement).toBe(btn)
    act(() => btn.click())
    expect(screen.queryByRole('note')).toBeNull()
  })
})
