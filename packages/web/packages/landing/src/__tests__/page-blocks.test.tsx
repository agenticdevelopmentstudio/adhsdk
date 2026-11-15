import { isValidElement } from 'react'
import type { ReactElement } from 'react'
import { describe, expect, it } from 'vitest'
import { Btn } from '../blocks/Btn'
import { Card } from '../blocks/Card'
import { Code } from '../blocks/Code'
import { Faq } from '../blocks/Faq'
import { Roadmap } from '../blocks/Roadmap'
import { Shot } from '../blocks/Shot'
import { indexRows, prose, renderBlock } from '../page/blocks'
import type { LandingBlock, LandingPage } from '../page/types'

type Props = Record<string, any>
const propsOf = (e: unknown): Props => (e as ReactElement<Props>).props
const kids = (e: unknown): ReactElement[] => [propsOf(e).children].flat() as ReactElement[]

describe('page/blocks conformance vectors', () => {
  it('blocks-001 prose returns one keyed <p> per entry in order', () => {
    const out = prose(['a', 'b'])
    expect(out.map((p) => p.type)).toEqual(['p', 'p'])
    expect(out.map((p) => p.props.children)).toEqual(['a', 'b'])
    expect(out.map((p) => p.key)).toEqual(['0', '1'])
  })
  it('blocks-002 prose of an empty list is empty', () => {
    expect(prose([])).toEqual([])
  })
  it('blocks-003 Code block renders a Code with its text', () => {
    const el = renderBlock({ kind: 'Code', text: 'a b' }, 0)
    expect(el.type).toBe(Code)
    expect(propsOf(el).text).toBe('a b')
  })
  it('blocks-004 the key argument becomes the element key', () => {
    expect(renderBlock({ kind: 'Lede', children: 'x' }, 7).key).toBe('7')
  })
  it('blocks-005 a card icon resolves to /icons/<icon>.svg', () => {
    const el = renderBlock({ kind: 'Cards', items: [{ title: 't', icon: 'shield', body: [] }] }, 0)
    const card = kids(el)[0]
    expect(card.type).toBe(Card)
    expect(propsOf(card).icon).toBe('/icons/shield.svg')
  })
  it('blocks-006 a card with no icon gets none', () => {
    const el = renderBlock({ kind: 'Cards', items: [{ title: 't', body: [] }] }, 0)
    expect(propsOf(kids(el)[0]).icon).toBeUndefined()
  })
  it('blocks-007 a card body renders as <p> children', () => {
    const el = renderBlock({ kind: 'Cards', items: [{ title: 't', body: ['one', 'two'] }] }, 0)
    const body = propsOf(kids(el)[0]).children as ReactElement[]
    expect(body.map((p) => p.type)).toEqual(['p', 'p'])
  })
  it('blocks-008 a Shot with src gets an img as media', () => {
    const el = renderBlock({ kind: 'Shot', src: 'main-window', title: 'App', caption: 'The main window' }, 0)
    expect(el.type).toBe(Shot)
    const media = propsOf(el).media as ReactElement<Props>
    expect(media.type).toBe('img')
    expect(media.props.src).toBe('/screenshots/main-window.png')
    expect(media.props.alt).toBe('The main window')
  })
  it('blocks-009 a Shot with no src has no media and the default pending label', () => {
    const el = renderBlock({ kind: 'Shot', title: 'App', caption: 'c' }, 0)
    expect('media' in propsOf(el)).toBe(false)
    expect(propsOf(el).pendingLabel).toBe('Screenshot coming soon')
  })
  it('blocks-010 a Roadmap hands the pending label to nested blocks and keys them by index', () => {
    const el = renderBlock({ kind: 'Roadmap', children: [{ kind: 'Shot', title: 'App', caption: 'c' }] }, 0, 'Soon')
    expect(el.type).toBe(Roadmap)
    const child = kids(el)[0]
    expect(propsOf(child).pendingLabel).toBe('Soon')
    expect(child.key).toBe('0')
  })
  it('blocks-011 a Faq entry keeps open and renders its answer as one <p>', () => {
    const el = renderBlock({ kind: 'Faq', entries: [{ question: 'q', answer: ['a'], open: true }] }, 0)
    expect(el.type).toBe(Faq)
    const entry = propsOf(el).entries[0]
    expect(entry.open).toBe(true)
    expect(entry.answer).toHaveLength(1)
    expect(entry.answer[0].type).toBe('p')
  })
  it('blocks-012 a Cta renders one Btn per button, variant only when given', () => {
    const el = renderBlock(
      {
        kind: 'Cta',
        buttons: [
          { href: '/start', label: 'Get started' },
          { href: '/more', label: 'More', variant: 'ghost' },
        ],
      },
      0,
    )
    const [first, second] = kids(el)
    expect(first.type).toBe(Btn)
    expect(propsOf(first).href).toBe('/start')
    expect(propsOf(first).variant).toBeUndefined()
    expect(propsOf(second).variant).toBe('ghost')
  })
  it('blocks-013 an unknown kind is returned unrendered', () => {
    const block = { kind: 'Nope' } as unknown as LandingBlock
    const out = renderBlock(block, 0) as unknown
    expect(out).toBe(block)
    expect(isValidElement(out)).toBe(false)
  })

  const page = {
    hero: { headline: 'h', tagline: 't', blocks: [] },
    sections: [
      { id: 'what-it-is', eyebrow: 'What it is', blocks: [] },
      { id: 'what-it-does', eyebrow: 'What it does', blocks: [] },
      { id: 'the-shape', eyebrow: 'The shape', blocks: [] },
    ],
  } as LandingPage

  it('blocks-014 indexRows gives each section an #id href and its eyebrow as label', () => {
    expect(indexRows(page)).toEqual([
      { href: '#what-it-is', label: 'What it is' },
      { href: '#what-it-does', label: 'What it does' },
      { href: '#the-shape', label: 'The shape' },
    ])
  })
  it('blocks-015 indexRows has no row for the hero', () => {
    expect(indexRows(page)).toHaveLength(3)
  })
  it('blocks-016 a hero Shot with no image shows the host label, not the default', () => {
    const el = renderBlock({ kind: 'Shot', title: 'App', caption: 'Soon' }, 0, 'Screenshot pending')
    expect(propsOf(el).pendingLabel).toBe('Screenshot pending')
  })
})
