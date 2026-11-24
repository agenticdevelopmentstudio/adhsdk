// The ONE client for the theme persistence API: `/v1/themes`. Reads are public (the
// gateway serves them signed out); writes are env-gated. Everything goes through the
// same same-origin `/api` BFF proxy that every adh site already configures (rewrites
// `/api/:path*` → backend `/:path*`), so this works unchanged on every site. The wire
// is /v1's snake_case with `created`/`updated` in unix seconds; this file maps it onto
// the camelCase `StoredTheme` (ISO strings) the editor has always held.

import { AuthHttpError, authedJson, authedRequest, listAllV1, unixToIso } from '@adh-sdk/auth/client'
import type { ThemeDelta } from '@adh-sdk/themes/tokens'

/** A theme as stored/returned by the backend — `data` is the delta from `basedOn`. */
export interface StoredTheme {
  key: string
  label: string
  basedOn: string | null
  data: ThemeDelta
  createdAt: string
  updatedAt: string
}

export interface ThemeWrite {
  label: string
  basedOn?: string | null
  data: ThemeDelta
}

const API = '/api/v1/themes'

/** A theme as /v1 sends it (`Theme`). */
interface ThemeWire {
  key: string
  label: string
  based_on: string | null
  data: ThemeDelta
  created: number
  updated: number
}

function fromWire(w: ThemeWire): StoredTheme {
  return {
    key: w.key,
    label: w.label,
    basedOn: w.based_on,
    data: w.data,
    createdAt: unixToIso(w.created),
    updatedAt: unixToIso(w.updated),
  }
}

/** The write body in /v1's snake_case; only the fields the caller set travel. */
function toWire(theme: Partial<ThemeWrite> & { key?: string }): Record<string, unknown> {
  const body: Record<string, unknown> = {}
  if (theme.key !== undefined) body.key = theme.key
  if (theme.label !== undefined) body.label = theme.label
  if (theme.basedOn !== undefined) body.based_on = theme.basedOn
  if (theme.data !== undefined) body.data = theme.data
  return body
}

const postInit = (body: unknown): RequestInit => ({
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify(body),
})

/** Every live theme (suite-wide). Empty in production, where the table is untouched;
 *  also [] on 404 so the editor degrades to the baked seeds against a backend that
 *  predates the /v1/themes routes (rather than surfacing a spurious error). Themes
 *  have no `id`, so the list pages by `key`. */
export async function listThemes(): Promise<StoredTheme[]> {
  try {
    const rows = await listAllV1<ThemeWire>(
      API,
      { cache: 'no-store' },
      { cursorOf: (row) => (row as ThemeWire).key },
    )
    return rows.map(fromWire)
  } catch (err) {
    if (err instanceof AuthHttpError && err.status === 404) return []
    throw err
  }
}

export async function createTheme(theme: ThemeWrite & { key: string }): Promise<StoredTheme> {
  return fromWire(await authedJson<ThemeWire>(API, postInit(toWire(theme))))
}

/** /v1 updates are a POST on the item path. */
export async function updateTheme(key: string, patch: Partial<ThemeWrite>): Promise<StoredTheme> {
  return fromWire(
    await authedJson<ThemeWire>(`${API}/${encodeURIComponent(key)}`, postInit(toWire(patch))),
  )
}

export async function deleteTheme(key: string): Promise<void> {
  try {
    await authedRequest(`${API}/${encodeURIComponent(key)}`, { method: 'DELETE' })
  } catch (err) {
    if (err instanceof AuthHttpError && err.status === 404) return
    throw err
  }
}
