import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { Divider } from '../components/Divider'

describe('Divider', () => {
  it('divider-001 renders an <hr>', () => {
    const { container } = render(<Divider />)
    expect(container.firstElementChild?.tagName).toBe('HR')
  })
  it('divider-002 has the base class', () => {
    const { container } = render(<Divider />)
    expect(container.firstElementChild?.classList.contains('aws-divider')).toBe(true)
  })
  it('divider-003 appends an extra className', () => {
    const { container } = render(<Divider className="custom-style" />)
    expect(container.firstElementChild?.getAttribute('class')).toBe('aws-divider custom-style')
  })
  it('divider-004 filters undefined and empty className', () => {
    const a = render(<Divider className={undefined} />)
    expect(a.container.firstElementChild?.getAttribute('class')).toBe('aws-divider')
    const b = render(<Divider className="" />)
    expect(b.container.firstElementChild?.getAttribute('class')).toBe('aws-divider')
  })
  it('divider-005 whitespace-only className yields only the base class token', () => {
    const { container } = render(<Divider className="   " />)
    expect(Array.from(container.firstElementChild!.classList)).toEqual(['aws-divider'])
  })
  it('divider-006 exposes the implicit separator role', () => {
    render(<Divider />)
    expect(screen.getByRole('separator')).toBeTruthy()
  })
})
