import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it } from 'vitest'
import { render } from '@testing-library/react'
import type { ReactElement } from 'react'
import { Lede } from '../index'

const CSS_DIR = join(__dirname, '..', 'css')
const lede = (ui: ReactElement): Element => render(ui).container.firstElementChild!

describe('Lede conformance vectors', () => {
  it('lede-001 renders as a p element', () => {
    expect(lede(<Lede>Text</Lede>).tagName).toBe('P')
  })

  it('lede-002 renders its children as the paragraph text', () => {
    expect(lede(<Lede>Hello World</Lede>).textContent).toBe('Hello World')
  })

  it('lede-003 carries the lp-lede class', () => {
    expect(lede(<Lede>Text</Lede>).classList.contains('lp-lede')).toBe(true)
  })

  it('lede-004 carries lp-lede and the extra class', () => {
    const el = lede(<Lede className="extra">Text</Lede>)
    expect(el.classList.contains('lp-lede')).toBe(true)
    expect(el.classList.contains('extra')).toBe(true)
  })

  it('lede-005 an undefined className leaves only lp-lede', () => {
    expect(lede(<Lede className={undefined}>Text</Lede>).getAttribute('class')).toBe('lp-lede')
  })

  it('lede-006 an empty className leaves only lp-lede', () => {
    expect(lede(<Lede className="">Text</Lede>).getAttribute('class')).toBe('lp-lede')
  })

  it('lede-007 a whitespace-only className is not filtered and leaves two trailing spaces', () => {
    expect(lede(<Lede className=" ">Text</Lede>).getAttribute('class')).toBe('lp-lede  ')
  })

  it('lede-008 the .lp-lede rule declares max-width: 72ch', () => {
    const css = readFileSync(join(CSS_DIR, 'blocks.css'), 'utf8')
    const rule = /(?:^|\n)\.lp-lede\s*\{([^}]*)\}/.exec(css)![1]
    expect(rule).toMatch(/max-width:\s*72ch\s*;/)
  })

  it('lede-009 renders an empty paragraph for empty children', () => {
    const { container } = render(<Lede>{null}</Lede>)
    expect(container.innerHTML).toBe('<p class="lp-lede"></p>')
  })

  it('lede-010 joins multiple extra classes after lp-lede', () => {
    expect(lede(<Lede className="a b">Text</Lede>).getAttribute('class')).toBe('lp-lede a b')
  })

  it('lede-011 the fallback ink on the fallback ground meets 4.5:1', () => {
    const color = /\.lp-lede\s*\{[^}]*color:\s*var\(--lp-ink-dim,\s*(#[0-9a-f]{6})\)/.exec(
      readFileSync(join(CSS_DIR, 'blocks.css'), 'utf8')
    )![1]
    const ground = /background:\s*var\(--lp-ground,\s*(#[0-9a-f]{6})\)/.exec(
      readFileSync(join(CSS_DIR, 'base.css'), 'utf8')
    )![1]
    const lum = (hex: string): number => {
      const [r, g, b] = [1, 3, 5].map((i) => {
        const c = parseInt(hex.slice(i, i + 2), 16) / 255
        return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4
      })
      return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    const [hi, lo] = [lum(color), lum(ground)].sort((a, b) => b - a)
    expect((hi + 0.05) / (lo + 0.05)).toBeGreaterThanOrEqual(4.5)
  })
})
