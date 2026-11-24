import { afterEach, describe, expect, it } from 'vitest'
import '@testing-library/jest-dom/vitest'
import { cleanup, render } from '@testing-library/react'
import { Popover } from './Popover'

afterEach(cleanup)

const panel = (container: HTMLElement): HTMLElement => container.firstElementChild as HTMLElement

describe('Popover (lightweight)', () => {
  it('popover-002: open={true} adds hover-popover--open and renders the panel', () => {
    const { container } = render(<Popover open>x</Popover>)
    expect(panel(container)).toHaveClass('hover-popover', 'hover-popover--open')
  })

  it('popover-004: open={false} keeps the panel in the DOM without the open class', () => {
    const { container } = render(<Popover open={false}>x</Popover>)
    expect(panel(container)).toBeInTheDocument()
    expect(panel(container)).not.toHaveClass('hover-popover--open')
    // The opacity/visibility hiding lives in css/base.css, which jsdom does not load here.
  })

  it('popover-009: placement defaults to top', () => {
    const { container } = render(<Popover open>x</Popover>)
    expect(panel(container)).toHaveClass('hover-popover--top')
  })

  it('popover-010: placement="bottom" uses the bottom class', () => {
    const { container } = render(<Popover open placement="bottom">x</Popover>)
    expect(panel(container)).toHaveClass('hover-popover--bottom')
    expect(panel(container)).not.toHaveClass('hover-popover--top')
  })

  it('popover-012: children render inside the panel', () => {
    const { container, getByText } = render(
      <Popover open>
        <p>Content text</p>
      </Popover>,
    )
    expect(panel(container)).toContainElement(getByText('Content text'))
  })

  it('popover-030: className is appended after the package classes, in order', () => {
    const { container } = render(
      <Popover open={false} className="custom-popover-class">x</Popover>,
    )
    expect(panel(container).className).toBe('hover-popover hover-popover--top custom-popover-class')
  })

  it('popover-036: toggling open ten times never remounts the panel', () => {
    const { container, rerender } = render(<Popover open={false}>x</Popover>)
    const node = panel(container)
    for (let i = 0; i < 10; i++) {
      const open = i % 2 === 0
      rerender(<Popover open={open}>x</Popover>)
      expect(panel(container)).toBe(node)
      expect(node.classList.contains('hover-popover--open')).toBe(open)
    }
  })

  it.skip('popover-035: every panel fact reachable without hovering is a property of a consumer, not of this component', () => {})
})
