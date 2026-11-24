// Conformance tests for resource-data's pure list/request helpers (client-helpers.ts).
import { describe, expect, it } from 'vitest'
import { compact, enc, narrow, scopeByOwner, sortByText, workspaceQuery } from '../client-helpers'

describe('client-helpers', () => {
  it('resource-data-001 enc percent-encodes URI components', () => {
    expect(enc('a b')).toBe('a%20b')
  })

  it('resource-data-002 compact drops undefined keys and preserves null', () => {
    const out = compact({ a: 1, b: undefined, c: null })
    expect(out).toEqual({ a: 1, c: null })
    expect('b' in out).toBe(false)
  })

  it('resource-data-003 compact does not mutate its input', () => {
    const input: { a: number; b?: number } = { a: 1, b: undefined }
    compact(input)
    expect('b' in input).toBe(true)
    expect(input.b).toBeUndefined()
  })

  it('resource-data-004 narrow falls back when the value is not allowed', () => {
    expect(narrow('x', ['a', 'b'] as const, 'a')).toBe('a')
    expect(narrow('b', ['a', 'b'] as const, 'a')).toBe('b')
  })

  it('resource-data-005 scopeByOwner keeps only the owner’s rows', () => {
    const rows = [{ owner: 1 }, { owner: 2 }]
    expect(scopeByOwner(rows, '1', (r) => String(r.owner))).toEqual([{ owner: 1 }])
    // No owner id: the rows come back unchanged.
    expect(scopeByOwner(rows, undefined, (r) => String(r.owner))).toBe(rows)
  })

  it('resource-data-006 sortByText sorts a copy and leaves the input alone', () => {
    const rows = [{ name: 'b' }, { name: 'a' }]
    const sorted = sortByText(rows, (r) => r.name)
    expect(sorted).toEqual([{ name: 'a' }, { name: 'b' }])
    expect(rows).toEqual([{ name: 'b' }, { name: 'a' }])
    expect(sorted).not.toBe(rows)
  })

  it('resource-data-007 workspaceQuery encodes the workspace', () => {
    expect(workspaceQuery({ workspace: 'a b' })).toBe('?workspace=a%20b')
  })

  it('resource-data-008 workspaceQuery is empty with no workspace', () => {
    expect(workspaceQuery()).toBe('')
    expect(workspaceQuery({})).toBe('')
  })
})
