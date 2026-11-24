import { fireEvent, render, screen } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { ViewTabBar } from '../blocks/view-tab-bar'

const noop = () => {}

describe('ViewTabBar conformance vectors', () => {
  it('view-tab-bar-001 renders a tablist with one tab button', () => {
    const { container } = render(<ViewTabBar tabs={[{ value: 'a', label: 'Tab A' }]} value="a" onChange={noop} />)
    const list = container.querySelector('div[role="tablist"]')!
    expect(list).not.toBeNull()
    expect(list.querySelectorAll('button[role="tab"]')).toHaveLength(1)
  })

  it('view-tab-bar-002 omits the tablist when tabs and links are empty', () => {
    render(<ViewTabBar tabs={[]} value="" onChange={noop} links={[]} />)
    expect(screen.queryByRole('tablist')).toBeNull()
  })

  it('view-tab-bar-003 renders nav aria-label="views" with one link', () => {
    const { container } = render(
      <ViewTabBar tabs={[]} value="" onChange={noop} links={[{ href: '/a', label: 'Link A' }]} />,
    )
    const nav = container.querySelector('nav[aria-label="views"]')!
    expect(nav).not.toBeNull()
    const anchors = nav.querySelectorAll('a')
    expect(anchors).toHaveLength(1)
    expect(anchors[0]!.getAttribute('href')).toBe('/a')
  })

  it('view-tab-bar-004 omits the nav when links are empty', () => {
    const { container } = render(
      <ViewTabBar tabs={[{ value: 'a', label: 'Tab A' }]} value="a" onChange={noop} links={[]} />,
    )
    expect(container.querySelector('nav')).toBeNull()
  })

  it('view-tab-bar-005 marks only the active tab aria-selected', () => {
    render(
      <ViewTabBar
        tabs={[
          { value: 'a', label: 'A' },
          { value: 'b', label: 'B' },
        ]}
        value="a"
        onChange={noop}
      />,
    )
    const [a, b] = screen.getAllByRole('tab') as [HTMLElement, HTMLElement]
    expect(a.getAttribute('aria-selected')).toBe('true')
    expect(b.getAttribute('aria-selected')).toBe('false')
  })

  it('view-tab-bar-006 clicking a tab calls onChange with its value', () => {
    const onChange = vi.fn()
    render(<ViewTabBar tabs={[{ value: 'a', label: 'A' }]} value="x" onChange={onChange} />)
    fireEvent.click(screen.getByRole('tab'))
    expect(onChange).toHaveBeenCalledWith('a')
  })

  it('view-tab-bar-007 active link has aria-current="page", the other does not', () => {
    const { container } = render(
      <ViewTabBar
        tabs={[]}
        value=""
        onChange={noop}
        links={[
          { href: '/a', label: 'A', active: true },
          { href: '/b', label: 'B', active: false },
        ]}
      />,
    )
    const [a, b] = Array.from(container.querySelectorAll('a')) as HTMLElement[] as [HTMLElement, HTMLElement]
    expect(a.getAttribute('aria-current')).toBe('page')
    expect(b.hasAttribute('aria-current')).toBe(false)
  })

  it('view-tab-bar-008 active tab has data-active=""', () => {
    render(<ViewTabBar tabs={[{ value: 'a', label: 'A' }]} value="a" onChange={noop} />)
    expect(screen.getByRole('tab').getAttribute('data-active')).toBe('')
  })

  it('view-tab-bar-009 inactive tab has no data-active', () => {
    render(<ViewTabBar tabs={[{ value: 'a', label: 'A' }]} value="b" onChange={noop} />)
    expect(screen.getByRole('tab').hasAttribute('data-active')).toBe(false)
  })

  it('view-tab-bar-010 each tab button has role="tab"', () => {
    const { container } = render(
      <ViewTabBar
        tabs={[
          { value: 'a', label: 'A' },
          { value: 'b', label: 'B' },
        ]}
        value="a"
        onChange={noop}
      />,
    )
    const buttons = container.querySelectorAll('button')
    expect(buttons).toHaveLength(2)
    buttons.forEach((b) => expect(b.getAttribute('role')).toBe('tab'))
  })

  it('view-tab-bar-011 title is applied as aria-label and title', () => {
    render(
      <ViewTabBar
        tabs={[{ value: 'a', label: <svg data-testid="icon" />, title: 'Icon Label' }]}
        value="a"
        onChange={noop}
      />,
    )
    const tab = screen.getByRole('tab')
    expect(tab.getAttribute('aria-label')).toBe('Icon Label')
    expect(tab.getAttribute('title')).toBe('Icon Label')
  })

  it.skip('view-tab-bar-013 flex/align/gap/padding computed values: jsdom loads no Tailwind CSS, so computed layout is unavailable', () => {})

  it('view-tab-bar-014 every tab and link shares one className; only active carries data-active', () => {
    const { container } = render(
      <ViewTabBar
        tabs={[
          { value: 'a', label: 'A' },
          { value: 'b', label: 'B' },
        ]}
        value="a"
        onChange={noop}
        links={[
          { href: '/x', label: 'X', active: true },
          { href: '/y', label: 'Y' },
        ]}
      />,
    )
    const items = Array.from(container.querySelectorAll('button, a'))
    expect(items).toHaveLength(4)
    const cls = items[0]!.className
    expect(cls).not.toBe('')
    items.forEach((i) => expect(i.className).toBe(cls))
    expect(items.map((i) => i.hasAttribute('data-active'))).toEqual([true, false, true, false])
  })

  it('view-tab-bar-015 ReactNode labels render', () => {
    render(<ViewTabBar tabs={[{ value: 'a', label: <span>Custom</span> }]} value="a" onChange={noop} />)
    const tab = screen.getByRole('tab')
    expect(tab.querySelector('span')?.textContent).toBe('Custom')
  })

  it('view-tab-bar-016 empty tabs and links still render the container with the custom class, no tablist or nav', () => {
    const { container } = render(<ViewTabBar tabs={[]} value="" onChange={noop} className="x" />)
    const outer = container.firstElementChild as HTMLElement
    expect(outer.classList.contains('x')).toBe(true)
    expect(outer.classList.contains('px-4')).toBe(true)
    expect(container.querySelector('[role="tablist"]')).toBeNull()
    expect(container.querySelector('nav')).toBeNull()
  })

  it('view-tab-bar-017 className merges with the layout classes on the outer container', () => {
    const { container } = render(<ViewTabBar tabs={[]} value="" onChange={noop} className="custom-class" />)
    const outer = container.firstElementChild as HTMLElement
    expect(outer.classList.contains('custom-class')).toBe(true)
    expect(outer.classList.contains('px-4')).toBe(true)
    expect(outer.classList.contains('flex')).toBe(true)
  })
})
