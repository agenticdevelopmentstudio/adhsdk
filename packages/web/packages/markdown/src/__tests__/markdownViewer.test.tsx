// @vitest-environment jsdom
// MarkdownViewer — conformance vectors mdv-001..018.
/// <reference types="@testing-library/jest-dom/vitest" />
import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest'
import { render, screen, cleanup, fireEvent, waitFor, act } from '@testing-library/react'
import { MarkdownViewer } from '../components/MarkdownViewer'
import type { MarkdownFetcher } from '../hooks/useMarkdownDocument'
import type { MarkdownDocument } from '../types'
import { MDV_PALETTES } from '../themes/palettes'

const STORAGE_KEY = 'adh-mdv-theme'

function doc(content: string, title = 'Doc'): MarkdownDocument {
  return { id: 'x', title, content } as MarkdownDocument
}

function fetcherFor(content: string, title = 'Doc'): MarkdownFetcher {
  return vi.fn(async () => doc(content, title))
}

/** A fetch mock that hangs until its signal aborts, then rejects like native fetch. */
function hangingFetch(signals: AbortSignal[] = []) {
  return vi.fn((_url: string, init?: RequestInit) => {
    const signal = init!.signal as AbortSignal
    signals.push(signal)
    return new Promise<Response>((_resolve, reject) => {
      signal.addEventListener('abort', () => reject(new Error('aborted')))
    })
  })
}

beforeEach(() => {
  window.localStorage.clear()
})

afterEach(() => {
  cleanup()
  vi.useRealTimers()
  vi.unstubAllGlobals()
  window.localStorage.clear()
})

describe('MarkdownViewer', () => {
  it('mdv-001 fetches the document by id through the fetcher', async () => {
    const fetcher = fetcherFor('hello')
    render(<MarkdownViewer id="abc123" fetcher={fetcher} />)
    await waitFor(() => expect(fetcher).toHaveBeenCalledTimes(1))
    expect(vi.mocked(fetcher).mock.calls[0]![0]).toBe('abc123')
    expect(vi.mocked(fetcher).mock.calls[0]![1]).toBeInstanceOf(AbortSignal)
  })

  it('mdv-002 enters idle state with no fetch when id is undefined', () => {
    const fetcher = fetcherFor('hello')
    render(<MarkdownViewer id={undefined} fetcher={fetcher} />)
    expect(fetcher).not.toHaveBeenCalled()
    expect(screen.getByText('No document selected.')).toBeInTheDocument()
  })

  it('mdv-003 aborts the fetch signal at timeoutMs and shows the error state (default fetcher)', async () => {
    vi.useFakeTimers()
    const signals: AbortSignal[] = []
    vi.stubGlobal('fetch', hangingFetch(signals))
    render(<MarkdownViewer id="slow" timeoutMs={5000} />)
    expect(signals).toHaveLength(1)
    expect(signals[0]!.aborted).toBe(false)
    await act(async () => {
      await vi.advanceTimersByTimeAsync(4999)
    })
    expect(signals[0]!.aborted).toBe(false)
    await act(async () => {
      await vi.advanceTimersByTimeAsync(2)
    })
    expect(signals[0]!.aborted).toBe(true)
    expect(screen.getByRole('alert')).toHaveTextContent('Failed to load document')
    expect(screen.getByRole('alert')).toHaveTextContent('Timed out loading document after 5s.')
  })

  it('mdv-004 shows the error message in the detail text when the fetch fails', async () => {
    const fetcher: MarkdownFetcher = vi.fn(async () => {
      throw new Error('Boom: backend down')
    })
    render(<MarkdownViewer id="abc" fetcher={fetcher} />)
    const alert = await screen.findByRole('alert')
    expect(alert).toHaveTextContent('Failed to load document')
    expect(alert.querySelector('.adh-mv-state-detail')).toHaveTextContent('Boom: backend down')
  })

  it('mdv-005 strips <script> from rendered markdown', async () => {
    const alertSpy = vi.fn()
    vi.stubGlobal('alert', alertSpy)
    const { container } = render(
      <MarkdownViewer id="a" fetcher={fetcherFor("para\n\n<script>alert('xss')</script>\n\nafter")} />,
    )
    await screen.findByText('after')
    // The only <script> in the tree is the viewer's own theme bootstrap script.
    expect(container.querySelectorAll('script')).toHaveLength(1)
    expect(container.textContent).not.toContain("alert('xss')")
    expect(alertSpy).not.toHaveBeenCalled()
  })

  it('mdv-006 highlights code blocks with inline --shiki-light/--shiki-dark variables', async () => {
    const { container } = render(
      <MarkdownViewer id="a" fetcher={fetcherFor('```js\nvar x=1;\n```')} />,
    )
    await waitFor(() => expect(container.querySelector('code span')).not.toBeNull())
    const code = container.querySelector('code')!
    const spans = Array.from(code.querySelectorAll('span'))
    expect(spans.length).toBeGreaterThan(0)
    const styled = spans.filter((s) => {
      const style = s.getAttribute('style') ?? ''
      return style.includes('--shiki-light') && style.includes('--shiki-dark')
    })
    expect(styled.length).toBeGreaterThan(0)
    // No bare color property: colors only arrive through the custom properties.
    for (const s of spans) {
      expect(s.getAttribute('style') ?? '').not.toMatch(/(^|;)\s*color\s*:/)
    }
  })

  it('mdv-007 persists the selected theme across a remount', async () => {
    const first = render(<MarkdownViewer id="a" fetcher={fetcherFor('hi')} />)
    fireEvent.change(screen.getByRole('combobox'), { target: { value: 'sepia' } })
    expect(window.localStorage.getItem(STORAGE_KEY)).toBe('sepia')
    first.unmount()
    const second = render(<MarkdownViewer id="a" fetcher={fetcherFor('hi')} />)
    expect((screen.getByRole('combobox') as HTMLSelectElement).value).toBe('sepia')
    expect(second.container.querySelector('.adh-mv-content')).toHaveAttribute('data-mdv-theme', 'sepia')
  })

  it('mdv-008 applies the active palette as inline --mdv-* custom properties on the content root', () => {
    const { container } = render(<MarkdownViewer id={undefined} />)
    const root = container.querySelector('.adh-mv-content') as HTMLElement
    expect(root.style.getPropertyValue('--mdv-text')).toBe(MDV_PALETTES['dark']!['--mdv-text'])
    fireEvent.change(screen.getByRole('combobox'), { target: { value: 'light' } })
    expect(root.style.getPropertyValue('--mdv-text')).toBe(MDV_PALETTES['light']!['--mdv-text'])
    expect(root.style.getPropertyValue('--mdv-text')).not.toBe(MDV_PALETTES['dark']!['--mdv-text'])
  })

  it('mdv-009 renders a toolbar with the title and the theme switcher', async () => {
    render(<MarkdownViewer id="a" fetcher={fetcherFor('hi', 'Toolbar Title')} />)
    expect(screen.getByRole('combobox', { name: 'Select reading theme' })).toBeVisible()
    expect(screen.getByText('Theme')).toBeVisible()
    expect(await screen.findByText('Toolbar Title')).toBeVisible()
  })

  it('mdv-010 shows the fetched document title in the toolbar', async () => {
    render(<MarkdownViewer id="a" fetcher={fetcherFor('hi', 'My Doc')} />)
    const title = await screen.findByText('My Doc')
    expect(title).toHaveAttribute('title', 'My Doc')
  })

  it('mdv-011 shows a spinner icon and "Loading…" while the fetch is in progress', () => {
    const pending: MarkdownFetcher = () => new Promise(() => {})
    const { container } = render(<MarkdownViewer id="a" fetcher={pending} />)
    expect(screen.getByText('Loading…')).toBeInTheDocument()
    const live = container.querySelector('[aria-live="polite"][aria-busy="true"]')!
    expect(live).not.toBeNull()
    expect(live.querySelector('svg.adh-mv-state-icon')).not.toBeNull()
  })

  it('mdv-012 shows "No document selected" before an id is set', () => {
    render(<MarkdownViewer id={undefined} />)
    expect(screen.getByText('No document selected.')).toBeInTheDocument()
  })

  it.each([
    ['empty', ''],
    ['whitespace-only', '  \n\t \n'],
  ])('mdv-013 shows the empty state for %s content', async (_label, content) => {
    const { container } = render(<MarkdownViewer id="a" fetcher={fetcherFor(content)} />)
    expect(await screen.findByText('Empty document')).toBeInTheDocument()
    expect(screen.getByText('This document has no content yet.')).toBeInTheDocument()
    expect(container.querySelector('svg.adh-mv-state-icon')).not.toBeNull()
  })

  it('mdv-014 the pre-hydration bootstrap script applies the persisted theme to its content root', () => {
    window.localStorage.setItem(STORAGE_KEY, 'light')
    const { container } = render(<MarkdownViewer id={undefined} />)
    const scriptEl = container.querySelector('.adh-mv-content script')!
    const code = scriptEl.textContent!
    // Simulate the browser running the inline script on a freshly parsed (default-theme) root.
    const root = document.createElement('div')
    root.setAttribute('data-mdv-theme', 'dark')
    const fakeDocument = { currentScript: { parentElement: root } }
    new Function('document', code)(fakeDocument)
    expect(root.getAttribute('data-mdv-theme')).toBe('light')
    expect(root.getAttribute('data-mdv-shiki-variant')).toBe('light')
    expect(root.style.getPropertyValue('--mdv-text')).toBe(MDV_PALETTES['light']!['--mdv-text'])
  })

  it.skip('mdv-015 theme switcher hit area is at least 44x44pt / 48x48dp (iOS/Android measurement; jsdom has no layout)', () => {})

  it("mdv-016 aborts the previous id's fetch on id change and reflects only the new id (default fetcher)", async () => {
    const signals: AbortSignal[] = []
    const wire = (title: string) => ({
      id: 'x',
      title,
      content: 'body',
      tags: [],
      created: 1,
      updated: 1,
    })
    const fetchMock = vi.fn((url: string, init?: RequestInit) => {
      const signal = init!.signal as AbortSignal
      signals.push(signal)
      if (url.endsWith('/xyz')) {
        return Promise.resolve(new Response(JSON.stringify(wire('XYZ Title')), { status: 200 }))
      }
      return new Promise<Response>((_res, reject) => {
        signal.addEventListener('abort', () => reject(new Error('aborted')))
      })
    })
    vi.stubGlobal('fetch', fetchMock)
    const { rerender } = render(<MarkdownViewer id="abc" />)
    expect(signals).toHaveLength(1)
    expect(signals[0]!.aborted).toBe(false)
    rerender(<MarkdownViewer id="xyz" />)
    expect(signals[0]!.aborted).toBe(true)
    expect(await screen.findByText('XYZ Title')).toBeInTheDocument()
    expect(screen.queryByRole('alert')).toBeNull()
    expect(fetchMock.mock.calls[0]![0]).toContain('/abc')
    expect(fetchMock.mock.calls[1]![0]).toContain('/xyz')
  })

  it('mdv-017 drops the href of a javascript: link', async () => {
    const { container } = render(
      <MarkdownViewer id="a" fetcher={fetcherFor('[link](javascript:alert(1))')} />,
    )
    const a = await waitFor(() => {
      const el = container.querySelector('a')
      expect(el).not.toBeNull()
      return el!
    })
    expect(a).toHaveTextContent('link')
    expect(a.hasAttribute('href')).toBe(false)
  })

  it('mdv-018 strips the onerror attribute from raw HTML', async () => {
    const { container } = render(
      <MarkdownViewer id="a" fetcher={fetcherFor('<img src=x onerror=alert(1)>\n\nafter')} />,
    )
    await screen.findByText('after')
    for (const el of Array.from(container.querySelectorAll('*'))) {
      expect(el.hasAttribute('onerror')).toBe(false)
    }
  })
})
