/**
 * `Spinner` conformance vectors (spinner-001 .. spinner-008).
 *
 * jsdom loads no Tailwind stylesheet, so computed size/colour/animation cannot be read;
 * those vectors assert the utility classes the component resolves (via `cn`), which is
 * all the source itself decides.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, cleanup } from '@testing-library/react'
import { describe, it, expect, afterEach } from 'vitest'

import { Spinner } from '../components/spinner'

afterEach(cleanup)

describe('Spinner', () => {
  it('spinner-001 render-indicator: renders a Lucide Loader2 svg', () => {
    const { container } = render(<Spinner />)
    const svg = container.querySelector('svg')
    expect(svg).toBeInTheDocument()
    expect(svg).toHaveClass('lucide-loader-circle')
  })

  it.skip('spinner-002 spin-animation: computed animation-name is non-empty (needs the Tailwind stylesheet; jsdom has none)', () => {})

  it('spinner-002 spin-animation: carries the animate-spin utility', () => {
    render(<Spinner />)
    expect(screen.getByRole('status')).toHaveClass('animate-spin')
  })

  it('spinner-003 accept-classname: caller size and colour override the defaults', () => {
    render(<Spinner className="size-8 text-red-500" />)
    const el = screen.getByRole('status')
    expect(el).toHaveClass('size-8', 'text-red-500')
    expect(el).not.toHaveClass('size-4')
    expect(el).not.toHaveClass('text-apt-text-muted')
  })

  it('spinner-004 accept-props: forwards data-testid', () => {
    render(<Spinner data-testid="loading-indicator" />)
    expect(screen.getByTestId('loading-indicator')).toBeInTheDocument()
  })

  it('spinner-005 aria-label: accessible name is "Loading"', () => {
    render(<Spinner />)
    expect(screen.getByRole('status', { name: 'Loading' })).toBeInTheDocument()
  })

  it('spinner-006 status-role: has role="status"', () => {
    render(<Spinner />)
    expect(document.querySelector('svg')).toHaveAttribute('role', 'status')
  })

  it('spinner-007 default-size: size-4 by default and when className omits a size utility', () => {
    const { rerender } = render(<Spinner />)
    expect(screen.getByRole('status')).toHaveClass('size-4')
    rerender(<Spinner className="text-red-500" />)
    expect(screen.getByRole('status')).toHaveClass('size-4')
  })

  it('spinner-008 default-color: text-apt-text-muted by default and when className omits a text colour', () => {
    const { rerender } = render(<Spinner />)
    expect(screen.getByRole('status')).toHaveClass('text-apt-text-muted')
    rerender(<Spinner className="size-8" />)
    expect(screen.getByRole('status')).toHaveClass('text-apt-text-muted')
  })
})
