/// <reference types="@testing-library/jest-dom/vitest" />
/** Conformance tests for the Checkbox wrapper (cookbook/checkbox, vectors checkbox-001..013, 017, 018, 021). */
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { Checkbox } from '../components/Checkbox'

describe('Checkbox wrapper conformance', () => {
  it('checkbox-001 value true sets the input checked property', () => {
    render(<Checkbox value={true} onChange={() => {}} />)
    expect((screen.getByRole('switch') as HTMLInputElement).checked).toBe(true)
  })

  it('checkbox-002 value false leaves the input unchecked', () => {
    render(<Checkbox value={false} onChange={() => {}} />)
    expect((screen.getByRole('switch') as HTMLInputElement).checked).toBe(false)
  })

  it('checkbox-003 clicking with value false calls onChange(true)', () => {
    const onChange = vi.fn()
    render(<Checkbox value={false} onChange={onChange} />)
    fireEvent.click(screen.getByRole('switch'))
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledWith(true)
  })

  it('checkbox-004 clicking with value true calls onChange(false)', () => {
    const onChange = vi.fn()
    render(<Checkbox value={true} onChange={onChange} />)
    fireEvent.click(screen.getByRole('switch'))
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledWith(false)
  })

  it('checkbox-005 appearance switch gives the input role=switch and the switch modifier class', () => {
    const { container } = render(<Checkbox appearance="switch" value={false} onChange={() => {}} />)
    expect(screen.getByRole('switch')).toHaveAttribute('role', 'switch')
    expect(container.firstElementChild).toHaveClass('aws-field--checkbox-switch')
  })

  it('checkbox-006 appearance check gives an implicit checkbox role and the check modifier class', () => {
    const { container } = render(<Checkbox appearance="check" value={false} onChange={() => {}} />)
    const input = screen.getByRole('checkbox')
    expect(input).not.toHaveAttribute('role')
    expect(container.firstElementChild).toHaveClass('aws-field--checkbox-check')
  })

  it('checkbox-007 defaults to the switch appearance', () => {
    const { container } = render(<Checkbox value={false} onChange={() => {}} />)
    expect(screen.getByRole('switch')).toBeInTheDocument()
    expect(container.firstElementChild).toHaveClass('aws-field--checkbox-switch')
  })

  it('checkbox-008 disabled input does not call onChange when clicked', () => {
    const onChange = vi.fn()
    render(<Checkbox disabled value={false} onChange={onChange} />)
    const input = screen.getByRole('switch')
    expect(input).toBeDisabled()
    // HTMLElement.click() honors `disabled` like a real click; fireEvent.click dispatches regardless.
    input.click()
    expect(onChange).not.toHaveBeenCalled()
  })

  it('checkbox-009 label renders adjacent to the input and is associated via htmlFor', () => {
    render(<Checkbox label="Agree to terms" value={false} onChange={() => {}} />)
    const label = screen.getByText('Agree to terms').closest('label') as HTMLLabelElement
    const input = screen.getByRole('switch')
    expect(label.htmlFor).toBe(input.id)
    expect(input.id).not.toBe('')
    expect(screen.getByLabelText('Agree to terms')).toBe(input)
  })

  it('checkbox-010 no label prop renders no label text', () => {
    const { container } = render(<Checkbox value={false} onChange={() => {}} />)
    expect(container.querySelector('.aws-checkbox__label')).toBeNull()
  })

  it('checkbox-011 hint renders in a paragraph', () => {
    render(<Checkbox hint="Required to proceed" value={false} onChange={() => {}} />)
    const hint = screen.getByText('Required to proceed')
    expect(hint.tagName).toBe('P')
  })

  it('checkbox-012 no hint prop renders no hint paragraph', () => {
    const { container } = render(<Checkbox value={false} onChange={() => {}} />)
    expect(container.querySelector('.aws-field__hint')).toBeNull()
    expect(container.querySelector('p')).toBeNull()
  })

  it('checkbox-013 clicking the label text toggles the input', () => {
    const onChange = vi.fn()
    render(<Checkbox label="Agree to terms" value={false} onChange={onChange} />)
    fireEvent.click(screen.getByText('Agree to terms'))
    expect(onChange).toHaveBeenCalledWith(true)
  })

  it('checkbox-017 className is appended to the wrapper root div', () => {
    const { container } = render(
      <Checkbox className="my-custom-class" value={false} onChange={() => {}} />,
    )
    const root = container.firstElementChild as HTMLElement
    expect(root.tagName).toBe('DIV')
    expect(root).toHaveClass('aws-field', 'aws-field--checkbox', 'my-custom-class')
    expect(root.className.endsWith('my-custom-class')).toBe(true)
  })

  it('checkbox-018 id is placed on the input and referenced by the label', () => {
    const { container } = render(
      <Checkbox id="my-checkbox" label="L" value={false} onChange={() => {}} />,
    )
    expect(screen.getByRole('switch')).toHaveAttribute('id', 'my-checkbox')
    expect(container.querySelector('label')).toHaveAttribute('for', 'my-checkbox')
  })

  it('checkbox-021 input aria-describedby references the hint element', () => {
    render(<Checkbox hint="Required to proceed" value={false} onChange={() => {}} />)
    const input = screen.getByRole('switch')
    const hint = screen.getByText('Required to proceed')
    expect(input.getAttribute('aria-describedby')).toBe(hint.id)
  })
})
