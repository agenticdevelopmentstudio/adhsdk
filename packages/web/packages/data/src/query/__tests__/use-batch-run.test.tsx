/// <reference types="@testing-library/jest-dom/vitest" />
import { act, renderHook, waitFor } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import { ToolkitQueryProvider, getToolkitQueryClient, useBatchRun, type BatchItem } from '../index'

const wrapper = ({ children }: { children: ReactNode }) => (
  <ToolkitQueryProvider>{children}</ToolkitQueryProvider>
)

const items: BatchItem[] = [
  { id: 'a', label: 'A' },
  { id: 'b', label: 'B' },
  { id: 'c', label: 'C' },
]

afterEach(() => {
  vi.restoreAllMocks()
})

/** A perform that fails for item `b` and records every item it was called with. */
function recorder(failId = 'b') {
  const calls: string[] = []
  const perform = vi.fn(async (item: BatchItem) => {
    calls.push(item.id)
    if (item.id === failId) throw new Error(`${item.id} rejected`)
  })
  return { calls, perform }
}

describe('useBatchRun', () => {
  it('query-cache-017 runs items in order and invalidates the key once', async () => {
    const invalidate = vi.spyOn(getToolkitQueryClient(), 'invalidateQueries')
    const order: string[] = []
    const { result } = renderHook(() => useBatchRun({ invalidateKey: ['list'] }), { wrapper })
    await act(async () => {
      await result.current.run(items, async (item) => {
        order.push(item.id)
      })
    })
    expect(order).toEqual(['a', 'b', 'c'])
    expect(result.current.state.results.map((r) => r.status)).toEqual(['ok', 'ok', 'ok'])
    expect(result.current.state.done).toBe(3)
    expect(result.current.state.finished).toBe(true)
    expect(invalidate).toHaveBeenCalledTimes(1)
    expect(invalidate).toHaveBeenCalledWith({ queryKey: ['list'] })
  })

  it('query-cache-018 halts on a failure and never performs the third item after Stop', async () => {
    const { calls, perform } = recorder()
    const { result } = renderHook(() => useBatchRun(), { wrapper })
    let ended: Promise<void> = Promise.resolve()
    act(() => {
      ended = result.current.run(items, perform)
    })
    await waitFor(() => expect(result.current.state.error).not.toBeNull())
    expect(result.current.state.error?.itemLabel).toBe('B')
    act(() => result.current.stop())
    await act(async () => {
      await ended
    })
    expect(calls).toEqual(['a', 'b'])
    expect(result.current.state.results.map((r) => r.status)).toEqual(['ok', 'failed'])
    expect(result.current.state.finished).toBe(true)
  })

  it('query-cache-019 a run over zero items leaves the state idle', async () => {
    const { result } = renderHook(() => useBatchRun(), { wrapper })
    await act(async () => {
      await result.current.run([], async () => {})
    })
    expect(result.current.state).toEqual({
      running: false,
      finished: false,
      total: 0,
      done: 0,
      error: null,
      results: [],
    })
  })

  it('query-cache-020 ignores a second run while the first is halted', async () => {
    const { calls, perform } = recorder()
    const second = vi.fn(async () => {})
    const { result } = renderHook(() => useBatchRun(), { wrapper })
    let ended: Promise<void> = Promise.resolve()
    act(() => {
      ended = result.current.run(items, perform)
    })
    await waitFor(() => expect(result.current.state.error).not.toBeNull())
    await act(async () => {
      await result.current.run(items, second)
    })
    expect(second).not.toHaveBeenCalled()
    act(() => result.current.stop())
    await act(async () => {
      await ended
    })
    expect(calls).toEqual(['a', 'b'])
  })

  it('query-cache-021 Continue performs the third item after a failure', async () => {
    const { calls, perform } = recorder()
    const { result } = renderHook(() => useBatchRun(), { wrapper })
    let ended: Promise<void> = Promise.resolve()
    act(() => {
      ended = result.current.run(items, perform)
    })
    await waitFor(() => expect(result.current.state.error).not.toBeNull())
    act(() => result.current.continueRun())
    await act(async () => {
      await ended
    })
    expect(calls).toEqual(['a', 'b', 'c'])
    expect(result.current.state.results.map((r) => r.status)).toEqual(['ok', 'failed', 'ok'])
    expect(result.current.state.done).toBe(2)
    expect(result.current.state.finished).toBe(true)
    expect(result.current.state.running).toBe(false)
  })

  it('query-cache-022 reset releases a halted run, invalidates, and returns to idle', async () => {
    const invalidate = vi.spyOn(getToolkitQueryClient(), 'invalidateQueries')
    const { calls, perform } = recorder()
    const { result } = renderHook(() => useBatchRun({ invalidateKey: ['list'] }), { wrapper })
    let ended: Promise<void> = Promise.resolve()
    act(() => {
      ended = result.current.run(items, perform)
    })
    await waitFor(() => expect(result.current.state.error).not.toBeNull())
    act(() => result.current.reset())
    await act(async () => {
      await ended
    })
    expect(calls).toEqual(['a', 'b'])
    expect(invalidate).toHaveBeenCalledTimes(1)
    expect(result.current.state.running).toBe(false)
    expect(result.current.state.results).toEqual([])
    expect(result.current.state.error).toBeNull()
  })

  it('query-cache-022 unmount releases a halted run as if stopped', async () => {
    const invalidate = vi.spyOn(getToolkitQueryClient(), 'invalidateQueries')
    const { calls, perform } = recorder()
    const { result, unmount } = renderHook(() => useBatchRun({ invalidateKey: ['list'] }), {
      wrapper,
    })
    let ended: Promise<void> = Promise.resolve()
    act(() => {
      ended = result.current.run(items, perform)
    })
    await waitFor(() => expect(result.current.state.error).not.toBeNull())
    unmount()
    await ended
    expect(calls).toEqual(['a', 'b'])
    expect(invalidate).toHaveBeenCalledTimes(1)
  })

  it('query-cache-023 invalidates once after a Stop, though the run did not complete', async () => {
    const invalidate = vi.spyOn(getToolkitQueryClient(), 'invalidateQueries')
    const { perform } = recorder()
    const { result } = renderHook(() => useBatchRun({ invalidateKey: ['list'] }), { wrapper })
    let ended: Promise<void> = Promise.resolve()
    act(() => {
      ended = result.current.run(items, perform)
    })
    await waitFor(() => expect(result.current.state.error).not.toBeNull())
    expect(invalidate).not.toHaveBeenCalled()
    act(() => result.current.stop())
    await act(async () => {
      await ended
    })
    expect(invalidate).toHaveBeenCalledTimes(1)
  })
})
