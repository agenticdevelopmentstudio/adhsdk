import { describe, expect, it } from 'vitest'
import { fireEvent, render } from '@testing-library/react'
import { NavChrome } from '../chrome/NavChrome'

const LINKS = [
  { href: '#one', label: 'One' },
  { href: '#two', label: 'Two' },
]

describe('NavChrome', () => {
  it('renders the brand and one anchor per link', () => {
    const { container, getByText } = render(<NavChrome brand={<b>Mark</b>} links={LINKS} />)
    expect(getByText('Mark')).toBeTruthy()
    expect(container.querySelectorAll('.lp-drawer a.lp-nav')).toHaveLength(2)
  })

  it('starts closed, and a closed drawer is inert', () => {
    const { container } = render(<NavChrome brand="M" links={LINKS} />)
    const drawer = container.querySelector('.lp-drawer')!
    expect(drawer.className).not.toContain('lp-drawer--open')
    expect(drawer.hasAttribute('inert')).toBe(true)
  })

  it('opens on the burger and closes on a link', () => {
    const { container, getByLabelText, getByText } = render(
      <NavChrome brand="M" links={LINKS} />
    )
    fireEvent.click(getByLabelText('Open menu'))
    const drawer = container.querySelector('.lp-drawer')!
    expect(drawer.className).toContain('lp-drawer--open')
    expect(drawer.hasAttribute('inert')).toBe(false)
    fireEvent.click(getByText('One'))
    expect(container.querySelector('.lp-drawer')!.className).not.toContain('lp-drawer--open')
  })

  it('closes on Escape and on the scrim', () => {
    const { container, getByLabelText } = render(<NavChrome brand="M" links={LINKS} />)
    fireEvent.click(getByLabelText('Open menu'))
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(container.querySelector('.lp-drawer')!.className).not.toContain('lp-drawer--open')

    fireEvent.click(getByLabelText('Open menu'))
    fireEvent.click(container.querySelector('.lp-scrim')!)
    expect(container.querySelector('.lp-drawer')!.className).not.toContain('lp-drawer--open')
  })

  it('moves focus into the drawer on open and back to the burger on close', () => {
    const { getByLabelText } = render(<NavChrome brand="M" links={LINKS} />)
    const burger = getByLabelText('Open menu')
    fireEvent.click(burger)
    expect(document.activeElement).toBe(getByLabelText('Close menu'))
    fireEvent.click(getByLabelText('Close menu'))
    expect(document.activeElement).toBe(burger)
  })

  it('does not steal focus on first render', () => {
    render(<NavChrome brand="M" links={LINKS} />)
    expect(document.activeElement).toBe(document.body)
  })

  it('renders the drawer footer when given one', () => {
    const { getByText } = render(
      <NavChrome brand="M" links={LINKS} footer={<a href="mailto:x@y.z">Mail</a>} />
    )
    expect(getByText('Mail')).toBeTruthy()
  })

  // An href is a URL, not a selector. Passing one straight to querySelector
  // threw a SyntaxError on exactly the off-page links the component's own
  // comment says a host may pass, so the click handler died mid-way.
  it('closes on an off-page link without throwing', () => {
    const offPage = [
      { href: 'mailto:hi@example.com', label: 'Mail' },
      { href: '/pricing.html', label: 'Pricing' },
      { href: 'https://example.com/x', label: 'Docs' },
      { href: '#', label: 'Top' },
    ]
    const { container, getByLabelText, getByText } = render(
      <NavChrome brand="M" links={offPage} />
    )
    for (const { label } of offPage) {
      fireEvent.click(getByLabelText('Open menu'))
      expect(() => fireEvent.click(getByText(label))).not.toThrow()
      expect(container.querySelector('.lp-drawer')!.className).not.toContain('lp-drawer--open')
    }
  })

  it('focuses a same-page target whose id is not a valid selector', () => {
    const target = document.createElement('section')
    target.id = '2024-results'
    // jsdom implements no scrolling at all, so scrollIntoView is simply absent.
    // No prior test reached this branch, which is how the selector bug survived.
    target.scrollIntoView = () => {}
    document.body.append(target)
    const { getByText } = render(
      <NavChrome brand="M" links={[{ href: '#2024-results', label: 'Results' }]} />
    )
    fireEvent.click(getByText('Results'))
    expect(document.activeElement).toBe(target)
    target.remove()
  })

  it('applies a host-supplied navLabel', () => {
    const { getByRole } = render(<NavChrome brand="M" links={LINKS} navLabel="Primary" />)
    expect(getByRole('navigation', { name: 'Primary' })).toBeTruthy()
  })

  // The bar was a <header>, which is a `banner` landmark unless it descends
  // from main/article/aside/nav/section — and what suppressed it was `Deck`
  // rendering a <main>, which it no longer does. Rendered where the host's site
  // header already claims that landmark, a second banner is announced beside it
  // with nothing to distinguish the two. Asserted through `getByRole` rather
  // than the tag, because the defect is the ROLE, and a `role="banner"` on any
  // element would bring it back.
  it('claims no banner landmark, so the host keeps the only one', () => {
    const { container, queryAllByRole } = render(<NavChrome brand="M" links={LINKS} />)
    expect(queryAllByRole('banner')).toHaveLength(0)
    expect(container.querySelector('.lp-bar')!.tagName).toBe('DIV')
  })

  // The action sits in the bar itself, so a drawer row — not the action — is what a
  // narrow viewport, where chrome.css hides it, navigates by.
  it('pins a host action in the bar, outside the drawer', () => {
    const { container } = render(<NavChrome brand="M" links={LINKS} action={<a href="#price">Free</a>} />)
    const action = container.querySelector('.lp-bar > .lp-bar-action')
    expect(action).not.toBeNull()
    expect(action!.textContent).toBe('Free')
    expect(container.querySelector('.lp-drawer .lp-bar-action')).toBeNull()
  })

  it('draws no action element when the host gives none', () => {
    const { container } = render(<NavChrome brand="M" links={LINKS} />)
    expect(container.querySelector('.lp-bar-action')).toBeNull()
  })

  // A host with its own site header has no second wordmark to draw here, and an
  // empty .lp-brand would still sit centred in the bar.
  it('draws no brand element when the host gives no brand', () => {
    const { container } = render(<NavChrome links={LINKS} />)
    expect(container.querySelector('.lp-brand')).toBeNull()
    expect(container.querySelector('.lp-burger')).toBeTruthy()
  })

  // The scrim dismisses on click but is not a control: focus is trapped inside
  // the drawer while it is open, so a button out here is unreachable by
  // keyboard however it is labelled — leaving only a full-viewport control
  // announced as covering the page.
  it('leaves the scrim unfocusable and unannounced', () => {
    const { container } = render(<NavChrome links={LINKS} />)
    const scrim = container.querySelector('.lp-scrim')!
    expect(scrim.tagName).toBe('DIV')
    expect(scrim.getAttribute('aria-hidden')).toBe('true')
    expect(scrim.hasAttribute('tabindex')).toBe(false)
  })

  describe('while open, the keyboard is held inside the drawer', () => {
    it('wraps forward off the last control back to the first', () => {
      const { getByLabelText, getByText } = render(<NavChrome links={LINKS} />)
      fireEvent.click(getByLabelText('Open menu'))
      const close = getByLabelText('Close menu')
      const last = getByText('Two')
      last.focus()
      fireEvent.keyDown(document, { key: 'Tab' })
      expect(document.activeElement).toBe(close)
    })

    it('wraps backward off the first control onto the last', () => {
      const { getByLabelText, getByText } = render(<NavChrome links={LINKS} />)
      fireEvent.click(getByLabelText('Open menu'))
      getByLabelText('Close menu').focus()
      fireEvent.keyDown(document, { key: 'Tab', shiftKey: true })
      expect(document.activeElement).toBe(getByText('Two'))
    })

    // The case an onKeyDown on the <nav> could never see: focus already outside
    // it — a stray click on the scrim, a browser restoring it after an alt-tab.
    it('pulls focus back in when Tab is pressed from outside', () => {
      const stray = document.createElement('button')
      document.body.append(stray)
      const { getByLabelText } = render(<NavChrome links={LINKS} />)
      fireEvent.click(getByLabelText('Open menu'))
      stray.focus()
      fireEvent.keyDown(document, { key: 'Tab' })
      expect(document.activeElement).toBe(getByLabelText('Close menu'))
      stray.remove()
    })

    it('lets Tab go where it likes once the drawer is shut', () => {
      const stray = document.createElement('button')
      document.body.append(stray)
      const { getByLabelText } = render(<NavChrome links={LINKS} />)
      stray.focus()
      fireEvent.keyDown(document, { key: 'Tab' })
      expect(document.activeElement).toBe(stray)
      stray.remove()
    })
  })

  // The focus-return on close is for a DISMISSAL. Arriving somewhere by picking
  // a link is not one, and letting the return run would take the focus `go` just
  // placed on the target and announce the menu button instead.
  it('leaves focus on the target when a link closed the drawer', () => {
    const target = document.createElement('section')
    target.id = 'two'
    target.scrollIntoView = () => {}
    document.body.append(target)
    const { getByLabelText, getByText } = render(<NavChrome links={LINKS} />)
    fireEvent.click(getByLabelText('Open menu'))
    fireEvent.click(getByText('Two'))
    expect(document.activeElement).toBe(target)
    target.remove()
  })

  // ...but a link that goes off-page has no arrival to announce, so the burger
  // still gets focus back.
  it('returns focus to the burger when the link went off-page', () => {
    const { getByLabelText, getByText } = render(
      <NavChrome links={[{ href: 'https://example.com/x', label: 'Docs' }]} />
    )
    const burger = getByLabelText('Open menu')
    fireEvent.click(burger)
    fireEvent.click(getByText('Docs'))
    expect(document.activeElement).toBe(burger)
  })

  it('renders sections after the rows', () => {
    const { container } = render(
      <NavChrome
        links={LINKS}
        sections={
          <p>
            Family <a className="lp-nav" href="https://example.com/">Example</a>
          </p>
        }
      />
    )
    expect(container.querySelector('.lp-drawer .lp-sections a')!.textContent).toBe('Example')
    expect(container.querySelectorAll('.lp-drawer a.lp-nav')).toHaveLength(3)
  })

  it('closes when a link in a section or the foot is picked, and not on plain text', () => {
    const { container, getByLabelText, getByText } = render(
      <NavChrome
        links={LINKS}
        sections={
          <p>
            Family <a className="lp-nav" href="https://example.com/">Example</a>
          </p>
        }
        footer={<button type="button">Contact</button>}
      />
    )
    const isOpen = () => container.querySelector('.lp-drawer')!.className.includes('lp-drawer--open')
    fireEvent.click(getByLabelText('Open menu'))
    fireEvent.click(getByText(/Family/))
    expect(isOpen()).toBe(true)
    fireEvent.click(getByText('Example'))
    expect(isOpen()).toBe(false)
    fireEvent.click(getByLabelText('Open menu'))
    fireEvent.click(getByText('Contact'))
    expect(isOpen()).toBe(false)
  })

  // A foot entry that opens a dialog over the page prevents its link's navigation; the
  // dialog has the focus then, and handing it back to the burger would take it away.
  it('leaves focus alone when a foot entry opened something over the page', () => {
    const { getByLabelText, getByText } = render(
      <NavChrome
        links={LINKS}
        footer={
          <a href="/terms" onClick={(event) => event.preventDefault()}>
            Terms
          </a>
        }
      />
    )
    const burger = getByLabelText('Open menu')
    fireEvent.click(burger)
    const terms = getByText('Terms')
    terms.focus()
    fireEvent.click(terms)
    expect(document.activeElement).not.toBe(burger)
  })
})

describe('NavChrome conformance vectors', () => {
  const FRAG = [{ href: '#section1', label: 'Section' }]
  const isOpen = (c: HTMLElement): boolean =>
    c.querySelector('.lp-drawer')!.className.includes('lp-drawer--open')
  // jsdom implements no scrolling, so scrollIntoView is absent and is stubbed on each target.
  const addTarget = (id: string): HTMLElement => {
    const target = document.createElement('section')
    target.id = id
    target.scrollIntoView = () => {}
    document.body.append(target)
    return target
  }

  it('nav-001: the bar div lp-bar contains the lp-burger button', () => {
    const { container } = render(<NavChrome links={LINKS} />)
    const bar = container.querySelector('div.lp-bar')!
    expect(bar.querySelector('button.lp-burger')).not.toBeNull()
  })

  it('nav-002: the burger is aria-expanded=false while closed', () => {
    const { getByLabelText } = render(<NavChrome links={LINKS} />)
    expect(getByLabelText('Open menu').getAttribute('aria-expanded')).toBe('false')
  })

  it('nav-003: clicking the burger sets aria-expanded=true', () => {
    const { getByLabelText } = render(<NavChrome links={LINKS} />)
    const burger = getByLabelText('Open menu')
    fireEvent.click(burger)
    expect(burger.getAttribute('aria-expanded')).toBe('true')
  })

  it('nav-004: clicking the burger adds lp-drawer--open', () => {
    const { container, getByLabelText } = render(<NavChrome links={LINKS} />)
    expect(isOpen(container)).toBe(false)
    fireEvent.click(getByLabelText('Open menu'))
    expect(isOpen(container)).toBe(true)
  })

  it('nav-005: clicking the burger again leaves the drawer open', () => {
    const { container, getByLabelText } = render(<NavChrome links={LINKS} />)
    const burger = getByLabelText('Open menu')
    fireEvent.click(burger)
    fireEvent.click(burger)
    expect(isOpen(container)).toBe(true)
    expect(burger.getAttribute('aria-expanded')).toBe('true')
  })

  it('nav-006: clicking the scrim closes the drawer and drops lp-scrim--show', () => {
    const { container, getByLabelText } = render(<NavChrome links={LINKS} />)
    fireEvent.click(getByLabelText('Open menu'))
    expect(container.querySelector('.lp-scrim')!.className).toContain('lp-scrim--show')
    fireEvent.click(container.querySelector('.lp-scrim')!)
    expect(isOpen(container)).toBe(false)
    expect(container.querySelector('.lp-scrim')!.className).not.toContain('lp-scrim--show')
  })

  it('nav-007: the brand renders in div.lp-brand inside the bar', () => {
    const { container } = render(<NavChrome brand={<b>Mark</b>} links={LINKS} />)
    expect(container.querySelector('.lp-bar > .lp-brand')!.textContent).toBe('Mark')
  })

  it('nav-008: no lp-brand when brand is undefined', () => {
    const { container } = render(<NavChrome links={LINKS} />)
    expect(container.querySelector('.lp-brand')).toBeNull()
  })

  it('nav-009: a same-page fragment link closes the drawer', () => {
    const target = addTarget('one')
    const { container, getByLabelText, getByText } = render(<NavChrome links={LINKS} />)
    fireEvent.click(getByLabelText('Open menu'))
    fireEvent.click(getByText('One'))
    expect(isOpen(container)).toBe(false)
    target.remove()
  })

  it('nav-010: an off-page link closes the drawer', () => {
    const { container, getByLabelText, getByText } = render(
      <NavChrome links={[{ href: 'https://example.com/x', label: 'Docs' }]} />
    )
    fireEvent.click(getByLabelText('Open menu'))
    fireEvent.click(getByText('Docs'))
    expect(isOpen(container)).toBe(false)
  })

  it('nav-011: a fragment link with a target is default-prevented and the target is located by id', () => {
    const target = addTarget('section1')
    const { getByText } = render(<NavChrome links={FRAG} />)
    // fireEvent returns false when the event was default-prevented.
    expect(fireEvent.click(getByText('Section'))).toBe(false)
    expect(document.activeElement).toBe(target)
    target.remove()
  })

  it('nav-012: the target gets focus and tabindex=-1', () => {
    const target = addTarget('section1')
    const { getByText } = render(<NavChrome links={FRAG} />)
    fireEvent.click(getByText('Section'))
    expect(document.activeElement).toBe(target)
    expect(target.getAttribute('tabindex')).toBe('-1')
    target.remove()
  })

  it('nav-013: a percent-encoded fragment resolves to the decoded id', () => {
    const target = addTarget('section one')
    const { getByText } = render(
      <NavChrome links={[{ href: '#section%20one', label: 'Spaced' }]} />
    )
    fireEvent.click(getByText('Spaced'))
    expect(document.activeElement).toBe(target)
    target.remove()
  })

  it('nav-014: a malformed percent escape does not throw and falls back to the raw id', () => {
    const target = addTarget('%XX')
    const { getByText } = render(<NavChrome links={[{ href: '#%XX', label: 'Bad' }]} />)
    expect(() => fireEvent.click(getByText('Bad'))).not.toThrow()
    expect(document.activeElement).toBe(target)
    target.remove()
  })

  it('nav-015: Tab from the last focusable wraps to the first', () => {
    const { getByLabelText, getByText } = render(<NavChrome links={LINKS} footer={<a href="/f">Foot</a>} />)
    fireEvent.click(getByLabelText('Open menu'))
    getByText('Foot').focus()
    fireEvent.keyDown(document, { key: 'Tab' })
    expect(document.activeElement).toBe(getByLabelText('Close menu'))
  })

  it('nav-016: Shift+Tab from the first focusable wraps to the last', () => {
    const { getByLabelText, getByText } = render(<NavChrome links={LINKS} footer={<a href="/f">Foot</a>} />)
    fireEvent.click(getByLabelText('Open menu'))
    getByLabelText('Close menu').focus()
    fireEvent.keyDown(document, { key: 'Tab', shiftKey: true })
    expect(document.activeElement).toBe(getByText('Foot'))
  })

  it('nav-017: Tab with focus on body pulls focus to the first focusable in the drawer', () => {
    const { getByLabelText } = render(<NavChrome links={LINKS} />)
    fireEvent.click(getByLabelText('Open menu'))
    ;(document.activeElement as HTMLElement).blur()
    expect(document.activeElement).toBe(document.body)
    fireEvent.keyDown(document, { key: 'Tab' })
    expect(document.activeElement).toBe(getByLabelText('Close menu'))
  })

  it('nav-018: Escape closes the drawer', () => {
    const { container, getByLabelText } = render(<NavChrome links={LINKS} />)
    fireEvent.click(getByLabelText('Open menu'))
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(isOpen(container)).toBe(false)
  })

  it('nav-019: opening moves focus to the close button', () => {
    const { getByLabelText } = render(<NavChrome links={LINKS} />)
    fireEvent.click(getByLabelText('Open menu'))
    expect(document.activeElement).toBe(getByLabelText('Close menu'))
  })

  it('nav-020: the close button closes the drawer and returns focus to the burger', () => {
    const { container, getByLabelText } = render(<NavChrome links={LINKS} />)
    const burger = getByLabelText('Open menu')
    fireEvent.click(burger)
    fireEvent.click(getByLabelText('Close menu'))
    expect(isOpen(container)).toBe(false)
    expect(document.activeElement).toBe(burger)
  })

  it('nav-021: initial render moves focus nowhere', () => {
    render(<NavChrome brand="M" links={LINKS} />)
    expect(document.activeElement).toBe(document.body)
  })

  it('nav-022: a closed drawer has inert', () => {
    const { container } = render(<NavChrome links={LINKS} />)
    expect(container.querySelector('.lp-drawer')!.hasAttribute('inert')).toBe(true)
  })

  it('nav-023: an open drawer has no inert', () => {
    const { container, getByLabelText } = render(<NavChrome links={LINKS} />)
    fireEvent.click(getByLabelText('Open menu'))
    expect(container.querySelector('.lp-drawer')!.hasAttribute('inert')).toBe(false)
  })

  it('nav-024: the footer renders in div.lp-foot inside the drawer', () => {
    const { container } = render(<NavChrome links={LINKS} footer={<span>Byline</span>} />)
    expect(container.querySelector('.lp-drawer > .lp-foot')!.textContent).toBe('Byline')
  })

  it('nav-025: no lp-foot when footer is undefined', () => {
    const { container } = render(<NavChrome links={LINKS} />)
    expect(container.querySelector('.lp-foot')).toBeNull()
  })

  it('nav-026: navLabel sets aria-label on the nav', () => {
    const { container } = render(<NavChrome links={LINKS} navLabel="Main Navigation" />)
    expect(container.querySelector('nav')!.getAttribute('aria-label')).toBe('Main Navigation')
  })

  it('nav-027: a focusable added while open is part of the Tab trap', () => {
    const { container, getByLabelText } = render(<NavChrome links={LINKS} />)
    fireEvent.click(getByLabelText('Open menu'))
    const added = document.createElement('button')
    container.querySelector('nav')!.append(added)
    added.focus()
    // `added` is now the last control, so Tab from it wraps to the first.
    fireEvent.keyDown(document, { key: 'Tab' })
    expect(document.activeElement).toBe(getByLabelText('Close menu'))
    // And Shift+Tab from the first now lands on the new last control.
    fireEvent.keyDown(document, { key: 'Tab', shiftKey: true })
    expect(document.activeElement).toBe(added)
  })

  it('nav-028: empty links and no footer: Tab does not throw', () => {
    const { getByLabelText } = render(<NavChrome links={[]} />)
    fireEvent.click(getByLabelText('Open menu'))
    expect(() => fireEvent.keyDown(document, { key: 'Tab' })).not.toThrow()
    expect(() => fireEvent.keyDown(document, { key: 'Tab', shiftKey: true })).not.toThrow()
  })

  it('nav-029: an off-page link closes the drawer and its default navigation is not prevented', () => {
    const { container, getByLabelText, getByText } = render(
      <NavChrome links={[{ href: '/other-page', label: 'Other' }]} />
    )
    fireEvent.click(getByLabelText('Open menu'))
    expect(fireEvent.click(getByText('Other'))).toBe(true)
    expect(isOpen(container)).toBe(false)
  })

  it('nav-030: the scrim is aria-hidden=true', () => {
    const { container } = render(<NavChrome links={LINKS} />)
    expect(container.querySelector('.lp-scrim')!.getAttribute('aria-hidden')).toBe('true')
  })

  it('nav-031: focus stays on the fragment target and is not returned to the burger', () => {
    const target = addTarget('section1')
    const { getByLabelText, getByText } = render(<NavChrome links={FRAG} />)
    fireEvent.click(getByLabelText('Open menu'))
    fireEvent.click(getByText('Section'))
    expect(document.activeElement).toBe(target)
    expect(document.activeElement).not.toBe(getByLabelText('Open menu'))
    target.remove()
  })

  it('nav-032: the drawer holds an anchor with the link text and href', () => {
    const { container } = render(<NavChrome links={[{ href: '#a', label: 'A' }]} />)
    const a = container.querySelector('.lp-drawer a')!
    expect(a.textContent).toBe('A')
    expect(a.getAttribute('href')).toBe('#a')
  })

  it('nav-033: Escape closes the drawer and returns focus to the burger', () => {
    const { container, getByLabelText } = render(<NavChrome links={LINKS} />)
    const burger = getByLabelText('Open menu')
    fireEvent.click(burger)
    fireEvent.keyDown(document, { key: 'Escape' })
    expect(isOpen(container)).toBe(false)
    expect(document.activeElement).toBe(burger)
  })

  it('nav-034: an open drawer holds a button labelled Close menu', () => {
    const { container, getByLabelText } = render(<NavChrome links={LINKS} />)
    fireEvent.click(getByLabelText('Open menu'))
    const close = container.querySelector('.lp-drawer button')!
    expect(close.getAttribute('aria-label')).toBe('Close menu')
  })

  it('nav-035: the burger and close buttons are type=button', () => {
    const { getByLabelText } = render(<NavChrome links={LINKS} />)
    expect(getByLabelText('Open menu').getAttribute('type')).toBe('button')
    expect(getByLabelText('Close menu', { selector: 'button' }).getAttribute('type')).toBe('button')
  })

  it('nav-036: default labels are Open menu, Close menu and Site', () => {
    const { container } = render(<NavChrome links={LINKS} />)
    expect(container.querySelector('.lp-bar .lp-burger')!.getAttribute('aria-label')).toBe('Open menu')
    expect(container.querySelector('.lp-drawer-close')!.getAttribute('aria-label')).toBe('Close menu')
    expect(container.querySelector('nav')!.getAttribute('aria-label')).toBe('Site')
  })

  it('nav-037: openLabel and closeLabel override the defaults', () => {
    const { container } = render(<NavChrome links={LINKS} openLabel="Menu" closeLabel="Dismiss" />)
    expect(container.querySelector('.lp-bar .lp-burger')!.getAttribute('aria-label')).toBe('Menu')
    expect(container.querySelector('.lp-drawer-close')!.getAttribute('aria-label')).toBe('Dismiss')
  })

  it('nav-038: a previously focused element keeps focus after render', () => {
    const other = document.createElement('input')
    document.body.append(other)
    other.focus()
    render(<NavChrome brand="M" links={LINKS} />)
    expect(document.activeElement).toBe(other)
    other.remove()
  })

  it('nav-039: a fragment with no target is not default-prevented and the drawer closes', () => {
    const { container, getByLabelText, getByText } = render(
      <NavChrome links={[{ href: '#missing-section', label: 'Missing' }]} />
    )
    fireEvent.click(getByLabelText('Open menu'))
    expect(fireEvent.click(getByText('Missing'))).toBe(true)
    expect(isOpen(container)).toBe(false)
  })
})
