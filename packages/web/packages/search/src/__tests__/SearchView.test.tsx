// @vitest-environment jsdom
import { act, type ReactElement } from 'react'
import { createRoot, type Root } from 'react-dom/client'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { SearchView, type SearchViewProps } from '../components/SearchView'
import type {
  DocumentPreviewHeaderProps,
  DocumentPreviewProps,
  DocumentResultProps,
  DocumentTypeConfig,
  SearchSource,
} from '../types'

// This package carries no @testing-library dependency, so a minimal render/query shim over
// react-dom stands in for it.
;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true

interface Hit {
  id: string
  title: string
}

const SOURCE: SearchSource = {
  baseUrl: 'https://example.test/api',
  endpoints: { results: '/results', tags: '/tags', categories: '/categories' },
}

// ── fetch mock ───────────────────────────────────────────────────────────────
let resultHits: Hit[] = []
let resultStatus = 200
const fetchMock = vi.fn()

function installFetch(): void {
  fetchMock.mockReset()
  fetchMock.mockImplementation((input: string) => {
    const url = String(input)
    if (url.includes('/tags')) return Promise.resolve(json({ items: ['t1', 't2'] }))
    if (url.includes('/categories')) return Promise.resolve(json({ items: ['Research', 'Other'] }))
    if (resultStatus !== 200) return Promise.resolve(new Response('', { status: resultStatus }))
    return Promise.resolve(json({ object: 'list', data: resultHits, has_more: false, url: '' }))
  })
  vi.stubGlobal('fetch', fetchMock)
}

function json(body: unknown): Response {
  return new Response(JSON.stringify(body), { status: 200, headers: { 'content-type': 'application/json' } })
}

function hits(n: number): Hit[] {
  return Array.from({ length: n }, (_, i) => ({ id: `h${i}`, title: `Title ${i}` }))
}

function resultCalls(): string[] {
  return fetchMock.mock.calls.map((c) => String(c[0])).filter((u) => u.includes('/results'))
}

// ── document type ────────────────────────────────────────────────────────────
const rowProps: Array<DocumentResultProps<Hit>> = []

function Row(props: DocumentResultProps<Hit>): ReactElement {
  rowProps.push(props)
  const { hit, active, selected, onSelect, controlRef, href } = props
  return (
    <div data-row={hit.id} data-href={href}>
      <button
        type="button"
        ref={controlRef as (el: HTMLButtonElement | null) => void}
        tabIndex={active === undefined ? undefined : active ? 0 : -1}
        aria-pressed={selected}
        onClick={() => onSelect(hit)}
      >
        {hit.title}
      </button>
    </div>
  )
}

function Preview({ hit }: DocumentPreviewProps<Hit>): ReactElement {
  return <p data-testid="preview-body">body {hit.id}</p>
}

function PreviewHeader({ hit }: DocumentPreviewHeaderProps<Hit>): ReactElement {
  return <h3 data-testid="preview-header">header {hit.id}</h3>
}

const documentType: DocumentTypeConfig<Hit> = {
  type: 'markdown',
  getId: (h) => h.id,
  getTitle: (h) => `T:${h.id}`,
  fromWire: (w) => w as Hit,
  ResultRow: Row,
  PreviewHeader,
  Preview,
}

// ── rendering helpers ────────────────────────────────────────────────────────
let root: Root | null = null
let host: HTMLElement | null = null

function mount(props: Partial<SearchViewProps<Hit>> = {}): void {
  host = document.createElement('div')
  document.body.appendChild(host)
  root = createRoot(host)
  act(() => {
    root!.render(
      <SearchView<Hit>
        source={SOURCE}
        documentType={documentType as DocumentTypeConfig<Hit>}
        documentHref={(h) => `/docs/${h.id}`}
        {...props}
      />,
    )
  })
}

async function advance(ms: number): Promise<void> {
  await act(async () => {
    await vi.advanceTimersByTimeAsync(ms)
  })
}

function q<T extends Element = HTMLElement>(sel: string): T | null {
  return document.querySelector<T>(sel)
}

function must<T extends Element = HTMLElement>(sel: string): T {
  const el = q<T>(sel)
  if (!el) throw new Error(`no element for ${sel}`)
  return el
}

const input = (): HTMLInputElement => must<HTMLInputElement>('input[type="search"]')
const list = (): HTMLElement => must('ul[aria-label="Search results"]')
const rows = (): HTMLButtonElement[] =>
  [...document.querySelectorAll<HTMLButtonElement>('[data-row] button')]
const toggle = (): HTMLButtonElement =>
  must<HTMLButtonElement>('section[aria-label="Document preview"] button[aria-expanded]')
const previewRegion = (): HTMLElement | null => q('[aria-label="Document preview content"]')
const dock = (): HTMLElement => must('section[aria-label="Document preview"]')

function textIn(el: Element): string {
  return el.textContent ?? ''
}

function setValue(el: HTMLInputElement | HTMLSelectElement, value: string, event: string): void {
  const proto = el instanceof HTMLSelectElement ? HTMLSelectElement.prototype : HTMLInputElement.prototype
  Object.getOwnPropertyDescriptor(proto, 'value')!.set!.call(el, value)
  act(() => {
    el.dispatchEvent(new Event(event, { bubbles: true }))
  })
}

function type(value: string): void {
  setValue(input(), value, 'input')
}

function pick(label: string, value: string): void {
  setValue(must<HTMLSelectElement>(`select[aria-label="${label}"]`), value, 'change')
}

function key(el: Element, k: string): void {
  act(() => {
    el.dispatchEvent(new KeyboardEvent('keydown', { key: k, bubbles: true, cancelable: true }))
  })
}

function click(el: Element): void {
  act(() => {
    ;(el as HTMLElement).click()
  })
}

function focus(el: HTMLElement): void {
  act(() => el.focus())
}

/** Type a query and let its debounced fetch settle with `n` hits. */
async function search(n: number, props: Partial<SearchViewProps<Hit>> = {}): Promise<void> {
  resultHits = hits(n)
  mount(props)
  await advance(0) // facets
  type('foo')
  await advance(400)
}

async function openRow(index: number): Promise<void> {
  click(rows()[index])
  await advance(0)
}

beforeEach(() => {
  vi.useFakeTimers()
  window.history.replaceState(null, '', '/')
  resultHits = []
  resultStatus = 200
  rowProps.length = 0
  installFetch()
})

afterEach(() => {
  if (root) act(() => root!.unmount())
  host?.remove()
  root = null
  host = null
  vi.useRealTimers()
  vi.unstubAllGlobals()
})

describe('SearchView conformance vectors', () => {
  it('search-view-001 fetches nothing and shows the prompt with no query and no facets', async () => {
    mount()
    await advance(1000)
    expect(resultCalls()).toHaveLength(0)
    expect(document.body.textContent).toContain('Search research documents to get started.')
    expect(q('ul')).toBeNull()
  })

  it('search-view-002 debounces the fetch by the default 250ms', async () => {
    mount()
    await advance(0)
    type('foo')
    await advance(249)
    expect(resultCalls()).toHaveLength(0)
    await advance(2)
    expect(resultCalls()).toHaveLength(1)
  })

  it('search-view-003 fires the fetch immediately on Enter', async () => {
    mount()
    await advance(0)
    type('foo')
    key(input(), 'Enter')
    await advance(1)
    expect(resultCalls()).toHaveLength(1)
  })

  it('search-view-004 renders 3 busy skeleton bars once a query is active', async () => {
    mount()
    await advance(0)
    type('foo')
    const skeleton = must('ul[aria-label="Loading results"]')
    expect(skeleton.getAttribute('aria-busy')).toBe('true')
    expect(skeleton.querySelectorAll('li')).toHaveLength(3)
  })

  it('search-view-005 shows a live result count when results settle', async () => {
    await search(3)
    expect(textIn(must('[role="status"]'))).toBe('3 results')
  })

  it('search-view-006 ArrowDown moves focus to the next row', async () => {
    await search(3)
    const r = rows()
    focus(r[0])
    key(r[0], 'ArrowDown')
    expect(document.activeElement).toBe(rows()[1])
    expect(rows()[1].tabIndex).toBe(0)
    expect(rows()[0].tabIndex).toBe(-1)
  })

  it('search-view-007 ArrowDown on the last row stays on it', async () => {
    await search(3)
    focus(rows()[2])
    key(rows()[2], 'ArrowDown')
    key(rows()[2], 'ArrowDown')
    key(rows()[2], 'ArrowDown')
    expect(document.activeElement).toBe(rows()[2])
    expect(rows()[2].tabIndex).toBe(0)
  })

  it('search-view-008 Home moves focus to the first row and resets the index', async () => {
    await search(4)
    key(rows()[0], 'ArrowDown')
    key(rows()[1], 'ArrowDown')
    key(rows()[2], 'Home')
    expect(document.activeElement).toBe(rows()[0])
    expect(rows()[0].tabIndex).toBe(0)
  })

  it('search-view-009 End moves focus to the last row', async () => {
    await search(4)
    focus(rows()[0])
    key(rows()[0], 'End')
    expect(document.activeElement).toBe(rows()[3])
    expect(rows()[3].tabIndex).toBe(0)
  })

  it('search-view-010 shows "No matching documents" and no Retry for zero results', async () => {
    await search(0)
    expect(document.body.textContent).toContain('No matching documents')
    expect(document.body.textContent).not.toContain('Retry')
  })

  it('search-view-011 shows the full error block with Retry when the fetch fails with no results', async () => {
    resultStatus = 500
    await search(0)
    const alert = must('[role="alert"]')
    expect(textIn(alert)).toContain('Search request failed (HTTP 500).')
    expect(textIn(alert)).toContain('Retry')
    expect(alert.className).toContain('min-h-[160px]')
  })

  it('search-view-012 shows a compact error strip above cached results', async () => {
    await search(2)
    resultStatus = 500
    key(input(), 'Enter')
    await advance(10)
    const alert = must('[role="alert"]')
    expect(alert.className).not.toContain('min-h-[160px]')
    expect(textIn(alert)).toContain('Retry')
    expect(rows()).toHaveLength(2)
    expect(alert.compareDocumentPosition(list()) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('search-view-013 shows a removable category chip and Clear filters', async () => {
    window.history.replaceState(null, '', '/?category=Research')
    mount()
    await advance(0)
    expect(document.body.textContent).toContain('Category: Research')
    expect(must('button[aria-label="Remove category filter Research"]')).toBeTruthy()
    expect(document.body.textContent).toContain('Clear filters')
  })

  it('search-view-014 shows a removable tag chip and Clear filters', async () => {
    window.history.replaceState(null, '', '/?tag=t1')
    mount()
    await advance(0)
    expect(document.body.textContent).toContain('Tag: t1')
    expect(must('button[aria-label="Remove tag filter t1"]')).toBeTruthy()
    expect(document.body.textContent).toContain('Clear filters')
  })

  it('search-view-015 Clear filters clears facets but keeps the query', async () => {
    window.history.replaceState(null, '', '/?q=foo&category=Research&tag=t1')
    mount()
    await advance(0)
    const clear = [...document.querySelectorAll('button')].find((b) => textIn(b) === 'Clear filters')!
    click(clear)
    expect(document.body.textContent).not.toContain('Category: Research')
    expect(document.body.textContent).not.toContain('Tag: t1')
    expect(input().value).toBe('foo')
  })

  it('search-view-016 selecting a result discloses the dock and focuses the preview region', async () => {
    await search(3)
    await openRow(1)
    expect(toggle().getAttribute('aria-expanded')).toBe('true')
    expect(document.activeElement).toBe(previewRegion())
  })

  it('search-view-017 Escape in the preview collapses it and returns focus to row 2', async () => {
    await search(4)
    key(rows()[0], 'ArrowDown')
    key(rows()[1], 'ArrowDown')
    await openRow(2)
    expect(document.activeElement).toBe(previewRegion())
    key(previewRegion()!, 'Escape')
    expect(previewRegion()).toBeNull()
    expect(toggle().getAttribute('aria-expanded')).toBe('false')
    expect(rows().every((r) => r.getAttribute('aria-pressed') === 'false')).toBe(true)
    expect(document.activeElement).toBe(rows()[2])
  })

  it('search-view-018 the preview content div (tabIndex -1) takes programmatic focus on select', async () => {
    await search(2)
    await openRow(0)
    const region = previewRegion()!
    expect(region.tagName).toBe('DIV')
    expect(region.getAttribute('tabindex')).toBe('-1')
    expect(document.activeElement).toBe(region)
  })

  it('search-view-019 shows a keyboard-operable SplitDivider while the dock is disclosed', async () => {
    await search(2)
    await openRow(0)
    const sep = must('[role="separator"]')
    expect(sep.getAttribute('aria-label')).toBe('Resize preview')
    const before = sep.getAttribute('aria-valuenow')
    focus(sep)
    key(sep, 'ArrowDown')
    expect(must('[role="separator"]').getAttribute('aria-valuenow')).not.toBe(before)
    // Draggable: it carries the pointer handlers' touch-none grab surface.
    expect(sep.className).toContain('touch-none')
  })

  it('search-view-020 renders no SplitDivider while the dock is collapsed', async () => {
    await search(2)
    expect(q('[role="separator"]')).toBeNull()
  })

  it('search-view-021 writes q, tag and category to the URL when urlSync is on', async () => {
    mount()
    await advance(0)
    type('foo')
    pick('Filter by tag', 't1')
    pick('Filter by category', 'Research')
    await advance(400)
    const p = new URLSearchParams(window.location.search)
    expect(p.get('q')).toBe('foo')
    expect(p.get('tag')).toBe('t1')
    expect(p.get('category')).toBe('Research')
  })

  it('search-view-022 re-syncs filters from the URL on popstate', async () => {
    mount()
    await advance(0)
    window.history.replaceState(null, '', '/?q=back&tag=t1')
    act(() => {
      window.dispatchEvent(new PopStateEvent('popstate'))
    })
    expect(input().value).toBe('back')
    expect(document.body.textContent).toContain('Tag: t1')
    resultHits = hits(2)
    await advance(400)
    expect(rows()).toHaveLength(2)
    expect(resultCalls().some((u) => u.includes('q=back'))).toBe(true)
  })

  it('search-view-023 labels the result list "Search results"', async () => {
    await search(2)
    expect(list().tagName).toBe('UL')
  })

  it('search-view-024 the count is a polite status region that updates', async () => {
    await search(3)
    const status = must('[role="status"]')
    expect(status.getAttribute('aria-live')).toBe('polite')
    expect(textIn(status)).toBe('3 results')
    resultHits = hits(1)
    key(input(), 'Enter')
    await advance(10)
    expect(textIn(must('[role="status"]'))).toBe('1 result')
  })

  it('search-view-025 uses the default placeholder "Search…"', () => {
    mount()
    expect(input().getAttribute('placeholder')).toBe('Search…')
  })

  it('search-view-026 debounceMs={500} replaces the default 250ms', async () => {
    mount({ debounceMs: 500 })
    await advance(0)
    type('foo')
    await advance(499)
    expect(resultCalls()).toHaveLength(0)
    await advance(2)
    expect(resultCalls()).toHaveLength(1)
  })

  it('search-view-027 clamps the active index when the result set shrinks', async () => {
    await search(6)
    for (let i = 0; i < 5; i++) key(rows()[Math.min(i, 5)], 'ArrowDown')
    expect(rows()[5].tabIndex).toBe(0)
    resultHits = hits(2)
    key(input(), 'Enter')
    await advance(10)
    expect(rows()).toHaveLength(2)
    expect(rows()[1].tabIndex).toBe(0)
    expect(rows()[0].tabIndex).toBe(-1)
  })

  it('search-view-028 Escape in the list collapses the preview and leaves focus where it is', async () => {
    await search(3)
    await openRow(1)
    focus(rows()[1])
    key(rows()[1], 'Escape')
    expect(previewRegion()).toBeNull()
    expect(rows().every((r) => r.getAttribute('aria-pressed') === 'false')).toBe(true)
    expect(document.activeElement).toBe(rows()[1])
  })

  it('search-view-029 collapse then re-expand does not move focus into the preview', async () => {
    await search(2)
    await openRow(0)
    focus(toggle())
    click(toggle())
    await advance(0)
    expect(previewRegion()).toBeNull()
    click(toggle())
    await advance(0)
    expect(previewRegion()).not.toBeNull()
    expect(document.activeElement).not.toBe(previewRegion())
    expect(document.activeElement).toBe(toggle())
  })

  it('search-view-030 wraps the search and filter bar in a role=search landmark "Document search"', () => {
    mount()
    const lm = must('[role="search"]')
    expect(lm.getAttribute('aria-label')).toBe('Document search')
    expect(lm.contains(input())).toBe(true)
    expect(lm.querySelector('select[aria-label="Filter by tag"]')).not.toBeNull()
  })

  it('search-view-031 labels the search input "Search documents"', () => {
    mount()
    expect(input().getAttribute('aria-label')).toBe('Search documents')
  })

  it('search-view-032 labels the preview dock section "Document preview"', async () => {
    mount()
    await advance(0)
    type('foo')
    expect(dock().tagName).toBe('SECTION')
  })

  it('search-view-033 labels the disclosed preview content region', async () => {
    await search(2)
    await openRow(0)
    expect(must('[aria-label="Document preview content"]')).toBeTruthy()
  })

  it('search-view-034 the collapsed header bar reads "Preview" with no selection', async () => {
    await search(2)
    expect(textIn(dock())).toContain('Preview')
    expect(textIn(dock())).toContain('Select a result to preview it.')
    expect(q('[data-testid="preview-header"]')).toBeNull()
  })

  it('search-view-035 the collapsed header bar shows the selected hit title', async () => {
    await search(2)
    await openRow(1)
    click(toggle())
    await advance(0)
    expect(textIn(dock())).toContain('T:h1')
  })

  it('search-view-036 the disclosed header renders the type PreviewHeader', async () => {
    await search(2)
    await openRow(1)
    expect(textIn(must('[data-testid="preview-header"]'))).toBe('header h1')
    expect(dock().contains(must('[data-testid="preview-header"]'))).toBe(true)
  })

  it('search-view-037 disclosed with no selection: no header, one "Select a result" text', async () => {
    await search(2)
    click(toggle())
    await advance(0)
    expect(q('[data-testid="preview-header"]')).toBeNull()
    const matches = [...document.querySelectorAll('p')].filter(
      (p) => textIn(p) === 'Select a result to preview it.',
    )
    expect(matches).toHaveLength(1)
  })

  it('search-view-038 Escape from the dock toggle collapses it and returns focus to row 2', async () => {
    await search(4)
    key(rows()[0], 'ArrowDown')
    key(rows()[1], 'ArrowDown')
    await openRow(2)
    focus(toggle())
    key(toggle(), 'Escape')
    expect(previewRegion()).toBeNull()
    expect(rows().every((r) => r.getAttribute('aria-pressed') === 'false')).toBe(true)
    expect(document.activeElement).toBe(rows()[2])
  })

  it('search-view-039 removing the category chip leaves the tag filter', async () => {
    window.history.replaceState(null, '', '/?category=Research&tag=t1')
    mount()
    await advance(0)
    click(must('button[aria-label="Remove category filter Research"]'))
    expect(document.body.textContent).not.toContain('Category: Research')
    expect(document.body.textContent).toContain('Tag: t1')
  })

  it('search-view-040 re-selecting the open hit focuses the preview without changing state', async () => {
    await search(3)
    await openRow(1)
    focus(input())
    click(rows()[1])
    await advance(0)
    expect(document.activeElement).toBe(previewRegion())
    expect(toggle().getAttribute('aria-expanded')).toBe('true')
    expect(rows()[1].getAttribute('aria-pressed')).toBe('true')
    expect(textIn(must('[data-testid="preview-header"]'))).toBe('header h1')
  })

  it('search-view-041 Escape in the list with no selection changes nothing', async () => {
    await search(3)
    focus(rows()[1])
    key(rows()[1], 'Escape')
    expect(document.activeElement).toBe(rows()[1])
    expect(toggle().getAttribute('aria-expanded')).toBe('false')
    expect(rows()).toHaveLength(3)
  })

  it('search-view-042 Escape returns focus to the active-index row, not the clicked one', async () => {
    await search(5)
    focus(rows()[0])
    await openRow(3)
    expect(rows()[3].getAttribute('aria-pressed')).toBe('true')
    focus(previewRegion()!)
    key(previewRegion()!, 'Escape')
    expect(previewRegion()).toBeNull()
    expect(rows()[3].getAttribute('aria-pressed')).toBe('false')
    expect(document.activeElement).toBe(rows()[0])
  })

  it('search-view-043 requests the source base URL and results endpoint', async () => {
    await search(1)
    const url = resultCalls()[0]
    expect(url.startsWith('https://example.test/api/results?')).toBe(true)
    expect(new URL(url).searchParams.get('q')).toBe('foo')
  })

  it('search-view-044 renders hits through the supplied ResultRow, Preview and PreviewHeader', async () => {
    await search(2)
    expect(document.querySelectorAll('[data-row]')).toHaveLength(2)
    await openRow(0)
    expect(textIn(must('[data-testid="preview-body"]'))).toBe('body h0')
    expect(textIn(must('[data-testid="preview-header"]'))).toBe('header h0')
  })

  it('search-view-045 passes documentHref(hit) to each ResultRow', async () => {
    await search(3)
    const hrefs = [...document.querySelectorAll('[data-row]')].map((e) => e.getAttribute('data-href'))
    expect(hrefs).toEqual(['/docs/h0', '/docs/h1', '/docs/h2'])
  })

  it('search-view-046 mounts the query input and both filter dropdowns with no query', () => {
    mount()
    expect(input()).toBeTruthy()
    expect(q('select[aria-label="Filter by category"]')).not.toBeNull()
    expect(q('select[aria-label="Filter by tag"]')).not.toBeNull()
  })

  it('search-view-047 one ul holds an li per hit and each ResultRow gets its full props', async () => {
    await search(3)
    expect(document.querySelectorAll('ul[aria-label="Search results"]')).toHaveLength(1)
    expect(list().querySelectorAll(':scope > li')).toHaveLength(3)
    const last = new Map(rowProps.map((p) => [p.hit.id, p]))
    expect(last.size).toBe(3)
    for (const p of last.values()) {
      expect(typeof p.href).toBe('string')
      expect(p.query).toBe('foo')
      expect(typeof p.selected).toBe('boolean')
      expect(typeof p.active).toBe('boolean')
      expect(typeof p.controlRef).toBe('function')
      expect(typeof p.onSelect).toBe('function')
    }
  })

  it('search-view-048 ArrowDown twice moves the index to 2 without selecting or opening a preview', async () => {
    await search(4)
    focus(rows()[0])
    key(rows()[0], 'ArrowDown')
    key(rows()[1], 'ArrowDown')
    expect(rows()[2].tabIndex).toBe(0)
    expect(rows().every((r) => r.getAttribute('aria-pressed') === 'false')).toBe(true)
    expect(previewRegion()).toBeNull()
    expect(q('[data-testid="preview-header"]')).toBeNull()
  })

  it('search-view-049 renders the dock below the list as a header bar with a toggle and no body', async () => {
    await search(2)
    const d = dock()
    expect(d.compareDocumentPosition(list()) & Node.DOCUMENT_POSITION_PRECEDING).toBeTruthy()
    expect(textIn(d)).toContain('Preview')
    expect(toggle()).toBeTruthy()
    expect(previewRegion()).toBeNull()
  })

  it('search-view-050 the list container is aria-busy during a re-query and not after', async () => {
    await search(2)
    const container = list().parentElement!
    expect(container.hasAttribute('aria-busy')).toBe(false)
    type('foo bar')
    expect(list().parentElement!.getAttribute('aria-busy')).toBe('true')
    await advance(400)
    expect(list().parentElement!.hasAttribute('aria-busy')).toBe(false)
  })

  it('search-view-051 labels the category dropdown "Filter by category" with options', async () => {
    mount()
    await advance(0)
    const sel = must<HTMLSelectElement>('select[aria-label="Filter by category"]')
    expect([...sel.options].map((o) => o.value)).toEqual(['', 'Research', 'Other'])
  })

  it('search-view-052 labels the tag dropdown "Filter by tag" with options', async () => {
    mount()
    await advance(0)
    const sel = must<HTMLSelectElement>('select[aria-label="Filter by tag"]')
    expect([...sel.options].map((o) => o.value)).toEqual(['', 't1', 't2'])
  })

  it('search-view-053 matches the selected row by the getId value', async () => {
    await search(2)
    await openRow(1)
    expect(rows()[1].getAttribute('aria-pressed')).toBe('true')
    expect(rows()[0].getAttribute('aria-pressed')).toBe('false')
  })

  it('search-view-054 the collapsed header shows what getTitle returns', async () => {
    await search(2)
    await openRow(0)
    click(toggle())
    await advance(0)
    expect(textIn(dock())).toContain('T:h0')
    expect(textIn(dock())).not.toContain('Title 0')
  })

  it('search-view-055 labels the loading skeleton list "Loading results"', async () => {
    mount()
    await advance(0)
    type('foo')
    expect(must('ul[aria-label="Loading results"]')).toBeTruthy()
  })

  it('search-view-056 urlSync={false} leaves the URL alone and filters still work', async () => {
    mount({ urlSync: false })
    await advance(0)
    resultHits = hits(2)
    type('foo')
    pick('Filter by tag', 't1')
    await advance(600)
    expect(window.location.search).toBe('')
    const url = new URL(resultCalls().at(-1)!)
    expect(url.searchParams.get('q')).toBe('foo')
    expect(url.searchParams.get('tag')).toBe('t1')
    expect(rows()).toHaveLength(2)
  })

  it('search-view-057 searchLabel and searchLandmarkLabel replace the defaults', () => {
    mount({ searchLabel: 'Find', searchLandmarkLabel: 'Site search' })
    expect(input().getAttribute('aria-label')).toBe('Find')
    expect(must('[role="search"]').getAttribute('aria-label')).toBe('Site search')
  })

  it('search-view-058 an initial failure replaces the skeleton with the error block, nothing busy', async () => {
    resultStatus = 500
    mount()
    await advance(0)
    type('foo')
    expect(q('ul[aria-label="Loading results"]')).not.toBeNull()
    await advance(400)
    expect(q('ul[aria-label="Loading results"]')).toBeNull()
    const alert = must('[role="alert"]')
    expect(textIn(alert)).toContain('Search request failed (HTTP 500).')
    expect(textIn(alert)).toContain('Retry')
    expect(q('[aria-busy]')).toBeNull()
  })
})
