// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { act, type ReactElement } from 'react'
import { createRoot, type Root } from 'react-dom/client'
import { MarkdownPreview } from '../components/markdown/MarkdownPreview'
import type { PaperSearchHit } from '../registry/markdown'
import type { SearchSource } from '../types'

// This package carries no @testing-library dependency, so a minimal render/query shim over
// react-dom stands in for it.
;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true
const mounted: { root: Root; host: HTMLElement }[] = []

function render(ui: ReactElement): {
  container: HTMLElement
  rerender: (next: ReactElement) => void
  unmount: () => void
} {
  const host = document.createElement('div')
  document.body.appendChild(host)
  const root = createRoot(host)
  act(() => root.render(ui))
  const entry = { root, host }
  mounted.push(entry)
  return {
    container: host,
    rerender: (next) => act(() => root.render(next)),
    unmount: () => {
      const i = mounted.indexOf(entry)
      if (i >= 0) mounted.splice(i, 1)
      act(() => root.unmount())
      host.remove()
    },
  }
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

/** Poll `check` (flushing microtasks/timers inside act) until it stops throwing. */
async function waitFor(check: () => void): Promise<void> {
  let last: unknown
  for (let i = 0; i < 100; i++) {
    try {
      check()
      return
    } catch (e) {
      last = e
    }
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0))
    })
  }
  throw last
}

function leaves(text: string | RegExp): HTMLElement[] {
  return [...document.querySelectorAll<HTMLElement>('body *')].filter(
    (e) => e.children.length === 0 && (typeof text === 'string' ? e.textContent === text : text.test(e.textContent ?? '')),
  )
}

const screen = {
  getByText(text: string): HTMLElement {
    const found = leaves(text)
    if (found.length !== 1) throw new Error(`expected one "${text}", found ${found.length}`)
    return found[0]
  },
  queryByText(text: string | RegExp): HTMLElement | null {
    return leaves(text)[0] ?? null
  },
  async findByText(text: string): Promise<HTMLElement> {
    await waitFor(() => screen.getByText(text))
    return screen.getByText(text)
  },
  getByTestId(id: string): HTMLElement {
    const el = document.querySelector<HTMLElement>(`[data-testid="${id}"]`)
    if (!el) throw new Error(`no testid ${id}`)
    return el
  },
  async findByTestId(id: string): Promise<HTMLElement> {
    await waitFor(() => screen.getByTestId(id))
    return screen.getByTestId(id)
  },
  getByRole(role: string, opts: { name?: string } = {}): HTMLElement {
    const sel = role === 'button' ? 'button' : `[role="${role}"]`
    const found = [...document.querySelectorAll<HTMLElement>(sel)].filter(
      (e) => opts.name === undefined || e.textContent === opts.name,
    )
    if (found.length !== 1) throw new Error(`expected one ${role}, found ${found.length}`)
    return found[0]
  },
  queryByRole(role: string): HTMLElement | null {
    return document.querySelector<HTMLElement>(`[role="${role}"]`)
  },
}

const rendererSpy = vi.fn()

vi.mock('@adh-sdk/markdown', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@adh-sdk/markdown')>()
  return {
    ...actual,
    MarkdownRenderer: (props: { content: string }) => {
      rendererSpy(props.content)
      return <div data-testid="rendered">{props.content}</div>
    },
  }
})

import { DEFAULT_THEME_ID, getThemeById } from '@adh-sdk/markdown'

function hit(over: Partial<PaperSearchHit> = {}): PaperSearchHit {
  return {
    id: 'p1',
    title: 'T',
    publicRoute: 'paper-001',
    author: { slug: 'alice-wonder', displayName: 'Alice' },
    category: null,
    tags: [],
    snippet: '',
    createdAt: '',
    updatedAt: '',
    kind: 'paper',
    ...over,
  }
}

function src(over: Partial<SearchSource> = {}): SearchSource {
  return {
    baseUrl: 'https://api.example.com',
    endpoints: { results: '/v1/papers', content: '/:slug/:route' },
    ...over,
  } as SearchSource
}

interface Call {
  url: string
  signal: AbortSignal
  init: RequestInit
}

let calls: Call[]
let timeoutCalls: number[]
let timeoutControllers: AbortController[]
/** Per-call responder; default resolves to an empty-ish ok response. */
let responder: (call: Call) => Promise<Response>

function jsonResponse(body: unknown, status = 200): Promise<Response> {
  return Promise.resolve({
    ok: status >= 200 && status < 300,
    status,
    json: async () => body,
  } as Response)
}

/** A fetch that never settles by itself but rejects with the signal's reason on abort. */
function stalled(call: Call): Promise<Response> {
  return new Promise((_resolve, reject) => {
    call.signal.addEventListener('abort', () => reject(call.signal.reason))
  })
}

beforeEach(() => {
  calls = []
  timeoutCalls = []
  timeoutControllers = []
  rendererSpy.mockClear()
  responder = () => jsonResponse({ content: 'x' })
  // AbortSignal.timeout is native and not driven by fake timers; hand the component a
  // signal the test fires, and record the duration it asked for.
  vi.spyOn(AbortSignal, 'timeout').mockImplementation((ms: number) => {
    timeoutCalls.push(ms)
    const c = new AbortController()
    timeoutControllers.push(c)
    return c.signal
  })
  vi.stubGlobal(
    'fetch',
    vi.fn((url: string, init: RequestInit) => {
      const call = { url, signal: init.signal as AbortSignal, init }
      calls.push(call)
      return responder(call)
    }),
  )
})

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
})

function fireTimeout(index = timeoutControllers.length - 1): void {
  act(() => timeoutControllers[index].abort(new DOMException('timed out', 'TimeoutError')))
}

describe('MarkdownPreview conformance vectors', () => {
  it('mp-001 builds the content URL from the source template, base URL, slug and route', async () => {
    render(<MarkdownPreview hit={hit()} source={src()} />)
    await waitFor(() => expect(calls).toHaveLength(1))
    expect(calls[0].url).toBe('https://api.example.com/alice-wonder/paper-001')
  })

  it('mp-002 renders the fetched markdown through MarkdownRenderer', async () => {
    responder = () => jsonResponse({ content: '# Title\n\nBody text.' })
    render(<MarkdownPreview hit={hit()} source={src()} />)
    const out = await screen.findByTestId('rendered')
    expect(rendererSpy).toHaveBeenCalledWith('# Title\n\nBody text.')
    expect(out.textContent).toBe('# Title\n\nBody text.')
  })

  it('mp-003 applies the reading theme attributes and palette as inline style', async () => {
    const { container } = render(<MarkdownPreview hit={hit()} source={src()} />)
    await screen.findByTestId('rendered')
    const theme = getThemeById(DEFAULT_THEME_ID)
    const root = container.firstElementChild as HTMLElement
    expect(root.getAttribute('data-mdv-theme')).toBe(theme.id)
    expect(root.getAttribute('data-mdv-shiki-variant')).toBe(theme.shikiVariant)
    const entries = Object.entries(theme.palette as Record<string, string>)
    expect(entries.length).toBeGreaterThan(0)
    for (const [prop, value] of entries) {
      expect(root.style.getPropertyValue(prop)).toBe(value)
    }
  })

  it('mp-004 shows the loading state before the fetch completes', () => {
    responder = stalled
    const { container } = render(<MarkdownPreview hit={hit()} source={src()} />)
    const state = container.querySelector('.adh-mv-state') as HTMLElement
    expect(state).not.toBeNull()
    expect(state.getAttribute('aria-live')).toBe('polite')
    expect(state.getAttribute('aria-busy')).toBe('true')
    expect(state.querySelector('p')?.textContent).toBe('Loading paper…')
  })

  it('mp-005 shows the empty state for empty and whitespace-only content', async () => {
    responder = () => jsonResponse({ content: '' })
    const first = render(<MarkdownPreview hit={hit()} source={src()} />)
    await screen.findByText('Empty paper')
    expect(screen.getByText('This paper has no content yet.')).toBeTruthy()
    expect(first.container.querySelector('.adh-mv-state')).not.toBeNull()
    first.unmount()

    responder = () => jsonResponse({ content: '   ' })
    render(<MarkdownPreview hit={hit()} source={src()} />)
    await screen.findByText('Empty paper')
    expect(screen.getByText('This paper has no content yet.')).toBeTruthy()
  })

  it('mp-006 shows the error state with role=alert for HTTP 404', async () => {
    responder = () => jsonResponse({}, 404)
    const { container } = render(<MarkdownPreview hit={hit()} source={src()} />)
    await screen.findByText('Failed to load paper')
    const alert = screen.getByRole('alert')
    expect(alert.className).toBe('adh-mv-state adh-mv-state--error')
    expect(container.contains(alert)).toBe(true)
    expect(screen.getByText('Failed to load paper (HTTP 404).')).toBeTruthy()
  })

  it('mp-007 aborts at the timeout and shows the timeout message', async () => {
    responder = stalled
    render(<MarkdownPreview hit={hit()} source={src()} timeoutMs={5000} />)
    await waitFor(() => expect(calls).toHaveLength(1))
    expect(timeoutCalls).toEqual([5000])
    fireTimeout()
    await screen.findByText('Timed out loading paper after 5s.')
    expect(calls[0].signal.aborted).toBe(true)
    expect(screen.getByRole('alert')).toBeTruthy()
  })

  it('mp-008 shows a network error message, never the timeout wording', async () => {
    responder = () => Promise.reject(new TypeError('Network down'))
    render(<MarkdownPreview hit={hit()} source={src()} timeoutMs={5000} />)
    await screen.findByText('Network down')
    expect(screen.queryByText(/Timed out loading paper/)).toBeNull()
  })

  it('mp-009 Retry re-issues the same request without remounting and returns to loading', async () => {
    responder = () => jsonResponse({}, 500)
    const { container } = render(<MarkdownPreview hit={hit()} source={src()} />)
    await screen.findByText('Failed to load paper')
    const root = container.firstElementChild
    responder = stalled
    fireEvent.click(screen.getByRole('button', { name: 'Retry' }))
    await waitFor(() => expect(calls).toHaveLength(2))
    expect(calls[1].url).toBe(calls[0].url)
    expect(container.firstElementChild).toBe(root)
    expect(screen.getByText('Loading paper…')).toBeTruthy()
    expect(screen.queryByText('Failed to load paper')).toBeNull()
  })

  it('mp-010 aborts the pending request when the author slug changes and never shows its result', async () => {
    let resolveFirst: (r: Response) => void = () => {}
    responder = (call) =>
      call.url.includes('/alice/')
        ? new Promise<Response>((resolve) => {
            resolveFirst = resolve
          })
        : stalled(call)
    const { rerender } = render(
      <MarkdownPreview hit={hit({ author: { slug: 'alice', displayName: null } })} source={src()} />,
    )
    await waitFor(() => expect(calls).toHaveLength(1))
    rerender(<MarkdownPreview hit={hit({ author: { slug: 'bob', displayName: null } })} source={src()} />)
    await waitFor(() => expect(calls).toHaveLength(2))
    expect(calls[0].signal.aborted).toBe(true)
    expect(calls[1].url).toBe('https://api.example.com/bob/paper-001')
    await act(async () => {
      resolveFirst({ ok: true, status: 200, json: async () => ({ content: 'ALICE RESULT' }) } as Response)
    })
    expect(screen.queryByText('ALICE RESULT')).toBeNull()
    expect(screen.getByText('Loading paper…')).toBeTruthy()
  })

  it('mp-011 shows the HTTP status in the error message for a 500', async () => {
    responder = () => jsonResponse({}, 500)
    render(<MarkdownPreview hit={hit()} source={src()} />)
    await screen.findByText('Failed to load paper (HTTP 500).')
  })

  it('mp-012 does not refetch when the source object is recreated with the same values', async () => {
    const { rerender } = render(<MarkdownPreview hit={hit()} source={src()} />)
    await screen.findByTestId('rendered')
    rerender(<MarkdownPreview hit={hit()} source={src()} />)
    rerender(<MarkdownPreview hit={hit()} source={src()} />)
    expect(calls).toHaveLength(1)
  })

  it('mp-013 URL-encodes the slug and route', async () => {
    render(<MarkdownPreview hit={hit({ author: { slug: 'a b/c', displayName: null }, publicRoute: 'p-1' })} source={src()} />)
    await waitFor(() => expect(calls).toHaveLength(1))
    expect(calls[0].url).toBe('https://api.example.com/a%20b%2Fc/p-1')
  })

  it('mp-014 does not refetch when only fetchInit changes', async () => {
    const { rerender } = render(<MarkdownPreview hit={hit()} source={src({ fetchInit: { headers: { a: '1' } } })} />)
    await screen.findByTestId('rendered')
    rerender(<MarkdownPreview hit={hit()} source={src({ fetchInit: { headers: { a: '2' } } })} />)
    expect(calls).toHaveLength(1)
  })

  it('mp-015 refetches when timeoutMs changes', async () => {
    const { rerender } = render(<MarkdownPreview hit={hit()} source={src()} timeoutMs={15000} />)
    await screen.findByTestId('rendered')
    rerender(<MarkdownPreview hit={hit()} source={src()} timeoutMs={20000} />)
    await waitFor(() => expect(calls).toHaveLength(2))
    expect(timeoutCalls).toEqual([15000, 20000])
  })

  it('mp-016 refetches to the new URL when endpoints.content changes', async () => {
    const { rerender } = render(<MarkdownPreview hit={hit()} source={src()} />)
    await screen.findByTestId('rendered')
    rerender(
      <MarkdownPreview
        hit={hit()}
        source={src({ endpoints: { results: '/v1/papers', content: '/v2/:slug/:route' } })}
      />,
    )
    await waitFor(() => expect(calls).toHaveLength(2))
    expect(calls[1].url).toBe('https://api.example.com/v2/alice-wonder/paper-001')
  })

  it('mp-017 aborts the pending request on unmount and makes no later state update', async () => {
    const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    let resolveFetch: (r: Response) => void = () => {}
    responder = () =>
      new Promise<Response>((resolve) => {
        resolveFetch = resolve
      })
    const { unmount } = render(<MarkdownPreview hit={hit()} source={src()} />)
    await waitFor(() => expect(calls).toHaveLength(1))
    unmount()
    expect(calls[0].signal.aborted).toBe(true)
    await act(async () => {
      resolveFetch({ ok: true, status: 200, json: async () => ({ content: 'late' }) } as Response)
    })
    expect(rendererSpy).not.toHaveBeenCalled()
    expect(errorSpy).not.toHaveBeenCalled()
  })

  it('mp-018 shows the empty state, not an error, when the body has no content key', async () => {
    responder = () => jsonResponse({})
    render(<MarkdownPreview hit={hit()} source={src()} />)
    await screen.findByText('Empty paper')
    expect(screen.queryByRole('alert')).toBeNull()
  })

  it('mp-019 defaults the timeout to 15s and reports it in the message', async () => {
    responder = stalled
    render(<MarkdownPreview hit={hit()} source={src()} />)
    await waitFor(() => expect(calls).toHaveLength(1))
    expect(timeoutCalls).toEqual([15000])
    fireTimeout()
    await screen.findByText('Timed out loading paper after 15s.')
  })
})
