import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { ExternalLink } from '../components/external-link'

describe('ExternalLink', () => {
  it('T1 opens in a new tab with safe rel', () => {
    render(<ExternalLink href="https://example.com">PostHog</ExternalLink>)
    const a = screen.getByRole('link')
    expect(a.getAttribute('target')).toBe('_blank')
    expect(a.getAttribute('rel')).toBe('noopener noreferrer')
  })
  it('T2 renders the trailing glyph by default', () => {
    render(<ExternalLink href="https://example.com">PostHog</ExternalLink>)
    expect(screen.getByRole('link').textContent).toContain('↗')
  })
  it('T3 glyph is decorative', () => {
    render(<ExternalLink href="https://example.com">PostHog</ExternalLink>)
    expect(screen.getByRole('link', { name: 'PostHog' })).toBeTruthy()
  })
  it('T4 suppresses the glyph when false', () => {
    render(<ExternalLink href="https://example.com" glyph={false}>GitHub</ExternalLink>)
    expect(screen.getByRole('link', { name: 'GitHub' }).textContent).not.toContain('↗')
  })
  it('T5 forwards anchor props', () => {
    render(<ExternalLink href="https://us.posthog.com">PostHog</ExternalLink>)
    expect(screen.getByRole('link').getAttribute('href')).toBe('https://us.posthog.com')
  })
  it('T6 merges className over the default skin', () => {
    render(<ExternalLink href="https://example.com" className="font-sans text-apt-text-muted">x</ExternalLink>)
    const a = screen.getByRole('link')
    expect(a.className).toContain('font-sans')
    expect(a.className).not.toContain('font-mono')
    expect(a.getAttribute('target')).toBe('_blank')
    expect(a.getAttribute('rel')).toBe('noopener noreferrer')
  })
  it('T7 target and rel cannot be overridden', () => {
    render(<ExternalLink href="https://example.com" target="_self" rel="">PostHog</ExternalLink>)
    const a = screen.getByRole('link')
    expect(a.getAttribute('target')).toBe('_blank')
    expect(a.getAttribute('rel')).toBe('noopener noreferrer')
  })
  it('T8 focus ring classes', () => {
    render(<ExternalLink href="https://example.com">PostHog</ExternalLink>)
    const cls = screen.getByRole('link').className
    expect(cls).toContain('focus-visible:ring-2')
    expect(cls).toContain('focus-visible:ring-apt-gold/40')
  })
  it('T9 default deep-link skin', () => {
    render(<ExternalLink href="https://example.com">PostHog</ExternalLink>)
    const cls = screen.getByRole('link').className
    expect(cls).toContain('whitespace-nowrap')
    expect(cls).toContain('no-underline')
  })
  it('T10 mirrors the glyph under RTL', () => {
    render(<div dir="rtl"><ExternalLink href="https://example.com">PostHog</ExternalLink></div>)
    const glyph = screen.getByRole('link').querySelector('[aria-hidden="true"]')
    expect(glyph?.textContent).toBe('↗')
    // Tailwind v4's rtl: variant applies the mirror under any [dir="rtl"] ancestor;
    // inline-block is required for the transform to take effect on an inline span.
    expect(glyph?.className.split(' ')).toEqual(expect.arrayContaining(['inline-block', 'rtl:-scale-x-100']))
  })
})
