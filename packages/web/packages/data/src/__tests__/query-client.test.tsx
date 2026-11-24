/// <reference types="@testing-library/jest-dom/vitest" />
import { render, cleanup } from '@testing-library/react'
import { useQueryClient } from '@tanstack/react-query'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  RESOURCE_GC_TIME,
  ToolkitQueryProvider,
  getToolkitQueryClient,
  useToolkitQueryClient,
} from '../query'

const h = vi.hoisted(() => ({
  subject: null as string | null,
  listeners: [] as Array<() => void>,
  constructed: 0,
  subjectReads: 0,
}))

// Unstub FIRST: `cleanup()` touches the DOM, and the server-render test below leaves `window`
// stubbed to undefined.
afterEach(() => {
  vi.unstubAllGlobals()
  cleanup()
})

const seen: unknown[] = []
function Probe() {
  seen.push(useToolkitQueryClient())
  return <div data-testid="probe" />
}

describe('the toolkit query client', () => {
  it('query-cache-001 is ONE instance in the browser', () => {
    expect(getToolkitQueryClient()).toBe(getToolkitQueryClient())
  })

  // The whole defect: the App Router remounts the page subtree on a same-segment param
  // navigation, so the provider is destroyed and rebuilt on every topic click. A client held in
  // component state dies with it, and the cache is empty every single time.
  it('query-cache-002 survives a provider that is unmounted and mounted again', () => {
    seen.length = 0
    const { unmount } = render(
      <ToolkitQueryProvider>
        <Probe />
      </ToolkitQueryProvider>,
    )
    unmount()
    render(
      <ToolkitQueryProvider>
        <Probe />
      </ToolkitQueryProvider>,
    )
    expect(seen).toHaveLength(2)
    expect(seen[0]).toBe(seen[1])
  })

  // 39 useResourceList call sites, and nothing guarantees a provider above any of them. Reading
  // the client from context alone would turn a missing provider into a runtime throw.
  it('query-cache-003 hands a consumer the same client with NO provider above it', () => {
    seen.length = 0
    render(<Probe />)
    expect(seen[0]).toBe(getToolkitQueryClient())
  })

  it('query-cache-004 makes a FRESH client per call on the server', () => {
    vi.stubGlobal('window', undefined)
    expect(getToolkitQueryClient()).not.toBe(getToolkitQueryClient())
  })
})

describe('client defaults', () => {
  it('query-cache-008 resolves staleTime 5 minutes and retry 1', () => {
    const queries = getToolkitQueryClient().getDefaultOptions().queries
    expect(queries?.staleTime).toBe(300_000)
    expect(queries?.retry).toBe(1)
  })

  it('query-cache-009 RESOURCE_GC_TIME is 30 minutes', () => {
    expect(RESOURCE_GC_TIME).toBe(1_800_000)
  })

  it('query-cache-010 pins gcTime for resource-list and resource-item keys only', () => {
    const client = getToolkitQueryClient()
    expect(client.getQueryDefaults(['resource-list', 'e1']).gcTime).toBe(RESOURCE_GC_TIME)
    expect(client.getQueryDefaults(['resource-item', 'e1', 'x']).gcTime).toBe(RESOURCE_GC_TIME)
    expect(client.getQueryDefaults(['api-tokens']).gcTime).toBeUndefined()
  })

  it('query-cache-016 the provider passes the singleton to the underlying provider', () => {
    let seenClient: unknown
    function Inner() {
      seenClient = useQueryClient()
      return null
    }
    render(
      <ToolkitQueryProvider>
        <Inner />
      </ToolkitQueryProvider>,
    )
    expect(seenClient).toBe(getToolkitQueryClient())
  })
})

// The session watch lives in a once-per-module closure, so each test loads a FRESH copy of the
// module with `@adh-sdk/auth/client` mocked: the subject the watch reads is a variable, and the
// session-change listener it registers is captured so the test can fire it.
describe('browser client construction and session watch', () => {
  type QueryModule = typeof import('../query')

  async function freshQueryModule(): Promise<QueryModule> {
    vi.resetModules()
    vi.doMock('@adh-sdk/auth/client', () => ({
      readTokenSubject: () => {
        h.subjectReads += 1
        return h.subject
      },
      onSessionChange: (fn: () => void) => {
        h.listeners.push(fn)
        return () => {}
      },
    }))
    vi.doMock('@tanstack/react-query', async (importOriginal) => {
      const actual = await importOriginal<typeof import('@tanstack/react-query')>()
      class CountedQueryClient extends actual.QueryClient {
        constructor(...args: ConstructorParameters<typeof actual.QueryClient>) {
          super(...args)
          h.constructed += 1
        }
      }
      return { ...actual, QueryClient: CountedQueryClient }
    })
    return import('../query')
  }

  beforeEach(() => {
    h.subject = 'user-1'
    h.listeners = []
    h.constructed = 0
    h.subjectReads = 0
  })

  afterEach(() => {
    vi.doUnmock('@adh-sdk/auth/client')
    vi.doUnmock('@tanstack/react-query')
    vi.resetModules()
  })

  it('query-cache-011 builds the client and the session watch once, on the first call', async () => {
    const mod = await freshQueryModule()
    expect(h.constructed).toBe(0)
    expect(h.listeners).toHaveLength(0)
    const first = mod.getToolkitQueryClient()
    const second = mod.getToolkitQueryClient()
    expect(second).toBe(first)
    expect(h.constructed).toBe(1)
    expect(h.listeners).toHaveLength(1)
  })

  it('query-cache-012 captures the stored subject on the first call', async () => {
    const mod = await freshQueryModule()
    const client = mod.getToolkitQueryClient()
    client.setQueryData(['k'], 1)
    expect(h.subjectReads).toBe(1)
    // The captured subject is observable through behavior: re-announcing the SAME subject
    // does not clear, which it would if the initial capture were null.
    h.listeners[0]!()
    expect(client.getQueryData(['k'])).toBe(1)
  })

  it('query-cache-013 clears the cache when the subject changes', async () => {
    const mod = await freshQueryModule()
    const client = mod.getToolkitQueryClient()
    client.setQueryData(['k'], 1)
    h.subject = 'user-2'
    h.listeners[0]!()
    expect(client.getQueryData(['k'])).toBeUndefined()
    // The last-seen subject is now user-2: announcing again does not clear new data.
    client.setQueryData(['k'], 2)
    h.listeners[0]!()
    expect(client.getQueryData(['k'])).toBe(2)
  })

  it('query-cache-014 keeps the cache when the same subject refreshes its token', async () => {
    const mod = await freshQueryModule()
    const client = mod.getToolkitQueryClient()
    client.setQueryData(['k'], 1)
    h.listeners[0]!()
    expect(client.getQueryData(['k'])).toBe(1)
  })

  it('query-cache-015 a cross-tab storage event runs the same comparison', async () => {
    const mod = await freshQueryModule()
    const client = mod.getToolkitQueryClient()
    client.setQueryData(['k'], 1)
    h.subject = 'user-2'
    window.dispatchEvent(new StorageEvent('storage', { key: 'auth_tokens' }))
    expect(client.getQueryData(['k'])).toBeUndefined()
  })
})
