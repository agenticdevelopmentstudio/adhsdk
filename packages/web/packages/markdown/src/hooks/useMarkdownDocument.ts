'use client'

import { useEffect, useRef, useState } from 'react'
import type { MarkdownDocument } from '../types'

export type FetchState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'error'; message: string }
  | { status: 'success'; data: T }

/**
 * Fetches a markdown document by id. Receives an AbortSignal so the caller can
 * cancel on unmount / id change / timeout. The default implementation calls the
 * host app's API forwarder; consumers (and tests) can inject an alternative.
 */
export type MarkdownFetcher = (
  id: string,
  signal: AbortSignal,
) => Promise<MarkdownDocument>

/** Default request timeout (ms) before the fetch is aborted and surfaced as an error. */
const DEFAULT_TIMEOUT_MS = 15_000

/** Sentinel so a timeout abort is distinguishable from an unmount/id-change abort. */
const TIMEOUT_REASON = 'mdv-timeout'

/**
 * Read an RFC 9457 problem detail (`application/problem+json`), a /v1 error body or a
 * plain-text body and return a human-readable message for the error state (c3).
 */
async function messageFromResponse(res: Response, id: string): Promise<string> {
  const contentType = res.headers.get('content-type') ?? ''
  // Read the body ONCE as text — a Response body is a single-use stream, so
  // calling res.json() then res.text() would throw "body already used" and lose
  // the fallback text. Parse problem+json from the text we already have.
  const body = await res.text().catch(() => '')
  if (contentType.includes('application/problem+json')) {
    try {
      const problem = JSON.parse(body) as { title?: string; detail?: string }
      const parts = [problem.title, problem.detail].filter(Boolean)
      if (parts.length > 0) return parts.join(' — ')
    } catch {
      // malformed problem+json — fall through to the generic message
    }
  }
  // /v1 errors are `{ error: { type, code, message, param } }` as plain JSON.
  try {
    const v1 = JSON.parse(body) as { error?: { message?: unknown } }
    const message = v1?.error?.message
    if (res.status !== 404 && typeof message === 'string' && message) return message
  } catch {
    // not JSON — fall through
  }
  if (res.status === 404) return `Document not found (id: ${id}).`
  return body || `Failed to load document (HTTP ${res.status}).`
}

/** A paper as `GET /v1/papers/:id` sends it (`MarkdownDocument`): snake_case, `created` and
 *  `updated` in unix seconds. This package carries no auth/API dependency, so the wire shape
 *  and its one mapping live here. */
interface PaperWire {
  id: string
  owner_kind: string
  owner_id: string
  author_kind?: string | null
  author_id?: string | null
  ecosystem_id: string
  deleted_at?: string | null
  title: string
  content: string
  frontmatter?: { [key: string]: unknown } | null
  category?: string | null
  tags: string[]
  visibility: 'private' | 'public'
  stage: 'draft' | 'final'
  kind: 'paper' | 'research'
  public_route?: string | null
  content_hash: string
  size_bytes: number
  current_version: number
  latest_version_id?: string | null
  created: number
  updated: number
  is_deleted: boolean
}

const iso = (seconds: number): string => new Date(seconds * 1000).toISOString()

function documentFromWire(w: PaperWire): MarkdownDocument {
  return {
    id: w.id,
    ownerKind: w.owner_kind,
    ownerId: w.owner_id,
    authorKind: w.author_kind,
    authorId: w.author_id,
    ecosystemId: w.ecosystem_id,
    deletedAt: w.deleted_at,
    title: w.title,
    content: w.content,
    frontmatter: w.frontmatter,
    category: w.category,
    tags: w.tags,
    visibility: w.visibility,
    stage: w.stage,
    kind: w.kind,
    publicRoute: w.public_route,
    contentHash: w.content_hash,
    sizeBytes: w.size_bytes,
    currentVersion: w.current_version,
    latestVersionId: w.latest_version_id,
    createdAt: iso(w.created),
    updatedAt: iso(w.updated),
    isDeleted: w.is_deleted,
  }
}

/** The default fetcher: GET /api/v1/papers/:id through the host app's forwarder. */
export const defaultMarkdownFetcher: MarkdownFetcher = async (id, signal) => {
  const res = await fetch(`/api/v1/papers/${encodeURIComponent(id)}`, {
    credentials: 'same-origin',
    headers: { Accept: 'application/json' },
    signal,
  })
  if (!res.ok) {
    // Throw a message-bearing error so the hook surfaces a readable error state.
    throw new Error(await messageFromResponse(res, id))
  }
  return documentFromWire((await res.json()) as PaperWire)
}

export interface UseMarkdownDocumentOptions {
  /** Injected fetcher (default: the real API forwarder). Lets demos/tests seed content. */
  fetcher?: MarkdownFetcher
  /** Abort + error after this many ms (default 15000). */
  timeoutMs?: number
}

/**
 * Fetches a markdown document by id and exposes a discriminated-union state so
 * the caller can render loading / error / success branches explicitly.
 *
 * Uses an AbortController: the request is aborted on unmount, on id change, and
 * on timeout. A missing/blank id short-circuits to an error (fail-fast, c3).
 */
export function useMarkdownDocument(
  id: string | undefined,
  options: UseMarkdownDocumentOptions = {},
): FetchState<MarkdownDocument> {
  const { fetcher = defaultMarkdownFetcher, timeoutMs = DEFAULT_TIMEOUT_MS } = options

  // Hold the fetcher in a ref so an UNMEMOIZED inline fetcher prop does not
  // re-trigger the effect every render — that would loop: fetch → setState →
  // re-render → new fetcher reference → effect re-fires → fetch … The effect
  // depends only on [id, timeoutMs] and reads the latest fetcher from the ref.
  const fetcherRef = useRef(fetcher)
  fetcherRef.current = fetcher

  // Seed loading when an id is present so the first paint doesn't flash idle.
  const [state, setState] = useState<FetchState<MarkdownDocument>>(() =>
    id ? { status: 'loading' } : { status: 'idle' },
  )

  useEffect(() => {
    // No id → nothing to fetch; the neutral idle state is DERIVED below rather
    // than synced here (a missing id is "no document selected", not an error).
    if (!id) return

    const controller = new AbortController()
    const timer = setTimeout(() => controller.abort(TIMEOUT_REASON), timeoutMs)
    setState({ status: 'loading' })

    fetcherRef
      .current(id, controller.signal)
      .then((doc) => {
        // Drop only an unmount/id-change abort; if the data arrived despite a
        // timeout abort, show it rather than getting stuck on "loading".
        if (controller.signal.aborted && controller.signal.reason !== TIMEOUT_REASON) {
          return
        }
        setState({ status: 'success', data: doc })
      })
      .catch((err: unknown) => {
        // An unmount/id-change abort is expected — drop it silently.
        if (controller.signal.aborted && controller.signal.reason !== TIMEOUT_REASON) {
          return
        }
        const message =
          controller.signal.reason === TIMEOUT_REASON
            ? `Timed out loading document after ${Math.round(timeoutMs / 1000)}s.`
            : err instanceof Error
              ? err.message
              : 'Network error.'
        setState({ status: 'error', message })
      })
      .finally(() => clearTimeout(timer))

    return () => {
      clearTimeout(timer)
      controller.abort()
    }
  }, [id, timeoutMs])

  // Derive the absent-id case (no effect-driven state sync, no flash).
  return id ? state : { status: 'idle' }
}
