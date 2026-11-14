---
id: c5b856ba-9e3e-4f0f-9b9d-5095d193508b
title: "Composable Tabs Sibling Contents"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "NSViewController extension answering which panes, and which pane contents, share this view controller's composable tab, in reading order."
platforms:
  - swift
  - macos
tags:
  - component
  - composable-tabs
  - ui
depends-on:
  - 0640ca96-95c5-4234-925e-386425cc4435
  - 2b4d0f95-dbdf-48a9-8579-a3e5b7d488fe
related: []
references:
  - https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.media.visualtreehelper
approved-by: ""
approved-date: ""
---

# Composable Tabs Sibling Contents

## Overview

This is an extension on `NSViewController` that lets any view controller sitting inside a pane of a [Composable Tabs](cookbook:0640ca96-95c5-4234-925e-386425cc4435) tab find the other panes of that tab. `tabPanes()` returns every pane of the tab in reading order, its own pane included, or an empty array when the view controller is not inside a pane. `tabPaneContents()` returns the content view controller of each of those panes. The answer is computed on each call by walking up to the pane that holds the view controller, from there to the host split, and from there to the tab's root split, so it reflects the layout at that moment: a pane added or closed since the last call is counted or not. Callers in the source are the terminal chat view controllers, which look up the pane a terminal is connected to by node id, and the persona terminal chat, which looks for a terminal session among the sibling contents. The extension is public; [Pane View](cookbook:2b4d0f95-dbdf-48a9-8579-a3e5b7d488fe) covers the pane itself.

## Behavioral Requirements

- **find-enclosing-pane**: `tabPanes()` MUST locate the nearest ancestor of the view controller, starting from its parent, that is a pane view controller.
- **empty-outside-pane**: `tabPanes()` MUST return an empty array when no ancestor of the view controller is a pane view controller.
- **empty-without-split-host**: `tabPanes()` MUST return an empty array when the enclosing pane's host is not a composable tabs split view controller.
- **empty-without-root-split**: `tabPanes()` MUST return an empty array when the host split's `rootSplit()` returns nothing. In source `rootSplit()` starts from the host split itself and climbs `enclosingSplit` until the split marked `isRoot` or a split with no enclosing split, so it returns a split in every case and this guard is defensive.
- **panes-from-root-in-reading-order**: `tabPanes()` MUST return every pane of the tab, found from the tab's root split in depth-first order, which is the order the user reads the panes in.
- **include-own-pane**: The array from `tabPanes()` MUST include the pane that holds the calling view controller.
- **answer-for-current-layout**: `tabPanes()` MUST be computed from the layout at the time of the call and MUST NOT be cached between calls.
- **contents-of-every-pane**: `tabPaneContents()` MUST return the content view controller of each pane returned by `tabPanes()`, in the same order.
- **omit-panes-without-content**: `tabPaneContents()` MUST omit a pane that has no content view controller, rather than leaving a placeholder.
- **contents-empty-outside-pane**: `tabPaneContents()` MUST return an empty array whenever `tabPanes()` does.

## Appearance

Not applicable: the extension has no visual output; it only reads the view controller hierarchy.

## States

| State | Appearance change |
|-------|------------------|
| Default | Not applicable: the extension is stateless and holds nothing between calls. |
| Pressed | Not applicable: the extension has no interactive element. |
| Disabled | Not applicable: the extension has no interactive element. |
| Focused | Not applicable: the extension has no interactive element. |
| Loading | Not applicable: the extension answers synchronously from the current hierarchy. |
| Outside a pane | `tabPanes()` and `tabPaneContents()` return empty arrays. |

## Accessibility

Not applicable: the extension draws nothing and handles no input; it exposes no accessible element. Any accessibility of the panes it returns belongs to those panes.

## Conformance Test Vectors

No test beside the source exercises `tabPanes()` or `tabPaneContents()` (the test bundles contain no reference to either), so these vectors are derived from the source's behavior and its doc comments; each states a hierarchy in which a view controller sits.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tab-sibling-contents-001 | find-enclosing-pane, include-own-pane, panes-from-root-in-reading-order | A tab whose root split holds panes A and B; a content view controller inside pane A calls `tabPanes()` | The result is A then B, and includes A |
| tab-sibling-contents-002 | panes-from-root-in-reading-order | A root split holding pane A and a nested split holding panes B and C; content in pane C calls `tabPanes()` | The result is A, B, C |
| tab-sibling-contents-003 | empty-outside-pane | A view controller with no pane ancestor calls `tabPanes()` | The result is empty |
| tab-sibling-contents-004 | empty-without-split-host | A view controller inside a pane whose host is not a composable tabs split view controller calls `tabPanes()` | The result is empty |
| tab-sibling-contents-005 | empty-without-root-split | A view controller inside a pane whose host split's `rootSplit()` returns nothing (a guard that the source's `rootSplit()` never trips, since it always returns the walked split) calls `tabPanes()` | The result is empty |
| tab-sibling-contents-006 | answer-for-current-layout | Call `tabPanes()` from content in pane A of a two-pane tab, add pane C, call it again | The first result has two panes and the second has three, including C |
| tab-sibling-contents-007 | answer-for-current-layout | From the three-pane tab, close pane B and call again | The result has two panes and omits B |
| tab-sibling-contents-008 | contents-of-every-pane | Panes A and B hold content view controllers X and Y; X calls `tabPaneContents()` | The result is X then Y |
| tab-sibling-contents-009 | omit-panes-without-content | Panes A, B and C where B has no content view controller; content in A calls `tabPaneContents()` | The result has the contents of A and C only |
| tab-sibling-contents-010 | contents-empty-outside-pane | A view controller with no pane ancestor calls `tabPaneContents()` | The result is empty |
| tab-sibling-contents-011 | find-enclosing-pane | Content nested several view controllers deep inside pane B calls `tabPanes()` | The result is the same as for content directly in B |

## Edge Cases

- **Null and empty input**: A view controller with no parent MUST get an empty array from both methods. A tab with a single pane MUST return that pane alone, and its content from `tabPaneContents()`.
- **Boundary values**: A pane with no content view controller MUST be counted by `tabPanes()` but omitted by `tabPaneContents()`.
- **Calling on a pane itself**: The walk starts at the receiver's parent, so the receiver is never tested. A pane view controller that calls `tabPanes()` on itself finds a pane only if it is nested inside another pane; otherwise it gets an empty array. The doc comment promises the receiver's own pane for a view controller inside a pane, which is the content case.
- **Concurrent access**: Not applicable: the extension reads view controller state that AppKit confines to the main thread, and keeps no state of its own.
- **Error states**: Not applicable: the extension returns an empty array for every broken or missing link in the chain and throws nothing.
- **Offline or disconnected state**: Not applicable: the extension performs no network or file access.
- **Layout change between calls**: A pane added or closed between two calls MUST be reflected in the second call, because the result is rebuilt from the tree each time. A caller that holds the array holds a snapshot that can go stale.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `tabPanes()` | `() -> [ComposableTabsPaneViewController]` | none | Every pane of this view controller's tab, in reading order. |
| `tabPaneContents()` | `() -> [NSViewController]` | none | The content view controller of each of those panes. |

## Deep Linking

Not applicable: the extension has no URL routing.

## Localization

Not applicable: the extension has no user-facing strings.

## Accessibility Options

Not applicable: the extension has no animation, color or visual output.

## Feature Flags

Not applicable: the extension has no feature flag logic.

## Analytics

Not applicable: the extension performs no analytics tracking.

## Privacy

- **Data collected**: None.
- **Storage**: None.
- **Transmission**: None.
- **Retention**: None.

## Logging

Not applicable: the extension performs no logging.

## Platform Notes

- **SwiftUI**: There is no view controller parent chain to walk. Publish the tab's pane list through an `@Observable` model placed in the environment (`@Environment` or `EnvironmentValues` entry) so any view inside a pane reads the sibling list. Differs from the source in being pushed by the model rather than recomputed from the hierarchy on each call.
- **Compose**: Hold the tab's pane list in a `ViewModel` or state holder and expose it through a `CompositionLocal` so any composable in a pane reads it. Differs from the source in that the list is observable state, not a walk done on demand.
- **React/Web**: Provide the pane list through a React context at the tab level and read it with a hook from any component inside a pane; the context value changes when panes are added or closed. Differs from the source in being state the provider pushes down.
- **AppKit / UIKit**: `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/ComposableTabsSiblingContents.swift` is the implementation: an `NSViewController` extension that climbs `parent` to the first `ComposableTabsPaneViewController`, takes its `host` as a `ComposableTabsViewController`, asks it for `rootSplit()` and returns `allLeaves()`; `tabPaneContents()` is a `compactMap` over `contentViewController`. On UIKit the same shape works over `UIViewController.parent`.
- **WinUI 3**: Start with `VisualTreeHelper.GetParent` to walk from a content element up to the pane control and on to the tab's root panel, then enumerate the pane controls depth first with `VisualTreeHelper.GetChildrenCount` and `GetChild`, returning an empty list when no pane control is found. A simpler composition is a tab host control that exposes an `IReadOnlyList<PaneControl>` property, handed to each pane's content through its `DataContext` or a shared view model, and re-read on each use so a closed pane drops out. Differs from the source: WinUI 3 has no view controller hierarchy, so a pane is a control in the visual tree, and the tree can be walked only once the elements are loaded (after the `Loaded` event).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/ComposableTabsSiblingContents.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

- **Decision**: Compute the sibling list from the live hierarchy on each call instead of caching it.
  **Rationale**: The doc comment states it "answers for whatever the layout is now": a pane added or closed since the last call is counted or not, so callers never act on a stale list.
  **Approved**: pending

- **Decision**: Return an empty array, not an error, when the view controller is not inside a pane, or the chain to the root split is broken.
  **Rationale**: The doc comment states the result is "empty when it is not inside a pane"; callers such as the terminal chat controllers use the result in `first(where:)` lookups, which an empty array answers with no match.
  **Approved**: pending

- **Decision**: Answer from the tab's root split, not from the enclosing split.
  **Rationale**: Panes nested in sub-splits are part of the same tab, so the walk goes up to the root split and uses its depth-first order, the order the user reads the panes in.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

`separation-of-concerns` passes because the extension only reads the hierarchy and leaves layout, ownership and use of the panes to the callers. `unit-test-coverage` fails because no test in the repository's test bundles references `tabPanes()` or `tabPaneContents()`. `graceful-degradation` passes because every missing link in the chain yields an empty array rather than a failure.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
