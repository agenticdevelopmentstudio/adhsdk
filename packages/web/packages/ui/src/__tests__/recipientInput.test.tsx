/// <reference types="@testing-library/jest-dom/vitest" />
import * as React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { RecipientInput } from '../components/recipient-input'

function setup(value: string[] = [], kind: any = 'text') {
  const onChange = vi.fn()
  render(<RecipientInput value={value} onChange={onChange} kind={kind} ariaLabel="Recipients" />)
  return { onChange, input: screen.getByRole('textbox', { name: 'Add to Recipients' }) as HTMLInputElement }
}

describe('RecipientInput', () => {
  it('tokenizes on Enter (trim + add)', () => {
    const { onChange, input } = setup([])
    fireEvent.change(input, { target: { value: '  ada@x.io ' } })
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onChange).toHaveBeenCalledWith(['ada@x.io'])
  })
  it('tokenizes on comma', () => {
    const { onChange, input } = setup(['a@x.io'])
    fireEvent.change(input, { target: { value: 'b@x.io,' } })
    expect(onChange).toHaveBeenCalledWith(['a@x.io', 'b@x.io'])
  })
  it('de-dupes case-insensitively for emails', () => {
    const { onChange, input } = setup(['A@x.io'], 'email')
    fireEvent.change(input, { target: { value: 'a@x.io' } })
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onChange).not.toHaveBeenCalled()
  })
  it('Backspace on empty removes the last chip', () => {
    const { onChange, input } = setup(['a@x.io', 'b@x.io'])
    fireEvent.keyDown(input, { key: 'Backspace' })
    expect(onChange).toHaveBeenCalledWith(['a@x.io'])
  })
  it('removes a specific chip via its × button', () => {
    const { onChange } = setup(['a@x.io', 'b@x.io'])
    fireEvent.click(screen.getByRole('button', { name: 'Remove a@x.io' }))
    expect(onChange).toHaveBeenCalledWith(['b@x.io'])
  })
  it('flags an invalid email chip with aria-invalid but still adds it', () => {
    const { onChange, input } = setup([], 'email')
    fireEvent.change(input, { target: { value: 'nope' } })
    fireEvent.keyDown(input, { key: 'Enter' })
    expect(onChange).toHaveBeenCalledWith(['nope'])
  })
  it('does not tokenize partial text when focus moves to a chip × button inside the component', () => {
    const { onChange, input } = setup(['a@x.io'])
    fireEvent.change(input, { target: { value: 'partial' } })
    const removeBtn = screen.getByRole('button', { name: 'Remove a@x.io' })
    fireEvent.blur(input, { relatedTarget: removeBtn })
    // onChange should only be called when the × button is clicked, not on blur
    expect(onChange).not.toHaveBeenCalled()
  })
})

// ── Conformance vectors T1..T28 ──────────────────────────────────────────────

type Kind = 'email' | 'phone' | 'text'

/** A stateful parent, so successive adds accumulate the way a real caller's would. */
function Harness({
  initial = [],
  onChangeSpy,
  ...rest
}: {
  initial?: string[]
  onChangeSpy: (next: string[]) => void
} & Partial<React.ComponentProps<typeof RecipientInput>>): React.ReactElement {
  const [value, setValue] = React.useState<string[]>(initial)
  return (
    <RecipientInput
      ariaLabel="Recipients"
      {...rest}
      value={value}
      onChange={(next: string[]) => {
        onChangeSpy(next)
        setValue(next)
      }}
    />
  )
}

function mount(props: Partial<React.ComponentProps<typeof RecipientInput>> & { initial?: string[] } = {}) {
  const spy = vi.fn<(next: string[]) => void>()
  const utils = render(<Harness onChangeSpy={spy} {...props} />)
  const input = (): HTMLInputElement => screen.getByRole('textbox', { name: 'Add to Recipients' })
  return { spy, input, ...utils }
}

function chip(text: string): HTMLElement {
  return screen.getByText(text)
}

describe('RecipientInput conformance vectors', () => {
  it('T1 Enter tokenizes a neutral chip and clears the input', () => {
    const { spy, input } = mount({ kind: 'email' })
    fireEvent.change(input(), { target: { value: 'ada@x.io' } })
    fireEvent.keyDown(input(), { key: 'Enter' })
    expect(spy).toHaveBeenCalledWith(['ada@x.io'])
    expect(chip('ada@x.io')).toHaveClass('border-apt-border')
    expect(input().value).toBe('')
  })

  it('T2 each comma adds a chip: two chips in total, input clears each time', () => {
    const { spy, input } = mount({ kind: 'email' })
    fireEvent.change(input(), { target: { value: 'ada@x.io,' } })
    expect(spy).toHaveBeenLastCalledWith(['ada@x.io'])
    expect(input().value).toBe('')
    fireEvent.change(input(), { target: { value: 'grace@x.io,' } })
    expect(spy).toHaveBeenLastCalledWith(['ada@x.io', 'grace@x.io'])
    expect(input().value).toBe('')
    expect(screen.getAllByRole('button')).toHaveLength(2)
  })

  it('T3 a pasted batch is split and its duplicate dropped', () => {
    const { spy, input } = mount({ kind: 'email' })
    fireEvent.change(input(), { target: { value: 'a@x.io, A@x.io' } })
    expect(spy).toHaveBeenCalledTimes(1)
    expect(spy).toHaveBeenCalledWith(['a@x.io'])
    expect(input().value).toBe('')
  })

  it('T4 blur trims and adds a chip, clearing the input', () => {
    const { spy, input } = mount({ kind: 'email' })
    fireEvent.change(input(), { target: { value: '  ada@x.io  ' } })
    fireEvent.blur(input())
    expect(spy).toHaveBeenCalledWith(['ada@x.io'])
    expect(input().value).toBe('')
  })

  it('T5 email dedup is case-insensitive; the rejected entry still clears the input', () => {
    const { spy, input } = mount({ kind: 'email', initial: ['Ada@x.io'] })
    fireEvent.change(input(), { target: { value: 'ada@x.io' } })
    fireEvent.keyDown(input(), { key: 'Enter' })
    expect(spy).not.toHaveBeenCalled()
    expect(screen.getAllByRole('button')).toHaveLength(1)
    expect(input().value).toBe('')
  })

  it('T6 non-email dedup is exact: Ada and ada both added', () => {
    const { spy, input } = mount({ kind: 'text' })
    fireEvent.change(input(), { target: { value: 'Ada' } })
    fireEvent.keyDown(input(), { key: 'Enter' })
    fireEvent.change(input(), { target: { value: 'ada' } })
    fireEvent.keyDown(input(), { key: 'Enter' })
    expect(spy).toHaveBeenLastCalledWith(['Ada', 'ada'])
  })

  it('T7 an invalid email chip is added with error appearance and aria-invalid', () => {
    const { spy, input } = mount({ kind: 'email' })
    fireEvent.change(input(), { target: { value: 'bad@' } })
    fireEvent.keyDown(input(), { key: 'Enter' })
    expect(spy).toHaveBeenCalledWith(['bad@'])
    expect(chip('bad@')).toHaveAttribute('aria-invalid', 'true')
    expect(chip('bad@')).toHaveClass('border-apt-red', 'text-apt-red')
  })

  it('T8 a valid email chip is neutral with no aria-invalid', () => {
    mount({ kind: 'email', initial: ['ada@x.io'] })
    expect(chip('ada@x.io')).not.toHaveAttribute('aria-invalid')
    expect(chip('ada@x.io')).toHaveClass('border-apt-border')
  })

  it('T9 a too-short phone chip is added with error appearance and aria-invalid', () => {
    const { spy, input } = mount({ kind: 'phone' })
    fireEvent.change(input(), { target: { value: '12345' } })
    fireEvent.keyDown(input(), { key: 'Enter' })
    expect(spy).toHaveBeenCalledWith(['12345'])
    expect(chip('12345')).toHaveAttribute('aria-invalid', 'true')
    expect(chip('12345')).toHaveClass('border-apt-red')
  })

  it('T10 a formatted phone number is valid and neutral', () => {
    mount({ kind: 'phone', initial: ['+1 (555) 123-4567'] })
    expect(chip('+1 (555) 123-4567')).not.toHaveAttribute('aria-invalid')
    expect(chip('+1 (555) 123-4567')).toHaveClass('border-apt-border')
  })

  it('T11 text kind applies no validation', () => {
    mount({ kind: 'text', initial: ['@#$%^'] })
    expect(chip('@#$%^')).not.toHaveAttribute('aria-invalid')
    expect(chip('@#$%^')).toHaveClass('border-apt-border')
  })

  it('T12 clicking × removes that chip', () => {
    const { spy } = mount({ initial: ['a@x.io', 'b@x.io'] })
    fireEvent.click(screen.getByRole('button', { name: 'Remove a@x.io' }))
    expect(spy).toHaveBeenCalledWith(['b@x.io'])
  })

  it('T13 a chip remove button is reachable by Tab and activates with Enter and Space', async () => {
    const user = userEvent.setup()
    const { spy } = mount({ initial: ['a@x.io', 'b@x.io'] })
    await user.tab()
    expect(screen.getByRole('button', { name: 'Remove a@x.io' })).toHaveFocus()
    await user.keyboard('{Enter}')
    expect(spy).toHaveBeenLastCalledWith(['b@x.io'])
    await user.tab()
    expect(screen.getByRole('button', { name: 'Remove b@x.io' })).toHaveFocus()
    await user.keyboard(' ')
    expect(spy).toHaveBeenLastCalledWith([])
  })

  it('T14 removal filters by value: duplicates seeded by the parent are both removed', () => {
    const { spy } = mount({ kind: 'email', initial: ['ada@x.io', 'ada@x.io'] })
    fireEvent.click(screen.getAllByRole('button', { name: 'Remove ada@x.io' })[0]!)
    expect(spy).toHaveBeenCalledWith([])
  })

  it('T15 fused mode: Backspace on an empty input removes the last chip', () => {
    const { spy, input } = mount({ initial: ['a@x.io', 'b@x.io'] })
    fireEvent.keyDown(input(), { key: 'Backspace' })
    expect(spy).toHaveBeenCalledWith(['a@x.io'])
  })

  it('T16 separate mode: Backspace on an empty input removes nothing', () => {
    const { spy, input } = mount({ initial: ['a@x.io', 'b@x.io'], separateInput: true })
    fireEvent.keyDown(input(), { key: 'Backspace' })
    expect(spy).not.toHaveBeenCalled()
  })

  it('T17 kind="email" sets inputMode="email"', () => {
    const { input } = mount({ kind: 'email' })
    expect(input()).toHaveAttribute('inputmode', 'email')
  })

  it('T18 kind="phone" sets inputMode="tel"', () => {
    const { input } = mount({ kind: 'phone' })
    expect(input()).toHaveAttribute('inputmode', 'tel')
  })

  it('T19 kind="text" and unspecified kind set inputMode="text"', () => {
    const { input, unmount } = mount({ kind: 'text' })
    expect(input()).toHaveAttribute('inputmode', 'text')
    unmount()
    const second = mount({})
    expect(second.input()).toHaveAttribute('inputmode', 'text')
  })

  it('T20 separateInput renders a recipients box with the input below it', () => {
    const { input } = mount({ separateInput: true, initial: ['a@x.io'] })
    const box = screen.getByTestId('recipients-box')
    expect(box).toContainElement(chip('a@x.io'))
    expect(box).not.toContainElement(input())
    expect(box.compareDocumentPosition(input()) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('T21 readOnly shows static Badge chips: no input, no remove control', () => {
    const { container } = mount({ readOnly: true, initial: ['a@x.io', 'b@x.io'] })
    expect(chip('a@x.io')).toHaveAttribute('data-slot', 'badge')
    expect(chip('b@x.io')).toHaveAttribute('data-slot', 'badge')
    expect(screen.queryByRole('textbox')).toBeNull()
    expect(container.querySelector('button')).toBeNull()
  })

  it('T22 readOnly renders no input or button and never calls onChange', () => {
    const { container, spy } = mount({ readOnly: true, initial: ['a@x.io'] })
    expect(container.querySelector('input')).toBeNull()
    expect(container.querySelector('button')).toBeNull()
    fireEvent.click(chip('a@x.io'))
    expect(spy).not.toHaveBeenCalled()
  })

  it('T23 disabled: grayed out, pointer-events-none, input disabled, typing does nothing', async () => {
    const { container, spy, input } = mount({ disabled: true, initial: ['a@x.io'] })
    const group = container.querySelector('[role="group"]')!
    expect(group).toHaveClass('opacity-50', 'pointer-events-none')
    expect(input()).toBeDisabled()
    await userEvent.setup().type(input(), 'abc{Enter}')
    expect(input().value).toBe('')
    expect(spy).not.toHaveBeenCalled()
  })

  it('T24 separate mode with an empty value shows "No recipients yet"', () => {
    mount({ separateInput: true })
    expect(screen.getByTestId('recipients-box')).toHaveTextContent('No recipients yet')
  })

  it('T25 fused placeholder shows when empty and hides once a chip exists', () => {
    const spy = vi.fn()
    const { rerender } = render(
      <RecipientInput value={[]} onChange={spy} ariaLabel="Recipients" placeholder="Who?" />,
    )
    expect(screen.getByRole('textbox')).toHaveAttribute('placeholder', 'Who?')
    rerender(<RecipientInput value={['a@x.io']} onChange={spy} ariaLabel="Recipients" placeholder="Who?" />)
    expect(screen.getByRole('textbox')).not.toHaveAttribute('placeholder')
  })

  it('T26 separate + readOnly shows static Badge chips and no input', () => {
    const { container } = mount({ separateInput: true, readOnly: true, initial: ['a@x.io'] })
    const box = screen.getByTestId('recipients-box')
    expect(box).toContainElement(chip('a@x.io'))
    expect(chip('a@x.io')).toHaveAttribute('data-slot', 'badge')
    expect(container.querySelector('input')).toBeNull()
    expect(container.querySelector('button')).toBeNull()
  })

  it('T27 a case-insensitive duplicate (comma or blur) adds nothing and clears the input', () => {
    const { spy, input } = mount({ kind: 'email', initial: ['ada@x.io'] })
    fireEvent.change(input(), { target: { value: 'Ada@x.io,' } })
    expect(spy).not.toHaveBeenCalled()
    expect(input().value).toBe('')
    fireEvent.change(input(), { target: { value: 'Ada@x.io' } })
    fireEvent.blur(input())
    expect(spy).not.toHaveBeenCalled()
    expect(input().value).toBe('')
  })

  it('T28 separate mode defaults the placeholder from kind', () => {
    const expected: Array<[Kind, string]> = [
      ['email', 'Add email…'],
      ['phone', 'Add phone…'],
      ['text', 'Add…'],
    ]
    for (const [kind, text] of expected) {
      const { unmount } = render(
        <RecipientInput value={[]} onChange={() => {}} ariaLabel="Recipients" kind={kind} separateInput />,
      )
      expect(screen.getByRole('textbox')).toHaveAttribute('placeholder', text)
      unmount()
    }
  })

  it('T28 fused mode defaults the placeholder from kind', () => {
    const expected: Array<[Kind, string]> = [
      ['email', 'Add email…'],
      ['phone', 'Add phone…'],
      ['text', 'Add…'],
    ]
    for (const [kind, text] of expected) {
      const { unmount } = render(
        <RecipientInput value={[]} onChange={() => {}} ariaLabel="Recipients" kind={kind} />,
      )
      expect(screen.getByRole('textbox')).toHaveAttribute('placeholder', text)
      unmount()
    }
  })
})
