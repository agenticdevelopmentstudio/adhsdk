---
id: 13339f1f-e815-4199-bdaa-dad533a94591
title: "Workspaces Feed"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-25
modified: 2026-11-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The shared provider that fills the header workspace menu with the signed-in user's workspaces, pre-resolved into menu rows, in one of two switch modes: a satellite's pick records the cross-site preference, the hub's pick goes through the mounted workspace route's switch."
platforms:
  - typescript
  - web
tags:
  - header
  - menu
  - workspace
  - provider
  - switcher
depends-on:
  - 14a8624d-5527-47e5-9513-1727910a5f47
related:
  - f2d56415-ac36-4a27-bee5-b447c4186513
  - 9069ccf9-0357-4311-9671-91ee2793adae
references:
  - packages/web/packages/adh/src/header/workspaces-feed.tsx (adhsdk)
  - packages/web/packages/adh/src/header/workspaces-menu.tsx (adhsdk)
  - packages/web/packages/adh/src/header/__tests__/workspacesFeed.test.tsx (adhsdk)
approved-by: ""
approved-date: ""
---

# Workspaces Feed

## Overview

The data side of the shared header's workspace menu. The menu lives in
chrome every site shares and must stay data-free, so a site that opts in
mounts this provider, which reads the signed-in user's workspaces through
[adhsdk.ingredient.data.services.workspace-switching](cookbook:14a8624d-5527-47e5-9513-1727910a5f47),
pre-resolves them into plain menu rows (id, label, href, current), and hands
them, with a loading state, an error flag and a pick handler, to the menu
through the workspaces-menu context. The
[adhsdk.recipe.adh.sites.site-menu](cookbook:f2d56415-ac36-4a27-bee5-b447c4186513)
switcher reads that context and decides where the menu shows.

It runs in one of two switch modes, the one way the hub and a satellite
differ:

- **preference** (the default; a satellite, which has no workspace routes):
  the personal workspace and the organizations, current by the stored
  cross-site preference, a pick records the preference without navigating,
  and the menu shows on every route.
- **route** (the hub): every row a bare `/<slug>` can reach, teams included,
  current by the URL, a pick goes through the switch a mounted workspace
  route registered, else follows `/<slug>`.

It was moved from the hub so the hub and every satellite that opts in run
one copy. This ingredient covers the provider, the route-switch registrar,
and the workspaces-menu context contract the provider fills. It draws
nothing itself.

## Behavioral Requirements

- **menu-context-contract**: The workspaces-menu context MUST carry
  `workspaces` (rows of `id`, `label`, `href` and optional `current`) and
  `loading`, and MAY carry `error`, `select`, `selectStaysOnPage` and
  `everyRoute`.
- **menu-context-absent**: Reading the workspaces-menu context with no
  provider mounted MUST return `null`, so the menu hides its workspace rows.
- **feed-sign-in-signal**: The feed MUST count the visitor as signed in
  exactly when the stored token has a subject.
- **feed-reads-every-row**: The feed MUST read rows through the every-row
  read state, enabled only while signed in, so no request fires without a
  subject.
- **feed-default-mode**: The switch mode MUST default to `preference`.
- **feed-error-gated**: `error` MUST be `true` only while signed in and the
  read has failed.
- **feed-rows-resolved**: Each row MUST carry the row's composite id as
  `id` and the list-label helper's answer as `label`.
- **preference-rows**: In preference mode the rows MUST be the
  non-team rows, one per slug (first per slug), in the backend's order.
- **preference-current**: In preference mode the current row MUST be the one
  whose slug is the stored preference when that slug is among the rows (the
  browser's cached preference before the server's answer is in), else, once
  the server's preference has settled, the individual row.
- **preference-current-waits**: In preference mode, while signed in, the
  server's preference has not settled and the preference names none of the
  rows, NO row MUST be current.
- **preference-href-hub**: In preference mode each row's `href` MUST open
  that workspace (`/<slug>`) on the hub, built from the request host when
  one is known and from the hub's production URL otherwise.
- **preference-pick-records**: In preference mode a pick MUST record the
  picked row's slug as the preference and MUST NOT navigate.
- **preference-stays-on-page**: In preference mode `selectStaysOnPage` MUST
  be `true`.
- **preference-every-route**: In preference mode `everyRoute` MUST be `true`
  while signed in and absent otherwise.
- **preference-loading**: In preference mode `loading` MUST be `true` only
  while signed in and either the read is loading or the current row waits
  on the server's preference (preference-current-waits).
- **preference-enables-preference**: The preference read state MUST be
  enabled only in preference mode while signed in.
- **route-rows**: In route mode the rows MUST be every row, teams included,
  one per slug (first per slug), in the backend's order, each with `href`
  `/<slug>`.
- **route-current**: In route mode the current row MUST be the one whose
  slug equals the URL path's first segment, and no row MUST be current when
  that segment is no row's slug.
- **route-loading**: In route mode `loading` MUST be `true` while there is
  no subject or the read is loading.
- **route-no-every-route**: In route mode `everyRoute` and
  `selectStaysOnPage` MUST be absent.
- **route-pick-registered**: In route mode a pick MUST map the row's id to
  its slug over the kept rows and call the switch registered at pick time
  with that slug, or push `/<slug>` when none is registered; an id with no
  kept row MUST do nothing.
- **route-registrar-provided**: The route-switch registrar MUST be provided
  only in route mode; anywhere else registering is a no-op.
- **route-register-hook**: The register hook MUST hand the registrar the
  route's switch on mount and whenever the switch changes, and `null` on
  unmount, before paint.
- **route-registration-no-render**: A registration MUST NOT re-render the
  provider or change the `select` the menu holds.
- **feed-entry-isolated**: The feed MUST be published as its own entry
  (`@adh-sdk/adh/header/workspaces-feed`), not through the header barrel,
  and MUST reach the menu context through the package path
  `@adh-sdk/adh/header`.

## Appearance

Not applicable — this is a context provider and its contract, not a visual
component; the site menu draws the rows.

## States

Not applicable — this is a context provider and its contract, not a visual
component; the site menu draws the loading, error and empty states from the
values this hands it.

## Accessibility

Not applicable — this is a context provider and its contract, not a visual
component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| workspaces-feed-001 | preference-rows, preference-every-route, feed-default-mode | signed in; rows `me`/individual, `acme`/organization, `crew`/team; no mode | ids `['individual:me', 'organization:acme']`; `everyRoute: true` (`workspacesFeed.test.tsx`, "lists the personal workspace and the organizations, never a team, on every route") |
| workspaces-feed-002 | preference-current | the same rows; preference `null`, then `'acme'`, then `'gone'` | current `individual:me`, then `organization:acme`, then `individual:me` |
| workspaces-feed-003 | preference-pick-records | preference mode; pick `organization:acme` | the preference is recorded as `'acme'` |
| workspaces-feed-004 | preference-href-hub | preference mode, host `localhost:3000` | each row's `href` ends in `/me` or `/acme` |
| workspaces-feed-005 | feed-reads-every-row, feed-error-gated, preference-loading | preference mode, no subject; the read reports loading and error | the read is called with `{ enabled: false }`; `loading: false`; `error: false` |
| workspaces-feed-006 | preference-every-route | preference mode, no subject | `everyRoute` absent |
| workspaces-feed-007 | route-rows, route-current, route-no-every-route | route mode at `/acme/research` | hrefs `['/me', '/acme', '/crew']`; current `organization:acme`; `everyRoute` absent |
| workspaces-feed-008 | route-pick-registered, route-register-hook | route mode, nothing registered, pick `organization:acme`; then a route registers a switch, pick `team:crew` | `/acme` is pushed; then the switch is called with `'crew'` and nothing more is pushed |
| workspaces-feed-009 | route-registration-no-render | route mode; a route registers one switch, then another; pick `organization:acme` | the menu's `select` is the same function; only the second switch is called, with `'acme'` |
| workspaces-feed-010 | route-rows, route-current | route mode at `/rocket/teams`; rows `mine`/individual, `rocket`/organization, `temporal`/organization, `rocket`/team twice | ids `['individual:mine', 'organization:rocket', 'organization:temporal']`; only `organization:rocket` current |
| workspaces-feed-011 | feed-error-gated | route mode, signed in, the read failed with no data | `{ workspaces: [], loading: false, error: true }` |
| workspaces-feed-012 | route-loading, feed-error-gated | route mode, the read loading, then loaded | `loading: true, error: false`, then `loading: false, error: false` |
| workspaces-feed-013 | route-current | route mode at `/settings` | no row current |
| workspaces-feed-014 | route-rows | route mode, the rows of vector 010, at `/mine` | only those three rows; no `Admin` label, no `/admin` href |
| workspaces-feed-015 | route-loading, feed-reads-every-row | route mode, no subject, at `/acme` | the read is called with `{ enabled: false }`; `{ workspaces: [], loading: true, error: false }`; `everyRoute` absent |
| workspaces-feed-016 | route-registrar-provided | a probe reading the registrar under a preference-mode feed and under a route-mode feed | two different registrars (the default no-op, then the feed's) |
| workspaces-feed-017 | preference-current-waits, preference-loading, preference-current | preference mode, signed in; preference `null` and not settled, then `'acme'` and settled | no row current and `loading: true`, then current `organization:acme` and `loading: false` |
| workspaces-feed-018 | preference-current-waits, preference-current | preference mode, signed in; preference `null` and not settled, then settled | `loading: true`, then current `individual:me` and `loading: false` |
| workspaces-feed-019 | preference-current, preference-loading | preference mode, signed in; cached preference `'acme'`, not settled | current `organization:acme`; `loading: false` |
| workspaces-feed-020 | preference-current-waits, preference-loading | preference mode, signed in; cached preference `'gone'`, not settled | no row current; `loading: true` |
## Edge Cases

- **Host auth ahead of the token**: The host can count the visitor signed in
  (a cached user during bootstrap, a silent sign-on) before the token store
  has a subject. Preference mode then withholds `everyRoute`, so the menu
  needs both signals and the site keeps its own menu (workspaces-feed-006);
  route mode reports `loading`, never an empty list
  (workspaces-feed-015).
- **Signed out**: The read is disabled; what the query still holds is not
  this visitor's, so `error` reads `false` (workspaces-feed-005).
- **A stored preference outside the rows**: A previous user's slug or an
  organization since left is inert; the personal workspace stands in, as it
  does for a caller who never chose (workspaces-feed-002).
- **No cached preference on this device**: Before the server's preference
  arrives the feed marks no row current and reports `loading`, so the
  trigger reads "Loading…" rather than naming the personal workspace and
  then swapping to the organization the server holds (workspaces-feed-017,
  workspaces-feed-018). A cached preference that names one of the rows is
  current at once (workspaces-feed-019); one that names none waits like no
  cache (workspaces-feed-020).
- **Duplicate slugs**: An organization and one or more teams sharing a slug
  give one row, the one a bare `/<slug>` opens; two teams under different
  owners would otherwise share an id (workspaces-feed-010).
- **Off a workspace route**: In route mode at a path whose first segment is
  no row's slug (`/settings`, `/login`) no row is current, so the trigger
  reads its generic label (workspaces-feed-013), and a pick follows
  `/<slug>`, since there is no feature to keep.
- **A new switch per navigation**: A workspace route hands up a new switch
  on each in-workspace navigation; it lands in a ref, so neither the root
  nor a menu consumer re-renders (workspaces-feed-009).
- **A pick for an unknown id**: A row id with no kept row does nothing.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `switchBy` | `'preference' \| 'route'` | `'preference'` | How a pick switches; every other difference between the hub and a satellite follows from it |

## Deep Linking

Each row's `href` is a deep link to that workspace's home: `/<slug>` on the
hub in route mode, and the hub's URL for `/<slug>` (built from the request
host, else the hub's production URL, through
[adhsdk.ingredient.adh.sites.site-registry](cookbook:9069ccf9-0357-4311-9671-91ee2793adae))
in preference mode, for open-in-new-tab. Route mode reads the URL's first
path segment to mark the current row. The feed registers no route.

## Localization

Not applicable: the feed adds no text of its own; row labels come from the
list-label helper (whose fallbacks Workspace Switching lists) and the menu's
own strings belong to the site menu.

## Accessibility Options

Not applicable: the feed renders nothing, so Reduce Motion, Increase
Contrast and Differentiate Without Color act on the site menu.

## Feature Flags

Not applicable: no flag is read. Mounting the provider is a site's opt-in to
the header workspace menu, and `switchBy` is a prop, not a flag.

## Analytics

Not applicable: no analytics or telemetry event is emitted.

## Privacy

Not applicable: the feed collects, stores and sends nothing of its own. It
maps rows the data layer already read, and a preference-mode pick is
recorded through the Workspace Switching preference read state.

## Logging

Not applicable: no log call is made; a failed read reaches the menu as
`error`.

## Platform Notes

- **SwiftUI**: An `@Observable` feed object injected with `.environment`
  replaces the context; the menu view reads it and is `nil`-safe for a scene
  that does not opt in. The registrar is a closure property the workspace
  route's view sets in `.onAppear` and clears in `.onDisappear`; keep it out
  of observation (`@ObservationIgnored`) so a registration re-renders
  nothing.
- **Compose**: A `CompositionLocal` (`staticCompositionLocalOf<WorkspacesMenu?>
  { null }`) carries the contract. The route registers its switch in a
  `DisposableEffect`, writing a plain holder rather than `State`, so the
  menu is not recomposed.
- **React/Web**: The source. `workspaces-menu.tsx` holds the contract
  (`MenuWorkspace`, `WorkspacesMenu`, `WorkspacesMenuProvider`,
  `useWorkspacesMenu`) inside the header barrel. `workspaces-feed.tsx` is a
  `"use client"` module with its own tsup entry and package export
  (`./header/workspaces-feed`), importing the context by package path so it
  fills the one `SiteMenuSwitcher` reads: `SiteWorkspacesMenuProvider`,
  `WorkspaceSelectRegistrar` (a context defaulting to a no-op, exported for
  tests) and `useRegisterWorkspaceSelect`, a `useLayoutEffect` that writes a
  `useRef`. It reads sign-in with `useTokenSubject`, the URL with Next's
  `usePathname`, navigates with `useRouter().push`, and builds hub URLs with
  `siteUrl` / `siteProdUrl` and `useClientHost`.
- **AppKit / UIKit**: The window controller (or scene delegate) owns the
  feed and rebuilds the `NSMenu` or `UIMenu` from its rows; the active
  workspace view controller sets a weak switch closure on it when it appears
  and clears it when it disappears.
- **WinUI 3**: A view-model implementing `INotifyPropertyChanged`, exposed as
  an app-level resource, holds the rows a `MenuFlyout` binds to. The
  workspace page sets a plain `Action<string>` field (not a bound property)
  in `OnNavigatedTo` and clears it in `OnNavigatedFrom`, so a registration
  raises no change notification. Preference-mode hrefs open with
  `Launcher.LaunchUriAsync`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/adh/src/header/workspaces-feed.tsx` | confirmed (1.0.0) |
| web | `packages/web/packages/adh/src/header/workspaces-menu.tsx` | confirmed (1.0.0) |

## Design Decisions

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
personal workspace, but only once the server's preference has settled.
**Rationale**: From the source: the workspace route "is the BARE `/<slug>`,
the same shape as `/login`, so the first segment is a workspace exactly when
a row carries it", and "off a workspace route no row is current, and the
trigger reads 'Workspaces', which is true there". A stored slug outside the
rows "is inert: the personal workspace stands in, as it does for a caller
who has never chosen". Marking that fallback before the server answered
showed a device with no cached pick the personal workspace and then swapped
to the organization the server held, so until then the feed reports
`loading` with no row current; a cached pick that names a row stays the
first paint's fast path.
**Approved**: pending

**Decision**: A preference-mode pick records and stays put.
**Rationale**: From the source and `selectStaysOnPage`'s doc comment: a
satellite has no workspace routes, so a pick "only RECORDS the preference",
and the menu "skips the leave-this-page confirmation: nothing unsaved is
lost, and a refused prompt would drop the pick for no reason".
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |

`separation-of-concerns` passes: the contract (`workspaces-menu.tsx`) holds
no data logic, the feed holds only the mapping from rows to menu rows, and
reading, naming and de-duplicating rows stays in the data layer.
`unit-test-coverage` passes: `workspacesFeed.test.tsx` holds a test for
every vector above. `explicit-error-handling` passes: a failed read reaches
the menu as `error`, never as an empty list. `graceful-degradation` passes:
with nothing registered a route-mode pick still follows `/<slug>`, and an
unknown preference falls back to the personal workspace. `safe-defaults`
passes: the default mode navigates nowhere, and with no subject no request
fires. `data-minimization` passes: the menu receives only id, label, href
and current.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-25 | Mike Fullerton | Preference mode marks the personal fallback current only once the server's preference has settled; until then loading, unless a cached preference names a row |
| 1.0.0 | 2026-11-25 | Mike Fullerton | Initial recipe: the header workspace menu's shared feed, moved from the hub, in preference and route switch modes, and the workspaces-menu context contract. |
