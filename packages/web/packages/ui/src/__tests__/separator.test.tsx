import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { Separator } from '../components/separator'

describe('Separator conformance vectors', () => {
  it('separator-001 semantic-role, horizontal-orientation: defaults', () => {
    render(<Separator />)
    const el = screen.getByRole('separator')
    expect(el.tagName).toBe('DIV')
    expect(el.getAttribute('aria-orientation')).toBe('horizontal')
    expect(el.getAttribute('data-orientation')).toBe('horizontal')
    expect(el.className).toContain('data-[orientation=horizontal]:h-px')
    expect(el.className).toContain('data-[orientation=horizontal]:w-full')
  })

  it('separator-002 vertical-orientation, orientation-sync: vertical', () => {
    render(<Separator orientation="vertical" />)
    const el = screen.getByRole('separator')
    expect(el.getAttribute('aria-orientation')).toBe('vertical')
    expect(el.getAttribute('data-orientation')).toBe('vertical')
    expect(el.className).toContain('data-[orientation=vertical]:w-px')
    expect(el.className).toContain('data-[orientation=vertical]:h-full')
  })

  it('separator-003 custom-style-override: className merged with base styles', () => {
    render(<Separator className="custom-class" />)
    const el = screen.getByRole('separator')
    expect(el.className).toContain('custom-class')
    expect(el.className).toContain('shrink-0')
    expect(el.className).toContain('bg-apt-border')
  })

  it('separator-004 forwarded-props: data-testid and id reach the element', () => {
    render(<Separator data-testid="my-sep" id="sep1" />)
    const el = screen.getByTestId('my-sep')
    expect(el.id).toBe('sep1')
    expect(el.getAttribute('role')).toBe('separator')
  })

  it('separator-005 semantic-role, orientation-values: unrecognized value set verbatim', () => {
    // @ts-expect-error deliberately outside the typed contract
    render(<Separator orientation="diagonal" />)
    const el = screen.getByRole('separator')
    expect(el.getAttribute('aria-orientation')).toBe('diagonal')
    expect(el.getAttribute('data-orientation')).toBe('diagonal')
    expect(el.className).toContain('shrink-0')
    // the size rules are keyed to horizontal/vertical only
    expect(el.className).not.toContain('data-[orientation=diagonal]')
  })
})
