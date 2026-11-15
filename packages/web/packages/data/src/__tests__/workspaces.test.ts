// Conformance tests for resource-data's workspace slug check and workspace list (workspaces.ts).
// The change-announcement vectors live in workspaces-changed.test.ts.
import { beforeEach, describe, expect, it } from 'vitest'
import { checkWorkspaceSlugAvailable, workspacesApi } from '../workspaces'
import { fetchMock, installFetch, pathAt, respondOnce, respondWith, v1List } from './v1-fetch'

beforeEach(() => {
  installFetch()
})

describe('workspaces', () => {
  it('resource-data-083 checkWorkspaceSlugAvailable GETs the encoded slug', async () => {
    respondWith({ available: true })
    await expect(checkWorkspaceSlugAvailable('a b')).resolves.toEqual({ available: true })
    expect(pathAt(0)).toBe('/api/v1/handles/a%20b')
    expect((fetchMock.mock.calls[0]![1] as RequestInit | undefined)?.method ?? 'GET').toBe('GET')
  })

  it('resource-data-084 list drops team rows', async () => {
    respondOnce(
      v1List([
        { slug: 'me', name: 'Me', type: 'individual' },
        { slug: 'crew', name: 'Crew', type: 'team' },
      ]),
    )
    const rows = await workspacesApi.list()
    expect(rows.map((r) => r.slug)).toEqual(['me'])
  })

  it('resource-data-085 list puts the individual first then organizations A to Z', async () => {
    respondOnce(
      v1List([
        { slug: 'zeta', name: 'Zeta', type: 'organization' },
        { slug: 'acme', name: 'Acme', type: 'organization' },
        { slug: 'me', name: 'Me', type: 'individual' },
      ]),
    )
    const rows = await workspacesApi.list()
    expect(rows.map((r) => r.name)).toEqual(['Me', 'Acme', 'Zeta'])
    expect(rows.map((r) => r.kind)).toEqual(['individual', 'organization', 'organization'])
  })
})
