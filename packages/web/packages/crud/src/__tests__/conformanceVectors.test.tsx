import { describe, it, expect, vi, beforeEach } from 'vitest'
import { act, renderHook, waitFor } from '@testing-library/react'
import { canReadTable, canWriteTable } from '../exposure'
import { EDITABLE_OVERRIDES, isColumnEditable } from '../editability'
import { isRowDirty } from '../edits'
import { useCrudResource } from '../useCrudResource'
import type { CrudColumn, CrudExposure, CrudTableMeta } from '../types'

vi.mock('@adh-sdk/auth/client', () => ({
  authedJson: vi.fn(),
  listAllV1: vi.fn(),
}))

const { authedJson, listAllV1 } = vi.mocked(await import('@adh-sdk/auth/client'))

const table = (exposure: CrudExposure): CrudTableMeta => ({
  key: 'demo/things',
  schema: 'demo',
  table: 'things',
  basePath: '/v1/demo/things',
  itemPath: '/v1/demo/things/{id}',
  pkParams: ['id'],
  exposure,
  columns: [],
})

const ownerTable = table('owner')

beforeEach(() => {
  authedJson.mockReset()
  listAllV1.mockReset()
})

describe('api-toolkit conformance vectors (crud)', () => {
  it('vector 3: read check on an admin-exposure table is false for a non-admin viewer', () => {
    expect(canReadTable(table('admin'), false)).toBe(false)
  })

  it('vector 4: write check on a catalog-exposure table is false for a non-admin viewer', () => {
    expect(canWriteTable(table('catalog'), false)).toBe(false)
    expect(canReadTable(table('catalog'), false)).toBe(true)
  })

  it('vector 5: an override cannot force a relational column editable outside create mode', () => {
    const meta = { ...table('owner'), key: 'demo/vector5' }
    const column: CrudColumn = {
      name: 'owner_id',
      type: 'string',
      required: false,
      nullable: false,
      serverManaged: false,
    }
    EDITABLE_OVERRIDES['demo/vector5'] = { owner_id: true }
    try {
      expect(isColumnEditable(meta, column, 'edit')).toBe(false)
      expect(isColumnEditable(meta, column, 'create')).toBe(true)
    } finally {
      delete EDITABLE_OVERRIDES['demo/vector5']
    }
  })

  it('vector 6: dirty detection is false with no edits and false for an edit typed back to baseline', () => {
    expect(isRowDirty({ name: 'Pro' }, undefined)).toBe(false)
    expect(isRowDirty({ name: 'Pro' }, { name: 'Pro' })).toBe(false)
  })

  it('vector 7: row removal resolves through authedJson DELETE (the delete endpoint answers a 200 tombstone) and re-lists', async () => {
    listAllV1.mockResolvedValue([])
    authedJson.mockResolvedValue({ id: 't1', object: 'thing', deleted: true })
    const { result } = renderHook(() => useCrudResource(ownerTable))
    await waitFor(() => expect(result.current.loading).toBe(false))
    await act(() => result.current.remove({ id: 't1' }))
    expect(authedJson).toHaveBeenCalledWith('/api/v1/demo/things/t1', { method: 'DELETE' })
    expect(listAllV1).toHaveBeenCalledTimes(2)
  })

  it('vector 8: a stale list response arriving after a newer one is discarded', async () => {
    const handles: Array<(rows: unknown) => void> = []
    const deferred = () =>
      new Promise((resolve) => {
        handles.push(resolve)
      }) as never
    listAllV1.mockImplementationOnce(deferred) // mount list: older sequence number
    const { result } = renderHook(() => useCrudResource(ownerTable))
    listAllV1.mockImplementationOnce(deferred) // refresh: newer sequence number
    let refreshing!: Promise<void>
    act(() => {
      refreshing = result.current.refresh()
    })
    expect(handles).toHaveLength(2)
    await act(async () => {
      handles[1]!([{ id: 'new' }])
      await refreshing
    })
    expect(result.current.rows).toEqual([{ id: 'new' }])
    await act(async () => {
      handles[0]!([{ id: 'stale' }])
    })
    expect(result.current.rows).toEqual([{ id: 'new' }])
  })
})
