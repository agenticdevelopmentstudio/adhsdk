---
id: ea417c67-3964-4620-871b-b98959be2773
title: "Safe Area Host View Controller"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Hosts one child view controller below the window's safe area or over the whole height, on a clipped backdrop that fills the pane behind a clear titlebar."
platforms:
  - swift
  - macos
tags:
  - composable-tabs
  - window-layout
  - safe-area
  - container
depends-on: []
related:
  - 55a394e6-9934-404b-941d-25bebbf71378
references:
  - https://developer.apple.com/design/human-interface-guidelines/layout
approved-by: ""
approved-date: ""
---

# Safe Area Host View Controller

## Overview

A container that holds exactly one child view controller inside a pane whose
own backdrop fills the whole pane, the strip behind a clear titlebar
included. It exists so that a window whose content runs up behind a
transparent titlebar can still choose, per pane, whether the child starts
below the titlebar (the safe area) or is given the whole height to place
things itself. The pane paints its own color, so adjoining panes can each
paint the titlebar strip in their own color and no band of a third color
crosses the top.

Use it around any pane in a window that extends its content under the
titlebar. It adds no controls, no state beyond its insets and its backdrop
color, and no behavior of its own beyond pinning, clipping and painting.

## Behavioral Requirements

### Hosting

- **single-child**: The component MUST host exactly one child view controller, supplied at construction, and MUST show that child's view as its only content.
- **child-owned**: The component MUST retain the child for its own lifetime and attach it as its child controller when its view is loaded.
- **view-fills-pane**: The component's own view MUST be one container view that holds the child's view; sizing that view to the pane is the job of the container that hosts it.
- **clips-child**: The component MUST clip its content to its own bounds, so a pane narrower than its child (a shelf sliding in) shows the part that fits and does not spill over its neighbors.

### Pinning

- **safe-area-top**: When constructed to pin to the safe area (the default), the component MUST hold the child's top edge at the pane's top safe area edge, offset by the top inset.
- **full-height-top**: When constructed not to pin to the safe area, the component MUST hold the child's top edge at the pane's top edge, offset by the top inset.
- **bottom-pinned**: The component MUST hold the child's bottom edge at the pane's bottom edge, offset upward by the bottom inset.
- **side-edges-pinned**: The component MUST hold the child's leading and trailing edges at the pane's leading and trailing edges, offset inward by the leading and trailing insets.
- **side-edges-yield**: The leading and trailing pins MUST sit below required priority, at the platform's default-high priority, so a pane collapsing to zero width does not force the layout system to break a required constraint.
- **top-bottom-required**: The top and bottom pins MUST be required.

### Insets

- **insets-default-zero**: The insets MUST default to zero on every edge.
- **insets-live**: Changing the insets MUST update the pins at once, without rebuilding the view.
- **insets-before-load**: Insets set before the view is first loaded MUST take effect when it loads.
- **insets-sign**: The component MUST apply the left and top insets as positive offsets and the right and bottom insets as negative offsets, so every inset moves its edge inward.

### Backdrop

- **backdrop-default-clear**: The backdrop color MUST default to clear.
- **backdrop-paints-pane**: Setting the backdrop color MUST paint the whole pane, including the strip behind the titlebar.
- **backdrop-snapshot**: The backdrop color MUST be applied as a resolved color value at the time it is set; the component MUST NOT track later appearance changes, so its owner re-applies the color when the theme changes.
- **backdrop-loads-view**: Setting the backdrop color before the view has loaded MUST load the view as a side effect.

### Lifetime and isolation

- **no-archive-init**: The component MUST NOT support construction from an archive.
- **ui-thread-confined**: The component MUST be used on the UI thread only.

## Appearance

- **Corner radius**: None; the pane is square-cornered and any card inside the child draws its own.
- **Padding**: Zero by default; the four insets move the child inward from each edge, the top one from the safe area when pinned to it.
- **Font**: Not applicable: the component draws no text.
- **Background**: The backdrop color, clear by default, painted across the whole pane.
- **Foreground/Text**: Not applicable: the component draws nothing but its backdrop.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: None of its own; the pane takes the size its container gives it and the child follows within the pins.

## States

| State | Appearance change |
|-------|------------------|
| Default | Child pinned within the pane, backdrop clear, insets zero |
| Backdrop set | The whole pane, titlebar strip included, is the chosen color |
| Pane narrower than child | Content is clipped to the pane; the child's side pins give way |
| Pressed | Not applicable: the component is an inert container with no pressed styling. |
| Disabled | Not applicable: the source exposes no enabled flag. |
| Focused | Not applicable: the component takes no focus itself; the child's own focus behavior applies. |
| Loading | Not applicable: nothing is fetched or awaited. |

## Accessibility

- **Role/trait**: Not set in source; the platform's default view role applies to the container and the child supplies its own.
- **Label requirements**: Not applicable: the container draws and announces nothing of its own; labels belong to the child.
- **Announce state changes**: Not applicable: the container has no state that changes what a user perceives besides its backdrop color and insets.
- **Keyboard navigation**: Not applicable: the container adds no controls and no key handling; the child's key view loop is untouched.
- **Minimum tap target**: Not applicable: the container defines no control.
- **Minimum contrast ratio**: Not applicable: the container chooses no color; the owner supplies the backdrop color and the contrast against the child's content is the owner's concern.

## Conformance Test Vectors

No test beside the source drives this component directly; it is built (indirectly) by the tests that construct a project window. These vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| safe-area-host-001 | single-child, child-owned | Construct with a child controller and load the view | The child is attached as a child controller and its view is the only subview |
| safe-area-host-002 | safe-area-top | Default construction in a window with a 28-point titlebar safe area | The child's top is 28 points below the pane's top |
| safe-area-host-003 | full-height-top | Construct with pinning to the safe area off, same window | The child's top is at the pane's top, 0 points |
| safe-area-host-004 | insets-sign, insets-live | Set insets of top 4, left 8, bottom 6, right 10 after load | Child frame is inset 8 leading, 10 trailing, 6 bottom, and 4 below its top pin |
| safe-area-host-005 | insets-before-load | Set insets before the view is loaded, then load | The child is inset by those values at first layout |
| safe-area-host-006 | insets-default-zero | Read the insets on a new instance | All four edges are 0 |
| safe-area-host-007 | side-edges-yield, top-bottom-required | Inspect the four pins after load | Leading and trailing at the default-high priority; top and bottom required |
| safe-area-host-008 | side-edges-yield, clips-child | Size the pane to zero width with a child that has a wide fitting size | No constraint is broken; the pane draws nothing outside its bounds |
| safe-area-host-009 | backdrop-default-clear | Read the backdrop color on a new instance | Clear; the layer's background is never set until a color is assigned, so nothing is painted |
| safe-area-host-010 | backdrop-paints-pane, backdrop-snapshot | Set the backdrop color to a theme color, then change the system appearance without re-setting | The layer holds the color as set; it does not change with the appearance |
| safe-area-host-011 | backdrop-loads-view | Set the backdrop color on an instance whose view is not loaded | The view is loaded and its layer carries the color |
| safe-area-host-012 | no-archive-init | Attempt to construct from an archive | The attempt is rejected with a fatal error |
| safe-area-host-013 | ui-thread-confined | Construct from off the UI thread | The use is rejected at build time or by a runtime check |

## Edge Cases

- **Null/empty input** (MUST): there is always a child; construction requires one. A zero-sized or never-laid-out pane leaves the child at zero size within the pins; insets of zero are the default.
- **Boundary values** (MUST): nothing in source clamps or validates insets, so insets larger than the pane are handed to the layout system as they are. The side pins sit below required priority so a pane at zero width is legal (see `side-edges-yield`).
- **Set the backdrop before load** (MUST): doing so loads the view (see `backdrop-loads-view`), so the order of backdrop and insets assignment does not matter.
- **Appearance change** (MUST): a backdrop color that is dynamic is resolved when set and not re-resolved on a light or dark switch (see `backdrop-snapshot`).
- **Concurrent access** (MUST): confined to the UI thread; there is no cross-thread path.
- **Error states**: Not applicable: no I/O, no throwing operation; the only failure is the fatal error for archive construction.
- **Offline/disconnected state**: Not applicable: no networking.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| child | view controller | required | The one controller hosted |
| pinsToSafeArea | boolean | true | Child starts below the titlebar when true; given the whole height when false |
| insets | edge insets | zero | How far the child is held off each edge |
| backdropColor | color | clear | Painted across the whole pane |

## Deep Linking

Not applicable: the component is an internal container with no URL scheme or route in the source.

## Localization

Not applicable: the component renders no text and defines no string.

## Accessibility Options

- **Reduce Motion**: Not applicable: the component animates nothing; moving its panes is its owner's concern.
- **Increase Contrast**: Not applicable: the component picks no color; the owner supplies the backdrop color.
- **Differentiate Without Color**: Not applicable: the component conveys no state by color.

## Feature Flags

Not applicable: the source contains no feature-flag lookup.

## Analytics

Not applicable: the source contains no analytics call.

## Privacy

- **Data collected**: None.
- **Storage**: Not applicable: nothing is persisted.
- **Transmission**: Not applicable: nothing leaves the device.
- **Retention**: None beyond the component's own lifetime.

## Logging

Not applicable: the source contains no logging call.

## Platform Notes

- **SwiftUI**: Use a `ZStack` whose bottom layer is the backdrop color extended with `.ignoresSafeArea()` and whose top layer is the child with `.padding(insets)`; for the full-height variant also apply `.ignoresSafeArea(.container, edges: .top)` to the child. Add `.clipped()` to match the clipping. A dynamic `Color` follows the appearance by itself, unlike the source's snapshot.
- **Compose**: Use a `Box(Modifier.background(color).clipToBounds())` with the child inside `Modifier.windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top))` for the pinned variant and no insets padding for the full-height one; apply the edge insets with `Modifier.padding`. Draw the box edge to edge with `enableEdgeToEdge()` so the backdrop reaches under the system bars.
- **React/Web**: Use a `position: relative; overflow: hidden` element with the backdrop as its `background-color`, the child absolutely positioned with `inset` set to the insets, and the top offset `calc(env(safe-area-inset-top) + var(--inset-top))` for the pinned variant. Set the meta viewport to `viewport-fit=cover` so the backdrop reaches the unsafe area. Prefer a CSS custom property for the backdrop so a theme change re-resolves it.
- **AppKit / UIKit** (source platform): Implemented in `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/SafeAreaHostViewController.swift` as a `@MainActor` `NSViewController` subclass. It builds the container in `loadView` with `wantsLayer` and `clipsToBounds`, adds the child controller and its view with `translatesAutoresizingMaskIntoConstraints` off, and pins the top to `safeAreaLayoutGuide.topAnchor` or to the container's top. Leading and trailing use `.defaultHigh` priority so a collapsing `NSSplitViewItem` does not trip required-constraint breakage. The backdrop sets `view.layer?.backgroundColor` from `NSColor.cgColor`, which resolves at set time. `init(coder:)` is unavailable. UIKit has the same pattern with `safeAreaLayoutGuide` on `UIView` and `view.backgroundColor`, which does track trait changes.
- **WinUI 3**: Use a `Grid` as the pane with `Background` bound to a `Brush` and `Margin` or a `Padding` for the insets, and a `ContentPresenter` or `Frame` for the child. For the full-height variant extend the window with `Window.ExtendsContentIntoTitleBar = true` and let the grid reach the top; for the pinned variant set `Padding="0,{TitleBar.Height},0,0"` using `AppWindow.TitleBar.Height` or the `SetTitleBar` region's `ActualHeight`. Clip with `Grid.Clip` set to a `RectangleGeometry` updated in `SizeChanged`, since XAML panels do not clip by default. A `ThemeResource` brush re-resolves on theme change, unlike the source's snapshot. WinUI has no priority-yielding pins; a width of zero is legal for a `Grid` column with no `MinWidth` on the child.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/SafeAreaHostViewController.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The leading and trailing pins are below required priority, while the top and bottom pins are required.
**Rationale**: Per the source comment, the Conversations shelf does the same: a collapsing pane animates to zero width, and a required side edge is one the layout system has to break, loudly, to get there.
**Approved**: pending

**Decision**: The container clips to its bounds.
**Rationale**: Per the source comment, a shelf sliding in is narrower than its contents, and showing the part that fits is better than letting the rest spill over the panes.
**Approved**: pending

**Decision**: The backdrop is applied as a resolved color value and is not kept in step with appearance changes.
**Rationale**: The source writes the color's resolved value to the layer once; the component's owners re-apply it from the theme palette when the theme changes. A port that uses a theme-aware brush gets the same result without the re-apply.
**Approved**: pending

**Decision**: The host pins to the safe area per instance, not per window.
**Rationale**: Per the source comment (the `pinsToSafeArea` parameter), the child either starts below the titlebar or is given the whole height to place things itself, and that choice differs between panes of one window.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | partial | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`platform-theming` is `partial`: the backdrop takes whatever color its owner supplies, so theming works when the owner re-applies it on a theme change, but the component itself does not track appearance changes (see `backdrop-snapshot`). `separation-of-concerns` passes because the component only pins, clips and paints; the color, the insets and the child all come from its owner. `unit-test-coverage` fails because no test beside the source constructs the component or asserts its pins, insets or backdrop; it runs only as part of the window-controller tests.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from the macOS `SafeAreaHostViewController` source. |
