---
id: 0c8a7db3-9948-466c-8c97-20de2ae53a17
title: "Pane Minimize Picker"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Four directional arrow buttons in a cross pattern within a popover, for selecting which edge a pane should minimize toward."
platforms:
  - swift
  - macos
tags:
  - pane-management
  - popover
  - directional-selection
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Pane Minimize Picker

## Overview

The Pane Minimize Picker is a directional arrow picker presented in a popover. It displays four arrows arranged in a cross (↑, ←, →, ↓) representing the four edges (top, leading, trailing, bottom). The picker allows users to select which direction a pane should minimize toward. Arrows corresponding to unavailable edges are disabled. The picker closes automatically after an edge is selected.

## Behavioral Requirements

- **render-four-arrows**: The component MUST render exactly four arrow buttons arranged in a cross pattern: top, leading, trailing, and bottom.
- **initialize-with-available-edges**: The component MUST accept an initial set of available edges at initialization and enable only those arrows.
- **disable-unavailable-arrows**: The component MUST disable arrow buttons for edges not in the available edges set.
- **invoke-callback-on-selection**: The component MUST invoke the onPick callback with the selected edge when an arrow is tapped.
- **close-popover-before-callback**: The component MUST close the popover before invoking the onPick callback.
- **support-dynamic-availability**: The component MUST update button enabled states when the available edges set is changed after initialization.
- **apply-theme-tint**: The component MUST apply primary text color to enabled arrows and tertiary text color to disabled arrows based on the current theme.
- **display-tooltips**: Each arrow button MUST display a tooltip with the edge's display name.

## Appearance

- **Layout**: 3×3 grid with center column and row empty, four arrow buttons at cardinal positions.
- **Button style**: Accessory bar action (AppKit system style).
- **Button content**: System symbol image only (SF Symbols), no text or border.
- **Grid spacing**: 2pt between rows and columns.
- **Padding**: 8pt on all sides (top, leading, trailing, bottom) around the grid.
- **Icon color (enabled)**: Primary text color from current theme (`palette.nsColor(.primaryText)`).
- **Icon color (disabled)**: Tertiary text color from current theme (`palette.nsColor(.tertiaryText)`).
- **Border**: None.
- **Popover anchor**: The popover is anchored to the invoking control, preferring the edge nearest available screen space. The reference AppKit implementation anchors from the `.minY` edge of the anchor view's bounds, in that view's own (typically flipped) coordinate space.

## States

| State | Appearance change |
|-------|------------------|
| Default (available) | Arrow button enabled, primary text tint. |
| Disabled (unavailable) | Arrow button disabled (visual disabled state), tertiary text tint. |
| Shown | Popover is visible. |
| Hidden | Popover is not visible. |

## Accessibility

- **Role**: Each arrow button is a button control.
- **Label**: Each button's accessibility label is the edge's exact `PaneEdge.displayName` string (see table below) — for example, "Minimize to Top", not "Minimize top".
- **ID**: Each button has an accessibility ID in the format `pane.minimize.{edge.rawValue}` (see table below).
- **Tooltip**: Each button's tooltip matches the same `displayName` string.
- **Symbol description**: The SF Symbol's accessibility description also matches the same `displayName` string.
- **Button size**: On macOS, arrows use the AppKit `.accessoryBarAction` bezel style, which renders well under 44×44pt; that is expected for a pointer-driven accessory control and is not a tap-target defect. The 44×44pt (iOS) / 48×48dp (Android) minimum applies to the touch-platform implementations in Platform Notes, not to this macOS control.
- **Keyboard**: Standard `NSButton` keyboard focus and activation (Tab to move focus, Space/Return to activate) apply; the component adds no custom key handling beyond `NSPopover`'s default `.transient` dismissal (see Edge Cases).

### PaneEdge reference

| `PaneEdge` raw value | Display name (label / tooltip / symbol description) | Accessibility ID | SF Symbol |
|---|---|---|---|
| top | Minimize to Top | pane.minimize.top | arrow.up |
| leading | Minimize to Left | pane.minimize.leading | arrow.left |
| bottom | Minimize to Bottom | pane.minimize.bottom | arrow.down |
| trailing | Minimize to Right | pane.minimize.trailing | arrow.right |

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-minimize-001 | render-four-arrows | Initialize PaneMinimizeCrossView with any available edges set | Grid contains exactly four buttons at top, leading, trailing, and bottom positions. |
| pane-minimize-002 | initialize-with-available-edges | Initialize with availableEdges = {.top, .leading} | Top and leading buttons are enabled; trailing and bottom buttons are disabled. |
| pane-minimize-003 | disable-unavailable-arrows | Initialize with availableEdges = {} | All four buttons are disabled. |
| pane-minimize-004 | invoke-callback-on-selection | availableEdges = {.top}; user taps top arrow | onPick callback is called with .top. |
| pane-minimize-005 | close-popover-before-callback | Picker is shown (isShown == true); user taps an available arrow | onPick's closure observes isShown == false at the moment it is called — the popover has already closed before onPick runs. |
| pane-minimize-006 | support-dynamic-availability | Initialize with {.top}; set availableEdges = {.top, .leading} | Leading button transitions from disabled to enabled; tint color updates immediately. |
| pane-minimize-007 | apply-theme-tint | Initialize with availableEdges = {.top, .leading}; inspect contentTintColor of all four buttons | Top and leading buttons' contentTintColor equals the theme's primaryText color; bottom and trailing buttons' contentTintColor equals the theme's tertiaryText color. |
| pane-minimize-008 | display-tooltips | Hover over any arrow button | Tooltip appears with the edge's display name. |

## Edge Cases

- **Empty available edges set**: If availableEdges is empty, all four buttons are disabled. User cannot select any edge, and onPick is not invoked if a disabled button is tapped. The popover remains open.
- **All edges available**: If availableEdges contains all four edges, all buttons are enabled. User can select any direction.
- **Availability change while popover is shown**: If availableEdges is updated while the popover is displayed, button states update immediately without closing the popover.
- **Button not found**: The component creates one button per `PaneEdge` case in `init`, so every edge always has a button. If that invariant were ever violated, the component fails fast instead of returning an unhandleable `nil` (see the AppKit platform note for the reference mechanism).
- **Disabled button interaction**: Tapping a disabled arrow button has no effect (platform buttons ignore taps when disabled).
- **Dismissal without selection**: The popover uses AppKit's `.transient` behavior, so it also closes on click-outside or Escape without a selection; onPick is wired only to the button-tap handler, so these dismissal paths never invoke it.
- **Right-to-left layout**: The cross's grid columns are fixed by ordinal position (leading's button is always in the left column, trailing's in the right column), and each edge's SF Symbol (`arrow.left` / `arrow.right`) is hardcoded rather than mirrored. In RTL locales the leading/trailing arrows do not swap sides or direction the way a mirrored layout would.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| availableEdges | `Set<PaneEdge>` | (required) | Set of edges for which arrows should be enabled. |
| onPick | (PaneEdge) -> Void | (required) | Callback invoked with the selected edge after the popover closes. |

## Deep Linking

Not applicable: This is a UI picker component with no deep linking requirement. Edge selection is local to the pane layout interaction.

## Localization

`PaneEdge.displayName` hardcodes its four label strings in English ("Minimize to Top", "Minimize to Left", "Minimize to Bottom", "Minimize to Right") directly in the enum; these strings are used verbatim as the accessibility label, the tooltip, and the SF Symbol's accessibility description. The component, not the calling code, owns these strings, and they are not currently externalized to a localization resource — see **string-externalization** in Compliance.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Platform default: popover presentation respects system reduce-motion setting. |
| Increase Contrast | Platform default: button tint colors are derived from theme palette, which SHOULD respect contrast settings. |
| Differentiate Without Color | Not applicable: Component relies on arrow symbols and position, not color alone, to convey direction. |

## Feature Flags

Not applicable: This component is a foundational UI element with no feature flag gating in the source.

## Analytics

Not applicable: The component does not emit analytics events. Event logging is the responsibility of the calling code.

## Privacy

Not applicable: This component does not collect, store, or transmit any user data.

## Logging

Not applicable: The component does not emit log messages in the source code.

## Platform Notes

- **Apple (AppKit)**: Implemented in `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/PaneMinimizePicker.swift`. The `PaneMinimizeCrossView` constructs a 3×3 `NSGridView` with four `NSButton` instances positioned at cardinal points, stored in a `[PaneEdge: NSButton]` dictionary. Button state is managed via `isEnabled` and `contentTintColor` properties; `button(for:)` looks buttons up in that dictionary and raises `fatalError` rather than returning `nil` (see Edge Cases). Tint color is kept current via a reactive `observeTheme` binding. The `PaneMinimizePicker` wraps the cross in an `NSPopover` with transient behavior and shows it relative to an anchor view at the minY edge.
- **SwiftUI**: Start from a grid-based container (e.g., `Grid` with custom layout or nested stacks in a 3×3 arrangement). Use `Button` views with SF Symbols for arrow images. Bind button disabled state to the availableEdges set. Use an `@State` popover presentation modifier to show/hide the picker. Apply theme-aware foreground colors using `.foregroundStyle()` based on enabled/disabled state (`.foregroundColor()` is deprecated). Call the onPick closure and dismiss the popover on button tap.
- **Compose (Android)**: Arrange four `IconButton` instances in a cross pattern using a `Box` with custom layout, or nested `Column`/`Row` (Compose has no `GridLayout`). Supply Material icons — `Icons.Filled.KeyboardArrowUp`/`KeyboardArrowDown` for the vertical arrows, and `Icons.AutoMirrored.Filled.KeyboardArrowLeft`/`KeyboardArrowRight` for the horizontal arrows so they mirror correctly in RTL locales. Disable buttons by setting `enabled = false` on the `IconButton`. Present the cross in a `Popup` composable (Compose has no `PopupMenu` that hosts arbitrary content). Invoke the callback and dismiss the popup on button click.
- **AppKit / UIKit (iOS)**: Construct a 3×3 grid using `UIStackView` with arranged subviews. Use `UIButton` with system arrow images. Toggle button enabled state via `isEnabled`. Present the picker in a `UIPopoverPresentationController` (iPad) or a sheet/modal (iPhone). Invoke the callback and dismiss after selection.
- **WinUI 3**: Build a 3×3 Grid in XAML with four `Button` controls at cardinal positions. Use `SymbolIcon` with arrow symbols (e.g., `SymbolIconSource` with "Up", "Left", "Right", "Down" glyphs from the Fluent icon set). Bind button `IsEnabled` to the available edges set. Bind `Foreground` color to a converter that selects primary or tertiary text color based on `IsEnabled`. Wrap the grid in a `Flyout` attached to a trigger button (a `MenuFlyout` cannot host arbitrary content like a Grid). Invoke the callback from the button `Click` event handler and close the flyout before invoking onPick.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/PaneMinimizePicker.swift` | unverified |

## Design Decisions

- **Decision**: Use `NSGridView` rather than nested `NSStackView` to construct the cross layout.
  **Rationale**: The grid layout structurally conveys the cross shape — a user sees four directions around a center — which improves code clarity and maintainability (`simplicity`, `explicit-over-implicit`).
  **Approved**: pending

- **Decision**: Keep `PaneMinimizeCrossView` (the cross buttons) separate from `PaneMinimizePicker` (the popover wrapper).
  **Rationale**: This separation allows tests to verify button state without opening a popover (`tight-feedback-loops`).
  **Approved**: pending

- **Decision**: `button(for:)` raises `fatalError` rather than returning `nil` when a button cannot be found for an edge.
  **Rationale**: Buttons for all four edges are always created in `init` and stored in a `[PaneEdge: NSButton]` dictionary, so a `nil` return cannot be safely handled by any caller; fast failure is the correct semantics (`fail-fast`).
  **Approved**: pending

- **Decision**: Close the popover before invoking onPick.
  **Rationale**: The pane is about to change shape, and a popover anchored to a button inside it would be left pointing at a view that has moved.
  **Approved**: pending

- **Decision**: Update button tint color reactively via `observeTheme` whenever the theme changes.
  **Rationale**: Ensures the picker respects user theme preferences without requiring an explicit refresh call.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Screen-reader labels, tooltips, and identifiers come directly from `setAccessibilityLabel`, `toolTip`, and `accessibilityID` calls in `PaneMinimizePicker.swift`; keyboard/focus behavior relies on undocumented `NSButton`/`NSPopover` defaults, and the theme palette's actual contrast values aren't specified in this source, hence partial; the accessory-bar button size (well under 44×44pt) and `PaneEdge`'s hardcoded, unmirrored English strings and fixed grid columns are visible directly in `PaneMinimizePicker.swift` and `PaneEdge.swift`, hence failed. `separation-of-concerns` passes because `PaneMinimizeCrossView` only renders the offered `availableEdges` and reports a pick via `onPick`; per its own doc comment, it never computes which edges are legal, leaving that to the layout tree. `unit-test-coverage` passes because `PaneMinimizePickerTests.swift` covers every edge having a labelled button, the cross layout, offered/unoffered enablement (including re-applying it when the set changes), edge-click reporting, and the popover closing before it reports a pick.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Wrapped Set<PaneEdge> in code span; added best-practices Compliance rows. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, reformatted Design Decisions to Decision/Rationale/Approved, populated the Compliance table, corrected the accessibility tap-target claim and defined the PaneEdge display-name/ID/symbol table, moved AppKit implementation details out of Edge Cases and into the AppKit platform note, fixed inaccurate Compose/SwiftUI/WinUI platform APIs, documented transient-dismissal and RTL-mirroring gaps as edge cases, tightened test vectors 005 and 007, and clarified popover anchor placement |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
