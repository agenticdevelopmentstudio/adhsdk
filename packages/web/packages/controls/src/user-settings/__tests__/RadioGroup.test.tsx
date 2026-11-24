import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, act } from '@testing-library/react'
import { RadioGroup } from '../components/RadioGroup'

const AB = [
  { value: 'a', label: 'A' },
  { value: 'b', label: 'B' },
]
const noop = () => {}
const inputs = (c: HTMLElement) => Array.from(c.querySelectorAll<HTMLInputElement>('input[type="radio"]'))

describe('RadioGroup', () => {
  it('radio-group-001 renders each choice as a radio', () => {
    const { container } = render(<RadioGroup value="a" onChange={noop} choices={AB} />)
    expect(inputs(container)).toHaveLength(2)
  })
  it('radio-group-002 checks the choice equal to value', () => {
    const { container } = render(<RadioGroup value="b" onChange={noop} choices={AB} />)
    expect(inputs(container).map((i) => i.checked)).toEqual([false, true])
  })
  it('radio-group-003 calls onChange with the clicked value', () => {
    const onChange = vi.fn()
    const choices = [...AB, { value: 'c', label: 'C' }]
    render(<RadioGroup value="a" onChange={onChange} choices={choices} />)
    fireEvent.click(screen.getByLabelText('C'))
    expect(onChange).toHaveBeenCalledWith('c')
  })
  it('radio-group-004 root is a fieldset', () => {
    const { container } = render(<RadioGroup value="a" onChange={noop} choices={AB} />)
    expect(container.firstElementChild?.tagName).toBe('FIELDSET')
  })
  it('radio-group-005 renders the label in a legend', () => {
    const { container } = render(<RadioGroup label="Group Label" value="a" onChange={noop} choices={AB} />)
    const legend = container.querySelector('legend')
    expect(legend?.textContent).toBe('Group Label')
    expect(container.firstElementChild?.firstElementChild).toBe(legend)
  })
  it('radio-group-006 container has role radiogroup', () => {
    render(<RadioGroup value="a" onChange={noop} choices={AB} />)
    expect(screen.getByRole('radiogroup')).toBeTruthy()
  })
  it('radio-group-007 choice label is associated with its input', () => {
    render(<RadioGroup value="a" onChange={noop} choices={[{ value: 'a', label: 'Option A' }]} />)
    expect(screen.getByLabelText('Option A').getAttribute('type')).toBe('radio')
  })
  it('radio-group-008 renders the choice hint', () => {
    const { container } = render(
      <RadioGroup value="a" onChange={noop} choices={[{ value: 'a', label: 'A', hint: 'Hint text' }]} />,
    )
    expect(container.querySelector('.aws-radio__hint')?.textContent).toBe('Hint text')
    expect(container.querySelector('label')?.textContent).toContain('Hint text')
  })
  it('radio-group-009 renders the field hint after the choices', () => {
    const { container } = render(<RadioGroup hint="Field guidance" value="a" onChange={noop} choices={AB} />)
    const hint = container.querySelector('p.aws-field__hint')
    expect(hint?.textContent).toBe('Field guidance')
    expect(container.querySelector('.aws-radio-group')?.nextElementSibling).toBe(hint)
  })
  it('radio-group-010 disabled disables the fieldset and every input', () => {
    const { container } = render(<RadioGroup disabled value="a" onChange={noop} choices={AB} />)
    expect(container.querySelector('fieldset')?.hasAttribute('disabled')).toBe(true)
    for (const i of inputs(container)) expect(i.matches(':disabled')).toBe(true)
  })
  it('radio-group-011 disables only the flagged choice', () => {
    const choices = [{ value: 'a', label: 'A' }, { value: 'b', label: 'B', disabled: true }]
    const { container } = render(<RadioGroup value="a" onChange={noop} choices={choices} />)
    const [a, b] = inputs(container)
    expect(a.disabled).toBe(false)
    expect(b.hasAttribute('disabled')).toBe(true)
  })
  it('radio-group-012 applies className to the fieldset', () => {
    const { container } = render(<RadioGroup className="custom-class" value="a" onChange={noop} choices={AB} />)
    expect(container.querySelector('fieldset')?.classList.contains('custom-class')).toBe(true)
  })
  it('radio-group-013 generates a unique shared name per instance', () => {
    const { container } = render(
      <>
        <RadioGroup value="a" onChange={noop} choices={AB} />
        <RadioGroup value="a" onChange={noop} choices={AB} />
      </>,
    )
    const [a1, a2, b1, b2] = inputs(container)
    expect(a1.name).not.toBe('')
    expect(a1.name).toBe(a2.name)
    expect(b1.name).toBe(b2.name)
    expect(a1.name).not.toBe(b1.name)
  })
  it('radio-group-014 uses the provided name', () => {
    const { container } = render(<RadioGroup name="my-group" value="a" onChange={noop} choices={AB} />)
    for (const i of inputs(container)) expect(i.getAttribute('name')).toBe('my-group')
  })
  it('radio-group-015 empty choices render the group with no radios', () => {
    const { container } = render(<RadioGroup value="a" onChange={noop} choices={[]} />)
    expect(container.querySelector('fieldset')).toBeTruthy()
    expect(container.querySelector('div[role="radiogroup"]')).toBeTruthy()
    expect(inputs(container)).toHaveLength(0)
  })
  it('radio-group-016 no legend without a label', () => {
    const { container } = render(<RadioGroup value="a" onChange={noop} choices={AB} />)
    expect(container.querySelector('legend')).toBeNull()
  })
  it('radio-group-017 no field hint without a hint', () => {
    const { container } = render(<RadioGroup value="a" onChange={noop} choices={AB} />)
    expect(container.querySelector('.aws-field__hint')).toBeNull()
  })
  it('radio-group-018 no choice hint when the choice has none', () => {
    const { container } = render(<RadioGroup value="a" onChange={noop} choices={AB} />)
    expect(container.querySelector('.aws-radio__hint')).toBeNull()
  })
  it('radio-group-019 nothing checked when value matches no choice', () => {
    const { container } = render(<RadioGroup value="z" onChange={noop} choices={AB} />)
    expect(inputs(container).some((i) => i.checked)).toBe(false)
  })
  it('radio-group-020 disabled group never calls onChange', () => {
    const onChange = vi.fn()
    render(<RadioGroup disabled value="a" onChange={onChange} choices={AB} />)
    act(() => screen.getByLabelText<HTMLInputElement>('B').click())
    expect(onChange).not.toHaveBeenCalled()
  })
  it('radio-group-021 stays checked when choices is replaced and still contains the value', () => {
    const { container, rerender } = render(<RadioGroup value="b" onChange={noop} choices={AB} />)
    rerender(<RadioGroup value="b" onChange={noop} choices={[...AB]} />)
    expect(inputs(container).map((i) => i.checked)).toEqual([false, true])
  })
  it('radio-group-022 nothing checked when the new choices drop the value', () => {
    const { container, rerender } = render(<RadioGroup value="b" onChange={noop} choices={AB} />)
    rerender(<RadioGroup value="b" onChange={noop} choices={[{ value: 'a', label: 'A' }]} />)
    expect(inputs(container).some((i) => i.checked)).toBe(false)
  })
  it('radio-group-023 empty label and hint render no legend or field hint', () => {
    const { container } = render(<RadioGroup label="" hint="" value="a" onChange={noop} choices={AB} />)
    expect(container.querySelector('legend')).toBeNull()
    expect(container.querySelector('.aws-field__hint')).toBeNull()
  })
  it('radio-group-024 label 0 renders a legend with text 0', () => {
    const { container } = render(<RadioGroup label={0} value="a" onChange={noop} choices={AB} />)
    expect(container.querySelector('legend')?.textContent).toBe('0')
  })
  it('radio-group-025 matches the css class hook structure', () => {
    const { container } = render(
      <RadioGroup
        label="L"
        hint="F"
        className="x"
        value="a"
        onChange={noop}
        choices={[{ value: 'a', label: 'A', hint: 'H' }]}
      />,
    )
    const fs = container.firstElementChild as HTMLElement
    expect(fs.tagName).toBe('FIELDSET')
    expect(fs.className).toBe('aws-field aws-field--radio x')
    const [legend, group, p] = Array.from(fs.children) as HTMLElement[]
    expect(legend.tagName).toBe('LEGEND')
    expect(legend.className).toBe('aws-field__label')
    expect(group.tagName).toBe('DIV')
    expect(group.className).toBe('aws-radio-group')
    expect(group.getAttribute('role')).toBe('radiogroup')
    const label = group.firstElementChild as HTMLElement
    expect(label.tagName).toBe('LABEL')
    expect(label.className).toBe('aws-radio')
    expect(Array.from(label.children).map((c) => `${c.tagName}.${c.className}`)).toEqual([
      'INPUT.aws-radio__input',
      'SPAN.aws-radio__indicator',
      'SPAN.aws-radio__label',
      'SPAN.aws-radio__hint',
    ])
    expect(p.tagName).toBe('P')
    expect(p.className).toBe('aws-field__hint')
  })
  it('radio-group-026 matching uses strict equality', () => {
    const choices = [{ value: 1, label: 'One' }]
    const { container } = render(
      <RadioGroup value={'1' as unknown as number} onChange={noop} choices={choices} />,
    )
    expect(inputs(container)[0].checked).toBe(false)
  })
})
