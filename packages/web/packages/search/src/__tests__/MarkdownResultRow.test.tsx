// @vitest-environment jsdom
import { act, createRef, type ReactElement } from 'react'
import { createRoot, type Root } from 'react-dom/client'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { MarkdownResultRow } from '../components/markdown/MarkdownResultRow'
import { registerKindRenderer } from '../registry/kinds'
import type { PaperSearchHit } from '../registry/markdown'

// This package carries no @testing-library dependency, so a minimal render/query shim over
// react-dom stands in for it.
;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true
const mounted: { root: Root; host: HTMLElement }[] = []

function render(ui: ReactElement): void {
  const host = document.createElement('div')
  document.body.appendChild(host)
  const root = createRoot(host)
  act(() => root.render(ui))
  mounted.push({ root, host })
}

function cleanup(): void {
  for (const { root, host } of mounted.splice(0)) {
    act(() => root.unmount())
    host.remove()
  }
}

const fireEvent = {
  click(el: Element): void {
    act(() => {
      el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
    })
  },
}

const screen = {
  getByRole(role: string, opts: { level?: number } = {}): HTMLElement {
    const sel =
      role === 'heading' ? `h${opts.level ?? 3}` : role === 'link' ? 'a[href]' : role === 'button' ? 'button' : `[role="${role}"]`
    const found = document.querySelectorAll<HTMLElement>(sel)
    if (found.length !== 1) throw new Error(`expected one ${role}, found ${found.length}`)
    return found[0]
  },
  getByText(text: string): HTMLElement {
    const found = [...document.querySelectorAll<HTMLElement>('body *')].filter(
      (e) => e.children.length === 0 && e.textContent === text,
    )
    if (found.length !== 1) throw new Error(`expected one "${text}", found ${found.length}`)
    return found[0]
  },
}

afterEach(cleanup)

function hit(over: Partial<PaperSearchHit> = {}): PaperSearchHit {
  return {
    id: 'p1',
    title: 'My Document',
    publicRoute: 'r',
    author: { slug: 'jdoe', displayName: 'Jane Doe' },
    category: null,
    tags: [],
    snippet: '',
    createdAt: '',
    updatedAt: '',
    kind: 'paper',
    ...over,
  }
}

function row(
  h: PaperSearchHit,
  props: Partial<Parameters<typeof MarkdownResultRow>[0]> = {},
) {
  return render(
    <MarkdownResultRow
      hit={h}
      href="/paper/123"
      query=""
      selected={false}
      onSelect={() => {}}
      {...props}
    />,
  )
}

describe('MarkdownResultRow conformance vectors', () => {
  it('mrr-001 renders the title in an h3', () => {
    row(hit({ title: 'My Document' }))
    expect(screen.getByRole('heading', { level: 3 }).textContent).toBe('My Document')
  })

  it('mrr-002 renders "Untitled" for a null or empty title', () => {
    row(hit({ title: '' }))
    expect(screen.getByRole('heading', { level: 3 }).textContent).toBe('Untitled')
    cleanup()
    row(hit({ title: null as unknown as string }))
    expect(screen.getByRole('heading', { level: 3 }).textContent).toBe('Untitled')
  })

  it('mrr-003 wraps a query match in the title in <mark>', () => {
    row(hit({ title: 'Search results' }), { query: 'search' })
    const marks = screen.getByRole('heading', { level: 3 }).querySelectorAll('mark')
    expect(marks).toHaveLength(1)
    expect(marks[0].textContent).toBe('Search')
  })

  it('mrr-004 renders no <mark> when the title does not match', () => {
    row(hit({ title: 'No match' }), { query: 'xyz' })
    expect(document.querySelectorAll('mark')).toHaveLength(0)
  })

  it('mrr-005 renders the badge from the registered renderer', () => {
    registerKindRenderer('mrr-test-kind', {
      badge: { label: 'Dataset', variant: 'blue' },
      rowSnippet: () => '',
      previewExtra: () => null,
    })
    row(hit({ kind: 'mrr-test-kind' }))
    expect(document.querySelector('[data-slot="badge"]')?.textContent).toBe('Dataset')
    cleanup()
    row(hit({ kind: 'paper' }))
    expect(document.querySelector('[data-slot="badge"]')?.textContent).toBe('Paper')
  })

  it('mrr-006 falls back to the default renderer badge for an unregistered kind', () => {
    expect(() => row(hit({ kind: 'unknown' }))).not.toThrow()
    expect(document.querySelector('[data-slot="badge"]')?.textContent).toBe('Document')
  })

  it('mrr-007 renders the trimmed snippet', () => {
    registerKindRenderer('mrr-padded', {
      badge: { label: 'Padded', variant: 'neutral' },
      rowSnippet: () => '  Some text  ',
      previewExtra: () => null,
    })
    row(hit({ kind: 'mrr-padded' }))
    const p = document.querySelector('p')
    expect(p?.textContent).toBe('Some text')
  })

  it('mrr-008 renders no snippet section when the snippet is empty', () => {
    row(hit({ snippet: '   ' }))
    expect(document.querySelector('p')).toBeNull()
  })

  it('mrr-009 wraps a query match in the snippet in <mark>', () => {
    row(hit({ snippet: 'Find results fast' }), { query: 'results' })
    const marks = document.querySelector('p')?.querySelectorAll('mark')
    expect(marks).toHaveLength(1)
    expect(marks?.[0].textContent).toBe('results')
  })

  it('mrr-010 clamps the snippet to two lines', () => {
    // jsdom has no layout, so the visible clamping is not measurable; the clamp utility is.
    row(hit({ snippet: 'a\nb\nc\nd\ne' }))
    expect(document.querySelector('p')?.className).toContain('line-clamp-2')
  })

  it('mrr-011 renders each tag as its own "#tag" element', () => {
    row(hit({ tags: ['tag1', 'tag2'] }))
    const a = screen.getByText('#tag1')
    const b = screen.getByText('#tag2')
    expect(a).not.toBe(b)
    expect(a.parentElement).toBe(b.parentElement)
    expect(a.parentElement?.textContent).toBe('#tag1#tag2')
  })

  it('mrr-012 renders no tags section for an empty list', () => {
    row(hit({ tags: [] }))
    expect(document.body.textContent).not.toContain('#')
  })

  it('mrr-013 renders the category in an uppercase capsule', () => {
    row(hit({ category: 'Research' }))
    const cap = screen.getByText('Research')
    expect(cap.className).toContain('uppercase')
    expect(cap.className).toContain('rounded-full')
  })

  it('mrr-014 renders no category for null or empty', () => {
    row(hit({ category: null }))
    expect(document.querySelector('span.border-apt-border')).toBeNull()
    cleanup()
    row(hit({ category: '' }))
    expect(document.querySelector('span.border-apt-border')).toBeNull()
  })

  it('mrr-015 renders "by <displayName>"', () => {
    row(hit({ author: { slug: 'jdoe', displayName: 'Jane Doe' } }))
    expect(document.body.textContent).toContain('by Jane Doe')
  })

  it('mrr-016 falls back to "by @slug" without a display name', () => {
    row(hit({ author: { slug: 'jdoe', displayName: '' } }))
    expect(document.body.textContent).toContain('by @jdoe')
    cleanup()
    row(hit({ author: { slug: 'jdoe', displayName: null } }))
    expect(document.body.textContent).toContain('by @jdoe')
  })

  it('mrr-017 renders the updated date after the author', () => {
    row(hit({ updatedAt: '2026-06-24T12:00:00Z' }))
    expect(document.body.textContent).toContain('by Jane Doe · Updated Jun 24, 2026')
  })

  it('mrr-018 renders no date when updatedAt is empty', () => {
    row(hit({ updatedAt: '' }))
    expect(document.body.textContent).not.toContain('Updated')
    cleanup()
    row(hit({ updatedAt: undefined as unknown as string }))
    expect(document.body.textContent).not.toContain('Updated')
  })

  it('mrr-019 calls onSelect with the hit when the button is clicked', () => {
    const onSelect = vi.fn()
    const h = hit()
    row(h, { onSelect })
    fireEvent.click(screen.getByRole('button'))
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect).toHaveBeenCalledWith(h)
  })

  it('mrr-020 uses the accent border when selected', () => {
    row(hit(), { selected: true })
    const cls = document.querySelector('article')?.className ?? ''
    expect(cls).toContain('border-apt-gold')
    expect(cls).not.toContain('border-apt-border')
  })

  it('mrr-021 uses the neutral border with a strong hover border when not selected', () => {
    row(hit(), { selected: false })
    const cls = document.querySelector('article')?.className ?? ''
    expect(cls).toContain('border-apt-border')
    expect(cls).toContain('hover:border-apt-border-strong')
    expect(cls).not.toContain('border-apt-gold')
  })

  it('mrr-022 sets aria-pressed="true" when selected', () => {
    row(hit(), { selected: true })
    expect(screen.getByRole('button').getAttribute('aria-pressed')).toBe('true')
  })

  it('mrr-023 sets aria-pressed="false" when not selected', () => {
    row(hit(), { selected: false })
    expect(screen.getByRole('button').getAttribute('aria-pressed')).toBe('false')
  })

  it('mrr-024 gives the button and link tabIndex 0 when active', () => {
    row(hit(), { active: true })
    expect(screen.getByRole('button').getAttribute('tabindex')).toBe('0')
    expect(screen.getByRole('link').getAttribute('tabindex')).toBe('0')
  })

  it('mrr-025 gives the button and link tabIndex -1 when inactive', () => {
    row(hit(), { active: false })
    expect(screen.getByRole('button').getAttribute('tabindex')).toBe('-1')
    expect(screen.getByRole('link').getAttribute('tabindex')).toBe('-1')
  })

  it('mrr-026 sets no tabindex when active is undefined', () => {
    row(hit(), { active: undefined })
    expect(screen.getByRole('button').hasAttribute('tabindex')).toBe(false)
    expect(screen.getByRole('link').hasAttribute('tabindex')).toBe(false)
  })

  it('mrr-027 forwards controlRef to the button element', () => {
    const controlRef = createRef<HTMLElement>()
    row(hit(), { controlRef })
    expect(controlRef.current).toBe(screen.getByRole('button'))
    expect(controlRef.current?.tagName).toBe('BUTTON')
  })

  it('mrr-028 gives the link tabIndex 0 when the button has 0', () => {
    row(hit(), { active: true })
    expect(screen.getByRole('link').getAttribute('tabindex')).toBe(
      screen.getByRole('button').getAttribute('tabindex'),
    )
    expect(screen.getByRole('link').getAttribute('tabindex')).toBe('0')
  })

  it('mrr-034 gives the link tabIndex -1 when the button has -1', () => {
    row(hit(), { active: false })
    expect(screen.getByRole('link').getAttribute('tabindex')).toBe('-1')
    expect(screen.getByRole('button').getAttribute('tabindex')).toBe('-1')
  })

  it('mrr-035 gives the link no tabindex when the button has none', () => {
    row(hit())
    expect(screen.getByRole('button').hasAttribute('tabindex')).toBe(false)
    expect(screen.getByRole('link').hasAttribute('tabindex')).toBe(false)
  })

  it.skip('mrr-029 the link ::after overlay is 24px tall (jsdom does not apply Tailwind CSS or pseudo-element layout)', () => {})

  it.skip('mrr-030 a touch near the link activates the 24px overlay (jsdom has no hit testing against pseudo-elements)', () => {})

  it('mrr-031 sets the link href', () => {
    row(hit(), { href: '/paper/123' })
    expect(screen.getByRole('link').getAttribute('href')).toBe('/paper/123')
  })

  it('mrr-032 renders markup in the title as text', () => {
    row(hit({ title: "<script>alert('xss')</script>" }))
    const h3 = screen.getByRole('heading', { level: 3 })
    expect(h3.textContent).toBe("<script>alert('xss')</script>")
    expect(document.querySelector('script')).toBeNull()
  })

  it.skip('mrr-033 computed border-radius equals --radius-lg / --radius-md (jsdom does not compile Tailwind or resolve CSS variables)', () => {})
})
