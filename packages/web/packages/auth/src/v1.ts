'use client'

// The /v1 wire conventions every adh client shares, in the lowest tier that holds an
// HTTP client (this package's authed fetch). adh's /v1 API is shaped after Stripe's:
//
//   * a collection answers `{object: 'list', data, has_more, url}`, paged by `limit`
//     (1–100), `starting_after` and `ending_before` (an object id);
//   * a DELETE answers 200 with a tombstone `{id, object, deleted: true}`;
//   * `created`/`updated` are unix seconds; every other timestamp stays an ISO string;
//   * `include[]` folds a sub-resource into the read (`GET /v1/account?include[]=x`).
//
// `listAllV1` is the ONE place that walks a collection to its end — a caller that
// needs every row calls it rather than looping `starting_after` itself.

import { authedJson } from './client'

/** The /v1 collection envelope. */
export interface V1List<T> {
  object: 'list'
  data: T[]
  has_more: boolean
  url: string
}

/** What a /v1 DELETE answers. */
export interface V1Deleted {
  id: string
  object: string
  deleted: true
}

/** The widest page /v1 serves. */
export const V1_PAGE_MAX = 100

type QueryValue = string | number | boolean | null | undefined | readonly (string | number)[]

/**
 * `url` with `params` appended to its query string. `null`/`undefined` values are
 * dropped; an array repeats its key (`include[]=a&include[]=b`). A key already in
 * `url` is replaced, so a cursor can be advanced on a URL that carries one.
 */
export function withV1Query(url: string, params: Record<string, QueryValue>): string {
  const hashAt = url.indexOf('#')
  const hash = hashAt >= 0 ? url.slice(hashAt) : ''
  const noHash = hashAt >= 0 ? url.slice(0, hashAt) : url
  const qAt = noHash.indexOf('?')
  const path = qAt >= 0 ? noHash.slice(0, qAt) : noHash
  const search = new URLSearchParams(qAt >= 0 ? noHash.slice(qAt + 1) : '')
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null) continue
    search.delete(key)
    if (Array.isArray(value)) for (const v of value) search.append(key, String(v))
    else search.set(key, String(value))
  }
  const qs = search.toString()
  return `${path}${qs ? `?${qs}` : ''}${hash}`
}

function defaultCursor(row: unknown): string | undefined {
  if (row && typeof row === 'object' && 'id' in row) {
    const id = (row as { id: unknown }).id
    if (typeof id === 'string' || typeof id === 'number') return String(id)
  }
  return undefined
}

export interface ListAllV1Options {
  /** The cursor a row pages by; defaults to its `id`. */
  cursorOf?: (row: unknown) => string | undefined
}

/**
 * Every row of a /v1 collection: fetches `limit=100` pages, advancing
 * `starting_after` to the last row's id while `has_more`. `url` may carry its own
 * filters; `init` is passed to each page's request (GET).
 *
 * A page whose last row has no id while `has_more` is still true cannot be advanced
 * (the gateway pages by id), so that throws rather than returning a silently
 * truncated list.
 */
export async function listAllV1<T>(
  url: string,
  init: RequestInit = {},
  opts: ListAllV1Options = {},
): Promise<T[]> {
  const cursorOf = opts.cursorOf ?? defaultCursor
  const rows: T[] = []
  let after: string | undefined
  for (;;) {
    const page = await authedJson<V1List<T>>(
      withV1Query(url, { limit: V1_PAGE_MAX, starting_after: after }),
      init,
    )
    const data = Array.isArray(page?.data) ? page.data : []
    rows.push(...data)
    if (!page?.has_more || data.length === 0) return rows
    const next = cursorOf(data[data.length - 1])
    if (next === undefined) {
      throw new Error(`${url}: has_more is set but the last row carries no id to page from`)
    }
    after = next
  }
}

/** One page of a /v1 collection, unwrapped: its rows and whether more follow. */
export async function listV1Page<T>(
  url: string,
  init: RequestInit = {},
): Promise<{ data: T[]; hasMore: boolean }> {
  const page = await authedJson<V1List<T>>(url, init)
  return { data: Array.isArray(page?.data) ? page.data : [], hasMore: page?.has_more === true }
}

/** A /v1 unix-second timestamp (`created`, `updated`) as an ISO string. */
export function unixToIso(seconds: number): string
export function unixToIso(seconds: number | null | undefined): string | null
export function unixToIso(seconds: number | null | undefined): string | null {
  if (seconds === null || seconds === undefined || !Number.isFinite(seconds)) return null
  return new Date(seconds * 1000).toISOString()
}

/** An ISO timestamp as /v1 unix seconds — for a filter or a body that takes one. */
export function isoToUnix(iso: string): number {
  return Math.floor(Date.parse(iso) / 1000)
}
