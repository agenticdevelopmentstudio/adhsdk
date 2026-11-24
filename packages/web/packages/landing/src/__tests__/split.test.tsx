// Split (landing/deck/split) — conformance vectors split-001..011.
// jsdom applies neither stylesheets nor media queries, so the layout vectors parse
// `css/base.css` for the `.lp-split` rules; real layout (RTL mirroring) is skipped.
import { describe, expect, it } from 'vitest'
import { render } from '@testing-library/react'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { Split } from '../deck/Split'

const css = readFileSync(resolve(__dirname, '../css/base.css'), 'utf8').replace(/\/\*[\s\S]*?\*\//g, '')

/** Body of the first `selector { ... }` rule in `source`. */
function ruleBody(source: string, selector: string): string | null {
  const esc = selector.replace(/[.*+?^${}()|[\]\\>]/g, '\\$&')
  const m = new RegExp(`(?:^|[}\\s])${esc}\\s*\\{([^}]*)\\}`).exec(source)
  return m ? m[1]! : null
}

/** Inside of the `@media (min-width: 62rem) { ... }` block that holds `.lp-split {`. */
function splitMedia(): string {
  const start = css.indexOf('@media (min-width: 62rem) {')
  expect(start).toBeGreaterThan(-1)
  const open = css.indexOf('{', start)
  let depth = 0
  for (let i = open; i < css.length; i++) {
    if (css[i] === '{') depth++
    if (css[i] === '}' && --depth === 0) return css.slice(open + 1, i)
  }
  throw new Error('unterminated media block')
}

// base.css with the 62rem block removed, leaving the single-column rules.
const topLevel = css.replace(splitMedia(), '')

describe('Split', () => {
  it('split-001 renders all children in the order given', () => {
    const { container } = render(<Split><p>Copy</p><p>Shot</p></Split>)
    const root = container.firstElementChild!
    expect(Array.from(root.children).map((c) => c.textContent)).toEqual(['Copy', 'Shot'])
  })

  it('split-002 root is a div with the lp-split class', () => {
    const { container } = render(<Split><p>x</p></Split>)
    const root = container.firstElementChild!
    expect(root.tagName).toBe('DIV')
    expect(root.classList.contains('lp-split')).toBe(true)
  })

  it('split-003 merges className after lp-split', () => {
    const { container } = render(<Split className="custom"><p>x</p></Split>)
    expect(container.firstElementChild!.getAttribute('class')).toBe('lp-split custom')
  })

  it('split-004 grid below the breakpoint, two 5fr/6fr columns at 62rem', () => {
    const base = ruleBody(topLevel, '.lp-split')!
    expect(base).toMatch(/display:\s*grid/)
    expect(base).toMatch(/gap:\s*2rem/)
    expect(base).not.toMatch(/grid-template-columns/)
    const wide = ruleBody(splitMedia(), '.lp-split')!
    expect(wide).toMatch(/grid-template-columns:\s*minmax\(0,\s*5fr\)\s+minmax\(0,\s*6fr\)/)
    expect(wide).toMatch(/gap:\s*3rem/)
  })

  it('split-005 no role and no visual reordering', () => {
    const { container } = render(<Split><p>a</p><p>b</p></Split>)
    expect(container.firstElementChild!.hasAttribute('role')).toBe(false)
    const rules = [ruleBody(topLevel, '.lp-split'), ruleBody(splitMedia(), '.lp-split'), ruleBody(splitMedia(), '.lp-split > *')]
    for (const r of rules) {
      expect(r).not.toBeNull()
      expect(r).not.toMatch(/\border\s*:/)
      expect(r).not.toMatch(/row-reverse/)
    }
  })

  it.skip('split-006 mirrors the columns under dir="rtl" (needs real layout, which jsdom does not compute)', () => {})

  it('split-007 undefined or empty className adds no token or whitespace', () => {
    const a = render(<Split><p>x</p></Split>)
    expect(a.container.firstElementChild!.getAttribute('class')).toBe('lp-split')
    const b = render(<Split className=""><p>x</p></Split>)
    expect(b.container.firstElementChild!.getAttribute('class')).toBe('lp-split')
  })

  it('split-008 renders an empty container with no children', () => {
    const { container } = render(<Split>{null}</Split>)
    const root = container.firstElementChild!
    expect(root.classList.contains('lp-split')).toBe(true)
    expect(root.childNodes.length).toBe(0)
  })

  it('split-009 renders a single child', () => {
    const { container } = render(<Split><p>Only</p></Split>)
    const root = container.firstElementChild!
    expect(root.children.length).toBe(1)
    expect(root.firstElementChild!.textContent).toBe('Only')
  })

  it('split-010 declares no max-width or width, with fr-based tracks', () => {
    for (const r of [ruleBody(topLevel, '.lp-split'), ruleBody(splitMedia(), '.lp-split')]) {
      expect(r).not.toMatch(/(^|[\s;])(max-)?width\s*:/)
    }
    expect(ruleBody(splitMedia(), '.lp-split')).toMatch(/\d+fr/)
  })

  it('split-011 no min-width, and columns are declared only inside the 62rem query', () => {
    for (const r of [ruleBody(topLevel, '.lp-split'), ruleBody(splitMedia(), '.lp-split')]) {
      expect(r).not.toMatch(/min-width\s*:/)
    }
    expect(ruleBody(topLevel, '.lp-split')).not.toMatch(/grid-template-columns/)
    expect(splitMedia()).toMatch(/grid-template-columns/)
  })
})
