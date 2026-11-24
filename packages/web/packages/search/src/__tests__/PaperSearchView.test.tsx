// @vitest-environment jsdom
import { act } from 'react'
import { createRoot, type Root } from 'react-dom/client'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const searchViewProps = vi.hoisted(() => ({ calls: [] as Array<Record<string, unknown>> }))

vi.mock('../components/SearchView', () => ({
  SearchView: (props: Record<string, unknown>) => {
    searchViewProps.calls.push(props)
    return null
  },
}))

import { PaperSearchView, paperSearchSource, type PaperSearchViewProps } from '../components/PaperSearchView'
import { markdownDocumentType } from '../registry/markdown'
import type { SearchSource } from '../types'

;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true

let host: HTMLElement
let root: Root

const documentHref: PaperSearchViewProps['documentHref'] = () => '/p/x'

function mount(props: Partial<PaperSearchViewProps> = {}): Record<string, unknown> {
  searchViewProps.calls.length = 0
  act(() => {
    root.render(<PaperSearchView documentHref={documentHref} {...props} />)
  })
  return searchViewProps.calls[searchViewProps.calls.length - 1]!
}

beforeEach(() => {
  host = document.createElement('div')
  document.body.appendChild(host)
  root = createRoot(host)
})

afterEach(() => {
  act(() => root.unmount())
  host.remove()
})

describe('PaperSearchView conformance vectors', () => {
  it('psv-001 passes documentHref through to SearchView', () => {
    expect(mount().documentHref).toBe(documentHref)
  })

  it('psv-002 default source uses the paper endpoints and /api', () => {
    const source = mount().source as SearchSource
    expect(source.baseUrl).toBe('/api')
    expect(source.endpoints).toEqual({
      results: '/v1/papers',
      tags: '/v1/paper_tags',
      categories: '/v1/paper_categories',
    })
  })

  it('psv-003 source fetchInit is no-store', () => {
    expect((mount().source as SearchSource).fetchInit).toEqual({ cache: 'no-store' })
  })

  it('psv-004 authorSlug becomes the author fixed param', () => {
    expect((mount({ authorSlug: 'author-name' }).source as SearchSource).fixedParams).toEqual({
      author: 'author-name',
    })
  })

  it('psv-005 baseUrl overrides the API prefix', () => {
    expect((mount({ baseUrl: '/custom/api' }).source as SearchSource).baseUrl).toBe('/custom/api')
  })

  it('psv-006 searchLabel override is passed through', () => {
    expect(mount({ searchLabel: 'Custom label' }).searchLabel).toBe('Custom label')
  })

  it('psv-007 searchLabel defaults', () => {
    expect(mount().searchLabel).toBe('Search research papers')
  })

  it('psv-008 searchPlaceholder override is passed through', () => {
    expect(mount({ searchPlaceholder: 'Custom…' }).searchPlaceholder).toBe('Custom…')
  })

  it('psv-009 searchPlaceholder defaults', () => {
    expect(mount().searchPlaceholder).toBe('Search papers…')
  })

  it('psv-010 searchLandmarkLabel override is passed through', () => {
    expect(mount({ searchLandmarkLabel: 'Custom landmark' }).searchLandmarkLabel).toBe('Custom landmark')
  })

  it('psv-011 searchLandmarkLabel defaults', () => {
    expect(mount().searchLandmarkLabel).toBe('Research paper search')
  })

  it('psv-012 registers markdownDocumentType', () => {
    expect(mount().documentType).toBe(markdownDocumentType)
  })

  it('psv-013 authorSlug is trimmed and lowercased', () => {
    expect((mount({ authorSlug: '  Jane Doe  ' }).source as SearchSource).fixedParams).toEqual({
      author: 'jane doe',
    })
  })

  it('psv-014 whitespace-only authorSlug adds no author param', () => {
    const source = mount({ authorSlug: '   ' }).source as SearchSource
    expect(source.fixedParams?.author).toBeUndefined()
    expect(source.fixedParams && 'author' in source.fixedParams).toBeFalsy()
  })

  it('psv-015 paperSearchSource() with no options', () => {
    const s = paperSearchSource()
    expect(s).toEqual({
      baseUrl: '/api',
      endpoints: { results: '/v1/papers', tags: '/v1/paper_tags', categories: '/v1/paper_categories' },
      fetchInit: { cache: 'no-store' },
    })
    expect('fixedParams' in s).toBe(false)
  })

  it('psv-016 SearchView receives exactly the six documented props', () => {
    expect(Object.keys(mount()).sort()).toEqual(
      ['documentHref', 'documentType', 'searchLabel', 'searchLandmarkLabel', 'searchPlaceholder', 'source'],
    )
  })

  it('psv-017 no authorSlug means no fixedParams key', () => {
    expect('fixedParams' in (mount().source as SearchSource)).toBe(false)
  })

  it('psv-018 component source deep-equals the factory result', () => {
    const source = mount({ baseUrl: '/custom/api', authorSlug: 'Jane' }).source
    expect(source).toEqual(paperSearchSource({ baseUrl: '/custom/api', authorSlug: 'Jane' }))
  })

  it('psv-019 label values are passed verbatim', () => {
    expect(mount({ searchLabel: '  Mixed Case  ' }).searchLabel).toBe('  Mixed Case  ')
  })
})
