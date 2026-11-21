import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, cleanup, within } from '@testing-library/react'
import { LinkList, type LinkItem } from '../blocks/link-list'

afterEach(cleanup)

const links: LinkItem[] = [
  { title: 'Docs', href: 'https://example.com/docs', description: 'The docs' },
  { title: 'Report', href: 'https://example.com/r.pdf', kind: 'file' },
  { title: 'Photo', href: 'https://example.com/p.png', image: true },
  { title: 'Gone', href: 'https://example.com/gone.png', image: true, missing: true },
  { title: 'Plain image', image: true },
]

describe('LinkList (ui)', () => {
  it('T1: a list with a row per link, in order', () => {
    const { container } = render(<LinkList links={links} />)
    expect(container.querySelector('ul')).toBeInTheDocument()
    const rows = screen.getAllByRole('listitem')
    expect(rows).toHaveLength(5)
    expect(within(rows[0]!).getByText('Docs')).toBeInTheDocument()
  })

  it('T2: a title with href is a new-tab link; without href it is text', () => {
    render(<LinkList links={links} />)
    const a = screen.getByRole('link', { name: 'Docs' })
    expect(a).toHaveAttribute('href', 'https://example.com/docs')
    expect(a).toHaveAttribute('target', '_blank')
    expect(a.getAttribute('rel')).toContain('noopener')
    expect(screen.queryByRole('link', { name: 'Plain image' })).toBeNull()
    expect(screen.getByText('Plain image')).toBeInTheDocument()
  })

  it('T3: every row has one decorative icon, chosen by kind', () => {
    const { container } = render(<LinkList links={links} />)
    const rows = container.querySelectorAll('li')
    const icon = (i: number) => rows[i]!.querySelector('svg')!
    expect(icon(0)).toHaveClass('lucide-globe')
    expect(icon(1)).toHaveClass('lucide-file')
    expect(icon(2)).toHaveClass('lucide-image')
    expect(icon(4)).toHaveClass('lucide-image')
    rows.forEach((_, i) => expect(icon(i)).toHaveAttribute('aria-hidden', 'true'))
  })

  it('T4: the description shows muted under the title', () => {
    render(<LinkList links={links} />)
    expect(screen.getByText('The docs')).toHaveClass('text-apt-text-muted')
  })

  it('T5: a thumbnail only for an image with href, linked, lazy, bounded', () => {
    const { container } = render(<LinkList links={links} />)
    const imgs = container.querySelectorAll('img')
    expect(imgs).toHaveLength(1)
    const img = imgs[0]!
    expect(img).toHaveAttribute('src', 'https://example.com/p.png')
    expect(img).toHaveAttribute('alt', '')
    expect(img).toHaveAttribute('loading', 'lazy')
    expect(img).toHaveClass('max-h-48', 'rounded-md', 'border')
    expect(img.closest('a')).toHaveAttribute('href', 'https://example.com/p.png')
  })

  it('T6: a missing row is struck through and dim, labelled, with no link or thumbnail', () => {
    render(<LinkList links={links} />)
    const row = screen.getAllByRole('listitem')[3]!
    expect(within(row).getByText('Gone')).toHaveClass('line-through', 'text-apt-text-dim')
    expect(within(row).getByText('missing')).toBeInTheDocument()
    expect(within(row).queryByRole('link')).toBeNull()
    expect(row.querySelector('img')).toBeNull()
  })

  it('T7: empty shows the default label, or a custom one, and no list', () => {
    const { container, rerender } = render(<LinkList links={[]} />)
    expect(screen.getByText('No links yet.')).toBeInTheDocument()
    expect(container.querySelector('ul')).toBeNull()
    rerender(<LinkList links={[]} emptyLabel="Nothing" />)
    expect(screen.getByText('Nothing')).toBeInTheDocument()
  })

  it('T8: className reaches the root', () => {
    const { container } = render(<LinkList links={links} className="mt-2" />)
    expect(container.firstElementChild).toHaveClass('mt-2')
  })
})
