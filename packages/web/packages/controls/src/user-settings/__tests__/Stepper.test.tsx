import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { Stepper } from '../components/Stepper'

const input = () => screen.getByRole('spinbutton') as HTMLInputElement
const inc = () => screen.getByRole('button', { name: 'Increment' })
const dec = () => screen.getByRole('button', { name: 'Decrement' })

describe('Stepper conformance vectors', () => {
  it('stepper-001 displays the numeric value', () => {
    render(<Stepper value={5} onChange={() => {}} />)
    expect(input().value).toBe('5')
  })

  it('stepper-002 increment calls onChange with 6', () => {
    const onChange = vi.fn()
    render(<Stepper value={5} step={1} onChange={onChange} />)
    fireEvent.click(inc())
    expect(onChange).toHaveBeenCalledWith(6)
  })

  it('stepper-003 decrement calls onChange with 4', () => {
    const onChange = vi.fn()
    render(<Stepper value={5} step={1} onChange={onChange} />)
    fireEvent.click(dec())
    expect(onChange).toHaveBeenCalledWith(4)
  })

  it('stepper-004 typing 15 clamps to max 10', () => {
    const onChange = vi.fn()
    render(<Stepper value={5} min={0} max={10} onChange={onChange} />)
    fireEvent.change(input(), { target: { value: '15' } })
    expect(onChange).toHaveBeenCalledWith(10)
  })

  it('stepper-005 typing -5 clamps to min 0', () => {
    const onChange = vi.fn()
    render(<Stepper value={5} min={0} max={10} onChange={onChange} />)
    fireEvent.change(input(), { target: { value: '-5' } })
    expect(onChange).toHaveBeenCalledWith(0)
  })

  it('stepper-006 increment by step 5 gives 5', () => {
    const onChange = vi.fn()
    render(<Stepper value={0} step={5} max={20} onChange={onChange} />)
    fireEvent.click(inc())
    expect(onChange).toHaveBeenCalledWith(5)
  })

  it('stepper-007 decrement by step 3 gives 7', () => {
    const onChange = vi.fn()
    render(<Stepper value={10} step={3} min={0} onChange={onChange} />)
    fireEvent.click(dec())
    expect(onChange).toHaveBeenCalledWith(7)
  })

  it('stepper-008 decrement disabled at min', () => {
    render(<Stepper value={0} min={0} onChange={() => {}} />)
    expect(dec()).toBeDisabled()
  })

  it('stepper-009 increment disabled at max', () => {
    render(<Stepper value={10} max={10} onChange={() => {}} />)
    expect(inc()).toBeDisabled()
  })

  it('stepper-010 disabled disables input and both buttons', () => {
    render(<Stepper value={5} disabled onChange={() => {}} />)
    expect(input()).toBeDisabled()
    expect(dec()).toBeDisabled()
    expect(inc()).toBeDisabled()
  })

  it('stepper-011 typing 42 calls onChange with 42', () => {
    const onChange = vi.fn()
    render(<Stepper value={5} min={0} max={100} onChange={onChange} />)
    fireEvent.change(input(), { target: { value: '42' } })
    expect(onChange).toHaveBeenCalledWith(42)
  })

  it('stepper-012 typing abc reports empty value and calls onChange with clamp(0)', () => {
    const onChange = vi.fn()
    render(<Stepper value={7} min={-5} max={10} onChange={onChange} />)
    fireEvent.change(input(), { target: { value: 'abc' } })
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledWith(0)
  })

  it('stepper-013 label is rendered and associated with the input', () => {
    render(<Stepper label="Quantity" value={5} onChange={() => {}} />)
    expect(screen.getByText('Quantity').tagName).toBe('LABEL')
    expect(screen.getByLabelText('Quantity')).toBe(input())
  })

  it('stepper-014 hint is displayed below the stepper', () => {
    const { container } = render(
      <Stepper hint="Enter a value between 1 and 10" value={5} onChange={() => {}} />,
    )
    const hint = screen.getByText('Enter a value between 1 and 10')
    expect(hint).toBeInTheDocument()
    const stepper = container.querySelector('.aws-stepper')!
    expect(stepper.nextElementSibling).toBe(hint)
  })

  it('stepper-015 className is applied to the wrapper', () => {
    const { container } = render(<Stepper className="my-stepper" value={5} onChange={() => {}} />)
    expect(container.firstElementChild).toHaveClass('my-stepper')
    expect(container.firstElementChild).toHaveClass('aws-field--stepper')
  })

  it('stepper-016 id is on the input and the label htmlFor', () => {
    render(<Stepper id="order-qty" label="Qty" value={5} onChange={() => {}} />)
    expect(input().id).toBe('order-qty')
    expect(screen.getByText('Qty')).toHaveAttribute('for', 'order-qty')
  })

  it('stepper-017 typing 25 clamps to max 20', () => {
    const onChange = vi.fn()
    render(<Stepper value={5} max={20} onChange={onChange} />)
    fireEvent.change(input(), { target: { value: '25' } })
    expect(onChange).toHaveBeenCalledWith(20)
  })

  it.skip('stepper-018 ArrowUp steps the value (native spin behavior; jsdom does not implement it)', () => {})

  it('stepper-019 increment 0.2 by 0.1 is raw floating-point addition', () => {
    const onChange = vi.fn()
    render(<Stepper value={0.2} step={0.1} onChange={onChange} />)
    fireEvent.click(inc())
    expect(onChange).toHaveBeenCalledWith(0.30000000000000004)
  })

  it('stepper-020 clearing the input clamps 0 to min 5', () => {
    const onChange = vi.fn()
    render(<Stepper value={7} min={5} onChange={onChange} />)
    fireEvent.change(input(), { target: { value: '' } })
    expect(onChange).toHaveBeenCalledWith(5)
  })

  it('stepper-021 first keystroke 5 with min 10 clamps to 10 immediately', () => {
    const onChange = vi.fn()
    render(<Stepper value={10} min={10} onChange={onChange} />)
    fireEvent.change(input(), { target: { value: '5' } })
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange).toHaveBeenCalledWith(10)
  })
})
