import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { Slider } from '../components/Slider'

function input(container: HTMLElement): HTMLInputElement {
  return container.querySelector('input') as HTMLInputElement
}

describe('Slider', () => {
  it('slider-001: renders a range input with value, min, max and step', () => {
    const { container } = render(
      <Slider value={50} onChange={() => {}} min={0} max={100} step={1} />,
    )
    const el = input(container)
    expect(el).toHaveAttribute('type', 'range')
    expect(el).toHaveAttribute('value', '50')
    expect(el).toHaveAttribute('min', '0')
    expect(el).toHaveAttribute('max', '100')
    expect(el).toHaveAttribute('step', '1')
  })

  it('slider-002: reflects the controlled value', () => {
    const { container } = render(<Slider value={75} onChange={() => {}} />)
    expect(input(container).value).toBe('75')
  })

  it('slider-003: onChange is called with 60', () => {
    const onChange = vi.fn()
    const { container } = render(<Slider value={5} onChange={onChange} />)
    fireEvent.change(input(container), { target: { value: '60' } })
    expect(onChange).toHaveBeenCalledWith(60)
  })

  it('slider-003a: onChange receives a number', () => {
    const onChange = vi.fn()
    const { container } = render(<Slider value={5} onChange={onChange} />)
    fireEvent.change(input(container), { target: { value: '60' } })
    expect(typeof onChange.mock.calls[0][0]).toBe('number')
  })

  it('slider-004: label is associated with the input', () => {
    const { container } = render(<Slider label="Volume" value={5} onChange={() => {}} />)
    const label = container.querySelector('label') as HTMLLabelElement
    expect(label.textContent).toBe('Volume')
    expect(label.getAttribute('for')).toBe(input(container).id)
    expect(label.getAttribute('for')).toBeTruthy()
  })

  it('slider-005: hint renders as the last child of the wrapper', () => {
    const { container } = render(
      <Slider label="V" hint="Adjust volume from 0–100" value={5} onChange={() => {}} />,
    )
    const wrapper = container.firstElementChild as HTMLElement
    const last = wrapper.lastElementChild as HTMLElement
    expect(last.tagName).toBe('P')
    expect(last).toHaveClass('aws-field__hint')
    expect(last.textContent).toBe('Adjust volume from 0–100')
  })

  it('slider-006: static caption renders in the caption span', () => {
    const { container } = render(<Slider caption="Volume: 50" value={50} onChange={() => {}} />)
    const cap = container.querySelector('span.aws-slider__caption')
    expect(cap?.textContent).toBe('Volume: 50')
  })

  it('slider-007: function caption is called with the current value', () => {
    const { container } = render(
      <Slider caption={(v) => `Level: ${v}`} value={75} onChange={() => {}} />,
    )
    expect(container.querySelector('.aws-slider__caption')?.textContent).toBe('Level: 75')
  })

  it('slider-008: disabled attribute is applied', () => {
    const { container } = render(<Slider disabled value={5} onChange={() => {}} />)
    expect(input(container)).toBeDisabled()
  })

  it('slider-009: min defaults to 0', () => {
    const { container } = render(<Slider value={5} onChange={() => {}} />)
    expect(input(container)).toHaveAttribute('min', '0')
  })

  it('slider-010: max defaults to 100', () => {
    const { container } = render(<Slider value={5} onChange={() => {}} />)
    expect(input(container)).toHaveAttribute('max', '100')
  })

  it('slider-011: step defaults to 1', () => {
    const { container } = render(<Slider value={5} onChange={() => {}} />)
    expect(input(container)).toHaveAttribute('step', '1')
  })

  it('slider-012: generated id is non-empty, unique and stable across re-renders', () => {
    const ui = (
      <>
        <Slider label="Value" value={1} onChange={() => {}} />
        <Slider label="Value" value={1} onChange={() => {}} />
      </>
    )
    const { container, rerender } = render(ui)
    const inputs = Array.from(container.querySelectorAll('input'))
    const labels = Array.from(container.querySelectorAll('label'))
    const ids = inputs.map((i) => i.id)
    expect(ids[0]).toBeTruthy()
    expect(ids[1]).toBeTruthy()
    expect(ids[0]).not.toBe(ids[1])
    expect(labels[0].getAttribute('for')).toBe(ids[0])
    expect(labels[1].getAttribute('for')).toBe(ids[1])
    rerender(
      <>
        <Slider label="Value" value={2} onChange={() => {}} />
        <Slider label="Value" value={1} onChange={() => {}} />
      </>,
    )
    expect(Array.from(container.querySelectorAll('input')).map((i) => i.id)).toEqual(ids)
  })

  it('slider-013: custom id is shared by label and input', () => {
    const { container } = render(
      <Slider id="custom-slider" label="Value" value={5} onChange={() => {}} />,
    )
    expect(container.querySelector('label')?.getAttribute('for')).toBe('custom-slider')
    expect(input(container).id).toBe('custom-slider')
  })

  it('slider-014: wrapper classes include className', () => {
    const { container } = render(
      <Slider className="my-custom-class" value={5} onChange={() => {}} />,
    )
    expect((container.firstElementChild as HTMLElement).className).toBe(
      'aws-field aws-field--slider my-custom-class',
    )
  })

  it('slider-015: dragging to min calls onChange(0)', () => {
    const onChange = vi.fn()
    const { container } = render(<Slider value={50} onChange={onChange} />)
    fireEvent.change(input(container), { target: { value: '0' } })
    expect(onChange).toHaveBeenCalledWith(0)
  })

  it('slider-016: dragging to max calls onChange(100)', () => {
    const onChange = vi.fn()
    const { container } = render(<Slider value={50} onChange={onChange} />)
    fireEvent.change(input(container), { target: { value: '100' } })
    expect(onChange).toHaveBeenCalledWith(100)
  })

  // jsdom implements no native range keyboard behavior; key events do not change the value.
  it.skip('slider-017: ArrowRight/ArrowUp increases the value by one step (native key handling, not jsdom)', () => {})
  it.skip('slider-018: ArrowLeft/ArrowDown decreases the value by one step (native key handling, not jsdom)', () => {})
  it.skip('slider-019: Home jumps to min (native key handling, not jsdom)', () => {})
  it.skip('slider-020: End jumps to max (native key handling, not jsdom)', () => {})
  it.skip('slider-021: Page Up / Page Down changes the value (native key handling, not jsdom)', () => {})
  it.skip('slider-022: disabled input ignores keys (native key handling, not jsdom)', () => {})

  it('slider-023: label={0} renders no label element', () => {
    const { container } = render(
      <Slider label={0} value={5} onChange={() => {}} />,
    )
    expect(container.querySelector('label')).toBeNull()
  })

  it('slider-024: input is enabled by default', () => {
    const { container } = render(<Slider value={5} onChange={() => {}} />)
    expect(input(container)).not.toHaveAttribute('disabled')
  })

  it('slider-025: caption={0} renders "0"', () => {
    const { container } = render(<Slider caption={0} value={5} onChange={() => {}} />)
    expect(container.querySelector('.aws-slider__caption')?.textContent).toBe('0')
  })
})
