import { renderHook, waitFor, cleanup, act } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { notifyManager } from '@tanstack/react-query'

// Synchronous notifications, as use-resource-item.test.tsx explains.
notifyManager.setScheduler((cb) => cb())

const get = vi.fn()
const put = vi.fn()
vi.mock('../workspace-prefs', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../workspace-prefs')>()
  return { ...actual, workspacePrefsApi: { get, put } }
})

const { useWorkspacePreference } = await import('../use-workspace-preference')
const { readCachedWorkspace, writeCachedWorkspace } = await import('../workspace-prefs')
const { getToolkitQueryClient } = await import('../query')

beforeEach(() => {
  get.mockReset()
  put.mockReset()
  put.mockResolvedValue(undefined)
})
afterEach(() => {
  cleanup()
  getToolkitQueryClient().clear()
  localStorage.clear()
})

describe('useWorkspacePreference', () => {
  it('paints the browser cache first, then the server row', async () => {
    writeCachedWorkspace('cached')
    let resolve!: (v: { slug?: string }) => void
    get.mockReturnValue(new Promise((r) => (resolve = r)))
    const { result } = renderHook(() => useWorkspacePreference())
    expect(result.current.slug).toBe('cached')
    expect(result.current.settled).toBe(false)
    await act(async () => resolve({ slug: 'server' }))
    await waitFor(() => expect(result.current.slug).toBe('server'))
    expect(result.current.settled).toBe(true)
  })

  it('reads nothing and reports no slug while disabled (signed out)', () => {
    writeCachedWorkspace('cached')
    const { result } = renderHook(() => useWorkspacePreference({ enabled: false }))
    expect(get).not.toHaveBeenCalled()
    expect(result.current.slug).toBeNull()
  })

  it('a pick made while the first read is in flight is not overwritten when that read lands', async () => {
    let resolve!: (v: { slug?: string }) => void
    get.mockReturnValue(new Promise((r) => (resolve = r)))
    const { result } = renderHook(() => useWorkspacePreference())
    act(() => result.current.choose('acme'))
    await act(async () => resolve({ slug: 'me' }))
    await waitFor(() => expect(result.current.slug).toBe('acme'))
    await new Promise((r) => setTimeout(r, 0))
    expect(result.current.slug).toBe('acme')
  })

  it('choose() records the pick in the browser cache, the item cache and the server row', async () => {
    get.mockResolvedValue({ slug: 'me' })
    const { result } = renderHook(() => useWorkspacePreference())
    await waitFor(() => expect(result.current.slug).toBe('me'))
    act(() => result.current.choose('acme'))
    expect(result.current.slug).toBe('acme')
    expect(readCachedWorkspace()).toBe('acme')
    expect(put).toHaveBeenCalledWith({ slug: 'acme' })
  })
})
