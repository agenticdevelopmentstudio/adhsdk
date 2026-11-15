/**
 * `TextBubble` / `useTextBubble` conformance vectors (T1 .. T14).
 *
 * jsdom does no layout, so `offsetLeft`/`offsetWidth` are stubbed to put each glyph span on a
 * 10px grid (centre = 10 * index + 5, all on one line). Timers (including rAF and the
 * performance clock) are faked so the sweep can be stepped deterministically.
 */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, cleanup, act } from '@testing-library/react'
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

import { TextBubble } from '../components/text-bubble'

const SPACING = 10

function glyphIndex(el: HTMLElement): number {
  // glyph -> word -> visual copy -> host
  const host = el.parentElement?.parentElement?.parentElement
  if (!host) return 0
  return Array.from(host.querySelectorAll('[aria-hidden="true"] span span')).indexOf(el)
}

beforeEach(() => {
  vi.useFakeTimers({ toFake: ['requestAnimationFrame', 'cancelAnimationFrame', 'performance', 'setTimeout', 'clearTimeout'] })
  vi.spyOn(HTMLElement.prototype, 'offsetLeft', 'get').mockImplementation(function (this: HTMLElement) {
    return Math.max(glyphIndex(this), 0) * SPACING
  })
  vi.spyOn(HTMLElement.prototype, 'offsetTop', 'get').mockReturnValue(0)
  vi.spyOn(HTMLElement.prototype, 'offsetWidth', 'get').mockReturnValue(SPACING)
  vi.spyOn(HTMLElement.prototype, 'offsetHeight', 'get').mockReturnValue(SPACING)
})

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
  vi.useRealTimers()
})

function advance(ms: number): void {
  act(() => {
    vi.advanceTimersByTime(ms)
  })
}

function host(container: HTMLElement): HTMLElement {
  return container.firstElementChild as HTMLElement
}

function glyphs(h: HTMLElement): HTMLElement[] {
  return Array.from(h.querySelectorAll<HTMLElement>('[aria-hidden="true"] span span'))
}

/** Index of the glyph under the lens centre (largest scale), or -1 when nothing is transformed. */
function lensIndex(h: HTMLElement): number {
  let best = -1
  let bestScale = 1
  glyphs(h).forEach((g, i) => {
    const m = /scale\(([\d.]+)\)/.exec(g.style.transform)
    if (m && Number(m[1]) > bestScale) {
      bestScale = Number(m[1])
      best = i
    }
  })
  return best
}

describe('TextBubble', () => {
  it('T1 render-plain-text + decorative-when-inactive: inactive renders plain text, no glyph spans', () => {
    const { container } = render(<TextBubble text="Hello world" active={false} />)
    const h = host(container)
    advance(1000)
    expect(h.textContent).toBe('Hello world')
    expect(h.querySelectorAll('span')).toHaveLength(0)
  })

  it('T2 animate-lens-when-active: active builds per-glyph spans and transforms some', () => {
    const { container } = render(<TextBubble text="Hello world" active radius={30} />)
    const h = host(container)
    advance(100)
    const gs = glyphs(h)
    expect(gs.length).toBe('Helloworld'.length)
    expect(gs.some((g) => g.style.transform !== '')).toBe(true)
  })

  it.skip('T3 scale-and-blur-under-lens: needs real rendering over frames (Playwright)', () => {})

  it('T4 color-shift-under-lens: an in-lens glyph carries an inline color-mix colour', () => {
    const { container } = render(
      <TextBubble text="Hello" active colorFrom="red" colorTo="blue" radius={30} />,
    )
    advance(100)
    const lens = glyphs(host(container))[lensIndex(host(container))]
    expect(lens).toBeDefined()
    expect(lens!.style.color).toContain('color-mix')
  })

  it('T5 preserve-accessible-text: an off-screen span holds the full string; visible copy is aria-hidden', () => {
    const { container } = render(<TextBubble text="Hello world" active />)
    advance(50)
    const h = host(container)
    const sr = h.firstElementChild as HTMLElement
    expect(sr.textContent).toBe('Hello world')
    expect(sr.style.position).toBe('absolute')
    const visual = h.querySelector('[aria-hidden="true"]')
    expect(visual).not.toBeNull()
    expect(visual).not.toBe(sr)
  })

  it('T6 restore-on-cleanup: deactivating and unmounting both restore the plain text', () => {
    const { container, rerender, unmount } = render(<TextBubble text="Hello world" active />)
    advance(100)
    const h = host(container)
    expect(h.querySelectorAll('span').length).toBeGreaterThan(0)
    rerender(<TextBubble text="Hello world" active={false} />)
    expect(host(container).textContent).toBe('Hello world')
    expect(host(container).querySelectorAll('span')).toHaveLength(0)

    rerender(<TextBubble text="Hello world" active />)
    advance(100)
    const h2 = host(container)
    expect(h2.querySelectorAll('span').length).toBeGreaterThan(0)
    unmount()
    expect(h2.textContent).toBe('Hello world')
    expect(h2.querySelectorAll('span')).toHaveLength(0)
  })

  it('T7 skip-cursive-scripts: Arabic text is left unchanged with no per-character spans', () => {
    const text = 'مرحبا بالعالم'
    const { container } = render(<TextBubble text={text} active />)
    advance(200)
    const h = host(container)
    expect(h.textContent).toBe(text)
    expect(h.querySelectorAll('span')).toHaveLength(0)
  })

  it('T8 not-break-words-at-wrap: each word is wrapped in an inline-block nowrap span', () => {
    const { container } = render(<TextBubble text="one two three" active />)
    advance(50)
    const words = (host(container).querySelector('[aria-hidden="true"]') as HTMLElement).children
    expect(words).toHaveLength(3)
    for (const w of Array.from(words) as HTMLElement[]) {
      expect(w.style.display).toBe('inline-block')
      expect(w.style.whiteSpace).toBe('nowrap')
    }
  })

  it('T9 follow-text-direction: the lens starts at the first glyph for ltr and the last for rtl', () => {
    const ltr = render(<TextBubble text="abc" active radius={5} style={{ direction: 'ltr' }} />)
    advance(20)
    expect(lensIndex(host(ltr.container))).toBe(0)
    cleanup()

    const rtl = render(<TextBubble text="abc" active radius={5} style={{ direction: 'rtl' }} />)
    advance(20)
    expect(lensIndex(host(rtl.container))).toBe(2)
  })

  it.skip('T10 remeasure-on-resize: needs real layout and a real ResizeObserver (Playwright)', () => {})

  it('T11 noop-on-empty-text: empty or whitespace text builds no spans', () => {
    const { container } = render(<TextBubble text="   " active />)
    advance(500)
    const h = host(container)
    expect(h.textContent).toBe('   ')
    expect(h.querySelectorAll('span')).toHaveLength(0)
  })

  it('T12 idle-hold-before-sweep: glyphs are plain for pauseMs, then the sweep begins; pauseMs 0 starts at once', () => {
    const held = render(<TextBubble text="abc" active radius={30} pauseMs={500} />)
    advance(400)
    expect(glyphs(host(held.container)).every((g) => g.style.transform === '')).toBe(true)
    advance(300)
    expect(lensIndex(host(held.container))).toBeGreaterThanOrEqual(0)
    cleanup()

    const immediate = render(<TextBubble text="abc" active radius={30} pauseMs={0} />)
    advance(20)
    expect(lensIndex(host(immediate.container))).toBeGreaterThanOrEqual(0)
  })

  it('T13 sweep-duration: 3 chars sweep over the 4500ms floor; 200 chars over 200 x 48 = 9600ms', () => {
    const short = render(<TextBubble text="abc" active radius={5} />)
    // At 1000ms a 4500ms sweep is 22% along (glyph 0); a 144ms sweep would have looped to glyph 2.
    advance(1000)
    expect(lensIndex(host(short.container))).toBe(0)
    cleanup()

    const long = render(<TextBubble text={'x'.repeat(200)} active radius={5} />)
    // At 2400ms a 9600ms sweep is 25% along (~glyph 50); a 4500ms floor would put it near glyph 106.
    advance(2400)
    const i = lensIndex(host(long.container))
    expect(i).toBeGreaterThanOrEqual(46)
    expect(i).toBeLessThanOrEqual(54)
  })

  it('T14 splitting unit: one span per code point', () => {
    const { container } = render(<TextBubble text={'é \u{1F468}‍\u{1F469}'} active />)
    advance(50)
    const gs = glyphs(host(container)).map((g) => g.textContent)
    expect(gs).toEqual(['e', '́', '\u{1F468}', '‍', '\u{1F469}'])
  })
})
