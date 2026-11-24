import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { Group } from '../components/Group'

const root = (c: HTMLElement) => c.firstElementChild as HTMLElement

describe('Group', () => {
  it('group-001 root is a section with the base class', () => {
    const { container } = render(<Group />)
    expect(root(container).tagName).toBe('SECTION')
    expect(root(container).classList.contains('aws-group')).toBe(true)
  })
  it('group-002 renders the title as an h3', () => {
    const { container } = render(<Group title="My Title" />)
    expect(container.querySelector('h3.aws-group__title')?.textContent).toBe('My Title')
  })
  it('group-003 renders no h3 without a title', () => {
    const { container } = render(<Group />)
    expect(container.querySelector('h3')).toBeNull()
  })
  it('group-004 renders the hint paragraph', () => {
    const { container } = render(<Group hint="Descriptive text" />)
    expect(container.querySelector('p.aws-group__hint')?.textContent).toBe('Descriptive text')
  })
  it('group-005 renders no hint without a hint prop', () => {
    const { container } = render(<Group />)
    expect(container.querySelector('p.aws-group__hint')).toBeNull()
  })
  it('group-006 renders children in the body div', () => {
    const { container } = render(<Group>Content</Group>)
    expect(container.querySelector('div.aws-group__body')?.textContent).toBe('Content')
  })
  it('group-007 accepts a custom className', () => {
    const { container } = render(<Group className="custom-class" />)
    expect(Array.from(root(container).classList)).toEqual(['aws-group', 'custom-class'])
  })
  it('group-008 filters an empty className', () => {
    const { container } = render(<Group className="" />)
    expect(root(container).getAttribute('class')).toBe('aws-group')
  })
  it('group-009 renders h3, p, div in order', () => {
    const { container } = render(<Group title="Title" hint="Hint">Body</Group>)
    const tags = Array.from(root(container).children).map((e) => e.tagName)
    expect(tags).toEqual(['H3', 'P', 'DIV'])
  })
  it('group-010 preserves multiple custom classes', () => {
    const { container } = render(<Group className="foo bar" />)
    expect(root(container).getAttribute('class')).toBe('aws-group foo bar')
  })
  it('group-011 filters a null className', () => {
    const { container } = render(<Group className={null as unknown as string} />)
    expect(root(container).getAttribute('class')).toBe('aws-group')
  })
  it('group-012 renders an empty body without children', () => {
    const { container } = render(<Group />)
    const body = container.querySelector('div.aws-group__body')
    expect(body).not.toBeNull()
    expect(body?.innerHTML).toBe('')
  })
  it('group-013 hint={0} renders no hint and no stray 0', () => {
    const { container } = render(<Group hint={0 as unknown as string} />)
    expect(container.querySelector('p.aws-group__hint')).toBeNull()
    expect(root(container).textContent).not.toContain('0')
  })
  it('group-014 title={0} renders no h3 and no stray 0', () => {
    const { container } = render(<Group title={0 as unknown as string} />)
    expect(container.querySelector('h3')).toBeNull()
    expect(root(container).textContent).not.toContain('0')
  })
})
