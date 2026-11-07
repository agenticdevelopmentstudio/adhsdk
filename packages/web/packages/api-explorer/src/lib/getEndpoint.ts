import { API_ENDPOINTS } from '../generated/endpoints.generated'
import type { EndpointMeta, EndpointRef } from '../types'

/** The map key for a method+path reference (`"GET /persona/personas/{id}"`). */
export function endpointKey(ref: EndpointRef | string): string {
  if (typeof ref === 'string') return ref
  return `${ref.method.toUpperCase()} ${ref.path}`
}

/** Look up generated metadata for an endpoint, by ref or by raw key. */
export function getEndpoint(ref: EndpointRef | string): EndpointMeta | undefined {
  return API_ENDPOINTS[endpointKey(ref)]
}

const METHOD_ORDER: Record<string, number> = { GET: 0, POST: 1, PUT: 2, PATCH: 3, DELETE: 4 }

// Computed once — the generated map is a module constant, so these never change.
let _tags: string[] | null = null
let _byTag: Map<string, EndpointMeta[]> | null = null

function index(): Map<string, EndpointMeta[]> {
  if (!_byTag) {
    _byTag = new Map()
    for (const meta of Object.values(API_ENDPOINTS)) {
      const tag = meta.tag ?? 'other'
      const list = _byTag.get(tag) ?? []
      list.push(meta)
      _byTag.set(tag, list)
    }
    for (const list of _byTag.values()) {
      list.sort(
        (a, b) => a.path.localeCompare(b.path) || (METHOD_ORDER[a.method] ?? 9) - (METHOD_ORDER[b.method] ?? 9),
      )
    }
  }
  return _byTag
}

/** All endpoint tags, sorted — the top level of the API browser. */
export function allTags(): string[] {
  if (!_tags) _tags = [...index().keys()].sort()
  return _tags
}

/** Endpoints under a tag, sorted by path then method (collection before item). */
export function endpointsForTag(tag: string): EndpointMeta[] {
  return index().get(tag) ?? []
}

/**
 * A route as a page names it: a path, with or without a method. Its placeholders may be named
 * differently from the spec's (`{ecosystem id}` for `{ecosystemId}`); only where they are counts.
 */
export interface EndpointMatch {
  method?: string
  path: string
}

/** A path with every `{placeholder}` emptied, so two namings of one route compare equal. */
function shapeOf(path: string): string {
  return path.replace(/\{[^}]*\}/g, '{}')
}

/**
 * The endpoints `matches` name, in the order they name them, each once. A match with a method is
 * that one endpoint; a match with no method is every endpoint on its path. A match the spec has
 * no endpoint for is left out.
 */
export function matchEndpoints(matches: readonly EndpointMatch[]): EndpointMeta[] {
  const out: EndpointMeta[] = []
  const seen = new Set<string>()
  const all = Object.values(API_ENDPOINTS)
  for (const match of matches) {
    const shape = shapeOf(match.path)
    const method = match.method?.toUpperCase()
    const hits = all
      .filter((meta) => shapeOf(meta.path) === shape && (!method || meta.method === method))
      .sort((a, b) => (METHOD_ORDER[a.method] ?? 9) - (METHOD_ORDER[b.method] ?? 9))
    for (const meta of hits) {
      if (seen.has(meta.key)) continue
      seen.add(meta.key)
      out.push(meta)
    }
  }
  return out
}
