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

describe('display conformance vectors', () => {
  const ISO = '2023-11-14T22:13:20.000Z'
  it('display-001 convert-unix-timestamp-columns: created/integer unix seconds to ISO', () => {
    expect(columnDisplayValue(col('created', 'integer'), 1_700_000_000)).toBe(ISO)
  })
  it('display-002 convert-unix-timestamp-columns: updated/integer 0 is the epoch', () => {
    expect(columnDisplayValue(col('updated', 'integer'), 0)).toBe('1970-01-01T00:00:00.000Z')
  })
  it('display-003 pass-through-other-columns: other columns come back unchanged', () => {
    expect(columnDisplayValue(col('count', 'integer'), 5)).toBe(5)
    expect(columnDisplayValue(col('granted_at', 'string'), '2024-01-01T00:00:00Z')).toBe(
      '2024-01-01T00:00:00Z',
    )
  })
  it('display-004 require-numeric-value: a null updated stays null', () => {
    expect(columnDisplayValue(col('updated', 'integer'), null)).toBeNull()
  })
  it('display-005 shared-by-list-surfaces: cellText shows the converted date', () => {
    expect(cellText({ created: 1_700_000_000 }, col('created', 'integer'))).toBe(ISO)
  })
  it('display-006 require-integer-column-type: a string-typed created is unchanged', () => {
    expect(columnDisplayValue(col('created', 'string'), 1_700_000_000)).toBe(1_700_000_000)
  })
  it('display-007 match-name-exactly: Created (capitalised) is unchanged', () => {
    expect(columnDisplayValue(col('Created', 'integer'), 1_700_000_000)).toBe(1_700_000_000)
  })
  it('display-008 require-numeric-value: a numeric string is unchanged', () => {
    expect(columnDisplayValue(col('created', 'integer'), '1700000000')).toBe('1700000000')
  })
  it('display-009 fall-back-on-non-finite: NaN comes back as NaN', () => {
    expect(columnDisplayValue(col('created', 'integer'), NaN)).toBeNaN()
  })
  it('display-010 fall-back-on-non-finite: Infinity comes back as Infinity', () => {
    expect(columnDisplayValue(col('updated', 'integer'), Infinity)).toBe(Infinity)
  })
  it('display-011 require-numeric-value: undefined stays undefined', () => {
    expect(columnDisplayValue(col('updated', 'integer'), undefined)).toBeUndefined()
  })
  it('display-012 throw-on-unrepresentable-date: 1e20 seconds throws RangeError', () => {
    expect(() => columnDisplayValue(col('created', 'integer'), 1e20)).toThrow(RangeError)
  })
  it('display-013 pass-through-other-columns, no-input-mutation: an object keeps its reference', () => {
    const o = { a: 1 }
    expect(columnDisplayValue(col('meta', 'object'), o)).toBe(o)
    expect(o).toEqual({ a: 1 })
  })
})
