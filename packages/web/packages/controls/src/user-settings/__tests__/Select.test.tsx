import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { Select } from '../components/Select'

const AB = [
  { value: 'a', label: 'A' },
  { value: 'b', label: 'B' },
]

describe('Select conformance vectors', () => {
  it('select-001 renders a native select element', () => {
    const { container } = render(<Select value="a" onChange={() => {}} choices={[{ value: 'a', label: 'A' }]} />)
    expect(container.querySelector('select')).toBeInTheDocument()
    expect(screen.getByRole('combobox').tagName).toBe('SELECT')
  })

  it('select-002 invokes onChange with the selected value', () => {
    const onChange = vi.fn()
    render(<Select label="Pick" value="a" onChange={onChange} choices={AB} />)
    fireEvent.change(screen.getByLabelText('Pick'), { target: { value: 'b' } })
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledWith('b')
  })

  it('select-003 reflects the value prop as the selected option', () => {
    render(
      <Select
        value="option2"
        onChange={() => {}}
        choices={[
          { value: 'option1', label: 'One' },
          { value: 'option2', label: 'Two' },
          { value: 'option3', label: 'Three' },
        ]}
      />,
    )
    expect((screen.getByRole('combobox') as HTMLSelectElement).value).toBe('option2')
    expect((screen.getByRole('option', { name: 'Two' }) as HTMLOptionElement).selected).toBe(true)
  })

  it('select-004 renders one option per choice', () => {
    const { container } = render(<Select value="a" onChange={() => {}} choices={AB} />)
    expect(container.querySelectorAll('option')).toHaveLength(2)
  })

  it('select-005 option displays the choice label', () => {
    render(<Select value="x" onChange={() => {}} choices={[{ value: 'x', label: 'Choose Me' }]} />)
    expect(screen.getByRole('option', { name: 'Choose Me' }).textContent).toBe('Choose Me')
  })

  it('select-006 a disabled choice renders a disabled option', () => {
    render(
      <Select
        value="a"
        onChange={() => {}}
        choices={[
          { value: 'a', label: 'A' },
          { value: 'b', label: 'B', disabled: true },
        ]}
      />,
    )
    expect(screen.getByRole('option', { name: 'B' })).toBeDisabled()
    expect(screen.getByRole('option', { name: 'A' })).not.toBeDisabled()
  })

  it('select-007 disabled prop disables the select', () => {
    render(<Select value="a" onChange={() => {}} choices={AB} disabled />)
    expect(screen.getByRole('combobox')).toBeDisabled()
  })

  it('select-008 generates a stable non-empty id matched by the label htmlFor', () => {
    const { rerender } = render(<Select label="L" value="a" onChange={() => {}} choices={AB} />)
    const id = screen.getByRole('combobox').id
    expect(id).not.toBe('')
    expect(screen.getByText('L').getAttribute('for')).toBe(id)
    rerender(<Select label="L" value="b" onChange={() => {}} choices={AB} />)
    expect(screen.getByRole('combobox').id).toBe(id)
  })

  it('select-008 generated ids are unique across instances', () => {
    render(
      <>
        <Select value="a" onChange={() => {}} choices={AB} />
        <Select value="a" onChange={() => {}} choices={AB} />
      </>,
    )
    const [first, second] = screen.getAllByRole('combobox')
    expect(first.id).not.toBe(second.id)
  })

  it('select-009 uses the provided id for the select and the label', () => {
    render(<Select id="my-select" label="L" value="a" onChange={() => {}} choices={AB} />)
    expect(screen.getByRole('combobox').id).toBe('my-select')
    expect(screen.getByText('L').getAttribute('for')).toBe('my-select')
  })

  it('select-010 renders a label associated with the select', () => {
    const { container } = render(<Select label="Choose an option" value="a" onChange={() => {}} choices={AB} />)
    const label = container.querySelector('label') as HTMLLabelElement
    expect(label.textContent).toBe('Choose an option')
    expect(label.htmlFor).toBe(screen.getByRole('combobox').id)
    expect(screen.getByLabelText('Choose an option')).toBe(screen.getByRole('combobox'))
  })

  it('select-011 applies className to the wrapper div', () => {
    const { container } = render(<Select className="custom-class" value="a" onChange={() => {}} choices={AB} />)
    const wrapper = container.firstElementChild as HTMLElement
    expect(wrapper.tagName).toBe('DIV')
    expect(wrapper.classList.contains('custom-class')).toBe(true)
    expect(screen.getByRole('combobox').classList.contains('custom-class')).toBe(false)
  })

  it('select-012 renders the hint in a p after the select', () => {
    const { container } = render(<Select hint="Select one item" value="a" onChange={() => {}} choices={AB} />)
    const p = container.querySelector('p') as HTMLElement
    expect(p.textContent).toBe('Select one item')
    expect(screen.getByRole('combobox').nextElementSibling).toBe(p)
  })

  // The chevron belongs to the styled-select primitive (ui select.tsx); see ui/__tests__/select.test.tsx.
  it.skip('select-013 chevron indicator (covered by the ui primitive test; the aws-field Select draws none)', () => {})

  it.skip('select-014 focus style (jsdom does not evaluate :focus-visible or the .aws-select:focus CSS rule)', () => {})

  it('select-015 renders no label element without a label prop', () => {
    const { container } = render(<Select value="a" onChange={() => {}} choices={AB} />)
    expect(container.querySelector('label')).toBeNull()
    expect(screen.getByRole('combobox')).not.toHaveAccessibleName()
  })

  it('select-016 renders no options for an empty choices array', () => {
    const { container } = render(<Select value="" onChange={() => {}} choices={[]} />)
    expect(container.querySelectorAll('option')).toHaveLength(0)
    expect((screen.getByRole('combobox') as HTMLSelectElement).options).toHaveLength(0)
  })

  it('select-017 hint is a sibling and the select aria-describedby references the hint id', () => {
    const { container } = render(<Select hint="Select one item" value="a" onChange={() => {}} choices={AB} />)
    const p = container.querySelector('p') as HTMLElement
    expect(p.id).not.toBe('')
    expect(screen.getByRole('combobox').getAttribute('aria-describedby')).toBe(p.id)
  })

  it.skip('select-018 a disabled option cannot be selected by keyboard or pointer (native browser behavior; jsdom does not enforce it)', () => {})
})
