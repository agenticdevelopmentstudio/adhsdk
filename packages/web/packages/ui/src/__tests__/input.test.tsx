/// <reference types="@testing-library/jest-dom/vitest" />
import { fireEvent, render, screen } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { Input, fieldShellClass } from '../components/input'

const OFF_ATTRS: Array<readonly [string, string]> = [
  ['autocomplete', 'off'],
  ['data-form-type', 'other'],
  ['data-1p-ignore', 'true'],
  ['data-lpignore', 'true'],
  ['data-bwignore', 'true'],
  ['data-protonpass-ignore', 'true'],
]

function field(): HTMLInputElement {
  return screen.getByTestId('f') as HTMLInputElement
}

describe('Input conformance vectors', () => {
  it('input-001 type="email" sets the type attribute', () => {
    render(<Input data-testid="f" type="email" />)
    expect(field()).toHaveAttribute('type', 'email')
  })

  it('input-002 type="password" sets the type attribute', () => {
    render(<Input data-testid="f" type="password" />)
    expect(field()).toHaveAttribute('type', 'password')
  })

  it('input-003 placeholder renders and is styled text-apt-text-dim', () => {
    render(<Input data-testid="f" placeholder="Enter name" />)
    expect(field()).toHaveAttribute('placeholder', 'Enter name')
    expect(field().className).toContain('placeholder:text-apt-text-dim')
  })

  it('input-004 a real autoComplete token passes through with no opt-out attributes', () => {
    render(<Input data-testid="f" autoComplete="email" />)
    expect(field()).toHaveAttribute('autocomplete', 'email')
    for (const [name] of OFF_ATTRS.slice(1)) expect(field()).not.toHaveAttribute(name)
  })

  it('input-005 autoComplete={undefined} applies the full opt-out set', () => {
    render(<Input data-testid="f" autoComplete={undefined} />)
    for (const [name, value] of OFF_ATTRS) expect(field()).toHaveAttribute(name, value)
  })

  it('input-006 selected text is tinted apt-gold/30', () => {
    render(<Input data-testid="f" />)
    expect(field().className).toContain('selection:bg-apt-gold/30')
  })

  it('input-007 value and onChange are forwarded to the native input', () => {
    const onChange = vi.fn()
    render(<Input data-testid="f" value="test" onChange={onChange} />)
    expect(field().value).toBe('test')
    fireEvent.change(field(), { target: { value: 'tests' } })
    expect(onChange).toHaveBeenCalledTimes(1)
  })

  it('input-008 field shell: rounded-lg, 1px border, apt-bg background', () => {
    render(<Input data-testid="f" />)
    for (const token of fieldShellClass.split(' ')) expect(field()).toHaveClass(token)
    expect(fieldShellClass).toContain('rounded-lg')
    expect(fieldShellClass).toContain('border-apt-border')
    expect(fieldShellClass).toContain('bg-apt-bg')
  })

  it('input-009 fills its container width without overflowing (w-full min-w-0)', () => {
    render(
      <div style={{ width: 200 }}>
        <Input data-testid="f" />
      </div>,
    )
    expect(field()).toHaveClass('w-full', 'min-w-0')
  })

  it('input-010 caller className merges with the defaults', () => {
    render(<Input data-testid="f" className="custom-class" />)
    expect(field()).toHaveClass('custom-class', 'h-9', 'w-full')
    expect(field().className).toContain(fieldShellClass)
  })

  it('input-011 focus: apt-gold border and 2px apt-gold/25 ring', () => {
    render(<Input data-testid="f" />)
    expect(field()).toHaveClass(
      'focus-visible:border-apt-gold',
      'focus-visible:ring-2',
      'focus-visible:ring-apt-gold/25',
    )
  })

  it('input-012 disabled: 50% opacity, not-allowed cursor, no pointer events', () => {
    render(<Input data-testid="f" disabled />)
    expect(field()).toBeDisabled()
    expect(field()).toHaveClass(
      'disabled:opacity-50',
      'disabled:cursor-not-allowed',
      'disabled:pointer-events-none',
    )
  })

  it('input-013 aria-invalid: apt-red border and 2px apt-red/25 ring', () => {
    render(<Input data-testid="f" aria-invalid="true" />)
    expect(field()).toHaveAttribute('aria-invalid', 'true')
    expect(field()).toHaveClass(
      'aria-invalid:border-apt-red',
      'aria-invalid:ring-2',
      'aria-invalid:ring-apt-red/25',
    )
  })

  it('input-014 autoComplete="off" applies the same opt-out set as input-005', () => {
    render(<Input data-testid="f" autoComplete="off" />)
    for (const [name, value] of OFF_ATTRS) expect(field()).toHaveAttribute(name, value)
  })

  it('input-015 disabled + invalid carries both treatments and pointer-events-none', () => {
    render(<Input data-testid="f" disabled aria-invalid="true" />)
    expect(field()).toBeDisabled()
    expect(field()).toHaveAttribute('aria-invalid', 'true')
    expect(field()).toHaveClass('disabled:pointer-events-none', 'aria-invalid:border-apt-red')
    // The focus ring is a focus-visible variant; a disabled control cannot take focus.
    field().focus()
    expect(document.activeElement).not.toBe(field())
  })

  it('input-016 placeholder color apt-text-dim differs from entered text color apt-text', () => {
    render(<Input data-testid="f" placeholder="Enter name" />)
    expect(field()).toHaveClass('text-apt-text', 'placeholder:text-apt-text-dim')
  })

  it('input-017 an external label names the input; the component renders no label', () => {
    const { container } = render(
      <>
        <label htmlFor="email">Email</label>
        <Input id="email" />
      </>,
    )
    expect(screen.getByLabelText('Email')).toBe(container.querySelector('input'))
    expect(container.querySelectorAll('label')).toHaveLength(1)
  })

  it('input-018 aria-invalid="true" is exposed to assistive technology', () => {
    render(<Input aria-label="Name" aria-invalid="true" />)
    expect(screen.getByRole('textbox', { name: 'Name' })).toBeInvalid()
  })
})
