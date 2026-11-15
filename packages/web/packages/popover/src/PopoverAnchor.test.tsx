import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { createPortal } from 'react-dom'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, fireEvent, render } from '@testing-library/react'
import { PopoverAnchor } from './PopoverAnchor'

afterEach(() => {
  cleanup()
  document.head.querySelectorAll('style[data-test-base-css]').forEach((n) => n.remove())
})

function anchorOf(container: HTMLElement): HTMLElement {
  return container.firstElementChild as HTMLElement
}

describe('PopoverAnchor', () => {
  it('anchor-001: renders its children as the anchor div direct children, in order, with no wrapping', () => {
    const { container } = render(
      <PopoverAnchor>
        <button>Trigger</button>
        <div>Panel</div>
      </PopoverAnchor>,
    )
    const anchor = anchorOf(container)
    expect(anchor.tagName).toBe('DIV')
    expect(Array.from(anchor.children).map((c) => c.tagName)).toEqual(['BUTTON', 'DIV'])
    expect(anchor.children[0].textContent).toBe('Trigger')
    expect(anchor.children[1].textContent).toBe('Panel')
  })

  it('anchor-002: base.css gives the anchor position: relative', () => {
    const style = document.createElement('style')
    style.setAttribute('data-test-base-css', '')
    style.textContent = readFileSync(join(__dirname, 'css/base.css'), 'utf8')
    document.head.appendChild(style)
    const { container } = render(<PopoverAnchor>x</PopoverAnchor>)
    expect(getComputedStyle(anchorOf(container)).position).toBe('relative')
  })

  it('anchor-003: concatenates className after hover-popover-anchor', () => {
    const { container } = render(<PopoverAnchor className="custom-class">x</PopoverAnchor>)
    expect(anchorOf(container).getAttribute('class')).toBe('hover-popover-anchor custom-class')
  })

  it('anchor-004: class is exactly hover-popover-anchor without className', () => {
    const { container } = render(<PopoverAnchor>x</PopoverAnchor>)
    expect(anchorOf(container).getAttribute('class')).toBe('hover-popover-anchor')
  })

  it('anchor-005: invokes onMouseLeave once when the pointer leaves the anchor', () => {
    const onMouseLeave = vi.fn()
    const { container } = render(<PopoverAnchor onMouseLeave={onMouseLeave}>x</PopoverAnchor>)
    fireEvent.mouseLeave(anchorOf(container))
    expect(onMouseLeave).toHaveBeenCalledTimes(1)
  })

  it('anchor-006: moving from trigger to panel sibling does not invoke onMouseLeave', () => {
    const onMouseLeave = vi.fn()
    const { getByText } = render(
      <PopoverAnchor onMouseLeave={onMouseLeave}>
        <button>Trigger</button>
        <div>Panel</div>
      </PopoverAnchor>,
    )
    const trigger = getByText('Trigger')
    const panel = getByText('Panel')
    fireEvent.mouseOver(trigger)
    fireEvent.mouseOut(trigger, { relatedTarget: panel })
    fireEvent.mouseOver(panel, { relatedTarget: trigger })
    expect(onMouseLeave).not.toHaveBeenCalled()
  })

  it('anchor-007: leaving without an onMouseLeave prop throws nothing and the anchor still renders', () => {
    const { container } = render(<PopoverAnchor>x</PopoverAnchor>)
    const anchor = anchorOf(container)
    expect(() => fireEvent.mouseLeave(anchor)).not.toThrow()
    expect(container.firstElementChild).toBe(anchor)
    expect(anchor.textContent).toBe('x')
  })

  it('anchor-008: two enter/leave cycles invoke onMouseLeave exactly twice', () => {
    const onMouseLeave = vi.fn()
    const { container } = render(<PopoverAnchor onMouseLeave={onMouseLeave}>x</PopoverAnchor>)
    const anchor = anchorOf(container)
    fireEvent.mouseEnter(anchor)
    fireEvent.mouseLeave(anchor)
    fireEvent.mouseEnter(anchor)
    fireEvent.mouseLeave(anchor)
    expect(onMouseLeave).toHaveBeenCalledTimes(2)
  })

  it.skip('anchor-009: a margin gap with no spanning element does not hit-test to the anchor (jsdom has no layout or hit-testing)', () => {})

  it('anchor-010: a portaled panel is not a DOM descendant of the anchor', () => {
    const { container, getByText } = render(
      <PopoverAnchor>
        <button>Trigger</button>
        {createPortal(<div>Panel</div>, document.body)}
      </PopoverAnchor>,
    )
    const anchor = anchorOf(container)
    const panel = getByText('Panel')
    expect(anchor.contains(panel)).toBe(false)
    expect(panel.parentElement).toBe(document.body)
  })

  it.skip('anchor-011: a bridging pseudo-element keeps every crossing point inside the anchor (jsdom has no layout, pseudo-elements or hit-testing)', () => {})
})
