import { afterEach, describe, expect, it } from 'vitest'
import { cleanup, fireEvent, render } from '@testing-library/react'
import { InlinePopover } from '../components/InlinePopover'
import type { PopoverData } from '../types'

afterEach(cleanup)

const root = (c: HTMLElement) => c.querySelector('.pc-popover') as HTMLElement

describe('InlinePopover conformance vectors', () => {
  it('inline-popover-001 defaultOpen true renders open and aria-hidden false', () => {
    const { container } = render(<InlinePopover data={{ title: 'T' }} defaultOpen={true} />)
    expect(root(container).classList.contains('pc-popover-open')).toBe(true)
    expect(root(container).getAttribute('aria-hidden')).toBe('false')
  })

  it('inline-popover-002 defaultOpen false renders closed and aria-hidden true', () => {
    const { container } = render(<InlinePopover data={{ title: 'T' }} defaultOpen={false} />)
    expect(root(container).classList.contains('pc-popover-open')).toBe(false)
    expect(root(container).getAttribute('aria-hidden')).toBe('true')
  })

  it('inline-popover-003 clicking the toggle when open closes it', () => {
    const { container } = render(<InlinePopover data={{ title: 'T' }} defaultOpen={true} />)
    fireEvent.click(container.querySelector('button')!)
    expect(root(container).getAttribute('aria-hidden')).toBe('true')
    expect(root(container).classList.contains('pc-popover-open')).toBe(false)
  })

  it('inline-popover-004 clicking the toggle when closed opens it', () => {
    const { container } = render(<InlinePopover data={{ title: 'T' }} defaultOpen={false} />)
    fireEvent.click(container.querySelector('button')!)
    expect(root(container).getAttribute('aria-hidden')).toBe('false')
    expect(root(container).classList.contains('pc-popover-open')).toBe(true)
  })

  it('inline-popover-005 renders the title in a span.pc-popover-title', () => {
    const { container } = render(<InlinePopover data={{ title: 'Test Title' }} />)
    const el = container.querySelector('.pc-popover-title')!
    expect(el.tagName).toBe('SPAN')
    expect(el.textContent).toBe('Test Title')
  })

  it('inline-popover-006 an empty title renders no title element', () => {
    const { container } = render(<InlinePopover data={{ title: '' }} />)
    expect(container.querySelector('.pc-popover-title')).toBeNull()
  })

  it('inline-popover-007 renders the description in a div.pc-popover-desc', () => {
    const { container } = render(
      <InlinePopover data={{ title: 'T', description: 'Test Description' }} />,
    )
    const el = container.querySelector('.pc-popover-desc')!
    expect(el.tagName).toBe('DIV')
    expect(el.textContent).toBe('Test Description')
  })

  it('inline-popover-008 an undefined description renders no description element', () => {
    const { container } = render(<InlinePopover data={{ title: 'T', description: undefined }} />)
    expect(container.querySelector('.pc-popover-desc')).toBeNull()
  })

  it('inline-popover-009 links render in a div.pc-popover-links with one link element', () => {
    const { container } = render(
      <InlinePopover
        data={{ title: 'T', links: [{ url: 'https://example.com', label: 'Example' }] }}
      />,
    )
    const links = container.querySelector('.pc-popover-links')!
    expect(links.tagName).toBe('DIV')
    expect(links.querySelectorAll('a').length).toBe(1)
  })

  it('inline-popover-010 empty or undefined links render no links container', () => {
    const a = render(<InlinePopover data={{ title: 'T', links: [] }} />)
    expect(a.container.querySelector('.pc-popover-links')).toBeNull()
    cleanup()
    const b = render(<InlinePopover data={{ title: 'T', links: undefined }} />)
    expect(b.container.querySelector('.pc-popover-links')).toBeNull()
  })

  it('inline-popover-011 a link displays its label', () => {
    const { container } = render(
      <InlinePopover
        data={{ title: 'T', links: [{ url: 'https://example.com', label: 'Click here' }] }}
      />,
    )
    expect(container.querySelector('a')!.textContent).toBe('Click here')
  })

  it('inline-popover-012 an empty label falls back to the url', () => {
    const { container } = render(
      <InlinePopover data={{ title: 'T', links: [{ url: 'https://example.com', label: '' }] }} />,
    )
    expect(container.querySelector('a')!.textContent).toBe('https://example.com')
  })

  it('inline-popover-013 links open in a new tab with noopener noreferrer', () => {
    const { container } = render(
      <InlinePopover data={{ title: 'T', links: [{ url: 'https://example.com', label: '' }] }} />,
    )
    const a = container.querySelector('a')!
    expect(a.getAttribute('target')).toBe('_blank')
    expect(a.getAttribute('rel')).toBe('noopener noreferrer')
  })

  it('inline-popover-014 the arrow span is always inside the toggle button', () => {
    const datas: PopoverData[] = [{ title: 'T' }, { title: '' }]
    for (const data of datas) {
      const { container } = render(<InlinePopover data={data} />)
      const arrow = container.querySelector('button.pc-popover-toggle > span.pc-popover-arrow')
      expect(arrow).not.toBeNull()
      cleanup()
    }
  })

  it('inline-popover-015 the toggle is a native button whose click handler toggles open state', () => {
    const { container } = render(<InlinePopover data={{ title: 'T' }} />)
    const btn = container.querySelector('.pc-popover-toggle') as HTMLButtonElement
    expect(btn.tagName).toBe('BUTTON')
    expect(btn.hasAttribute('tabindex')).toBe(false)
    expect(btn.disabled).toBe(false)
    // jsdom does not synthesize a click from Enter/Space; native activation is a click event.
    fireEvent.click(btn)
    expect(root(container).getAttribute('aria-hidden')).toBe('true')
    fireEvent.click(btn)
    expect(root(container).getAttribute('aria-hidden')).toBe('false')
  })

  it('inline-popover-016 defaultOpen omitted initializes open', () => {
    const { container } = render(<InlinePopover data={{ title: 'T' }} />)
    expect(root(container).classList.contains('pc-popover-open')).toBe(true)
    expect(root(container).getAttribute('aria-hidden')).toBe('false')
  })

  it('inline-popover-017 the toggle button carries the fixed aria-label regardless of title', () => {
    for (const title of ['Some title', '']) {
      const { container } = render(<InlinePopover data={{ title }} />)
      const btn = container.querySelector('button.pc-popover-toggle')!
      expect(btn.getAttribute('aria-label')).toBe('Toggle details')
      cleanup()
    }
  })

  it('inline-popover-018 the arrow span has no aria-hidden attribute (known gap)', () => {
    const { container } = render(<InlinePopover data={{ title: 'T' }} />)
    expect(container.querySelector('.pc-popover-arrow')!.hasAttribute('aria-hidden')).toBe(false)
  })
})
