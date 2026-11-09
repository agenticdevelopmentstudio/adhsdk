import { describe, expect, it } from 'vitest'
import { buildFacetUrl, buildSearchUrl } from '../data/useDocumentSearch'
import { paperSearchSource } from '../components/PaperSearchView'

describe('paperSearchSource', () => {
  it('defaults to the same-origin BFF proxy and the /v1 paper endpoints', () => {
    const s = paperSearchSource()
    expect(s.baseUrl).toBe('/api')
    expect(s.endpoints.results).toBe('/v1/papers')
    expect(s.endpoints.tags).toBe('/v1/paper_tags')
    expect(s.endpoints.categories).toBe('/v1/paper_categories')
    expect(s.fixedParams).toBeUndefined()
  })

  it('scopes to one author when asked', () => {
    const s = paperSearchSource({ authorSlug: 'Ada' })
    expect(s.fixedParams).toEqual({ author: 'ada' })
    expect(buildSearchUrl(s, { q: '', category: '', tag: '' })).toContain('author=ada')
    expect(buildFacetUrl(s, 'categories')).toContain('author=ada')
  })

  it('reads live, never a cached corpus', () => {
    expect(paperSearchSource().fetchInit).toEqual({ cache: 'no-store' })
  })
})
