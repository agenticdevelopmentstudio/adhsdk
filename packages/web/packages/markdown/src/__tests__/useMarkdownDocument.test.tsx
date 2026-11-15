// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { renderHook, waitFor, act } from '@testing-library/react'
import { useMarkdownDocument } from '../hooks/useMarkdownDocument'
import type { MarkdownFetcher } from '../hooks/useMarkdownDocument'
import type { MarkdownDocument } from '../types'

const doc = (id: string): MarkdownDocument => ({ id, title: id, content: `# ${id}` }) as unknown as MarkdownDocument

afterEach(() => {
  vi.useRealTimers()
})

describe('useMarkdownDocument', () => {
  it('mdc-045: holds the fetcher in a ref, so a new inline fetcher each render does not refetch', async () => {
    const calls: string[] = []
    const { result, rerender } = renderHook(
      ({ n }: { n: number }) =>
        useMarkdownDocument('a', {
          // A fresh function identity every render.
          fetcher: async (id) => {
            calls.push(`${id}:${n}`)
            return doc(id)
          },
        }),
      { initialProps: { n: 0 } },
    )
    await waitFor(() => expect(result.current.status).toBe('success'))
    rerender({ n: 1 })
    rerender({ n: 2 })
    await act(async () => {})
    expect(calls).toHaveLength(1)
  })

  it('mdc-046: a timeout aborts the signal with reason mdv-timeout and surfaces a timed-out error', async () => {
    vi.useFakeTimers()
    let seen: AbortSignal | undefined
    const fetcher: MarkdownFetcher = (_id, signal) =>
      new Promise((_resolve, reject) => {
        seen = signal
        signal.addEventListener('abort', () => reject(new Error('aborted')))
      })
    const { result } = renderHook(() => useMarkdownDocument('a', { fetcher, timeoutMs: 1000 }))
    expect(result.current.status).toBe('loading')
    await act(async () => {
      await vi.advanceTimersByTimeAsync(1000)
    })
    expect(seen?.aborted).toBe(true)
    expect(seen?.reason).toBe('mdv-timeout')
    expect(result.current).toEqual({ status: 'error', message: 'Timed out loading document after 1s.' })
  })

  it('mdc-047: a response that arrives after a timeout abort still shows as success', async () => {
    vi.useFakeTimers()
    let resolveIt: (d: MarkdownDocument) => void = () => {}
    const fetcher: MarkdownFetcher = () => new Promise((resolve) => (resolveIt = resolve))
    const { result } = renderHook(() => useMarkdownDocument('a', { fetcher, timeoutMs: 1000 }))
    await act(async () => {
      await vi.advanceTimersByTimeAsync(1000)
    })
    await act(async () => {
      resolveIt(doc('late'))
    })
    expect(result.current.status).toBe('success')
    if (result.current.status === 'success') expect(result.current.data.id).toBe('late')
  })

  it('mdc-047: a response for a superseded id is dropped; state reflects only the new id', async () => {
    const resolvers: Record<string, (d: MarkdownDocument) => void> = {}
    const fetcher: MarkdownFetcher = (id) => new Promise((resolve) => (resolvers[id] = resolve))
    const { result, rerender } = renderHook(({ id }: { id: string }) => useMarkdownDocument(id, { fetcher }), {
      initialProps: { id: 'old' },
    })
    rerender({ id: 'new' })
    await act(async () => {
      resolvers['old']!(doc('old'))
    })
    expect(result.current.status).toBe('loading')
    await act(async () => {
      resolvers['new']!(doc('new'))
    })
    expect(result.current.status).toBe('success')
    if (result.current.status === 'success') expect(result.current.data.id).toBe('new')
  })

  it('mdc-048: an absent id is idle on the first render and never calls the fetcher', async () => {
    const fetcher = vi.fn<MarkdownFetcher>()
    const states: string[] = []
    const { result } = renderHook(() => {
      const s = useMarkdownDocument(undefined, { fetcher })
      states.push(s.status)
      return s
    })
    expect(states[0]).toBe('idle')
    expect(result.current).toEqual({ status: 'idle' })
    await act(async () => {})
    expect(fetcher).not.toHaveBeenCalled()
  })
})
