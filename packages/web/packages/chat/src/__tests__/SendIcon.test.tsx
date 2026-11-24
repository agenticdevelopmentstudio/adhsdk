import { afterEach, describe, expect, it } from 'vitest'
import { cleanup, render } from '@testing-library/react'
import { SendIcon } from '../components/SendIcon'

afterEach(cleanup)

const svg = (c: HTMLElement) => c.querySelector('svg') as SVGSVGElement

describe('SendIcon conformance vectors', () => {
  it('send-icon-001 renders an svg with a line and a polygon', () => {
    const { container } = render(<SendIcon />)
    expect(svg(container)).not.toBeNull()
    expect(svg(container).querySelectorAll('line').length).toBe(1)
    expect(svg(container).querySelectorAll('polygon').length).toBe(1)
  })

  it('send-icon-002 the svg strokes with currentColor', () => {
    const { container } = render(<SendIcon />)
    expect(svg(container).getAttribute('stroke')).toBe('currentColor')
  })

  it('send-icon-003 width and height are hardcoded to 20', () => {
    const { container } = render(
      <div style={{ width: 40, height: 40 }}>
        <SendIcon />
      </div>,
    )
    expect(svg(container).getAttribute('width')).toBe('20')
    expect(svg(container).getAttribute('height')).toBe('20')
  })

  it('send-icon-004 the svg is static: no handlers, tabindex or pointer-events override', () => {
    const { container } = render(<SendIcon />)
    const attrs = Array.from(svg(container).attributes).map((a) => a.name)
    expect(attrs.filter((n) => n.startsWith('on'))).toEqual([])
    expect(attrs).not.toContain('tabindex')
    expect(attrs).not.toContain('pointer-events')
    expect(svg(container).style.pointerEvents).toBe('')
  })

  it('send-icon-005 viewBox is 0 0 24 24 rendered into a 20x20 box', () => {
    const { container } = render(<SendIcon />)
    expect(svg(container).getAttribute('viewBox')).toBe('0 0 24 24')
    expect(svg(container).getAttribute('width')).toBe('20')
    expect(svg(container).getAttribute('height')).toBe('20')
  })

  it('send-icon-006 aria-hidden true and focusable false are present, no role', () => {
    const { container } = render(<SendIcon />)
    expect(svg(container).getAttribute('aria-hidden')).toBe('true')
    expect(svg(container).getAttribute('focusable')).toBe('false')
    expect(svg(container).hasAttribute('role')).toBe(false)
  })
})
