'use client'

// The header workspace menu's FEED — the shared provider that fills `WorkspacesMenuProvider` with
// the signed-in user's workspaces. Moved from the hub (`HubWorkspacesMenuProvider`) so the hub and
// any satellite that opts in run on one copy.
//
// ITS OWN ENTRY (`@adh-sdk/adh/header/workspaces-feed`), not a member of the header barrel, for
// `header-auth`'s reason: this is a header module that value-imports `@adh-sdk/data` (and through
// it react-query and `@adh-sdk/auth`), and a site that renders a nav link should not pull the data
// layer in behind it. It reaches the menu context by the PACKAGE PATH `@adh-sdk/adh/header`
// (external in tsup), so the context this fills is the one SiteMenuSwitcher reads. The registrar
// context below lives in this entry only; nothing may reach this module by a relative specifier.

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import { usePathname } from 'next/navigation'
import { useTokenSubject } from '@adh-sdk/auth/client'
import {
  firstWorkspacePerSlug,
  useWorkspacePreference,
  useWorkspaces,
  workspaceCompositeId,
  workspaceListLabel,
  type WorkspaceRow,
} from '@adh-sdk/data'
import { siteUrl, siteProdUrl } from '@adh-sdk/adh-registry'
import {
  WorkspacesMenuProvider,
  useClientHost,
  type MenuWorkspace,
  type WorkspacesMenu,
} from '@adh-sdk/adh/header'

/** Hands the provider the switch a mounted workspace route performs (or null when it unmounts). */
export type RegisterWorkspaceSelect = (select: ((slug: string) => void) | null) => void

/** Exported for tests, which capture the registered switch without the whole provider. Filled by
 *  {@link SiteWorkspacesMenuProvider} in `switchBy="route"`; a no-op anywhere else. */
export const WorkspaceSelectRegistrar = createContext<RegisterWorkspaceSelect>(() => {})

/**
 * Called by a mounted workspace route (the hub's HubWorkspaceRoute) with its `useWorkspaceRoute`
 * switch, so the header's WorkspaceMenu — which sits above every route, in the root layout —
 * switches exactly as the route would: KEEPING the feature you are on (the route's
 * `switchHrefFor`), where a row's plain `href` lands on the bare workspace.
 *
 * Remembering the pick is not what it adds: the route records ANY fresh arrival on a `/<slug>` it
 * did not seed itself as the preference (teams excepted) — `useWorkspaceRoute`'s documented rule.
 *
 * It registers ONE stable wrapper per mount, which calls whichever `select` the route rendered
 * last. `select` is a new function on every in-workspace navigation (it closes over the pathname),
 * and registering each new one set the provider's state at the app root, re-rendering the root a
 * second time per navigation and handing every menu consumer a new context value. Reading the
 * latest through a ref gives the menu a switch that does what the route would do NOW, with no new
 * identity to pass up.
 */
export function useRegisterWorkspaceSelect(select: (slug: string) => void): void {
  const register = useContext(WorkspaceSelectRegistrar)
  const latest = useRef(select)
  // A layout effect rather than a render-time write: a render React discards must not leave its
  // switch behind for the menu to call, and it runs before paint, so no click lands in between.
  useLayoutEffect(() => {
    latest.current = select
  })
  useEffect(() => {
    register((slug) => latest.current(slug))
    return () => register(null)
  }, [register])
}

export type SiteWorkspacesMenuProviderProps = {
  children: ReactNode
  /**
   * How a pick switches — the one way the hub and a satellite differ, and everything else follows
   * from it:
   *
   * - `'preference'` (default; a satellite, which has no workspace routes): rows are the personal
   *   workspace and the organizations (a team owns nothing and is never a preference); the current
   *   row is the stored family preference, else the personal workspace; a pick RECORDS the
   *   preference (`useWorkspacePreference`) and marks it current, with no navigation; and the menu
   *   shows on every route (`everyRoute`). A row's `href` opens that workspace on the hub, for
   *   open-in-new-tab.
   * - `'route'` (the hub): every row the URL can reach, teams included, one per slug; the current
   *   row is the one whose slug is the URL's first segment, else none; a pick goes through the
   *   switch a mounted workspace route registered ({@link useRegisterWorkspaceSelect}), else
   *   follows `/<slug>`; and the menu shows on the hub's workspace routes only.
   */
  switchBy?: 'preference' | 'route'
}

/**
 * Fills the shared header's workspace menu with the signed-in user's workspaces, PRE-RESOLVED into
 * {@link MenuWorkspace} rows so the menu itself stays data-free. Mounting it is a site's opt-in to
 * the header workspace menu (see `SiteMenuSwitcher`).
 *
 * Gated on sign-in by the stored token's subject ({@link useTokenSubject}), so it works under any
 * host's auth context: signed out, no request fires and `loading`/`error` read false.
 */
export function SiteWorkspacesMenuProvider({
  children,
  switchBy = 'preference',
}: SiteWorkspacesMenuProviderProps): ReactNode {
  const signedIn = useTokenSubject() != null
  const { data, isLoading, isError } = useWorkspaces({ enabled: signedIn })
  const byRoute = switchBy === 'route'
  const route = useRouteSwitch(byRoute ? data : undefined)
  const pref = usePreferenceSwitch(byRoute ? undefined : data, signedIn && !byRoute)
  const feed = byRoute ? route : pref

  // `error`, so a list that failed to load reads as one rather than "No workspaces yet". Gated on
  // sign-in like `loading`: signed out the query is disabled, and what it still holds is not this
  // visitor's.
  const value = useMemo<WorkspacesMenu>(
    () => ({
      workspaces: feed.workspaces,
      loading: signedIn && isLoading,
      error: signedIn && isError,
      select: feed.select,
      everyRoute: byRoute ? undefined : true,
    }),
    [feed.workspaces, feed.select, signedIn, isLoading, isError, byRoute],
  )

  const menu = <WorkspacesMenuProvider value={value}>{children}</WorkspacesMenuProvider>
  return byRoute ? (
    <WorkspaceSelectRegistrar.Provider value={route.register}>{menu}</WorkspaceSelectRegistrar.Provider>
  ) : (
    menu
  )
}

type Feed = { workspaces: MenuWorkspace[]; select?: (workspace: MenuWorkspace) => void }

const NO_ROWS: WorkspaceRow[] = []

/** The hub's feed: URL-reachable rows, current by the URL, the registered route switch. */
function useRouteSwitch(data: WorkspaceRow[] | undefined): Feed & { register: RegisterWorkspaceSelect } {
  const pathname = usePathname() ?? '/'
  const rows = data ?? NO_ROWS
  // Membership is the discriminator: the workspace route is the BARE `/<slug>`, the same shape as
  // `/login`, so the first segment is a workspace exactly when a row carries it. No fallback: off a
  // workspace route no row is current, and the trigger reads "Workspaces", which is true there.
  const [firstSeg] = pathname.split('/').filter(Boolean)
  const activeSlug = rows.some((w) => w.slug === firstSeg) ? firstSeg : undefined
  // One row per slug: a bare `/<slug>` opens only the first (see firstWorkspacePerSlug).
  const reachable = useMemo(() => firstWorkspacePerSlug(rows), [rows])
  const workspaces = useMemo<MenuWorkspace[]>(
    () =>
      reachable.map((w) => ({
        id: workspaceCompositeId(w),
        label: workspaceListLabel(w),
        href: `/${w.slug}`,
        current: w.slug === activeSlug,
      })),
    [reachable, activeSlug],
  )
  // State, because it changes only when a route mounts or unmounts (one stable wrapper per mount).
  // Off a workspace route nothing registers and the menu follows each row's `href`, which loses
  // only the feature you were on — and off a workspace route there is none.
  const [routeSelect, setRouteSelect] = useState<((slug: string) => void) | null>(null)
  const register = useCallback<RegisterWorkspaceSelect>((fn) => setRouteSelect(() => fn), [])
  const select = useMemo(() => {
    if (!routeSelect) return undefined
    const slugById = new Map(reachable.map((w) => [workspaceCompositeId(w), w.slug]))
    return (w: MenuWorkspace) => {
      const slug = slugById.get(w.id)
      if (slug) routeSelect(slug)
    }
  }, [routeSelect, reachable])
  return { workspaces, select, register }
}

/** A satellite's feed: personal + orgs, current by the stored preference, a pick records it. */
function usePreferenceSwitch(data: WorkspaceRow[] | undefined, enabled: boolean): Feed {
  const host = useClientHost()
  const { slug: preferred, choose } = useWorkspacePreference({ enabled })
  const owners = useMemo(
    () => firstWorkspacePerSlug((data ?? NO_ROWS).filter((w) => w.type !== 'team')),
    [data],
  )
  // A stored slug that is not one of the caller's rows (a previous user's, an org since left) is
  // inert: the personal workspace stands in, as it does for a caller who has never chosen.
  const currentSlug = owners.some((w) => w.slug === preferred)
    ? preferred
    : owners.find((w) => w.type === 'individual')?.slug
  const workspaces = useMemo<MenuWorkspace[]>(
    () =>
      owners.map((w) => {
        const path = `/${w.slug}`
        return {
          id: workspaceCompositeId(w),
          label: workspaceListLabel(w),
          href: host ? siteUrl('hub', path, host) : siteProdUrl('hub', path),
          current: w.slug === currentSlug,
        }
      }),
    [owners, currentSlug, host],
  )
  const select = useMemo(() => {
    const slugById = new Map(owners.map((w) => [workspaceCompositeId(w), w.slug]))
    return (w: MenuWorkspace) => {
      const slug = slugById.get(w.id)
      if (slug) choose(slug)
    }
  }, [owners, choose])
  return { workspaces, select }
}
