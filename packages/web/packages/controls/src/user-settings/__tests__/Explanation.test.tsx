import { describe, it, expect } from 'vitest'
import { render } from '@testing-library/react'
import { Explanation } from '../components/Explanation'

const root = (c: HTMLElement) => c.firstElementChild as HTMLElement

describe('Explanation', () => {
  it('explanation-001 renders a paragraph with the base class', () => {
    const { container } = render(<Explanation>Hello</Explanation>)
    expect(container.innerHTML).toBe('<p class="aws-explanation">Hello</p>')
  })
  it('explanation-002 contains the default class', () => {
    const { container } = render(<Explanation className="x">a</Explanation>)
    expect(root(container).classList.contains('aws-explanation')).toBe(true)
  })
  it('explanation-003 renders children inside the paragraph', () => {
    const { container } = render(<Explanation>Text content</Explanation>)
    expect(root(container).textContent).toBe('Text content')
  })
  it('explanation-004 has both classes with the default first', () => {
    const { container } = render(<Explanation className="custom-class">Text</Explanation>)
    expect(Array.from(root(container).classList)).toEqual(['aws-explanation', 'custom-class'])
  })
  it('explanation-005 combines class names', () => {
    const { container } = render(<Explanation className="extra">Content</Explanation>)
    expect(root(container).getAttribute('class')).toBe('aws-explanation extra')
  })
  it('explanation-006 filters an empty className', () => {
    const { container } = render(<Explanation className="">Text</Explanation>)
    expect(root(container).getAttribute('class')).toBe('aws-explanation')
  })
  it('explanation-007 renders JSX children', () => {
    const { container } = render(<Explanation><span>Rich</span> content</Explanation>)
    expect(root(container).innerHTML).toBe('<span>Rich</span> content')
  })
  it('explanation-008 renders empty with children omitted', () => {
    const { container } = render(<Explanation />)
    expect(container.innerHTML).toBe('<p class="aws-explanation"></p>')
  })
  it('explanation-009 renders empty for empty-string children', () => {
    const { container } = render(<Explanation>{''}</Explanation>)
    expect(container.innerHTML).toBe('<p class="aws-explanation"></p>')
  })
  it('explanation-010 filters an undefined className', () => {
    const { container } = render(<Explanation className={undefined}>Text</Explanation>)
    expect(root(container).getAttribute('class')).toBe('aws-explanation')
  })
  it('explanation-011 passes a whitespace-only className through unchanged', () => {
    const { container } = render(<Explanation className="   ">Text</Explanation>)
    expect(root(container).getAttribute('class')).toBe('aws-explanation    ')
  })
  it('explanation-012 preserves internal whitespace between classes', () => {
    const { container } = render(<Explanation className="class1 class2">Text</Explanation>)
    expect(root(container).getAttribute('class')).toBe('aws-explanation class1 class2')
  })
  it('explanation-013 renders empty for null children', () => {
    const { container } = render(<Explanation>{null}</Explanation>)
    expect(container.innerHTML).toBe('<p class="aws-explanation"></p>')
  })
  it('explanation-014 renders empty for an empty array of children', () => {
    const { container } = render(<Explanation>{[]}</Explanation>)
    expect(container.innerHTML).toBe('<p class="aws-explanation"></p>')
  })
})
