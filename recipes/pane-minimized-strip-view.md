---
id: 5ec45ac4-a02f-4ee7-becb-7894c2893f23
title: Pane Minimized Strip View
domain: adhsdk://recipes/pane-minimized-strip-view
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A vertical rail representing a minimized pane, showing its glyph and restore
  button.
platforms:
- swift
- macos
tags:
- pane
- layout
- chrome
- minimized
depends-on: []
related:
- adhsdk://recipes/separator
- adhsdk://recipes/pane-title-bar-view
references: []
approved-by: ''
approved-date: ''
---

# Pane Minimized Strip View

## Overview

A vertical rail component that represents a minimized multi-pane layout element. When a pane is minimized to the side edge of a window, it appears as a thin vertical strip showing a symbol representing the pane's content and a restore button to expand it. Used in multi-pane layouts where content can be hidden to maximize workspace while remaining accessible.

## Behavioral Requirements

- **fixed-width**: Component MUST render at exactly 28 points wide.
- **restore-button**: Component MUST display a restore button with a plus symbol (`+`) at the top.
- **glyph-display**: Component MUST display a glyph or symbol representing the minimized pane's content.
- **restore-callback**: Component MUST invoke the `onRestore` callback when the restore button is tapped.
- **symbol-name**: Component MUST accept a `symbolName` property to specify which SF Symbol to display as the glyph.
- **glyph-tracks-symbol**: Component MUST update the displayed glyph immediately when `symbolName` property changes.
- **tooltip**: Component MUST accept a `tooltip` property that appears on hover over the glyph.
- **tooltip-tracks-property**: Component MUST update the tooltip text immediately when the `tooltip` property changes.
- **hairline-inward**: Component MUST place a vertical separator hairline on the interior side (inward) based on the edge the pane docks to—trailing side if pane docks to leading edge, or leading side if pane docks to trailing edge.
- **glyph-fallback**: Component MUST display a dashed square (`square.dashed`) when the provided `symbolName` is invalid or unavailable.
- **theme-colors**: Component MUST observe theme changes and update button and glyph colors to secondary text color from the current theme palette.
- **accessibility-labels**: Component MUST set accessibility label "Restore Pane" on the restore button and provide accessibility description based on tooltip or "Minimized Pane" for the glyph.

## Appearance

- **Width**: 28 points (fixed)
- **Background**: Elevated surface background (theme-aware)
- **Icon size**: 16 × 16 points
- **Icon color**: Secondary text color (theme-aware)
- **Button color**: Secondary text color (theme-aware)
- **Separator**: Vertical hairline, 1 point wide (`ThemedSeparatorView(role: .border, axis: .vertical)`), full height of the strip, positioned on the inward side
- **Below the glyph**: No further content; the elevated-surface background fills the remaining height down to the bottom of the strip, with the hairline continuing the full height alongside it
- **Spacing**: 
  - Restore button: 4 points from top, centered horizontally
  - Glyph: 6 points below restore button, centered horizontally
- **Corner radius**: None (rectangular)
- **Shadow**: None

## States

| State | Appearance change |
|-------|------------------|
| Default | Icon and restore button rendered in secondary text color, hairline visible |
| Restore button pressed | Button responds to platform's press state (handled by NSButton bezel style) |
| Restore button focused | Focus ring visible (handled by NSButton) |
| Theme changed | Icon and button colors update to match new theme palette |

## Accessibility

- **Role**: Container holding button and icon
- **Restore button role**: Button (role automatically provided by NSButton)
- **Restore button label**: "Restore Pane" (set via accessibility label and accessibility description)
- **Glyph accessibility description**: Tooltip text if provided; when `tooltip` is empty (the default), falls back to "Minimized Pane"
- **Accessibility IDs**: `pane.restore` for restore button, `pane.minimized.glyph` for glyph view
- **Click target size**: The strip is 28 points wide, so a 44×44 target — the iOS touch-target minimum — cannot fit in either dimension. The restore button sizes to its own intrinsic content size (`.accessoryBarAction` bezel, image-only, no minimum-size constraint in source); this is a mouse-driven macOS chrome control, not an iOS touch target. See **touch-target-size** in Compliance for a `partial` accounting of the shortfall.
- **Keyboard navigation**: Restore button is keyboard-accessible via Tab (provided by NSButton)

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pane-strip-001 | fixed-width | View initialized with edge `.leading` | View width is 28 points |
| pane-strip-002 | restore-button | Default initialization | Restore button visible at top, displays plus symbol |
| pane-strip-003 | glyph-display | Default initialization with no symbolName override | Glyph displays `square.dashed` symbol |
| pane-strip-004 | symbol-name | Initialize with `symbolName: "folder"` | Glyph displays folder symbol |
| pane-strip-005 | glyph-tracks-symbol | After init, set `symbolName = "star"` | Glyph updates to star symbol immediately |
| pane-strip-006 | restore-callback | Set `onRestore` callback, tap restore button | Callback is invoked |
| pane-strip-007 | tooltip | Initialize with `tooltip: "Documents"` | Tooltip text "Documents" appears on glyph hover |
| pane-strip-008 | tooltip-tracks-property | After init, set `tooltip = "Settings"` | Tooltip updates to "Settings" immediately |
| pane-strip-009 | hairline-inward | Initialize with edge `.leading` | Hairline positioned at trailing side (interior) |
| pane-strip-010 | hairline-inward | Initialize with edge `.trailing` | Hairline positioned at leading side (interior) |
| pane-strip-011 | glyph-fallback | Initialize with `symbolName: "nonexistent.symbol"` | Glyph displays `square.dashed` fallback |
| pane-strip-012 | accessibility-labels | Default initialization | Restore button has accessibility label "Restore Pane", accessibility ID `pane.restore` |
| pane-strip-013 | accessibility-labels | Initialize with `tooltip: "Mail"` | Glyph accessibility description is "Mail" |
| pane-strip-014 | theme-colors | Apply theme with secondary text color #666666 | Icon and button render in #666666 |
| pane-strip-015 | accessibility-labels | Initialize with `tooltip: ""` (default) | Glyph accessibility description is "Minimized Pane" |
| pane-strip-016 | restore-callback | `onRestore` left `nil` (default), tap restore button | No crash; tap has no observable effect (safe no-op) |
| pane-strip-017 | theme-colors | Apply theme with border color #444444 | Hairline renders in #444444 |
| pane-strip-018 | hairline-inward | Attempt to change `edge` after initialization | No API exists to mutate `edge`; hairline position stays fixed to the value passed at init |

## Edge Cases

- **Empty tooltip**: If `tooltip` is empty string, glyph's tooltip is `nil` (no tooltip appears on hover).
- **Very long tooltip**: Tooltip text is set directly on glyph; platform handles wrapping and display.
- **Rapid symbol changes**: Multiple rapid updates to `symbolName` will update the glyph each time; no debouncing is performed.
- **onRestore callback not set**: If `onRestore` is `nil`, tapping restore button has no observable effect (safe no-op).
- **Invalid symbol name**: If provided symbol name cannot be loaded, fallback to `square.dashed` automatically.
- **Theme not observed**: This cannot occur. `observeTheme` applies the current palette synchronously inside its own initializer and then re-applies on every posted theme-change notification, so registration cannot silently fail. If no theme manager is registered, the palette falls back to the built-in default rather than leaving colors unset.
- **View initialization**: Component cannot be initialized from a coder (`.xib`, `.storyboard`); `init(coder:)` is unavailable.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `edge` | `PaneEdge` enum | required | Which side the pane docks to (`.leading` or `.trailing`); determines hairline placement. Set once at initialization — there is no stored property or setter to change it afterward. |
| `symbolName` | `String` | `"square.dashed"` | SF Symbol name to display as the glyph |
| `tooltip` | `String` | `""` (empty) | Tooltip text for the glyph; no tooltip if empty |
| `onRestore` | `() -> Void` closure | `nil` | Callback invoked when restore button is tapped |

## Deep Linking

Not applicable: This component is a chrome/layout element without user-navigable content; it has no corresponding deep link URL.

## Localization

These accessibility strings are heard by VoiceOver users even though the strip itself is a chrome element, so they are localizable text, not exempt UI chrome:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `pane.minimized.restoreLabel` | Restore Pane | Restore button's accessibility label and hover tooltip |
| `pane.minimized.glyphFallbackLabel` | Minimized Pane | Glyph's accessibility description when `tooltip` is empty |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; the component performs no animation. |
| Increase Contrast | Not observed directly; colors come from whatever the active theme palette resolves for the secondary-text role (glyph, button) and the border role (hairline) via `observeTheme`. The palette has no distinct high-contrast variant in this codebase, so this setting has no effect on the strip. |
| Differentiate Without Color | Not applicable; the glyph and restore button are distinguished by symbol and position, not by color alone. |

## Feature Flags

Not applicable: This component has no feature flag controls; it is always enabled.

## Analytics

Not applicable: This component does not emit analytics events; analytics for pane restore actions belong to the pane manager, not the view itself.

## Privacy

Not applicable: This component does not collect or transmit any user data.

## Logging

Not applicable: This component does not emit diagnostic logs; logging of pane state changes belongs to the client that manages the pane lifecycle.

## Platform Notes

- **Source**: `PaneMinimizedStripView.swift` in `AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/`. Uses `NSView`, `NSButton`, `NSImageView`, theme-aware `ThemedBackgroundView` and `ThemedSeparatorView` helpers. Fixed layout via Auto Layout constraints. `@MainActor` actor-isolated for UI thread safety.
- **SwiftUI**: Wrap the AppKit view using `NSViewRepresentable`, or build natively using `VStack` with `Button` (label: Image), a `Divider` for the hairline, and state to bind `symbolName` and `tooltip`. Apply secondary text color via `.foregroundStyle()`.
- **Compose**: Implement using `Column` with an icon `Button` (icon: `Icons.Default.Add`) at top, `Spacer(Modifier.height(6.dp))`, and the glyph icon below. Use `Modifier.fillMaxHeight()` on the column, `Modifier.width(28.dp)` for the fixed width, and `Divider(color = ..., thickness = 1.dp, modifier = Modifier.fillMaxHeight())` positioned on the leading or trailing edge of the column based on the `edge` parameter.
- **AppKit / UIKit**: On UIKit/iOS, adapt using `UIView` with `UIButton` (system style, image: UIImage(systemName: "plus")), `UIImageView` for glyph, and `UIView` separator. Use Auto Layout constraints matching desktop spacing. Ensure button and glyph areas meet 44×44 minimum tap target on iOS.
- **WinUI 3**: Implement using a two-column `Grid` (Width=28) so the hairline can sit in its own column on the side facing inward, rather than a `StackPanel`, which cannot host a side-anchored divider. In the content column: a `Button` (icon: `SymbolIcon(Symbol.Add)`) at top with `Margin="0,4,0,0"` for the 4pt top offset, then a spacer `Grid` row (Height=6), then an `Image` for the glyph (Width=16, Height=16). In the hairline column: a `Rectangle` (Width=1) with `VerticalAlignment="Stretch"`, filled with the theme's divider brush. Fill the background with the theme's elevated-surface brush — not `Acrylic`, which is a blur material, not a semantic surface role; map directly to whichever brush resource represents `elevatedSurface`. Set `ToolTipService.ToolTip` for the glyph tooltip.

## Design Decisions

**Decision**: The strip renders at a fixed width of `PaneMinimizedStripView.thickness` (28 points).
**Rationale**: The width accommodates a 16×16 glyph with 6 points of padding on each side (28 − 16 = 12, split evenly) and keeps a row of minimized panes aligned. This size reads as "a pane is present" without taking excessive screen space.
**Approved**: pending

**Decision**: The vertical hairline is placed on the inward side (interior) of the strip, determined by the `edge` parameter at initialization.
**Rationale**: This avoids doubling a line at the window edge. The `edge` parameter drives this decision at initialization time and cannot be changed post-construction (see **hairline-inward**).
**Approved**: pending

**Decision**: When no valid `symbolName` is available, the glyph falls back to `square.dashed`.
**Rationale**: Provides a safe default when a pane does not implement `PaneMinimizedRepresenting` or supplies an invalid symbol. A completely empty strip would be unidentifiable to users.
**Approved**: pending

**Decision**: Changes to `symbolName` and `tooltip` apply immediately, with no debouncing.
**Rationale**: The source applies changes immediately in `didSet` observers. Rapid changes are rare in practice; if debouncing is needed, the client should throttle updates before setting properties.
**Approved**: pending

**Decision**: The restore button uses `NSButton`'s `.accessoryBarAction` bezel style, borderless, image-only.
**Rationale**: A platform convention for small chrome buttons in narrow spaces; provides appropriate sizing and appearance for the restore action.
**Approved**: pending

**Decision**: Colors update through `observeTheme` closures rather than an external notification the client has to wire up.
**Rationale**: `observeTheme` applies the palette synchronously at registration and again on every theme-change notification, so the component stays visually consistent without requiring external updates (see **theme-colors**).
**Approved**: pending

**Decision**: `init(coder:)` is unavailable; the view is only constructed programmatically via `init(edge:symbolName:tooltip:)`.
**Rationale**: The component is designed for programmatic use in layout code, not for instantiation from `.xib` or `.storyboard` files; this keeps the interface focused and enforces the layout-by-code pattern.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

screen-reader-support and keyboard-navigable pass because `NSButton` carries an accessibility label and ID and is Tab-navigable by default; touch-target-size and contrast-ratio are partial because the 28pt-wide strip cannot fit a 44×44 target in either dimension and colors resolve from whatever the active theme palette supplies with no documented contrast guarantee; no-hardcoded-strings fails because `"Restore Pane"` and `"Minimized Pane"` are literal Swift string constants with no localization API in the source; the view is pure presentation of a glyph/restore button over `symbolName`/`tooltip` props, reporting via `onRestore` with no business logic (separation-of-concerns: passed), and `PaneMinimizedStripViewTests.swift` exercises fallback glyph, glyph/tooltip mutation, restore-click reporting, and fixed thickness (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; fixed the 28pt-width padding arithmetic and reformatted Design Decisions into the three-line form; corrected the click-target and Increase Contrast accessibility guidance for a 28pt macOS chrome control instead of the iOS 44×44 minimum; made "Theme not observed" explicit about `observeTheme`'s synchronous apply-then-notify behavior instead of guessing at a failure mode; converted Localization to a keyed table for the VoiceOver-only strings and converted Accessibility Options to the template's table form; replaced the Compliance section with a real linked check table, lowercase statuses, and an added Internationalization check; fixed the Compose and WinUI 3 platform notes and specified hairline thickness and below-glyph fill in Appearance; added test vectors for a nil `onRestore`, an empty tooltip, hairline theme reactivity, and `edge` immutability, and marked `edge` immutable in Configuration; linked `separator` and `pane-title-bar-view` in `related`. |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from PaneMinimizedStripView.swift |
