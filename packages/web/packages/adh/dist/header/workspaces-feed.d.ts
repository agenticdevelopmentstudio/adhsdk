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
 * It registers ONE stable wrapper per mount, which calls whichever `select` the route rendered
 * last. `select` is a new function on every in-workspace navigation (it closes over the pathname),
 * and registering each new one set the provider's state at the app root, re-rendering the root a
 * second time per navigation and handing every menu consumer a new context value. Reading the
 * latest through a ref gives the menu a switch that does what the route would do NOW, with no new
 * identity to pass up.
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
     *   row is the stored family preference, else the personal workspace; a pick RECORDS the
     *   preference (`useWorkspacePreference`) and marks it current, with no navigation; and the menu
     *   shows on every route (`everyRoute`). A row's `href` opens that workspace on the hub, for
     *   open-in-new-tab.
     * - `'route'` (the hub): every row the URL can reach, teams included, one per slug; the current
     *   row is the one whose slug is the URL's first segment, else none; a pick goes through the
     *   switch a mounted workspace route registered ({@link useRegisterWorkspaceSelect}), else
     *   follows `/<slug>`; and the menu shows on the hub's workspace routes only.
     */
    switchBy?: 'preference' | 'route';
};
/**
 * Fills the shared header's workspace menu with the signed-in user's workspaces, PRE-RESOLVED into
 * {@link MenuWorkspace} rows so the menu itself stays data-free. Mounting it is a site's opt-in to
 * the header workspace menu (see `SiteMenuSwitcher`).
 *
 * Gated on sign-in by the stored token's subject ({@link useTokenSubject}), so it works under any
 * host's auth context: signed out, no request fires and `loading`/`error` read false.
 */
export declare function SiteWorkspacesMenuProvider({ children, switchBy, }: SiteWorkspacesMenuProviderProps): ReactNode;
//# sourceMappingURL=workspaces-feed.d.ts.map