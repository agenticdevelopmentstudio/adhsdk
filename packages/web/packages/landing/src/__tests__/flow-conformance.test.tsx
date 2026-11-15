import { act, render } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { Band } from '../flow/Band'
import { Bleed } from '../flow/Bleed'
import { FlowHero } from '../flow/FlowHero'
import { Reveal } from '../flow/Reveal'
import { SiteFooter } from '../flow/SiteFooter'

const section = (c: HTMLElement): HTMLElement => c.querySelector('section') as HTMLElement
const bleed = (c: HTMLElement): HTMLElement => c.firstElementChild as HTMLElement
const base = { headline: 'A claim', sub: 'A sub' }

describe('Band conformance vectors', () => {
  it('band-001 renders a section element', () => {
    const { container } = render(<Band>x</Band>)
    expect(section(container)).not.toBeNull()
  })
  it('band-002 defaults to the dark tone', () => {
    const { container } = render(<Band>x</Band>)
    expect(section(container).classList.contains('lp-band--dark')).toBe(true)
  })
  it('band-003 forwards id', () => {
    const { container } = render(<Band id="section-1">x</Band>)
    expect(section(container).id).toBe('section-1')
  })
  it('band-004 soft tone class', () => {
    const { container } = render(<Band tone="soft">x</Band>)
    expect(section(container).classList.contains('lp-band--soft')).toBe(true)
  })
  it('band-005 paper tone class', () => {
    const { container } = render(<Band tone="paper">x</Band>)
    expect(section(container).classList.contains('lp-band--paper')).toBe(true)
  })
  it('band-006 seam defaults to true', () => {
    const { container } = render(<Band>x</Band>)
    expect(section(container).classList.contains('lp-band--seam')).toBe(true)
  })
  it('band-007 seam={false} withholds the seam class', () => {
    const { container } = render(<Band seam={false}>x</Band>)
    expect(section(container).classList.contains('lp-band--seam')).toBe(false)
  })
  it('band-008 base class', () => {
    const { container } = render(<Band>x</Band>)
    expect(section(container).classList.contains('lp-band')).toBe(true)
  })
  it('band-009 accepts className', () => {
    const { container } = render(<Band className="custom-class">x</Band>)
    expect(section(container).classList.contains('custom-class')).toBe(true)
  })
  it('band-010 wraps children in lp-wrap', () => {
    const { container } = render(
      <Band>
        <p>Content</p>
      </Band>,
    )
    const child = section(container).firstElementChild as HTMLElement
    expect(child.tagName).toBe('DIV')
    expect(child.classList.contains('lp-wrap')).toBe(true)
    expect(child.innerHTML).toBe('<p>Content</p>')
  })
  it('band-011 no id attribute when omitted', () => {
    const { container } = render(<Band>x</Band>)
    expect(section(container).hasAttribute('id')).toBe(false)
  })
  it('band-012 combines base, tone, seam and custom classes', () => {
    const { container } = render(
      <Band tone="soft" seam className="custom-class">
        x
      </Band>,
    )
    const list = Array.from(section(container).classList)
    expect(list).toEqual(expect.arrayContaining(['lp-band', 'lp-band--soft', 'lp-band--seam', 'custom-class']))
  })
  it('band-013 empty className leaves no empty entries or doubled whitespace', () => {
    const { container } = render(<Band className="">x</Band>)
    const attr = section(container).getAttribute('class') as string
    expect(attr).not.toMatch(/\s{2,}/)
    expect(attr).toBe(attr.trim())
    expect(Array.from(section(container).classList).every((c) => c !== '')).toBe(true)
  })
  it.skip('band-014 paper clip-path foot cut (needs real browser computed style)', () => {})
  it.skip('band-015 position relative and z-index 1 (needs real browser computed style)', () => {})
  it.skip('band-016 paper z-index 2 (needs real browser computed style)', () => {})
  it.skip('band-017 seam clip-path and negative margin (needs real browser computed style)', () => {})
  it.skip('band-018 paper plus seam combined clip-path (needs real browser computed style)', () => {})
  it.skip('band-019 dock clearance on last band (needs real browser computed style)', () => {})
  it.skip('band-020 tone token background (needs real browser computed style)', () => {})
})

describe('Bleed conformance vectors', () => {
  it('bleed-001 renders a div containing the content', () => {
    const { container } = render(<Bleed>Content</Bleed>)
    expect(bleed(container).tagName).toBe('DIV')
    expect(bleed(container).textContent).toBe('Content')
  })
  it('bleed-002 base class', () => {
    const { container } = render(<Bleed>Content</Bleed>)
    expect(bleed(container).classList.contains('lp-bleed')).toBe(true)
  })
  it('bleed-003 left side class', () => {
    const { container } = render(<Bleed side="left">Content</Bleed>)
    expect(bleed(container).classList.contains('lp-bleed--left')).toBe(true)
  })
  it('bleed-004 right side class', () => {
    const { container } = render(<Bleed side="right">Content</Bleed>)
    expect(bleed(container).classList.contains('lp-bleed--right')).toBe(true)
  })
  it('bleed-005 side defaults to right', () => {
    const { container } = render(<Bleed>Content</Bleed>)
    expect(bleed(container).classList.contains('lp-bleed--right')).toBe(true)
  })
  it('bleed-006 appends className', () => {
    const { container } = render(<Bleed className="custom">Content</Bleed>)
    expect(Array.from(bleed(container).classList)).toEqual(['lp-bleed', 'lp-bleed--right', 'custom'])
  })
  it('bleed-007 empty className excluded', () => {
    const { container } = render(<Bleed className="">Content</Bleed>)
    expect(Array.from(bleed(container).classList)).toEqual(['lp-bleed', 'lp-bleed--right'])
    expect(bleed(container).getAttribute('class')).toBe('lp-bleed lp-bleed--right')
  })
  it('bleed-008 renders multiple children', () => {
    const { container } = render(
      <Bleed>
        <span>Text</span>
        <button>Click</button>
      </Bleed>,
    )
    expect(bleed(container).querySelector('span')).not.toBeNull()
    expect(bleed(container).querySelector('button')).not.toBeNull()
  })
  it('bleed-009 null child renders empty', () => {
    const { container } = render(<Bleed>{null}</Bleed>)
    expect(bleed(container).childNodes.length).toBe(0)
    expect(bleed(container).textContent).toBe('')
  })
  it('bleed-011 space-separated className appended as-is', () => {
    const { container } = render(<Bleed className="custom-one custom-two">Content</Bleed>)
    expect(bleed(container).getAttribute('class')).toBe('lp-bleed lp-bleed--right custom-one custom-two')
  })
  it('bleed-012 fragment children render inside the div', () => {
    const { container } = render(
      <Bleed>
        <>Content</>
      </Bleed>,
    )
    expect(bleed(container).textContent).toBe('Content')
  })
  it('bleed-013 no undefined or trailing space without className', () => {
    const { container } = render(<Bleed>Content</Bleed>)
    const attr = bleed(container).getAttribute('class') as string
    expect(attr).toBe('lp-bleed lp-bleed--right')
    expect(attr).not.toContain('undefined')
  })
  it.skip('bleed-014 right margin -128px at 1280px (needs real layout and media queries)', () => {})
  it.skip('bleed-015 left margin -128px at 1280px (needs real layout and media queries)', () => {})
  it.skip('bleed-016 no offset at 700px (needs real layout and media queries)', () => {})
})

describe('FlowHero conformance vectors', () => {
  it('flow-hero-001 renders the headline as h1', () => {
    const { container } = render(<FlowHero {...base} />)
    expect(container.querySelector('h1')?.textContent).toBe('A claim')
  })
  it('flow-hero-002 renders sub as p.lp-hero-sub', () => {
    const { container } = render(<FlowHero {...base} />)
    const p = container.querySelector('p.lp-hero-sub')
    expect(p?.textContent).toBe('A sub')
  })
  it('flow-hero-003 renders mark unmodified', () => {
    const { container } = render(<FlowHero {...base} mark={<img src="/m.png" alt="Mark" />} />)
    const img = container.querySelector('img') as HTMLImageElement
    expect(img.getAttribute('src')).toBe('/m.png')
    expect(img.getAttribute('alt')).toBe('Mark')
    expect(img.parentElement?.classList.contains('lp-wrap')).toBe(true)
  })
  it('flow-hero-004 wraps children in lp-hero-actions', () => {
    const { container } = render(
      <FlowHero {...base}>
        <button>Go</button>
      </FlowHero>,
    )
    const actions = container.querySelector('div.lp-hero-actions')
    expect(actions).not.toBeNull()
    expect(actions?.querySelector('button')?.textContent).toBe('Go')
  })
  it('flow-hero-005 no actions container when children undefined', () => {
    const { container } = render(<FlowHero {...base} />)
    expect(container.querySelector('.lp-hero-actions')).toBeNull()
  })
  it('flow-hero-006 renders meta paragraph', () => {
    const { container } = render(<FlowHero {...base} meta="Free" />)
    expect(container.querySelector('p.lp-hero-meta')?.textContent).toBe('Free')
  })
  it('flow-hero-007 no meta paragraph when undefined', () => {
    const { container } = render(<FlowHero {...base} />)
    expect(container.querySelector('.lp-hero-meta')).toBeNull()
  })
  it('flow-hero-008 shot wrapped in lp-hero-shot', () => {
    const { container } = render(<FlowHero {...base} shot={<img src="/s.png" alt="" />} />)
    const shot = container.querySelector('div.lp-hero-shot')
    expect(shot).not.toBeNull()
    expect(shot?.querySelector('img')?.getAttribute('src')).toBe('/s.png')
  })
  it('flow-hero-009 no shot container when undefined', () => {
    const { container } = render(<FlowHero {...base} />)
    expect(container.querySelector('.lp-hero-shot')).toBeNull()
  })
  it('flow-hero-010 root div carries the id', () => {
    const { container } = render(<FlowHero {...base} id="hero-1" />)
    expect((container.firstElementChild as HTMLElement).id).toBe('hero-1')
  })
  it('flow-hero-011 root is div.lp-hero-flow', () => {
    const { container } = render(<FlowHero {...base} />)
    const root = container.firstElementChild as HTMLElement
    expect(root.tagName).toBe('DIV')
    expect(root.getAttribute('class')).toBe('lp-hero-flow')
  })
  it('flow-hero-012 child order', () => {
    const { container } = render(
      <FlowHero {...base} mark={<img alt="" />} meta="Free" shot={<img alt="" />}>
        <button>Go</button>
      </FlowHero>,
    )
    const root = container.firstElementChild as HTMLElement
    const wraps = Array.from(root.children) as HTMLElement[]
    expect(wraps).toHaveLength(2)
    expect(wraps.every((w) => w.classList.contains('lp-wrap'))).toBe(true)
    const first = Array.from(wraps[0]!.children)
    expect(first.map((e) => e.tagName + '.' + e.getAttribute('class'))).toEqual([
      'IMG.null',
      'H1.null',
      'P.lp-hero-sub',
      'DIV.lp-hero-actions',
      'P.lp-hero-meta',
    ])
    expect(wraps[0]!.querySelector('.lp-hero-shot')).toBeNull()
    expect(wraps[1]!.querySelector('div.lp-hero-shot')).not.toBeNull()
  })
  it('flow-hero-013 null children renders empty actions container', () => {
    const { container } = render(<FlowHero {...base}>{null}</FlowHero>)
    const actions = container.querySelector('div.lp-hero-actions')
    expect(actions).not.toBeNull()
    expect(actions?.childNodes.length).toBe(0)
  })
  it('flow-hero-014 empty-string meta renders empty paragraph', () => {
    const { container } = render(<FlowHero {...base} meta="" />)
    const meta = container.querySelector('p.lp-hero-meta')
    expect(meta).not.toBeNull()
    expect(meta?.textContent).toBe('')
  })
  it('flow-hero-015 null shot renders empty shot container', () => {
    const { container } = render(<FlowHero {...base} shot={null} />)
    const shot = container.querySelector('div.lp-hero-shot')
    expect(shot).not.toBeNull()
    expect(shot?.childNodes.length).toBe(0)
  })
  it('flow-hero-016 undefined mark renders nothing; h1 is first child', () => {
    const { container } = render(<FlowHero {...base} mark={undefined} />)
    const wrap = container.querySelector('.lp-wrap') as HTMLElement
    expect(wrap.firstElementChild?.tagName).toBe('H1')
  })
})

describe('Reveal conformance vectors', () => {
  interface Fake {
    cb: (entries: { isIntersecting: boolean }[]) => void
    options: IntersectionObserverInit | undefined
    disconnect: ReturnType<typeof vi.fn>
  }
  let observers: Fake[]
  let rectTop = 0
  const original = Element.prototype.getBoundingClientRect

  beforeEach(() => {
    observers = []
    class FakeIO {
      cb: Fake['cb']
      options: Fake['options']
      disconnect = vi.fn()
      observe = vi.fn()
      constructor(cb: Fake['cb'], options?: IntersectionObserverInit) {
        this.cb = cb
        this.options = options
        observers.push(this as unknown as Fake)
      }
    }
    vi.stubGlobal('IntersectionObserver', FakeIO)
    Element.prototype.getBoundingClientRect = () => ({ top: rectTop }) as DOMRect
  })
  afterEach(() => {
    vi.unstubAllGlobals()
    Element.prototype.getBoundingClientRect = original
  })

  const below = (): void => {
    rectTop = window.innerHeight + 500
  }
  const wrapper = (c: HTMLElement): HTMLElement => c.firstElementChild as HTMLElement
  const fire = (): void => {
    act(() => observers[0].cb([{ isIntersecting: true }]))
  }

  it('reveal-001 children render in the resting state before any observer fires', () => {
    below()
    const { container } = render(<Reveal><p>x</p></Reveal>)
    expect(container.textContent).toBe('x')
    expect(wrapper(container).className).toContain('lp-reveal')
    // Never hidden by inline style: the hidden state lives only on the armed class.
    expect(wrapper(container).getAttribute('style')).toBeNull()
  })
  it('reveal-002 below the fold arms the wrapper', () => {
    below()
    const { container } = render(<Reveal>x</Reveal>)
    expect(wrapper(container).classList.contains('lp-reveal--armed')).toBe(true)
    expect(observers).toHaveLength(1)
  })
  it('reveal-003 entry disconnects the observer and removes the armed class', () => {
    below()
    const { container } = render(<Reveal>x</Reveal>)
    fire()
    expect(observers[0].disconnect).toHaveBeenCalled()
    expect(wrapper(container).classList.contains('lp-reveal--armed')).toBe(false)
  })
  it('reveal-004 a revealed element is never re-armed after scrolling away', () => {
    below()
    const { container } = render(<Reveal>x</Reveal>)
    fire()
    act(() => observers[0].cb([{ isIntersecting: false }]))
    expect(observers).toHaveLength(1)
    expect(wrapper(container).classList.contains('lp-reveal--armed')).toBe(false)
  })
  it('reveal-005 armed class is present on the wrapper while below the viewport', () => {
    below()
    const { container } = render(<Reveal>x</Reveal>)
    expect(wrapper(container).classList.contains('lp-reveal--armed')).toBe(true)
  })
  it('reveal-006 base class is present while armed and once revealed', () => {
    below()
    const { container } = render(<Reveal>x</Reveal>)
    expect(wrapper(container).classList.contains('lp-reveal')).toBe(true)
    fire()
    expect(wrapper(container).classList.contains('lp-reveal')).toBe(true)
  })
  it('reveal-007 custom class sits beside the base and armed classes', () => {
    below()
    const { container } = render(<Reveal className="custom">x</Reveal>)
    expect(wrapper(container).className).toBe('lp-reveal lp-reveal--armed custom')
  })
  it('reveal-008 children are rendered as-is inside the wrapper', () => {
    below()
    const { container } = render(
      <Reveal>
        <img src="a.png" alt="" />
        <p>Text</p>
      </Reveal>,
    )
    expect(wrapper(container).querySelector('img')?.getAttribute('src')).toBe('a.png')
    expect(wrapper(container).querySelector('p')?.textContent).toBe('Text')
  })
  it('reveal-009 an element already on screen creates no observer and is never armed', () => {
    rectTop = 0
    const { container } = render(<Reveal>x</Reveal>)
    expect(observers).toHaveLength(0)
    expect(wrapper(container).classList.contains('lp-reveal--armed')).toBe(false)
  })
  it('reveal-010 the observer is configured with a 12% negative bottom margin', () => {
    below()
    render(<Reveal>x</Reveal>)
    expect(observers[0].options?.rootMargin).toBe('0px 0px -12% 0px')
  })
  it.skip('reveal-011 reduced-motion shows an armed element at its resting values (needs a real browser computing the media query)', () => {})
})

describe('SiteFooter conformance vectors', () => {
  const footer = (c: HTMLElement): HTMLElement => c.querySelector('footer') as HTMLElement
  it('site-footer-001 renders a footer element', () => {
    const { container } = render(<SiteFooter>x</SiteFooter>)
    expect(footer(container)).not.toBeNull()
  })
  it('site-footer-002 footer carries lp-site-foot', () => {
    const { container } = render(<SiteFooter>x</SiteFooter>)
    expect(footer(container).classList.contains('lp-site-foot')).toBe(true)
  })
  it('site-footer-003 footer contains its children', () => {
    const { container } = render(<SiteFooter>Footer content</SiteFooter>)
    expect(footer(container).textContent).toContain('Footer content')
  })
  it('site-footer-004 children sit in a direct lp-wrap div child', () => {
    const { container } = render(<SiteFooter><span id="kid">k</span></SiteFooter>)
    const child = footer(container).firstElementChild as HTMLElement
    expect(child.tagName).toBe('DIV')
    expect(child.classList.contains('lp-wrap')).toBe(true)
    expect(child.querySelector('#kid')).not.toBeNull()
  })
  it('site-footer-005 merges a custom class', () => {
    const { container } = render(<SiteFooter className="custom-footer">x</SiteFooter>)
    expect(footer(container).getAttribute('class')).toBe('lp-site-foot custom-footer')
  })
  it('site-footer-006 undefined className adds nothing', () => {
    const { container } = render(<SiteFooter className={undefined}>x</SiteFooter>)
    expect(footer(container).getAttribute('class')).toBe('lp-site-foot')
  })
  it('site-footer-007 empty className is filtered', () => {
    const { container } = render(<SiteFooter className="">x</SiteFooter>)
    expect(footer(container).getAttribute('class')).toBe('lp-site-foot')
  })
  it.skip('site-footer-008 footer chrome computed style (needs a real browser; jsdom loads no stylesheet)', () => {})
  it.skip('site-footer-009 dock-clear padding (needs a real browser computing CSS variables)', () => {})
  it.skip('site-footer-010 descendant link style (needs a real browser computing CSS)', () => {})
  it.skip('site-footer-011 small font size (needs a real browser computing CSS)', () => {})
  it.skip('site-footer-012 link hover border colour (needs a real browser and hover)', () => {})
  it.skip('site-footer-013 small letter-spacing (needs a real browser computing CSS)', () => {})
  it.skip('site-footer-014 contentinfo landmark outside main.lp-flow (needs a real browser accessibility tree)', () => {})
})
