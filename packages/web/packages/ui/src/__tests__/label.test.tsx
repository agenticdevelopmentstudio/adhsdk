import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { Label } from '../components/label'

describe('Label', () => {
  it('label-001 renders a label element', () => {
    render(<Label>Name</Label>)
    const el = screen.getByText('Name')
    expect(el.tagName).toBe('LABEL')
    expect(el.getAttribute('data-slot')).toBe('label')
  })

  it('label-002 forwards htmlFor and id', () => {
    render(<Label htmlFor="input-id" id="label-1">Name</Label>)
    const el = screen.getByText('Name') as HTMLLabelElement
    expect(el.htmlFor).toBe('input-id')
    expect(el.getAttribute('for')).toBe('input-id')
    expect(el.id).toBe('label-1')
  })

  it.skip('label-003 default typography (computed style needs the compiled Tailwind stylesheet, absent in jsdom)', () => {})

  it('label-004 merges className with defaults', () => {
    render(<Label className="custom-class">Name</Label>)
    const cls = screen.getByText('Name').className
    expect(cls).toContain('custom-class')
    expect(cls).toContain('font-medium')
    expect(cls).toContain('select-none')
  })

  it.skip('label-005 peer-disabled style when disabled (computed opacity/cursor need compiled CSS, absent in jsdom)', () => {})
  it.skip('label-006 peer-disabled style when enabled (computed opacity/cursor need compiled CSS, absent in jsdom)', () => {})

  it('label-007 clicking the label toggles the associated checkbox', () => {
    render(
      <>
        <input type="checkbox" id="cb" />
        <Label htmlFor="cb">Accept</Label>
      </>,
    )
    const box = screen.getByRole('checkbox') as HTMLInputElement
    expect(box.checked).toBe(false)
    fireEvent.click(screen.getByText('Accept'))
    expect(box.checked).toBe(true)
  })

  it.skip('label-008 row layout (computed display/align-items/column-gap need compiled CSS, absent in jsdom)', () => {})
  it.skip('label-009 default text color (computed color needs the resolved token stylesheet, absent in jsdom)', () => {})
})
