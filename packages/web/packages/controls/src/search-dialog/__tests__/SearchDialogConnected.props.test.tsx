import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render } from '@testing-library/react'
import type { ReactNode } from 'react'
import { SiteConfigProvider, ContentProvider, RouteProvider } from '@adh-sdk/model'
import type { SiteConfig, SiteEntry } from '@adh-sdk/model'
import type { SearchDialogProps } from '../SearchDialog'

// The props SearchDialogConnected hands to SearchDialog are only observable by
// replacing SearchDialog, so these vectors live in their own file (vi.mock is file-wide).
const received: SearchDialogProps[] = []
vi.mock('../SearchDialog', () => ({
  SearchDialog: (props: SearchDialogProps) => {
    received.push(props)
    return null
  },
}))

import { SearchDialogConnected } from '../SearchDialogConnected'

function config(sections: { key: string; label: string }[]): SiteConfig {
  return {
    branding: { title: 'T', titleEmphasis: 'E' },
    meta: { description: '', siteUrl: '' },
    hero: { heading: '', body: '' },
    nav: { sections: sections.map((s) => ({ ...s, path: `/${s.key}` })) },
  }
}

const entry: SiteEntry = {
  slug: 'my-page',
  section: 'guides',
  raw: '',
  html: '',
  headings: [],
  frontmatter: { title: 'Install' },
}

function wrap(
  sections: { key: string; label: string }[],
  navigate: (s: string) => void,
  children: ReactNode,
) {
  return (
    <SiteConfigProvider config={config(sections)}>
      <ContentProvider entries={[entry]}>
        <RouteProvider pathname="/" hash="" navigate={navigate}>
          {children}
        </RouteProvider>
      </ContentProvider>
    </SiteConfigProvider>
  )
}

const last = () => received[received.length - 1]

describe('SearchDialogConnected conformance vectors (props handed to SearchDialog)', () => {
  beforeEach(() => {
    received.length = 0
  })

  it('search-dialog-connected-001 forwards open, onClose (same reference) and placeholder', () => {
    const onClose = vi.fn()
    render(wrap([], vi.fn(), <SearchDialogConnected open={true} onClose={onClose} placeholder="Find" />))
    expect(last().open).toBe(true)
    expect(last().placeholder).toBe('Find')
    // onClose is forwarded as-is to the dialog; select wraps it, so also check the pass-through
    expect(last().onClose).toBe(onClose)
  })

  it('search-dialog-connected-003 sectionLabels maps each nav section key to its label', () => {
    render(
      wrap(
        [
          { key: 'guides', label: 'Guides' },
          { key: 'api', label: 'API Reference' },
          { key: 'examples', label: 'Examples' },
        ],
        vi.fn(),
        <SearchDialogConnected open={true} onClose={() => {}} />,
      ),
    )
    expect(last().sectionLabels).toEqual({
      guides: 'Guides',
      api: 'API Reference',
      examples: 'Examples',
    })
  })

  it('search-dialog-connected-004 selecting navigates to the slug, then closes, in that order', () => {
    const order: string[] = []
    const navigate = vi.fn(() => order.push('navigate'))
    const onClose = vi.fn(() => order.push('close'))
    render(wrap([], navigate, <SearchDialogConnected open={true} onClose={onClose} />))
    last().onSelect(entry)
    expect(navigate).toHaveBeenCalledWith('my-page')
    expect(order).toEqual(['navigate', 'close'])
  })

  it('search-dialog-connected-006 empty nav.sections gives empty sectionLabels', () => {
    render(wrap([], vi.fn(), <SearchDialogConnected open={true} onClose={() => {}} />))
    expect(last().sectionLabels).toEqual({})
  })

  it('search-dialog-connected-007 duplicate section keys: the last label wins', () => {
    render(
      wrap(
        [
          { key: 'dup', label: 'First' },
          { key: 'dup', label: 'Second' },
        ],
        vi.fn(),
        <SearchDialogConnected open={true} onClose={() => {}} />,
      ),
    )
    expect(last().sectionLabels).toEqual({ dup: 'Second' })
  })

  it('search-dialog-connected-008 a throwing navigate propagates and onClose is not called', () => {
    const onClose = vi.fn()
    const navigate = vi.fn(() => {
      throw new Error('nav failed')
    })
    render(wrap([], navigate, <SearchDialogConnected open={true} onClose={onClose} />))
    expect(() => last().onSelect(entry)).toThrow('nav failed')
    expect(onClose).not.toHaveBeenCalled()
  })
})
