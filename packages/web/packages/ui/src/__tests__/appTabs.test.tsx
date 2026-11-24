/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, cleanup, fireEvent } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { AppTabs } from '../blocks/app-tabs'

afterEach(cleanup)

const two = [
  { id: 'tab1', label: 'T1' },
  { id: 'tab2', label: 'T2' },
]

describe('AppTabs conformance vectors', () => {
  it('app-tabs-001 renders every item as a button with its label', () => {
    render(<AppTabs items={[{ id: 'tab1', label: 'Tab 1' }, { id: 'tab2', label: 'Tab 2' }]} value="" />)
    const buttons = screen.getAllByRole('tab')
    expect(buttons.map((b) => b.tagName)).toEqual(['BUTTON', 'BUTTON'])
    expect(buttons.map((b) => b.textContent)).toEqual(['Tab 1', 'Tab 2'])
  })

  it('app-tabs-002 marks only the matching tab active', () => {
    render(<AppTabs items={two} value="tab1" />)
    const [a, b] = screen.getAllByRole('tab')
    expect(a).toHaveAttribute('aria-selected', 'true')
    expect(a).toHaveAttribute('data-active', 'true')
    expect(b).toHaveAttribute('aria-selected', 'false')
    expect(b).not.toHaveAttribute('data-active')
  })

  it('app-tabs-003 renders the icon inside the tab button beside the label', () => {
    render(<AppTabs items={[{ id: 'tab1', label: 'Tab', icon: <svg data-testid="icon" /> }]} value="" />)
    const tab = screen.getByRole('tab')
    expect(tab).toContainElement(screen.getByTestId('icon'))
    expect(tab.textContent).toBe('Tab')
  })

  it('app-tabs-004 clicking a tab calls onValueChange with its id', () => {
    const spy = vi.fn()
    render(<AppTabs items={[{ id: 'tab1', label: 'T1' }]} value="" onValueChange={spy} />)
    fireEvent.click(screen.getByRole('tab'))
    expect(spy).toHaveBeenCalledTimes(1)
    expect(spy).toHaveBeenCalledWith('tab1')
  })

  it('app-tabs-005 renders endItem as a button after all items, pushed to the trailing edge', () => {
    render(<AppTabs items={two} value="" endItem={{ id: 'settings', label: 'Settings' }} />)
    const tabs = screen.getAllByRole('tab')
    expect(tabs.map((t) => t.textContent)).toEqual(['T1', 'T2', 'Settings'])
    expect(tabs[2]!.tagName).toBe('BUTTON')
    expect(tabs[2]!.className).toContain('ml-auto')
    expect(tabs[0]!.className).not.toContain('ml-auto')
  })

  it('app-tabs-006 items follow value; endItem follows its own active flag', () => {
    render(
      <AppTabs
        items={[{ id: 'tab1', label: 'Tab' }]}
        value="tab1"
        endItem={{ id: 'settings', label: 'Settings', active: true }}
      />,
    )
    expect(screen.getByRole('tab', { name: 'Tab' })).toHaveAttribute('aria-selected', 'true')
    expect(screen.getByRole('tab', { name: 'Settings' })).toHaveAttribute('aria-selected', 'true')
    expect(screen.getByRole('tab', { name: 'Settings' })).toHaveAttribute('data-active', 'true')
  })

  it('app-tabs-006 endItem is not active just because value matches its id', () => {
    render(<AppTabs items={[]} value="settings" endItem={{ id: 'settings', label: 'Settings' }} />)
    expect(screen.getByRole('tab')).toHaveAttribute('aria-selected', 'false')
  })

  it('app-tabs-007 root has role tablist', () => {
    render(<AppTabs items={two} value="" />)
    expect(screen.getByRole('tablist').tagName).toBe('DIV')
  })

  it('app-tabs-008 every rendered button has role tab', () => {
    const { container } = render(<AppTabs items={two} value="" endItem={{ id: 'e', label: 'E' }} />)
    const buttons = container.querySelectorAll('button')
    expect(buttons).toHaveLength(3)
    for (const b of buttons) expect(b).toHaveAttribute('role', 'tab')
  })

  it('app-tabs-009 applies className to the root container', () => {
    render(<AppTabs items={two} value="" className="custom-class" />)
    expect(screen.getByRole('tablist').classList.contains('custom-class')).toBe(true)
  })

  it('app-tabs-010 renders no content panels', () => {
    const { container } = render(<AppTabs items={two} value="tab1" endItem={{ id: 'e', label: 'E' }} />)
    expect(screen.queryByRole('tabpanel', { hidden: true })).toBeNull()
    expect(container.querySelector('[role="tabpanel"]')).toBeNull()
    expect(container.querySelectorAll('button')).toHaveLength(3)
  })

  it('app-tabs-011 clicking endItem calls onValueChange with its id', () => {
    const spy = vi.fn()
    render(
      <AppTabs
        items={[{ id: 'tab1', label: 'T1' }]}
        value=""
        endItem={{ id: 'settings', label: 'Settings' }}
        onValueChange={spy}
      />,
    )
    fireEvent.click(screen.getByRole('tab', { name: 'Settings' }))
    expect(spy).toHaveBeenCalledTimes(1)
    expect(spy).toHaveBeenCalledWith('settings')
  })

  it('app-tabs-012 empty items still renders the list and the endItem', () => {
    render(<AppTabs items={[]} value="" endItem={{ id: 'settings', label: 'Settings' }} />)
    expect(screen.getByRole('tablist')).toBeInTheDocument()
    const tabs = screen.getAllByRole('tab')
    expect(tabs).toHaveLength(1)
    expect(tabs[0]!.textContent).toBe('Settings')
  })

  it('app-tabs-013 a value matching no tab leaves every tab inactive', () => {
    render(<AppTabs items={[{ id: 'tab1', label: 'T1' }]} value="missing" />)
    const tab = screen.getByRole('tab')
    expect(tab).toHaveAttribute('aria-selected', 'false')
    expect(tab).not.toHaveAttribute('data-active')
    expect(document.querySelector('[data-active]')).toBeNull()
  })

  it('app-tabs-014 endItem without active is unselected', () => {
    render(<AppTabs items={[]} value="" endItem={{ id: 'settings', label: 'Settings' }} />)
    const tab = screen.getByRole('tab')
    expect(tab).toHaveAttribute('aria-selected', 'false')
    expect(tab).not.toHaveAttribute('data-active')
  })

  it('app-tabs-015 a null or false icon renders nothing but the label', () => {
    for (const icon of [null, false] as const) {
      const { unmount } = render(<AppTabs items={[{ id: 'tab1', label: 'Tab', icon }]} value="" />)
      const tab = screen.getByRole('tab')
      expect(tab.textContent).toBe('Tab')
      expect(tab.children).toHaveLength(0)
      unmount()
    }
  })

  it('app-tabs-016 clicking without onValueChange does nothing and does not throw', () => {
    render(<AppTabs items={[{ id: 'tab1', label: 'T1' }]} value="" />)
    expect(() => fireEvent.click(screen.getByRole('tab'))).not.toThrow()
  })

  it('app-tabs-017 duplicate ids both read as selected', () => {
    const err = vi.spyOn(console, 'error').mockImplementation(() => {})
    render(<AppTabs items={[{ id: 'a', label: 'A' }, { id: 'a', label: 'B' }]} value="a" />)
    for (const t of screen.getAllByRole('tab')) expect(t).toHaveAttribute('aria-selected', 'true')
    err.mockRestore()
  })
})
