import { describe, expect, it } from 'vitest'
import { render } from '@testing-library/react'
import { Btn } from '../blocks/Btn'

function anchor(ui: React.ReactElement): HTMLElement {
  return render(ui).container.firstElementChild as HTMLElement
}

describe('Btn conformance vectors', () => {
  it('btn-001 renders an anchor element', () => {
    expect(anchor(<Btn href="/path">Click</Btn>).tagName).toBe('A')
  })

  it('btn-002 passes href to the anchor', () => {
    expect(anchor(<Btn href="/signup">Go</Btn>).getAttribute('href')).toBe('/signup')
  })

  it('btn-003 renders children as the link text', () => {
    expect(anchor(<Btn href="/x">Sign up now</Btn>).textContent).toBe('Sign up now')
  })

  it('btn-004 ghost variant gives exactly "lp-btn lp-btn--ghost"', () => {
    expect(anchor(<Btn href="/x" variant="ghost">Go</Btn>).className).toBe('lp-btn lp-btn--ghost')
  })

  it('btn-005 defaults to the primary variant', () => {
    expect(anchor(<Btn href="/x">Go</Btn>).className).toBe('lp-btn lp-btn--primary')
  })

  it('btn-006 always carries lp-btn', () => {
    expect(anchor(<Btn href="/x">Go</Btn>).classList.contains('lp-btn')).toBe(true)
    expect(anchor(<Btn href="/x" variant="ghost">Go</Btn>).classList.contains('lp-btn')).toBe(true)
  })

  it('btn-007 explicit primary gives exactly "lp-btn lp-btn--primary"', () => {
    expect(anchor(<Btn href="/x" variant="primary">Go</Btn>).className).toBe('lp-btn lp-btn--primary')
  })

  it('btn-008 an unsupported variant is used verbatim, with no fallback', () => {
    const a = anchor(<Btn href="/x" variant={'invalid' as any}>Go</Btn>)
    expect(a.className).toBe('lp-btn lp-btn--invalid')
    expect(a.className).not.toContain('primary')
  })

  it('btn-009 an unrelated prop is not forwarded', () => {
    const props = { href: '/x', target: '_blank' } as any
    const a = anchor(<Btn {...props}>Go</Btn>)
    expect(a.hasAttribute('target')).toBe(false)
    expect(a.getAttributeNames().sort()).toEqual(['class', 'href'])
  })

  it('btn-010 empty children leave an empty anchor in place', () => {
    const a = anchor(<Btn href="/x">{''}</Btn>)
    expect(a.tagName).toBe('A')
    expect(a.textContent).toBe('')
    expect(a.getAttribute('href')).toBe('/x')
  })

  it('btn-011 an undefined href leaves the attribute absent', () => {
    const a = anchor(<Btn href={undefined as any}>Go</Btn>)
    expect(a.tagName).toBe('A')
    expect(a.hasAttribute('href')).toBe(false)
  })
})
