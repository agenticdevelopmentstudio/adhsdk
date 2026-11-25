// The pure workspace-row helpers every switcher uses (workspace-rows.ts), and the all-rows list
// they run over (workspacesApi.listAll).
import { beforeEach, describe, expect, it } from 'vitest'
import {
  firstWorkspacePerSlug,
  workspaceCompositeId,
  workspaceListLabel,
} from '../workspace-rows'
import { workspaceCursor, workspacesApi } from '../workspaces'
import { installFetch, pathAt, respondOnce, v1List } from './v1-fetch'

beforeEach(() => {
  installFetch()
})

describe('workspaceCompositeId', () => {
  it('carries the type, because a slug is unique only within one', () => {
    expect(workspaceCompositeId({ type: 'organization', slug: 'acme' })).toBe('organization:acme')
    expect(workspaceCompositeId({ type: 'team', slug: 'acme' })).toBe('team:acme')
  })
})

describe('workspaceListLabel', () => {
  it('is the trimmed name when there is one', () => {
    expect(workspaceListLabel({ name: '  Acme ', type: 'organization' })).toBe('Acme')
  })
  it('names a nameless personal workspace "My Workspace" and any other "Workspace"', () => {
    expect(workspaceListLabel({ name: ' ', type: 'individual' })).toBe('My Workspace')
    expect(workspaceListLabel({ name: '', type: 'team' })).toBe('Workspace')
  })
})

describe('firstWorkspacePerSlug', () => {
  it('keeps the first row of each slug, in order', () => {
    const rows = [
      { slug: 'me', type: 'individual' },
      { slug: 'acme', type: 'organization' },
      { slug: 'acme', type: 'team' },
      { slug: 'crew', type: 'team' },
    ]
    expect(firstWorkspacePerSlug(rows)).toEqual([rows[0], rows[1], rows[3]])
  })
})

describe('workspaceCursor', () => {
  it('pages by slug, the only key a workspace row carries', () => {
    expect(workspaceCursor({ slug: 'acme' })).toBe('acme')
    expect(workspaceCursor({ id: 'x' })).toBeUndefined()
    expect(workspaceCursor(null)).toBeUndefined()
  })
})

describe('workspacesApi.listAll', () => {
  it('returns every row, teams included, in the backend order', async () => {
    respondOnce(
      v1List([
        { slug: 'me', name: 'Me', type: 'individual' },
        { slug: 'acme', name: 'Acme', type: 'organization' },
        { slug: 'crew', name: 'Crew', type: 'team' },
      ]),
    )
    const rows = await workspacesApi.listAll()
    expect(rows.map((r) => r.slug)).toEqual(['me', 'acme', 'crew'])
    expect(pathAt(0)).toContain('/api/v1/workspaces')
  })
})
