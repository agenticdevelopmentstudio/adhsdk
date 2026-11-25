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
   *   row is the stored family preference, else the personal workspace — that fallback only once
   *   the server's preference has settled (until then `loading`, unless the browser's cached
   *   preference already names a row); a pick RECORDS the
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
 * host's auth context: with no subject, no request fires and `error` reads false. The menu and its
 * feed must never disagree about the visitor, and each mode settles that with this one signal:
 *
 * - `'preference'` asks for the swap (`everyRoute`) only while the token says signed in, so the
 *   menu needs both the host's sign-in and this one; `loading` reads false with no subject.
 * - `'route'` does not ask for the swap: the host swaps on its own `authenticated` on its workspace
 *   routes. So with no subject it reports `loading`, never an empty list. The menu shows only to a
 *   visitor the host counts as signed in, and to that visitor a token with no subject is one that
 *   has not landed yet (the host's cached user during bootstrap or a silent SSO): "Loading…" is
 *   true there, where "No workspaces yet" is a false statement about an account that has some.
 *   Signed out on both sides the menu is not shown, so the `loading` it holds is never read.
 */
export function SiteWorkspacesMenuProvider({
  children,
  switchBy = 'preference',
}: SiteWorkspacesMenuProviderProps): ReactNode {
  const subject = useTokenSubject()
  const signedIn = subject != null
  const { data, isLoading, isError } = useWorkspaces({ enabled: signedIn })
  const byRoute = switchBy === 'route'
  const route = useRouteSwitch(byRoute ? data : undefined)
  const pref = usePreferenceSwitch(byRoute ? undefined : data, signedIn && !byRoute, subject)
  const feed: Feed = byRoute ? route : pref

  // `error`, so a list that failed to load reads as one rather than "No workspaces yet". Gated on
  // sign-in: signed out the query is disabled, and what it still holds is not this visitor's.
  //
  // `everyRoute` only while THIS feed counts the visitor as signed in. SiteMenuSwitcher swaps on the
  // host's `authenticated`; the feed loads on the stored token's subject. Asking for the swap only
  // when the token says signed in makes the menu need BOTH, so a host whose auth says signed in while
  // the token store has no subject keeps its site menu rather than an empty "No workspaces yet"
  // menu for an account that has workspaces.
  //
  // Route mode has no swap to withhold (the hub swaps on its workspace routes, by the host's auth),
  // so it closes the same gap through `loading`: no subject yet reads as the list not being here
  // yet, which is the truth for a visitor the host already counts as signed in. The two signals
  // still never meet in one condition; the menu reads one value either way.
  //
  // Preference mode is also `loading` while its current row waits on the server's preference (see
  // usePreferenceSwitch): no row is current then, and the trigger reads "Loading…" rather than
  // naming the personal workspace it may be about to replace. Never over a failed list that leaves
  // nothing to show, though: the menu checks `loading` before `error`, so a pending preference
  // would hide the failure behind "Loading…" for as long as the preference took. A failed
  // background refetch keeps the rows react-query already held; those rows are listed with none
  // current, so the trigger still reads "Loading…" rather than "Workspaces".
  const prefPending = !byRoute && pref.pending
  const failedEmpty = isError && feed.workspaces.length === 0
  const value = useMemo<WorkspacesMenu>(
    () => ({
      workspaces: feed.workspaces,
      loading: byRoute
        ? !signedIn || isLoading
        : signedIn && !failedEmpty && (isLoading || prefPending),
      error: signedIn && isError,
      select: feed.select,
      // A preference pick records and stays put, so the menu asks no leave-this-page question.
      selectStaysOnPage: byRoute ? undefined : true,
      everyRoute: !byRoute && signedIn ? true : undefined,
    }),
    [feed.workspaces, feed.select, signedIn, isLoading, isError, byRoute, prefPending, failedEmpty],
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

/** How long the satellite feed waits on the server's preference before the personal workspace
 *  stands in: long enough for a healthy account read, short enough that a stalled one is not a
 *  trigger stuck on "Loading…". */
const PREFERENCE_WAIT_MS = 3000

/**
 * A satellite's feed: personal + orgs, current by the stored preference, a pick records it.
 * `pending` while the current row waits on the server's preference: the personal fallback is
 * marked only once that answer is in, or once {@link PREFERENCE_WAIT_MS} has passed without one.
 */
function usePreferenceSwitch(
  data: WorkspaceRow[] | undefined,
  enabled: boolean,
  subject: string | null,
): Feed & { pending: boolean } {
  const host = useClientHost()
  const { slug: preferred, settled, choose } = useWorkspacePreference({ enabled })
  const owners = useMemo(
    () => firstWorkspacePerSlug((data ?? NO_ROWS).filter((w) => w.type !== 'team')),
    [data],
  )
  // A preferred slug that names one of the caller's rows is current at once, even before the
  // server answers: before then it is the browser's cached pick (`adh:home:workspace`), the first
  // paint's fast path. Anything else waits for the server's answer before the personal workspace
  // stands in: marked current straight away, a device with no cached pick showed the personal
  // workspace and then swapped to the organization the server held. Once settled, a slug that is
  // not one of the caller's rows (a previous user's, an org since left) is inert: the personal
  // workspace stands in, as it does for a caller who has never chosen.
  //
  // The wait is BOUNDED ({@link PREFERENCE_WAIT_MS}). The account read has no timeout of its own,
  // so a stalled one held the trigger on "Loading…", with no row current, for the life of the
  // page. Once the bound passes the personal workspace stands in as if the read had settled empty;
  // `settled` itself stays honest, and an answer that lands later still takes over, because a
  // preferred slug naming one of the caller's rows wins whatever the wait did.
  const preferredRow = owners.some((w) => w.slug === preferred)
  const waiting = enabled && !preferredRow && !settled
  // The expiry belongs to the wait it timed, so it records whose wait that was: a subject that
  // changes straight from one user to another (another tab signing in as someone else) is a new
  // wait, not one already over. And any wait that starts again — signed back in, or a settled
  // answer the cache has since dropped — starts unexpired. Adjusted during render (React's
  // "storing information from previous renders"), not synced from an effect.
  const [expiredFor, setExpiredFor] = useState<string | null>(null)
  const [wasWaiting, setWasWaiting] = useState(waiting)
  if (wasWaiting !== waiting) {
    setWasWaiting(waiting)
    if (waiting) setExpiredFor(null)
  }
  // An effect because a timer is a subscription to the clock, not derived state.
  useEffect(() => {
    if (!waiting) return
    const timer = setTimeout(() => setExpiredFor(subject), PREFERENCE_WAIT_MS)
    return () => clearTimeout(timer)
  }, [waiting, subject])
  const pending = waiting && expiredFor !== subject
  const currentSlug = preferredRow
    ? preferred
    : pending
      ? undefined
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
  return { workspaces, select, pending }
}
