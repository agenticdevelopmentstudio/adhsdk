import { describe, it, expect, afterEach } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { render, cleanup } from '@testing-library/react'
import { ViewportSpacer } from '../ViewportSpacer'

const baseCss = readFileSync(resolve(__dirname, '../css/base.css'), 'utf8')

afterEach(() => {
  cleanup()
  document.head.querySelectorAll('style').forEach((s) => s.remove())
})

const root = (container: HTMLElement): HTMLElement => container.firstElementChild as HTMLElement

describe('ViewportSpacer', () => {
  it('viewport-spacer-001: renders its children', () => {
    const { container } = render(
      <ViewportSpacer>
        <p>Content</p>
      </ViewportSpacer>,
    )
    expect(root(container).querySelector('p')?.textContent).toBe('Content')
  })

  it('viewport-spacer-002: root is a div with class vp-spacer by default', () => {
    const { container } = render(<ViewportSpacer />)
    expect(root(container).tagName).toBe('DIV')
    expect(root(container).getAttribute('class')).toBe('vp-spacer')
  })

  it('viewport-spacer-003: className is appended after vp-spacer', () => {
    const { container } = render(<ViewportSpacer className="my-custom" />)
    expect(root(container).getAttribute('class')).toBe('vp-spacer my-custom')
  })

  it('viewport-spacer-004: a multi-class className is appended whole', () => {
    const { container } = render(<ViewportSpacer className="custom-a custom-b" />)
    expect(root(container).getAttribute('class')).toBe('vp-spacer custom-a custom-b')
  })

  it('viewport-spacer-005: null or omitted children render an empty div', () => {
    const a = render(<ViewportSpacer>{null}</ViewportSpacer>)
    expect(root(a.container).childNodes.length).toBe(0)
    expect(root(a.container).className).toBe('vp-spacer')
    const b = render(<ViewportSpacer />)
    expect(root(b.container).childNodes.length).toBe(0)
  })

  it('viewport-spacer-006: an empty className adds no trailing space', () => {
    const { container } = render(<ViewportSpacer className="" />)
    expect(root(container).getAttribute('class')).toBe('vp-spacer')
  })

  it('viewport-spacer-007: a fragment of two children renders both', () => {
    const { container } = render(
      <ViewportSpacer>
        <>
          <p>A</p>
          <span>B</span>
        </>
      </ViewportSpacer>,
    )
    expect(root(container).querySelector('p')?.textContent).toBe('A')
    expect(root(container).querySelector('span')?.textContent).toBe('B')
  })

  it('viewport-spacer-008: .vp-spacer sets flex: 1 1 0 and min-height: 0', () => {
    // jsdom does not expand the flex shorthand in computed style, so read the rule itself.
    const m = baseCss.match(/\.vp-spacer\s*\{([^}]*)\}/)
    expect(m).not.toBeNull()
    const block = m![1]
    expect(block).toMatch(/flex:\s*1 1 0\s*;/)
    expect(block).toMatch(/min-height:\s*0\s*;/)
  })

  it('viewport-spacer-009: root carries no role, accessible label or tabindex', () => {
    const { container } = render(<ViewportSpacer />)
    const el = root(container)
    for (const attr of ['role', 'aria-label', 'aria-labelledby', 'tabindex']) {
      expect(el.hasAttribute(attr)).toBe(false)
    }
  })
})
