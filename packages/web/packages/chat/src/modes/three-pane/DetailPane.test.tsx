import { describe, it, expect, vi, afterEach } from 'vitest'
import { createRef } from 'react'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { render, fireEvent } from '@testing-library/react'
import { ConnectorRegistryProvider } from './connectors/ConnectorRegistry'
import { DetailPane, type TopicData } from './DetailPane'

const base: TopicData = {
  title: 'Test Topic',
  description: '',
  links: [],
  images: [],
  messageIndex: 0,
}

function wrapped(ui: React.ReactElement) {
  return <ConnectorRegistryProvider>{ui}</ConnectorRegistryProvider>
}

afterEach(() => {
  vi.restoreAllMocks()
})

describe('DetailPane', () => {
  it('detail-001 header contains the literal text Details', () => {
    const { container } = render(<DetailPane topic={null} visible />)
    expect(container.querySelector('.pc-panel-header')?.textContent).toBe('Details')
  })

  it('detail-002 renders empty content when topic is null', () => {
    const { container } = render(<DetailPane topic={null} visible />)
    const content = container.querySelector('.pc-detail-content')
    expect(content).not.toBeNull()
    expect(content?.children.length).toBe(0)
    expect(content?.textContent).toBe('')
  })

  it('detail-003 renders the title', () => {
    const { container } = render(<DetailPane topic={base} visible />)
    expect(container.querySelector('.pc-detail-title')?.textContent).toBe('Test Topic')
  })

  it('detail-004 renders the description below the title', () => {
    const { container } = render(<DetailPane topic={{ ...base, description: 'Test desc' }} visible />)
    const desc = container.querySelector('.pc-detail-desc')
    expect(desc?.textContent).toBe('Test desc')
    const title = container.querySelector('.pc-detail-title')!
    expect(title.nextElementSibling).toBe(desc)
  })

  it('detail-005 omits the description when empty', () => {
    const { container } = render(<DetailPane topic={base} visible />)
    expect(container.querySelector('.pc-detail-desc')).toBeNull()
  })

  it('detail-006 renders images with src and alt', () => {
    const { container } = render(
      <DetailPane topic={{ ...base, images: [{ src: '/img.jpg', alt: 'Alt text' }] }} visible />,
    )
    const img = container.querySelector('img')!
    expect(img.getAttribute('src')).toBe('/img.jpg')
    expect(img.getAttribute('alt')).toBe('Alt text')
  })

  it('detail-007 uses an empty alt when omitted', () => {
    const { container } = render(<DetailPane topic={{ ...base, images: [{ src: '/img.jpg' }] }} visible />)
    expect(container.querySelector('img')!.getAttribute('alt')).toBe('')
  })

  it('detail-008 calls onImageLoad when an image loads', () => {
    const onImageLoad = vi.fn()
    const { container } = render(
      <DetailPane topic={{ ...base, images: [{ src: '/img.jpg' }] }} visible onImageLoad={onImageLoad} />,
    )
    fireEvent.load(container.querySelector('img')!)
    expect(onImageLoad).toHaveBeenCalledTimes(1)
  })

  it('detail-009 renders the Links label and a clickable link', () => {
    const { container, getByText } = render(
      <DetailPane topic={{ ...base, links: [{ label: 'Link1', url: 'http://example.com' }] }} visible />,
    )
    expect(container.querySelector('.pc-detail-links-label')?.textContent).toBe('Links')
    const a = getByText('Link1')
    expect(a.tagName).toBe('A')
    expect(a.getAttribute('href')).toBe('http://example.com')
  })

  it('detail-010 links open in a new tab with noopener noreferrer', () => {
    const { container } = render(
      <DetailPane topic={{ ...base, links: [{ label: 'Link1', url: 'http://example.com' }] }} visible />,
    )
    const a = container.querySelector('a')!
    expect(a.getAttribute('target')).toBe('_blank')
    expect(a.getAttribute('rel')).toBe('noopener noreferrer')
  })

  it('detail-011 falls back to the URL when the label is empty', () => {
    const { container } = render(
      <DetailPane topic={{ ...base, links: [{ label: '', url: 'http://example.com' }] }} visible />,
    )
    expect(container.querySelector('a')!.textContent).toBe('http://example.com')
  })

  it('detail-012 root has pc-pane-visible when visible', () => {
    const { container } = render(<DetailPane topic={null} visible />)
    const root = container.firstElementChild!
    expect(root.classList.contains('pc-pane-visible')).toBe(true)
    expect(root.classList.contains('pc-pane-hidden')).toBe(false)
  })

  it('detail-013 root has pc-pane-hidden when not visible', () => {
    const { container } = render(<DetailPane topic={null} visible={false} />)
    const root = container.firstElementChild!
    expect(root.classList.contains('pc-pane-hidden')).toBe(true)
    expect(root.classList.contains('pc-pane-visible')).toBe(false)
  })

  it('detail-014 renders the connector anchor with data-connector-anchor and no id', () => {
    const { container } = render(wrapped(<DetailPane topic={{ ...base, messageIndex: 5 }} visible />))
    const anchor = container.querySelector('[data-connector-anchor]')!
    expect(anchor.getAttribute('data-connector-anchor')).toBe('panel-5-in')
    expect(anchor.hasAttribute('id')).toBe(false)
  })

  it('detail-015 keeps content mounted when hidden', () => {
    const topic: TopicData = {
      ...base,
      description: 'd',
      images: [{ src: '/i.jpg' }],
      links: [{ label: 'L', url: 'http://x.test' }],
    }
    const { container, rerender } = render(<DetailPane topic={topic} visible />)
    rerender(<DetailPane topic={topic} visible={false} />)
    expect(container.querySelector('.pc-detail-title')).not.toBeNull()
    expect(container.querySelector('.pc-detail-desc')).not.toBeNull()
    expect(container.querySelector('img')).not.toBeNull()
    expect(container.querySelector('a')).not.toBeNull()
  })

  it('detail-016 leaves focus untouched when visible changes', () => {
    const topic: TopicData = { ...base, links: [{ label: 'L', url: 'http://x.test' }] }
    const focusSpy = vi.spyOn(HTMLElement.prototype, 'focus')
    const { container, rerender } = render(<DetailPane topic={topic} visible />)
    const link = container.querySelector('a')!
    link.focus()
    focusSpy.mockClear()
    rerender(<DetailPane topic={topic} visible={false} />)
    expect(document.activeElement).toBe(link)
    expect(focusSpy).not.toHaveBeenCalled()
  })

  it('detail-017 dispatches no analytics event and references no analytics client', () => {
    const topic: TopicData = {
      ...base,
      images: [{ src: '/i.jpg' }],
      links: [{ label: 'L', url: 'http://x.test' }],
    }
    const events: Event[] = []
    const listener = (e: Event) => events.push(e)
    document.addEventListener('analytics', listener)
    window.addEventListener('analytics', listener)
    const { container, rerender } = render(<DetailPane topic={topic} visible />)
    fireEvent.load(container.querySelector('img')!)
    fireEvent.click(container.querySelector('a')!)
    rerender(<DetailPane topic={topic} visible={false} />)
    document.removeEventListener('analytics', listener)
    window.removeEventListener('analytics', listener)
    expect(events).toEqual([])
    const src = readFileSync(resolve(__dirname, 'DetailPane.tsx'), 'utf8')
    expect(src).not.toMatch(/analytics|track\(|gtag|posthog|segment/i)
  })

  it('detail-018 produces no console output', () => {
    const spies = (['log', 'info', 'warn', 'error', 'debug'] as const).map((m) =>
      vi.spyOn(console, m).mockImplementation(() => {}),
    )
    const topic: TopicData = { ...base, images: [{ src: '/i.jpg' }] }
    const { container, rerender } = render(<DetailPane topic={topic} visible />)
    fireEvent.load(container.querySelector('img')!)
    rerender(<DetailPane topic={topic} visible={false} />)
    rerender(<DetailPane topic={null} visible={false} />)
    for (const s of spies) expect(s).not.toHaveBeenCalled()
  })

  it('detail-019 renders a minimal topic standalone with only the title', () => {
    const { container } = render(<DetailPane topic={base} visible />)
    expect(container.querySelector('.pc-detail-title')?.textContent).toBe('Test Topic')
    expect(container.querySelector('[data-connector-anchor]')).toBeNull()
    expect(container.querySelector('.pc-detail-desc')).toBeNull()
    expect(container.querySelector('.pc-detail-images')).toBeNull()
    expect(container.querySelector('.pc-detail-links')).toBeNull()
  })

  it('detail-020 forwards the ref to the root div', () => {
    const ref = createRef<HTMLDivElement>()
    const { container } = render(<DetailPane ref={ref} topic={null} visible />)
    expect(ref.current).toBeInstanceOf(HTMLDivElement)
    expect(ref.current).toBe(container.firstElementChild)
  })

  it('detail-021 renders no connector anchor when topic is null', () => {
    const { container } = render(wrapped(<DetailPane topic={null} visible />))
    expect(container.querySelector('[data-connector-anchor]')).toBeNull()
  })
})
