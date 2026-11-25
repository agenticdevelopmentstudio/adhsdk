// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest'
import { render, cleanup, screen } from '@testing-library/react'

// A satellite opts in to the header workspace menu by mounting a provider whose value says
// `everyRoute`. The menus are stubbed to their names: what the dispatcher owes is the CHOICE.

const route = { pathname: '/' }
vi.mock('next/navigation', () => ({ usePathname: () => route.pathname }))

const workspaces = { current: null as object | null }
vi.mock('@adh-sdk/adh/header', () => ({ useWorkspacesMenu: () => workspaces.current }))
vi.mock('../WorkspaceMenu', () => ({ WorkspaceMenu: () => <div>workspace menu</div> }))
vi.mock('../WorkspaceSiteMenu', () => ({ WorkspaceSiteMenu: () => <div>workspace site menu</div> }))
vi.mock('../MarketingSiteMenu', () => ({ MarketingSiteMenu: () => <div>marketing site menu</div> }))
vi.mock('../PrefetchSiblingSites', () => ({ PrefetchSiblingSites: () => null }))

import { SiteMenuSwitcher } from '../SiteMenuSwitcher'

afterEach(() => {
  cleanup()
  workspaces.current = null
})

describe('SiteMenuSwitcher opt-in', () => {
  it('shows the workspace menu on every route of a satellite whose provider says everyRoute', () => {
    workspaces.current = { workspaces: [], loading: false, everyRoute: true }
    for (const path of ['/', '/home', '/about']) {
      route.pathname = path
      render(<SiteMenuSwitcher currentSiteId="myagenticdevteam" authenticated />)
      expect(screen.getByText('workspace menu')).toBeTruthy()
      cleanup()
    }
  })

  it('keeps the site menu on an opted-in satellite when signed out', () => {
    workspaces.current = { workspaces: [], loading: false, everyRoute: true }
    route.pathname = '/'
    render(<SiteMenuSwitcher currentSiteId="myagenticdevteam" authenticated={false} />)
    expect(screen.queryByText('workspace menu')).toBeNull()
    expect(screen.getByText('marketing site menu')).toBeTruthy()
  })

  it('keeps the site menu on a satellite whose provider does not say everyRoute', () => {
    workspaces.current = { workspaces: [], loading: false }
    route.pathname = '/home'
    render(<SiteMenuSwitcher currentSiteId="myagenticdevteam" authenticated />)
    expect(screen.queryByText('workspace menu')).toBeNull()
  })

  it('keeps the hub rule for a provider without everyRoute: workspace routes only', () => {
    workspaces.current = { workspaces: [], loading: false }
    route.pathname = '/'
    render(<SiteMenuSwitcher currentSiteId="hub" authenticated />)
    expect(screen.queryByText('workspace menu')).toBeNull()
    cleanup()
    route.pathname = '/home'
    render(<SiteMenuSwitcher currentSiteId="hub" authenticated />)
    expect(screen.getByText('workspace menu')).toBeTruthy()
  })
})
