---
id: 81cd8a13-b12f-4090-879f-978a563ce88b
title: "Project Database Browser Jars"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The browser_jars half of the project database: jar records, live-pane discovery from saved layouts, and the upgrade that keeps existing panes on the shared jar."
platforms:
  - swift
  - macos
tags:
  - projects
  - persistence
  - sqlite
  - database
  - browser
depends-on: []
related:
  - c212ea39-10e7-4146-89dd-36edb3b3455a
  - ded9b397-958d-437d-8235-48ef85ae7386
references:
  - https://developer.apple.com/documentation/webkit/wkwebsitedatastore
  - https://www.sqlite.org/lang_with.html
approved-by: ""
approved-date: ""
---

# Project Database Browser Jars

## Overview

This is an extension of the project database that holds the browser jar
registry: the `browser_jars` table (created by migration 5) and the queries
that read the saved layout to decide which browser panes still exist. A jar is
one browser storage container (a `WKWebsiteDataStore` identifier), and what
shares it: every browser pane in one worktree's tabs (a worktree jar) or one
pane alone (a pane jar).

It defines three value types and one set of database operations:

- `BrowserJarRecord`: one jar row, whose `id` is the WebKit store identifier
  itself, so the row and the store on disk are named by one value.
- `LiveBrowserPane`: a browser pane still present in a saved layout, with the
  worktree it works in, used by the jar reconciler to tell a jar in use from a
  leftover.
- `BrowserJarRecord.Kind`: `worktree` or `pane`.
- Operations on `ProjectDatabase`: find, insert, relabel, list and delete jar
  rows, read creation dates, list the live panes and live pane ids, and the
  upgrade step `keepExistingBrowserPanesOnTheSharedJar`.

Everything here is non-visual and synchronous. The code that creates the
stores, applies a grace period and deletes leftovers (the registry and
reconciler) lives in the browser pane feature and calls these operations; this
extension owns only the table and the layout queries. The base
`ProjectDatabase` supplies the SQLite connection and the shared `executeBound`,
`forEachRow`, `bindText`, `bindOptionalText` and `columnText` helpers.

## Behavioral Requirements

### BrowserJarRecord

- **jar-id-is-store-id**: A jar record's `id` MUST be the identifier of its
  WebKit data store, so the row and the store cannot drift apart.
- **jar-id-defaults-new**: Constructing a `BrowserJarRecord` without an `id`
  MUST assign a fresh random UUID.
- **jar-label-default-empty**: Constructing a `BrowserJarRecord` without a
  `label` MUST give it an empty label.
- **jar-kinds-persisted-raw**: `Kind` MUST have exactly the cases `worktree` and
  `pane`, and their raw values (`worktree`, `pane`) MUST be what is stored in
  `browser_jars.kind`, where a `CHECK` constraint refuses any other value.
- **jar-equatable-by-fields**: Two records MUST compare equal when every field
  (`id`, `kind`, `repoID`, `worktreePath`, `paneNodeID`, `label`) is equal.
- **jar-pane-node-optional**: A caller MUST set `paneNodeID` for a `pane` jar and
  MUST leave it `nil` for a `worktree` jar; neither the type nor the table
  enforces this (the column is nullable and the initializer takes an optional).
- **jar-label-mutable**: `label` MUST be the only mutable field; it holds the
  last name the jar was shown under so a list can outlive the pane that named it.
- **jar-global-has-no-row**: The shared (global) jar MUST NOT have a row; the
  schema refuses a `global` kind and the global jar uses WebKit's default store.

### LiveBrowserPane

- **pane-standardized-path**: `LiveBrowserPane.standardizedPath(_:)` MUST return
  the standardized file-URL path of its input treated as a directory, and the
  pane at construction and the reconciler reading the layout MUST both use it,
  so a trailing slash never makes one worktree two jars.
- **pane-state-node-id**: `stateNodeID` MUST be `ownerNodeID` when set, otherwise
  `nodeID`.
- **pane-state-key-prefix**: `stateKeyPrefix(_:)` MUST return the prefix unchanged
  when `ownerNodeID` is `nil`, and otherwise the prefix followed by the pane's
  `nodeID` UUID string and a period.
- **pane-own-prefix**: `ownStateKeyPrefix` MUST equal `stateKeyPrefix` of the
  pane's own `statePrefix`.
- **pane-default-prefix**: A `LiveBrowserPane` constructed without a
  `statePrefix` MUST use the default browser state prefix of the composable-tabs
  registry, and without an `ownerNodeID` MUST have `nil` (a layout node itself).
- **pane-hashable**: `LiveBrowserPane` MUST be `Hashable` and `Sendable`, so sets
  of panes can be compared (the tests compare sets).

### Jar rows

- **insert-unique-worktree-jar**: `insertBrowserJar` MUST throw when a second
  worktree jar is inserted for the same repository and worktree path, because
  the unique index refuses it. A worktree jar for another path, or the same path
  in another project, MUST be accepted.
- **insert-unique-pane-jar**: `insertBrowserJar` MUST throw when a second jar is
  inserted for the same pane node id. Many pane jars MAY share one worktree path.
- **insert-loser-reads-winner**: The refusal of a duplicate is the contract that
  lets a caller that lost a race read the winner's row instead; the insert
  itself MUST NOT swallow or retry the error.
- **insert-stamps-created-at**: `insertBrowserJar` MUST store the current time
  as a Unix-epoch double in `created_at`.
- **find-worktree-jar**: `browserJar(worktreeOf:path:)` MUST return the record
  whose kind is `worktree`, repository id equals the argument and worktree path
  equals the argument exactly, or `nil` if none exists.
- **find-pane-jar**: `browserJar(pane:)` MUST return the record whose kind is
  `pane` and `pane_node_id` equals the argument, or `nil` if none exists.
- **relabel-by-id**: `updateBrowserJarLabel(id:label:)` MUST set the label of the
  row with that id; an id with no row changes nothing and does not throw.
- **delete-by-id**: `deleteBrowserJar(id:)` MUST delete the row with that id; an
  id with no row changes nothing and does not throw.
- **list-project-jars-order**: `browserJars(repoID:)` MUST return only that
  project's jars, worktree jars first and then pane jars, each group in
  creation order (the query orders by kind descending, then `created_at`).
- **list-all-jars-order**: `allBrowserJars()` MUST return every jar of every
  project in creation order.
- **creation-dates-by-id**: `browserJarCreationDates()` MUST return a map from
  jar id to its creation date, for the reconciler's grace period.
- **malformed-row-skipped**: NEEDS REVIEW: Not implemented in source. A row the code cannot read is dropped from the result with no throw and no log (a `browser_jars` row whose `id` or `repo_id` is not a UUID string, which the table does not forbid; a live-node row whose node id, repo id or worktree cannot be read); the schema's `NOT NULL` and `CHECK` constraints make a null path or unknown kind unreachable in `browser_jars`, so the open point is whether a silent skip is acceptable or a log line or error is wanted; evidence to settle it is how the reconciler treats a jar store whose row is skipped.
- **statement-failure-throws**: When a statement cannot be prepared, the
  operation MUST throw `ProjectDatabaseError.prepareFailed`, and when a step
  fails (a duplicate insert, a read error) it MUST throw
  `ProjectDatabaseError.executionFailed`, each carrying the SQLite error
  message.
- **operations-throw-on-failure**: Every operation here is `throws` and MUST
  surface the database's error to the caller rather than returning a default.

### Live pane discovery

- **live-layout-is-authority**: `liveBrowserPanes()` MUST treat `layout_nodes`
  (walked from each saved tab's root node) as the authority for which panes
  exist, not `pane_state`, so a fresh pane that has never written a state row is
  still listed.
- **live-leaves-only**: A layout leaf MUST count as a browser pane only while its
  `content_type` equals the engine's view id; a leaf whose content changed to
  something else MUST NOT count.
- **live-worktree-from-tab**: A pane's worktree MUST be its tab's
  `working_directory`, or the repository's own path (`git_repo.path`) when the
  tab's directory is null or empty, then standardized.
- **live-all-engines**: `liveBrowserPanes()` MUST list the panes of every
  `BrowserEngineKind`, since a Chrome pane holds a jar exactly as a Safari pane
  does, and MUST list a node id once even if more than one engine matches it.
- **live-nested-by-state-key**: `liveBrowserPanes(contentType:statePrefix:)` MUST
  also list a browser nested inside another pane, found by a `pane_state` key
  under a live node that begins with the state prefix followed by a UUID; the
  nested pane MUST carry the enclosing node as `ownerNodeID`, and a UUID equal
  to the owner's own id MUST NOT count as nested.
- **live-nested-needs-state**: A nested pane that has written no state row MUST
  NOT be listed; while it is open the registry's in-use set covers it.
- **live-ids-include-any-key-uuid**: `livePaneNodeIDs()` MUST return the node ids
  of the live browser panes plus every UUID found in any period-separated
  component of any `pane_state` key under a live node, of any pane type, because
  keeping a jar a little too long is cheap and deleting one a live pane holds
  signs the user out.
- **live-deduplicated**: A pane found as a leaf and again by a state key MUST be
  listed once.

### Upgrade

- **upgrade-pins-existing-panes-global**: `keepExistingBrowserPanesOnTheSharedJar()`
  MUST, for every live browser pane, write the storage-jar setting with the
  value `[global]` (a JSON-encoded array holding the global jar) into the
  pane's own state, in the shape the pane's settings sheet writes, so the sheet
  shows it as an override that the user can revert.
- **upgrade-keeps-existing-override**: A pane that already has a value for the
  storage-jar setting MUST keep it unchanged.
- **upgrade-index-merged**: The pane's index of overridden setting names (a JSON
  array of strings) MUST gain the storage-jar setting name only if it is absent,
  and MUST keep the names already present; running the upgrade twice MUST leave
  one entry (idempotent).
- **upgrade-fresh-database-noop**: On a database with no saved panes the
  upgrade MUST write nothing, so new panes keep the setting's default (a jar per
  pane).
- **upgrade-corrupt-index-reset**: An override index that is present but not a
  decodable JSON string array is treated as empty and rewritten to contain only
  the storage-jar name; the previous content is not preserved.
- **upgrade-keys-by-owner**: The state rows for a nested pane MUST be written under
  its `stateNodeID` (the owner) with its own key prefix, and for a layout-node
  pane under its own node id.

### Isolation

- **not-sendable-store**: The extension adds no isolation: `ProjectDatabase` is a
  `public final class` with no `Sendable` conformance and no actor isolation,
  so every call MUST be made from one thread or queue at a time by the caller.
  `BrowserJarRecord`, `BrowserJarRecord.Kind` and `LiveBrowserPane` are `Sendable`
  values.

## Appearance

Not applicable — this is a database extension and a set of value types, not a
visual component.

## States

Not applicable — this is a database extension, not a visual component. The only
lifecycle it has is a jar row's existence: absent, then present after
`insertBrowserJar`, then absent after `deleteBrowserJar`, with the label
mutable while present.

| State | Appearance change |
|-------|------------------|
| Default | Not applicable: no visual surface |

## Accessibility

Not applicable — this is a persistence layer, not a visual component; it has no
controls, labels or focus behavior.

## Conformance Test Vectors

Derived from `BrowserJarTests.swift` in the macOS test target where a test
exists (its name is in the Requirements column); a row with no test named is
derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| jars-001 | insert-unique-worktree-jar, insert-unique-pane-jar, jar-global-has-no-row (`testTheSchemaRefusesDuplicateJarsAndUnknownKinds`) | Insert worktree jar for repo R at `/a`, then again | Second insert throws; a worktree jar at `/b`, and one at `/a` in another repo, are accepted |
| jars-002 | insert-unique-pane-jar (same test) | Insert pane jar for node N, then again for N, then a pane jar for a new node at the same path | Second throws; third succeeds |
| jars-003 | jar-global-has-no-row, jar-kinds-persisted-raw (same test) | Execute an `INSERT` with kind `global` | Throws (the `CHECK` constraint) |
| jars-004 | find-worktree-jar, find-pane-jar, relabel-by-id, delete-by-id, list-project-jars-order, list-all-jars-order (`testRecordsRoundTripAndRename`) | Insert a pane jar then a worktree jar in repo R; list, find, relabel the pane jar to `Docs`, delete it | `browserJars` returns `[worktree, pane]`; finds equal the records; label reads `Docs`; after delete `browserJar(pane:)` is `nil` and `allBrowserJars` is `[worktree]` |
| jars-005 | live-layout-is-authority, live-leaves-only, live-worktree-from-tab, live-ids-include-any-key-uuid (`testLiveBrowserPanesFollowTheSavedLayout`) | Tab with working directory W holds a split of a browser leaf and an editor leaf; second tab with none holds a browser leaf | Live panes are the two browser leaves, with W and the repository path (both standardized); `livePaneNodeIDs` is those two ids |
| jars-006 | upgrade-pins-existing-panes-global, upgrade-index-merged (`testAnUpgradeKeepsExistingBrowserPanesOnTheSharedJar`) | File from before jars (table dropped, migration 5 row deleted) with one saved browser pane; reopen; run the upgrade again | Schema version is 5; the pane has the storage-jar override equal to global; the index holds the name once |
| jars-007 | upgrade-fresh-database-noop (`testAFreshDatabaseLeavesNewPanesOnTheirOwnJar`) | Fresh database with a saved browser pane, reopened | No storage-jar override for the pane; the setting's default is `pane` |
| jars-008 | upgrade-keeps-existing-override | Pane already has a storage-jar value (for example `pane`); run the upgrade | Value unchanged; the name is added to the index only if missing |
| jars-009 | pane-standardized-path | `standardizedPath("/tmp/wt/")` and `standardizedPath("/tmp/wt")` | Equal strings |
| jars-010 | pane-state-key-prefix, pane-state-node-id | Pane with owner O and node N, prefix `p.` | `stateNodeID` is O; `stateKeyPrefix("p.")` is `p.` + N + `.`; with no owner it is `p.` and the node id is N |
| jars-011 | live-nested-by-state-key, live-nested-needs-state (`testANestedBrowserPaneIsLiveWhileItsOwnerIs`) | Live node O has a state row whose key is the prefix + nested UUID + `.url` | A pane for the nested id is listed with owner O; with no state row it is not listed |
| jars-012 | live-ids-include-any-key-uuid | A state key under a live node contains a UUID of any pane type | `livePaneNodeIDs` contains that UUID (the reconciler side is `testAPaneJarIsKeptForAPaneKnownOnlyByAStateKey`, which keeps a pane jar whose node id is in the live node ids) |
| jars-013 | creation-dates-by-id, insert-stamps-created-at | Insert a jar; read the dates | The map has the jar id with a date near now |
| jars-014 | upgrade-corrupt-index-reset | Pane's override index holds the text `not json` | After the upgrade the index is `["<storage-jar name>"]` |
| jars-015 | malformed-row-skipped | A `browser_jars` row with a `repo_id` that is not a UUID is inserted by raw SQL | The record queries return no record for it and do not throw |

## Edge Cases

- **Null and empty input**: A tab with a null or empty `working_directory` falls
  back to the repository path (MUST). An empty label is valid and is the default.
  A `nil` `paneNodeID` is stored as null (MUST for a worktree jar). A key with no
  period after the prefix, or with a non-UUID first component, is not a nested
  pane (MUST).
- **Boundary values**: An empty database returns empty lists and maps and an
  upgrade that writes nothing (MUST). A state key that is exactly the prefix
  has no UUID and is ignored (MUST).
- **Concurrent access**: The store is not `Sendable`; callers serialize
  access (see the requirement on isolation). Two callers racing to make the same
  jar are resolved by the unique indexes: one insert throws and that caller reads
  the winner's row (MUST). The upgrade's row writes are separate statements with no
  transaction of their own; migration 5 calls it inside the migration chain's
  single transaction, so they roll back with the migration, while a direct call
  (as the test makes) is not wrapped.
- **Error states**: A statement that fails to prepare throws
  `prepareFailed` with the SQLite message (MUST). A duplicate insert throws and
  the row is unchanged (MUST). Malformed rows are skipped, see the open question
  on `malformed-row-skipped`.
- **Corrupt stored values**: A corrupt override index is rewritten to the single
  storage-jar name (MUST); the previous value is lost.
- **Moved or removed panes**: A pane whose leaf now shows other content stops
  counting as a browser pane while keeping its node id (MUST); its jar becomes a
  leftover for the reconciler.
- **Nested panes**: A nested browser that has written no state is invisible to
  these queries (MUST); the registry's in-use set covers it while it is open.
- **Offline or disconnected state**: Not applicable: local SQLite only, with no
  network.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `kind` | `BrowserJarRecord.Kind` | none (required) | `worktree` or `pane` |
| `label` | `String` | empty | Last name the jar was shown under |
| `id` | `UUID` | new random UUID | The WebKit store identifier |
| `statePrefix` | `String` | the composable-tabs registry's browser state prefix | Where an engine files its pane state |
| `ownerNodeID` | `UUID?` | `nil` | Layout node a nested pane files its rows under |

The storage-jar setting name, its `global` value and the settings-key shape
come from `BrowserStorageJar` and `PaneStateSettingsStorageProvider`, injected
by the surrounding module.

## Deep Linking

Not applicable: no screen or URL; the source has no deep-link handling.

## Localization

Not applicable: no user-facing string. A jar's `label` is a stored name supplied
by the caller.

## Accessibility Options

Not applicable: nothing is drawn or animated.

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source records no analytics event.

## Privacy

- **Data collected**: Jar rows hold a project id, a worktree path, an optional
  pane id, a label and a creation time. The labels and paths can reveal what the
  user works on. The jar itself identifies where cookies and site data live, and
  the upgrade exists to stop signing the user out of every site.
- **Storage**: The project database (SQLite) on the local disk; the site data
  lives in WebKit's store named by the jar `id`, outside this file.
- **Transmission**: None through this code.
- **Retention**: A row lives until `deleteBrowserJar` is called by the
  reconciler or a user action; this extension applies no expiry of its own.

## Logging

Not applicable: the source makes no log call in this extension; failures throw
and malformed rows are skipped silently (see the open question on
`malformed-row-skipped`).

## Platform Notes

- **SwiftUI**: Nothing here is a view; a SwiftUI app calls these operations from a
  model object off the main actor or behind one actor, and may wrap the list in
  an `ObservableObject` for a settings screen. Replace `WKWebsiteDataStore`
  identifiers with the same-named store API.
- **Compose**: Use a Room entity with a unique index on repository plus path
  filtered to `kind = 'worktree'` (a partial index via a raw migration) and a
  unique index on the pane id, a `CHECK` on kind, and `Flow` queries ordered
  by kind descending then created time. The jar identifier maps to an Android
  WebView profile or data directory name (`WebViewCompat` profiles).
- **React/Web**: A browser has no jar concept per pane; an Electron or Tauri
  port maps jars to named partitions (`session.fromPartition`) with the row
  held in SQLite (`better-sqlite3`) using the same unique-index race rule.
- **AppKit / UIKit**: Source file:
  `macOS/Features/Projects/ProjectDatabase+BrowserJars.swift`, using the
  `SQLite3` C API through the base class's helpers, a recursive common table
  expression (`liveNodesCTE`) over `project_tabs`, `layout_nodes` and `git_repo`
  to walk each tab, and `WKWebsiteDataStore` identifiers as jar ids (macOS 14
  and later). UIKit has the same store API; the layout tables are shared.
- **WinUI 3**: Use `Microsoft.Data.Sqlite` with a `SqliteConnection` and
  parameterised `SqliteCommand`s; the table needs a `CHECK (kind IN
  ('worktree','pane'))`, a partial unique index for worktree jars and a unique
  index on `pane_node_id`; translate the live-node query as the same
  `WITH RECURSIVE` statement. `BrowserJarRecord` becomes a `record` with a
  `Guid Id`; `LiveBrowserPane` a `record` (value equality gives set
  comparison); `standardizedPath` becomes `Path.GetFullPath` with
  trailing-separator trimming. A jar maps to a WebView2 user data folder or
  `CoreWebView2Profile` (`CoreWebView2ControllerOptions.ProfileName`) named by
  the id. Unique-index violations surface as `SqliteException` (error code
  19), which replaces the thrown error the source relies on; `SqliteConnection`
  is not thread-safe, so serialise access as the source requires.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Projects/ProjectDatabase+BrowserJars.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: A jar row's `id` is the WebKit store identifier.
**Rationale**: The source comment (`dry`) says the row and the store on disk are
named by one value and cannot drift apart.
**Approved**: pending

**Decision**: Duplicate jars are refused by unique indexes, and the insert throws
instead of checking first.
**Rationale**: The `insertBrowserJar` comment says this lets a caller that lost a
race read the winner's row, so no lock is needed.
**Approved**: pending

**Decision**: `layout_nodes` is the authority for live panes, not `pane_state`.
**Rationale**: The source comment says `saveTabs` rewrites it to exactly the
panes that exist and prunes `pane_state` by it, and a pane that has not yet
written state is still a pane.
**Approved**: pending

**Decision**: `livePaneNodeIDs` counts every UUID in any state key under a live
node, of any pane type.
**Rationale**: The source comment says keeping a jar a little longer than needed
is cheap and deleting one a live pane holds signs the user out.
**Approved**: pending

**Decision**: Worktree paths are keyed through one standardizing function.
**Rationale**: The source comment says a trailing slash would otherwise make one
worktree two jars.
**Approved**: pending

**Decision**: The upgrade pins existing panes to the global jar through the same
pane-state shape the settings sheet writes, and is idempotent.
**Rationale**: Before jars every pane used WebKit's default store and the
setting now defaults to a jar per pane; without the upgrade, restored panes
would sit on an empty store and sign the user out of every site. Writing the
sheet's own shape lets the user revert it, and merging the index (not replacing
it) makes a second run safe.
**Approved**: pending

**Decision**: Rows that fail to decode are skipped without a signal.
**Rationale**: This is how the source behaves (guard-and-return in every row
callback). It is recorded as an open question on `malformed-row-skipped`, not
approved behavior.
**Approved**: pending

**Decision**: A nested browser that has written no state is not listed.
**Rationale**: The source comment says the registry's in-use set covers it while
it is open; the database cannot see it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |

The extension owns only the jar table, its value types and the layout queries;
connection setup, migrations and the SQL helpers stay in the base database, and
the creation and deletion of the stores stays in the registry and reconciler,
so it meets separation-of-concerns. `BrowserJarTests.swift` covers the schema's
refusals, the round trip, the live-pane queries, the upgrade and its
idempotency, but no test exercises the malformed-row skip or the corrupt-index
reset, so test coverage is partial. Failures to prepare a statement throw a
typed error, but malformed rows vanish silently (the open question on
`malformed-row-skipped`), so error handling is partial. Unique indexes and a
`CHECK` guard the table, the upgrade merges rather than replaces, and
migration 5 runs it inside the migration chain's single transaction, so data
integrity is met.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
