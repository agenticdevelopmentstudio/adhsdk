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
const preference = { slug: null as string | null, settled: true }
vi.mock('@adh-sdk/data', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@adh-sdk/data')>()
  return {
    ...actual,
    useWorkspaces: (opts: { enabled?: boolean }) => useWorkspaces(opts),
    useWorkspacePreference: () => ({ slug: preference.slug, settled: preference.settled, choose }),
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
  preference.settled = true
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

  it('marks no row current, and reports loading, until the server preference settles', () => {
    // With no cached pick, the personal fallback marked current at once showed the personal
    // workspace and then swapped to the organization the server held.
    preference.settled = false
    const { rerender } = render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.filter((w) => w.current)).toEqual([])
    expect(menu().loading).toBe(true)
    preference.slug = 'acme'
    preference.settled = true
    rerender(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.find((w) => w.current)?.id).toBe('organization:acme')
    expect(menu().loading).toBe(false)
  })

  it('falls back to the personal workspace once the server has no preference for the caller', () => {
    preference.settled = false
    const { rerender } = render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().loading).toBe(true)
    preference.settled = true
    rerender(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.find((w) => w.current)?.id).toBe('individual:me')
    expect(menu().loading).toBe(false)
  })

  it("marks a cached pick that names one of the caller's rows current before the server answers", () => {
    // The browser cache (`adh:home:workspace`) seeds the first paint; it does not wait on the trip.
    preference.slug = 'acme'
    preference.settled = false
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.find((w) => w.current)?.id).toBe('organization:acme')
    expect(menu().loading).toBe(false)
  })

  it('waits for the server when a cached pick names none of the caller rows', () => {
    preference.slug = 'gone'
    preference.settled = false
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.filter((w) => w.current)).toEqual([])
    expect(menu().loading).toBe(true)
  })

  it('reads a failed list as failed while the preference is still in flight', () => {
    // The menu checks `loading` before `error`: a pending preference held the trigger on
    // "Loading…" over a list request that had already failed.
    preference.settled = false
    useWorkspaces.mockReturnValue({ data: undefined, isLoading: false, isError: true })
    render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
    expect(menu()).toMatchObject({ workspaces: [], loading: false, error: true })
  })

  it('lets the personal workspace stand in when the preference read stalls', () => {
    // The account read has no timeout: unbounded, a stalled one held the trigger on "Loading…"
    // with no row current for the life of the page.
    vi.useFakeTimers()
    try {
      preference.settled = false
      render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
      act(() => vi.advanceTimersByTime(2999))
      expect(menu().workspaces.filter((w) => w.current)).toEqual([])
      expect(menu().loading).toBe(true)
      act(() => vi.advanceTimersByTime(1))
      expect(menu().workspaces.find((w) => w.current)?.id).toBe('individual:me')
      expect(menu().loading).toBe(false)
    } finally {
      vi.useRealTimers()
    }
  })

  it('still lets a preference that answers after the stand-in take over', () => {
    vi.useFakeTimers()
    try {
      preference.settled = false
      const { rerender } = render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
      act(() => vi.advanceTimersByTime(3000))
      expect(menu().workspaces.find((w) => w.current)?.id).toBe('individual:me')
      preference.slug = 'acme'
      preference.settled = true
      rerender(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
      expect(menu().workspaces.find((w) => w.current)?.id).toBe('organization:acme')
    } finally {
      vi.useRealTimers()
    }
  })

  it('waits afresh after signing out and back in', () => {
    vi.useFakeTimers()
    try {
      preference.settled = false
      const { rerender } = render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
      act(() => vi.advanceTimersByTime(3000))
      expect(menu().loading).toBe(false)
      subject.current = null
      rerender(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
      subject.current = 'user-1'
      rerender(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
      expect(menu().workspaces.filter((w) => w.current)).toEqual([])
      expect(menu().loading).toBe(true)
    } finally {
      vi.useRealTimers()
    }
  })

  it('waits afresh when the subject switches straight to another user', () => {
    // Another tab signing in as someone else changes the subject with no signed-out render
    // between: the expired wait was user-1's, and user-2's personal row marked current at once
    // brought back the personal-then-organization flash.
    vi.useFakeTimers()
    try {
      preference.settled = false
      const { rerender } = render(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
      act(() => vi.advanceTimersByTime(3000))
      expect(menu().loading).toBe(false)
      subject.current = 'user-2'
      rerender(<SiteWorkspacesMenuProvider>x</SiteWorkspacesMenuProvider>)
      act(() => vi.advanceTimersByTime(2999))
      expect(menu().workspaces.filter((w) => w.current)).toEqual([])
      expect(menu().loading).toBe(true)
      act(() => vi.advanceTimersByTime(1))
      expect(menu().workspaces.find((w) => w.current)?.id).toBe('individual:me')
      expect(menu().loading).toBe(false)
    } finally {
      vi.useRealTimers()
    }
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
    preference.settled = false
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

  // Ported from the hub's HubWorkspacesMenuProvider tests when the hub moved onto this feed.
  //
  // In GET /workspaces order (individual → organization → team). `rocket` is an org and TWO teams:
  // a team's slug is unique only within its owner, so both teams also share the id `team:rocket`.
  const ROCKETS = [
    { slug: 'mine', name: 'Mike Fullerton', type: 'individual' },
    { slug: 'rocket', name: 'Rocket', type: 'organization' },
    { slug: 'temporal', name: 'Temporal', type: 'organization' },
    { slug: 'rocket', name: 'Rocket', type: 'team' },
    { slug: 'rocket', name: 'Rocket', type: 'team' },
  ]

  it('lists each slug once, the row a bare /<slug> opens, and marks only that one current', () => {
    // The hub opens `/rocket` as the FIRST `rocket` row. The two team rows could only ever open the
    // org: marked current by slug they were three highlighted rows, and the two teams were React
    // siblings with one key.
    useWorkspaces.mockReturnValue({ data: ROCKETS, isLoading: false, isError: false })
    route.pathname = '/rocket/teams'
    render(<SiteWorkspacesMenuProvider switchBy="route">x</SiteWorkspacesMenuProvider>)
    const ids = menu().workspaces.map((w) => w.id)
    expect(ids).toEqual(['individual:mine', 'organization:rocket', 'organization:temporal'])
    expect(new Set(ids).size).toBe(ids.length)
    expect(menu().workspaces.filter((w) => w.current).map((w) => w.id)).toEqual([
      'organization:rocket',
    ])
  })

  it('tells the menu a signed-in list failed to load', () => {
    // Handed only `workspaces: []`, the menu drew "No workspaces yet" over a request that never
    // came back.
    useWorkspaces.mockReturnValue({ data: undefined, isLoading: false, isError: true })
    route.pathname = '/settings'
    render(<SiteWorkspacesMenuProvider switchBy="route">x</SiteWorkspacesMenuProvider>)
    expect(menu()).toMatchObject({ workspaces: [], loading: false, error: true })
  })

  it('is not an error while the list loads or once it has', () => {
    useWorkspaces.mockReturnValue({ data: undefined, isLoading: true, isError: false })
    route.pathname = '/settings'
    const { rerender } = render(<SiteWorkspacesMenuProvider switchBy="route">x</SiteWorkspacesMenuProvider>)
    expect(menu()).toMatchObject({ loading: true, error: false })
    useWorkspaces.mockReturnValue({ data: rows, isLoading: false, isError: false })
    rerender(<SiteWorkspacesMenuProvider switchBy="route">x</SiteWorkspacesMenuProvider>)
    expect(menu()).toMatchObject({ loading: false, error: false })
  })

  it('marks NO row current off a workspace route', () => {
    // The trigger reads the current row as its label. Falling back to the user's own slug here made
    // `/settings` claim to be the personal workspace; with nothing current it reads "Workspaces".
    route.pathname = '/settings'
    render(<SiteWorkspacesMenuProvider switchBy="route">x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.filter((w) => w.current)).toEqual([])
  })

  it('lists no Admin row: only the rows the backend returned', () => {
    // Admin work happens only on the admin site now, so the hub lists no Admin row for anyone, not
    // even a viewer holding `admin`, and its old `/admin` path redirects there (the hub's site.json).
    useWorkspaces.mockReturnValue({ data: ROCKETS, isLoading: false, isError: false })
    route.pathname = '/mine'
    render(<SiteWorkspacesMenuProvider switchBy="route">x</SiteWorkspacesMenuProvider>)
    expect(menu().workspaces.map((w) => w.id)).toEqual([
      'individual:mine',
      'organization:rocket',
      'organization:temporal',
    ])
    expect(menu().workspaces.map((w) => w.label)).not.toContain('Admin')
    expect(menu().workspaces.map((w) => w.href)).not.toContain('/admin')
  })

  it('reports loading, never an empty list, while the token has no subject yet', () => {
    // The hub swaps to the workspace menu on its own auth, which can say signed in (a cached user
    // during bootstrap, a silent SSO) before the token store has a subject. The query is disabled
    // then, so its empty, settled result must not reach the menu as "No workspaces yet".
    subject.current = null
    useWorkspaces.mockReturnValue({ data: undefined, isLoading: false, isError: false })
    route.pathname = '/acme'
    render(<SiteWorkspacesMenuProvider switchBy="route">x</SiteWorkspacesMenuProvider>)
    expect(useWorkspaces).toHaveBeenCalledWith({ enabled: false })
    expect(menu()).toMatchObject({ workspaces: [], loading: true, error: false })
    expect(menu().everyRoute).toBeUndefined()
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
