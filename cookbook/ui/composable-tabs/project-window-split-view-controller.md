---
id: 5f832f45-b409-41db-b1ab-b360a0c7a1ea
title: "Project Window Split View Controller"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A project window's content: an optional collapsible shelf down the leading edge beside the tabs, with a hand-walked slide and remembered visibility and width."
platforms:
  - swift
  - macos
tags:
  - composable-tabs
  - split-view
  - window-layout
  - shelf
depends-on: []
related:
  - 55a394e6-9934-404b-941d-25bebbf71378
  - 4c528e38-b70a-4ed3-bedc-9009292ad908
references:
  - https://developer.apple.com/design/human-interface-guidelines/sidebars
  - https://developer.apple.com/design/human-interface-guidelines/split-views
approved-by: ""
approved-date: ""
---

# Project Window Split View Controller

## Overview

The content of one project window: an optional shelf (the list of projects)
down the leading edge, and the window's own content (the tabs and their
footer) beside it. Both halves run the full height of the window, up behind a
clear titlebar, and each paints that strip in its own color, which is what
makes the titlebar seamless: no band of a third color crosses the top. The
content is laid out from the safe area, below the toolbar; the shelf is given
the whole height, because its bordered card encloses the window controls and
lays out its own controls from the safe area.

Beyond arranging the two panes, the component owns three behaviors a plain
split view does not give: a shelf that slides in and out by a layout pass on
every display frame instead of an animated collapse; a remembered shelf
visibility and width shared by every project window; and a pair of
"shelf will move" and "shelf did move" notifications that let the window hold
each tab pane at its share of the width while the shelf moves. Use it as the
content controller of a project window. A window with no shelf (a host with no
projects to list) passes none and gets the content alone.

## Behavioral Requirements

### Structure

- **content-pane**: The component MUST host the window content in a pane whose minimum width is 300 points.
- **content-safe-area**: The component MUST lay the window content out from the top safe area, below the toolbar.
- **content-backdrop**: The component MUST paint the content pane's full area, the strip behind the titlebar included, in the theme's window background color.
- **shelf-optional**: The component MUST accept an absent shelf, and with none MUST host the content alone and report that it has no shelf.
- **shelf-leading-pane**: When a shelf is supplied, the component MUST place it in a pane on the leading side of the content pane.
- **shelf-full-height**: The component MUST give the shelf pane the window's whole height, up behind the titlebar, and MUST NOT inset the shelf from the safe area.
- **shelf-backdrop**: The component MUST paint the shelf pane's full area in the theme's project pane backdrop color.
- **theme-repaint**: The component MUST re-apply both backdrop colors whenever the active theme palette changes.
- **divider-thin**: The component MUST draw a thin divider between the panes.
- **plain-panes**: The component MUST use ordinary (non-sidebar) split items and a plain split view, because sidebar material and a themed split view's divider color reach no theme (see Design Decisions).

### Shelf geometry and persistence

- **shelf-width-bounds**: The shelf pane MUST be no narrower than 180 points and no wider than 480 points.
- **shelf-width-restored**: The component MUST ask for the shelf's opening width from the persisted shelf width (default 240 points) at a priority that any user drag beats.
- **shelf-visibility-restored**: The component MUST start with the shelf collapsed unless the persisted shelf visibility (default hidden) is true.
- **shelf-collapsible**: The shelf pane MUST be collapsible.
- **window-keeps-size**: When the shelf collapses or expands, the window MUST keep its size and the content pane MUST give up or take the room.
- **window-resize-spares-shelf**: When the window is resized, the content pane MUST absorb the change and the shelf MUST keep the width the reader gave it.
- **width-remembered-on-drag**: The component MUST persist the shelf's width whenever it changes while the shelf is visible, not sliding, and at least its minimum width.
- **width-ignored-below-minimum**: The component MUST NOT persist a shelf width below 180 points, which is what a window still being assembled reports.
- **width-ignored-while-animating**: The component MUST NOT persist the shelf's width while a collapse is in flight, so the shrinking width on the way to zero is not recorded as the reader's choice.
- **width-synced-after-drag**: After persisting a dragged width, the component MUST make that width the shelf's requested width, so the next layout pass does not pull the shelf back.
- **open-width-clamped**: The width the shelf slides open to MUST be the persisted width clamped to 180 through 480 points.

### Visibility API

- **has-shelf**: The component MUST report whether a shelf pane exists.
- **is-shelf-visible-target**: The component MUST report the shelf's visibility as the destination of a slide in flight (visible when the slide's target width is above zero), and otherwise as the inverse of the shelf pane's collapsed state.
- **no-shelf-not-visible**: With no shelf, the component MUST report the shelf as not visible.
- **toggle**: Toggling MUST request the opposite of the reported visibility.
- **set-visible-persists**: Requesting a visibility change that is not already satisfied MUST persist the new visibility at once, before any animation runs.
- **set-visible-noop**: Requesting the visibility the shelf already has, with no slide in flight, MUST change nothing and MUST run the completion at once.
- **set-visible-no-shelf**: With no shelf, a visibility request MUST do nothing, and the completion MUST NOT run.
- **same-direction-joins**: Requesting the destination a slide in flight is already heading to MUST NOT start a second slide, and the new completion MUST run after the first slide's completion when that slide lands.
- **opposite-supersedes**: Requesting the opposite destination mid-slide MUST land the slide in flight at its destination first and MUST drop that slide's completion unrun.
- **hide-resigns-focus**: Hiding the shelf MUST make the shelf give up keyboard focus before the slide begins.
- **no-window-immediate**: When the component's view is not in a window, a visibility request MUST apply the collapsed state at once with no animation, then notify the visibility callback and run the completion.
- **panel-toggle-hide**: Toggling a shelf panel while the shelf is visible and already showing that panel MUST hide the shelf.
- **panel-toggle-show**: Toggling a shelf panel otherwise MUST switch the shelf to that panel, show the shelf, and put keyboard focus in the shelf's filter once the shelf has landed.
- **panel-toggle-no-shelf**: With no shelf, toggling a shelf panel MUST do nothing.
- **land-slide**: The component MUST let a caller end a slide in flight at its destination.

### Slide

- **slide-duration**: A shelf slide MUST last 0.2 seconds.
- **slide-easing**: A slide's width MUST follow smoothstep easing, progress squared times three minus two times progress, from origin to target.
- **slide-per-frame-layout**: A slide MUST run a full layout pass on every display frame, so every view inside both panes takes the frame its constraints give it on every frame.
- **slide-through-width**: A slide MUST move the shelf by changing the shelf host's requested width, and MUST NOT move the divider position.
- **slide-width-priority**: During a slide the requested width MUST sit at priority 999, above every holding priority and below required.
- **slide-minimum-zero**: During a slide the shelf pane's minimum thickness MUST be zero so the width can be walked to and from zero.
- **slide-in-from-zero**: Sliding in MUST uncollapse the shelf at zero width, so the shelf never shows at its full width before the slide begins.
- **slide-in-window-frame**: Sliding in MUST restore the window's frame if uncollapsing grew it.
- **slide-window-width-hold**: For the length of a slide the window's content width MUST be held to its width at the start.
- **slide-content-gives-up-room**: The content pane MUST give up what the shelf gains, point for point, through an animated resize that begins before the slide and ends after it.
- **slide-start-after-draw**: The slide clock MUST start only once the panes have drawn for the animated resize.
- **slide-start-guard**: A slide whose start is overtaken by a later toggle MUST NOT start.
- **slide-end-collapse**: Ending a slide to zero width MUST collapse the shelf pane.
- **slide-end-restore**: Ending a slide MUST restore the shelf's minimum thickness to 180 points, the requested width to the clamped open width, its priority to the drag-beatable one, and release the window width hold.
- **slide-end-order**: Ending a slide MUST run the did-move callback, then the visibility callback, then the completion (unless superseded).
- **slide-visibility-callbacks**: An animated visibility change MUST call the visibility callback when the slide begins and again when it ends.

### Move notifications

- **move-pair**: The component MUST call the will-move callback as the shelf's width is about to change beside the content and the did-move callback when it has finished, for a slide, an adopted layout and a divider drag.
- **move-not-for-window-resize**: The component MUST NOT call either move callback for a window resize, which moves the content's edge and not the shelf's.
- **move-detects-by-width**: The component MUST treat a resize as a shelf move when the split view's width equals its width at the previous resize and is above zero.
- **drag-settle**: A divider drag MUST count as finished when no further resize has arrived for 250 milliseconds.
- **drag-settle-restart**: Each further drag step MUST restart that 250 millisecond wait.
- **slide-owns-callbacks**: While a slide or adoption holds the pane shares, drag detection MUST NOT call either move callback.

### Layout handoff

- **shelf-layout-snapshot**: The component MUST describe its shelf as a value holding visibility and the shelf pane's current width, with width zero when there is no shelf.
- **adopt-immediate**: Adopting a layout MUST apply it at once with no animation.
- **adopt-holds-shares**: Adopting a layout MUST call will-move before changing the shelf and did-move after a layout pass completed, with the pane shares held for the whole span.
- **adopt-visibility**: Adopting a layout MUST collapse or uncollapse the shelf only when its state differs from the layout's visibility, and MUST call the visibility callback when it does.
- **adopt-width**: Adopting a visible layout MUST apply its width only when it is at least the shelf's minimum thickness, by setting the requested width and the divider position.
- **adopt-no-shelf**: With no shelf, adopting a layout MUST do nothing.

### Lifetime and isolation

- **teardown**: Releasing the component MUST cancel a pending drag-settle wait, stop a slide's display link and remove both split view observers.
- **ui-thread-confined**: The component MUST be used on the UI thread only.
- **no-archive-init**: The component MUST NOT support construction from an archive.

## Appearance

- **Corner radius**: None set here; the shelf's bordered card belongs to the shelf controller.
- **Padding**: None; the content is pinned to the safe area and the shelf to the whole pane (see `content-safe-area` and `shelf-full-height`).
- **Font**: Not applicable: the component draws no text.
- **Background**: The content pane is the theme's window background; the shelf pane is the theme's project pane backdrop; both are reapplied on a theme change (see `theme-repaint`).
- **Foreground/Text**: Not applicable: the component draws no text or glyphs of its own.
- **Border**: A thin divider between the panes (see `divider-thin`); no other border.
- **Shadow**: None.
- **Min/Max size**: Content pane minimum width 300 points; shelf pane 180 through 480 points, 240 points by default; a slide's duration is 0.2 seconds.

## States

| State | Appearance change |
|-------|------------------|
| Default (shelf hidden) | Shelf pane collapsed to zero width; the content pane fills the window; persisted visibility is false |
| Shelf visible | Shelf pane at its remembered width (180 to 480 points) beside the content pane, divider drawn between them |
| Sliding in | Shelf host width walks from 0 to the open width over 0.2 seconds with smoothstep easing; the content pane narrows by the same amount on every frame |
| Sliding out | Shelf host width walks from its current width to 0 over 0.2 seconds; the pane collapses when the slide lands |
| Dragging | The reader moves the divider; the shelf width follows within 180 to 480 points and is persisted on each step |
| No shelf | Only the content pane exists; shelf requests do nothing |
| Pressed | Not applicable: the component is a container with no pressed styling; the divider's drag is the Dragging state. |
| Disabled | Not applicable: the source exposes no enabled flag; a shelfless window is the No shelf state. |
| Focused | Not applicable: the component never takes keyboard focus itself; focus moves to the shelf's filter only through `panel-toggle-show`. |
| Loading | Not applicable: nothing is fetched or awaited; a slide is the only timed state. |

## Accessibility

- **Role/trait**: Not set in source; the platform's split view role applies to the divider and panes unmodified.
- **Label requirements**: Not applicable: the component renders no label of its own; the pane contents carry their own labels.
- **Announce state changes**: NEEDS REVIEW: Not implemented in source. Showing or hiding the shelf posts no accessibility notification and sets no label on the divider; evidence needed is a screen reader pass on a shelf toggle to see whether the platform announces the layout change by itself.
- **keyboard-toggle-shelf-panel**: A keyboard user MUST be able to show and hide the shelf through the shelf-panel toggle (documented in source as the Command-0 and Command-1 keys), which also puts the keyboard in the shelf's filter.
- **keyboard-divider-resize**: NEEDS REVIEW: Not implemented in source. No keyboard path adjusts the divider; width changes by keyboard are limited to the show and hide toggles; evidence needed is whether the platform's split view exposes a keyboard divider adjustment that applies here.
- **Minimum tap target**: Not applicable: the component defines no control; the divider's grab area is the platform split view's.
- **Minimum contrast ratio**: Not applicable: the component picks backdrop colors from the theme palette and draws no foreground; contrast belongs to the theme and the pane contents.

## Conformance Test Vectors

The only test beside the source, `testTheFooterHostWrapsTheTabsBesideTheShelf` in `ProjectFooterStatusTests`, asserts that a project window's content controller is this type. The other vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| split-001 | content-pane, shelf-leading-pane (`testTheFooterHostWrapsTheTabsBesideTheShelf`) | Build a project window controller | Its content controller is this component (the test's assertion); the shelf pane sits before the content pane by construction |
| split-002 | shelf-optional, has-shelf, no-shelf-not-visible | Construct with no shelf | One pane exists; has-shelf is false; shelf-visible is false |
| split-003 | set-visible-no-shelf, panel-toggle-no-shelf | With no shelf, request show and toggle a panel, each with a completion | Nothing changes; neither completion runs |
| split-004 | shelf-visibility-restored | Persisted visibility false (default); construct with a shelf | The shelf pane is collapsed |
| split-005 | shelf-visibility-restored | Persisted visibility true; construct with a shelf | The shelf pane is uncollapsed |
| split-006 | shelf-width-restored | Persisted width 300; construct with a shelf and show it | The shelf opens at 300 points |
| split-007 | shelf-width-bounds, open-width-clamped | Persisted width 100, then 900; show the shelf | It opens at 180 points, then at 480 points |
| split-008 | set-visible-noop | Shelf hidden, no slide; request hidden with a completion | No state change; the completion has run synchronously |
| split-009 | set-visible-persists | Shelf hidden; request visible | Persisted visibility is true before the first slide frame |
| split-010 | is-shelf-visible-target | Request hide on a visible shelf and read visibility before the slide lands | Visibility reads false although the pane is not yet collapsed |
| split-011 | toggle | Shelf visible; toggle twice in the same run loop turn | Final destination is visible; at most one slide ran per destination |
| split-012 | same-direction-joins | Request visible twice with completions A then B during one slide | One slide runs; A runs then B when it lands |
| split-013 | opposite-supersedes | Request visible with completion A, then hidden before it lands | The first slide lands at once; A never runs; the shelf slides out |
| split-014 | slide-duration, slide-easing | Run a slide in with a fake display link at t = 0, 0.1 and 0.2 seconds | Width is 0, half the open width (smoothstep at 0.5), and the open width |
| split-015 | slide-through-width, slide-width-priority | Inspect during a slide | The shelf host's requested width is at priority 999 and the divider position is not set |
| split-016 | slide-end-restore, slide-end-order | Let a slide out land | Pane collapsed; minimum thickness 180; requested width equals the clamped open width at the drag-beatable priority; did-move, visibility callback, then completion in that order |
| split-017 | no-window-immediate | Request visible on a controller whose view is in no window | The pane is uncollapsed immediately; the visibility callback and completion have run; no slide exists |
| split-018 | width-remembered-on-drag | Drag the visible shelf to 260 points | Persisted width is 260 and the requested width is 260 |
| split-019 | width-ignored-below-minimum, width-ignored-while-animating | Resize notification arrives with the shelf at 0 width, and another during a slide | Persisted width is unchanged both times |
| split-020 | move-not-for-window-resize | Resize the window | Neither move callback runs and the shelf width is unchanged |
| split-021 | drag-settle, drag-settle-restart | Three drag steps 100 milliseconds apart | Will-move runs at the start of each step (each is a width-preserving resize while no slide holds the shares); did-move runs once, 250 milliseconds after the last step |
| split-022 | slide-owns-callbacks | Drag-detected resize arrives during a slide | Neither callback runs from drag detection |
| split-023 | adopt-visibility, adopt-width | Adopt a layout of visible at 300 points onto a collapsed shelf | The shelf uncollapses at once, width 300, divider at 300, will-move then did-move run, visibility callback runs once |
| split-024 | adopt-width | Adopt a visible layout of 100 points | The shelf's visibility is applied; its width is not applied |
| split-025 | shelf-layout-snapshot | Read the layout with no shelf, then with a visible 260-point shelf | Not visible and 0, then visible and 260 |
| split-026 | panel-toggle-hide, panel-toggle-show | Toggle the shelf's current panel while visible, then a different panel | The shelf hides; then the panel switches, the shelf shows and the filter takes focus once landed |
| split-027 | hide-resigns-focus | Hide the shelf while its filter has focus | The shelf has resigned focus before the first slide frame |

## Edge Cases

- **Null/empty input** (MUST): a nil shelf produces a content-only window and every shelf operation is inert (see `shelf-optional`, `set-visible-no-shelf`, `adopt-no-shelf`). On a shelfless window a visibility request never runs its completion, so a caller waiting on one waits forever; callers check has-shelf first.
- **Boundary values** (MUST): the shelf is clamped to 180 through 480 points; a persisted width outside that range is clamped when opening by slide (see `open-width-clamped`), but the width requested at first construction is the raw persisted value and the pane's own bounds then constrain it. A width below 180 is never persisted.
- **View not in a window** (MUST): visibility changes apply without animation (see `no-window-immediate`).
- **Concurrent access** (MUST): confined to the UI thread; the only re-entrancy is a second toggle mid-slide, which lands the first slide and drops its completion (see `opposite-supersedes`), and a drag during a slide, which is ignored for callbacks (see `slide-owns-callbacks`).
- **First uncollapse after a collapsed launch** (MUST): uncollapsing can grow the window by the shelf's remembered width; the component puts the window frame back (see `slide-in-window-frame`).
- **Slide against a pane at its minimum** (MUST): the window width is held for the slide so the window does not widen to satisfy the walked width; what cannot fit is the shelf's width or a pane share (see `slide-window-width-hold`).
- **Adoption during a slide** (SHOULD): nothing in the component lands a slide in flight before adopting a layout; the source assigns that to the caller through the land-slide operation.
- **Error states** (dependency/network failure): Not applicable: the source performs no I/O beyond reading and writing two user settings and throws nothing.
- **Offline/disconnected state**: Not applicable: no networking exists in this file.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| content | view controller | required | The window content, laid out from the safe area |
| shelf | shelf controller or none | none | The shelf; none gives a content-only window |
| onShelfVisibilityChange | callback | none | Called when a slide begins and ends, on an immediate change, and when an adopted layout changes visibility |
| onShelfWillMove | callback | none | Called as the shelf's width is about to change beside the content |
| onShelfDidMove | callback | none | Called when that movement has finished |
| Persisted shelf visibility | setting | hidden | Remembered across launches and shared by every project window |
| Persisted shelf width | setting, points | 240 | The width the reader last gave the shelf |
| Shelf width bounds | constants, points | 180 through 480 | Fixed |
| Content minimum width | constant, points | 300 | Fixed |
| Slide duration | constant | 0.2 seconds | Fixed |
| Drag settle delay | constant | 250 milliseconds | Fixed |

## Deep Linking

Not applicable: the component is internal window layout with no URL scheme, route or handler in the source.

## Localization

Not applicable: the component renders no text and defines no string of its own.

## Accessibility Options

- **Reduce Motion**: NEEDS REVIEW: Not implemented in source. The 0.2 second shelf slide runs whatever the system's Reduce Motion setting is, and no immediate-change path is chosen for it; evidence needed is whether a width slide counts as motion the project's accessibility policy requires reducing.
- **Increase Contrast**: Not applicable: the component picks no color of its own; its backdrops come from the theme palette.
- **Differentiate Without Color**: Not applicable: the component conveys no state by color; shelf visibility is shown by the pane's presence.

## Feature Flags

Not applicable: the source contains no feature-flag lookup.

## Analytics

Not applicable: the source contains no analytics or telemetry call.

## Privacy

- **Data collected**: None beyond two interface preferences, the shelf's visibility and width.
- **Storage**: Both are written to the app's user settings store as they change.
- **Transmission**: Not applicable: nothing leaves the device from this file.
- **Retention**: Until the user settings are cleared; both are shared by every project window.

## Logging

Not applicable: the source contains no logging call.

## Platform Notes

- **SwiftUI**: Use `NavigationSplitView` for the structure only if its sidebar styling suits; the source deliberately avoids sidebar items because their material reaches no theme (see Design Decisions), so an `HSplitView` or an `HStack` with a draggable divider gives the same plain behavior. Persist width and visibility with `@AppStorage`, clamp to 180 through 480 and animate width with `withAnimation(.easeInOut(duration: 0.2))` on a frame width. SwiftUI re-lays out every frame of an animated width by itself, so the hand-walked display link is unnecessary. Extend the background under the titlebar with `.ignoresSafeArea(.container, edges: .top)` on each pane's background and keep the content inside the safe area.
- **Compose**: Use a `Row` with a shelf `Box` using `Modifier.width` animated by `animateDpAsState(tween(200, easing = FastOutSlowInEasing))` and a draggable divider built with `Modifier.draggable` that clamps to 180 through 480 dp. Persist width and visibility in DataStore. Compose recomposes the content weight every frame, so no per-frame layout loop is needed. Draw each pane's background under the status bar with edge-to-edge insets, and apply `WindowInsets.systemBars` padding only to the content pane. Read `Settings.Global.ANIMATOR_DURATION_SCALE` to skip the animation when animations are disabled.
- **React/Web**: Use a CSS grid with `grid-template-columns` of the shelf width and `1fr`, transitioned over `200ms` with `cubic-bezier(0.4, 0, 0.2, 1)`, a draggable divider with `role="separator"` and `aria-valuenow`, `aria-valuemin` 180 and `aria-valuemax` 480, and Arrow-key handling on the separator (the keyboard divider path the source lacks). Persist both values in `localStorage`. Honor `prefers-reduced-motion: reduce` by setting the transition to none. Debounce the drag-finished callback by 250 milliseconds.
- **AppKit / UIKit** (source platform): Implemented in `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/ProjectWindowSplitViewController.swift` as a `@MainActor` `NSSplitViewController` subclass. The shelf item uses `.preferResizingSiblingsWithFixedSplitView`, a holding priority one above the default-low, minimum and maximum thickness of 180 and 480, and `isCollapsed` restored from the persisted setting. Slides are driven by a `CADisplayLink` created from the view, running in the common run loop mode, which sets the shelf host's width constraint and calls `layoutSubtreeIfNeeded()` on the split view each frame; `item.animator().isCollapsed` is avoided because it lays contents out once at the final size. Drag detection uses `NSSplitView.willResizeSubviewsNotification` and `didResizeSubviewsNotification` rather than the delegate method, which the superclass does not offer for overriding, and a 250 millisecond `Task.sleep` for settle. `beginAnimatedResize` and `endAnimatedResize` on the content view are helpers from the surrounding framework. Backdrop colors come from a `ThemePaletteObserver`. `init(coder:)` is unavailable and `deinit` is `isolated`. UIKit has no equivalent controller; `UISplitViewController` is the nearest, with different collapse semantics.
- **WinUI 3**: Use a `Grid` with two `ColumnDefinition`s: a shelf column with `MinWidth="180"`, `MaxWidth="480"` and a `Width` bound to the persisted value, and a content column with `MinWidth="300"` and `Width="*"`. Place a `GridSplitter` (Windows Community Toolkit `CommunityToolkit.WinUI.Controls.GridSplitter`) between them, with `ResizeBehavior="PreviousAndNext"`, a thin 1 epx visual and the `Focus` visual state for keyboard resizing with Left and Right arrows. Slide the column by animating its width in code with a `CompositionTarget.Rendering` handler or a `DoubleAnimation` with `EnableDependentAnimation="True"` over 0.2 seconds with a `CubicBezierEase` approximating smoothstep, because `ColumnDefinition.Width` is a layout property and a composition-only animation would not re-lay the content out. Extend each pane's backdrop under the title bar with `Window.ExtendsContentIntoTitleBar = true` and `SetTitleBar`, drawing the shelf's `Background` as `ThemeResource` brushes, and pad the content with the title bar's height. Persist visibility and width in `ApplicationData.Current.LocalSettings`. Pair the slide with the will-move and did-move notifications around the animation. Honor the system's animation setting through `UISettings.AnimationsEnabled`.

## Design Decisions

**Decision**: The shelf is a plain split item in a plain split view, not a sidebar item in a themed split view.
**Rationale**: The source documents this as the Conversations shelf's shape: sidebar material is drawn by the appearance and reaches no theme, and the themed split view's divider color is what trapped Conversations at launch.
**Approved**: pending

**Decision**: The slide is walked by hand through the shelf host's width constraint on every display frame, not by an animated collapse and not by moving the divider.
**Rationale**: Per the source comment, an animated collapse lays contents out once at the final size, so a web view jumps to its end width on the first frame while its pane slides to meet it; setting a divider near zero collapses a collapsible item, and a set divider is undone by the next layout pass in favor of the constraint.
**Approved**: pending

**Decision**: The walked width sits at priority 999 and the window width is held required during the slide.
**Rationale**: The walked width and the panes' held shares sit above the window's own stay-put priority of 500, so once a pane reached its minimum the layout widened the window instead of stopping the shelf; held, the window keeps its size and what cannot fit is the shelf's width or a share.
**Approved**: pending

**Decision**: On the first uncollapse after a launch that began collapsed, the window frame is put back to what it was before.
**Rationale**: Per the source comment, that first uncollapse grows the window by the shelf's remembered width as if the shelf were added beside the content, whereas the shelf should take its room from the panes.
**Approved**: pending

**Decision**: Shelf moves are told apart from window resizes by comparing the split view's width with its width at the last resize, and a drag is finished when it has rested for 250 milliseconds.
**Rationale**: Per the source, AppKit has no notification for the user letting go of a divider, and the window holds each pane at its share of the width only across shelf moves, not window resizes.
**Approved**: pending

**Decision**: While a slide or adoption holds the shares, resize notifications do not raise the move callbacks, and sliding out reads shares before the first step.
**Rationale**: Per the source comment, sliding out AppKit lays the content out at its final width before the first step, so shares read at a step would already be lopsided.
**Approved**: pending

**Decision**: The visibility callback fires both when an animated change starts and when it ends, although its documentation says "after the shelf has finished".
**Rationale**: The source calls it at the end of the slide-starting function and again when the slide lands; the component's callers repaint the toggle from the state reached, which both calls report correctly (the first reports the destination). A port that fires it once at the start keeps that behavior.
**Approved**: pending

**Decision**: The opening width requested at construction is the raw persisted width, while sliding in uses the clamped width.
**Rationale**: The source applies the clamp only in the slide path; the pane's own minimum and maximum thickness constrain the construction path. Technical debt that does not change the visible result inside 180 through 480 points.
**Approved**: pending

**Decision**: On a window with no shelf, visibility requests are ignored without running their completion.
**Rationale**: The source returns before the completion when there is no shelf item, which can leave a caller waiting; callers that pass a completion check has-shelf.
**Approved**: pending

**Decision**: A slide does not consult the system's Reduce Motion setting.
**Rationale**: No such check exists in source; this is recorded as the open question on `Reduce Motion` pending a policy on whether a width slide counts as motion to reduce.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |
| [adc.check.performance.animation-frame-rate](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9eb9b4fc-2e44-5391-9445-d6e78caa874e) | passed | Performance |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`keyboard-navigable` is `partial`: the shelf-panel toggle is a keyboard path for showing, hiding and focusing the shelf, but the open question on `keyboard-divider-resize` records that no keyboard path moves the divider. `reduced-motion` fails because the slide never consults the system setting (see the open question on `Reduce Motion`). `platform-theming` passes because both backdrops come from the theme palette and are re-applied on a theme change. `animation-frame-rate` passes because the slide lays out once per display frame and ends by wall-clock progress. `state-recovery` passes because the shelf's visibility and width are persisted and restored at launch. `separation-of-concerns` is `partial`: the component delegates the shelf's contents, the pane shares and the window's reaction to callbacks, but it also owns the persistence writes, the slide engine and the window-width hold in one type. `unit-test-coverage` fails because the only test beside the source asserts the controller's type; no test drives a slide, a drag, a restore or a layout adoption.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial recipe extracted from the macOS `ProjectWindowSplitViewController` source. |
