---
id: 3edb67d7-f58f-43ed-8bf7-e909662b6aaa
title: "Project Tab Configuration"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-15
modified: 2026-11-15
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The value every project window shares so switching projects keeps the panes' shape and sizes: the pane arrangement only, never the tab edges."
platforms:
  - swift
  - macos
tags:
  - composable-tabs
  - projects
  - layout
  - value-type
depends-on: []
related:
  - 55a394e6-9934-404b-941d-25bebbf71378
  - 7f1b8bef-e78e-4cac-be55-c948fe9062e5
  - 0640ca96-95c5-4234-925e-386425cc4435
references: []
approved-by: ""
approved-date: ""
---

# Project Tab Configuration
## Overview

Project Tab Configuration is the value every project window shares: the pane arrangement of the front tab — the split tree's shape and its divider sizes — taken from the project window the user last worked in. The window manager reads it out of one window (or, when that window is closed, derives it from that project's stored tabs) and hands it to the next window that comes forward, so switching projects keeps the panels the same size instead of each project remembering its own.

It deliberately carries nothing else. In particular it never carries the tab edges: a project's edges are its own explicit Tab Bars choice, or the app-wide tab positions when it has made none, and copying one project's edges into another would make a choice for a project whose user never made one. Reading the value out of a window and applying it to another window are the tabs window's and the window manager's concerns, documented in their own recipes.
## Behavioral Requirements

- **arrangement-only**: The configuration MUST hold exactly one field, the pane arrangement: the front tab's split tree, carrying its shape and sizes.
- **arrangement-optional**: The arrangement MUST be optional; an absent arrangement means there is nothing to copy, and a window adopting such a configuration MUST leave its panes as they are.
- **no-edges**: The configuration MUST NOT carry the enabled tab edges or any other per-project choice, so adopting it can never make a Tab Bars choice for the adopting project.
- **immutable-value**: The configuration MUST be an immutable value, safe to pass across concurrency domains, so the window manager can read it from one window and hand it to another without either window referring to the other.
- **memberwise-construction**: The configuration MUST be constructible from an arrangement (present or absent) alone.
## Appearance

Not applicable: this is a data value with no visual representation.
## States

| State | Appearance change |
|-------|------------------|
| Has arrangement | Not applicable: a data value; the adopting window applies the arrangement's shape and sizes. |
| No arrangement | Not applicable: a data value; the adopting window keeps its own panes. |
## Accessibility

- **Role/trait**: Not applicable — a data value, not a view.
- **Label requirements**: Not applicable — it labels nothing.
- **Announce state changes**: Not applicable — adopting it only resizes panes the user arranged themselves in another window.
- **Minimum interactive target**: Not applicable — it has no interactive surface.
## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| project-tab-configuration-001 | arrangement-only, memberwise-construction | Build a configuration from a two-leaf horizontal split | Its arrangement equals that split tree |
| project-tab-configuration-002 | arrangement-optional | Build a configuration with no arrangement | Its arrangement is absent |
| project-tab-configuration-003 | no-edges | Inspect the configuration's stored fields | The arrangement is the only field; no edge set is present |
| project-tab-configuration-004 | immutable-value | Hand a configuration from one concurrency domain to another | It compiles and arrives unchanged; its arrangement cannot be reassigned |
## Edge Cases

- **Null/empty input**: An absent arrangement is valid and means "nothing to copy" (**arrangement-optional**); the window manager also produces one when the source project has no stored tabs.
- **Source and target are the same project**: Not handled here — the window manager skips adopting a project's own configuration.
- **Arrangement from a different edge layout**: Edges are not carried (**no-edges**), so a source project on the left edge and a target on the top edge exchange pane sizes only; each keeps its own edges.
- **Concurrent access**: Not applicable — an immutable value (**immutable-value**).
- **Error states**: Not applicable — construction cannot fail.
- **Offline/disconnected state**: Not applicable — no I/O.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `arrangement` | split tree, optional | none (required argument) | The front tab's pane arrangement — shape and divider sizes — to put on another project window. |
## Deep Linking

Not applicable: a process-internal value with no screen, route or URL.
## Localization

Not applicable: this value defines no user-facing string.
## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable — no animation is defined here. |
| Increase Contrast | Not applicable — nothing is drawn. |
| Differentiate Without Color | Not applicable — nothing is drawn. |
## Feature Flags

Not applicable: no feature-flag or remote-config lookup appears in this component.
## Analytics

Not applicable: no analytics event is emitted.
## Privacy

- **Data collected**: None — a pane arrangement (split shape and sizes) held in memory.
- **Storage**: None of its own; the arrangement it copies comes from the project's stored tabs, which the project database owns.
- **Transmission**: None.
- **Retention**: In memory only, for the duration of one hand-off between windows.
## Logging

Not applicable: no logging call appears in this component.
## Platform Notes

- **AppKit / UIKit**: This is the source. `ProjectTabConfiguration` is a `Sendable` struct with one `let arrangement: LayoutNode?` and a memberwise `init(arrangement:)`. `ComposableTabsWindowController.tabConfiguration` produces it and `adopt(_:)` applies it; `ProjectWindowManager` moves it between windows when a project window is shown or becomes key.
- **SwiftUI**: The same plain struct works unchanged; a SwiftUI host would pass it through an environment value or an observable model rather than between window controllers.
- **Compose**: A Kotlin `data class ProjectTabConfiguration(val arrangement: LayoutNode?)` with `val` fields gives the same immutable value.
- **React/Web**: A frozen object `{ arrangement }`, typed `Readonly<{ arrangement: LayoutNode | null }>` in TypeScript.
- **WinUI 3**: A C# `record ProjectTabConfiguration(LayoutNode? Arrangement)`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/ProjectTabConfiguration.swift` | unverified |

## Design Decisions

**Decision**: The shared configuration carries the pane arrangement only and never the enabled tab edges.
**Rationale**: A project's edges are its own explicit Tab Bars choice, or the app-wide tab positions when it has made none. Carrying edges from the last-active window would write that window's edges into every project the user switches to, turning the app-wide default into a per-project choice nobody made (`principle-of-least-astonishment`).
**Approved**: pending

**Decision**: A value type passed by the window manager rather than one window reading another directly.
**Rationale**: Neither window needs to know the other exists; the manager reads the value out of one and hands it to the next (`dependency-injection`).
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Data-minimization passes because the value holds only the pane arrangement it exists to copy. Separation-of-concerns passes because reading and applying the value live in the tabs window and moving it lives in the window manager. Unit-test coverage is partial: no test targets the value directly.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-15 | Mike Fullerton | Initial extraction from `ProjectTabConfiguration.swift`: the shared configuration carries the pane arrangement only, never the tab edges. |
