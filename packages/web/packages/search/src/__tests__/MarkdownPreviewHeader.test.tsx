// @vitest-environment jsdom
import { act, type ReactElement } from 'react'
import { createRoot, type Root } from 'react-dom/client'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { MarkdownPreviewHeader } from '../components/markdown/MarkdownPreviewHeader'
import { registerKindRenderer } from '../registry/kinds'
import type { PaperSearchHit } from '../registry/markdown'

// This package carries no @testing-library dependency, so a minimal render shim over
// react-dom stands in for it.
;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true
const mounted: { root: Root; host: HTMLElement }[] = []

function render(ui: ReactElement): HTMLElement {
  const host = document.createElement('div')
  document.body.appendChild(host)
  const root = createRoot(host)
  act(() => root.render(ui))
  mounted.push({ root, host })
  return host
}

const originalTz = process.env.TZ

beforeEach(() => {
  process.env.TZ = 'UTC'
})

afterEach(() => {
  for (const { root, host } of mounted.splice(0)) {
    act(() => root.unmount())
    host.remove()
  }
  if (originalTz === undefined) delete process.env.TZ
  else process.env.TZ = originalTz
})

function hit(over: Partial<PaperSearchHit> = {}): PaperSearchHit {
  return {
    id: 'p1',
    title: 'Example Paper',
    publicRoute: '/papers/example',
    author: { slug: 'alice', displayName: 'Alice Smith' },
    category: null,
    tags: [],
    snippet: '',
    createdAt: '',
    updatedAt: '',
    kind: 'paper',
    ...over,
  }
}

function header(h: PaperSearchHit, href = 'https://example.com/paper'): HTMLElement {
  return render(<MarkdownPreviewHeader hit={h} href={href} />)
}

const h3 = (c: HTMLElement): HTMLElement => c.querySelector('h3') as HTMLElement
const link = (c: HTMLElement): HTMLAnchorElement | null => c.querySelector('a')
const summaryP = (c: HTMLElement): HTMLElement | null =>
  [...c.querySelectorAll('p')].find((p) => p.textContent?.startsWith('Summary:')) ?? null
const metaRow = (c: HTMLElement): HTMLElement => c.querySelector('[data-slot="badge"]')!.parentElement as HTMLElement
const asAny = <T,>(v: unknown): T => v as T

describe('MarkdownPreviewHeader conformance vectors', () => {
  it('header-001 renders the title in an h3', () => {
    expect(h3(header(hit({ title: 'Example Paper' }))).textContent).toBe('Example Paper')
  })

  it('header-002 falls back to "Untitled" for an empty title and keeps an empty title attribute', () => {
    const el = h3(header(hit({ title: '' })))
    expect(el.textContent).toBe('Untitled')
    expect(el.getAttribute('title')).toBe('')
  })

  it('header-003 falls back to "Untitled" for a null title with no title attribute', () => {
    const el = h3(header(hit({ title: asAny<string>(null) })))
    expect(el.textContent).toBe('Untitled')
    expect(el.hasAttribute('title')).toBe(false)
  })

  it('header-004 falls back to "Untitled" for an undefined title with no title attribute', () => {
    const el = h3(header(hit({ title: asAny<string>(undefined) })))
    expect(el.textContent).toBe('Untitled')
    expect(el.hasAttribute('title')).toBe(false)
  })

  it('header-005 renders a whitespace-only title literally', () => {
    expect(h3(header(hit({ title: '   ' }))).textContent).toBe('   ')
  })

  it('header-006 puts the raw title in the title attribute', () => {
    expect(h3(header(hit({ title: 'Long Paper Title Here' }))).getAttribute('title')).toBe('Long Paper Title Here')
  })

  it('header-007 renders the research kind badge with its variant class and label', () => {
    const c = header(hit({ kind: 'research' }))
    const badge = c.querySelector('[data-slot="badge"]') as HTMLElement
    expect(badge.textContent).toBe('Research')
    expect(badge.className).toContain('border-apt-blue')
  })

  it('header-008 shows "by <displayName>"', () => {
    const c = header(hit({ author: { displayName: 'Alice Smith', slug: 'alice' } }))
    expect(c.textContent).toContain('by Alice Smith')
  })

  it('header-009 shows "by @slug" for a whitespace-only displayName', () => {
    const c = header(hit({ author: { displayName: '  ', slug: 'bob' } }))
    expect(c.textContent).toContain('by @bob')
  })

  it('header-010 shows "by @slug" for a null displayName', () => {
    const c = header(hit({ author: { displayName: null, slug: 'charlie' } }))
    expect(c.textContent).toContain('by @charlie')
  })

  it('header-011 shows "by @slug" for an undefined displayName', () => {
    const c = header(hit({ author: asAny({ displayName: undefined, slug: 'dave' }) }))
    expect(c.textContent).toContain('by @dave')
  })

  it('header-012 formats the date as "· Updated Sep 20, 2026" in UTC', () => {
    const c = header(hit({ updatedAt: '2026-09-20' }))
    expect(metaRow(c).textContent).toContain('· Updated Sep 20, 2026')
  })

  it('header-013 renders no date for a null updatedAt', () => {
    expect(header(hit({ updatedAt: asAny<string>(null) })).textContent).not.toContain('Updated')
  })

  it('header-014 renders no date for an undefined updatedAt', () => {
    expect(header(hit({ updatedAt: asAny<string>(undefined) })).textContent).not.toContain('Updated')
  })

  it('header-015 renders no date for an empty updatedAt', () => {
    expect(header(hit({ updatedAt: '' })).textContent).not.toContain('Updated')
  })

  it('header-016 renders the summary paragraph', () => {
    expect(summaryP(header(hit({ summary: 'This is a summary' })))).not.toBeNull()
  })

  it('header-017 prefixes the summary with a "Summary:" label span', () => {
    const p = summaryP(header(hit({ summary: 'This is a summary' })))!
    expect(p.textContent).toBe('Summary: This is a summary')
    const label = p.querySelector('span') as HTMLElement
    expect(label.textContent).toBe('Summary: ')
    expect(label.className).toContain('font-medium')
    expect(label.className).toContain('text-apt-text-dim')
    expect(p.className).toContain('text-apt-text-muted')
  })

  it('header-018 renders no summary for an empty string', () => {
    expect(summaryP(header(hit({ summary: '' })))).toBeNull()
  })

  it('header-019 renders no summary for whitespace only', () => {
    expect(summaryP(header(hit({ summary: '   ' })))).toBeNull()
  })

  it('header-020 renders no summary for null', () => {
    expect(summaryP(header(hit({ summary: null })))).toBeNull()
  })

  it('header-021 renders the element returned by previewExtra', () => {
    registerKindRenderer('t-extra', {
      badge: { label: 'Extra', variant: 'neutral' },
      rowSnippet: () => '',
      previewExtra: () => <section data-testid="extra">Extra content</section>,
    })
    const c = header(hit({ kind: 't-extra' }))
    expect(c.querySelector('[data-testid="extra"]')?.textContent).toBe('Extra content')
  })

  it('header-022 renders nothing extra when previewExtra returns null', () => {
    registerKindRenderer('t-null', {
      badge: { label: 'Null', variant: 'neutral' },
      rowSnippet: () => '',
      previewExtra: () => null,
    })
    const root = header(hit({ kind: 't-null' })).firstElementChild as HTMLElement
    // Only the title row and the metadata row.
    expect(root.children).toHaveLength(2)
  })

  it('header-023 renders nothing extra when previewExtra returns undefined', () => {
    registerKindRenderer('t-undef', {
      badge: { label: 'Undef', variant: 'neutral' },
      rowSnippet: () => '',
      previewExtra: () => undefined,
    })
    const root = header(hit({ kind: 't-undef' })).firstElementChild as HTMLElement
    expect(root.children).toHaveLength(2)
  })

  it('header-024 renders the "View full paper" link with the supplied href', () => {
    const a = link(header(hit({ publicRoute: '/papers/example' }), 'https://example.com/paper'))!
    expect(a.textContent).toBe('View full paper')
    expect(a.getAttribute('href')).toBe('https://example.com/paper')
    expect(a.hasAttribute('target')).toBe(false)
    expect(a.hasAttribute('rel')).toBe(false)
  })

  it('header-025 renders no link for an empty publicRoute', () => {
    expect(link(header(hit({ publicRoute: '' })))).toBeNull()
  })

  it('header-026 renders no link for an empty publicRoute even with a well-formed href', () => {
    expect(link(header(hit({ publicRoute: '' }), 'https://example.com/paper'))).toBeNull()
  })

  it('header-027 renders badge, author and date in that order in one row', () => {
    const c = header(hit({ updatedAt: '2026-09-20' }))
    const row = metaRow(c)
    expect(row.className).toContain('flex-wrap')
    const kids = [...row.children]
    expect(kids).toHaveLength(3)
    expect(kids[0].getAttribute('data-slot')).toBe('badge')
    expect(kids[1].textContent).toContain('by Alice Smith')
    expect(kids[2].textContent).toBe('· Updated Sep 20, 2026')
  })

  it('header-028 shows the previous day for a date-only string west of UTC', () => {
    process.env.TZ = 'America/Los_Angeles'
    const c = header(hit({ updatedAt: '2026-09-20' }))
    expect(metaRow(c).textContent).toContain('· Updated Sep 19, 2026')
  })

  it('header-029 renders no date for an unparseable updatedAt', () => {
    expect(header(hit({ updatedAt: 'not-a-date' })).textContent).not.toContain('Updated')
  })
})
