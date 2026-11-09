// How a row value reads in a list cell. The /v1 API serves `created` / `updated` as integer unix
// seconds; every other timestamp column stays an ISO string, so only these two are converted.

import { unixToIso } from '@adh-sdk/auth/client'
import type { CrudColumn } from './types'

/** The /v1 row timestamps, served as integer unix seconds. */
const UNIX_SECONDS_COLUMNS = new Set(['created', 'updated'])

/** `value` as the cell should show it: a unix-seconds `created`/`updated` as an ISO date,
 *  anything else untouched. */
export function columnDisplayValue(column: CrudColumn, value: unknown): unknown {
  if (
    UNIX_SECONDS_COLUMNS.has(column.name) &&
    column.type === 'integer' &&
    typeof value === 'number'
  ) {
    return unixToIso(value) ?? value
  }
  return value
}
