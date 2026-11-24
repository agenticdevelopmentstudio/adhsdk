import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import { JsonLd, withWebSite } from '../index'

const site = { name: 'Site', url: 'https://x.example', description: 'What it is.' }
const webSite = { '@type': 'WebSite', '@id': 'https://x.example/#website', ...site }

describe('json-ld conformance vectors', () => {
  it('json-ld-001 adds a WebSite ahead of the site’s own entities', () => {
    const doc = withWebSite(site, { '@context': 'https://schema.org', '@graph': [{ '@type': 'Organization', name: 'O' }] })
    expect(doc).toEqual({
      '@context': 'https://schema.org',
      '@graph': [webSite, { '@type': 'Organization', name: 'O' }],
    })
  })

  it('json-ld-002 keeps a WebSite the site already declares, without its @context', () => {
    const doc = withWebSite(site, { '@context': 'https://schema.org', '@type': 'WebSite', name: 'Mine' })
    expect(doc['@graph']).toEqual([{ '@type': 'WebSite', name: 'Mine' }])
  })

  it('json-ld-003 escapes `<` so the data cannot close its script', () => {
    const html = renderToStaticMarkup(<JsonLd data={{ name: '</script><b>' }} />)
    expect(html).toBe('<script type="application/ld+json">{"name":"\\u003c/script>\\u003cb>"}</script>')
  })

  it('json-ld-004 leaves `>` unescaped', () => {
    const html = renderToStaticMarkup(<JsonLd data={{ name: '</script><b>' }} />)
    expect(html).toContain('>')
    expect(html).not.toContain('\\u003e')
    expect(html).toContain('\\u003c/script>')
  })

  it('json-ld-005 accepts an omitted or null extra', () => {
    expect(withWebSite(site)['@graph']).toEqual([webSite])
    expect(withWebSite(site, null)['@graph']).toEqual([webSite])
  })

  it('json-ld-006 trims every trailing slash from the @id only', () => {
    const doc = withWebSite({ ...site, url: 'https://x.example///' })
    const [entity] = doc['@graph'] as Record<string, unknown>[]
    expect(entity['@id']).toBe('https://x.example/#website')
    expect(entity.url).toBe('https://x.example///')
  })

  it('json-ld-007 accepts a single entity as extra', () => {
    const a = { '@type': 'Thing', name: 'A' }
    expect(withWebSite(site, a)['@graph']).toEqual([webSite, a])
  })

  it('json-ld-008 flattens nested lists and nested @graph arrays in order', () => {
    const [a, b, c, d] = ['A', 'B', 'C', 'D'].map((name) => ({ '@type': 'Thing', name }))
    const doc = withWebSite(site, [a, { '@graph': [b, [c]] }, d])
    expect(doc['@graph']).toEqual([webSite, a, b, c, d])
  })

  it('json-ld-009 strips @context from entities taken from extra', () => {
    const doc = withWebSite(site, { '@context': 'https://schema.org', '@type': 'Thing', name: 'A' })
    const entity = (doc['@graph'] as Record<string, unknown>[])[1]
    expect('@context' in entity).toBe(false)
    expect(entity.name).toBe('A')
  })

  it('json-ld-010 does not mutate the objects passed in extra', () => {
    const original = { '@context': 'https://schema.org', '@type': 'Thing', name: 'A' }
    withWebSite(site, original)
    expect(original['@context']).toBe('https://schema.org')
  })

  it('json-ld-011 detects an existing WebSite only by the exact string @type', () => {
    const typed = { '@type': ['WebSite', 'Thing'], name: 'Mine' }
    const doc = withWebSite(site, typed)
    expect(doc['@graph']).toEqual([webSite, typed])
  })

  it('json-ld-012 treats an empty @graph as no entities', () => {
    expect(withWebSite(site, { '@graph': [] })['@graph']).toEqual([webSite])
  })

  it('json-ld-013 is pure: equal arguments give deeply equal results', () => {
    const extra = { '@context': 'https://schema.org', '@type': 'Thing', name: 'A' }
    const snapshot = structuredClone(extra)
    const first = withWebSite(site, extra)
    const second = withWebSite(site, extra)
    expect(first).toEqual(second)
    expect(first).not.toBe(second)
    expect(extra).toEqual(snapshot)
    expect(site).toEqual({ name: 'Site', url: 'https://x.example', description: 'What it is.' })
  })
})
