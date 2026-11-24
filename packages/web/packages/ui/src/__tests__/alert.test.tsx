/** Conformance tests for Alert / AlertTitle / AlertDescription / alertVariants
 *  (alert-001..alert-025). jsdom cannot resolve Tailwind utilities into computed
 *  styles, so styling vectors assert the utility classes that produce them. */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { Alert, AlertTitle, AlertDescription, alertVariants } from '../components/alert'

const first = (c: HTMLElement) => c.firstElementChild as HTMLElement

describe('Alert conformance vectors', () => {
  it('alert-001 root has role="alert"', () => {
    const { container } = render(<Alert>Text</Alert>)
    expect(first(container)).toHaveAttribute('role', 'alert')
  })

  it('alert-002 root has data-slot="alert"', () => {
    const { container } = render(<Alert>Text</Alert>)
    expect(first(container)).toHaveAttribute('data-slot', 'alert')
  })

  it('alert-003 default variant uses border and surface tokens', () => {
    const { container } = render(<Alert>Text</Alert>)
    expect(first(container)).toHaveClass('border-apt-border', 'bg-apt-surface')
  })

  it('alert-004 each of the six variants renders its tone', () => {
    const tones: Record<string, [string, string]> = {
      default: ['border-apt-border', 'bg-apt-surface'],
      info: ['border-apt-blue/40', 'bg-apt-blue/10'],
      success: ['border-apt-green/40', 'bg-apt-green/10'],
      error: ['border-apt-red/40', 'bg-apt-red/10'],
      warning: ['border-apt-orange/40', 'bg-apt-orange/10'],
      accent: ['border-apt-gold/40', 'bg-apt-gold/10'],
    }
    for (const [variant, [border, bg]] of Object.entries(tones)) {
      const { container, unmount } = render(
        <Alert variant={variant as 'default'}>Text</Alert>,
      )
      expect(first(container)).toHaveClass(border, bg)
      unmount()
    }
  })

  it('alert-005 custom className merges with base styling', () => {
    const { container } = render(<Alert className="custom">Text</Alert>)
    expect(first(container)).toHaveClass('custom', 'rounded-lg', 'border', 'bg-apt-surface')
  })

  it('alert-006 forwards id and data-testid', () => {
    const { container } = render(<Alert id="my-alert" data-testid="my-alert">Text</Alert>)
    expect(first(container)).toHaveAttribute('id', 'my-alert')
    expect(first(container)).toHaveAttribute('data-testid', 'my-alert')
  })

  it.skip('alert-007 icon widens grid to 1.25rem 1fr with 0.75rem gap (needs real browser: has-[>svg] computed grid-template-columns)', () => {})

  it.skip('alert-008 direct svg is 1rem and translated 0.125rem (needs real browser: computed size and transform)', () => {})

  it('alert-009 AlertTitle is placed in column two', () => {
    const { container } = render(<AlertTitle>Title</AlertTitle>)
    expect(first(container)).toHaveClass('col-start-2')
  })

  it('alert-010 AlertTitle uses medium font weight', () => {
    const { container } = render(<AlertTitle>Title</AlertTitle>)
    expect(first(container)).toHaveClass('font-medium')
  })

  it('alert-011 AlertTitle className merges with column placement', () => {
    const { container } = render(<AlertTitle className="custom">Title</AlertTitle>)
    expect(first(container)).toHaveClass('custom', 'col-start-2')
  })

  it('alert-012 AlertTitle forwards id', () => {
    const { container } = render(<AlertTitle id="t1">Title</AlertTitle>)
    expect(first(container)).toHaveAttribute('id', 't1')
  })

  it('alert-013 AlertDescription is placed in column two', () => {
    const { container } = render(<AlertDescription>Desc</AlertDescription>)
    expect(first(container)).toHaveClass('col-start-2')
  })

  it('alert-014 AlertDescription is small and muted', () => {
    const { container } = render(<AlertDescription>Desc</AlertDescription>)
    expect(first(container)).toHaveClass('text-sm', 'text-apt-text-muted')
  })

  it('alert-015 AlertDescription className merges with column placement', () => {
    const { container } = render(<AlertDescription className="custom">Desc</AlertDescription>)
    expect(first(container)).toHaveClass('custom', 'col-start-2')
  })

  it('alert-016 AlertDescription forwards id', () => {
    const { container } = render(<AlertDescription id="d1">Desc</AlertDescription>)
    expect(first(container)).toHaveAttribute('id', 'd1')
  })

  it('alert-017 alertVariants returns success tokens without rendering', () => {
    const cls = alertVariants({ variant: 'success' })
    expect(cls).toContain('border-apt-green/40')
    expect(cls).toContain('bg-apt-green/10')
  })

  it('alert-018 title and description compose inside the grid root with row gap', () => {
    const { container } = render(
      <Alert><AlertTitle>T</AlertTitle><AlertDescription>D</AlertDescription></Alert>,
    )
    const root = first(container)
    expect(root).toHaveClass('grid', 'gap-y-0.5')
    expect(root.querySelector('[data-slot="alert-title"]')).toHaveClass('col-start-2')
    expect(root.querySelector('[data-slot="alert-description"]')).toHaveClass('col-start-2')
  })

  it('alert-019 explicit role and data-slot override the defaults', () => {
    const { container } = render(<Alert role="status" data-slot="banner">Text</Alert>)
    expect(first(container)).toHaveAttribute('role', 'status')
    expect(first(container)).toHaveAttribute('data-slot', 'banner')
  })

  it.skip('alert-020 no-icon baseline grid is 0px 1fr with no gap (needs real browser: computed grid-template-columns)', () => {})

  it('alert-021 unknown variant yields only the shared base classes', () => {
    const cls = alertVariants({ variant: 'bogus' as never })
    expect(cls).toContain('rounded-lg')
    expect(cls).not.toMatch(/border-apt-|bg-apt-|text-apt-/)
  })

  it('alert-022 AlertTitle has data-slot="alert-title"', () => {
    const { container } = render(<AlertTitle>Title</AlertTitle>)
    expect(first(container)).toHaveAttribute('data-slot', 'alert-title')
  })

  it('alert-023 AlertDescription has data-slot="alert-description"', () => {
    const { container } = render(<AlertDescription>Desc</AlertDescription>)
    expect(first(container)).toHaveAttribute('data-slot', 'alert-description')
  })

  it('alert-024 Alert with no children renders an empty role="alert" div', () => {
    const { container } = render(<Alert />)
    expect(first(container).tagName).toBe('DIV')
    expect(first(container)).toHaveAttribute('role', 'alert')
    expect(first(container)).toBeEmptyDOMElement()
  })

  it('alert-025 variant undefined matches the default variant', () => {
    const a = render(<Alert>Text</Alert>)
    const b = render(<Alert variant={undefined}>Text</Alert>)
    expect(first(b.container).className).toBe(first(a.container).className)
  })
})
