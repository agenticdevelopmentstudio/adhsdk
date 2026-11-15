import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { render, cleanup } from '@testing-library/react'
import { ViewportShell } from '../ViewportShell'

const baseCss = readFileSync(resolve(__dirname, '../css/base.css'), 'utf8')

interface FakeVV {
  height: number
  offsetTop: number
  addEventListener: ReturnType<typeof vi.fn>
  removeEventListener: ReturnType<typeof vi.fn>
  fire: (type: string) => void
}

/** A minimal window.visualViewport that records listeners and can fire them. */
function installVisualViewport(height: number, offsetTop = 0): FakeVV {
  const listeners = new Map<string, Set<() => void>>()
  const vv: FakeVV = {
    height,
    offsetTop,
    addEventListener: vi.fn((type: string, fn: () => void) => {
      if (!listeners.has(type)) listeners.set(type, new Set())
      listeners.get(type)!.add(fn)
    }),
    removeEventListener: vi.fn((type: string, fn: () => void) => {
      listeners.get(type)?.delete(fn)
    }),
    fire: (type) => listeners.get(type)?.forEach((fn) => fn()),
  }
  Object.defineProperty(window, 'visualViewport', { value: vv, configurable: true, writable: true })
  return vv
}

function loadBaseCss(): HTMLStyleElement {
  const style = document.createElement('style')
  style.textContent = baseCss
  document.head.append(style)
  return style
}

const root = (container: HTMLElement): HTMLElement => container.firstElementChild as HTMLElement

beforeEach(() => {
  vi.spyOn(window, 'innerHeight', 'get').mockReturnValue(800)
  installVisualViewport(800)
})

afterEach(() => {
  cleanup()
  document.documentElement.removeAttribute('style')
  document.body.removeAttribute('style')
  document.head.querySelectorAll('style').forEach((s) => s.remove())
  Reflect.deleteProperty(window, 'visualViewport')
  vi.restoreAllMocks()
})

describe('ViewportShell', () => {
  it('viewport-001: renders children inside the shell', () => {
    const { container, getByText } = render(
      <ViewportShell>
        <div>Content</div>
      </ViewportShell>,
    )
    expect(getByText('Content').parentElement).toBe(root(container))
  })

  it('viewport-002: root element has class viewport-shell', () => {
    const { container } = render(<ViewportShell>{null}</ViewportShell>)
    expect(root(container).classList.contains('viewport-shell')).toBe(true)
  })

  it('viewport-003: clip={false} adds vp-shell--open and computed overflow is visible', () => {
    loadBaseCss()
    const { container } = render(<ViewportShell clip={false}>{null}</ViewportShell>)
    const el = root(container)
    expect(el.className).toBe('viewport-shell vp-shell--open')
    expect(getComputedStyle(el).overflow).toBe('visible')
  })

  it('viewport-004: className is appended to the root class list', () => {
    const { container } = render(<ViewportShell className="custom-class">{null}</ViewportShell>)
    expect(root(container).className).toBe('viewport-shell custom-class')
  })

  it('viewport-005: an empty className is not added', () => {
    const { container } = render(<ViewportShell className="">{null}</ViewportShell>)
    expect(root(container).className).toBe('viewport-shell')
  })

  it('viewport-013: a whitespace-only className is kept verbatim, not trimmed or filtered', () => {
    const { container } = render(<ViewportShell className="  ">{null}</ViewportShell>)
    expect(root(container).getAttribute('class')).toBe('viewport-shell   ')
  })

  it('viewport-006: clip defaults to true, no vp-shell--open, computed overflow is hidden', () => {
    loadBaseCss()
    const { container } = render(<ViewportShell>{null}</ViewportShell>)
    const el = root(container)
    expect(el.classList.contains('vp-shell--open')).toBe(false)
    expect(getComputedStyle(el).overflow).toBe('hidden')
  })

  it('viewport-007: a visualViewport resize writes --kb-inset from the viewport difference', () => {
    const vv = installVisualViewport(800, 0)
    render(<ViewportShell>{null}</ViewportShell>)
    vv.height = 500 // innerHeight 800 - 500 - 0 = 300
    vv.fire('resize')
    expect(document.documentElement.style.getPropertyValue('--kb-inset')).toBe('300px')
  })

  it('viewport-008: base.css locks html and body; the component sets no inline overflow', () => {
    loadBaseCss()
    render(<ViewportShell>{null}</ViewportShell>)
    expect(getComputedStyle(document.documentElement).overflow).toBe('hidden')
    expect(getComputedStyle(document.body).overflow).toBe('hidden')
    expect(document.documentElement.style.overflow).toBe('')
    expect(document.body.style.overflow).toBe('')
  })

  it('viewport-009: mounting and unmounting several shells never writes inline overflow', () => {
    const a = render(<ViewportShell>{null}</ViewportShell>)
    const b = render(<ViewportShell>{null}</ViewportShell>)
    expect(document.documentElement.style.overflow).toBe('')
    expect(document.body.style.overflow).toBe('')
    a.unmount()
    expect(document.documentElement.style.overflow).toBe('')
    expect(document.body.style.overflow).toBe('')
    b.unmount()
  })

  it('viewport-010: null children render an empty root', () => {
    const { container } = render(<ViewportShell>{null}</ViewportShell>)
    expect(root(container).childNodes.length).toBe(0)
  })

  it('viewport-011: an empty array of children renders no child elements', () => {
    const { container } = render(<ViewportShell>{[]}</ViewportShell>)
    expect(root(container).children.length).toBe(0)
  })

  it('viewport-012: multiple children render as siblings in order', () => {
    const { container } = render(
      <ViewportShell>
        <span>A</span>
        <span>B</span>
      </ViewportShell>,
    )
    const kids = Array.from(root(container).children)
    expect(kids.map((k) => k.textContent)).toEqual(['A', 'B'])
  })

  it('viewport-014: toggling clip updates classes and overflow without remounting children', () => {
    loadBaseCss()
    const child = <span data-testid="kid">x</span>
    const { container, getByTestId, rerender } = render(<ViewportShell clip={true}>{child}</ViewportShell>)
    const kid = getByTestId('kid')
    const el = root(container)
    expect(getComputedStyle(el).overflow).toBe('hidden')

    rerender(<ViewportShell clip={false}>{child}</ViewportShell>)
    expect(root(container)).toBe(el)
    expect(el.classList.contains('vp-shell--open')).toBe(true)
    expect(getComputedStyle(el).overflow).toBe('visible')
    expect(getByTestId('kid')).toBe(kid)

    rerender(<ViewportShell clip={true}>{child}</ViewportShell>)
    expect(el.classList.contains('vp-shell--open')).toBe(false)
    expect(getComputedStyle(el).overflow).toBe('hidden')
    expect(getByTestId('kid')).toBe(kid)
  })

  it('viewport-015: --kb-inset is written as 0px on mount before any event', () => {
    installVisualViewport(800)
    render(<ViewportShell>{null}</ViewportShell>)
    expect(document.documentElement.style.getPropertyValue('--kb-inset')).toBe('0px')
  })

  it('viewport-016: --kb-inset never goes negative', () => {
    const vv = installVisualViewport(800, 0)
    render(<ViewportShell>{null}</ViewportShell>)
    vv.offsetTop = 50 // height + offsetTop > innerHeight
    vv.fire('resize')
    expect(document.documentElement.style.getPropertyValue('--kb-inset')).toBe('0px')
  })

  it('viewport-017: without visualViewport the shell mounts and --kb-inset is not written', () => {
    Object.defineProperty(window, 'visualViewport', { value: undefined, configurable: true, writable: true })
    expect(() => render(<ViewportShell>{null}</ViewportShell>)).not.toThrow()
    expect(document.documentElement.style.getPropertyValue('--kb-inset')).toBe('')
  })

  it('viewport-018: unmount removes both listeners and leaves --kb-inset in place', () => {
    const vv = installVisualViewport(800, 0)
    const { unmount } = render(<ViewportShell>{null}</ViewportShell>)
    vv.height = 500
    vv.fire('resize')
    expect(document.documentElement.style.getPropertyValue('--kb-inset')).toBe('300px')
    unmount()
    const removed = vv.removeEventListener.mock.calls.map((c) => c[0]).sort()
    expect(removed).toEqual(['resize', 'scroll'])
    expect(document.documentElement.style.getPropertyValue('--kb-inset')).toBe('300px')
  })
})
