---
id: 31a21ecf-cf6a-42d8-bae5-3b482f8d554d
title: Window Drawer
domain: adhsdk://recipes/window-drawer
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A tabbed drawer that slides out beside a window's trailing edge, providing
  lazy-loaded tab content without reflow.
platforms:
- swift
- macos
tags:
- drawer
- window-chrome
- navigation
depends-on: []
related: []
references:
- https://developer.apple.com/documentation/appkit/nsdrawer
- https://developer.apple.com/documentation/appkit/nssegmentedcontrol
approved-by: ''
approved-date: ''
---

# Window Drawer

## Overview

A tabbed drawer that slides out beside a window's trailing edge, leaving the window's content unaffected. The drawer lazily loads tab content, renders with the theme's window background color, and allows the user to drag the outer edge to resize horizontally. Designed to present optional, contextual content (help, settings, details) without reflow or visual discontinuity.

## Behavioral Requirements

- **open-and-close**: Component MUST support `open()` and `close()` methods to show and hide the drawer.
- **open-with-tab-selection**: Component MUST accept an optional tab ID in `open(selecting:)` to select a specific tab before opening.
- **toggle-state**: Component MUST support `toggle(selecting:)` to open on a tab if closed, or close if already open on that tab.
- **lazy-load-tabs**: Component MUST create a tab's view only on first access via `view(forTab:)`, and retain it thereafter. MUST cache views so repeated access returns the same instance. For an id that names none of the drawer's tabs, `view(forTab:)` MUST return `nil` and MUST NOT cache anything.
- **track-open-state**: Component MUST expose an `isOpen` boolean that is true while the drawer is open or transitioning to open, and false otherwise.
- **track-selected-tab**: Component MUST expose `selectedTabID`, identifying which tab is currently shown; it defaults to the first tab.
- **announce-visibility-changes**: Component MUST invoke `onVisibilityChange` after every open, close, or drag-initiated visibility change. A single change MAY produce more than one invocation.
- **honor-dragged-close**: Component MUST detect when the user drags the drawer closed at the outer edge, as distinct from a programmatic close, via the `closeIsAttributableToTheReader` property.
- **clamp-content-width**: Component MUST accept content width in the range 220–520 points; values outside this range MUST be clamped to the nearest bound. NaN and infinite values MUST fall back to the default width (300 points).
- **expose-content-width**: Component MUST expose `contentWidth` as a getter and setter, allowing the caller to read and persist the width the user dragged it to.
- **hide-single-tab-strip**: Component MUST hide the tab strip when fewer than two tabs are present at initialization.
- **use-tab-symbols**: Component MUST display a system symbol image for each tab in the strip, paired with the tab title.
- **use-theme-colors**: Component MUST paint the drawer's background using the theme's `windowBackground` role, and MUST repaint any border chrome drawn by the underlying platform control in the same role, so the drawer's edge does not mismatch the app's theme (e.g., a light system-drawn rim on a dark drawer).
- **sync-height-at-open**: Component MUST re-read the parent window's height at `open()` time, so a window assembled before toolbar growth or frame restoration is still sized correctly.
- **reapply-remembered-state-on-window-key**: Component MUST invoke `reapplyVisibility` when the parent window becomes key or main, so a caller can re-open a remembered drawer that was dropped during `init`.
- **accessibility-prefixed-ids**: Component MUST accept `accessibilityPrefix` and namespace all accessibility identifiers under it: `<prefix>` for the container, `<prefix>.tabs` for the strip, `<prefix>.tab.<id>` for the body.
- **release-delegate-on-deinit**: Component MUST clear any reference the underlying platform control holds back to this wrapper when the wrapper is deallocated, so the control cannot message a freed instance.

## Appearance

- **Corner radius**: None; drawer inherits NSDrawer's system-drawn frame.
- **Padding**: Tab strip: 8pt top margin, centered horizontally. Body: 32pt top (when strip shown) or 0pt (when hidden), fill remaining drawer space.
- **Font**: Tab titles use system font; symbol images are system symbols scaled by AppKit's NSSegmentedControl.
- **Background**: Theme's `windowBackground` role for container and bezel overlay.
- **Foreground/Text**: Theme text color via ThemedBackgroundView.
- **Border**: AppKit draws NSDrawerFrame border; bezel overlay repaints it in theme color to avoid system-appearance rim.
- **Shadow**: None; NSDrawer's frame provides system shadow.
- **Min/Max size**: Width draggable between 220–520 points (default 300). Height is window height; locked (not draggable).

## States

| State | Appearance Change |
|-------|------------------|
| Closed | Drawer is hidden; no drawer frame or bezel visible. |
| Opening | Drawer slides into view from the window's trailing edge. |
| Open | Drawer fully visible; edge is draggable. |
| Dragging | Cursor changes to resize indicator; drawer width follows mouse horizontally, clamped to bounds. |

## Accessibility

- **Role**: Container is a group; tab strip is a button group (NSSegmentedControl); each tab is a button-like segment.
- **Label requirements**: Each segment is labeled with its tab title (from `DrawerTab.title`). System symbol images include `accessibilityDescription` (title) for screen readers.
- **Announce state changes**: Tab selection change MUST update the body's accessibility ID to `<prefix>.tab.<id>` so screen readers track the active pane. Visibility changes do not require additional announcement (caller handles state memory).
- **Control size**: Tab strip uses NSSegmentedControl's default `.regular` control size (about 24–28pt tall). macOS HIG sizes pointer-driven controls by control size, not by the 44×44pt touch-target minimum that applies on iOS; no additional minimum is imposed here.
- **Keyboard navigation**: Tab selection MUST be operable via arrow keys and Return (NSSegmentedControl standard behavior); drawer open/close MUST be programmatic or draggable, not keyboard-initiated.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|-------|---------|
| drawer-001 | open-and-close | Call `open()` on closed drawer. | `isOpen` becomes true; drawer frame is visible. |
| drawer-002 | open-and-close | Call `close()` on open drawer. | `isOpen` becomes false; drawer frame is hidden. |
| drawer-003 | open-with-tab-selection | Call `open(selecting: "help")` with tab ID "help" present. | Drawer opens and body shows "help" tab content. |
| drawer-004 | open-with-tab-selection | Call `open(selecting: "nonexistent")` on a freshly initialized drawer (currently selected tab is the first tab). | Drawer opens; the invalid ID is ignored and the currently selected tab (the first tab) keeps showing. |
| drawer-005 | toggle-state | Call `toggle()` on closed drawer. | Drawer opens on currently selected tab. |
| drawer-006 | toggle-state | Call `toggle()` on open drawer. | Drawer closes. |
| drawer-007 | toggle-state | Call `toggle(selecting: "other")` while open on "help". | Drawer remains open and switches to "other" tab. |
| drawer-008 | toggle-state | Call `toggle(selecting: "help")` while open on "help". | Drawer closes. |
| drawer-009 | lazy-load-tabs | Call `view(forTab: "tab1")` once; call again. | Both calls return the same NSView instance (not newly created). |
| drawer-010 | lazy-load-tabs | Call `view(forTab: "missing")`, where "missing" names no tab. | Returns `nil`; no view is cached. |
| drawer-011 | track-open-state | Observe `isOpen` before and after `open()`. | Returns false initially, true after `open()` completes. |
| drawer-012 | track-selected-tab | Initialize with tabs `[tab1, tab2]`. | `selectedTabID` is "tab1" (first tab). |
| drawer-013 | track-selected-tab | Call `open(selecting: "tab2")`. | `selectedTabID` becomes "tab2". |
| drawer-014 | announce-visibility-changes | Set `onVisibilityChange` callback; call `open()`. | Callback is invoked at least once; it may be invoked twice (once from `open()`, once from the platform's own open notification). |
| drawer-015 | honor-dragged-close | Open drawer; user drags outer edge closed by hand. | Callback is invoked; `closeIsAttributableToTheReader` is true. |
| drawer-016 | honor-dragged-close | Open drawer; call `close()` programmatically. | `closeIsAttributableToTheReader` is false. |
| drawer-017 | honor-dragged-close | Minimize parent window (drawer auto-closes). | `closeIsAttributableToTheReader` is false. |
| drawer-018 | honor-dragged-close | Parent window deallocates. | `closeIsAttributableToTheReader` is false (weak `parentWindow` becomes nil). |
| drawer-019 | clamp-content-width | Set `contentWidth = 150` (below min 220). | `contentWidth` is clamped to 220. |
| drawer-020 | clamp-content-width | Set `contentWidth = 600` (above max 520). | `contentWidth` is clamped to 520. |
| drawer-021 | clamp-content-width | Set `contentWidth = .nan`. | `contentWidth` falls back to default 300. |
| drawer-022 | clamp-content-width | Set `contentWidth = .infinity`. | `contentWidth` falls back to default 300. |
| drawer-023 | expose-content-width | Read `contentWidth` after initialization with default. | Returns 300.0. |
| drawer-024 | expose-content-width | Set `contentWidth = 400`; read it back. | Returns 400.0. |
| drawer-025 | hide-single-tab-strip | Initialize with 1 tab. | `tabStripIsHidden` is true. |
| drawer-026 | hide-single-tab-strip | Initialize with 2+ tabs. | `tabStripIsHidden` is false. |
| drawer-027 | use-tab-symbols | Initialize with tabs specifying SF symbol names. | Each segment displays the symbol image; image is non-nil. |
| drawer-028 | use-theme-colors | Observe `contentView`'s theme role after initialization. | Role is `windowBackground` (not `.surface`); the container and the platform-drawn border chrome match, with no contrast seam at the drawer's edge. |
| drawer-029 | sync-height-at-open | Initialize drawer while parent window frame height is 0; later set frame height to 800. Call `open()`. | `contentHeight` reflects 800 (not 0). |
| drawer-030 | reapply-remembered-state-on-window-key | Set `reapplyVisibility` callback to call `open()`. Initialize drawer; window not yet on-screen. Window becomes key. | Callback is invoked; drawer opens. |
| drawer-031 | accessibility-prefixed-ids | Initialize with `accessibilityPrefix = "help"`; select tab "settings". | Container ID is "help"; strip ID is "help.tabs"; body ID is "help.tab.settings". |
| drawer-032 | release-delegate-on-deinit | Initialize a drawer, release the only strong reference to it, then trigger an event the platform would otherwise deliver to its delegate (e.g., post the parent window's key/main notification). | No crash and no delegate callback fires against the deallocated instance. |

## Edge Cases

- **Single tab, no user action**: Drawer with one tab hides the strip and renders cleanly; tab count is fixed at initialization, so the strip's hidden state never needs to change after `init`.
- **Width clamped at init**: Initialize with `contentWidth: -50` or `999`. Value is clamped before NSDrawer receives it; user can drag within clamped range.
- **NaN width from string parsing**: If width is parsed from user defaults as `Double("nan")` or `Double("inf")`, fallback to 300 prevents invisible drawer.
- **Window closes while drawer open**: Weak reference to parent window prevents dangling pointer; drawer is cleaned up by NSWindow.
- **Window minimized**: Drawer auto-closes; `isOpen` becomes false; `closeIsAttributableToTheReader` is false (not attributed to user action).
- **Drawer edge flipped at screen boundary**: AppKit automatically flips drawer to opposite edge; no logic needed; caller receives same object with edge flipped.
- **Open called while opening**: AppKit's NSDrawer state machine handles overlapping calls; open is idempotent if drawer is already opening.
- **Tab ID invalid during select**: Invalid ID is silently ignored; drawer keeps showing current tab (fail-safe behavior to prevent blank drawer).
- **Parent window height = 0 at init**: Height is not cached from init; re-read at `open()` time, so construction order does not matter.
- **Bezel needs reinstall after NSDrawer rebuilds**: NSDrawer rebuilds NSDrawerFrame when edge changes or contentView is reassigned; `installBezelIfNeeded()` idempotently reattaches bezel to the current frame.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `parentWindow` | NSWindow | (required) | The window the drawer is attached to. |
| `accessibilityPrefix` | String | (required) | Namespace for accessibility IDs; e.g., "help" produces IDs like "help.tabs" and "help.tab.settings". |
| `tabs` | [DrawerTab] | (required) | Array of tab definitions; each has `id`, `title`, `symbolName`, and lazy view factory. Fixed at initialization; there is no API to add or remove tabs afterward. |
| `contentWidth` | CGFloat | 300 | Initial width in points; clamped to 220–520 on init and on setter. |
| `onVisibilityChange` | `(() -> Void)?` | `nil` | Callback invoked after every open, close, or drag-initiated visibility change. |
| `reapplyVisibility` | `(() -> Void)?` | `nil` | Callback invoked when the parent window becomes key or main; lets the caller re-open a remembered drawer that was dropped during `init`. |

## Deep Linking

Not applicable: AppKit drawers are window-internal views and do not support URL routing. Deep linking is caller's responsibility if the app implements URL schemes that should open specific tabs.

## Localization

Not applicable: Tab titles and accessibility labels are provided by the caller via `DrawerTab.title` and symbol accessibility descriptions; the component does not define any strings.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | NSSegmentedControl animation is system-controlled; AppKit honors system motion settings automatically. NSDrawer slide animation respects system reduce-motion preference. |
| Increase Contrast | Tab strip uses NSSegmentedControl system styling; increased contrast is handled by AppKit's theme system. Bezel uses theme's `windowBackground` role, which respects contrast settings. |
| Differentiate Without Color | Segments are labeled with text and images; selection is shown by both color and a filled segment state (not color alone). |

## Feature Flags

Not applicable: Component has no internal feature flags. Enablement is caller's responsibility.

## Analytics

Not applicable: Component does not emit analytics events. Caller may instrument `onVisibilityChange` and tab selection to track user behavior.

## Privacy

Not applicable: Component does not collect, store, or transmit any user data.

## Logging

Not applicable: Component produces no internal logging. Caller may log visibility changes and tab selections as needed for debugging.

## Platform Notes

- **Swift (AppKit source)**: Use `NSDrawer` directly or wrap with `WindowDrawer`. The wrapper provides tabbed interface, lazy loading, and theme integration. Key files: `WindowDrawer.swift` (main class), `DrawerTab` struct (tab definition), `MouseTransparentView` (hit-test bypass for bezel overlay). Notably, `NSDrawer` is deprecated since macOS 10.13 but remains functional; the deprecation attribute allows wrapper to use NSDrawer without compiler warnings bleeding into caller code. `isOpen` maps to `NSDrawer.State.openState`/`.openingState`; the wrapper's `deinit` clears `NSDrawer.delegate` because that property is `assign` (`unowned(unsafe)` on the Swift side) and the parent window keeps the underlying `NSDrawer` alive past the wrapper's own lifetime. The theme-colored bezel is a mouse-transparent overlay laid under the drawer's content and over AppKit's own `NSDrawerFrame`, which otherwise draws its border in the system appearance regardless of the app's theme.

- **SwiftUI**: There is no native SwiftUI equivalent to `NSDrawer`; it must be wrapped via `NSViewRepresentable`/`NSViewControllerRepresentable`, or exposed through a view modifier applied to *view* content, not to a `Scene`. A SwiftUI wrapper would need to own the underlying `WindowDrawer` instance and bridge tab view builders to `DrawerTab` closures. Consider `struct WindowDrawerModifier: ViewModifier { let tabs: [DrawerTab] }` applied to the window's root content view (e.g. `WindowGroup { ContentView().modifier(WindowDrawerModifier(tabs: tabs)) }`), since `ViewModifier` only composes with `View`, not with `Scene` types like `Window`/`WindowGroup`.

- **Jetpack Compose (Android)**: `ModalNavigationDrawer` is a scrim-backed overlay and contradicts the "beside the window, no reflow" requirement; `BottomDrawerScaffold` predates Material 3. Android has no exact analog to a panel that extends past its own window's bounds, so the nearest fit is `PermanentNavigationDrawer` (Material 3) or a custom `Row` with an `AnimatedVisibility` side panel — both share width with the content rather than floating beside the window, so some reflow is unavoidable on this platform. Content should lazily load `Composable` functions similar to `DrawerTab.makeView`. Accessibility prefixes map to `testTag()` modifiers for each drawer region. Width is not draggable on Android; preset a width or use a percentage of the available space.

- **AppKit / UIKit (native)**: On macOS, use `NSDrawer` directly or the `WindowDrawer` wrapper. On iOS/iPadOS, use `UISplitViewController` or a custom modal drawer, as `NSDrawer` is macOS-only. Width dragging must be implemented via a custom gesture recognizer on iOS. Tab strip maps to `UISegmentedControl` or `UITabBarController`. Accessibility IDs map to `accessibilityIdentifier` on UIKit.

- **WinUI 3**: `NavigationView`'s `PaneDisplayMode.LeftMinCompact`/`.LeftCompact` place the pane on the leading edge and cannot be flipped to trailing, so it does not fit here; instead, build a custom `Grid` with two columns — content, then the drawer pane on the right (or the left, mirrored, for RTL). Tab strip maps to `NavigationViewItem` or a separate `RadioButton` group inside that pane. Width dragging uses a `GridSplitter` between the columns (from the Windows Community Toolkit, `CommunityToolkit.WinUI.Controls.Primitives` — not built into the WinUI 3 SDK); set `MinWidth="220"` and `MaxWidth="520"` on the drawer's `Grid.Column`. Theme colors use `x:ThemeResource` XAML bindings to current WinUI 3 brushes, e.g. `ApplicationPageBackgroundThemeBrush` for the window-background equivalent, rather than the legacy `SystemControl*` brush family. Bezel overlay is handled by the pane's own `Border` background, painted in the same brush as the content.

## Design Decisions

**Lazy tab loading**
**Decision**: Tabs are views created on demand by a factory closure, not eagerly.
**Rationale**: This allows windows with many possible tabs to avoid upfront cost and memory bloat. A tab never opened costs nothing. Views are retained once made, avoiding repeated allocation if the user switches tabs multiple times.
**Approved**: pending

**Idempotent visibility callbacks**
**Decision**: `onVisibilityChange` may be called multiple times for a single open or close (once from the programmatic call, once from NSDrawer's delegate callback); callers MUST make their callbacks idempotent.
**Rationale**: This design avoids losing information: if the callback were called only once, a programmatic open made while the drawer is still animating would not notify, and an app that persists state would miss the change.
**Approved**: pending

**Width handling at init**
**Decision**: Width is clamped at initialization, before NSDrawer receives it, and NaN/infinity fall back to the default rather than being clamped to a bound.
**Rationale**: A bad remembered value (from a previous version or corrupt storage) cannot create an undraggable drawer this way. NaN and infinity carry no meaningful data, so the default is safer than a guess at which bound was meant.
**Approved**: pending

**Height re-read at open**
**Decision**: Height is not cached from `init`; it is re-read at `open()` time.
**Rationale**: Drawers are often built before their windows are fully assembled (before toolbar, before frame restoration). Reading height at open time makes construction order irrelevant; the drawer adapts to its window's final size automatically.
**Approved**: pending

**Bezel overlay for theme border**
**Decision**: A mouse-transparent `ThemedBackgroundView` overlay repaints AppKit's `NSDrawerFrame` border in the theme's window background color.
**Rationale**: `NSDrawerFrame` draws its border opaquely in the *system* appearance, which can produce a white rim around a dark theme drawer. AppKit's frame cannot be told what color to be, but a subview drawn after it can; making that subview mouse-transparent keeps the outer-edge drag that resizes the drawer working.
**Approved**: pending

**closeIsAttributableToTheReader**
**Decision**: A drawer closes for three reasons — programmatic `close()`, user drag, or window shutdown — and only the drag is attributable to the user's choice; the component exposes that distinction as a single boolean.
**Rationale**: An app that persists "drawer open" must know the difference: a drag close means remember closed, a programmatic close during teardown means ignore this, and window minimize means ignore this. The property answers "was this the user?" without the caller having to guess.
**Approved**: pending

**AccessibilityPrefix**
**Decision**: All accessibility IDs are namespaced under a required prefix.
**Rationale**: Multiple drawers in the same app (e.g., one per window) would otherwise collide in test automation or assistive technology. Making the prefix required, not optional, enforces the namespace discipline.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | Platform Compliance |
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | passed | Platform Compliance |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Source basis: `NSSegmentedControl` labels every segment with its tab title and gives symbol images an `accessibilityDescription` (screen-reader-support, dynamic-type-support — system font, no fixed override); tab selection is keyboard-operable via the control's own arrow-key/Return behavior but open/close is programmatic-or-drag only, and control sizing, contrast, and reduce-motion all come from AppKit's `NSSegmentedControl`/theme system rather than anything `WindowDrawer` verifies itself (keyboard-navigable, contrast-ratio, touch-target-size, reduced-motion — partial); and the component wraps `NSDrawer`/`NSSegmentedControl` per HIG, painting both the container and the AppKit-drawn frame in the theme's `windowBackground` role (platform-design-language, native-controls-preference, platform-theming). `separation-of-concerns` passes because `WindowDrawer` knows neither whether it was open (that is its owner's) nor what a tab contains (a `DrawerTab` is just an id, title, symbol, and view factory), and `MouseTransparentView` is split out so "what colour" and "does it take clicks" stay independent; `unit-test-coverage` passes on `WindowDrawerTests.swift`'s exercise of open/close, tab selection, visibility announcements, width clamping, and delegate teardown.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from WindowDrawer.swift |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; moved NSDrawer/AppKit internals from requirements into Platform Notes; made announce-visibility-changes deterministic and reconciled the tab-selection and single-tab-strip edge cases; reformatted Design Decisions to Decision/Rationale/Approved; added a Compliance table; corrected the SwiftUI, Compose, and WinUI 3 platform notes; rewrote untestable or mismatched conformance vectors and retagged drawer-015; fixed the Opening-state and tap-target descriptions; added missing Configuration entries and API references. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
