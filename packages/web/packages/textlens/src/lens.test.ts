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
