import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { Badge, badgeVariants } from '../components/badge'

describe('Badge', () => {
  it('badge-001 renders a span with data-slot', () => {
    render(<Badge>Beta</Badge>)
    const el = screen.getByText('Beta')
    expect(el.tagName).toBe('SPAN')
    expect(el.getAttribute('data-slot')).toBe('badge')
  })
  it('badge-002 default is neutral', () => {
    render(<Badge>Beta</Badge>)
    const cls = screen.getByText('Beta').className
    expect(cls).toContain('border-apt-border')
    expect(cls).toContain('text-apt-text-dim')
  })
  const tones: Array<[string, 'accent' | 'orange' | 'blue' | 'success' | 'error', string]> = [
    ['badge-003', 'accent', 'gold'],
    ['badge-004', 'orange', 'orange'],
    ['badge-005', 'blue', 'blue'],
    ['badge-006', 'success', 'green'],
    ['badge-007', 'error', 'red'],
  ]
  for (const [id, variant, color] of tones) {
    it(`${id} ${variant} tone`, () => {
      render(<Badge variant={variant}>x</Badge>)
      const cls = screen.getByText('x').className
      expect(cls).toContain(`border-apt-${color}`)
      expect(cls).toContain(`text-apt-${color}`)
    })
  }
  it('badge-008 merges className', () => {
    render(<Badge className="ml-2">x</Badge>)
    const cls = screen.getByText('x').className
    expect(cls).toContain('ml-2')
    expect(cls).toContain('border-apt-border')
    expect(cls).toContain('text-apt-text-dim')
  })
  it('badge-009 spreads props', () => {
    render(<Badge id="b1" title="Preview">x</Badge>)
    const el = screen.getByText('x')
    expect(el.getAttribute('id')).toBe('b1')
    expect(el.getAttribute('title')).toBe('Preview')
  })
  it('badge-010 uppercase mono nowrap pill', () => {
    render(<Badge>x</Badge>)
    const cls = screen.getByText('x').className
    for (const c of ['uppercase', 'font-mono', 'whitespace-nowrap', 'rounded-full']) expect(cls).toContain(c)
  })
  it('badge-011 sizes svg children', () => {
    render(<Badge><svg data-testid="s" /></Badge>)
    const cls = screen.getByTestId('s').parentElement!.className
    expect(cls).toContain('[&_svg]:size-3')
    expect(cls).toContain('[&_svg]:shrink-0')
  })
  it('badge-012 exports badgeVariants', () => {
    expect(badgeVariants({ variant: 'error' })).toContain('border-apt-red')
  })
})
