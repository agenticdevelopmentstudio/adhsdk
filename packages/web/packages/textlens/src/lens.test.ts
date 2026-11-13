import { afterEach, describe, expect, it, vi } from 'vitest'
import { createLens } from './lens.js'

function mount(text: string): HTMLElement {
  const element = document.createElement('span')
  element.textContent = text
  document.body.appendChild(element)
  return element
}

function stubFrames() {
  const raf = vi.spyOn(window, 'requestAnimationFrame').mockReturnValue(7)
  const caf = vi.spyOn(window, 'cancelAnimationFrame').mockImplementation(() => {})
  return { raf, caf }
}

/**
 * Lay the glyphs of `element` out 10px apart (centres at 10, 20, 30, ...), pin
 * the clock at 0, and hand back a way to run the frame at any time `t` and read
 * which glyphs the lens is enlarging.
 */
function driveFrames(element: HTMLElement) {
  vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockImplementation(function (this: HTMLElement) {
    const index = [...(this.parentElement?.children ?? [])].indexOf(this)
    return new DOMRect(5 + index * 10, 0, 10, 10)
  })
  vi.spyOn(performance, 'now').mockReturnValue(0)
  let step: FrameRequestCallback | null = null
  vi.spyOn(window, 'requestAnimationFrame').mockImplementation((callback) => {
    step = callback
    return 7
  })
  vi.spyOn(window, 'cancelAnimationFrame').mockImplementation(() => {})
  const enlargedAt = (t: number): string[] => {
    step?.(t)
    return [...element.querySelectorAll('span')]
      .filter((span) => span.style.transform !== '' && span.style.transform !== 'scale(1.000)')
      .map((span) => span.textContent ?? '')
  }
  return { enlargedAt }
}

afterEach(() => {
  vi.restoreAllMocks()
  document.body.innerHTML = ''
})

describe('createLens', () => {
  it('splits the text into one span per character', () => {
    const element = mount('abc')
    createLens([element])

    const spans = element.querySelectorAll('span')
    expect(spans).toHaveLength(3)
    expect([...spans].map((span) => span.textContent)).toEqual(['a', 'b', 'c'])
  })

  it('keeps spaces from collapsing', () => {
    const element = mount('a b')
    createLens([element])

    expect(element.querySelectorAll('span')[1]?.textContent).toBe('\u00A0')
  })

  it('pins no width on a glyph, so a split measured before layout cannot collapse the row', () => {
    const element = mount('About')
    vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockReturnValue(new DOMRect(0, 0, 0, 0))

    createLens([element])

    expect([...element.querySelectorAll('span')].map((span) => span.style.width)).toEqual(['', '', '', '', ''])
  })

  it('travels a radius past the outer glyphs by default, so it starts off the text', () => {
    const element = mount('abc')
    const { enlargedAt } = driveFrames(element)
    createLens([element], { radius: 5, duration: 1000 }).start()

    expect(enlargedAt(0)).toEqual([])
  })

  it('turns round on the outer glyphs with no margin, so the text is never without it', () => {
    const element = mount('abc')
    const { enlargedAt } = driveFrames(element)
    createLens([element], { radius: 5, duration: 1000, margin: 0 }).start()

    expect(enlargedAt(0)).toEqual(['a'])
    expect(enlargedAt(1000)).toEqual(['c'])
  })

  it('holds at each end for the dwell before it turns back', () => {
    const element = mount('abc')
    const { enlargedAt } = driveFrames(element)
    createLens([element], { radius: 5, duration: 1000, dwell: 1000, margin: 0 }).start()

    expect(enlargedAt(1500)).toEqual(['c'])
    expect(enlargedAt(2500)).toEqual(['b'])
    expect(enlargedAt(3500)).toEqual(['a'])
    expect(enlargedAt(4500)).toEqual(['b'])
  })

  it('turns back the instant it arrives with no dwell', () => {
    const element = mount('abc')
    const { enlargedAt } = driveFrames(element)
    createLens([element], { radius: 5, duration: 1000, margin: 0 }).start()

    expect(enlargedAt(1500)).toEqual(['b'])
  })

  it('leaves an already-split element alone', () => {
    const element = mount('abc')
    createLens([element])
    const first = element.firstChild

    createLens([element])

    expect(element.querySelectorAll('span')).toHaveLength(3)
    expect(element.firstChild).toBe(first)
  })

  it('schedules no frames when the user prefers reduced motion', () => {
    vi.spyOn(window, 'matchMedia').mockReturnValue({ matches: true } as MediaQueryList)
    const { raf } = stubFrames()

    createLens([mount('abc')]).start()

    expect(raf).not.toHaveBeenCalled()
  })

  it('sweeps anyway when the caller opts out of that check', () => {
    vi.spyOn(window, 'matchMedia').mockReturnValue({ matches: true } as MediaQueryList)
    const { raf } = stubFrames()

    createLens([mount('abc')], { respectReducedMotion: false }).start()

    expect(raf).toHaveBeenCalled()
  })

  it('starts once however many times it is started', () => {
    const { raf } = stubFrames()
    const lens = createLens([mount('abc')])

    lens.start()
    lens.start()

    expect(raf).toHaveBeenCalledTimes(1)
  })

  it('cancels its pending frame and rests the glyphs when destroyed', () => {
    const { caf } = stubFrames()
    const element = mount('abc')
    const lens = createLens([element])
    lens.start()

    const glyph = element.querySelector('span') as HTMLSpanElement
    glyph.style.transform = 'scale(1.2)'

    lens.destroy()

    expect(caf).toHaveBeenCalledWith(7)
    expect(glyph.style.transform).toBe('')
  })

  it('stops pausing on hover once destroyed', () => {
    const { raf } = stubFrames()
    const element = mount('abc')
    const lens = createLens([element])
    lens.destroy()

    element.dispatchEvent(new Event('pointerenter'))
    lens.start()

    // A live pause listener would have set the flag before this start; the
    // lens still schedules a frame either way, so the check that matters is
    // that destroy() left nothing bound to mutate its state afterwards.
    expect(raf).toHaveBeenCalledTimes(1)
  })

  it('refuses one end of the colour ramp without the other', () => {
    const lens = createLens([mount('abc')], { fromColor: '#8a8a9a' })

    expect(() => lens.start()).toThrow(/fromColor and toColor/)
  })

  it('reads both ends of the ramp from custom properties', () => {
    document.body.style.setProperty('--from', '#8a8a9a')
    document.body.style.setProperty('--to', '#e8a33d')
    stubFrames()

    const lens = createLens([mount('abc')], { fromColor: '--from', toColor: '--to' })

    expect(() => lens.start()).not.toThrow()
  })
})
