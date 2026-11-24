import { existsSync, readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'

// Where the two drift gates get adh's OpenAPI spec — the one input neither of
// them can derive.
//
// The spec belongs to adh: its `/v1` spec, `openapi.v1.json`, committed in the
// adhbackend repo at `src/adh/openapi.v1.json` and served live at
// https://api.agenticdeveloperhub.com/v1/openapi.json. This package lives inside
// adhsdk, which is consumed standalone by repos that have no spec at all. Both gates
// once read a path relative to `process.cwd()` that was only ever correct while the
// package sat inside adh's frontend; after the move it pointed at a directory that
// does not exist. So the spec is an explicit INPUT — `ADH_OPENAPI_SPEC` — never a
// walk up the tree.
//
// Unset means "no adh checkout here", which is a legitimate state for this repo,
// so the gates skip rather than fail. A silent skip is how a guard goes blind,
// so `skipNotice()` is the single place that says so out loud, and the gate that
// matters — adh's — is expected to set the variable. Set-but-wrong is never
// tolerated: it throws, because a typo'd path must not read as "no adh here".

const raw = process.env.ADH_OPENAPI_SPEC?.trim()

export const ADH_SPEC_PATH: string | null = raw ? resolve(raw) : null

// The legacy `openapi.json` the /v1 routes replay onto. Only the CRUD gate reads it,
// for the `x-exposure` tiers /v1 does not forward: `ADH_OPENAPI_LEGACY_SPEC`, else the
// `openapi.json` committed beside `openapi.v1.json` (tools/gen_table_metadata.py
// resolves it the same way).
const rawLegacy = process.env.ADH_OPENAPI_LEGACY_SPEC?.trim()

function besideV1(): string | null {
  if (!ADH_SPEC_PATH) return null
  const beside = join(dirname(ADH_SPEC_PATH), 'openapi.json')
  return beside !== ADH_SPEC_PATH && existsSync(beside) ? beside : null
}

export const ADH_LEGACY_SPEC_PATH: string | null = rawLegacy ? resolve(rawLegacy) : besideV1()

export function skipNotice(gate: string): void {
  console.warn(
    `SKIPPED ${gate}: ADH_OPENAPI_SPEC is unset, so the committed generated ` +
      `module was cross-checked against nothing. Set it to an adhbackend checkout's ` +
      `src/adh/openapi.v1.json to run this gate.`,
  )
}

function readJson<T>(path: string, envVar: string): T {
  try {
    return JSON.parse(readFileSync(path, 'utf8')) as T
  } catch (cause) {
    throw new Error(
      `${envVar} points at ${path}, which could not be read as ` +
        `JSON. A wrong path must fail loudly — it must not read as "no adh checkout".`,
      { cause },
    )
  }
}

export function loadAdhSpec<T>(): T {
  if (!ADH_SPEC_PATH) {
    throw new Error('loadAdhSpec() called with ADH_OPENAPI_SPEC unset')
  }
  return readJson<T>(ADH_SPEC_PATH, 'ADH_OPENAPI_SPEC')
}

export function loadAdhLegacySpec<T>(): T {
  if (!ADH_LEGACY_SPEC_PATH) {
    throw new Error('loadAdhLegacySpec() called with no legacy spec available')
  }
  return readJson<T>(ADH_LEGACY_SPEC_PATH, 'ADH_OPENAPI_LEGACY_SPEC')
}
