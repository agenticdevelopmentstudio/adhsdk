/// <reference types="@testing-library/jest-dom/vitest" />
/** Conformance tests for the Checkbox primitive (cookbook/checkbox, vectors checkbox-014..016, 019, 020, 022, 023). */
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { Checkbox } from '../components/checkbox'

describe('Checkbox primitive conformance', () => {
  it('checkbox-014 checked renders the Check icon in the indicator', () => {
    const { container } = render(<Checkbox checked onCheckedChange={() => {}} />)
    const indicator = container.querySelector('[data-slot="checkbox-indicator"]')
    expect(indicator).not.toBeNull()
    expect(indicator!.querySelector('svg.lucide-check')).not.toBeNull()
  })

  it('checkbox-015 unchecked does not render the Check icon', () => {
    const { container } = render(<Checkbox checked={false} onCheckedChange={() => {}} />)
    expect(container.querySelector('svg')).toBeNull()
  })

  it('checkbox-016 root carries the 2px apt-gold/25 focus-visible ring utilities', () => {
    render(<Checkbox />)
    const root = screen.getByRole('checkbox')
    expect(root).toHaveClass('focus-visible:ring-2', 'focus-visible:ring-apt-gold/25')
  })

  it('checkbox-019 Check glyph is present when checked and absent when unchecked, independent of color', () => {
    const checked = render(<Checkbox checked onCheckedChange={() => {}} />)
    expect(checked.container.querySelector('svg.lucide-check')).not.toBeNull()
    checked.unmount()
    const unchecked = render(<Checkbox checked={false} onCheckedChange={() => {}} />)
    expect(unchecked.container.querySelector('svg.lucide-check')).toBeNull()
  })

  it('checkbox-020 className is merged into the root class list', () => {
    render(<Checkbox className="my-custom-class" />)
    const root = screen.getByRole('checkbox')
    expect(root).toHaveClass('my-custom-class', 'size-4', 'rounded')
  })

  it('checkbox-022 defaultChecked renders checked and toggles itself', () => {
    render(<Checkbox defaultChecked />)
    const root = screen.getByRole('checkbox')
    expect(root).toHaveAttribute('aria-checked', 'true')
    fireEvent.click(root)
    expect(root).toHaveAttribute('aria-checked', 'false')
  })

  it('checkbox-023 disabled root is an aria-disabled span with disabled utilities and blocks toggling', () => {
    const onCheckedChange = vi.fn()
    render(<Checkbox disabled onCheckedChange={onCheckedChange} />)
    const root = screen.getByRole('checkbox')
    expect(root.tagName).toBe('SPAN')
    expect(root).toHaveAttribute('aria-disabled', 'true')
    expect(root).toHaveAttribute('data-disabled')
    expect(root).toHaveAttribute('tabindex', '-1')
    expect(root).toHaveClass('data-[disabled]:opacity-50', 'data-[disabled]:pointer-events-none')
    fireEvent.click(root)
    expect(onCheckedChange).not.toHaveBeenCalled()
  })
})
