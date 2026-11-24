/** Conformance vectors for the ToggleGroup recipe (cookbook/ui/components/inputs/toggle-group). */
/// <reference types="@testing-library/jest-dom/vitest" />
import * as React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { ToggleGroup, ToggleGroupItem } from '../components/toggle-group'

type GroupProps = React.ComponentProps<typeof ToggleGroup>

function Group(props: GroupProps & { centerDisabled?: boolean; itemClass?: string }): React.ReactElement {
  const { centerDisabled, itemClass, ...rest } = props
  return (
    <ToggleGroup {...rest}>
      <ToggleGroupItem value="left" className={itemClass}>Left</ToggleGroupItem>
      <ToggleGroupItem value="center" disabled={centerDisabled}>Center</ToggleGroupItem>
      <ToggleGroupItem value="right">Right</ToggleGroupItem>
    </ToggleGroup>
  )
}

const item = (name: string): HTMLElement => screen.getByRole('button', { name })
const pressed = (name: string): boolean => item(name).hasAttribute('data-pressed')

function Harness({ onChange }: { onChange?: (next: string[]) => void }): React.ReactElement {
  const [selected, setSelected] = React.useState('center')
  return (
    <Group
      value={[selected]}
      onValueChange={(next: string[]): void => {
        onChange?.(next)
        if (next[0] !== undefined) setSelected(next[0])
      }}
    />
  )
}

describe('ToggleGroup conformance vectors', () => {
  it('T1 renders one focusable toggle button per value', () => {
    render(<Group />)
    expect(screen.getAllByRole('button')).toHaveLength(3)
    for (const name of ['Left', 'Center', 'Right']) {
      item(name).focus()
      expect(item(name)).toHaveFocus()
    }
  })

  it('T2 marks the selected item pressed', () => {
    render(<Group value={['center']} />)
    expect(pressed('Center')).toBe(true)
    expect(pressed('Left')).toBe(false)
    expect(pressed('Right')).toBe(false)
  })

  it('T3 pressed item carries the gold fill classes', () => {
    render(<Group value={['center']} />)
    expect(item('Center')).toHaveClass('data-[pressed]:bg-apt-gold', 'data-[pressed]:text-apt-bg')
  })

  it('T4 clicking an item emits onValueChange with the next array', () => {
    const onValueChange = vi.fn()
    render(<Group value={['center']} onValueChange={onValueChange} />)
    fireEvent.click(item('Right'))
    expect(onValueChange).toHaveBeenCalledTimes(1)
    expect(onValueChange.mock.calls[0]![0]).toEqual(['right'])
  })

  it('T5 a controlled single-select harness ends with exactly one item pressed', () => {
    render(<Harness />)
    fireEvent.click(item('Right'))
    expect(pressed('Right')).toBe(true)
    expect(pressed('Center')).toBe(false)
    expect(pressed('Left')).toBe(false)
  })

  it.skip('T6 arrow-key focus and Enter activation (Playwright: needs real focus and key handling)', () => {})

  it.skip('T7 focus-visible ring on keyboard focus (Playwright: needs real :focus-visible and CSS)', () => {})

  it('T8 a disabled item is inert and dimmed', () => {
    const onValueChange = vi.fn()
    render(<Group value={['left']} onValueChange={onValueChange} centerDisabled />)
    fireEvent.click(item('Center'))
    expect(onValueChange).not.toHaveBeenCalled()
    expect(item('Center')).toHaveClass('disabled:opacity-50', 'disabled:pointer-events-none')
  })

  it('T9 clicking the pressed item emits [] and the harness keeps its selection', () => {
    const onChange = vi.fn()
    render(<Harness onChange={onChange} />)
    fireEvent.click(item('Right'))
    expect(pressed('Right')).toBe(true)
    onChange.mockClear()
    fireEvent.click(item('Right'))
    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange.mock.calls[0]![0]).toEqual([])
    expect(pressed('Right')).toBe(true)
  })

  it('T10 ArrowRight skips the disabled center item', async () => {
    const user = userEvent.setup()
    render(<Group centerDisabled />)
    item('Left').focus()
    expect(item('Left')).toHaveFocus()
    await user.keyboard('{ArrowRight}')
    expect(item('Right')).toHaveFocus()
  })

  it('T11 forwards group and item props', () => {
    render(<Group aria-label="Alignment" className="x" itemClass="y" />)
    expect(screen.getByLabelText('Alignment')).toHaveClass('x')
    expect(item('Left')).toHaveClass('y')
  })

  it('T12 multiple marks every value in the array pressed', () => {
    render(<Group multiple value={['left', 'right']} />)
    expect(pressed('Left')).toBe(true)
    expect(pressed('Right')).toBe(true)
    expect(pressed('Center')).toBe(false)
  })

  it('T13 defaultValue seeds the state and Base UI owns it after a click', () => {
    render(<Group defaultValue={['center']} />)
    expect(pressed('Center')).toBe(true)
    fireEvent.click(item('Right'))
    expect(pressed('Right')).toBe(true)
    expect(pressed('Center')).toBe(false)
  })

  it('T14 a value matching no item presses nothing', () => {
    render(<Group value={['missing']} />)
    for (const name of ['Left', 'Center', 'Right']) expect(pressed(name)).toBe(false)
  })

  it('T15 a disabled group is inert and every item is dimmed', () => {
    const onValueChange = vi.fn()
    render(<Group disabled onValueChange={onValueChange} />)
    fireEvent.click(item('Left'))
    expect(onValueChange).not.toHaveBeenCalled()
    for (const name of ['Left', 'Center', 'Right']) {
      expect(item(name)).toHaveClass('disabled:opacity-50')
    }
  })

  it.skip('T16 pressed item keeps text-apt-bg on hover (Playwright: needs computed styles from real CSS)', () => {})
})
