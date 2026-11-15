import { describe, expect, it } from 'vitest'
import { render } from '@testing-library/react'
import { Contact } from '../blocks/Contact'

const MAIL = { href: 'mailto:test@example.com', label: 'Email us' }

function root(ui: React.ReactElement): HTMLElement {
  return render(ui).container.firstElementChild as HTMLElement
}

describe('Contact conformance vectors', () => {
  it('contact-001 renders the mailto link with its label', () => {
    const a = root(<Contact title="T" mail={MAIL}>{null}</Contact>).querySelector('a')!
    expect(a.getAttribute('href')).toBe('mailto:test@example.com')
    expect(a.textContent).toBe('Email us')
  })

  it('contact-002 the link carries lp-mail', () => {
    const a = root(<Contact title="T" mail={MAIL}>{null}</Contact>).querySelector('a')!
    expect(a.classList.contains('lp-mail')).toBe(true)
  })

  it('contact-003 the colophon is a p.lp-colophon', () => {
    const p = root(<Contact title="T" mail={MAIL} colophon="© 2026 Example">{null}</Contact>)
      .querySelector('p.lp-colophon')!
    expect(p.textContent).toBe('© 2026 Example')
  })

  it('contact-004 title, children, mail link, colophon appear in order', () => {
    const el = root(
      <Contact title="Get in Touch" mail={MAIL} colophon="Col">
        <p className="body">We'd love to hear from you</p>
      </Contact>
    )
    expect(el.querySelector('h2')!.textContent).toBe('Get in Touch')
    const kids = Array.from(el.children)
    expect(kids.map((k) => k.tagName)).toEqual(['H2', 'P', 'A', 'P'])
    expect(kids[1].className).toBe('body')
    expect(kids[2].className).toBe('lp-mail')
    expect(kids[3].className).toBe('lp-colophon')
  })

  it('contact-005 an undefined colophon renders no paragraph', () => {
    const el = root(<Contact title="T" mail={MAIL} colophon={undefined}>{null}</Contact>)
    expect(el.querySelector('.lp-colophon')).toBeNull()
    expect(el.querySelector('p')).toBeNull()
  })

  it('contact-006 the root matches .lp-closer.lp-contact', () => {
    const el = root(<Contact title="T" mail={MAIL}>{null}</Contact>)
    expect(el.matches('.lp-closer.lp-contact')).toBe(true)
    expect(el.className).toBe('lp-closer lp-contact')
  })

  it('contact-007 an empty label renders an empty anchor', () => {
    const a = root(<Contact title="T" mail={{ href: MAIL.href, label: '' }}>{null}</Contact>)
      .querySelector('a')!
    expect(a.textContent).toBe('')
    expect(a.getAttribute('href')).toBe(MAIL.href)
  })

  it('contact-008 a non-mailto href is rendered as given', () => {
    const a = root(
      <Contact title="T" mail={{ href: 'https://example.com/contact', label: 'Contact' }}>{null}</Contact>
    ).querySelector('a')!
    expect(a.getAttribute('href')).toBe('https://example.com/contact')
  })

  it('contact-009 an empty-string colophon renders an empty paragraph', () => {
    const p = root(<Contact title="T" mail={MAIL} colophon="">{null}</Contact>)
      .querySelector('p.lp-colophon')!
    expect(p).toBeTruthy()
    expect(p.textContent).toBe('')
  })

  it('contact-010 undefined children add nothing between the h2 and the link', () => {
    const el = root(<Contact title="T" mail={MAIL}>{undefined}</Contact>)
    expect(Array.from(el.children).map((k) => k.tagName)).toEqual(['H2', 'A'])
  })

  it('contact-011 an undefined title leaves the h2 empty', () => {
    const el = root(<Contact title={undefined} mail={MAIL}>{null}</Contact>)
    expect(el.querySelector('h2')!.textContent).toBe('')
    expect(el.querySelector('h2')!.childNodes).toHaveLength(0)
  })

  it('contact-012 a null colophon renders an empty paragraph', () => {
    const p = root(<Contact title="T" mail={MAIL} colophon={null}>{null}</Contact>)
      .querySelector('p.lp-colophon')!
    expect(p).toBeTruthy()
    expect(p.textContent).toBe('')
  })

  it('contact-013 a null label renders an anchor with no text', () => {
    const a = root(<Contact title="T" mail={{ href: MAIL.href, label: null }}>{null}</Contact>)
      .querySelector('a')!
    expect(a.textContent).toBe('')
    expect(a.childNodes).toHaveLength(0)
  })
})
