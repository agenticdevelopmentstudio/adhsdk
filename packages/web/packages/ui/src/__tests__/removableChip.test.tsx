import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { RemovableChip } from '../components/removable-chip'
import { badgeVariants } from '../components/badge'

const chip = (props: Partial<React.ComponentProps<typeof RemovableChip>> = {}) => {
  const onRemove = vi.fn()
  render(
    <RemovableChip removeLabel="Remove x" onRemove={onRemove} id="c1" {...props}>
      x
    </RemovableChip>,
  )
  return onRemove
}

describe('RemovableChip', () => {
  it('T1 renders the badge body with children and forwarded props', () => {
    chip()
    const body = document.querySelector('[data-slot="badge"]') as HTMLElement
    expect(body).not.toBeNull()
    expect(body.textContent).toContain('x')
    expect(body.id).toBe('c1')
  })

  it('T2 renders a named type=button remove button', () => {
    chip()
    const btn = screen.getByRole('button', { name: 'Remove x' })
    expect(btn.tagName).toBe('BUTTON')
    expect(btn.getAttribute('type')).toBe('button')
    expect(btn.getAttribute('aria-label')).toBe('Remove x')
  })

  it('T3 clicking remove calls onRemove once', () => {
    const onRemove = chip()
    fireEvent.click(screen.getByRole('button', { name: 'Remove x' }))
    expect(onRemove).toHaveBeenCalledTimes(1)
  })

  it('T4 chip stays in the DOM after removal (stateless)', () => {
    chip()
    fireEvent.click(screen.getByRole('button', { name: 'Remove x' }))
    expect(document.querySelector('[data-slot="badge"]')).not.toBeNull()
  })

  it('T5 variant applies the same classes as badgeVariants (display class is overridden to flex)', () => {
    chip({ variant: 'success' })
    const body = document.querySelector('[data-slot="badge"]') as HTMLElement
    const expected = badgeVariants({ variant: 'success' }).split(/\s+/).filter((c) => c !== 'inline-flex')
    expect(body.classList.contains('flex')).toBe(true)
    for (const c of expected) {
      expect(body.classList.contains(c)).toBe(true)
    }
  })

  it('T6 disabled blocks removal', async () => {
    const user = userEvent.setup()
    const onRemove = chip({ disabled: true })
    const btn = screen.getByRole('button', { name: 'Remove x' }) as HTMLButtonElement
    expect(btn.disabled).toBe(true)
    await user.click(btn)
    expect(onRemove).not.toHaveBeenCalled()
  })

  it('T7 the X icon is aria-hidden', () => {
    chip()
    const svg = screen.getByRole('button', { name: 'Remove x' }).querySelector('svg')!
    expect(svg.getAttribute('aria-hidden')).toBe('true')
  })

  it('T8 remove button is found by name and operable with Enter and Space', async () => {
    const user = userEvent.setup()
    const onRemove = chip()
    const btn = screen.getByRole('button', { name: 'Remove x' })
    btn.focus()
    await user.keyboard('{Enter}')
    await user.keyboard(' ')
    expect(onRemove).toHaveBeenCalledTimes(2)
  })
})
