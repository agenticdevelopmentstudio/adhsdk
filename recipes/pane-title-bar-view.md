---
id: 9c5e7d75-e253-4dce-b12c-7eaede9ee405
title: Pane Title Bar View
domain: adhsdk://recipes/pane-title-bar-view
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A fixed-height title bar for document panes with truncated title, trailing
  gear control, and variable accessory area.
platforms:
- swift
- macos
tags:
- ui
- chrome
- title-bar
depends-on:
- adhsdk://recipes/pane-control-cluster
related: []
references: []
approved-by: ''
approved-date: ''
---

# Pane Title Bar View

## Overview

The Pane Title Bar View is a reusable chrome component that renders the title bar for a document pane within a multi-pane editor. It provides four regions in left-to-right order: leading controls (close/minimize/zoom buttons), title text, accessory views supplied by the pane's content, and a trailing gear button for options. The title truncates in the middle when space is constrained, and the gear control remains at the trailing edge regardless of content width, establishing a consistent visual anchor across all panes in a window.

## Behavioral Requirements

- **render-title-label**: The component MUST render a text label displaying the current title text.
- **truncate-title-in-middle**: The component MUST truncate the title text in the middle (not at trailing edge) when the available width is insufficient to display the full title.
- **sync-tooltip-with-title**: The component MUST set the title label's tooltip to the full title text when the title is non-empty, and clear it (set to nil) when the title is empty.
- **render-fixed-height**: The component MUST have a fixed height of 26pt and MUST NOT resize vertically based on content.
- **leading-controls-cluster**: The component MUST include a `PaneControlCluster` positioned at the leading edge, 6pt from the leading edge, vertically centered within the bar.
- **bottom-separator**: The component MUST render a 1pt hairline separator spanning the full width of the bar, pinned to the bottom edge, using the themed border color.
- **support-accessory-views**: The component MUST support an ordered array of accessory views positioned between the title and the gear control.
- **replace-accessory-views-atomically**: When the accessory views array is replaced, the component MUST remove all previous accessory views from the view tree and add all new views in the provided array order.
- **support-optional-gear-view**: The component MUST support an optional gear view supplied by the pane owner and positioned at the trailing edge, with a default trailing margin of 6pt from the pane edge.
- **gear-trailing**: When a gear view is present, the component MUST keep it at the trailing edge and constrain all other content to its leading side, maintaining a 6pt gap between the accessory stack and the gear.
- **center-content-vertically**: The component MUST vertically center all child elements (controls, title label, accessory views, gear view) within the bar.
- **honor-yield-width-request**: When `yieldWidthToContainer()` is called, the component MUST set the content compression resistance priority of itself and all subviews (depth-first) to the lowest value (1) for the horizontal axis, allowing the container to constrain its width without resistance.
- **apply-yield-to-future-subviews**: When width-yielding is enabled, any accessory views or gear views added after the call to `yieldWidthToContainer()` MUST also have their compression resistance priority set to the lowest value for the horizontal axis.
- **accessory-spacing**: The component SHOULD maintain 4pt spacing between consecutive accessory views.

## Appearance

- **Height**: 26pt (fixed)
- **Background**: Themed elevated surface color (via ThemedBackgroundView with role `.elevatedSurface`)
- **Bottom border**: 1pt hairline separator using themed border color (via ThemedSeparatorView with role `.border`)
- **Title label**: 13pt body text role, primary text color (via ThemedLabel)
- **Accessory stack spacing**: 4pt between items, centered vertically
- **Leading margin**: 6pt from leading edge to controls cluster
- **Title leading margin**: 8pt from controls trailing edge to title label
- **Accessory leading margin**: 8pt minimum gap from title trailing edge to accessory stack leading edge (when title is visible)
- **Trailing margin**: 6pt from gear view (or accessory stack if no gear) to pane edge

## States

| State | Appearance change |
|-------|------------------|
| With title | Title text is displayed |
| Empty title | Title label is empty; tooltip is nil |
| No gear view | Accessory stack extends to trailing margin (6pt from edge) |
| Gear view present | Accessory stack stops at gear leading edge with 6pt gap |
| No accessory views | Accessory stack is empty; title and gear remain visible |

## Accessibility

- **Identifier**: The title label carries the accessibility identifier `pane.title` (via `accessibilityID`), used to locate the view in UI tests and automation — it is an identifier, not the announced label.
- **Label**: `NSTextField`'s accessibility label derives from `stringValue`, which always holds the full, untruncated title text. Visual middle-truncation (`lineBreakMode = .byTruncatingMiddle`) affects only the rendered glyphs, not `stringValue`, so VoiceOver announces the complete title even when the on-screen text is truncated.
- **Role**: The component itself is a container; child elements (title label, controls, gear) provide their own accessibility semantics.
- **Assistive technology**: The component does not announce state changes; it is a static chrome element.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-title-bar-001 | render-title-label | Initialize component; set title to "My File.txt" | Title label displays "My File.txt" |
| pane-title-bar-002 | sync-tooltip-with-title | Set title to "Long File Name"; then set title to "" | Tooltip equals "Long File Name" after first set; tooltip is nil after second set |
| pane-title-bar-003 | render-fixed-height | Initialize component; read height | Height is exactly 26pt |
| pane-title-bar-004 | truncate-title-in-middle | Set title to "VeryLongFileName.extension"; constrain pane width to 80pt | Title text truncates in middle (e.g., "VeryLong...extension") not "VeryLongFile..." |
| pane-title-bar-005 | support-accessory-views | Set accessoryViews to [viewA, viewB] | Both views appear in accessory stack in order |
| pane-title-bar-006 | replace-accessory-views-atomically | Set accessoryViews to [viewA]; then set to [viewC, viewD] | viewA is removed from view tree; viewC and viewD appear in order; no views are orphaned |
| pane-title-bar-007 | support-optional-gear-view | Initialize component; gearView is nil by default | Gear area is empty; accessory stack extends to trailing margin |
| pane-title-bar-008 | support-optional-gear-view, gear-trailing | Set gearView to a button; set accessoryViews to [viewA] | Gear button appears at trailing edge; viewA appears to its left with 6pt gap |
| pane-title-bar-009 | center-content-vertically | Initialize component; inspect layout | Title label centerY equals bar centerY; accessory stack centerY equals bar centerY; gear centerY equals bar centerY |
| pane-title-bar-010 | honor-yield-width-request | Call yieldWidthToContainer(); then constrain the bar's width to 0pt and lay out | Layout resolves with no unsatisfiable-constraint conflict; the bar renders at 0pt width because every subview's horizontal compression resistance is priority 1 |
| pane-title-bar-011 | apply-yield-to-future-subviews | Call yieldWidthToContainer(); then set gearView; inspect gear constraint | Gear has compression resistance priority 1 (minimum) for horizontal axis |
| pane-title-bar-012 | accessory-spacing | Set accessoryViews to [viewA, viewB]; inspect stack spacing | Spacing between viewA and viewB is 4pt |
| pane-title-bar-013 | support-optional-gear-view | Initialize component; do not set gearView; inspect accessoryStack trailing constraint | accessoryStack's trailing anchor constant equals -6pt relative to the bar's trailing anchor |
| pane-title-bar-014 | bottom-separator | Initialize component; inspect hairline view constraints | Hairline view's leading and trailing anchors equal the bar's leading and trailing anchors; its bottom anchor equals the bar's bottom anchor |
| pane-title-bar-015 | leading-controls-cluster | Initialize component; inspect controls view constraints | controls.leadingAnchor equals bar.leadingAnchor + 6pt; controls.centerYAnchor equals bar.centerYAnchor |

## Edge Cases

- **Empty title**: Setting title to empty string sets tooltip to nil. Subsequent title sets restore tooltip if title is non-empty.
- **Very long title**: Title truncates in middle; full text is preserved and is reachable via accessibility (see **truncate-title-in-middle**).
- **No accessory views**: Accessory stack is empty but present; layout remains valid with title and optional gear only.
- **Main-actor-only replacement**: `PaneTitleBarView` is `@MainActor`-isolated, so accessory-view replacement can never overlap with layout on another thread; each call to the `accessoryViews` setter runs to completion (old views removed, then new views added) before layout can observe an inconsistent state. See **replace-accessory-views-atomically**.
- **No gear view**: Accessory stack extends to 6pt trailing margin; setting gear later repositions accessory stack and activates new trailing constraint.
- **Width constraint below minimum**: When yielding width (**honor-yield-width-request**) and the container constrains the bar to a very narrow width, every subview's horizontal compression resistance is priority 1 (the lowest), so the title, accessory views, and the gear itself can all be compressed or clipped — the yield applies uniformly and does not exempt any one region.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | String | "" | The pane's title text, displayed in the label and as tooltip when non-empty. |
| `accessoryViews` | [NSView] | [] | Array of views to display between title and gear, in left-to-right order. |
| `gearView` | NSView? | nil | Optional view for the trailing gear button or menu control, positioned at trailing edge. |
| `controls` | `PaneControlCluster` (read-only) | instantiated internally | The leading close/minimize/zoom cluster; not configurable by callers beyond what `PaneControlCluster` itself exposes. See **leading-controls-cluster**. |
| `yieldWidthToContainer()` | Method | not called (opt-in) | One-way switch: sets the horizontal compression resistance of the bar and every current and future subview (including the gear) to priority 1. Cannot be undone; see **honor-yield-width-request** and **apply-yield-to-future-subviews**. |

## Deep Linking

Not applicable: This is a chrome component without user-addressable content requiring deep linking.

## Localization

Not applicable: The component displays no user-facing strings of its own; localization is the responsibility of the title text and accessory views supplied by the pane's content.

## Accessibility Options

Not applicable: The component does not respond to system accessibility display options (reduce motion, increase contrast, differentiate without color); it renders static chrome.

## Feature Flags

Not applicable: No feature flags are defined in the source code.

## Analytics

Not applicable: This component does not own analytics tracking; such concerns belong to the pane content and application layer.

## Privacy

Not applicable: The component does not collect, store, or transmit data.

## Logging

Not applicable: No logging is defined in the source code.

## Platform Notes

- **Source (AppKit/macOS)**: `PaneTitleBarView.swift` uses NSView, NSStackView, NSLayoutConstraint, and AppKit-specific classes (ThemedBackgroundView, ThemedSeparatorView, ThemedLabel, PaneControlCluster). The layout is achieved entirely via Auto Layout constraints. The title label has `lineBreakMode = .byTruncatingMiddle` to truncate in the middle. Compression resistance priorities are used to yield width to the container.

- **SwiftUI**: A SwiftUI equivalent would use HStack as the root container with fixed height via `.frame(height: 26)`. The title would be a Text view with `.lineLimit(1)` and `.truncationMode(.middle)`. Accessory views would be inserted into the HStack dynamically via a ForEach loop. The gear would be anchored to the trailing edge within the HStack. SwiftUI has no direct equivalent of compression-resistance priority; width-yielding maps instead to giving the title `.frame(minWidth: 0)` (so it can shrink to zero) combined with a lower `.layoutPriority` than the gear and accessory views, so the title is the first to give up space. Background and border would use ZStack with custom modifiers.

- **Compose (Android)**: A Compose equivalent would use Row with `modifier = Modifier.height(26.dp)` and `verticalAlignment = Alignment.CenterVertically` — not `Arrangement.Center`, which would center every child instead of pinning the gear to the trailing edge. The title would be a Text composable given `Modifier.weight(1f)` so it absorbs the available space and pushes the gear to the row's end, with `overflow = TextOverflow.MiddleEllipsis` (which now exists in Compose UI for center truncation) and `maxLines = 1`. Accessory views and the gear would be Box composables placed after the weighted title. Background would be applied via `modifier.background()`.

- **AppKit / UIKit**: AppKit (the source platform) implements this with NSStackView, NSView, and NSLayoutConstraint as described in the Source bullet above. A UIKit port (iOS) would replace NSStackView with UIStackView, NSView with UIView, and the NSTextField-backed `ThemedLabel` with a UILabel using `lineBreakMode = .byTruncatingMiddle`. UIStackView's `alignment = .center` handles vertical centering, and the same NSLayoutConstraint API carries over unchanged. UIAppearance or custom view subclasses would replace the themed views (`ThemedBackgroundView`, `ThemedSeparatorView`, `ThemedLabel`).

- **WinUI 3**: A WinUI 3 equivalent would use a `Grid` with three columns (`Auto`, `*`, `Auto`) rather than a horizontal `StackPanel`, because a `StackPanel` lays out children back-to-back and ignores `HorizontalAlignment="Right"` on them. The leading controls cluster occupies the first `Auto` column; the title (`TextBlock` with `TextTrimming="CharacterEllipsis"` — center-truncation needs a custom TextBlock subclass or layout override) and the accessory stack occupy the `*` column; the gear `Button` occupies the trailing `Auto` column, which keeps it pinned regardless of what the middle column contains. `Height="26"` (pixels) sets the fixed height. Width-yielding maps to setting the `*` column's `MinWidth` to `0`.

## Design Decisions

- **Decision**: The title truncates in the middle rather than at the trailing edge.
  **Rationale**: File names keep their extension and distinguishing suffix visible when the middle is elided instead of the end — "VeryLong…extension" still identifies the file, where "VeryLongFile…" would not. (The gear's trailing position is held by its own layout constraints, not by the title's truncation mode.)
  **Approved**: pending

- **Decision**: The bar has a fixed height of 26pt.
  **Rationale**: 26pt accommodates a 13pt label and a small square button while keeping chrome minimal, so a three-pane editor does not spend a quarter of its height on chrome — a deliberate trade-off between readability and usable content area.
  **Approved**: pending

- **Decision**: `yieldWidthToContainer()` is opt-in; it is not called by default.
  **Rationale**: The default respects the intrinsic width needs of the title and controls. A container that divides width among panes (e.g., a split view) calls it explicitly to override that preference for constrained layouts; the switch is one-way because restoring would mean remembering a per-view priority for a case that never happens.
  **Approved**: pending

- **Decision**: Reassigning `accessoryViews` removes all old views from the view tree before adding the new ones.
  **Rationale**: This atomic replacement prevents old and new views from briefly coexisting, keeping layout consistent and predictable.
  **Approved**: pending

- **Decision**: The title label's tooltip is kept in sync with the title text.
  **Rationale**: When the title truncates, hovering reveals the full text — a standard AppKit pattern that avoids separate UI for displaying the complete title.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The accessibility statuses are partial because the source sets only an accessibility identifier (`pane.title`) and leaves label, dynamic type, and contrast behavior to AppKit defaults and the themed dependencies (`ThemedLabel`, `ThemedBackgroundView`) rather than defining them itself; the internationalization statuses are passed because the source has no hardcoded user-facing strings, displays title text through `NSTextField`'s native Unicode handling, and lays out using leading/trailing (not left/right) anchors that flip automatically for RTL; the file is pure layout/composition of `controls`, `titleLabel`, `accessoryViews`, and `gearView` with no business logic (separation-of-concerns: passed), and `PaneTitleBarViewTests.swift` exercises title truncation/round-trip, accessory replacement, and gear-slot swap (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Removed dangling depends-on entries (themed-background-view/separator-view/label) with no matching recipe. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; added leading-controls-cluster and bottom-separator requirements with matching configuration and test-vector coverage; corrected the middle-truncation rationale and the width-below-minimum edge case; reformatted Design Decisions; replaced the Compliance prose with a check table; fixed the SwiftUI, Compose, and WinUI 3 platform notes and folded the AppKit source notes into the AppKit / UIKit bullet; corrected the accessibility label description; populated depends-on; replaced the macos tag |
| 1.0.0 | 2026-09-22 | Claude | Initial creation from source code |
