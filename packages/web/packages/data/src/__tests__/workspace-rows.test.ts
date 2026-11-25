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
  it('reads every type by its own name, the personal one included', () => {
    // The backend already names the individual workspace after its owner, so reading the name
    // straight through is what puts the USER'S NAME on the row.
    expect(workspaceListLabel({ name: 'Ada', type: 'individual' })).toBe('Ada')
    expect(workspaceListLabel({ name: 'Acme', type: 'organization' })).toBe('Acme')
  })
  it('never renders a NAMELESS workspace, however blank the backend name is', () => {
    // The backend builds the personal row as `displayName ?? slug` — NULLISH-coalescing, so a
    // display name saved as the empty string sails through as `name: ''`. Downstream every
    // consumer treats '' as a present value (the hub breadcrumb's `?? selectedId` fallback does
    // not fire on it), so the refusal has to happen here or the row has no accessible name at all.
    expect(workspaceListLabel({ name: '', type: 'individual' })).toBe('My Workspace')
    expect(workspaceListLabel({ name: '   ', type: 'individual' })).toBe('My Workspace')
    expect(workspaceListLabel({ name: '', type: 'organization' })).toBe('Workspace')
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

  it('reads each row through fromV1, as the drift gate measures it', async () => {
    // adh-api-types' data-workspace-wire.test-d.ts holds WorkspaceRow to FromV1 of the generated
    // row, so the runtime must be that mapping too: the /v1 `object` tag is dropped, not passed on.
    respondOnce(v1List([{ object: 'workspace', slug: 'me', name: 'Me', type: 'individual' }]))
    expect(await workspacesApi.listAll()).toEqual([{ slug: 'me', name: 'Me', type: 'individual' }])
  })
})
