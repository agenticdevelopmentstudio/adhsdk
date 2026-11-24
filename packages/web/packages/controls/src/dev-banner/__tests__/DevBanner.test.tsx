import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { afterEach, describe, expect, it } from 'vitest'
import { cleanup, render } from '@testing-library/react'
import { DevBanner } from '../DevBanner'

const CSS = readFileSync(
  join(dirname(fileURLToPath(import.meta.url)), '../styles/dev-banner.css'),
  'utf8',
)

function root(container: HTMLElement): HTMLElement {
  return container.firstElementChild as HTMLElement
}

afterEach(() => {
  cleanup()
  document.head.querySelectorAll('style').forEach((s) => s.remove())
})

describe('DevBanner', () => {
  it('dev-banner-001: renders the provided message', () => {
    const { container } = render(<DevBanner message="Custom Alert" />)
    expect(root(container).textContent).toBe('Custom Alert')
  })

  it('dev-banner-002: renders the default message when message is undefined', () => {
    const { container } = render(<DevBanner />)
    expect(root(container).textContent).toBe('Development Preview — Coming Soon!')
  })

  it('dev-banner-003: position="fixed" adds awt-dev-banner--fixed', () => {
    const { container } = render(<DevBanner position="fixed" />)
    expect(root(container)).toHaveClass('awt-dev-banner--fixed')
  })

  it('dev-banner-004: position="static" adds awt-dev-banner--static', () => {
    const { container } = render(<DevBanner position="static" />)
    expect(root(container)).toHaveClass('awt-dev-banner--static')
  })

  it('dev-banner-005: defaults to the fixed position class', () => {
    const { container } = render(<DevBanner />)
    expect(root(container)).toHaveClass('awt-dev-banner--fixed')
  })

  it('dev-banner-006: className is included in the class list', () => {
    const { container } = render(<DevBanner className="my-custom-class" />)
    expect(root(container)).toHaveClass('my-custom-class')
  })

  it('dev-banner-007: empty className adds no empty class token', () => {
    const { container } = render(<DevBanner className="" />)
    expect(Array.from(root(container).classList)).toEqual(['awt-dev-banner', 'awt-dev-banner--fixed'])
    expect(root(container).getAttribute('class')).toBe('awt-dev-banner awt-dev-banner--fixed')
  })

  it('dev-banner-008: root has aria-hidden="true"', () => {
    const { container } = render(<DevBanner />)
    expect(root(container)).toHaveAttribute('aria-hidden', 'true')
  })

  it('dev-banner-009: base class sits beside the position class and className', () => {
    const { container } = render(<DevBanner position="static" className="extra" />)
    expect(Array.from(root(container).classList)).toEqual(['awt-dev-banner', 'awt-dev-banner--static', 'extra'])
  })

  it('dev-banner-010: message={null} renders empty and does not use the default', () => {
    const { container } = render(<DevBanner message={null as unknown as string} />)
    expect(root(container).textContent).toBe('')
  })

  it('dev-banner-011: message="" renders no text', () => {
    const { container } = render(<DevBanner message="" />)
    expect(root(container).textContent).toBe('')
  })

  it('dev-banner-012: leading and trailing whitespace in the message is preserved', () => {
    const { container } = render(<DevBanner message="  padded  " />)
    expect(root(container).textContent).toBe('  padded  ')
  })

  it('dev-banner-013: the default stylesheet gives the container pointer-events: none', () => {
    const style = document.createElement('style')
    style.textContent = CSS
    document.head.appendChild(style)
    const { container } = render(<DevBanner />)
    expect(getComputedStyle(root(container)).pointerEvents).toBe('none')
  })

  it('dev-banner-014: an out-of-range position passes through with no fallback to fixed', () => {
    const style = document.createElement('style')
    style.textContent = CSS
    document.head.appendChild(style)
    const { container } = render(<DevBanner position={'sticky' as unknown as 'fixed'} />)
    const el = root(container)
    expect(el).toHaveClass('awt-dev-banner--sticky')
    expect(el).not.toHaveClass('awt-dev-banner--fixed')
    // No rule matches, so neither the fixed positioning nor the static rule's display applies.
    expect(getComputedStyle(el).position).not.toBe('fixed')
    expect(getComputedStyle(el).display).toBe('block')
  })
})
