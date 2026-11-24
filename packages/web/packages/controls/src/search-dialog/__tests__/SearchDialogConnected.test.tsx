import { describe, it, expect, vi } from 'vitest'
import { render, fireEvent } from '@testing-library/react'
import { SearchDialogConnected } from '../SearchDialogConnected'
import { SiteConfigProvider } from '@adh-sdk/model'
import { ContentProvider } from '@adh-sdk/model'
import { RouteProvider } from '@adh-sdk/model'
import type { SiteConfig, SiteEntry } from '@adh-sdk/model'

const config: SiteConfig = {
  branding: { title: 'T', titleEmphasis: 'E' },
  meta: { description: '', siteUrl: '' },
  hero: { heading: '', body: '' },
  nav: {
    sections: [
      { key: 'guides', label: 'Guides', path: '/guides' },
    ],
  },
}

const entries: SiteEntry[] = [
  {
    slug: '/guides/install',
    section: 'guides',
    raw: '',
    html: '',
    headings: [],
    frontmatter: { title: 'Install', summary: 'How to install' },
  },
]

describe('SearchDialogConnected', () => {
  it('navigates and closes when an entry is selected', () => {
    const navigate = vi.fn()
    const onClose = vi.fn()
    const { container } = render(
      <SiteConfigProvider config={config}>
        <ContentProvider entries={entries}>
          <RouteProvider pathname="/" hash="" navigate={navigate}>
            <SearchDialogConnected open={true} onClose={onClose} />
          </RouteProvider>
        </ContentProvider>
      </SiteConfigProvider>,
    )
    const input = container.querySelector('.awt-search-dialog__input') as HTMLInputElement
    fireEvent.change(input, { target: { value: 'install' } })
    const result = container.querySelector('.awt-search-dialog__result') as HTMLButtonElement
    fireEvent.click(result)
    expect(navigate).toHaveBeenCalledWith('/guides/install')
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  const mount = (open = true) =>
    render(
      <SiteConfigProvider config={config}>
        <ContentProvider entries={entries}>
          <RouteProvider pathname="/" hash="" navigate={() => {}}>
            <SearchDialogConnected open={open} onClose={() => {}} />
          </RouteProvider>
        </ContentProvider>
      </SiteConfigProvider>,
    )

  it('search-dialog-connected-002 lists the entry from the content search index after typing', () => {
    const { container } = mount()
    const input = container.querySelector('.awt-search-dialog__input') as HTMLInputElement
    fireEvent.change(input, { target: { value: 'install' } })
    const titles = Array.from(container.querySelectorAll('.awt-search-dialog__result-title')).map(
      (n) => n.textContent,
    )
    expect(titles).toEqual(['Install'])
  })

  it('search-dialog-connected-004 navigate then onClose on selection (real providers)', () => {
    const order: string[] = []
    const { container } = render(
      <SiteConfigProvider config={config}>
        <ContentProvider entries={entries}>
          <RouteProvider pathname="/" hash="" navigate={(s) => order.push(`navigate:${s}`)}>
            <SearchDialogConnected open={true} onClose={() => order.push('close')} />
          </RouteProvider>
        </ContentProvider>
      </SiteConfigProvider>,
    )
    fireEvent.change(container.querySelector('input')!, { target: { value: 'install' } })
    fireEvent.click(container.querySelector('.awt-search-dialog__result')!)
    expect(order).toEqual(['navigate:/guides/install', 'close'])
  })

  it('search-dialog-connected-005 renders the SearchDialog with mapped section labels', () => {
    const { container } = mount()
    const root = container.firstElementChild as HTMLElement
    expect(root.getAttribute('role')).toBe('dialog')
    fireEvent.change(container.querySelector('input')!, { target: { value: 'install' } })
    expect(container.querySelector('.awt-search-dialog__section-label')!.textContent).toBe('Guides')
  })

  it('search-dialog-connected-005 renders nothing when open is false', () => {
    expect(mount(false).container.firstChild).toBeNull()
  })
})
