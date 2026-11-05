---
id: 3ec6618a-03a4-4740-9655-e6e47c05cf2b
title: WindowFooterBar
domain: adhsdk://recipes/window-footer-bar
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Fixed-height footer bar for window bottom edge with status text and trailing
  accessory slot.
platforms:
- swift
- macos
tags:
- window-chrome
- status-display
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# WindowFooterBar

## Overview

A fixed-height status bar component positioned at the bottom edge of a document window. It displays a status string at the leading edge (truncated by middle if too long, with full text as tooltip) and provides a trailing slot for accessory views such as progress indicators or badges. The component uses theme-aware colors and a hairline separator at the top edge.

## Behavioral Requirements

- **top-hairline**: Component MUST render a hairline separator at its top edge using the border theme role.
- **status-text-leading**: Component MUST display the status string at the leading edge of the bar.
- **middle-truncation**: Component MUST truncate status text by the middle when it exceeds available width.
- **hover-tooltip**: Component MUST display the full status text as a tooltip on pointer-capable platforms when not empty; when status is empty, tooltip MUST be cleared. On touch-only platforms, the full text remains available via the accessible label instead (see **full-text-accessible-label**).
- **full-text-accessible-label**: Component MUST expose the complete, untruncated status string as the status label's accessibility value, independent of visual truncation.
- **fixed-height**: Component MUST maintain a fixed height of 22pt.
- **status-vertical-centering**: Component MUST center-align the status label vertically within the bar.
- **trailing-accessories**: Component MUST accept an ordered list of accessory views for the trailing slot and render them in that order.
- **trailing-vertical-centering**: Component MUST center-align trailing accessory views vertically within the bar.
- **trailing-spacing**: Component MUST apply 6pt spacing between trailing accessory views.
- **edge-margins**: Component MUST maintain 10pt leading and trailing margins from the bar edges.
- **minimum-gap**: Component MUST maintain at least 8pt minimum gap between status label and trailing accessories when both are present.
- **theme-support**: Component MUST apply theme-aware colors: elevated surface background, border-role hairline, and secondary text.
- **accessibility-prefix**: Component MUST require an accessibility prefix string during initialization.
- **status-accessibility-id**: Component MUST assign an accessibility identifier to the status label using the provided prefix (formatted as `{prefix}.status`).

## Appearance

- **Height**: 22pt (fixed)
- **Corner radius**: None (rectangular)
- **Padding**: Leading 10pt, trailing 10pt (from bar edges); 8pt minimum horizontal gap between status and accessories
- **Font**: Caption text size (inherited from ThemedLabel secondary text role)
- **Background**: Themed elevated surface
- **Foreground/Text**: Themed secondary text color
- **Border**: 1pt hairline at top edge, themed border role
- **Shadow**: None
- **Spacing**: 6pt between trailing accessory views; status label centered vertically, trailing accessories centered vertically

## States

| State | Appearance change |
|-------|------------------|
| Default | Status text visible; hairline and background applied; trailing accessories visible if present |
| Status truncated | Status text truncated by middle; full text available via tooltip on pointer platforms and via the accessible label (**full-text-accessible-label**) on all platforms |
| Empty status | Tooltip cleared; the 8pt minimum gap (**minimum-gap**) applies only when both status text and accessories are present, so trailing accessories may use the full available width |
| Empty accessories | Trailing slot hidden; status text uses available horizontal space |

## Accessibility

- **Role**: Container (NSView subclass; does not have an interactive role itself)
- **Status label**: Assigned accessibility ID using provided prefix (**status-accessibility-id**)
- **Label requirements**: The status label's accessibility value always carries the complete, untruncated status string (**full-text-accessible-label**), independent of the visually truncated, middle-ellipsized text; the tooltip (**hover-tooltip**) is a supplementary affordance for pointer platforms only.
- **State changes**: Status text updates are reflected in accessibility element content
- **Minimum tap target**: Not applicable; component is not interactive

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| window-footer-001 | fixed-height | Component instantiated with any status | Bar height equals 22pt |
| window-footer-002 | top-hairline | Component rendered | Hairline separator visible at top edge |
| window-footer-003 | status-text-leading | `status = "File.txt"` | Text "File.txt" visible at leading edge |
| window-footer-004 | middle-truncation | `status = "very/long/file/path/that/exceeds/available/width.txt"` | Text truncated in middle with ellipsis; full path accessible via tooltip |
| window-footer-005 | hover-tooltip | `status = "example text"` | Hovering over status displays full "example text" |
| window-footer-006 | hover-tooltip | `status = ""` | No tooltip displayed |
| window-footer-007 | status-vertical-centering | Component rendered | Status label vertically centered within 22pt height |
| window-footer-008 | trailing-accessories | `trailingAccessories = [view1, view2]` | Both views rendered horizontally in trailing slot |
| window-footer-009 | trailing-spacing | `trailingAccessories = [view1, view2]` | 6pt horizontal space between view1 and view2 |
| window-footer-010 | trailing-vertical-centering | `trailingAccessories = [view1, view2]` | Accessory views vertically centered within bar |
| window-footer-011 | trailing-accessories | `trailingAccessories = [view1]` then `trailingAccessories = []` | view1 is detached from the view hierarchy (removed as arranged subview and from its superview); trailing slot is empty |
| window-footer-012 | status-accessibility-id | `init(accessibilityPrefix: "project.footer")` | Status label accessibility ID is "project.footer.status" |
| window-footer-013 | full-text-accessible-label | `status` set to a long path that is visually truncated | Status label's accessibility value equals the full, untruncated string |
| window-footer-014 | edge-margins | Component rendered | Status label leading edge is 10pt from the bar's leading edge; trailing accessory stack's trailing edge is 10pt from the bar's trailing edge |
| window-footer-015 | minimum-gap | `status` long enough to approach the trailing edge, `trailingAccessories = [view1]` | Gap between status label's trailing edge and trailing stack's leading edge is at least 8pt |
| window-footer-016 | theme-support | Component rendered under light and dark appearance | Background uses the elevated-surface role, hairline uses the border role, and status text uses the secondary-text role in both appearances |
| window-footer-017 | accessibility-prefix | `init(accessibilityPrefix: "project.footer")` | Component initializes; child identifiers are derived from `"project.footer"` (see **status-accessibility-id**) |

## Edge Cases

- **Empty status string**: Status label renders as empty; tooltip is nil (see **hover-tooltip**); trailing accessories have the full trailing slot width available since the minimum gap (**minimum-gap**) applies only when both status text and accessories are present.
- **Very long status string**: Text is truncated by middle (**middle-truncation**); the full string remains available via tooltip on pointer platforms and via the accessible label (**full-text-accessible-label**) on all platforms; no horizontal scroll occurs.
- **Empty trailing accessories array**: Trailing slot is empty; no layout errors occur; status label can expand to available width.
- **Rapid status updates**: Status text and tooltip update without layout thrashing; component remains at fixed 22pt height.
- **Trailing accessories with varying heights**: All accessories center-aligned vertically to bar center (**trailing-vertical-centering**); no clipping or overflow.
- **Accessory replacement**: Existing accessories removed from the view hierarchy and replaced with the new array; no memory leaks or dangling views.
- **Long accessory list**: Accessories squeeze toward the trailing edge; 6pt spacing (**trailing-spacing**) maintained; minimum gap (**minimum-gap**, 8pt) from status preserved until width is exhausted.
- **Large system text size**: Bar height remains fixed at 22pt (`WindowFooterBar.height` is a constant, not derived from font metrics); at very large caption text sizes (Dynamic Type or a platform text scale) the status label's text may be vertically clipped rather than the bar growing to fit it.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `accessibilityPrefix` | String | (required) | Namespace for accessibility identifiers; used to derive status label ID |

## Deep Linking

Not applicable: WindowFooterBar is a non-interactive display component with no user navigation targets.

## Localization

Not applicable: Component displays application-provided status strings; no hardcoded user-facing text.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Animation not applicable; component is static display |
| Increase Contrast | Component respects theme-aware colors; no additional configuration needed |
| Differentiate Without Color | Status text is the primary affordance; no color-only status indicators |

## Feature Flags

Not applicable: No feature flags referenced in component implementation.

## Analytics

Not applicable: Component is passive display element with no user interactions.

## Privacy

Not applicable: Component displays caller-provided status strings; no data is collected, stored, or transmitted.

## Logging

Not applicable: No logging instrumentation defined in component source.

## Platform Notes

- **AppKit** (source): `WindowFooterBar` in `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/WindowFooterBar.swift`. Composed of `NSStackView` for trailing accessories and `NSView` constraints for layout. Uses `ThemedLabel`, `ThemedBackgroundView`, and `ThemedSeparatorView` for theme integration. `NSTextField`'s accessibility value is backed by `stringValue`, so the full status string remains the accessible value regardless of the label's visual middle-truncation (**full-text-accessible-label**). Accessibility requires a string prefix at init time.
- **SwiftUI**: `VStack(spacing: 0) { Divider(); HStack { Text(status).lineLimit(1).truncationMode(.middle); Spacer(minLength: 8); HStack(spacing: 6) { accessories } } }`. Apply `.help(status)` for the pointer-platform tooltip and `.accessibilityLabel(status)` so the full string remains the accessible value on all platforms (**full-text-accessible-label**). Map colors to the toolkit's theme roles (elevated surface, border, secondary text) rather than raw `@Environment(\.colorScheme)`. Set the identifier via `.accessibilityIdentifier()`.
- **Compose**: `Row` with a top `Divider`. Leading: `Text(status, maxLines = 1, overflow = TextOverflow.MiddleEllipsis, modifier = Modifier.weight(1f))` — `Arrangement.SpaceBetween` does not guarantee the 8dp minimum gap, so pair the weighted leading `Text` with an explicit `Spacer(Modifier.width(8.dp))` before the trailing `Row`. Trailing: `Row` with 6dp spacing for accessories. Apply Material 3 surface colors mapped to the toolkit's theme roles. Compose has no hover tooltip, so set `Modifier.semantics { contentDescription = status }` on the leading `Text` as the full-text fallback (**full-text-accessible-label**); accessibility ID via `testTag()`.
- **UIKit**: `UIView` subclass using a horizontal `UIStackView`. Leading: `UILabel` with `lineBreakMode = .byTruncatingMiddle`. Add a hairline `UIView` separator at the top via `CALayer`. Trailing: horizontal `UIStackView` with 6pt spacing. Apply `UIColor` semantic colors mapped to the toolkit's elevated-surface and border roles. iOS has no hover tooltip, so explicitly set `accessibilityLabel = status` (the full string) on the leading label rather than relying on the truncated `text` (**full-text-accessible-label**); set `accessibilityIdentifier` on the label.
- **WinUI 3**: `UserControl` containing a `Grid`. Top row: a `Border` with a 1px stroke for the hairline. Content row: horizontal `StackPanel`. WinUI's `TextTrimming="CharacterEllipsis"` only trims from the end, so it cannot express middle truncation (**middle-truncation**); compute the middle-truncated display string with a value converter or a custom measure pass and bind it to the `TextBlock`, while keeping the full string in `AutomationProperties.Name` (**full-text-accessible-label**) and its `ToolTipService.SetToolTip` (**hover-tooltip**). Trailing cell: horizontal `StackPanel` with 6pt spacing for buttons or other controls. Use Fluent 2 SurfaceAlt and Divider tokens.

## Design Decisions

- **Decision**: Fixed height of 22pt.
  **Rationale**: Sized to match the visual weight of this toolkit's own macOS tab bar height so a window using both elements does not read as bottom-heavy; this is an internal consistency choice for the toolkit's chrome components, not a cited platform guideline.
  **Approved**: pending

- **Decision**: Truncate the status string by the middle rather than the end.
  **Rationale**: Status strings are typically paths or identifiers where the end (filename or key identifier) is more important than the beginning (directory structure); middle truncation preserves both ends, maximizing recognizability when the text is clipped.
  **Approved**: pending

- **Decision**: Require an accessibility prefix string at initialization rather than defaulting one.
  **Rationale**: The bar is meant to sit under more than one kind of window; requiring a prefix keeps accessibility identifiers unique per window type and avoids a UI test addressing "the footer" ambiguously matching whichever instance came first.
  **Approved**: pending

- **Decision**: 10pt leading/trailing margins with an 8pt minimum inter-element gap.
  **Rationale**: An internal consistency choice for this toolkit's chrome components rather than a cited platform guideline; the 8pt gap keeps breathing room between the status text and accessories without wasting space.
  **Approved**: pending

- **Decision**: Expose trailing accessories as a settable array property rather than a slot builder/closure.
  **Rationale**: A fixed array is simpler for callers to manage than a closure; removal and replacement are explicit and obvious, reducing layout surprises.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | failed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on the source: `dynamic-type-support` fails because `WindowFooterBar.height` is a hardcoded 22pt constant with no logic that grows the bar or the label for larger text (see the **Large system text size** edge case); `contrast-ratio` is partial because the source applies theme-role colors (elevated surface, border, secondary text) but the actual color values behind those roles are defined outside this file, so the resulting contrast cannot be confirmed here. `separation-of-concerns` passes because the bar takes only a status string and knows nothing of what a pane or a path is — the window formats that and hands over the result; `unit-test-coverage` passes on `WindowFooterBarTests.swift`'s exercise of the status round-trip, its tooltip, its identifier, and the trailing accessory slot.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; added full-text-accessible-label requirement, accessibility text, and test vector so screen-reader/keyboard/touch users get the untruncated string without relying on hover; reworded platform-tied requirement text to be platform-neutral; added a Dynamic Type edge case; fixed test vector 011 and added vectors for edge-margins, minimum-gap, theme-support, and accessibility-prefix; corrected the WinUI and Compose platform notes' truncation/spacing claims and tightened the SwiftUI note; reformatted Design Decisions into the Decision/Rationale/Approved form and removed unsourced platform-convention citations; filled in the Compliance table |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from WindowFooterBar.swift source |
