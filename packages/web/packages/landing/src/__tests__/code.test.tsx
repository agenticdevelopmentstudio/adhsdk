import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { Code } from '../blocks/Code'

function pre(container: HTMLElement): HTMLPreElement {
  return container.querySelector('pre') as HTMLPreElement
}

describe('Code conformance vectors', () => {
  it('code-001 preserves newlines and leading spaces', () => {
    const { container } = render(<Code text={'line1\nline2\n  indented'} />)
    const lines = pre(container).textContent!.split('\n')
    expect(lines).toEqual(['line1', 'line2', '  indented'])
  })

  it.skip('code-002 computed white-space is pre (jsdom does not load the landing stylesheet)', () => {})

  it('code-003 renders the text prop without error', () => {
    const { container } = render(<Code text="$ echo hello" />)
    expect(pre(container).textContent).toBe('$ echo hello')
    expect(pre(container).className).toBe('lp-code')
    expect(pre(container).firstElementChild!.tagName).toBe('CODE')
  })

  it('code-004 does not interpret markdown or HTML', () => {
    const text = '# Heading\n**bold** <html>'
    const { container } = render(<Code text={text} />)
    expect(pre(container).textContent).toBe(text)
    expect(container.querySelector('strong, h1, html')).toBeNull()
    expect(pre(container).querySelector('code')!.children).toHaveLength(0)
  })

  it.skip('code-005 computed font-family from --lp-font-mono (jsdom does not load the landing stylesheet)', () => {})

  it.skip('code-006 empty-block padding and layout shift (needs real CSS layout)', () => {})

  it('code-006 (DOM shape) empty string renders an empty pre/code', () => {
    const { container } = render(<Code text="" />)
    expect(pre(container).innerHTML).toBe('<code></code>')
  })

  it('code-007 whitespace-only text is preserved exactly', () => {
    const text = '   \t\n  '
    const { container } = render(<Code text={text} />)
    expect(pre(container).textContent).toBe(text)
    expect(pre(container).textContent!.length).toBe(text.length)
    expect(pre(container).textContent!.split('\n')).toHaveLength(2)
  })

  it.skip('code-008 tab-size default rendering (needs real layout)', () => {})

  it('code-009 Unicode text renders unmodified', () => {
    const text = 'café 日本語 🎉'
    const { container } = render(<Code text={text} />)
    expect(pre(container).textContent).toBe(text)
  })

  it.skip('code-010 overflow-x auto and scrollWidth (needs real layout and the landing stylesheet)', () => {})
})
