---
id: 31c4c156-8f47-4ad1-9b40-e4ab2d7f4fb7
title: "Hidden Items Store"
type: ingredient
version: 0.1.3
status: draft
language: en
created: 2026-11-15
modified: 2026-11-23
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The standalone database that keeps the browser's two hidden-item lists, the user's distracting items and the agent's excluded elements, apart, matches them to pages site-wide, and answers which selectors are in force for a page."
platforms:
  - swift
  - macos
tags:
  - browser
  - privacy
  - hidden-items
  - persistence
  - sqlite
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserHiddenItem.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserHiddenItemsStore.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserHiddenItemsStoring.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserStoreChanges.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserWindowsFeature.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserHistoryStore.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Privacy/PrivacySitePattern.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKDatabaseTests/Browser/BrowserHiddenItemsStoreTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Hidden Items Store

## Overview

This component keeps the web browser's hidden-item lists. There are two
lists with the same shape, kept apart: the **user list** ("Hide distracting
items"), which holds what the user does not want to see, and the **agent
list** ("Hide elements from agent"), which holds what an agent must not
receive. Each entry names a site (a site pattern, by default the page's host
and every path under it), a CSS selector, whether the selector picks one
item or all items like it, a short human label captured when the item was
picked, whether the entry is enabled, and when it was created. An entry
applies site-wide: to every page whose address matches its site pattern.

Per site, the user list also has a "Hide distracting items" switch, on by
default, that turns the whole user list off for that site without deleting
any entry. The agent list has no such switch.

The store's main question is "which selectors are in force on this page for
this list", which the rendering of the user list and the agent gatekeeper
both ask. It announces every change so a page showing can be brought up to
date. Everything lives in its own SQLite file, `BrowserHiddenItems.db`, in
the app's home directory, which follows the test home override so a scratch
run never touches the real lists.

## Behavioral Requirements

- **two-separate-lists**: The store MUST keep the user list and the agent
  list apart: an entry belongs to exactly one list, and every query MUST
  name a list and MUST return only that list's entries, so an agent-list
  entry never appears in a user-list answer and the reverse.
- **entry-fields**: The store MUST record for every entry an identifier
  assigned by the store, its list, its site pattern, its CSS selector, its
  scope (this item, or all items like it), its label, whether it is
  enabled, and its creation time, and MUST return all of them unchanged
  when the entry is read back.
- **default-site-pattern**: Where an entry is created from a page, its site
  MUST default to the site pattern derived from that page's address by the
  shared site-pattern rules: the page's host followed by `/*`, or the
  everywhere pattern `*` for a page with no host.
- **site-wide-matching**: An entry MUST apply to a page if and only if its
  site pattern matches the page's address under the shared site-pattern
  matching rules; a page on another host MUST NOT receive it, and a page
  with no address MUST receive only entries whose site is `*`.
- **items-include-disabled**: Listing a list's items for a page MUST return
  every entry of that list whose site matches the page, enabled and
  disabled alike, so a caller can show and toggle disabled entries.
- **enabled-selectors-only-enabled**: Asking for a list's enabled selectors
  for a page MUST return the selectors of exactly the entries of that list
  that match the page and are enabled; a disabled entry's selector MUST NOT
  be returned.
- **add-returns-stored-entry**: Adding an entry MUST store it and return it
  with its newly assigned identifier, and the entry MUST be returned by
  subsequent queries for a matching page.
- **set-enabled**: Setting an entry's enabled state MUST change only that
  entry's enabled flag, leaving the entry and its other fields in place.
- **remove-entry**: Removing an entry MUST delete it, so no later query
  returns it.
- **site-switch-defaults-on**: The per-site "Hide distracting items" switch
  MUST read as on for any list and site for which it has never been set.
- **site-switch-off-empties-user-list**: While the user list's switch for a
  site is off, asking for the user list's enabled selectors for a page
  matching that site MUST return none, and the user list's entries for that
  site MUST remain stored, unchanged, so turning the switch back on
  restores them.
- **site-switch-persists**: Setting a site switch MUST be stored, so the
  value set is the value read afterwards, including after the store is
  reopened.
- **agent-list-ignores-site-switch**: The agent list MUST have no site
  switch in effect: its enabled selectors for a page MUST be returned
  whatever any switch for that site says.
- **change-notification**: Every change to stored state (adding, enabling
  or disabling, removing an entry, and setting a site switch) MUST post the
  store's change notification after the change is stored, so a page showing
  can be re-rendered.
- **persists-across-reopen**: Entries and site switches MUST survive
  closing and reopening the store's file, so a hidden-item list survives
  reloads and relaunches.
- **standalone-file**: The store MUST keep its data in its own SQLite file
  named `BrowserHiddenItems.db`, separate from every other database (not a
  migration of the project database), so the file can be deleted without
  touching anything else.
- **file-in-app-home**: The store's default file location MUST be the app's
  home directory (`~/.agenticdeveloperkitchen/BrowserHiddenItems.db`), and
  MUST follow the test home override (`APP_TEST_HOME`) when one is set.
- **opened-at-launch**: The browser feature MUST open the store once at
  launch and share that one store with every pane, in the same way the
  browser history store is opened. The open MUST run off the main thread,
  and a read of the shared store made before the open finishes MUST wait
  for it rather than answer that there is no store, so a consumer that
  fails closed on no store (the agent gatekeeper) never runs ahead of the
  open. A reader that can run during launch (an engine's first read, the
  pane's toolbar actions, an agent view's page read) MUST await the open
  rather than block the main thread on it; an open that fails MUST answer
  no store.

## Appearance

Not applicable — this is a persistence component, not a visual component.
The popover that lists and toggles a site's entries is the element picker's
concern.

## States

Not applicable — this is a persistence component, not a visual component.
Its only lasting state is the rows in its file; the site switch's on/off
value is stored data, not a UI state machine.

## Accessibility

Not applicable — this is a persistence component, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hidden-items-store-001 | add-returns-stored-entry, site-wide-matching | Add a user-list entry with site `example.com/*`, selector `.ad`; list user items for `https://example.com/a` and for `https://other.com/` | The added entry is returned with a non-nil identifier; `example.com/a` lists it; `other.com` lists nothing |
| hidden-items-store-002 | two-separate-lists | Add an agent-list entry with site `example.com/*`, selector `#secret`; list user items and enabled user selectors for `https://example.com/` | Neither answer contains the agent entry; listing agent items for the same page returns it |
| hidden-items-store-003 | entry-fields | Add an entry with every field set (list agent, site `foo.com/hi/*`, selector `div.x`, scope all items like it, label `div "Sponsored"`, enabled false, a fixed creation time); read it back | Every field equals what was added, plus the assigned identifier |
| hidden-items-store-004 | default-site-pattern | Create an entry from the page `https://News.Example.com/story/1`; then from a page with no host (`about:blank`) | Site is `news.example.com/*`; then `*` |
| hidden-items-store-005 | site-wide-matching | A user entry with site `*` and one with site `example.com/*`; list user items for a place with no address | Only the `*` entry |
| hidden-items-store-006 | items-include-disabled, enabled-selectors-only-enabled | Two user entries on `example.com/*`, `.a` enabled and `.b` disabled; list items and enabled selectors for `https://example.com/` | Items: both. Enabled selectors: `[".a"]` |
| hidden-items-store-007 | set-enabled | Disable `.a` from vector 006, then re-enable it | After disabling, enabled selectors are `[]` and items still list `.a` with all other fields unchanged; after re-enabling, enabled selectors are `[".a"]` |
| hidden-items-store-008 | remove-entry | Remove `.a` from vector 006; list items for `https://example.com/` | Only `.b` |
| hidden-items-store-009 | site-switch-defaults-on | Read the user switch and the agent switch for `example.com/*` on a fresh store | Both on |
| hidden-items-store-010 | site-switch-off-empties-user-list | Enabled user entry `.a` on `example.com/*`; set the user switch for `example.com/*` off; ask enabled user selectors, list user items; set it on; ask again | Off: selectors `[]`, items still list `.a`. On again: selectors `[".a"]` |
| hidden-items-store-011 | agent-list-ignores-site-switch | Enabled agent entry `#s` on `example.com/*`; set the user switch and the agent switch for `example.com/*` off; ask enabled agent selectors for `https://example.com/` | `["#s"]` |
| hidden-items-store-012 | change-notification | Observe the change notification; add, disable, remove an entry and set a site switch | Exactly one notification per change, each posted after the change is readable from the store |
| hidden-items-store-013 | persists-across-reopen, site-switch-persists | Add two entries and set a site switch off; close the store; reopen the same file | The same entries, field for field, and the switch still off |
| hidden-items-store-014 | standalone-file, file-in-app-home | Read the store's default location with no test home override | `~/.agenticdeveloperkitchen/BrowserHiddenItems.db`, a file of its own, not the project database |
| hidden-items-store-015 | file-in-app-home | Read the default location with `APP_TEST_HOME` set to a scratch directory | `BrowserHiddenItems.db` under the scratch home's app directory, never the real home |
| hidden-items-store-016 | opened-at-launch | Launch the browser feature and open two browser panes | One store is opened at launch and both panes answer from it (an entry added through one is in force in the other) |
| hidden-items-store-017 | opened-at-launch | Start `openCurrent` on a valid file and read `current` at once on the main actor | The read waits and returns the opened store, never nil; `hasCurrent` is true before the open finishes |
| hidden-items-store-018 | opened-at-launch | Start `openCurrent` on a path that cannot be opened; read `current` | The read returns nil and `onFailure` is called with the error |
| hidden-items-store-019 | opened-at-launch | Start `openCurrent` on a valid file and await `currentStore()` at once; repeat on a path that cannot be opened | The first await returns the opened store; the second returns nil |

## Edge Cases

- **Null and empty input**: A page with no address matches only entries
  whose site is `*` (MUST, see `site-wide-matching`, vector 005). A list
  with no entries for a page answers an empty list of items and an empty
  list of selectors, never an error. An entry with an empty selector is
  never stored: the picker refuses a pick with no selector before it reaches
  the store, and the store also refuses to add an entry whose selector is
  empty after trimming (a builder's choice, see Design Decisions).
- **Boundary values**: A site switch that has never been set reads as on
  (MUST, see `site-switch-defaults-on`). Many entries on one site are all
  returned; no cap is imposed by this component.
- **Concurrent access**: Several app copies (Debug builds) and several
  panes share one file. The store sits on the toolkit's bounded database
  pool (one writer, pooled readers, a deadline on every statement), so
  concurrent readers and a writer are safe; the last write wins for a site
  switch.
- **Error states**: A file that cannot be opened or a statement that fails
  or times out throws to the caller. The store never answers a failed read
  with a guessed list; what the caller does with the failure is the
  caller's concern (the agent gatekeeper fails closed). A file that cannot
  be opened at launch leaves the app with no store, a degraded mode rather
  than a launch failure.
- **Read during the launch open**: The launch open runs off the main
  thread; a read of the shared store before it finishes waits for it
  (awaiting, never blocking the main thread, for a caller that can run
  during launch) and gets the store, or no store if the open failed, never
  a premature no store (MUST, see `opened-at-launch`).
- **Offline or disconnected state**: Not applicable — the store is a local
  file and makes no network call.
- **Missing file or unreachable server**: A missing file is created, with
  its directory, on first open; deleting it loses both lists and every site
  switch and nothing else (MUST, see `standalone-file`).
- **Cancellation and timeouts**: Every statement runs under the database
  pool's deadline, so a wedged file throws rather than hanging the pane.
- **Site pattern edited after creation**: An entry's site is stored as
  text and matched at query time, so a page is matched against the current
  site pattern, never a cached host.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| store file location | file URL | `<app home>/BrowserHiddenItems.db` | Where the store's SQLite file lives; the app home follows `APP_TEST_HOME`. |
| site switch (per list and site) | boolean | on | The user list's "Hide distracting items" switch for one site; stored, not a setting. The agent list's value is ignored. |

## Deep Linking

Not applicable: this component defines no URL scheme, route, or navigable
destination.

## Localization

Not applicable: the store produces no user-facing text of its own. An
entry's label is captured from the page at pick time and stored verbatim.

## Accessibility Options

Not applicable: this component renders nothing and reads no accessibility
display setting.

## Feature Flags

Not applicable: this component contains no feature-flag or remote-config
check.

## Analytics

Not applicable: this component emits no analytics or telemetry event.

## Privacy

- **Data collected**: the site patterns, CSS selectors and short labels of
  items the user chose to hide from themselves or from an agent. A label
  is a trimmed piece of the picked element's text and may carry page
  content.
- **Storage**: one local SQLite file in the app's home directory; never
  transmitted, never synced between devices.
- **Retention**: until the user removes the entry or the file is deleted.
- **Agent exposure**: this component is not an agent surface; the agent
  list exists to keep content from agents.

## Logging

Not applicable: the store logs nothing of its own; failures are thrown to
the caller, which logs them where it handles them.

## Platform Notes

- **SwiftUI**: Not applicable as a home; the store imports only Foundation,
  GRDB and the toolkit's database module, so a SwiftUI host would use it
  unchanged.
- **AppKit / UIKit**: The store is in the toolkit's database tier, below
  the browser pane, so a daemon can serve the same lists:
  `BrowserHiddenItemsStore` in
  `Database/Daemon/Browser/BrowserHiddenItemsStore.swift`,
  with the value types `BrowserHiddenItem`, `BrowserHiddenItemList`
  (`user`, `agent`) and `BrowserHiddenItemScope` (`thisItem`, `allLikeIt`)
  in `BrowserHiddenItem.swift`. Consumers hold the protocol
  `BrowserHiddenItemsStoring` (`AnyObject, Sendable`, in
  `BrowserHiddenItemsStoring.swift`), whose operations are all
  `async throws`: `items(list:for:)`, `allItems(list:)`,
  `enabledSelectors(list:for:)`, `isSiteSwitchOn(list:site:)`, `add(_:)`,
  `setEnabled(_:_:)`, `remove(_:)` and `setSiteSwitch(list:site:on:)`, plus
  `changes: AsyncStream<Void>`. The local store conforms with async
  wrappers over its synchronous operations, each run through its `perform`
  off the main thread, and keeps `open(at:)`, `defaultURL` and
  `didChangeNotification`, which is
  `Notification.Name.browserHiddenItemsDidChange` (in
  `BrowserStoreChanges.swift`): every conforming store posts it with itself
  as the object after each committed write, and its `changes` is
  `BrowserStoreChanges.stream(of:from:)` over it. Opened
  through `BoundedDatabase` as `BrowserHistoryStore` is, with tables
  `hidden_item` (index on `(list, site)`) and `site_switch` (primary key
  `(list, site)`) in migration `v1`. Site matching and the default pattern
  are `PrivacySitePattern.matches(_:url:)` and
  `PrivacySitePattern.defaultPattern(for:)`. `WebBrowserWindowsFeature`
  opens it at launch with `BrowserHiddenItemsStore.openCurrent(at:onFailure:)`
  into `BrowserHiddenItemsStore.current`, typed
  `(any BrowserHiddenItemsStoring)?`,
  unless a host or test already set one (`hasCurrent`, which answers without
  waiting). `openCurrent` opens on a global `userInitiated` queue. Callers
  that can run during launch await
  `BrowserHiddenItemsStore.currentStore() async`, which awaits the
  `PendingOpen` in flight (`value()`, resumed in `finish`), answers nil
  when the open failed, and awaits again when a setter or a newer open
  replaced the pending one: `WebKitBrowserEngine`'s hidden-items read (its
  first runs when the engine is made), the pane's
  `openHiddenItemsStore() async` behind its three toolbar actions (each run
  in a `Task`), and the pane's `agentPageSource(engine:) async`, since a
  tab restored into an agent view reads during launch. The blocking
  `current` getter (a main-actor read waits on the `PendingOpen`'s
  `NSCondition`) is for callers after launch only; the one left is
  `BrowserToolSet`'s default `hiddenItems` closure. Setting `current`
  replaces an open in flight. A file that cannot be opened is logged through
  `onFailure` and leaves `current` nil, which every consumer takes as no
  store. A host that keeps the lists elsewhere (a daemon's adapter) sets
  its own `BrowserHiddenItemsStoring` as `current`. Main-actor callers
  await the protocol's operations, so no file access runs on the main
  thread.
- **Compose**: Room or SQLDelight over one database file, two tables of the
  same shape; post changes on a `SharedFlow`.
- **React/Web**: IndexedDB with two object stores; changes announced with
  a `BroadcastChannel` so other tabs re-render.
- **WinUI 3**: Microsoft.Data.Sqlite on a file under the app's local
  folder; changes raised as a .NET event on the store.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/BrowserPane/WebBrowserWindowsFeature.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserHiddenItem.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserHiddenItemsStore.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserHiddenItemsStoring.swift` | unverified |
| macos | `packages/apple/AgenticDeveloperHubSDK/Database/Daemon/Browser/BrowserStoreChanges.swift` | unverified |

## Design Decisions

**Decision**: one store and one file for both lists, with a `list` column,
rather than two stores.
**Rationale**: The two lists have the same shape and are asked the same
question; one implementation keeps them from drifting (`dry`) while the
`list` column and a list argument on every query keep them apart.
**Approved**: pending

**Decision**: a standalone file, `BrowserHiddenItems.db`, not a migration
of the project database.
**Rationale**: A call recorded in the design. A file holding only these
lists can be deleted without a migration touching anything else
(`design-for-deletion`), as the browser history store's own file can.
**Approved**: pending

**Decision**: the site switch lives in its own table keyed by list and
site, with absence meaning on.
**Rationale**: The default needs no row for every site visited, and a
list-keyed switch leaves room to give the agent list a switch later without
a migration; today the agent list's value is ignored.
**Approved**: pending

**Decision**: the store refuses an entry with an empty selector.
**Rationale**: Builder's choice. An empty selector would produce an
invalid rule; the picker already refuses such picks, and the store
enforces it once more at the boundary.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|

Notes: no compliance checks have been run against the code yet.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 0.1.3 | 2026-11-23 | Mike Fullerton | Moved to the database tier behind BrowserHiddenItemsStoring; the launch store is current (openCurrent, currentStore, hasCurrent). |
| 0.1.2 | 2026-11-16 | Mike Fullerton | Opened off the main thread at launch; reads wait for the open; launch-time callers await sharedStore(). |
| 0.1.1 | 2026-11-16 | Mike Fullerton | Implemented: opened at launch into BrowserHiddenItemsStore.shared; an unopenable file leaves no store. |
| 0.1.0 | 2026-11-15 | Mike Fullerton | Initial creation (design-first, from the more privacy features design) |
