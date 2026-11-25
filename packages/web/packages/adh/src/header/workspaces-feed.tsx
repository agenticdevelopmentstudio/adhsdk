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
  useLayoutEffect,
  useMemo,
  useRef,
  type ReactNode,
} from 'react'
import { usePathname, useRouter } from 'next/navigation'
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
 * The provider keeps what is registered in a REF, never in state: nothing renders from it. The
 * menu's `select` is one stable function that, at pick time, calls whichever switch is registered
 * then, else follows `/<slug>`. So a registration re-renders nothing — not the app root, not a menu
 * consumer — however often the route hands up a new `select` (one per in-workspace navigation; it
 * closes over the pathname).
 *
 * The one effect here is a deliberate exception to the rule "Never use `useEffect` to sync state —
 * derive it instead", and it syncs no state. The switch is a CALLBACK owned by a component below
 * the provider; the provider cannot derive it, only be handed it, and handing a child's value to an
 * ancestor without a render-time side effect takes an effect. It writes a ref and sets no state. A
 * layout effect, so a render React discards never leaves its switch behind, and so the latest
 * switch is in place before paint, ahead of any click.
 */
export function useRegisterWorkspaceSelect(select: (slug: string) => void): void {
  const register = useContext(WorkspaceSelectRegistrar)
  useLayoutEffect(() => {
    register(select)
    return () => register(null)
  }, [register, select])
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
   *   switch a mounted workspace route registered at pick time ({@link useRegisterWorkspaceSelect}),
   *   else follows `/<slug>`; and the menu shows on the hub's workspace routes only.
   */
  switchBy?: 'preference' | 'route'
}

/**
 * Fills the shared header's workspace menu with the signed-in user's workspaces, PRE-RESOLVED into
 * {@link MenuWorkspace} rows so the menu itself stays data-free. Mounting it is a site's opt-in to
 * the header workspace menu (see `SiteMenuSwitcher`).
 *
 * Gated on sign-in by the stored token's subject ({@link useTokenSubject}), so it works under any
 * host's auth context: signed out, no request fires and `loading`/`error` read false. In
 * `'preference'` mode it asks for the swap (`everyRoute`) only while that same signal says signed
 * in, so the menu and its feed never disagree about the visitor.
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
  //
  // `everyRoute` only while THIS feed counts the visitor as signed in. SiteMenuSwitcher swaps on the
  // host's `authenticated`; the feed loads on the stored token's subject. Asking for the swap only
  // when the token says signed in makes the menu need BOTH, so a host whose auth says signed in while
  // the token store has no subject keeps its site menu rather than an empty "No workspaces yet"
  // menu for an account that has workspaces.
  const value = useMemo<WorkspacesMenu>(
    () => ({
      workspaces: feed.workspaces,
      loading: signedIn && isLoading,
      error: signedIn && isError,
      select: feed.select,
      // A preference pick records and stays put, so the menu asks no leave-this-page question.
      selectStaysOnPage: byRoute ? undefined : true,
      everyRoute: !byRoute && signedIn ? true : undefined,
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
  // A ref, not state: nothing renders from it (see useRegisterWorkspaceSelect). Read at pick time.
  // Off a workspace route nothing is registered and a pick follows `/<slug>`, which loses only the
  // feature you were on — and off a workspace route there is none.
  const router = useRouter()
  const routeSelect = useRef<((slug: string) => void) | null>(null)
  const register = useCallback<RegisterWorkspaceSelect>((fn) => {
    routeSelect.current = fn
  }, [])
  const select = useMemo(() => {
    const slugById = new Map(reachable.map((w) => [workspaceCompositeId(w), w.slug]))
    return (w: MenuWorkspace) => {
      const slug = slugById.get(w.id)
      if (!slug) return
      if (routeSelect.current) routeSelect.current(slug)
      else router.push(`/${slug}`)
    }
  }, [reachable, router])
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
