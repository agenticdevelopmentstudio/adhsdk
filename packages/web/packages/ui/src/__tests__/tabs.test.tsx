import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect, vi } from 'vitest'
import { DirectionProvider } from '@base-ui/react/direction-provider'
import { Tabs, TabsList, TabsTab, TabsPanel } from '../components/tabs'

function Basic(props: {
  defaultValue?: string
  value?: string
  onValueChange?: (v: string) => void
  disabled?: string[]
  dir?: 'rtl'
  classes?: boolean
}) {
  const { disabled = [], dir, classes, ...root } = props
  const c = (n: string) => (classes ? `custom-${n}` : undefined)
  return (
    <DirectionProvider direction={dir ?? 'ltr'}>
    <div dir={dir}>
      <button type="button">before</button>
      <Tabs {...root} className={c('root')}>
        <TabsList className={c('list')}>
          {['a', 'b', 'c'].map((v) => (
            <TabsTab key={v} value={v} disabled={disabled.includes(v)} className={c('tab')}>
              Label {v.toUpperCase()}
            </TabsTab>
          ))}
        </TabsList>
        {['a', 'b', 'c'].map((v) => (
          <TabsPanel key={v} value={v} className={c('panel')}>
            Content {v}
          </TabsPanel>
        ))}
      </Tabs>
      <button type="button">after</button>
    </div>
    </DirectionProvider>
  )
}

const tab = (n: string) => screen.getByRole('tab', { name: `Label ${n}` })

describe('Tabs conformance vectors', () => {
  it('tabs-001 render-tab-list: flex container with bottom border', () => {
    render(<Basic defaultValue="a" />)
    const list = screen.getByRole('tablist')
    expect(list.className).toContain('flex')
    expect(list.className).toContain('border-b')
  })

  it('tabs-002 render-tabs: tab is a button with text', () => {
    render(<Basic defaultValue="a" />)
    expect(tab('A').tagName).toBe('BUTTON')
    expect(tab('A').textContent).toBe('Label A')
  })

  it('tabs-003 render-panels: active panel content visible', () => {
    render(<Basic defaultValue="a" />)
    expect(screen.getByText('Content a')).toBeTruthy()
    expect(screen.queryByText('Content b')).toBeNull()
  })

  it('tabs-004 default-value: defaultValue b is active initially', () => {
    render(<Basic defaultValue="b" />)
    expect(tab('B').getAttribute('aria-selected')).toBe('true')
    expect(tab('A').getAttribute('aria-selected')).toBe('false')
    expect(screen.getByText('Content b')).toBeTruthy()
  })

  it('tabs-005 active-indicator: active has gold border class, inactive transparent', () => {
    render(<Basic defaultValue="a" />)
    expect(tab('A').hasAttribute('data-active')).toBe(true)
    expect(tab('B').hasAttribute('data-active')).toBe(false)
    for (const t of [tab('A'), tab('B')]) {
      expect(t.className).toContain('border-b-2')
      expect(t.className).toContain('border-transparent')
      expect(t.className).toContain('data-[active]:border-apt-gold')
    }
    fireEvent.click(tab('B'))
    expect(tab('B').hasAttribute('data-active')).toBe(true)
    expect(tab('A').hasAttribute('data-active')).toBe(false)
  })

  it('tabs-006 disabled-tabs: click does nothing, dimmed, still focusable', () => {
    render(<Basic defaultValue="a" disabled={['b']} />)
    fireEvent.click(tab('B'))
    expect(tab('A').getAttribute('aria-selected')).toBe('true')
    expect(tab('B').getAttribute('aria-selected')).toBe('false')
    expect(tab('B').className).toContain('disabled:opacity-50')
    tab('B').focus()
    expect(document.activeElement).toBe(tab('B'))
  })

  it('tabs-007 click-selection: click selects tab and shows panel', () => {
    render(<Basic defaultValue="a" />)
    fireEvent.click(tab('B'))
    expect(tab('B').getAttribute('aria-selected')).toBe('true')
    expect(screen.getByText('Content b')).toBeTruthy()
    expect(screen.queryByText('Content a')).toBeNull()
  })

  it('tabs-008 aria-tab-roles: roles, aria-controls/labelledby, aria-disabled', () => {
    render(<Basic defaultValue="a" disabled={['b']} />)
    expect(screen.getByRole('tablist')).toBeTruthy()
    const panel = screen.getByRole('tabpanel')
    expect(tab('A').getAttribute('aria-selected')).toBe('true')
    expect(tab('A').getAttribute('aria-controls')).toBe(panel.id)
    expect(panel.getAttribute('aria-labelledby')).toBe(tab('A').id)
    expect(tab('B').getAttribute('aria-disabled')).toBe('true')
  })

  it('tabs-009 hover-emphasis: muted text with hover to full text, border unchanged', () => {
    render(<Basic defaultValue="a" />)
    const cls = tab('B').className
    expect(cls).toContain('text-apt-text-muted')
    expect(cls).toContain('hover:text-apt-text')
    expect(cls).not.toMatch(/hover:border/)
  })

  it('tabs-010 focus-visible-state: keyboard focus shows indicator distinct from hover', () => {
    render(<Basic defaultValue="a" />)
    expect(tab('A').className).toMatch(/focus-visible:(ring|outline|border)/)
  })

  it('tabs-011 class-name: custom classes appended on all four parts', () => {
    render(<Basic defaultValue="a" classes />)
    expect(screen.getByRole('tablist').className).toContain('custom-list')
    expect(tab('A').className).toContain('custom-tab')
    expect(screen.getByRole('tabpanel').className).toContain('custom-panel')
    expect(screen.getByRole('tablist').closest('[data-slot="tabs"]')!.className).toContain('custom-root')
  })

  it('tabs-012 keyboard-tab-navigation: Right moves focus to next incl. disabled, no selection', async () => {
    const user = userEvent.setup()
    render(<Basic defaultValue="a" disabled={['b']} />)
    tab('A').focus()
    await user.keyboard('{ArrowRight}')
    expect(document.activeElement).toBe(tab('B'))
    expect(tab('A').getAttribute('aria-selected')).toBe('true')
    expect(tab('B').getAttribute('aria-selected')).toBe('false')
  })

  it('tabs-013 keyboard-tab-navigation: End moves to last tab even if disabled', async () => {
    const user = userEvent.setup()
    render(<Basic defaultValue="a" disabled={['c']} />)
    tab('A').focus()
    await user.keyboard('{End}')
    expect(document.activeElement).toBe(tab('C'))
  })

  it('tabs-014 controlled-value: onValueChange fires, active changes only on parent update', () => {
    const onValueChange = vi.fn()
    const { rerender } = render(<Basic value="a" onValueChange={onValueChange} />)
    fireEvent.click(tab('B'))
    expect(onValueChange).toHaveBeenCalledTimes(1)
    expect(onValueChange.mock.calls[0]![0]).toBe('b')
    expect(tab('A').getAttribute('aria-selected')).toBe('true')
    rerender(<Basic value="b" onValueChange={onValueChange} />)
    expect(tab('B').getAttribute('aria-selected')).toBe('true')
  })

  it('tabs-015 default-value: no value given activates the first tab', () => {
    render(<Basic />)
    expect(tab('A').getAttribute('aria-selected')).toBe('true')
    expect(screen.getByText('Content a')).toBeTruthy()
  })

  it('tabs-016 keyboard-tab-navigation: Home moves to first tab', async () => {
    const user = userEvent.setup()
    render(<Basic defaultValue="c" />)
    tab('C').focus()
    await user.keyboard('{Home}')
    expect(document.activeElement).toBe(tab('A'))
  })

  it('tabs-017 keyboard-tab-navigation: Tab lands on active tab, second Tab leaves list', async () => {
    const user = userEvent.setup()
    render(<Basic defaultValue="b" />)
    screen.getByRole('button', { name: 'before' }).focus()
    await user.tab()
    expect(document.activeElement).toBe(tab('B'))
    await user.tab()
    expect(screen.getByRole('tablist').contains(document.activeElement)).toBe(false)
  })

  it('tabs-018 keyboard-tab-navigation: rtl (Base UI DirectionProvider) Left goes next, Right goes previous', async () => {
    const user = userEvent.setup()
    render(<Basic defaultValue="a" dir="rtl" />)
    tab('B').focus()
    await user.keyboard('{ArrowLeft}')
    expect(document.activeElement).toBe(tab('C'))
    await user.keyboard('{ArrowRight}')
    expect(document.activeElement).toBe(tab('B'))
  })

  it('tabs-019 visible-label: accessible name is the visible text', () => {
    render(<Basic defaultValue="a" />)
    expect(screen.getByRole('tab', { name: 'Label A' })).toBeTruthy()
  })

  it('tabs-020 disabled-tabs: all disabled, defaultValue b stays selected', () => {
    render(<Basic defaultValue="b" disabled={['a', 'b', 'c']} />)
    expect(tab('B').getAttribute('aria-selected')).toBe('true')
    expect(screen.getByText('Content b')).toBeTruthy()
    fireEvent.click(tab('C'))
    fireEvent.click(tab('A'))
    expect(tab('B').getAttribute('aria-selected')).toBe('true')
    expect(screen.getByText('Content b')).toBeTruthy()
  })

  it('tabs-021 render-tab-list: empty list renders, no panel selected', () => {
    render(
      <Tabs>
        <TabsList />
      </Tabs>,
    )
    expect(screen.getByRole('tablist').children.length).toBe(0)
    expect(screen.queryByRole('tabpanel')).toBeNull()
  })

  it('tabs-022 render-panels: empty panel renders without error', () => {
    render(
      <Tabs defaultValue="a">
        <TabsList>
          <TabsTab value="a">Label A</TabsTab>
        </TabsList>
        <TabsPanel value="a" />
      </Tabs>,
    )
    expect(screen.getByRole('tabpanel').textContent).toBe('')
  })

  it('tabs-023 click-selection: rapid clicks end on the last tab', () => {
    render(<Basic defaultValue="a" />)
    fireEvent.click(tab('B'))
    fireEvent.click(tab('C'))
    fireEvent.click(tab('A'))
    expect(tab('A').getAttribute('aria-selected')).toBe('true')
    expect(screen.getByText('Content a')).toBeTruthy()
  })
})
