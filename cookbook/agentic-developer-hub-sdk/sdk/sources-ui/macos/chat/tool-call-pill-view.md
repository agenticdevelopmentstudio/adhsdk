---
id: e5165b31-6a06-4d79-8fb8-98ba491623b1
title: "Tool Call Pill View"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Displays a tool invocation as a bordered pill with status-based coloring and error messaging."
platforms:
  - swift
  - macos
tags:
  - chat
  - status
  - pill
  - theming
depends-on: []
related:
  - 46e0a509-8eac-460a-b24a-d39a8b71b02c
references: []
approved-by: ""
approved-date: ""
---

# Tool Call Pill View

## Overview

The Tool Call Pill View displays a single `CommandActivity` as a bordered, status-colored pill in a chat transcript. It shows the command name and, when the command has failed, appends the error message. The pill is color-coded by execution state: neutral blue (info) while running, green (success) on successful completion, and red (danger) on failure. The component observes theme palette changes and recolors its border and text live without requiring a rebuild.

## Behavioral Requirements

- **render-activity-name**: The component MUST display the command's name from `activity.invocation.commandName` as the pill's text content.
- **display-error-on-failure**: When `activity.result` exists and `result.ok` is `false`, the component MUST append the error message in the format `"<name> — <message>"` where `<name>` is the command name and `<message>` is `result.errorMessage`, or display only the name if `errorMessage` is `nil` or empty.
- **truncate-overflow-text**: Text longer than the available width MUST be truncated at the tail with an ellipsis (`…`).
- **apply-status-color**: The component MUST color its label text and border according to the activity state: `.info` (neutral blue) while `activity.result` is `nil`, `.success` (green) when `result.ok` is `true`, and `.danger` (red) when `result.ok` is `false`.
- **observe-theme-changes**: The component MUST observe theme palette changes on initialization and recolor itself live, without requiring a view hierarchy rebuild. See **Platform Notes** for the observer used on Apple platforms.
- **use-caption-font**: The component MUST render text using the semantic palette's `caption` text style.
- **render-border**: The component MUST display a 1-point border around the pill.
- **apply-corner-radius**: The component MUST have a corner radius of 9 points.
- **apply-padding**: The component MUST apply 4 points of vertical padding and 10 points of horizontal padding between the text and the pill's edges.
- **use-elevated-surface**: The component MUST use the semantic palette's `elevated-surface` background role.

## Appearance

- **Corner radius**: 9 points
- **Padding**: 4pt vertical × 10pt horizontal
- **Font**: Caption weight and size from semantic palette
- **Background**: Elevated surface color from semantic palette
- **Foreground/Text**: Status-dependent color (info / success / danger)
- **Border**: 1 point, status-dependent color (info / success / danger)
- **Shadow**: None
- **Min/Max size**: No explicit constraints; size determined by text width and padding

## States

| State | Appearance change |
|-------|------------------|
| Running (result == nil) | Text and border colored `.info` |
| Success (result.ok == true) | Text and border colored `.success` |
| Failed (result.ok == false) | Text and border colored `.danger`; error message appended to name |
| Theme changed | All colors updated to match the new palette; the same view instance recolors in place (no rebuild) |

## Accessibility

- **Role**: The pill container is a plain `NSView` that sets no accessibility role, label, or value and is not itself an accessibility element; the only element VoiceOver reaches is the inner `NSTextField(labelWithString:)`, which exposes the static-text role.
- **Label and value**: The source makes no `setAccessibility*` calls. VoiceOver reads the label's `stringValue` — the same text `title(for:)` paints: the command name alone while running or on success, and `"<name> — <message>"` on a failure that carries a non-empty `errorMessage`.
- **Status reading**: Status is not announced. Running and success read identically (just the command name), and a failure with a `nil` or empty `errorMessage` also reads as just the name, so VoiceOver users cannot tell those states apart; only a failure with a message is audibly distinct, via its appended text. No accessibility notification is posted when the status changes.
- **Truncated text**: VoiceOver reads the full `stringValue`, including any portion hidden by the tail ellipsis from `truncate-overflow-text`.
- **Keyboard focus**: The pill is not focusable. The label is a non-editable, non-selectable static text field, and the view does not override `acceptsFirstResponder`, so it never enters the key-view loop and has no keyboard interaction.
- **Hit target**: The pill is display-only with no click, gesture, or action handling, so no interactive hit-target minimum applies. The source sets no minimum size; its height is the caption font's line height plus 8 points of vertical padding.
- **Color dependence**: Status is conveyed visually only by the text and border color (`.info` / `.success` / `.danger`); see **Differentiate Without Color** under Accessibility Options.
- **contrast-verification**: NEEDS REVIEW: Not implemented in source. Text and border colors come from `SemanticPalette` roles drawn on the `elevated-surface` background, and the ratio depends on the active theme, so contrast cannot be decided from this file.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pill-001 | render-activity-name | CommandActivity with `invocation.commandName = "fetch_data"`, `result = nil` | Text reads "fetch_data" |
| pill-002 | apply-status-color, render-border | CommandActivity with `result = nil` | Label text and border colored `.info` |
| pill-003 | apply-status-color, render-border | CommandActivity with `result.ok = true` | Label text and border colored `.success` |
| pill-004 | apply-status-color, render-border | CommandActivity with `result.ok = false` | Label text and border colored `.danger` |
| pill-005 | display-error-on-failure | CommandActivity with `result.ok = false`, `result.errorMessage = "Connection timeout"` | Text reads "fetch_data — Connection timeout" |
| pill-006 | display-error-on-failure | CommandActivity with `result.ok = false`, `result.errorMessage = ""` or `nil` | Text reads "fetch_data" (name only) |
| pill-007 | truncate-overflow-text | CommandActivity with command name exceeding available width | Text ends with ellipsis; does not overflow pill boundary |
| pill-008 | observe-theme-changes | Pill on screen; theme palette changes | The same pill view instance updates its border and text colors in place; no new instance is created |
| pill-009 | use-caption-font | Pill rendered | Rendered font matches the semantic palette's `caption` text style (`palette.font(.caption)` in the reference implementation) |
| pill-010 | apply-padding, apply-corner-radius | Pill rendered | Vertical padding 4pt, horizontal 10pt, corner radius 9pt |
| pill-011 | use-elevated-surface | Pill rendered | Background color matches the semantic palette's `elevated-surface` role (`palette.nsColor(.elevatedSurface)` in the reference implementation) |
| pill-012 | render-border | Pill rendered | 1-point border present and colored per status |

## Edge Cases

- **Empty command name**: If `invocation.commandName` is an empty string, `title(for:)` returns the empty string unless the result failed with a non-empty message, in which case the text becomes `" — <message>"` (a leading separator with no name before it). The pill still renders its status color, border, and padding; only the text content is empty or leads with the separator.
- **Nil error message with failed result**: If `result.ok` is `false` but `result.errorMessage` is `nil`, the component displays only the command name (no error message appended). This is a MUST per requirement display-error-on-failure.
- **Very long error message**: If the error message is very long, the combined "name — message" text is truncated at the tail with an ellipsis. The full text is not available via tooltip or other means (see **Design Decisions**: No Tooltip for Truncated Text).
- **Theme palette deallocated**: The observer closure captures `self` weakly (`[weak self] palette in self?.applyTheme(palette)` in the reference implementation), so if the pill is deallocated while the observer is still registered, the closure becomes a no-op via optional chaining rather than crashing or retaining the view.
- **Multiple theme changes in rapid succession**: Each theme change triggers a full recolor via `applyTheme(_:)`. No debouncing or batching is implemented; rapid theme changes apply each update immediately.

## Configuration

Not applicable: The component accepts a `CommandActivity` at initialization and has no configuration options. All appearance parameters (padding, corner radius, font size) are hardcoded constants.

## Deep Linking

Not applicable: This component is a passive display element embedded in a chat message transcript and does not handle deep links.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded) | `"<name> — <message>"` | Separator between command name and error message, built in `title(for:)`. It is not externalized and always renders in left-to-right order regardless of locale (see **Compliance**: `no-hardcoded-strings`, `rtl-layout-support`). |

## Accessibility Options

- **Reduce Motion**: Not applicable. The component has no animations.
- **Increase Contrast**: Not applicable. The component uses semantic palette colors determined by the theme; contrast compliance is the palette's responsibility.
- **Differentiate Without Color**: The component communicates status only through color (info / success / danger); no alternate visual indicator (icon, pattern, or label) is provided. See **apply-status-color**.

## Feature Flags

Not applicable: The component has no feature flags. It is always active when instantiated.

## Analytics

Not applicable: The component does not emit analytics events. Event tracking, if desired, is the responsibility of the parent message bubble or transcript view.

## Privacy

Not applicable: The component displays command names and error messages supplied by the caller. It does not collect, store, or transmit data beyond what is rendered on screen.

## Logging

Not applicable: The component does not emit log messages.

## Platform Notes

- **Source (Apple/Swift)**: Implemented as an `NSView` subclass in `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chat/ToolCallPillView.swift` (path relative to the repo root). Uses `NSTextField` for text rendering and `CALayer` for border, corner radius, and background. Text uses the semantic palette's `caption` style (`palette.font(.caption)`); background uses its `elevatedSurface` role (`palette.nsColor(.elevatedSurface)`). Integrates with the semantic palette via the `ThemePaletteObserver` pattern (see **observe-theme-changes**).
- **SwiftUI**: A SwiftUI wrapper would apply `RoundedRectangle(cornerRadius: 9)` as the pill's background/border shape with a `Text` overlay, applying the same padding and semantic colors — not `Capsule`, which would not match the fixed 9pt corner radius. Live theme observation would read the palette via `@Environment` from an `@Observable` palette type, rather than the older `@EnvironmentObject`.
- **Compose**: An Android Compose equivalent would use `Box` or `Surface` with a `border` modifier, applying the same padding and corner radius. Status color would be driven by a Compose state or `remember` block observing the palette. Material 3 would use `Surface` with `contentColor` for theming.
- **AppKit / UIKit**: On AppKit (macOS), see **Source (Apple/Swift)** above. On UIKit (iOS), replace `NSView` with `UIView`, `NSTextField` with `UILabel`, and `CALayer` properties with frame-based layout or Auto Layout. The `ThemePaletteObserver` pattern adapts to UIKit lifecycle (e.g. observer registration in `viewWillAppear`). The toolkit's semantic palette is injected the same way on UIKit as it is on AppKit; UIKit itself has no semantic palette concept, but this toolkit's palette does not depend on one.
- **WinUI 3**: Implement as a `UserControl` with a `Border` as the root element, containing a `TextBlock` for the text. Apply `CornerRadius` property for 9-point radius, `BorderThickness` for 1-point border, and `Padding` for 4pt/10pt vertical/horizontal. Use WinUI's `SolidColorBrush` bindings to apply status-dependent colors from a semantic color dictionary. Subscribe to a theme-changed event or binding to update colors live.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chat/ToolCallPillView.swift` | unverified |

## Design Decisions

**Decision**: The component uses `.info` (neutral blue) for the running state rather than `.warning` (yellow/orange).
**Rationale**: This prioritizes reduced alert fatigue: a running command is neither good news nor bad, and using a warning color would create false urgency on every tool call. This differs from error indicators (red / `.danger`) and success indicators (green / `.success`), which are meaningful outcomes.
**Approved**: pending

**Decision**: When a command fails, the error message is appended to the name using a space–em dash–space separator (`" — "`), producing `"<name> — <message>"`.
**Rationale**: This is consistent with the error handling approach taken in `MessageBubbleView` for failed message deliveries: a colored pill with no words requires the user to decode the color; the message makes the failure legible.
**Approved**: pending

**Decision**: Truncated text does not display a tooltip showing the full text.
**Rationale**: This is consistent with the source code, which has no tooltip implementation. A tooltip would improve UX for long error messages but is out of scope for this component.
**Approved**: pending

**Decision**: The component holds its own `ThemePaletteObserver` and recolors in place on palette changes, rather than relying on a full view-tree rebuild.
**Rationale**: This is a performance optimization for live theme switching in a transcript view: pills already rendered remain on screen and update their colors directly, reducing layout churn.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source's delegation of caption font sizing, status colors, and contrast to `SemanticPalette` (unverifiable from this file, hence partial); the hardcoded `" — "` concatenation in `title(for:)` (ToolCallPillView.swift), which is neither externalized nor RTL-aware; the fixed tail-truncation in `truncate-overflow-text`, which always truncates rather than accommodating expanded text; and full-Unicode text rendering inherited from `NSTextField`; the status-to-role and title-formatting logic lives in private static/computed members (`statusRole`, `title(for:)`) kept apart from the view's paint/layout code, with no data access or business rules tangled into rendering (separation-of-concerns passed), and `ToolCallPillViewTests.swift` directly asserts `titleText`, `titleColor`, and the border color across running/success/failure states plus a live theme change (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.1 | 2026-09-24 | Claude | Added the missing Accessibility section describing role, label/value, VoiceOver status reading, keyboard focus, hit target, and color dependence from source, with one contrast NEEDS REVIEW marker. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; restated AppKit-specific requirements as semantic palette roles and moved API names into Platform Notes; fixed SwiftUI (RoundedRectangle, @Environment) and AppKit/UIKit (palette injection) platform notes; reformatted Design Decisions to Decision/Rationale/Approved; populated Compliance with applicable accessibility and internationalization checks; replaced the Localization "Not applicable" with the hardcoded separator string; made the theme-change test vector and state row observable; clarified the empty-command-name and theme-deallocation edge cases; standardized on `nil` and "space–em dash–space"; added tags and a related cross-reference to Message Bubble. |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from ToolCallPillView.swift source |
