import { describe, it, expect } from 'vitest'
import { columnDisplayValue } from '../display'
import { cellText } from '../CrudTable'
import type { CrudColumn } from '../types'

const col = (name: string, type: CrudColumn['type']): CrudColumn => ({
  name,
  type,
  required: false,
  nullable: false,
  serverManaged: true,
})

describe('columnDisplayValue', () => {
  it('renders /v1 created/updated unix seconds as an ISO date', () => {
    expect(columnDisplayValue(col('created', 'integer'), 1_700_000_000)).toBe(
      '2023-11-14T22:13:20.000Z',
    )
    expect(columnDisplayValue(col('updated', 'integer'), 0)).toBe('1970-01-01T00:00:00.000Z')
  })
  it('leaves every other column, and a null timestamp, untouched', () => {
    expect(columnDisplayValue(col('count', 'integer'), 5)).toBe(5)
    expect(columnDisplayValue(col('granted_at', 'string'), '2024-01-01T00:00:00Z')).toBe(
      '2024-01-01T00:00:00Z',
    )
    expect(columnDisplayValue(col('updated', 'integer'), null)).toBeNull()
  })
  it('is what the list cell shows', () => {
    expect(cellText({ created: 1_700_000_000 }, col('created', 'integer'))).toBe(
      '2023-11-14T22:13:20.000Z',
    )
  })
})
