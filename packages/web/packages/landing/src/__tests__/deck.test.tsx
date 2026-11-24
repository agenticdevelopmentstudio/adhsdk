import { afterEach, describe, expect, it, vi } from 'vitest'
import { render } from '@testing-library/react'
import { renderToString } from 'react-dom/server'
import { Deck, Screen, Wrap, deckScript } from '../index'
import { DeckScript } from '../deck/DeckScript'
import { Glow } from '../deck/Glow'

describe('deckScript', () => {
  it('arms snapping on the first pointer, wheel or key input', () => {
    const s = deckScript()
    expect(s).toContain('pointerdown')
    expect(s).toContain('wheel')
    expect(s).toContain('keydown')
    expect(s).toContain('data-snap')
    expect(s).toContain('once:true')
  })

  it('opens the page at the top', () => {
    expect(deckScript()).toContain('history.scrollRestoration="manual"')
  })

  // The two halves of the easing gate, and the second is the whole point of it:
  // `scroll-behavior: smooth` also governs the browser's scroll RESTORATION, so a
  // deck that only ever SET `data-smooth` would still animate its way back to where
  // the reader already was when they hit Back.
  it('arms easing on first input and disarms it on a history traversal', () => {
    const s = deckScript()
    expect(s).toContain('data-smooth')
    expect(s).toContain('popstate')
  })

  it('drops each half when asked', () => {
    expect(deckScript({ openAtTop: false })).not.toContain('scrollRestoration')
    expect(deckScript({ armSnapping: false })).not.toContain('data-snap')
    expect(deckScript({ armSmooth: false })).not.toContain('data-smooth')
    expect(deckScript({ armSmooth: false })).not.toContain('popstate')
    expect(deckScript({ restoreZoomOffIos: false })).not.toContain('maximum-scale')
  })

  it('emits one statement per enabled part and nothing else', () => {
    expect(
      deckScript({
        openAtTop: false,
        armSnapping: false,
        armSmooth: false,
        restoreZoomOffIos: false,
      }),
    ).toBe('')
  })
})

describe('Screen', () => {
  it('is a <section> that carries the id and the snap class', () => {
    const { container } = render(<Screen id="different">x</Screen>)
    const el = container.querySelector('section')
    expect(el).toBeTruthy()
    expect(el!.id).toBe('different')
    expect(el!.className).toContain('lp-screen')
    expect(el!.className).not.toContain('lp-screen--center')
  })

  it('centres when asked, and can be a div for the hero', () => {
    const { container } = render(<Screen as="div" align="center">x</Screen>)
    const el = container.firstElementChild!
    expect(el.tagName).toBe('DIV')
    expect(el.className).toContain('lp-screen--center')
  })

  it('keeps a caller class alongside its own', () => {
    const { container } = render(<Screen className="lp-hero">x</Screen>)
    expect(container.firstElementChild!.className).toContain('lp-screen')
    expect(container.firstElementChild!.className).toContain('lp-hero')
  })

  it('has no glow unless asked', () => {
    const { container } = render(<Screen>x</Screen>)
    expect(container.querySelector('.lp-glow')).toBeNull()
  })

  // The glow must PRECEDE the content: it is what the content sits in front of,
  // and `z-index: -1` only settles the paint order within the screen's stacking
  // context, not which siblings the host wrote first.
  it('lights the screen from behind its content when asked', () => {
    const { container } = render(<Screen glow><p>x</p></Screen>)
    const el = container.firstElementChild!
    expect(el.firstElementChild!.className).toBe('lp-glow')
    expect(el.firstElementChild!.getAttribute('aria-hidden')).toBe('true')
  })
})

describe('Deck', () => {
  it('is a focusable-but-untabbable div', () => {
    const { container } = render(<Deck><Screen>x</Screen></Deck>)
    const el = container.firstElementChild!
    expect(el.tagName).toBe('DIV')
    expect(el.getAttribute('tabindex')).toBe('-1')
    expect(el.className).toContain('lp-deck')
  })

  // It was a <main>, and every consumer renders it inside a host shell that
  // already draws one — so the deck nested a second landmark inside the first,
  // which is invalid and announces two "main"s to a screen reader. The class is
  // what `base.css` and the chrome are written against, so the element is free
  // to be the neutral one.
  it('renders no landmark of its own, so a host shell keeps the only <main>', () => {
    const { container } = render(<Deck><Screen>x</Screen></Deck>)
    expect(container.querySelector('main')).toBeNull()
  })
})

describe('Wrap', () => {
  it('is the content column', () => {
    const { container } = render(<Wrap>x</Wrap>)
    expect(container.firstElementChild!.className).toContain('lp-wrap')
  })
})

/* ---- deck-script conformance vectors ---- */

const OPEN = 'history.scrollRestoration="manual";'
const SNAP_ONLY = deckScript({ openAtTop: false, armSmooth: false, restoreZoomOffIos: false })
const SMOOTH_ONLY = deckScript({ openAtTop: false, armSnapping: false, restoreZoomOffIos: false })
const ZOOM_ONLY = deckScript({ openAtTop: false, armSnapping: false, armSmooth: false })
const ALL_OFF = { openAtTop: false, armSnapping: false, armSmooth: false, restoreZoomOffIos: false }

/** Listeners the executed script attached to window, so each test can remove them again. */
const attached: Array<[string, any, any]> = []
function run(script: string): void {
  const real = window.addEventListener.bind(window)
  const spy = vi.spyOn(window, 'addEventListener').mockImplementation((t: string, l: any, o?: any) => {
    attached.push([t, l, o])
    real(t, l, o)
  })
  try {
    new Function(script)()
  } finally {
    spy.mockRestore()
  }
}

function stubPlatform(userAgent: string, platform = 'Linux x86_64', maxTouchPoints = 0): void {
  vi.spyOn(navigator, 'userAgent', 'get').mockReturnValue(userAgent)
  vi.spyOn(navigator, 'platform', 'get').mockReturnValue(platform)
  // jsdom has no maxTouchPoints, so there is nothing to spy on; define it and remove it in afterEach.
  Object.defineProperty(navigator, 'maxTouchPoints', { value: maxTouchPoints, configurable: true })
}

const IOS_UA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Safari/604.1'
const DESKTOP_UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120 Safari/537.36'
const VIEWPORT = '<meta name="viewport" content="width=device-width, maximum-scale=1">'

describe('DeckScript conformance', () => {
  afterEach(() => {
    for (const [t, l, o] of attached.splice(0)) window.removeEventListener(t, l, o)
    document.documentElement.removeAttribute('data-snap')
    document.documentElement.removeAttribute('data-smooth')
    document.head.innerHTML = ''
    delete (navigator as unknown as Record<string, unknown>).maxTouchPoints
    vi.restoreAllMocks()
  })

  it('deck-script-001 renders a script element with a non-empty inline body', () => {
    const el = DeckScript({}) as any
    expect(el.type).toBe('script')
    expect(el.props.dangerouslySetInnerHTML.__html.length).toBeGreaterThan(0)
  })

  it('deck-script-002 openAtTop true includes the scrollRestoration statement', () => {
    expect(deckScript({ openAtTop: true })).toContain('history.scrollRestoration="manual"')
  })

  it('deck-script-003 openAtTop false omits scrollRestoration', () => {
    expect(deckScript({ openAtTop: false })).not.toContain('history.scrollRestoration')
  })

  it('deck-script-004 armSnapping true listens to three inputs and sets data-snap', () => {
    const s = deckScript({ armSnapping: true })
    expect(s).toContain('["pointerdown","wheel","keydown"]')
    expect(s).toContain('addEventListener')
    expect(s).toContain('data-snap')
  })

  it('deck-script-005 armSnapping false omits data-snap', () => {
    expect(deckScript({ armSnapping: false })).not.toContain('data-snap')
  })

  it('deck-script-006 armSmooth true sets data-smooth and removes it on popstate', () => {
    const s = deckScript({ armSmooth: true })
    expect(s).toContain('setAttribute("data-smooth"')
    expect(s).toContain('addEventListener("popstate"')
    expect(s).toContain('removeAttribute("data-smooth")')
  })

  it('deck-script-007 armSmooth false omits data-smooth', () => {
    expect(deckScript({ armSmooth: false })).not.toContain('data-smooth')
  })

  it('deck-script-008 restoreZoomOffIos true carries the maximum-scale strip, platform independent', () => {
    const a = deckScript({ restoreZoomOffIos: true })
    expect(a).toContain('maximum-scale')
    expect(a).toContain('meta[name=viewport]')
    stubPlatform(IOS_UA)
    expect(deckScript({ restoreZoomOffIos: true })).toBe(a)
  })

  it('deck-script-009 restoreZoomOffIos false omits the viewport code', () => {
    const s = deckScript({ restoreZoomOffIos: false })
    expect(s).not.toContain('viewport')
    expect(s).not.toContain('maximum-scale')
  })

  it('deck-script-010 a disabled segment is absent and the rest concatenate in order', () => {
    const got = deckScript({ openAtTop: true, armSnapping: false, armSmooth: true, restoreZoomOffIos: true })
    expect(got).toBe(OPEN + SMOOTH_ONLY + ZOOM_ONLY)
  })

  it('deck-script-011 snapping listeners are once and passive', () => {
    expect(deckScript({ armSnapping: true })).toContain('{once:true,passive:true}')
  })

  it('deck-script-012 smooth listeners are passive and not once', () => {
    expect(SMOOTH_ONLY).toContain('{passive:true}')
    expect(SMOOTH_ONLY).not.toContain('once')
  })

  it('deck-script-013 attribute mutations target document.documentElement only', () => {
    const s = deckScript({ armSnapping: true, armSmooth: true, restoreZoomOffIos: false })
    const receivers = [...s.matchAll(/([\w.]+)\.(?:set|remove)Attribute\(/g)].map((m) => m[1])
    expect(receivers.length).toBeGreaterThan(0)
    for (const r of receivers) expect(['document.documentElement', 'd']).toContain(r)
    expect(s).toContain('d=document.documentElement')
  })

  it('deck-script-014 the script and its body are in the server-rendered HTML', () => {
    const html = renderToString(<DeckScript />)
    expect(html.startsWith('<script>')).toBe(true)
    expect(html).toContain(deckScript())
  })

  it('deck-script-015 all four segments concatenate in order with no separators', () => {
    const all = deckScript({ openAtTop: true, armSnapping: true, armSmooth: true, restoreZoomOffIos: true })
    expect(all).toBe(OPEN + SNAP_ONLY + SMOOTH_ONLY + ZOOM_ONLY)
  })

  it('deck-script-016 on an iOS user agent maximum-scale stays in the viewport meta', () => {
    stubPlatform(IOS_UA)
    document.head.innerHTML = VIEWPORT
    run(ZOOM_ONLY)
    window.dispatchEvent(new Event('load'))
    expect(document.querySelector('meta[name=viewport]')!.getAttribute('content')).toContain('maximum-scale=1')
  })

  it('deck-script-017 on a non-iOS user agent maximum-scale is removed now and again on load', () => {
    stubPlatform(DESKTOP_UA)
    document.head.innerHTML = VIEWPORT
    run(ZOOM_ONLY)
    const meta = document.querySelector('meta[name=viewport]')!
    expect(meta.getAttribute('content')).toBe('width=device-width')
    meta.setAttribute('content', 'width=device-width, maximum-scale=1')
    window.dispatchEvent(new Event('load'))
    expect(meta.getAttribute('content')).toBe('width=device-width')
  })

  it('deck-script-018 an empty options object is the all-enabled string', () => {
    expect(deckScript({})).toBe(OPEN + SNAP_ONLY + SMOOTH_ONLY + ZOOM_ONLY)
  })

  it('deck-script-019 omitted options equal an empty options object', () => {
    expect(deckScript()).toBe(deckScript({}))
  })

  it('deck-script-020 all disabled returns the empty string', () => {
    expect(deckScript(ALL_OFF)).toBe('')
  })

  it('deck-script-021 a missing viewport meta throws nothing and a load listener retries', () => {
    stubPlatform(DESKTOP_UA)
    expect(() => run(ZOOM_ONLY)).not.toThrow()
    expect(attached.some(([t]) => t === 'load')).toBe(true)
    document.head.innerHTML = VIEWPORT
    window.dispatchEvent(new Event('load'))
    expect(document.querySelector('meta[name=viewport]')!.getAttribute('content')).toBe('width=device-width')
  })

  it('deck-script-022 input before the listeners attach has no effect; input after sets data-snap', () => {
    const root = document.documentElement
    window.dispatchEvent(new Event('wheel'))
    expect(root.hasAttribute('data-snap')).toBe(false)
    run(SNAP_ONLY)
    expect(root.hasAttribute('data-snap')).toBe(false)
    window.dispatchEvent(new Event('wheel'))
    expect(root.hasAttribute('data-snap')).toBe(true)
  })

  it('deck-script-023 two instances render two independent script elements', () => {
    const html = renderToString(
      <>
        <DeckScript />
        <DeckScript />
      </>,
    )
    expect(html.split('<script>').length - 1).toBe(2)
    run(SNAP_ONLY)
    run(SNAP_ONLY)
    window.dispatchEvent(new Event('wheel'))
    expect(document.documentElement.getAttribute('data-snap')).toBe('')
  })

  it('deck-script-024 rendered in head, the viewport strip succeeds only via the load fallback', () => {
    stubPlatform(DESKTOP_UA)
    run(ZOOM_ONLY) // the viewport meta is not parsed yet
    document.head.innerHTML = VIEWPORT
    const meta = document.querySelector('meta[name=viewport]')!
    expect(meta.getAttribute('content')).toContain('maximum-scale=1')
    window.dispatchEvent(new Event('load'))
    expect(meta.getAttribute('content')).toBe('width=device-width')
    run(SNAP_ONLY)
    window.dispatchEvent(new Event('wheel'))
    expect(document.documentElement.hasAttribute('data-snap')).toBe(true)
  })

  it('deck-script-025 the only attribute names are data-snap and data-smooth', () => {
    const s = deckScript({ armSnapping: true, armSmooth: true, restoreZoomOffIos: false })
    expect(new Set(s.match(/data-[a-z]+/g))).toEqual(new Set(['data-snap', 'data-smooth']))
  })

  it('deck-script-026 one wheel event sets both data-snap and data-smooth', () => {
    const root = document.documentElement
    run(deckScript({ openAtTop: false, armSnapping: true, armSmooth: true, restoreZoomOffIos: false }))
    window.dispatchEvent(new Event('wheel'))
    expect(root.hasAttribute('data-snap')).toBe(true)
    expect(root.hasAttribute('data-smooth')).toBe(true)
    window.dispatchEvent(new Event('popstate'))
    expect(root.hasAttribute('data-smooth')).toBe(false)
  })
})

describe('Glow conformance', () => {
  it('glow-001 renders a div', () => {
    const { container } = render(<Glow />)
    expect(container.firstElementChild!.tagName).toBe('DIV')
  })

  it('glow-002 carries aria-hidden="true"', () => {
    const { container } = render(<Glow />)
    expect(container.firstElementChild!.getAttribute('aria-hidden')).toBe('true')
  })

  it('glow-003 has the lp-glow class', () => {
    const { container } = render(<Glow />)
    expect(container.firstElementChild!.classList.contains('lp-glow')).toBe(true)
  })

  it('glow-004 combines a className with lp-glow', () => {
    const { container } = render(<Glow className="custom-glow" />)
    expect([...container.firstElementChild!.classList]).toEqual(['lp-glow', 'custom-glow'])
  })

  it('glow-005 an empty className is filtered out', () => {
    const { container } = render(<Glow className="" />)
    expect(container.firstElementChild!.getAttribute('class')).toBe('lp-glow')
  })

  it('glow-006 an undefined className is filtered out', () => {
    const { container } = render(<Glow className={undefined} />)
    expect(container.firstElementChild!.getAttribute('class')).toBe('lp-glow')
  })

  it('glow-007 no className prop gives lp-glow only', () => {
    const { container } = render(<Glow />)
    expect(container.firstElementChild!.getAttribute('class')).toBe('lp-glow')
  })

  it('glow-008 a multi-token className is appended', () => {
    const { container } = render(<Glow className="a b" />)
    const el = container.firstElementChild!
    expect(el.getAttribute('class')).toBe('lp-glow a b')
    expect([...el.classList]).toEqual(['lp-glow', 'a', 'b'])
  })

  it('glow-009 a whitespace-only className leaves the single token lp-glow', () => {
    const { container } = render(<Glow className="   " />)
    const el = container.firstElementChild!
    expect(el.getAttribute('class')).toBe('lp-glow    ')
    expect([...el.classList]).toEqual(['lp-glow'])
  })
})

describe('Wrap conformance', () => {
  it('wrap-001 renders its children', () => {
    const { container } = render(<Wrap><span>Hello</span></Wrap>)
    expect(container.querySelector('.lp-wrap')!.innerHTML).toBe('<span>Hello</span>')
  })

  it('wrap-002 applies the lp-wrap class to a div', () => {
    const { container } = render(<Wrap><div /></Wrap>)
    const el = container.firstElementChild!
    expect(el.tagName).toBe('DIV')
    expect(el.classList.contains('lp-wrap')).toBe(true)
  })

  it('wrap-003 an undefined className leaves only lp-wrap', () => {
    const { container } = render(<Wrap className={undefined}><div /></Wrap>)
    expect(container.firstElementChild!.getAttribute('class')).toBe('lp-wrap')
  })

  it('wrap-004 an empty className leaves only lp-wrap', () => {
    const { container } = render(<Wrap className=""><div /></Wrap>)
    expect(container.firstElementChild!.getAttribute('class')).toBe('lp-wrap')
  })

  it('wrap-005 a className is appended after lp-wrap', () => {
    const { container } = render(<Wrap className="custom"><div /></Wrap>)
    expect(container.firstElementChild!.getAttribute('class')).toBe('lp-wrap custom')
  })

  it.skip('wrap-006 width is min(100% - 2.5rem, 70rem): jsdom does not compute layout', () => {})

  it.skip('wrap-007 margin-inline is auto and symmetric: jsdom does not compute layout', () => {})

  it('wrap-008 empty children render an empty div.lp-wrap', () => {
    const a = render(<Wrap>{undefined as never}</Wrap>)
    expect(a.container.firstElementChild!.className).toBe('lp-wrap')
    expect(a.container.firstElementChild!.childNodes.length).toBe(0)
    const b = render(<Wrap>{null}</Wrap>)
    expect(b.container.firstElementChild!.className).toBe('lp-wrap')
    expect(b.container.firstElementChild!.childNodes.length).toBe(0)
  })
})
