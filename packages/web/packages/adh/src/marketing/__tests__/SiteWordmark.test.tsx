/// <reference types="@testing-library/jest-dom/vitest" />
import { render, cleanup } from '@testing-library/react'
import { describe, it, expect, afterEach } from 'vitest'
import type { SiteId } from '@adh-sdk/adh-registry'

import { SiteWordmark } from '../SiteWordmark'

// Conformance vectors T1-T7 (cookbook/adh/sites/site-wordmark/conformance-test-vectors.md).
// This package's vitest config has no auto-cleanup setup file, so tear each render down.
afterEach(cleanup)

/** The brand line (first <p>) and the identity line (second <p>, when present). */
function lines(container: HTMLElement) {
  const ps = container.querySelectorAll('p')
  return { brand: ps[0] as HTMLElement, identity: ps[1] as HTMLElement | undefined, count: ps.length }
}

describe('SiteWordmark', () => {
  it('T1 renders the Agentic Developer lead and a gold italic Research accent', () => {
    const { container } = render(<SiteWordmark siteId="research" />)
    const { brand } = lines(container)
    expect(brand.textContent).toBe('Agentic Developer Research')
    const accent = brand.querySelector('span > span') as HTMLElement
    expect(accent).toHaveTextContent('Research')
    expect(accent).toHaveClass('text-apt-gold', 'italic')
  })

  it('T2 defaults the identity line to the registry description', () => {
    const { container } = render(<SiteWordmark siteId="research" />)
    expect(lines(container).identity).toHaveTextContent('Store & review research')
  })

  it('T3 honors an explicit tagline', () => {
    const { container } = render(<SiteWordmark siteId="research" tagline="Published research" />)
    expect(lines(container).identity).toHaveTextContent('Published research')
  })

  it('T4 omits the identity line when the tagline is null', () => {
    const { container } = render(<SiteWordmark siteId="research" tagline={null} />)
    expect(lines(container).count).toBe(1)
  })

  it('T5 falls back to the raw identifier as the accent for an unknown site', () => {
    const { container } = render(<SiteWordmark siteId={'not-a-real-site' as SiteId} />)
    const { brand, count } = lines(container)
    expect(brand.textContent).toBe('not-a-real-site')
    expect(brand.querySelector('span > span')).toHaveTextContent('not-a-real-site')
    expect(count).toBe(1)
  })

  it('T6 renders the whole Bitbag label as the accent with no lead', () => {
    const { container } = render(<SiteWordmark siteId="bitbag" />)
    const { brand, identity } = lines(container)
    expect(brand.textContent).toBe('Bitbag')
    expect(brand.textContent).not.toMatch(/^Agentic Developer /)
    expect(brand.querySelector('span > span')).toHaveTextContent('Bitbag')
    expect(identity).toHaveTextContent('The Agentic Developer persona')
  })

  it('T7 omits the identity line when the tagline is an empty string', () => {
    const { container } = render(<SiteWordmark siteId="research" tagline="" />)
    expect(lines(container).count).toBe(1)
  })
})
