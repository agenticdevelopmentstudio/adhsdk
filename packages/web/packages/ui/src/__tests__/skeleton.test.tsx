/** Conformance tests for Skeleton (skeleton-001..skeleton-009). jsdom does not
 *  resolve Tailwind utilities, so styling vectors assert the utility classes. */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import { Skeleton } from '../components/skeleton'

const first = (c: HTMLElement) => c.firstElementChild as HTMLElement

describe('Skeleton conformance vectors', () => {
  it('skeleton-001 renders a div with data-slot="skeleton"', () => {
    const { container } = render(<Skeleton />)
    expect(first(container).tagName).toBe('DIV')
    expect(first(container)).toHaveAttribute('data-slot', 'skeleton')
  })

  it('skeleton-002 applies pulse animation, rounded corners and surface background classes', () => {
    const { container } = render(<Skeleton />)
    expect(first(container)).toHaveClass('animate-pulse', 'rounded-md', 'bg-apt-surface-2')
  })

  it('skeleton-003 custom sizing classes merge with the built-in styling', () => {
    const { container } = render(<Skeleton className="w-12 h-12" />)
    expect(first(container)).toHaveClass('w-12', 'h-12', 'animate-pulse', 'rounded-md')
  })

  it('skeleton-004 forwards id and data-testid', () => {
    const { container } = render(<Skeleton id="loader" data-testid="skeleton-1" />)
    expect(first(container)).toHaveAttribute('id', 'loader')
    expect(first(container)).toHaveAttribute('data-testid', 'skeleton-1')
  })

  it('skeleton-005 forwards inline style', () => {
    const { container } = render(<Skeleton style={{ width: '100px', height: '100px' }} />)
    expect(first(container)).toHaveStyle({ width: '100px', height: '100px' })
  })

  it.skip('skeleton-006 pulse keyframes cycle opacity 1 -> 0.5 -> 1 (jsdom does not load Tailwind keyframes)', () => {})

  it.skip('skeleton-007 motion-reduce:animate-none yields animation-name none (jsdom has no media-query/CSS resolution)', () => {})

  it('skeleton-008 aria-hidden is forwarded inside an aria-busy parent', () => {
    const { container } = render(
      <div aria-busy="true"><Skeleton aria-hidden="true" /></div>,
    )
    expect(first(container)).toHaveAttribute('aria-busy', 'true')
    expect(first(first(container))).toHaveAttribute('aria-hidden', 'true')
  })

  it('skeleton-009 empty, undefined and unrecognised className all render with base styling', () => {
    const a = render(<Skeleton className="" />)
    const b = render(<Skeleton className={undefined} />)
    const c = render(<Skeleton className="no-such-class" />)
    for (const r of [a, b, c]) {
      expect(first(r.container)).toHaveClass('animate-pulse', 'rounded-md', 'bg-apt-surface-2')
    }
    expect(first(c.container)).toHaveClass('no-such-class')
  })
})
