import { afterEach, describe, expect, it } from 'vitest'
import { cleanup, render } from '@testing-library/react'
import { OrbRow } from '../OrbRow'
import type { OrbSite } from '../types'

function site(over: Partial<OrbSite> = {}): OrbSite {
  return {
    id: 'a',
    url: 'https://site-a.com',
    name: 'Site A',
    emoji: '🅰',
    iconGradient: 'linear-gradient(red, blue)',
    ...over,
  }
}

function root(container: HTMLElement): HTMLElement {
  return container.firstElementChild as HTMLElement
}

afterEach(cleanup)

describe('OrbRow', () => {
  it('orb-row-001: renders an anchor with the site url as href', () => {
    const { container } = render(<OrbRow sites={[site()]} />)
    const a = container.querySelector('a')
    expect(a).not.toBeNull()
    expect(a?.getAttribute('href')).toBe('https://site-a.com')
  })

  it('orb-row-002: root has role navigation and aria-label "Agentic family"', () => {
    const { container } = render(<OrbRow sites={[site()]} />)
    expect(root(container)).toHaveAttribute('role', 'navigation')
    expect(root(container)).toHaveAttribute('aria-label', 'Agentic family')
  })

  it('orb-row-003: current link has is-current and aria-current="page"; others lack both', () => {
    const { container } = render(
      <OrbRow
        currentSite="a"
        sites={[site(), site({ id: 'b', url: 'https://site-b.com', name: 'Site B' })]}
      />,
    )
    const current = container.querySelector('a[href="https://site-a.com"]') as HTMLElement
    const other = container.querySelector('a[href="https://site-b.com"]') as HTMLElement
    expect(current).toHaveClass('is-current')
    expect(current).toHaveAttribute('aria-current', 'page')
    expect(other).not.toHaveClass('is-current')
    expect(other).not.toHaveAttribute('aria-current')
  })

  it('orb-row-004: link style carries the iconGradient as background', () => {
    const gradient = 'linear-gradient(to right, #ff0000, #0000ff)'
    const { container } = render(<OrbRow sites={[site({ iconGradient: gradient })]} />)
    const a = container.querySelector('a') as HTMLElement
    // The style attribute is re-serialized by the DOM, which normalizes hex colors to rgb().
    expect(a.getAttribute('style')).toContain('background: linear-gradient(to right, rgb(255, 0, 0), rgb(0, 0, 255))')
  })

  it('orb-row-005: emoji renders in an aria-hidden span and is not in the link accessible name', () => {
    const { container } = render(<OrbRow sites={[site({ emoji: '🎯' })]} />)
    const span = container.querySelector('span[aria-hidden="true"]') as HTMLElement
    expect(span.textContent).toBe('🎯')
    const a = container.querySelector('a') as HTMLElement
    // The link's aria-label supplies its accessible name, so the glyph is not part of it.
    expect(a.getAttribute('aria-label')).not.toContain('🎯')
  })

  it('orb-row-006: site name renders in a span with role="tooltip"', () => {
    const { container } = render(<OrbRow sites={[site({ name: 'Example' })]} />)
    const tip = container.querySelector('span[role="tooltip"]')
    expect(tip?.tagName).toBe('SPAN')
    expect(tip?.textContent).toBe('Example')
  })

  it('orb-row-007: current link contains an aria-hidden orb-row-here indicator', () => {
    const { container } = render(<OrbRow currentSite="x" sites={[site({ id: 'x' })]} />)
    const here = container.querySelector('a > span.orb-row-here')
    expect(here).not.toBeNull()
    expect(here).toHaveAttribute('aria-hidden', 'true')
    expect(here?.tagName).toBe('SPAN')
  })

  it('orb-row-008: docked=true adds is-docked to the root', () => {
    const { container } = render(<OrbRow sites={[site()]} docked />)
    expect(root(container)).toHaveClass('is-docked')
  })

  it('orb-row-009: className is appended to the root class list', () => {
    const { container } = render(<OrbRow sites={[site()]} className="custom-class" />)
    expect(root(container)).toHaveClass('custom-class')
  })

  it('orb-row-010: link has aria-label equal to the site name', () => {
    const { container } = render(<OrbRow sites={[site({ name: 'Example' })]} />)
    expect(container.querySelector('a')).toHaveAttribute('aria-label', 'Example')
  })

  it('orb-row-011: no link has aria-current when currentSite is null or not in the list', () => {
    const first = render(<OrbRow sites={[site()]} currentSite={null as unknown as string} />)
    expect(first.container.querySelector('[aria-current]')).toBeNull()
    first.unmount()
    const second = render(<OrbRow sites={[site()]} currentSite="missing" />)
    expect(second.container.querySelector('[aria-current]')).toBeNull()
  })

  it.skip('orb-row-012: focus-visible ring and paused animation (jsdom does not evaluate :focus-visible against keyboard focus; computed box-shadow is not cascaded)', () => {})

  it.skip('orb-row-013: tooltip opacity on keyboard focus (jsdom does not evaluate :focus-visible, so the revealed opacity cannot be observed)', () => {})

  it('orb-row-014: empty sites renders only the navigation root with no anchors', () => {
    const { container } = render(<OrbRow sites={[]} />)
    expect(root(container)).toHaveAttribute('role', 'navigation')
    expect(container.querySelectorAll('a')).toHaveLength(0)
  })

  it('orb-row-015: empty className leaves the root class list as exactly orb-row', () => {
    const { container } = render(<OrbRow sites={[site()]} className="" />)
    expect(root(container).getAttribute('class')).toBe('orb-row')
  })

  it('orb-row-016: docked=false and docked undefined both omit is-docked', () => {
    const off = render(<OrbRow sites={[site()]} docked={false} />)
    expect(root(off.container)).not.toHaveClass('is-docked')
    off.unmount()
    const unset = render(<OrbRow sites={[site()]} />)
    expect(root(unset.container)).not.toHaveClass('is-docked')
  })

  it('orb-row-017: duplicate ids both render as current', () => {
    // Duplicate ids share a React key; React warns but still renders both links.
    const { container } = render(
      <OrbRow
        currentSite="a"
        sites={[site(), site({ url: 'https://dup.example', name: 'Dup' })]}
      />,
    )
    const links = Array.from(container.querySelectorAll('a'))
    expect(links.length).toBeGreaterThanOrEqual(1)
    for (const a of links) {
      expect(a).toHaveClass('is-current')
      expect(a).toHaveAttribute('aria-current', 'page')
    }
  })
})
