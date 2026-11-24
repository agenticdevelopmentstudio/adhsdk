import { describe, it, expect, vi, beforeEach } from 'vitest'
import { useState } from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import { SettingsPanel } from '../components/SettingsPanel'

function CompoundExample(props: { selectedId?: string; onSelect?: (id: string) => void; persistKey?: string }) {
  return (
    <SettingsPanel
      sidebarTitle="Settings"
      selectedId={props.selectedId}
      onSelect={props.onSelect}
      persistKey={props.persistKey}
    >
      <SettingsPanel.Sidebar />
      <SettingsPanel.Pane id="general" title="General">
        <div>general body</div>
      </SettingsPanel.Pane>
      <SettingsPanel.Pane id="notifications" title="Notifications" section="Preferences">
        <div>notifications body</div>
      </SettingsPanel.Pane>
      <SettingsPanel.Pane id="security" title="Security" section="Preferences" isDisabled>
        <div>security body</div>
      </SettingsPanel.Pane>
    </SettingsPanel>
  )
}

function resetStorage() {
  const ls = window.localStorage
  if (!ls) return
  for (let i = ls.length - 1; i >= 0; i--) {
    const k = ls.key(i)
    if (k) ls.removeItem(k)
  }
}

describe('SettingsPanel', () => {
  beforeEach(() => {
    resetStorage()
  })

  it('settings-panel-001: selects the first enabled pane by default', () => {
    render(<CompoundExample />)
    expect(screen.getByText('general body')).toBeInTheDocument()
    expect(screen.queryByText('notifications body')).not.toBeInTheDocument()
  })

  it('settings-panel-002: switches pane when sidebar row is clicked', () => {
    render(<CompoundExample />)
    fireEvent.click(screen.getByRole('tab', { name: 'Notifications' }))
    expect(screen.getByText('notifications body')).toBeInTheDocument()
    expect(screen.queryByText('general body')).not.toBeInTheDocument()
  })

  it('settings-panel-003: groups panes by section, unsectioned first', () => {
    render(<CompoundExample />)
    const sidebar = screen.getByRole('navigation', { name: 'Settings sections' })
    const sectionTitles = sidebar.querySelectorAll('.aws-panel__sidebar-section-title')
    expect(sectionTitles).toHaveLength(1)
    expect(sectionTitles[0].textContent).toBe('Preferences')
    const rows = sidebar.querySelectorAll('.aws-panel__sidebar-row')
    expect(rows[0].textContent).toContain('General')
    expect(rows[1].textContent).toContain('Notifications')
    expect(rows[2].textContent).toContain('Security')
  })

  it('settings-panel-004: disables a pane and prevents selection', () => {
    render(<CompoundExample />)
    const securityRow = screen.getByRole('tab', { name: 'Security' })
    expect(securityRow).toBeDisabled()
    fireEvent.click(securityRow)
    expect(screen.queryByText('security body')).not.toBeInTheDocument()
  })

  it('settings-panel-005: respects controlled selectedId and calls onSelect on click', () => {
    const onSelect = vi.fn()
    render(<CompoundExample selectedId="notifications" onSelect={onSelect} />)
    expect(screen.getByText('notifications body')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('tab', { name: 'General' }))
    expect(onSelect).toHaveBeenCalledWith('general')
    // Still shows notifications since parent never updated.
    expect(screen.getByText('notifications body')).toBeInTheDocument()
  })

  it('settings-panel-006: persists selection to localStorage when persistKey is set', () => {
    const { unmount } = render(<CompoundExample persistKey="t1" />)
    fireEvent.click(screen.getByRole('tab', { name: 'Notifications' }))
    expect(window.localStorage.getItem('aws-settings:t1')).toBe('notifications')
    unmount()
    render(<CompoundExample persistKey="t1" />)
    expect(screen.getByText('notifications body')).toBeInTheDocument()
  })

  it('settings-panel-007: renders panes via the data-driven API', () => {
    render(
      <SettingsPanel
        sidebarTitle="Account"
        panes={[
          { id: 'a', title: 'A', body: <div>body a</div> },
          { id: 'b', title: 'B', body: <div>body b</div> },
        ]}
      />,
    )
    expect(screen.getByText('body a')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('tab', { name: 'B' }))
    expect(screen.getByText('body b')).toBeInTheDocument()
  })

  it('settings-panel-008: uncontrolled mode tracks internal selection across clicks', () => {
    function Host() {
      const [, setHistory] = useState<string[]>([])
      return (
        <SettingsPanel onSelect={(id) => setHistory((h) => [...h, id])}>
          <SettingsPanel.Sidebar />
          <SettingsPanel.Pane id="x" title="X"><div>x body</div></SettingsPanel.Pane>
          <SettingsPanel.Pane id="y" title="Y"><div>y body</div></SettingsPanel.Pane>
        </SettingsPanel>
      )
    }
    render(<Host />)
    fireEvent.click(screen.getByRole('tab', { name: 'Y' }))
    expect(screen.getByText('y body')).toBeInTheDocument()
  })
})

describe('SettingsPanel conformance vectors (continued)', () => {
  beforeEach(() => {
    resetStorage()
    vi.restoreAllMocks()
  })

  it('settings-panel-009: Pane outside a panel throws the context error', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
    expect(() =>
      render(
        <SettingsPanel.Pane id="a" title="A">
          <div>a</div>
        </SettingsPanel.Pane>,
      ),
    ).toThrow('SettingsPanel subcomponents must be rendered inside <SettingsPanel>')
    spy.mockRestore()
  })

  it('settings-panel-010: data mode ignores children', () => {
    render(
      <SettingsPanel panes={[{ id: 'a', title: 'A', body: <div>body a</div> }]}>
        <div>child text</div>
      </SettingsPanel>,
    )
    expect(screen.queryByText('child text')).not.toBeInTheDocument()
    expect(screen.getByText('body a')).toBeInTheDocument()
  })

  it('settings-panel-011: auto-select notifies once in controlled mode and does not persist', () => {
    const onSelect = vi.fn()
    render(
      <SettingsPanel
        selectedId="gone"
        persistKey="t2"
        onSelect={onSelect}
        panes={[
          { id: 'A', title: 'A', body: <div>body a</div> },
          { id: 'B', title: 'B', body: <div>body b</div> },
        ]}
      />,
    )
    expect(onSelect).toHaveBeenCalledTimes(1)
    expect(onSelect).toHaveBeenCalledWith('A')
    expect(window.localStorage.getItem('aws-settings:t2')).toBeNull()
  })

  it('settings-panel-012: nothing is selected when every pane is disabled', () => {
    const onSelect = vi.fn()
    render(
      <SettingsPanel
        onSelect={onSelect}
        panes={[
          { id: 'A', title: 'A', isDisabled: true, body: <div>body a</div> },
          { id: 'B', title: 'B', isDisabled: true, body: <div>body b</div> },
        ]}
      />,
    )
    expect(screen.queryByText('body a')).not.toBeInTheDocument()
    expect(screen.queryByText('body b')).not.toBeInTheDocument()
    expect(onSelect).not.toHaveBeenCalled()
  })

  it('settings-panel-013: storage read and write failures are swallowed', () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new Error('denied')
    })
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new Error('denied')
    })
    render(
      <SettingsPanel
        persistKey="t3"
        defaultPaneId="b"
        panes={[
          { id: 'a', title: 'A', body: <div>body a</div> },
          { id: 'b', title: 'B', body: <div>body b</div> },
        ]}
      />,
    )
    expect(screen.getByText('body b')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('tab', { name: 'A' }))
    expect(screen.getByText('body a')).toBeInTheDocument()
  })

  it('settings-panel-014: controlled mode writes persistence but keeps the selection', () => {
    render(
      <SettingsPanel
        selectedId="a"
        persistKey="t4"
        panes={[
          { id: 'a', title: 'A', body: <div>body a</div> },
          { id: 'b', title: 'B', body: <div>body b</div> },
        ]}
      />,
    )
    fireEvent.click(screen.getByRole('tab', { name: 'B' }))
    expect(window.localStorage.getItem('aws-settings:t4')).toBe('b')
    expect(screen.getByText('body a')).toBeInTheDocument()
    expect(screen.queryByText('body b')).not.toBeInTheDocument()
  })

  it('settings-panel-015: Sidebar title wins over sidebarTitle; no heading when neither is given', () => {
    const first = render(
      <SettingsPanel sidebarTitle="Global">
        <SettingsPanel.Sidebar title="Local" />
        <SettingsPanel.Pane id="a" title="A">
          <div>a</div>
        </SettingsPanel.Pane>
      </SettingsPanel>,
    )
    const headings = first.container.querySelectorAll('h2')
    expect(headings).toHaveLength(1)
    expect(headings[0].textContent).toBe('Local')
    expect(headings[0].className).toBe('aws-panel__sidebar-title')
    first.unmount()

    const second = render(
      <SettingsPanel>
        <SettingsPanel.Sidebar />
        <SettingsPanel.Pane id="a" title="A">
          <div>a</div>
        </SettingsPanel.Pane>
      </SettingsPanel>,
    )
    expect(second.container.querySelectorAll('h2')).toHaveLength(0)
  })

  it('settings-panel-016: the icon span renders only for a pane with an icon', () => {
    render(
      <SettingsPanel>
        <SettingsPanel.Sidebar />
        <SettingsPanel.Pane id="a" title="A" icon={<i>*</i>}>
          <div>a</div>
        </SettingsPanel.Pane>
        <SettingsPanel.Pane id="b" title="B">
          <div>b</div>
        </SettingsPanel.Pane>
      </SettingsPanel>,
    )
    const tabs = screen.getAllByRole('tab')
    const rowA = tabs.find((t) => t.textContent?.includes('A'))!
    const rowB = tabs.find((t) => t.textContent === 'B')!
    expect(rowA.querySelector('span.aws-panel__sidebar-icon')).not.toBeNull()
    expect(rowB.querySelector('span.aws-panel__sidebar-icon')).toBeNull()
    expect(rowB.querySelector('span.aws-panel__sidebar-label')?.textContent).toBe('B')
  })

  it('settings-panel-017: changing a title re-registers the pane at the end of the list', () => {
    function Host({ pTitle }: { pTitle: string }) {
      return (
        <SettingsPanel>
          <SettingsPanel.Sidebar />
          <SettingsPanel.Pane id="p" title={pTitle}><div>p</div></SettingsPanel.Pane>
          <SettingsPanel.Pane id="q" title="Q"><div>q</div></SettingsPanel.Pane>
          <SettingsPanel.Pane id="r" title="R"><div>r</div></SettingsPanel.Pane>
        </SettingsPanel>
      )
    }
    const { rerender } = render(<Host pTitle="P" />)
    const order = () => screen.getAllByRole('tab').map((t) => t.textContent)
    expect(order()).toEqual(['P', 'Q', 'R'])
    rerender(<Host pTitle="P2" />)
    expect(order()).toEqual(['Q', 'R', 'P2'])
  })

  it('settings-panel-018: auto-select does not repeat for the same id across renders', () => {
    const onSelect = vi.fn()
    const panes = [
      { id: 'A', title: 'A', body: <div>body a</div> },
      { id: 'B', title: 'B', body: <div>body b</div> },
    ]
    const ui = <SettingsPanel selectedId="gone" onSelect={onSelect} panes={panes} />
    const { rerender } = render(ui)
    rerender(ui)
    rerender(ui)
    expect(onSelect).toHaveBeenCalledTimes(1)
  })
})
