---
id: 19759edb-a4c1-4b3b-b759-191b4c55ce6a
title: "Project Window Group"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Model of one project window: its ordered active projects, the one on screen, the shelf panel and filter text, plus its persisted state record."
platforms:
  - swift
  - macos
tags:
  - projects
  - windows
  - observable-state
depends-on: []
related:
  - 5bfadad5-c93b-432a-807e-04be57ff16b4
references:
  - https://developer.apple.com/documentation/combine/observableobject
  - https://developer.apple.com/documentation/swift/mainactor
approved-by: ""
approved-date: ""
---

# Project Window Group

## Overview

A project window, as the user sees it, is one window with a list of active
projects and one of them on screen. `ProjectWindowGroup` is the model behind
that window. It holds the ordered list of active repository ids
(`activeRepoIDs`), which one is on screen (`selectedRepoID`), which panel the
window's shelf shows (`panel`) and what each panel's filter field holds
(`filterText`).

Underneath, each active project keeps a window of its own and the group shows
exactly one of them, swapping which one in place, so switching is instant. With
no project active the group shows an empty project window. Every window in the
group has its own shelf and every shelf reads this one object, so the panel,
the active list and the filter text are the same whichever window is on
screen. The window machinery itself (the window controllers, the swap) is
outside this component; this recipe covers the model and its persisted record.

Three types are specified together:

- `ProjectShelfPanel`: the shelf panels (`browser`, `activeProjects`), each with
  a title, an SF Symbol name and a filter placeholder.
- `ProjectWindowState`: one window as persisted (the `UserSettings.projectWindows`
  entry).
- `ProjectWindowGroup`: the live main-actor `ObservableObject`.

## Behavioral Requirements

### ProjectShelfPanel

- **panel-cases**: `ProjectShelfPanel` MUST have exactly the cases `browser` and
  `activeProjects`, `CaseIterable`.
- **panel-raw-values-persisted**: The raw values (`browser`, `activeProjects`) are
  what is persisted, so a new case MUST be added and an existing one MUST NOT
  be renamed.
- **panel-codable**: `ProjectShelfPanel` MUST be `Codable` and `Sendable`.
- **panel-title**: `title` MUST be `Project Browser` for `browser` and
  `Active Projects` for `activeProjects`; it is the button tooltip and the key
  command title.
- **panel-symbol**: `symbol` MUST be the SF Symbol `folder` for `browser` and
  `square.stack.3d.up` for `activeProjects`.
- **panel-filter-placeholder**: The filter placeholder MUST be `Filter Projects`
  for `browser` and `Filter Active Projects` for `activeProjects`; it is shown in
  the bottom filter field while that panel is up. It is internal to the
  module, while `title` and `symbol` are public.
- **panel-more-will-join**: The enumeration is documented as open to additions;
  a consumer MUST NOT assume two cases are the full set.

### ProjectWindowState

- **state-fields**: `ProjectWindowState` MUST carry `id` (`UUID`), `activeRepoIDs`
  (`[UUID]`), `selectedRepoID` (`UUID?`) and `panel`, and MUST be `Codable`,
  `Sendable` and `Equatable`.
- **state-defaults**: Constructing `ProjectWindowState` with no arguments MUST
  produce a fresh random `id`, an empty `activeRepoIDs`, a `nil` `selectedRepoID`
  and `panel` equal to `browser`.
- **state-has-no-filter**: The persisted state MUST NOT contain `filterText`.

### ProjectWindowGroup

- **group-main-actor**: `ProjectWindowGroup` MUST be isolated to the main actor.
- **group-observable**: It MUST be a `final` class, an `ObservableObject` and
  `Identifiable`, with `id` as its identity.
- **group-init-from-state**: Constructing it from a `ProjectWindowState` MUST copy
  `id`, `activeRepoIDs`, `selectedRepoID` and `panel` from that state; with no
  argument it MUST use a default `ProjectWindowState`.
- **group-init-empty-filter**: A newly constructed group MUST have an empty
  `filterText`.
- **group-state-snapshot**: `state` MUST return a `ProjectWindowState` holding the
  group's current `id`, `activeRepoIDs`, `selectedRepoID` and `panel`.
- **group-filter-not-persisted**: `filterText` MUST NOT be part of `state`,
  because a filter is a moment's question and returning to a list already
  narrowed by yesterday's filter reads as projects having gone missing.
- **group-filter-per-panel**: `filterText` MUST be keyed by panel, so each
  panel's field keeps its own text.
- **group-published**: `activeRepoIDs`, `selectedRepoID`, `panel` and `filterText`
  MUST be published properties.
- **group-mutation-access**: `activeRepoIDs` and `selectedRepoID` MUST be
  settable only inside the module (`internal(set)`), while `panel` and
  `filterText` are publicly settable; `activate(_:)`, `deactivate(_:)` and
  `select(_:)` MUST be internal to the module, so only the window manager
  changes the list and selection.
- **group-contains**: `contains(_:)` MUST return `true` exactly when the id is in
  `activeRepoIDs`.
- **activate-appends-after-selected**: `activate(_:)` MUST insert the id
  immediately after the selected project when a selected id exists and is in
  the list, so a project opened from the browser lands next to the one the user
  was working in.
- **activate-appends-at-end**: `activate(_:)` MUST append the id to the end when
  no project is selected or the selected id is not in the list.
- **activate-idempotent**: `activate(_:)` MUST do nothing when the id is already
  in the list (no reorder, no publish).
- **activate-keeps-selection**: `activate(_:)` MUST NOT change `selectedRepoID`.
- **deactivate-removes**: `deactivate(_:)` MUST remove the id from
  `activeRepoIDs` when present.
- **deactivate-absent-noop**: `deactivate(_:)` of an id not in the list MUST
  change nothing and MUST return the current `selectedRepoID`.
- **deactivate-not-selected**: Deactivating a project that is not the selected one
  MUST return the current `selectedRepoID`.
- **deactivate-selected-next**: Deactivating the selected project MUST return the
  project that followed it in the list, or, if it was last, the one before it.
- **deactivate-selected-none**: Deactivating the selected project when no other
  remains MUST return `nil`.
- **deactivate-leaves-selection-to-caller**: `deactivate(_:)` MUST NOT itself change
  `selectedRepoID`; the caller applies the returned id (it is
  `@discardableResult`).
- **select-changes-only-on-difference**: `select(_:)` MUST assign `selectedRepoID`
  only when the new value differs, so equal selections publish nothing.
- **select-accepts-nil**: `select(nil)` MUST clear the selection.
- **selection-not-validated**: The group MUST NOT itself check that `selectedRepoID` is in `activeRepoIDs`: neither the initializer, `select(_:)` nor `activate(_:)` validates it, and the initializer neither de-duplicates nor validates the persisted list. The consistency is the caller's: the window manager selects only a project it has a window for, applies the id `deactivate(_:)` returns, and on restore moves a persisted selection that is not in the filtered active list to the first active project.
## Appearance

Not applicable — this is a model and its persisted record, not a visual
component. The panel buttons, tooltips and filter field that show these values
belong to the project shelf view.

## States

Not applicable — this is a model, not a visual component, so the visual-state
table has one row. The model's runtime states (no active project, one or more
active with one selected, the panel shown) are covered under Behavioral
Requirements.

| State | Appearance change |
|-------|------------------|
| Default | Not applicable: no visual surface |

## Accessibility

Not applicable — this is a model with no controls of its own. The tooltip text
(`title`) and the filter placeholder it supplies are consumed by the shelf
view, which owns accessibility.

## Conformance Test Vectors

The source has no tests beside it and the package's tests do not construct
`ProjectWindowGroup`; the vectors are derived from the source. Repository ids
are written A, B, C, D.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| group-001 | state-defaults, group-init-from-state | `ProjectWindowGroup()` | `activeRepoIDs` is empty, `selectedRepoID` is `nil`, `panel` is `browser`, `filterText` is empty |
| group-002 | activate-appends-at-end | Empty group; `activate(A)`, `activate(B)` | `[A, B]` |
| group-003 | activate-appends-after-selected | Active `[A, B, C]`, selected A; `activate(D)` | `[A, D, B, C]` |
| group-004 | activate-idempotent | Active `[A, B]`; `activate(A)` | `[A, B]`, nothing published |
| group-005 | deactivate-selected-next | Active `[A, B, C]`, selected B; `deactivate(B)` | Returns C; list `[A, C]`; `selectedRepoID` still B |
| group-006 | deactivate-selected-next | Active `[A, B, C]`, selected C; `deactivate(C)` | Returns B; list `[A, B]` |
| group-007 | deactivate-selected-none | Active `[A]`, selected A; `deactivate(A)` | Returns `nil`; list empty |
| group-008 | deactivate-not-selected | Active `[A, B]`, selected A; `deactivate(B)` | Returns A; list `[A]` |
| group-009 | deactivate-absent-noop | Active `[A]`, selected A; `deactivate(D)` | Returns A; list unchanged |
| group-010 | group-state-snapshot, group-filter-not-persisted | Group with filter text set for `browser`; read `state` | State has the four fields; no filter text |
| group-011 | panel-title, panel-symbol, panel-filter-placeholder | Read all three for each case | `Project Browser`/`folder`/`Filter Projects` and `Active Projects`/`square.stack.3d.up`/`Filter Active Projects` |
| group-012 | panel-raw-values-persisted, panel-codable, state-fields | Encode a `ProjectWindowState` with panel `activeProjects`, decode | Equal state; encoded panel is `activeProjects` |
| group-013 | select-changes-only-on-difference | Subscribe to `$selectedRepoID`, `select(A)` twice | One new value after the subscription's first |
| group-014 | selection-not-validated | `select(D)` where D is not active | `selectedRepoID` becomes D (no check) |
| group-015 | activate-appends-at-end | Active `[A]`, selected D (not in list); `activate(B)` | `[A, B]` |

## Edge Cases

- **Null and empty input**: An empty list: `deactivate` of anything returns the
  current selection; `activate` appends (MUST). A `nil` selection makes
  `activate` append at the end (MUST). `select(nil)` clears (MUST).
- **Boundary values**: Deactivating the last element of the selected project
  picks the one before; the first picks the new first; the only one returns
  `nil` (MUST). The index is clamped with `min(index, count - 1)`.
- **Duplicates**: `activate` never creates a duplicate; the initializer accepts
  whatever list the state holds, including duplicates, without checking (see
  the requirement `selection-not-validated`).
- **Concurrent access**: Main-actor isolated, so all access and every change is
  serialized on one actor (MUST). Callers off the main actor hop first.
- **Error states**: No operation throws or returns an error; an unknown id is
  handled as a no-op or a returned selection (MUST).
- **Selection drift**: `deactivate` returns the next selection but does not apply
  it; a caller that ignores the return leaves `selectedRepoID` pointing at a
  project no longer in the list.
- **Offline or disconnected state**: Not applicable: no network or file access.
  Persistence is the caller's, through `state` and `UserSettings.projectWindows`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `state` | `ProjectWindowState` | fresh state | Initial `id`, `activeRepoIDs`, `selectedRepoID` and `panel` |
| `panel` | `ProjectShelfPanel` | `browser` | The shelf panel on screen |
| `filterText` | `[ProjectShelfPanel: String]` | empty | Filter text per panel, not persisted |

## Deep Linking

Not applicable: the model has no URL or screen; the source has no deep-link
handling.

## Localization

The panel titles and filter placeholders are hardcoded English strings in
`ProjectShelfPanel`, not looked up through a localization table.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | Project Browser | Button tooltip and key command title for `browser` |
| none (literal) | Active Projects | Button tooltip and key command title for `activeProjects` |
| none (literal) | Filter Projects | Filter field placeholder, `browser` panel |
| none (literal) | Filter Active Projects | Filter field placeholder, `activeProjects` panel |

## Accessibility Options

Not applicable: the model draws and animates nothing.

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source records no analytics event.

## Privacy

- **Data collected**: Repository ids and a selection; the filter text a user
  types is held in memory.
- **Storage**: `state` is what the owner persists (`UserSettings.projectWindows`);
  the filter text is deliberately never stored.
- **Transmission**: None through this code.
- **Retention**: Until the owner removes the window state; this type applies no
  expiry.

## Logging

Not applicable: the source makes no log call.

## Platform Notes

- **SwiftUI**: Hold the group as an `@StateObject` or `@ObservedObject` and read
  `activeRepoIDs` for a list and `selectedRepoID` for the selection;
  `ProjectShelfPanel` maps to a `Picker` or a toolbar of buttons using the
  `symbol` name with `Image(systemName:)`. A `NavigationSplitView` is the
  native shape, though the source swaps whole windows instead of views.
- **Compose**: A `ViewModel` with `MutableStateFlow` for the list, selection
  and panel and a `Map` flow for filter text; `activate` and `deactivate` become
  pure functions on an immutable list. Use `NavigationRail` or a `TabRow` for the
  panels, with icon names mapped from the SF Symbols.
- **React/Web**: A store (reducer or Zustand) with `activeRepoIDs`,
  `selectedRepoID`, `panel` and a `filterText` record; persist only the
  state without `filterText`. Panels become tabs (`role="tablist"`).
- **AppKit / UIKit**: Source file:
  `macOS/Features/Projects/ProjectWindowGroup.swift`, consumed by the project
  shelf and active-projects view controllers, the window manager and the
  composable-tabs window controllers (the group shows exactly one project
  window by ordering one in and another out). `@MainActor` and
  `ObservableObject` come from Combine; SF Symbols need macOS 11 or iOS 13.
- **WinUI 3**: A view-model class using `CommunityToolkit.Mvvm`
  (`ObservableObject`) with `ObservableCollection<Guid> ActiveRepoIds`,
  `Guid? SelectedRepoId`, a `ShelfPanel` enum property and a
  `Dictionary<ShelfPanel,string>` for filters; a `record` for the persisted
  state serialised with `System.Text.Json` (use `JsonStringEnumConverter` so
  the persisted names stay `browser` and `activeProjects`). Show panels with a
  `NavigationView` or a `SelectorBar` whose items use `FontIcon` glyphs in place
  of SF Symbols, and the filter with `AutoSuggestBox.PlaceholderText`. WinUI
  requires UI-bound changes on the `DispatcherQueue` thread, replacing the
  main-actor isolation; the group swap becomes showing one `Window` or
  `Frame` content and hiding the others.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Projects/ProjectWindowGroup.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The panel enumeration is persisted by raw value, so cases are added
and never renamed.
**Rationale**: The source comment states that the raw value is what is persisted.
**Approved**: pending

**Decision**: The filter text is held on the group but never persisted.
**Rationale**: The source comment says a filter is a moment's question, and a list
already narrowed by a filter from yesterday reads as projects having gone
missing.
**Approved**: pending

**Decision**: A newly activated project is placed after the one on screen.
**Rationale**: The source comment says a project opened from the browser lands
next to the one the user was working in.
**Approved**: pending

**Decision**: `deactivate` returns the next selection rather than applying it.
**Rationale**: The group cannot swap windows itself; the caller owns the window
change and applies the returned id with `select`. The return prefers the next
project, then the previous one, so the neighbour in the bar takes over.
**Approved**: pending

**Decision**: One group object is read by every window's shelf.
**Rationale**: The source comment says every window in the group has its own shelf
and every shelf reads this object, so the panel, active list and filter are the
same whichever window is on screen.
**Approved**: pending

**Decision**: `select(_:)` assigns only on a difference.
**Rationale**: It avoids publishing an unchanged selection to every subscribed
shelf (inferred from the guard in the source; no comment states the reason).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | partial | reliability |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

The group holds list, selection and panel state and leaves windows, shelf
drawing and persistence to other types, so it meets separation-of-concerns. A
search of the package's tests finds none that construct `ProjectWindowGroup`
or `ProjectShelfPanel`, so unit-test coverage fails and the vectors above are
unasserted. The list, selection and persisted state can disagree because
the group itself does not check that the selected id is in the list (the
requirement `selection-not-validated`); the window manager repairs a persisted
selection on restore, so data integrity is partial. The tooltip titles and
placeholders are English literals, so no-hardcoded-strings fails.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
