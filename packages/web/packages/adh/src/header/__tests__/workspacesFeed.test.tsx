// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest'
import { render, cleanup, act } from '@testing-library/react'
import { useContext, useEffect } from 'react'

// The shared workspace-menu feed: what it hands the header menu in each switch mode, and the
// sign-in gate. The data layer is stubbed at its hooks — the feed's job is the mapping.

const route = { pathname: '/' }
const push = vi.fn()
const router = { push }
vi.mock('next/navigation', () => ({ usePathname: () => route.pathname, useRouter: () => router }))

const subject = { current: null as string | null }
vi.mock('@adh-sdk/auth/client', () => ({ useTokenSubject: () => subject.current }))

const rows = [
  { slug: 'me', name: 'Me', type: 'individual' },
  { slug: 'acme', name: 'Acme', type: 'organization' },
  { slug: 'crew', name: 'Crew', type: 'team' },
]
const useWorkspaces = vi.fn()
const choose = vi.fn()
const preference = { slug: null as string | null }
vi.mock('@adh-sdk/data', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@adh-sdk/data')>()
  return {
    ...actual,
    useWorkspaces: (opts: { enabled?: boolean }) => useWorkspaces(opts),
    useWorkspacePreference: () => ({ slug: preference.slug, settled: true, choose }),
  }
})

const seen = { current: null as unknown }
vi.mock('@adh-sdk/adh/header', async () => {
  const { createContext } = await import('react')
  const Ctx = createContext<unknown>(null)
  return {
    WorkspacesMenuProvider: ({ value, children }: { value: unknown; children: unknown }) => {
      seen.current = value
      return <Ctx.Provider value={value}>{children as never}</Ctx.Provider>
    },
    useClientHost: () => 'localhost:3000',
  }
})

import {
  SiteWorkspacesMenuProvider,
  WorkspaceSelectRegistrar,
  useRegisterWorkspaceSelect,
} from '../workspaces-feed'

type Menu = {
  workspaces: { id: string; label: string; href: string; current: boolean }[]
  loading?: boolean
  error?: boolean
  select?: (w: { id: string }) => void
  everyRoute?: boolean
}
const menu = () => seen.current as Menu

beforeEach(() => {
  subject.current = 'user-1'
  preference.slug = null
  route.pathname = '/'
  useWorkspaces.mockReturnValue({ data: rows, isLoading: false, isError: false })
})
afterEach(() => {
  cleanup()
  choose.mockReset()
  push.mockReset()
  useWorkspaces.mockReset()
  seen.current = null
})

describe('SiteWorkspacesMenuProvider (preference, a satellite)', () => {
  it('lists the personal workspace and the organizations, never a team, on every route', () => {
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.map((w) => w.id)).toEqual(['individual:me', 'organization:acme'])
    expect(menu().everyRoute).toBe(true)
  })

  it('marks the stored preference current, else the personal workspace', () => {
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.find((w) => w.current)?.id).toBe('individual:me')
    cleanup()
    preference.slug = 'acme'
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.find((w) => w.current)?.id).toBe('organization:acme')
    cleanup()
    preference.slug = 'gone'
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.find((w) => w.current)?.id).toBe('individual:me')
  })

  it('a pick records the preference and does not navigate', () => {
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    act(() => menu().select!({ id: 'organization:acme' }))
    expect(choose).toHaveBeenCalledWith('acme')
  })

  it("points each row's href at that workspace on the hub", () => {
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    for (const w of menu().workspaces) expect(w.href).toMatch(/\/(me|acme)$/)
  })

  it('asks for nothing and reports no loading or error signed out', () => {
    subject.current = null
    useWorkspaces.mockReturnValue({ data: undefined, isLoading: true, isError: true })
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(useWorkspaces).toHaveBeenCalledWith({ enabled: false })
    expect(menu().loading).toBe(false)
    expect(menu().error).toBe(false)
  })

  it('does not ask for the header swap while its token signal says signed out', () => {
    // The host's auth may still say signed in; the menu needs both, so no empty "No workspaces yet".
    subject.current = null
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().everyRoute).toBeUndefined()
  })
})

describe('SiteWorkspacesMenuProvider (route, the hub)', () => {
  it('lists every reachable row, teams included, current by the URL, workspace routes only', () => {
    route.pathname = '/acme/research'
    render(<SiteWorkspacesMenuProvider switchBy="route">x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.map((w) => w.href)).toEqual(['/me', '/acme', '/crew'])
    expect(menu().workspaces.find((w) => w.current)?.id).toBe('organization:acme')
    expect(menu().everyRoute).toBeUndefined()
  })

  it('follows /<slug> until a workspace route registers its switch, then routes picks through it', () => {
    const routeSelect = vi.fn()
    function Route() {
      useRegisterWorkspaceSelect(routeSelect)
      return null
    }
    render(<SiteWorkspacesMenuProvider switchBy="route">x</SiteWorkspacesMenuProvider>)
    act(() => menu().select!({ id: 'organization:acme' }))
    expect(push).toHaveBeenCalledWith('/acme')
    cleanup()
    render(
      <SiteWorkspacesMenuProvider switchBy="route">
        <Route />
      </SiteWorkspacesMenuProvider>,
    )
    act(() => menu().select!({ id: 'team:crew' }))
    expect(routeSelect).toHaveBeenCalledWith('crew')
    expect(push).toHaveBeenCalledTimes(1)
  })

  it('hands the menu no new value when a route registers a new switch', () => {
    // The registration lives in a ref: a route handing up a new switch per navigation must not
    // re-render the root or give menu consumers a new context value.
    const first = vi.fn()
    const second = vi.fn()
    function Route({ select }: { select: (slug: string) => void }) {
      useRegisterWorkspaceSelect(select)
      return null
    }
    const { rerender } = render(
      <SiteWorkspacesMenuProvider switchBy="route">
        <Route select={first} />
      </SiteWorkspacesMenuProvider>,
    )
    const before = menu()
    rerender(
      <SiteWorkspacesMenuProvider switchBy="route">
        <Route select={second} />
      </SiteWorkspacesMenuProvider>,
    )
    expect(menu().select).toBe(before.select)
    act(() => menu().select!({ id: 'organization:acme' }))
    expect(second).toHaveBeenCalledWith('acme')
    expect(first).not.toHaveBeenCalled()
  })

  it('provides the registrar only in route mode', () => {
    const got: unknown[] = []
    function Probe() {
      const register = useContext(WorkspaceSelectRegistrar)
      useEffect(() => {
        got.push(register)
      }, [register])
      return null
    }
    render(
      <SiteWorkspacesMenuProvider>
        <Probe />
      </SiteWorkspacesMenuProvider>,
    )
    render(
      <SiteWorkspacesMenuProvider switchBy="route">
        <Probe />
      </SiteWorkspacesMenuProvider>,
    )
    expect(got[0]).not.toBe(got[1])
  })
})
