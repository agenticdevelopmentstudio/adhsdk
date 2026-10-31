import type { ReactElement } from 'react'

/** One schema.org entity, or a `{ "@context", "@graph" }` document of them. */
export type JsonLdValue = Record<string, unknown>

/**
 * A page's structured data, as the `<script type="application/ld+json">` search engines read.
 * `<` is escaped so no string in the data can close the script element.
 */
export function JsonLd({ data }: { data: JsonLdValue }): ReactElement {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data).replace(/</g, '\\u003c') }}
    />
  )
}

/**
 * `entities` as one schema.org document, with a `WebSite` for the site added unless one of
 * them already is one. `extra` may itself be a `{ "@context", "@graph" }` document, a single
 * entity, or a list; its entities keep their order, after the site's.
 *
 * The WebSite entry is what tells an answer engine that the name, the description and the
 * origin belong together, which every site can say without writing anything new.
 */
export function withWebSite(site: { name: string; url: string; description: string }, extra?: unknown): JsonLdValue {
  const entities = graphOf(extra)
  const hasWebSite = entities.some((e) => e['@type'] === 'WebSite')
  const webSite = { '@type': 'WebSite', '@id': `${site.url.replace(/\/+$/, '')}/#website`, ...site }
  return {
    '@context': 'https://schema.org',
    '@graph': hasWebSite ? entities : [webSite, ...entities],
  }
}

function graphOf(value: unknown): JsonLdValue[] {
  if (value === undefined || value === null) return []
  if (Array.isArray(value)) return value.flatMap(graphOf)
  const doc = value as JsonLdValue
  if (Array.isArray(doc['@graph'])) return graphOf(doc['@graph'])
  const entity = { ...doc }
  delete entity['@context']
  return [entity]
}
