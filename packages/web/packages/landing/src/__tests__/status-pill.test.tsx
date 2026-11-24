import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { afterEach, describe, expect, it } from 'vitest'
import { render } from '@testing-library/react'
import { StatusPill } from '../index'

const css = readFileSync(resolve(__dirname, '../css/blocks.css'), 'utf8')

afterEach(() => {
  document.head.querySelectorAll('style').forEach((s) => s.remove())
})

describe('StatusPill conformance vectors', () => {
  it('status-pill-001 accept-children: renders its text', () => {
    const { container } = render(<StatusPill>Active</StatusPill>)
    expect(container.firstElementChild!.textContent).toBe('Active')
  })

  it('status-pill-002 base-style: root has lp-status', () => {
    const { container } = render(<StatusPill>Free</StatusPill>)
    expect(container.firstElementChild!.classList.contains('lp-status')).toBe(true)
  })

  it('status-pill-003 accent-style: free adds lp-status--free, whose rule sets border and background', () => {
    const { container } = render(<StatusPill free={true}>Free Plan</StatusPill>)
    const root = container.firstElementChild!
    expect(root.classList.contains('lp-status')).toBe(true)
    expect(root.classList.contains('lp-status--free')).toBe(true)
    const rule = css.match(/\.lp-status\.lp-status--free\s*\{([^}]*)\}/)![1]
    expect(rule).toContain('border-color: var(--lp-status-free-border')
    expect(rule).toContain('background: var(--lp-accent-dim')
  })

  it('status-pill-004 accent-opt-in: default has no lp-status--free', () => {
    const { container } = render(<StatusPill>Standard</StatusPill>)
    expect(container.firstElementChild!.getAttribute('class')).toBe('lp-status')
  })

  it('status-pill-005 accent-opt-in: free={false} has no lp-status--free', () => {
    const { container } = render(<StatusPill free={false}>Standard</StatusPill>)
    expect(container.firstElementChild!.getAttribute('class')).toBe('lp-status')
  })

  it('status-pill-006 status-conveyed-by-text: text reads Free Plan', () => {
    const { container } = render(<StatusPill free={true}>Free Plan</StatusPill>)
    expect(container.firstElementChild!.textContent).toBe('Free Plan')
  })

  it('status-pill-007 base-style: lp-status is white-space: nowrap', () => {
    const style = document.createElement('style')
    style.textContent = css
    document.head.appendChild(style)
    const { container } = render(
      <div style={{ width: '40px' }}>
        <StatusPill>A very long status text</StatusPill>
      </div>,
    )
    expect(getComputedStyle(container.querySelector('.lp-status')!).whiteSpace).toBe('nowrap')
  })
})
