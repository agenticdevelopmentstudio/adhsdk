import { type ReactNode } from 'react';
/** Hands the provider the switch a mounted workspace route performs (or null when it unmounts). */
export type RegisterWorkspaceSelect = (select: ((slug: string) => void) | null) => void;
/** Exported for tests, which capture the registered switch without the whole provider. Filled by
 *  {@link SiteWorkspacesMenuProvider} in `switchBy="route"`; a no-op anywhere else. */
export declare const WorkspaceSelectRegistrar: import("react").Context<RegisterWorkspaceSelect>;
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
export declare function useRegisterWorkspaceSelect(select: (slug: string) => void): void;
export type SiteWorkspacesMenuProviderProps = {
    children: ReactNode;
    /**
     * How a pick switches — the one way the hub and a satellite differ, and everything else follows
     * from it:
     *
     * - `'preference'` (default; a satellite, which has no workspace routes): rows are the personal
     *   workspace and the organizations (a team owns nothing and is never a preference); the current
     *   row is the stored family preference, else the personal workspace — that fallback only once
     *   the server's preference has settled or a bounded wait (`PREFERENCE_WAIT_MS`) has run out,
     *   timed afresh for each wait and each subject (until then `loading`, unless the browser's
     *   cached preference already names a row, or the list failed with no rows to show); a pick
     *   RECORDS the preference (`useWorkspacePreference`) and marks it current, with no navigation;
     *   and the menu
     *   shows on every route (`everyRoute`). A row's `href` opens that workspace on the hub, for
     *   open-in-new-tab.
     * - `'route'` (the hub): every row the URL can reach, teams included, one per slug; the current
     *   row is the one whose slug is the URL's first segment, else none; a pick goes through the
     *   switch a mounted workspace route registered at pick time ({@link useRegisterWorkspaceSelect}),
     *   else follows `/<slug>`; and the menu shows on the hub's workspace routes only.
     */
    switchBy?: 'preference' | 'route';
};
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
export declare function SiteWorkspacesMenuProvider({ children, switchBy, }: SiteWorkspacesMenuProviderProps): ReactNode;
//# sourceMappingURL=workspaces-feed.d.ts.map