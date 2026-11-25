---
id: 14a8624d-5527-47e5-9513-1727910a5f47
title: "Workspace Switching"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-25
modified: 2026-11-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The shared data every workspace switcher reads: every workspace row in one cached, change-subscribed entry per query client, the cross-site workspace preference, and the pure helpers that name, label and de-duplicate workspace rows."
platforms:
  - typescript
  - web
tags:
  - data
  - workspace
  - cache
  - preference
  - switcher
depends-on:
  - ec6e6ca5-8780-4ce2-8b3a-087adc50ed35
  - 0fcd16c1-a8da-4184-b63f-97b68ed6378d
related: []
references:
  - packages/web/packages/data/src/use-workspaces.ts (adhsdk)
  - packages/web/packages/data/src/workspace-rows.ts (adhsdk)
  - packages/web/packages/data/src/use-workspace-preference.ts (adhsdk)
  - packages/web/packages/data/src/__tests__/use-workspaces.test.tsx (adhsdk)
  - packages/web/packages/data/src/__tests__/workspace-rows.test.ts (adhsdk)
  - packages/web/packages/data/src/__tests__/use-workspace-preference.test.tsx (adhsdk)
approved-by: ""
approved-date: ""
---

# Workspace Switching

## Overview

The shared data layer behind every surface that offers workspaces: the hub's
switcher and rail, and the header workspace menu a satellite site opts into.
It was moved out of the hub so every such surface reads, names, labels and
de-duplicates workspaces one way. It has three parts:

- an **every-row read state** that reads every workspace the caller can
  switch to, teams included, through the
  [adhsdk.ingredient.data.services.resource-data](cookbook:ec6e6ca5-8780-4ce2-8b3a-087adc50ed35)
  all-rows operation, cached once on the toolkit's query client
  ([adhsdk.ingredient.data.services.query-cache](cookbook:0fcd16c1-a8da-4184-b63f-97b68ed6378d))
  and refreshed when the workspace list is announced as changed;
- a **workspace-preference read state** that reads and records the caller's
  cross-site workspace choice through the one shared item-cache entry, for a
  surface that records a choice without navigating;
- **pure row helpers** (no React, no fetch, so a server module can use
  them): a workspace's selection id across types, the label a workspace is
  shown by, and the first row of each slug.

The workspace client, the cache keys, the change announcement and the
preference's storage and endpoints belong to Resource Data; this ingredient
is the read side every switcher shares on top of them. It has no visual
surface.

## Behavioral Requirements

- **every-row-read**: The every-row read state MUST resolve to the result of
  the all-rows operation: every workspace row the caller can switch to,
  teams included, in the backend's order.
- **every-row-cache-entry**: The every-row read state MUST cache its rows on
  the toolkit's own query client under the workspace-rows cache key, so
  every reader on that client shares one entry.
- **every-row-enabled-default**: The every-row read state's `enabled` option
  MUST default to `true`.
- **every-row-disabled-no-request**: While `enabled` is `false` (the
  signed-out case), the every-row read state MUST NOT issue a request.
- **every-row-no-retry**: The every-row read state MUST NOT retry a failed
  read; the failure MUST surface on the returned query result.
- **every-row-refetch-on-change**: When this copy of the package announces
  that the workspace list changed, a mounted, enabled every-row reader MUST
  refetch and resolve to the new rows.
- **every-row-subscribe-on-read**: Mounting an every-row reader MUST
  subscribe its query client to workspace-list-changed announcements made by
  any other copy of the package, through Resource Data's subscription for
  announcements made elsewhere, and each such announcement MUST invalidate
  the workspace-rows entry on that client.
- **every-row-one-subscription-per-client**: The every-row read state MUST
  hold at most one such subscription per query client however many readers
  are mounted on it, so one announcement invalidates the entry once per
  client.
- **every-row-own-announcement-one-sweep**: An announcement this copy made
  MUST invalidate the workspace-rows entry exactly once on this copy's
  client (the announcement's own direct invalidation), however many readers
  are mounted.
- **every-row-subscription-refcount**: The subscription MUST stay in place
  while any reader on that client is mounted, and MUST be removed when the
  last one unmounts.
- **composite-id-format**: The composite-id helper, given a row's `type` and
  `slug`, MUST return `<type>:<slug>`.
- **composite-id-carries-type**: Two rows with the same slug and different
  types MUST get different composite ids.
- **list-label-trimmed-name**: The list-label helper MUST return the row's
  `name` with leading and trailing whitespace removed when that is not
  empty, for every type, the individual workspace included.
- **list-label-blank-individual**: The list-label helper MUST return
  `My Workspace` for an individual row whose name is empty or whitespace.
- **list-label-blank-other**: The list-label helper MUST return `Workspace`
  for an organization or team row whose name is empty or whitespace.
- **list-label-never-empty**: The list-label helper MUST NOT return an empty
  string.
- **first-per-slug-keeps-first**: The first-per-slug helper MUST keep the
  first row of each slug and drop every later row with that slug.
- **first-per-slug-order**: The first-per-slug helper MUST keep the
  surviving rows in their input order and return the same row values it was
  given, of whatever row shape.
- **row-helpers-pure**: The three row helpers MUST be pure functions with no
  UI-framework or network dependency.
- **preference-shared-entry**: The workspace-preference read state MUST read
  and write the caller's preference row through the shared item cache under
  the cache key `workspace-prefs` and the item id `me`, both exported so
  every reader and writer of the row shares one entry.
- **preference-load**: The workspace-preference read state MUST load the
  row with Resource Data's workspace-preferences read operation.
- **preference-disabled**: While `enabled` is `false`, the
  workspace-preference read state MUST NOT read the row and MUST report
  `slug` as `null` and `settled` as `false`.
- **preference-enabled-default**: The workspace-preference read state's
  `enabled` option MUST default to `true`.
- **preference-seed-browser-cache**: Until the row is in, the
  workspace-preference read state MUST report the slug held in the browser's
  cached-workspace storage, or `null` when none is held.
- **preference-seed-read-each-render**: The browser-cache seed MUST be read
  on every render while enabled, never captured once at mount.
- **preference-server-row-wins**: Once the row is in, the
  workspace-preference read state MUST report the row's `slug`, and MUST
  report `null` when the row carries no slug.
- **preference-failed-read**: When the row's read fails, the
  workspace-preference read state MUST keep reporting the browser-cache seed.
- **preference-settled**: `settled` MUST be `true` once the row is in or its
  read has failed, and `false` before that.
- **preference-slug-not-validated**: The workspace-preference read state
  MUST NOT check the slug against the caller's workspaces; the caller holds
  the list and decides what a slug outside it means.
- **preference-choose-order**: Choosing a slug MUST write it to the browser's
  cached-workspace storage, then re-render the reader, then write it into the
  shared item-cache entry, then send it to the server with Resource Data's
  workspace-preferences write operation as `{ slug }`.
- **preference-choose-shows-at-once**: After a choice, the reader MUST
  report the chosen slug without waiting for the server.
- **preference-choose-put-failure-silent**: A failed server write MUST NOT
  raise, and MUST leave the choice standing in both caches; the next choice
  writes again, and nothing retries this one.
- **preference-choose-survives-first-read**: A choice made while the first
  read is in flight MUST NOT be overwritten when that read lands.

## Appearance

Not applicable — this is a data layer (read states and pure helpers), not a
visual component.

## States

Not applicable — this is a data layer (read states and pure helpers), not a
visual component.

## Accessibility

Not applicable — this is a data layer (read states and pure helpers), not a
visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| workspace-switching-001 | every-row-read | the backend returns `me` (individual) and `crew` (team); one enabled reader | resolves to slugs `['me', 'crew']` (`use-workspaces.test.tsx`, "loads every workspace row, teams included") |
| workspace-switching-002 | every-row-disabled-no-request | a reader mounted with `enabled: false` | no request is issued ("asks for nothing while disabled") |
| workspace-switching-003 | every-row-refetch-on-change | an enabled reader holding one row; the backend now returns two; this copy announces a change | the reader resolves to two rows ("refetches when the workspace list is announced as changed") |
| workspace-switching-004 | every-row-one-subscription-per-client, every-row-own-announcement-one-sweep | three readers on one client; this copy announces a change | the workspace-rows entry is invalidated once ("sweeps the entry once per change, however many readers are mounted") |
| workspace-switching-005 | every-row-subscribe-on-read, every-row-one-subscription-per-client | two readers on one client; another copy's change event | the workspace-rows entry is invalidated once ("sweeps once for an announcement another copy of the module sent") |
| workspace-switching-006 | every-row-subscription-refcount | of those two readers, one unmounts, then another foreign event; then the last unmounts, then another foreign event | one more invalidation after the first event; none after the second |
| workspace-switching-007 | composite-id-format, composite-id-carries-type | `{ type: 'organization', slug: 'acme' }` and `{ type: 'team', slug: 'acme' }` | `'organization:acme'` and `'team:acme'` (`workspace-rows.test.ts`) |
| workspace-switching-008 | list-label-trimmed-name | `{ name: '  Acme ', type: 'organization' }`; `{ name: 'Ada', type: 'individual' }` | `'Acme'`; `'Ada'` |
| workspace-switching-009 | list-label-blank-individual, list-label-blank-other, list-label-never-empty | names `''` and `'   '` (individual), `''` (organization), `''` (team) | `'My Workspace'`, `'My Workspace'`, `'Workspace'`, `'Workspace'` |
| workspace-switching-010 | first-per-slug-keeps-first, first-per-slug-order | rows `me`/individual, `acme`/organization, `acme`/team, `crew`/team | the first, second and fourth rows, in that order |
| workspace-switching-011 | preference-seed-browser-cache, preference-server-row-wins, preference-settled | browser cache holds `'cached'`; the row read is pending, then resolves `{ slug: 'server' }` | `slug: 'cached'`, `settled: false`; then `slug: 'server'`, `settled: true` (`use-workspace-preference.test.tsx`) |
| workspace-switching-012 | preference-disabled | browser cache holds `'cached'`; `enabled: false` | no read issued; `slug: null` |
| workspace-switching-013 | preference-seed-read-each-render | mounted disabled with cache `'previous-user'`; cache becomes `'this-user'`; re-rendered enabled with the read pending | `slug: 'this-user'` |
| workspace-switching-014 | preference-choose-survives-first-read | the first read is pending; `choose('acme')`; the read resolves `{ slug: 'me' }` | `slug` stays `'acme'` |
| workspace-switching-015 | preference-choose-order, preference-choose-shows-at-once | the row read resolves `{ slug: 'me' }`; then `choose('acme')` | `slug: 'acme'` at once; the browser cache holds `'acme'`; the server write is called with `{ slug: 'acme' }` |

## Edge Cases

- **Signed out**: Both read states take `enabled: false`; the every-row read
  state issues no request (workspace-switching-002) and the preference read
  state reads nothing and reports `slug: null` (workspace-switching-012).
- **Two copies of the package**: A host that bundles its own copy announces
  with an event this copy did not send. That copy's direct invalidation
  reached its own client, so this copy's subscription sweeps this client
  once (workspace-switching-005); this copy's own announcements add no
  second sweep (workspace-switching-004).
- **Concurrent readers**: The header menu, the rail and a gate can all read
  at once; they share one entry and one subscription per client
  (workspace-switching-004). JavaScript runs these on one thread, so the
  reader count needs no further ordering.
- **Duplicate slugs**: A personal workspace and a team, or an organization
  and a team, can share a slug, and two teams under different owners share
  a composite id. The first-per-slug helper keeps only the row a bare
  `/<slug>` opens (workspace-switching-010); a menu that needs unique ids
  runs it first.
- **Blank names**: The backend names a personal workspace `displayName ??
  slug`, so a display name saved as `''` arrives as `''`; the list-label
  helper still returns a name (workspace-switching-009).
- **Stale browser cache**: A sign-in, sign-out or another tab can rewrite the
  cached slug while a preference reader is mounted; the seed is re-read
  each render, so a previous session's slug does not linger
  (workspace-switching-013).
- **A row with no slug, or a slug outside the list**: A row of `{}` (a
  caller who never chose) reports `slug: null`. A slug the caller no longer
  has is reported as is; the consumer decides what it means.
- **Failed reads and writes**: A failed every-row read surfaces on the query
  result, unretried. A failed preference read keeps the seed and settles. A
  failed preference write is dropped silently with the choice standing in
  both caches.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` (every-row read state) | `boolean`, per call | `true` | Gates the authed request; pass the signed-in state |
| `enabled` (preference read state) | `boolean`, per call | `true` | Gates the read; `false` reports `slug: null` |
| preference cache key | exported constant | `'workspace-prefs'` | The shared item-cache key every reader and writer of the preference row uses |
| preference item id | exported constant | `'me'` | The row's id in that cache; the item cache's tenant scoping already separates one signed-in caller from the next |
| preference loader | exported function | Resource Data's workspace-preferences read | Module-scope, so the item read state can hold it in a dependency list |
| query client | injected by the toolkit | the toolkit's own query client | The every-row read state always uses the toolkit client, never a host's |

## Deep Linking

Not applicable: these read states and helpers register no route and parse no
URL. The composite id is a selection id for menus, never decoded back into a
slug or used as a path.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `workspaceListLabel.individualFallback` | My Workspace | The list-label helper's answer for an individual workspace with a blank name |
| `workspaceListLabel.fallback` | Workspace | The list-label helper's answer for an organization or team with a blank name |

Both are hardcoded English literals in `workspace-rows.ts`, with no message
catalog or locale parameter. A non-blank name is the backend's own text,
shown as is.

## Accessibility Options

Not applicable: this layer renders nothing, so Reduce Motion, Increase
Contrast and Differentiate Without Color act on the menus that consume it.

## Feature Flags

Not applicable: no flag is defined or read. Every branch follows from a
caller's `enabled` argument, the rows, or the stored preference.

## Analytics

Not applicable: no analytics or telemetry event is emitted.

## Privacy

- **Data collected**: None of its own. It reads the caller's workspace rows
  (slug, name, type) and their preferred workspace slug.
- **Storage**: Workspace rows live only in the in-memory query cache. The
  preferred slug is kept in the browser's cached-workspace storage
  (plaintext, Resource Data's `<prefix>:home:workspace`) and in the
  in-memory item cache; neither is a credential.
- **Transmission**: The preferred slug is sent to the caller's own account
  row through Resource Data's workspace-preferences write; rows are read
  through the shared authenticated request layer.
- **Retention**: In-memory entries follow the shared query cache's lifetime
  and are cleared when the signed-in principal changes. The browser-cache
  slug persists until overwritten or cleared by the host.

## Logging

Not applicable: no log call is made. A failed every-row read surfaces on the
query result; a failed preference write is dropped deliberately (see Design
Decisions).

## Platform Notes

- **SwiftUI**: An `@Observable` store per client, holding the rows as an
  array and loading them with `async`/`await` on `URLSession`, stands in for
  the react-query entry. A `NotificationCenter` observer on the
  workspaces-changed name replaces the window event; keep one observer per
  store with a reader count, and tag the notifications this process posted
  (an `object` sender or a `userInfo` token) so they are skipped. The
  preference reads `UserDefaults` for the seed and writes it before the
  network call.
- **Compose**: A `ViewModel` exposing `StateFlow<List<WorkspaceRow>>`,
  loaded in `viewModelScope`, replaces the hook. A `SharedFlow` replaces the
  event; collect it once per repository, not per screen. DataStore holds the
  preference seed. The row helpers are top-level Kotlin functions
  (`distinctBy { it.slug }` is the first-per-slug helper).
- **React/Web**: The source. `use-workspaces.ts` (`useWorkspaces`, a
  `useQuery` on `getToolkitQueryClient()` under `WORKSPACE_ROWS_QUERY_KEY`
  with `retry: false`, and a module-scope `WeakMap<QueryClient, { readers,
  unsubscribe }>` that counts readers and subscribes through
  `onWorkspacesChangedElsewhere`); `workspace-rows.ts`
  (`workspaceCompositeId`, `workspaceListLabel`, `firstWorkspacePerSlug`);
  `use-workspace-preference.ts` (`useWorkspacePreference`,
  `WORKSPACE_PREFS_CACHE_KEY`, `WORKSPACE_PREFS_ID`, `loadWorkspacePrefs`,
  built on `useResourceItemQuery` and `useResourceItemWriter`, with a
  `useReducer` counter to re-render after a choice). Both hook modules are
  `"use client"`; `workspace-rows.ts` is not, so a server module can import
  it.
- **AppKit / UIKit**: The same store as SwiftUI, observed with Combine
  (`@Published` rows) or KVO by the menu's controller; an `NSMenu` or
  `UIMenu` is rebuilt from the rows. `NotificationCenter` carries the change
  event.
- **WinUI 3**: A singleton service holding an
  `ObservableCollection<WorkspaceRow>` that a `MenuFlyout` or
  `NavigationView` binds to, filled by `HttpClient.GetFromJsonAsync` with
  `System.Text.Json` (map snake_case with
  `JsonNamingPolicy.SnakeCaseLower`), on the UI thread through
  `DispatcherQueue`. The change event is a C# `event` on that service,
  subscribed once (a reference count of attached views, or
  `WeakEventManager`); tag events this process raised so its own direct
  refresh is not doubled. The preference seed lives in
  `ApplicationData.Current.LocalSettings`, written before the
  `HttpClient.PostAsJsonAsync` call, whose failure is caught and dropped.
  The row helpers are static methods; `DistinctBy(r => r.Slug)` is the
  first-per-slug helper.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/data/src/use-workspaces.ts` | confirmed (1.0.0) |
| web | `packages/web/packages/data/src/workspace-rows.ts` | confirmed (1.0.0) |
| web | `packages/web/packages/data/src/use-workspace-preference.ts` | confirmed (1.0.0) |

## Design Decisions

**Decision**: Reading workspaces subscribes the reader's query client to
change announcements, once per client, counted, and only for announcements
another copy of the package made.
**Rationale**: From `useWorkspaces`' doc comment: the announcement already
invalidates this copy's entry directly, but "a host that bundles a second
physical `@adh-sdk/data` has a second toolkit client, and the window event
is the one announcement every copy hears". A second invalidation "is NOT
harmless: react-query's `invalidateQueries` cancels the refetch in flight
and starts another, so each extra sweep is an extra request". And "the
header menu, the rail and a gate can all read at once, and a subscription
each would sweep the one shared entry once per reader", so the subscription
is counted, "so the last reader to unmount removes it".
**Approved**: pending

**Decision**: One entry holds every row, teams included; a caller that wants
fewer rows filters what it gets.
**Rationale**: From the doc comment: "a caller that wants fewer rows (a
satellite: no teams) filters what this returns, so every switcher shares
one entry of all rows". `workspacesApi.list()`'s owner subset is a
different shape and keeps its own key.
**Approved**: pending

**Decision**: The every-row read state does not retry.
**Rationale**: From the doc comment: "No retry: the menu shows the failure,
and a second try only delays it."
**Approved**: pending

**Decision**: The composite id carries the type, and is never decoded back
into a slug.
**Rationale**: From `workspaceCompositeId`'s doc comment: "A slug alone
isn't unique across TYPES", yet the id is "NOT unique on its own either: a
team's slug is unique only within its owner". A menu gets unique ids only
because the header's workspaces feed first keeps one row per slug, and "the
feed maps a picked id to its row's slug with its own lookup over those same
kept rows".
**Approved**: pending

**Decision**: The list label reads every type by its own name, and falls back
to `My Workspace` or `Workspace` only for a blank name.
**Rationale**: From `workspaceListLabel`'s doc comment: the backend already
names the individual workspace after its owner, "so a personal workspace
shows the USER'S NAME rather than a generic 'My Workspace'". The blank
fallback "is load-bearing, not defensive noise": the backend's nullish
coalescing passes an empty display name through as `''`, which every
consumer treats as present, "so it is also the only place that can refuse
to return nothing". One function, "so all those surfaces can never drift".
**Approved**: pending

**Decision**: The first row of each slug is the only one offered.
**Rationale**: From `firstWorkspacePerSlug`'s doc comment: the hub resolves
a bare `/<slug>` with the first matching row of a priority-ordered list,
"so of the rows sharing a slug only the first can ever be opened. Offering
the others lists a row that opens its namesake, and a menu that marks the
current row by slug highlights all of them at once."
**Approved**: pending

**Decision**: The preference row is one shared item-cache entry with a
constant id, and its browser-cache seed is read on every render.
**Rationale**: From the doc comments: "two keys would let a pick in the
header leave `/home` resolving the old preference from its cache"; the id is
constant because the item hook's tenant scoping "already separates one
signed-in caller from the next". The seed is read each render because "the
cache is written by sign-in, sign-out and other tabs over this hook's
lifetime, and a copy taken at mount would keep showing a previous session's
slug".
**Approved**: pending

**Decision**: A failed preference write is dropped silently.
**Rationale**: From `choose`'s doc comment and the catch: "A failed PUT
leaves the choice standing locally; it is retried by the next pick, not by
this call", and "Silent, deliberately: the caches already carry the
choice."
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.idempotent-operations](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b476dbc7-de81-5f6b-8d9e-de6d319e631b) | passed | Reliability |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | partial | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` passes: `workspace-rows.ts` holds only pure row
helpers, `use-workspaces.ts` only the every-row read state and its
subscription, and `use-workspace-preference.ts` only the preference read
state; the client, keys, storage and endpoints stay in Resource Data.
`unit-test-coverage` passes: `use-workspaces.test.tsx`,
`workspace-rows.test.ts` and `use-workspace-preference.test.tsx` hold a test
for every vector above. `explicit-error-handling` passes: a failed every-row
read reaches the caller on the query result, a failed preference read
settles the state, and the one swallowed failure (the preference write) is a
documented decision. `graceful-degradation` passes: the preference shows the
browser-cache seed before and without the server row, and the label helper
never yields an empty name. `idempotent-operations` passes: recording the
same slug twice leaves the same caches and server row, and one announcement
is one invalidation per client however many readers are mounted.
`secure-storage` is partial: the preferred slug sits in plaintext browser
storage; it is not a credential. `data-minimization` passes: only slug,
name and type are read. `no-hardcoded-strings` fails: the two label
fallbacks are English literals with no catalog (see Localization).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-25 | Mike Fullerton | Initial recipe: the every-row read state, the workspace preference read state and the row helpers moved from the hub. |
