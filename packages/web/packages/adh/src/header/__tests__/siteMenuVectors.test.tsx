/** The site-menu recipe's integration vectors T1-T12 that render the menu, through the real
 *  popover. T9 and T11 (the recents store) are in recents.test.ts; T8 is skipped here. */
/// <reference types="@testing-library/jest-dom/vitest" />
import { render, screen, fireEvent, waitFor, cleanup } from '@testing-library/react'
import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { ScrollText, Users } from 'lucide-react'

const push = vi.fn()
vi.mock('next/navigation', () => ({
  usePathname: () => '/',
  useRouter: () => ({ push }),
}))

import { SiteMenu, WorkspacesMenuProvider, type WorkspacesMenu } from '@adh-sdk/adh/header'
import { MarketingSiteMenu } from '../MarketingSiteMenu'
import { WorkspaceSiteMenu } from '../WorkspaceSiteMenu'
import { clearRecents, recordRecent } from '../recents'
import { MENU_ICONS, menuIcon } from '../menu-icons'

// jsdom has no layout, so no scrollIntoView; the popover calls it on a keyboard highlight.
Element.prototype.scrollIntoView = vi.fn()

beforeEach(() => {
  localStorage.clear()
  clearRecents()
  push.mockClear()
})
afterEach(cleanup)

const TRIGGER = /switch site$/

async function openMenu(): Promise<void> {
  fireEvent.click(screen.getByRole('button', { name: TRIGGER }))
  await waitFor(() => expect(screen.getByRole('menu')).toBeInTheDocument())
}

function rowNames(): string[] {
  return screen.getAllByRole('menuitem').map((el) => (el.textContent ?? '').trim())
}

const THREE_WORKSPACES: WorkspacesMenu = {
  loading: false,
  workspaces: [
    { id: 'individual:mine', label: 'Mike Fullerton', href: '/mine', current: true },
    { id: 'org:acme', label: 'Acme', href: '/acme', current: false },
    { id: 'org:globex', label: 'Globex', href: '/globex', current: false },
  ],
}

function renderWorkspaceSignedIn(menu: WorkspacesMenu | null = THREE_WORKSPACES): void {
  const ui = <WorkspaceSiteMenu currentSiteId="hub" authenticated />
  render(menu ? <WorkspacesMenuProvider value={menu}>{ui}</WorkspacesMenuProvider> : ui)
}

describe('site menu integration vectors', () => {
  it('T1: marketing and workspace menus share the SiteMenu base and neither has a Reference row', async () => {
    render(<MarketingSiteMenu currentSiteId="hub" />)
    await openMenu()
    const marketing = rowNames()
    expect(marketing.some((n) => /^Bitbag/.test(n))).toBe(true)
    expect(marketing.some((n) => /^Hub/.test(n))).toBe(true)
    expect(marketing.some((n) => /^Reference/.test(n))).toBe(false)
    cleanup()
    render(<WorkspaceSiteMenu currentSiteId="hub" />)
    await openMenu()
    const workspace = rowNames()
    expect(workspace.some((n) => /^Bitbag/.test(n))).toBe(true)
    expect(workspace.some((n) => /^Hub/.test(n))).toBe(true)
    expect(workspace.some((n) => /^Reference/.test(n))).toBe(false)
  })

  it('T2: signed out, Login and Sign up lead the menu and Home and Recents are absent', async () => {
    recordRecent({ url: '/acme/research', label: 'Research' })
    render(
      <WorkspaceSiteMenu
        currentSiteId="hub"
        loginHref="https://hub.test/login"
        signupHref="https://hub.test/signup"
      />,
    )
    await openMenu()
    const names = rowNames()
    expect(names[0]).toBe('Login')
    expect(names[1]).toBe('Sign up')
    expect(names.indexOf('Login')).toBeLessThan(names.findIndex((n) => /^Bitbag/.test(n)))
    expect(screen.queryByRole('menuitem', { name: /^Home/ })).toBeNull()
    expect(screen.queryByRole('menuitem', { name: /^Recents/ })).toBeNull()
  })

  it('T3: signed in shows Home, Workspaces and Recents; the family rows do not change with auth', async () => {
    recordRecent({ url: '/acme/research', label: 'Research' })
    renderWorkspaceSignedIn()
    await openMenu()
    const signedIn = rowNames()
    expect(signedIn.some((n) => /^Home/.test(n))).toBe(true)
    expect(signedIn.some((n) => /^Workspaces/.test(n))).toBe(true)
    expect(signedIn.some((n) => /^Recents/.test(n))).toBe(true)
    cleanup()
    render(<WorkspaceSiteMenu currentSiteId="hub" />)
    await openMenu()
    const signedOut = rowNames()
    for (const chrome of [/^Home/, /^Workspaces/, /^Recents/])
      expect(signedOut.some((n) => chrome.test(n))).toBe(false)
    const family = (names: string[]) => names.filter((n) => !/^(Home|Workspaces|Recents)/.test(n))
    // Signed in adds only the chrome rows; every family row is the same in both.
    expect(family(signedIn)).toEqual(family(signedOut))
  })

  it('T4: an inline row renders indented under its parent and is always visible', async () => {
    render(
      <SiteMenu
        currentSiteId="hub"
        groups={[
          { kind: 'leaf', section: 1, link: { site: 'hub' } },
          { kind: 'inline', section: 1, link: { site: 'bitbag' } },
          { kind: 'leaf', section: 1, link: { site: 'cookbook' } },
        ]}
      />,
    )
    await openMenu()
    const rows = screen.getAllByRole('menuitem')
    const hub = rows.findIndex((r) => /^Hub/.test(r.textContent ?? ''))
    const bitbag = rows.findIndex((r) => /^Bitbag/i.test(r.textContent ?? ''))
    expect(bitbag).toBe(hub + 1)
    expect(rows[bitbag]).toHaveClass('adh-nav-popover__item--indent')
    expect(rows[hub]).not.toHaveClass('adh-nav-popover__item--indent')
    expect(rows[bitbag]).toHaveAttribute('href')
  })

  it('T5: a row draws its icon before its label, from the menu-icons map', async () => {
    render(<MarketingSiteMenu currentSiteId="hub" />)
    await openMenu()
    const bitbag = screen.getAllByRole('menuitem').find((r) => /^Bitbag/i.test(r.textContent ?? ''))!
    const icon = bitbag.querySelector('svg')
    expect(icon).not.toBeNull()
    const label = [...bitbag.querySelectorAll('*')].find((el) => /^Bitbag/i.test(el.textContent ?? '') && el.children.length === 0)!
    expect(icon!.compareDocumentPosition(label) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
    expect(menuIcon('community')).toBe(Users)
    expect(menuIcon('narratives')).toBe(ScrollText)
    expect(MENU_ICONS.community).toBe(Users)
    expect(MENU_ICONS.narratives).toBe(ScrollText)
  })

  it('T6: the Workspaces flyout lists every workspace, each linking to its home', async () => {
    renderWorkspaceSignedIn()
    await openMenu()
    const row = screen.getByRole('menuitem', { name: 'Workspaces' })
    fireEvent.mouseMove(row)
    await waitFor(() => expect(screen.getByText('Acme')).toBeInTheDocument())
    for (const [label, href] of [
      ['Mike Fullerton', '/mine'],
      ['Acme', '/acme'],
      ['Globex', '/globex'],
    ] as const)
      expect(screen.getByText(label).closest('[href]')).toHaveAttribute('href', href)
  })

  it('T7: Recents is hidden with none recorded, and lists the recorded places newest-first', async () => {
    renderWorkspaceSignedIn(null)
    await openMenu()
    expect(screen.queryByRole('menuitem', { name: /^Recents/ })).toBeNull()
    cleanup()
    recordRecent({ url: '/acme/one', label: 'One' })
    recordRecent({ url: '/acme/two', label: 'Two' })
    recordRecent({ url: '/acme/three', label: 'Three' })
    renderWorkspaceSignedIn(null)
    await openMenu()
    fireEvent.mouseMove(screen.getByRole('menuitem', { name: /^Recents/ }))
    await waitFor(() => expect(screen.getByText('Three')).toBeInTheDocument())
    const labels = ['One', 'Two', 'Three'].map((l) => screen.getByText(l))
    const order = [...document.querySelectorAll('[role="menuitem"]')].map((el) => el.textContent ?? '')
    const idx = (l: string) => order.findIndex((t) => t.startsWith(l))
    expect(labels).toHaveLength(3)
    expect(idx('Three')).toBeLessThan(idx('Two'))
    expect(idx('Two')).toBeLessThan(idx('One'))
  })

  // The settle-debounced recorder is the hub app's (it watches the hub's selection); this
  // package holds only the store it writes to, so the debounce cannot be driven from here.
  it.skip('T8: only the settled leaf is recorded after a list to detail to leaf drill', () => {})

  it('T10: choosing a recent navigates to its deep URL', async () => {
    recordRecent({ url: '/acme/research', label: 'Research' })
    renderWorkspaceSignedIn(null)
    await openMenu()
    fireEvent.mouseMove(screen.getByRole('menuitem', { name: /^Recents/ }))
    await waitFor(() => expect(screen.getByText('Research')).toBeInTheDocument())
    const row = screen.getByText('Research').closest('[role="menuitem"]') as HTMLElement
    expect(row).toHaveAttribute('href', '/acme/research')
    fireEvent.click(row)
    await waitFor(() => expect(push).toHaveBeenCalledWith('/acme/research'))
  })

  it('T12: the keyboard opens the menu, moves the selection, opens and closes a flyout, and Escape returns focus', async () => {
    renderWorkspaceSignedIn()
    const trigger = screen.getByRole('button', { name: TRIGGER })
    trigger.focus()
    fireEvent.click(trigger)
    await waitFor(() => expect(screen.getByRole('menu')).toBeInTheDocument())
    const input = screen.getByRole('combobox')
    // Arrow down onto the first row, then the next: the active row moves.
    fireEvent.keyDown(input, { key: 'ArrowDown' })
    const active = () => document.querySelector('.adh-nav-popover__item--active')
    const first = active()
    expect(first).not.toBeNull()
    fireEvent.keyDown(input, { key: 'ArrowDown' })
    expect(active()).not.toBe(first)
    // Walk to the Workspaces row and disclose it with the right arrow, close it with the left.
    for (let i = 0; i < 40 && !/^Workspaces/.test(active()?.textContent ?? ''); i++)
      fireEvent.keyDown(input, { key: 'ArrowDown' })
    expect(active()?.textContent).toMatch(/^Workspaces/)
    fireEvent.keyDown(input, { key: 'ArrowRight' })
    await waitFor(() => expect(screen.getByText('Acme')).toBeInTheDocument())
    fireEvent.keyDown(input, { key: 'ArrowLeft' })
    await waitFor(() => expect(screen.queryByText('Acme')).toBeNull())
    fireEvent.keyDown(input, { key: 'Escape' })
    await waitFor(() => expect(screen.queryByRole('menu')).toBeNull())
    await waitFor(() => expect(trigger).toHaveFocus())
  })
})
