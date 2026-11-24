import { describe, it, expect, afterEach } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { render, cleanup } from '@testing-library/react'
import { ViewportComposer } from '../ViewportComposer'

const baseCss = readFileSync(resolve(__dirname, '../css/base.css'), 'utf8')
const composerSource = readFileSync(resolve(__dirname, '../ViewportComposer.tsx'), 'utf8')

/** The declaration block of `.vp-composer { ... }` from base.css. */
function composerRule(): string {
  const m = baseCss.match(/\.vp-composer\s*\{([^}]*)\}/)
  if (!m) throw new Error('.vp-composer rule not found in base.css')
  return m[1]
}

function declaration(block: string, prop: string): string | undefined {
  const m = block.match(new RegExp(`(?:^|;|\\s)${prop}\\s*:\\s*([^;]+);`))
  return m?.[1].trim()
}

afterEach(() => {
  cleanup()
  document.head.querySelectorAll('style').forEach((s) => s.remove())
})

const root = (container: HTMLElement): HTMLElement => container.firstElementChild as HTMLElement

describe('ViewportComposer', () => {
  it('vp-composer-001: renders children directly with no wrapper', () => {
    const { container } = render(
      <ViewportComposer>
        <button>Send</button>
      </ViewportComposer>,
    )
    expect(root(container).children.length).toBe(1)
    expect(root(container).firstElementChild?.tagName).toBe('BUTTON')
  })

  it('vp-composer-002: className is composed after vp-composer', () => {
    const { container } = render(<ViewportComposer className="custom-class">Text</ViewportComposer>)
    expect(root(container).getAttribute('class')).toBe('vp-composer custom-class')
  })

  it('vp-composer-003: no className leaves only vp-composer', () => {
    const { container } = render(<ViewportComposer>Text</ViewportComposer>)
    expect(root(container).getAttribute('class')).toBe('vp-composer')
  })

  it('vp-composer-004: .vp-composer padding-bottom is calc(var(--kb-inset) + var(--safe-bottom))', () => {
    expect(declaration(composerRule(), 'padding-bottom')).toBe('calc(var(--kb-inset) + var(--safe-bottom))')
  })

  it('vp-composer-007: .vp-composer transition includes padding-bottom 180ms ease-out', () => {
    expect(declaration(composerRule(), 'transition')).toContain('padding-bottom 180ms ease-out')
  })

  it.skip('vp-composer-005: needs a real browser (Playwright) to measure computed padding and layout shift', () => {})

  it('vp-composer-006: the source never uses useKeyboardInset and no inline style touches --kb-inset', () => {
    expect(composerSource).not.toMatch(/useKeyboardInset/)
    const { container } = render(<ViewportComposer>Text</ViewportComposer>)
    expect(root(container).getAttribute('style') ?? '').not.toContain('--kb-inset')
  })

  it('vp-composer-008: with no children an empty div.vp-composer renders', () => {
    const props = {} as { children: never }
    const { container } = render(<ViewportComposer {...props} />)
    const el = root(container)
    expect(el.tagName).toBe('DIV')
    expect(el.classList.contains('vp-composer')).toBe(true)
    expect(el.childNodes.length).toBe(0)
    expect(declaration(composerRule(), 'padding-bottom')).toBeDefined()
  })

  it('vp-composer-009: a multi-class className is composed whole', () => {
    const { container } = render(<ViewportComposer className="a b">Text</ViewportComposer>)
    expect(root(container).getAttribute('class')).toBe('vp-composer a b')
  })

  it('vp-composer-010: without base.css no padding-bottom or transition rule applies', () => {
    const { container } = render(<ViewportComposer>Text</ViewportComposer>)
    const cs = getComputedStyle(root(container))
    expect(['', '0', '0px']).toContain(cs.paddingBottom)
    expect(cs.transitionProperty).not.toBe('padding-bottom')
  })
})
