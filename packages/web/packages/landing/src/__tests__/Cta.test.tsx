import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render } from '@testing-library/react'
import { Cta } from '../index'

const BLOCKS_CSS = readFileSync(join(__dirname, '..', 'css', 'blocks.css'), 'utf8')

describe('Cta conformance vectors', () => {
  it('cta-001 renders a child button inside the container', () => {
    const { container } = render(<Cta><button>Sign Up</button></Cta>)
    expect(container.querySelector('.lp-cta')!.innerHTML).toBe('<button>Sign Up</button>')
  })

  it('cta-002 renders several children in order', () => {
    const { container } = render(
      <Cta>
        <button>One</button>
        <a href="#two">Two</a>
        <button>Three</button>
      </Cta>
    )
    const kids = Array.from(container.querySelector('.lp-cta')!.children)
    expect(kids.map((k) => k.textContent)).toEqual(['One', 'Two', 'Three'])
    expect(kids.map((k) => k.tagName)).toEqual(['BUTTON', 'A', 'BUTTON'])
  })

  it('cta-003 renders an empty container for null, undefined or no children', () => {
    for (const ui of [<Cta>{null}</Cta>, <Cta>{undefined}</Cta>, <Cta>{[]}</Cta>]) {
      const { container, unmount } = render(ui)
      expect(container.innerHTML).toBe('<div class="lp-cta"></div>')
      unmount()
    }
    // The zero-size claim rests on `.lp-cta` declaring no padding or margin.
    const rule = /\.lp-cta\s*\{([^}]*)\}/.exec(BLOCKS_CSS)![1]
    expect(rule).not.toMatch(/padding|margin/)
  })

  it('cta-004 gives the container exactly the lp-cta class', () => {
    const { container } = render(<Cta><button>Go</button></Cta>)
    expect(container.firstElementChild!.getAttribute('class')).toBe('lp-cta')
  })

  it('cta-005 leaves a child onClick handler working', () => {
    const onClick = vi.fn()
    const { getByText } = render(<Cta><button onClick={onClick}>Go</button></Cta>)
    fireEvent.click(getByText('Go'))
    expect(onClick).toHaveBeenCalledTimes(1)
  })

  it('cta-007 passes child props through unchanged', () => {
    const { getByTestId } = render(
      <Cta><button aria-label="Download it" data-testid="dl" className="mine">Go</button></Cta>
    )
    const btn = getByTestId('dl')
    expect(btn.getAttribute('aria-label')).toBe('Download it')
    expect(btn.className).toBe('mine')
  })

  it('cta-008 the stylesheet makes the container a wrapping, centered row', () => {
    const style = document.createElement('style')
    style.textContent = BLOCKS_CSS
    document.head.appendChild(style)
    try {
      const { container } = render(<Cta><button>A</button><button>B</button></Cta>)
      const cs = getComputedStyle(container.firstElementChild!)
      expect(cs.display).toBe('flex')
      expect(cs.flexWrap).toBe('wrap')
      expect(cs.justifyContent).toBe('center')
      expect(['', 'row']).toContain(cs.flexDirection)
    } finally {
      style.remove()
    }
  })

  it.skip('cta-008 children wider than the container wrap onto a second row (jsdom does no layout)', () => {})
})
