import { renderHook, waitFor, cleanup } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { notifyManager } from '@tanstack/react-query'
import { useWorkspaces } from '../use-workspaces'
import { notifyWorkspacesChanged } from '../workspaces'
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
})

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
})
