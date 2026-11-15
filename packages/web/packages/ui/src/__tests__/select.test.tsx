import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { Select } from '../components/select'

describe('Select (styled primitive) conformance vectors', () => {
  it('select-001 renders a native select with native option children', () => {
    render(
      <Select aria-label="Pick" defaultValue="a">
        <option value="a">A</option>
      </Select>,
    )
    expect(screen.getByRole('combobox', { name: 'Pick' }).tagName).toBe('SELECT')
  })

  it('select-007 disabled prop disables the select', () => {
    render(
      <Select aria-label="Pick" disabled>
        <option value="a">A</option>
      </Select>,
    )
    expect(screen.getByRole('combobox')).toBeDisabled()
  })

  it('select-011 className lands on the select, not the fixed relative wrapper', () => {
    const { container } = render(
      <Select aria-label="Pick" className="custom-class">
        <option value="a">A</option>
      </Select>,
    )
    const wrapper = container.firstElementChild as HTMLElement
    expect(wrapper.className).toBe('relative')
    expect(screen.getByRole('combobox').classList.contains('custom-class')).toBe(true)
  })

  it('select-013 shows a decorative chevron svg after the select inside the wrapper', () => {
    const { container } = render(
      <Select aria-label="Pick">
        <option value="a">A</option>
      </Select>,
    )
    const select = screen.getByRole('combobox')
    const chevron = select.nextElementSibling as SVGElement
    expect(chevron.tagName.toLowerCase()).toBe('svg')
    expect(container.firstElementChild).toContainElement(chevron)
    expect(chevron.getAttribute('class')).toContain('pointer-events-none')
    expect(chevron.getAttribute('class')).toContain('right-3')
  })

  it.skip('select-014 focus style (jsdom does not evaluate :focus-visible; the Tailwind focus-visible classes need a real browser)', () => {})
})
