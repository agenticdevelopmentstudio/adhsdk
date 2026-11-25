import { renderHook, waitFor, cleanup } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { notifyManager } from '@tanstack/react-query'
import { useWorkspaces } from '../use-workspaces'
import {
  WORKSPACES_CHANGED_EVENT,
  WORKSPACE_ROWS_QUERY_KEY,
  notifyWorkspacesChanged,
} from '../workspaces'
import { getToolkitQueryClient } from '../query'
import { fetchMock, installFetch, respondOnce, v1List } from './v1-fetch'

// Synchronous notifications, as use-resource-item.test.tsx explains.
notifyManager.setScheduler((cb) => cb())

beforeEach(() => {
  installFetch()
})
afterEach(() => {
  cleanup()
  getToolkitQueryClient().clear()
  vi.restoreAllMocks()
})

/** The calls that swept the all-rows entry, by key. */
function rowSweeps(invalidate: { mock: { calls: unknown[][] } }): number {
  return invalidate.mock.calls.filter(
    ([arg]) => (arg as { queryKey?: unknown })?.queryKey === WORKSPACE_ROWS_QUERY_KEY,
  ).length
}

describe('useWorkspaces', () => {
  it('loads every workspace row, teams included', async () => {
    respondOnce(
      v1List([
        { slug: 'me', name: 'Me', type: 'individual' },
        { slug: 'crew', name: 'Crew', type: 'team' },
      ]),
    )
    const { result } = renderHook(() => useWorkspaces())
    await waitFor(() => expect(result.current.data?.map((r) => r.slug)).toEqual(['me', 'crew']))
  })

  it('asks for nothing while disabled (signed out)', () => {
    renderHook(() => useWorkspaces({ enabled: false }))
    expect(fetchMock).not.toHaveBeenCalled()
  })

  it('refetches when the workspace list is announced as changed', async () => {
    respondOnce(v1List([{ slug: 'me', name: 'Me', type: 'individual' }]))
    const { result } = renderHook(() => useWorkspaces())
    await waitFor(() => expect(result.current.data).toHaveLength(1))
    respondOnce(
      v1List([
        { slug: 'me', name: 'Me', type: 'individual' },
        { slug: 'acme', name: 'Acme', type: 'organization' },
      ]),
    )
    notifyWorkspacesChanged()
    await waitFor(() => expect(result.current.data).toHaveLength(2))
  })

  it('sweeps the entry once per change, however many readers are mounted', () => {
    // A second sweep is a second request: invalidateQueries cancels the refetch in flight and
    // starts another. notifyWorkspacesChanged sweeps this client directly, so the readers'
    // subscription must add nothing, and three readers must not add three.
    renderHook(() => useWorkspaces({ enabled: false }))
    renderHook(() => useWorkspaces({ enabled: false }))
    renderHook(() => useWorkspaces({ enabled: false }))
    const invalidate = vi.spyOn(getToolkitQueryClient(), 'invalidateQueries').mockResolvedValue()
    notifyWorkspacesChanged()
    expect(rowSweeps(invalidate)).toBe(1)
  })

  it('sweeps once for an announcement another copy of the module sent', () => {
    // A host bundling its own @adh-sdk/data announces with its own event object; that copy's
    // direct sweep reached ITS client, so this one hears only the window event, and sweeps once.
    const first = renderHook(() => useWorkspaces({ enabled: false }))
    renderHook(() => useWorkspaces({ enabled: false }))
    const invalidate = vi.spyOn(getToolkitQueryClient(), 'invalidateQueries').mockResolvedValue()
    window.dispatchEvent(new CustomEvent(WORKSPACES_CHANGED_EVENT))
    expect(rowSweeps(invalidate)).toBe(1)

    // One reader leaving keeps the subscription for the other; the last one leaving drops it.
    first.unmount()
    window.dispatchEvent(new CustomEvent(WORKSPACES_CHANGED_EVENT))
    expect(rowSweeps(invalidate)).toBe(2)
    cleanup()
    window.dispatchEvent(new CustomEvent(WORKSPACES_CHANGED_EVENT))
    expect(rowSweeps(invalidate)).toBe(2)
  })
})
