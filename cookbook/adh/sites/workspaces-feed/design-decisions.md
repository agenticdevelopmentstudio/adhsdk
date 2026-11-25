
**Decision**: The menu is handed pre-resolved rows through a context; it
never reads workspace data itself.
**Rationale**: From `workspaces-menu.tsx`: the menu "lives in shared chrome
that can't import the hub. So the hub PRE-RESOLVES each workspace into a
plain `MenuWorkspace` and injects the list through this context; the shared
menu stays dumb. Off the hub (no provider) the menu simply hides the
Workspaces row."
**Approved**: pending

**Decision**: The feed is its own package entry, not a member of the header
barrel.
**Rationale**: From the module comment: it "value-imports `@adh-sdk/data`
(and through it react-query and `@adh-sdk/auth`), and a site that renders a
nav link should not pull the data layer in behind it". It reaches the menu
context by the package path "so the context this fills is the one
SiteMenuSwitcher reads".
**Approved**: pending

**Decision**: One prop, `switchBy`, separates the hub from a satellite.
**Rationale**: From the prop's doc comment: it is "the one way the hub and a
satellite differ, and everything else follows from it" — which rows, which
is current, what a pick does, and where the menu shows.
**Approved**: pending

**Decision**: Sign-in is read from the stored token's subject, and each mode
closes the gap with the host's own sign-in through a single value.
**Rationale**: From the provider's doc comment: "The menu and its feed must
never disagree about the visitor." Preference mode asks for the swap only
while the token says signed in, "so a host whose auth says signed in while
the token store has no subject keeps its site menu rather than an empty 'No
workspaces yet' menu"; route mode reports loading, since "to that visitor a
token with no subject is one that has not landed yet".
**Approved**: pending

**Decision**: `error` exists in the contract.
**Rationale**: From `WorkspacesMenu.error`'s doc comment: "no rows, not
loading" was all the menu could see, "and it told someone whose fetch had
failed that they had 'No workspaces yet' — a false statement about their
account, where the truth is that we could not ask."
**Approved**: pending

**Decision**: The route's switch is registered into a ref by a layout
effect, and the menu's `select` is one stable function that reads it at pick
time.
**Rationale**: From `useRegisterWorkspaceSelect`'s doc comment: the switch
keeps "the feature you are on", where a plain `href` lands on the bare
workspace. Held in a ref "never in state: nothing renders from it", so a
registration "re-renders nothing — not the app root, not a menu consumer".
The effect is the deliberate exception to deriving state: the switch "is a
CALLBACK owned by a component below the provider; the provider cannot
derive it, only be handed it". A layout effect, "so a render React discards
never leaves its switch behind, and so the latest switch is in place before
paint, ahead of any click".
**Approved**: pending

**Decision**: In route mode the current row comes from URL membership with
no fallback; in preference mode an unknown preference falls back to the
personal workspace, but only once the server's preference has settled or a
3000 ms wait has run out without it.
**Rationale**: From the source: the workspace route "is the BARE `/<slug>`,
the same shape as `/login`, so the first segment is a workspace exactly when
a row carries it", and "off a workspace route no row is current, and the
trigger reads 'Workspaces', which is true there". A stored slug outside the
rows "is inert: the personal workspace stands in, as it does for a caller
who has never chosen". Marking that fallback before the server answered
showed a device with no cached pick the personal workspace and then swapped
to the organization the server held, so until then the feed reports
`loading` with no row current; a cached pick that names a row stays the
first paint's fast path. The wait is bounded because the account read has
no timeout of its own: unbounded, a stalled read held the trigger on
"Loading…" for the life of the page. The bound stays in the feed, not the
shared loader, so `settled` keeps meaning the server answered.
**Approved**: pending

**Decision**: A preference-mode pick records and stays put.
**Rationale**: From the source and `selectStaysOnPage`'s doc comment: a
satellite has no workspace routes, so a pick "only RECORDS the preference",
and the menu "skips the leave-this-page confirmation: nothing unsaved is
lost, and a refused prompt would drop the pick for no reason".
**Approved**: pending

