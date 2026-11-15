import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { RadioGroup, RadioGroupItem } from '../components/radio'

function group(props: React.ComponentProps<typeof RadioGroup> = {}, itemProps: Record<string, unknown> = {}) {
  return render(
    <RadioGroup {...props}>
      <RadioGroupItem value="a" aria-label="A" {...itemProps} />
      <RadioGroupItem value="b" aria-label="B" {...itemProps} />
    </RadioGroup>,
  )
}
const indicator = (el: HTMLElement) => el.querySelector('.bg-apt-gold') as HTMLElement | null
const shown = (el: HTMLElement) => {
  const i = indicator(el)
  return !!i && !i.hasAttribute('hidden') && i.getAttribute('data-checked') !== null
}

describe('RadioGroupItem', () => {
  it('radio-001 checked item shows the gold indicator in a 16px circle', () => {
    group({ defaultValue: 'a' })
    const a = screen.getByRole('radio', { name: 'A' })
    expect(a.getAttribute('aria-checked')).toBe('true')
    expect(shown(a)).toBe(true)
    expect(a.className).toContain('size-4')
    expect(a.className).toContain('rounded-full')
    expect(indicator(a)!.className).toContain('bg-apt-gold')
  })

  it('radio-002 unchecked item renders no indicator dot', () => {
    group({ defaultValue: 'a' })
    const b = screen.getByRole('radio', { name: 'B' })
    expect(b.getAttribute('aria-checked')).toBe('false')
    expect(shown(b)).toBe(false)
  })

  it('radio-003 selecting B unchecks A', async () => {
    const user = userEvent.setup()
    group({ defaultValue: 'a' })
    const a = screen.getByRole('radio', { name: 'A' })
    const b = screen.getByRole('radio', { name: 'B' })
    await user.click(b)
    expect(a.getAttribute('aria-checked')).toBe('false')
    expect(b.getAttribute('aria-checked')).toBe('true')
    expect(shown(a)).toBe(false)
    expect(shown(b)).toBe(true)
  })

  it('radio-004 disabled item ignores a pointer click', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    group({ onValueChange }, { disabled: true })
    const a = screen.getByRole('radio', { name: 'A' })
    await user.click(a)
    fireEvent.click(a)
    expect(a.getAttribute('aria-checked')).toBe('false')
    expect(onValueChange).not.toHaveBeenCalled()
  })

  it('radio-005 disabled item ignores Space and Enter', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    group({ onValueChange }, { disabled: true })
    const a = screen.getByRole('radio', { name: 'A' })
    a.focus()
    await user.keyboard(' ')
    await user.keyboard('{Enter}')
    expect(a.getAttribute('aria-checked')).toBe('false')
    expect(onValueChange).not.toHaveBeenCalled()
  })

  it('radio-006 focus-visible classes: gold border and 25% gold ring', () => {
    group()
    const cls = screen.getByRole('radio', { name: 'A' }).className
    expect(cls).toContain('focus-visible:border-apt-gold')
    expect(cls).toContain('focus-visible:ring-2')
    expect(cls).toContain('focus-visible:ring-apt-gold/25')
  })

  it('radio-007 Space on a focused unchecked item checks it', async () => {
    const user = userEvent.setup()
    group()
    const a = screen.getByRole('radio', { name: 'A' })
    a.focus()
    await user.keyboard(' ')
    expect(a.getAttribute('aria-checked')).toBe('true')
  })

  it('radio-008 default state uses apt-border and apt-bg tokens', () => {
    group()
    const cls = screen.getByRole('radio', { name: 'A' }).className
    expect(cls).toContain('border-apt-border')
    expect(cls).toContain('bg-apt-bg')
  })

  it.skip('radio-009 color transitions (computed transition-property/duration need compiled CSS, absent in jsdom)', () => {})

  it('radio-010 no initial selection shows no indicator', () => {
    group()
    for (const r of screen.getAllByRole('radio')) {
      expect(r.getAttribute('aria-checked')).toBe('false')
      expect(shown(r)).toBe(false)
    }
  })

  it('radio-011 value matching no item leaves all unchecked', () => {
    group({ value: 'zzz', onValueChange: () => {} })
    for (const r of screen.getAllByRole('radio')) {
      expect(r.getAttribute('aria-checked')).toBe('false')
      expect(shown(r)).toBe(false)
    }
  })

  it('radio-012 all items disabled: unselectable, aria-disabled and data-disabled set', async () => {
    const user = userEvent.setup()
    const onValueChange = vi.fn()
    group({ onValueChange }, { disabled: true })
    for (const r of screen.getAllByRole('radio')) {
      await user.click(r)
      expect(r.getAttribute('aria-checked')).toBe('false')
      expect(r.getAttribute('aria-disabled')).toBe('true')
      expect(r.hasAttribute('data-disabled')).toBe(true)
    }
    expect(onValueChange).not.toHaveBeenCalled()
  })

  it('radio-013 checked and disabled item shows indicator with disabled state', () => {
    render(
      <RadioGroup defaultValue="a">
        <RadioGroupItem value="a" aria-label="A" disabled />
      </RadioGroup>,
    )
    const a = screen.getByRole('radio', { name: 'A' })
    expect(shown(a)).toBe(true)
    expect(a.getAttribute('aria-checked')).toBe('true')
    expect(a.getAttribute('aria-disabled')).toBe('true')
    expect(a.hasAttribute('data-disabled')).toBe(true)
  })

  it('radio-014 item carries shrink-0 and size-4 so a flex container cannot resize it', () => {
    group()
    const cls = screen.getByRole('radio', { name: 'A' }).className
    expect(cls).toContain('shrink-0')
    expect(cls).toContain('size-4')
  })
})
