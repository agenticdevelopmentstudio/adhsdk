import { afterEach, describe, expect, it, vi } from 'vitest'
import {
  WORKSPACES_QUERY_KEY,
  WORKSPACE_ROWS_QUERY_KEY,
  notifyWorkspacesChanged,
  onWorkspacesChanged,
} from '../workspaces'
import { getToolkitQueryClient } from '../query'

// The announcement exists because an org is a WORKSPACE: creating one from the Organizations rail
// changes a list three caches hold, and only one of them is reachable by the code doing the
// creating. What is pinned here is that one call reaches all three — the two toolkit caches
// directly, the host's through the window event that crosses the physical react-query boundary.

afterEach(() => {
  getToolkitQueryClient().clear()
  vi.restoreAllMocks()
})

describe('notifyWorkspacesChanged', () => {
  it('invalidates the toolkit list AND the resource-list entry the fleet chooser reads', () => {
    const client = getToolkitQueryClient()
    const invalidate = vi.spyOn(client, 'invalidateQueries').mockResolvedValue()

    notifyWorkspacesChanged()

    // The switcher's list, by key.
    expect(invalidate).toHaveBeenCalledWith({ queryKey: WORKSPACES_QUERY_KEY })
    // The header menu's all-rows list, which keeps its own key (a different shape).
    expect(invalidate).toHaveBeenCalledWith({ queryKey: WORKSPACE_ROWS_QUERY_KEY })
    // SiteHomeShell's chooser reads the SAME endpoint under a different entry
    // (`useResourceList('workspaces')`), so a key-only sweep would leave the fleet's picker stale.
    // `revalidateResources` matches by predicate; assert the predicate accepts that cache key and
    // nothing else.
    const predicateCall = invalidate.mock.calls
      .map(([arg]) => arg as { predicate?: (q: { queryKey: unknown[] }) => boolean })
      .find((arg) => typeof arg?.predicate === 'function')
    expect(predicateCall).toBeDefined()
    const predicate = predicateCall!.predicate!
    expect(predicate({ queryKey: ['resource-list', null, 'workspaces'] })).toBe(true)
    expect(predicate({ queryKey: ['resource-list', null, 'organizations'] })).toBe(false)
  })

  it('fires the window event a host with its own react-query copy listens on', () => {
    const heard = vi.fn()
    const stop = onWorkspacesChanged(heard)

    notifyWorkspacesChanged()
    expect(heard).toHaveBeenCalledTimes(1)

    // The subscribe returns its own unsubscribe, so an effect body can be exactly
    // `() => onWorkspacesChanged(fn)` — which is how the hub's `useWorkspaces` mounts it.
    stop()
    notifyWorkspacesChanged()
    expect(heard).toHaveBeenCalledTimes(1)
  })
})

// Conformance vectors for resource-data (cookbook/data/services/resource-data).
describe('workspaces conformance', () => {
  it('resource-data-078 the workspace-list cache key is ["workspaces"]', () => {
    expect(WORKSPACES_QUERY_KEY).toEqual(['workspaces'])
  })

  it('resource-data-079 announcing invalidates the list entry and the resource-list "workspaces" entry only', () => {
    const invalidate = vi.spyOn(getToolkitQueryClient(), 'invalidateQueries').mockResolvedValue()
    notifyWorkspacesChanged()
    expect(invalidate).toHaveBeenCalledWith({ queryKey: WORKSPACES_QUERY_KEY })
    const predicate = invalidate.mock.calls
      .map(([arg]) => arg as { predicate?: (q: { queryKey: unknown[] }) => boolean })
      .find((arg) => typeof arg?.predicate === 'function')!.predicate!
    expect(predicate({ queryKey: ['resource-list', null, 'workspaces'] })).toBe(true)
    expect(predicate({ queryKey: ['resource-list', null, 'organizations'] })).toBe(false)
  })

  it('resource-data-080 announcing swallows a failing invalidation', async () => {
    vi.spyOn(getToolkitQueryClient(), 'invalidateQueries').mockRejectedValue(new Error('offline'))
    // Vitest fails the run on an unhandled rejection, so surviving the tick is the assertion.
    expect(() => notifyWorkspacesChanged()).not.toThrow()
    await new Promise((r) => setTimeout(r, 10))
  })

  it('resource-data-081 announcing calls a subscribed listener exactly once', () => {
    const heard = vi.fn()
    const stop = onWorkspacesChanged(heard)
    notifyWorkspacesChanged()
    stop()
    expect(heard).toHaveBeenCalledTimes(1)
  })

  it('resource-data-082 an unsubscribed listener is not called again', () => {
    const heard = vi.fn()
    const stop = onWorkspacesChanged(heard)
    notifyWorkspacesChanged()
    stop()
    notifyWorkspacesChanged()
    expect(heard).toHaveBeenCalledTimes(1)
  })
})
