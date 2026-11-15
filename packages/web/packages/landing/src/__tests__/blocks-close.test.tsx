import { describe, expect, it } from 'vitest'
import { render } from '@testing-library/react'
import { Btn, Contact, Cta, Faq, Hero, StatusPill, Trust } from '../index'

describe('Faq', () => {
  it('is native details/summary, and honours the first-open flag', () => {
    const { container } = render(
      <Faq entries={[
        { question: 'What does it cost?', answer: <p>Nothing.</p>, open: true },
        { question: 'Is it open source?', answer: <p>No.</p> },
      ]} />
    )
    const items = container.querySelectorAll('.lp-faq details')
    expect(items).toHaveLength(2)
    expect(items[0].querySelector('summary')!.textContent).toBe('What does it cost?')
    expect((items[0] as HTMLDetailsElement).open).toBe(true)
    expect((items[1] as HTMLDetailsElement).open).toBe(false)
  })
})

describe('Btn', () => {
  it('defaults to primary and takes ghost', () => {
    const { container, rerender } = render(<Btn href="#a">Go</Btn>)
    expect(container.firstElementChild!.className).toContain('lp-btn--primary')
    rerender(<Btn href="#a" variant="ghost">Go</Btn>)
    expect(container.firstElementChild!.className).toContain('lp-btn--ghost')
  })

  it('is plain text and not large by default', () => {
    const { container } = render(<Btn href="#a">Go</Btn>)
    const btn = container.firstElementChild!
    expect(btn.className).not.toContain('lp-btn--lg')
    expect(btn.className).not.toContain('lp-btn--detailed')
    expect(btn.querySelector('.lp-btn__label')).toBeNull()
    expect(btn.textContent).toBe('Go')
  })

  it('treats a null detail as no detail', () => {
    const { container } = render(<Btn href="#a" detail={null}>Go</Btn>)
    const btn = container.firstElementChild!
    expect(btn.className).not.toContain('lp-btn--detailed')
    expect(btn.querySelector('.lp-btn__detail')).toBeNull()
    expect(btn.textContent).toBe('Go')
  })

  it('takes lg and a detail line under the label', () => {
    const { container } = render(
      <Btn href="#a" size="lg" detail="28.8 MB">
        Download
      </Btn>
    )
    const btn = container.firstElementChild!
    expect(btn.className).toContain('lp-btn--lg')
    expect(btn.className).toContain('lp-btn--detailed')
    expect(btn.querySelector('.lp-btn__label')!.textContent).toBe('Download')
    expect(btn.querySelector('.lp-btn__detail')!.textContent).toBe('28.8 MB')
  })
})

describe('StatusPill', () => {
  it('takes the free modifier', () => {
    const { container } = render(<StatusPill free>Coming soon</StatusPill>)
    expect(container.firstElementChild!.className).toContain('lp-status--free')
  })
})

describe('Trust', () => {
  it('is a list, one item each', () => {
    const { container } = render(<Trust items={['Free', 'macOS 14+']} />)
    expect(container.querySelectorAll('ul.lp-trust li')).toHaveLength(2)
  })

  it('trust-001: renders a ul.lp-trust with one li per element item', () => {
    const { container } = render(<Trust items={[<span>Claim A</span>, <span>Claim B</span>]} />)
    expect(container.innerHTML).toBe(
      '<ul class="lp-trust"><li><span>Claim A</span></li><li><span>Claim B</span></li></ul>'
    )
  })

  it('trust-002: the ul is the single root, with no wrapping element', () => {
    const { container } = render(<Trust items={[<span>Claim A</span>]} />)
    expect(container.children).toHaveLength(1)
    expect(container.firstElementChild!.tagName).toBe('UL')
    expect(container.querySelectorAll('ul')).toHaveLength(1)
  })

  it('trust-003: the ul carries class lp-trust', () => {
    const { container } = render(<Trust items={[<span>Claim A</span>]} />)
    expect(container.querySelector('ul')!.getAttribute('class')).toBe('lp-trust')
  })

  it('trust-004: every entry, including null, becomes an li in order', () => {
    const Badge = () => <em>Badge</em>
    const { container } = render(<Trust items={['Text', <Badge />, <span>Mixed</span>, null]} />)
    const lis = Array.from(container.querySelectorAll('ul.lp-trust > li'))
    expect(lis).toHaveLength(4)
    expect(lis.map((li) => li.innerHTML)).toEqual(['Text', '<em>Badge</em>', '<span>Mixed</span>', ''])
  })

  it('trust-005: an empty items array renders an empty ul.lp-trust', () => {
    const { container } = render(<Trust items={[]} />)
    expect(container.innerHTML).toBe('<ul class="lp-trust"></ul>')
  })
})

describe('Contact', () => {
  it('is a closer with a mailto and a colophon', () => {
    const { container } = render(
      <Contact
        title="Free, local, on the record."
        mail={{ href: 'mailto:hello@example.com', label: 'hello@example.com' }}
        colophon={<small>By someone</small>}
      >
        <p>Body.</p>
      </Contact>
    )
    expect(container.querySelector('.lp-closer')).toBeTruthy()
    expect(container.querySelector('a.lp-mail')!.getAttribute('href'))
      .toBe('mailto:hello@example.com')
    expect(container.querySelector('.lp-colophon')!.textContent).toBe('By someone')
  })
})

describe('Hero', () => {
  it('is a centred div screen with a glow, a mark, an h1 and a tagline', () => {
    const { container } = render(
      <Hero
        id="top"
        mark={<img alt="A mark" src="/m.svg" />}
        headline={<>On <b>the record</b>.</>}
        tagline="It records things."
      >
        <Cta><Btn href="#a">Go</Btn></Cta>
      </Hero>
    )
    const hero = container.firstElementChild!
    expect(hero.tagName).toBe('DIV')
    expect(hero.id).toBe('top')
    expect(hero.className).toContain('lp-screen')
    expect(hero.className).toContain('lp-screen--center')
    expect(hero.className).toContain('lp-hero')
    expect(hero.querySelector('.lp-glow')!.getAttribute('aria-hidden')).toBe('true')
    expect(hero.querySelector('img')!.getAttribute('alt')).toBe('A mark')
    expect(hero.querySelector('h1 b')!.textContent).toBe('the record')
    expect(hero.querySelector('p.lp-tag')!.textContent).toBe('It records things.')
    expect(hero.querySelector('.lp-cta .lp-btn')).toBeTruthy()
  })

  it('drops the glow when told to', () => {
    const { container } = render(<Hero headline="H" tagline="T" glow={false} />)
    expect(container.querySelector('.lp-glow')).toBeNull()
  })
})
