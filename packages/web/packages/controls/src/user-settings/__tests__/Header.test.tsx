import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { Header } from '../components/Header'

function h2(container: HTMLElement): HTMLElement {
  return container.querySelector('h2') as HTMLElement
}

describe('Header conformance vectors', () => {
  it('header-001 renders an h2 element', () => {
    const { container } = render(<Header>Test</Header>)
    expect(h2(container)).not.toBeNull()
    expect(h2(container).textContent).toBe('Test')
  })

  it('header-002 default class is aws-header', () => {
    const { container } = render(<Header>Test</Header>)
    expect(h2(container).classList.contains('aws-header')).toBe(true)
  })

  it('header-003 composes className with the default class', () => {
    const { container } = render(<Header className="custom">Test</Header>)
    expect(h2(container).classList.contains('aws-header')).toBe(true)
    expect(h2(container).classList.contains('custom')).toBe(true)
  })

  it('header-004 renders child elements', () => {
    const { container } = render(<Header><span>Child</span></Header>)
    const span = h2(container).querySelector('span')
    expect(span).not.toBeNull()
    expect(span!.textContent).toBe('Child')
  })

  it('header-005 undefined className is filtered out', () => {
    const { container } = render(<Header className={undefined}>Test</Header>)
    expect(h2(container).getAttribute('class')).toBe('aws-header')
  })

  it('header-006 empty className is filtered out', () => {
    const { container } = render(<Header className="">Test</Header>)
    expect(h2(container).getAttribute('class')).toBe('aws-header')
  })

  it('header-007 multiple classes pass through', () => {
    const { container } = render(<Header className="class1 class2">Test</Header>)
    expect(Array.from(h2(container).classList)).toEqual(['aws-header', 'class1', 'class2'])
  })

  it('header-008 null children render an empty h2 without error', () => {
    const { container } = render(<Header>{null}</Header>)
    expect(h2(container).getAttribute('class')).toBe('aws-header')
    expect(h2(container).childNodes.length).toBe(0)
  })

  it('header-009 className is passed through unsanitized', () => {
    const { container } = render(<Header className="a_b-c:d">Test</Header>)
    expect(h2(container).getAttribute('class')).toBe('aws-header a_b-c:d')
  })
})
