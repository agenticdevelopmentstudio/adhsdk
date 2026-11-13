---
id: 56388aa3-bc75-4d0a-830b-222f39750a9d
title: "Options Dialog View Controller"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A container-agnostic macOS dialog that presents customizable rows with no commit or cancel step; each row applies its own changes as it is made."
platforms:
  - swift
  - macos
tags:
  - ui
  - dialog
  - macos
depends-on: []
related: []
references:
  - https://developer.apple.com/design/human-interface-guidelines/buttons
  - https://developer.apple.com/design/human-interface-guidelines/sheets
  - https://developer.apple.com/design/human-interface-guidelines/modality
approved-by: ""
approved-date: ""
---

# Options Dialog View Controller

## Overview

`OptionsDialogViewController` is a macOS NSViewController that presents a modal or sheet dialog containing an optional heading, a stack of customizable rows (any NSView subclasses), and a Done button. There is no commit or cancel step in the dialog itself: each row applies its own change as it is made, and Done is the way out, not an acceptance. This component is designed to be container-agnostic; the same view controller body is used whether the dialog is presented as a sheet, a modal window, or through other presentation mechanisms. The caller controls presentation and dismissal through callbacks.

## Behavioral Requirements

- **render-content-in-vertical-stack**: The component MUST render the heading (if provided), all rows, and the Done button in a vertical stack with consistent spacing and alignment.
- **accept-custom-rows**: The component MUST accept an array of NSView subclasses as row content and render them without modification or filtering.
- **support-dynamic-heading**: The component MUST allow the heading text to be changed after initialization via the `heading` property, with the UI updating immediately to reflect the change or hide the heading if set to `nil`.
- **no-change-buffering**: The component MUST NOT provide a commit or cancel step, and MUST NOT buffer row changes itself; rows are responsible for applying and persisting or propagating their own changes as they occur.
- **provide-done-callback**: The component MUST invoke the `onDone` callback when the Done button is pressed, allowing the presenter to decide how to close the dialog (sheet dismissal, modal stop loop, etc.).
- **provide-close-callback**: The component MUST invoke the `onDidClose` callback once the dialog is off-screen, signaling the end of any pending row control gestures and allowing the presenter to finalize state.
- **set-return-key-equivalent**: The Done button MUST have Return (Carriage Return, `\r`) as its key equivalent, enabling keyboard activation.
- **support-accessibility-identification**: The component MUST assign accessibility identifiers to the dialog container (`<prefix>.dialog`) and Done button (`<prefix>.dialog.done`), where `<prefix>` is customizable at initialization and defaults to `"options"`.
- **respect-row-width-constraint**: The component MUST size each row to the full width of the dialog minus left and right insets, preventing row content from narrowing the dialog.
- **use-minimum-width-floor**: The component MUST apply a minimum width constraint (not an exact width) so that row content wider than the default width can expand the dialog; this allows the dialog to grow as needed while maintaining a baseline size.

## Appearance

- **Corner radius**: Rounded corners applied via the `NSButton` bezel style (`.rounded`) on the Done button; dialog background is system-defined.
- **Padding (stack insets)**: Top 18pt, left 20pt, right 20pt applied to the row/heading stack; the stack's own bottom inset is 8pt, which is internal spacing consumed before the explicit 12pt gap to the Done button described below — it is not the dialog's outer bottom margin.
- **Padding (Done button spacing)**: 12pt from the stack's bottom edge to the Done button's top, 16pt from the Done button's bottom to the dialog's outer bottom edge (the dialog's actual bottom margin), 20pt from the Done button to the right edge.
- **Row spacing**: 16pt vertical spacing between rows and between the heading and first row.
- **Font**: The heading uses `ThemedLabel` with `role: .secondaryText` and `textRole: .button`; rows use caller-provided styling.
- **Background**: `ThemedBackgroundView` with `role: .windowBackground` for the dialog container; Done button uses default system button styling.
- **Foreground/Text**: Heading text color determined by the `secondaryText` role of `ThemedLabel`.
- **Border**: None on the dialog; system button styling on Done button.
- **Shadow**: None visible; system window/sheet presentation may add shadow depending on context.
- **Min/Max size**: Minimum width is 340pt by default (customizable via `width` parameter); width grows if rows require more space. Minimum height is determined by the sum of heading, rows, spacing, and Done button.

## States

| State | Appearance change |
|-------|------------------|
| Default | Dialog displays heading (if provided), rows, and Done button in vertical stack. |
| Heading hidden | Heading label is not visible; rows and Done button remain. |
| Row interaction | No change to dialog appearance; row changes propagate immediately. |
| Closed | Dialog is removed from view hierarchy; `onDidClose` fires (from `viewDidDisappear`) to allow cleanup. |

## Accessibility

- **Role/identifier**: The component does not explicitly set an NSAccessibility role on the dialog container; it sets only an accessibility identifier (`<prefix>.dialog`) via `accessibilityID(_:)`. Any role comes from the container's underlying view class (`ThemedBackgroundView`), which this recipe does not define. The Done button is a standard `NSButton`, whose accessibility role (`.button`) comes from AppKit itself; the component adds only its accessibility identifier (`<prefix>.dialog.done`).
- **Heading label**: When present, the heading is rendered as a label with `role: .secondaryText`, providing context about the dialog's purpose. When `nil`, the label is hidden.
- **Row accessibility**: Rows are passed in by the caller; the component does not impose accessibility requirements on row content. Callers are responsible for ensuring rows are accessible (labels, roles, traits).
- **Done button**: The button has a clear, descriptive label ("Done") and is keyboard-accessible via the Return key. The button's accessibility ID (`<prefix>.dialog.done`) allows UI tests to identify and interact with it.
- **Minimum tap target**: The Done button uses the default `NSButton` `.rounded` bezel style at the regular control size, whose standard height is well under 44pt — a mouse-driven macOS convention, not the touch-target minimum the Apple HIG specifies for touch platforms. See [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons).
- **Keyboard navigation**: The Return key activates the Done button; Tab and Shift+Tab move focus through interactive row controls as defined by each row. The component does not bind Escape or ⌘. to any action — no control carries an escape key equivalent, consistent with there being no commit/cancel step (see **no-change-buffering**). If the presenter's own window or sheet dismisses on Escape, that dismissal still goes through `onDidClose`, not `onDone`.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| options-001 | accept-custom-rows | Initialize with `rows: [sliderView, popupView, textFieldView]` | All three row views are rendered in the dialog in vertical order. |
| options-002 | render-content-in-vertical-stack | Initialize with heading, 2 rows, Done button | Stack is vertical; heading renders above rows; rows render above Done button; spacing and alignment are consistent. |
| options-003 | support-dynamic-heading | Initialize with `heading: "Settings"`, then set `heading = nil` | Heading label is hidden; layout recalculates without heading space. |
| options-004 | support-dynamic-heading | Set heading to a new string after initialization | Heading label updates immediately to show the new text; dialog layout remains stable. |
| options-005 | provide-done-callback | Initialize with `onDone` callback, press Done button | `onDone` callback fires exactly once. |
| options-006 | provide-close-callback | Initialize with `onDidClose` callback, present dialog, then dismiss | `onDidClose` fires after dialog is off-screen. |
| options-007 | set-return-key-equivalent | Initialize with focus in a row control (not the Done button), press Return | Done button's action fires via its key equivalent rather than direct focus; `onDone` fires. |
| options-008 | no-change-buffering | Add a slider row that triggers an action on value change, interact with slider | Row action fires immediately; no commit or cancel operation occurs. |
| options-009 | support-accessibility-identification | Initialize with `accessibilityPrefix: "prefs"` | Dialog container has accessibility ID `"prefs.dialog"`; Done button has ID `"prefs.dialog.done"`. |
| options-010 | respect-row-width-constraint | Add a row with a long label and trailing button | Row is sized to full dialog width minus insets; content does not exceed dialog width. |
| options-011 | use-minimum-width-floor | Add a row wider than 340pt (e.g., a popup with a long provider name) | Dialog expands to accommodate the row; minimum width is not restrictive. |
| options-012 | support-accessibility-identification | Initialize with default accessibility prefix | Done button accessibility ID is `"options.dialog.done"`. |
| options-013 | render-content-in-vertical-stack | Initialize with `rows: []` and a heading | Dialog renders the heading and the Done button only; no row spacing is applied. |
| options-014 | support-dynamic-heading | Initialize with `heading: "Settings"`, set `heading = nil`, then set `heading = "Settings"` again | Heading label re-appears with its original text; layout recalculates to include heading space again. |
| options-015 | provide-close-callback | Initialize with `onDidClose` callback, present and dismiss the dialog exactly once | `onDidClose` fires exactly once. |
| options-016 | use-minimum-width-floor | Initialize with rows no wider than the default and no explicit `width` | Dialog width equals 340pt, the default floor. |

## Edge Cases

- **Null or empty heading**: If `heading` is `nil`, the heading label is hidden and does not occupy space. Setting `heading` to `nil` after initialization hides the label; setting to a non-nil string shows it again.
- **Empty rows array**: If `rows` is an empty array, the dialog renders only the heading (if provided) and the Done button. No row spacing is applied.
- **Very long heading text**: The heading label may wrap or truncate depending on the dialog width and the length of the text. The caller is responsible for managing heading length.
- **Row gesture coalescing**: Rows that coalesce writes (e.g., a stepper ticking through a multi-step gesture) may have the last change pending when the dialog closes. The `onDidClose` callback, fired from `viewDidDisappear`, allows the presenter to finalize any pending row state.
- **Dialog resizing during interaction**: Each row carries an exact equality constraint to the stack's width minus the left and right insets (see **respect-row-width-constraint** and Design Decision 7) — rows are not pinned by a minimum-width floor of their own. Only the container itself carries the `>=` floor (see **use-minimum-width-floor**). A row's own content therefore cannot shrink the dialog below the floor, but a row whose content resists compression below the floor-derived width forces the stack — and so the container — wider than the floor to satisfy that equality constraint (Design Decision 4). Separately, a row's intrinsic height change (e.g., a text-size slider growing taller) propagates through Auto Layout to the container's fitting size. The view controller does not resize any window itself — the window that hosts its view (the sheet's or modal's window) is the one that resizes, and the presenter must let that window track the view's fitting size rather than pinning it to a fixed frame.
- **Multiple dialogs presented simultaneously**: Two or more `OptionsDialogViewController` instances can be presented at the same time (e.g., sheet + modal). Each must use a distinct `accessibilityPrefix` to avoid accessibility ID collisions.
- **Dialog dismissed while row gesture in progress**: If the dialog is dismissed while a row control (e.g., a slider) is in the middle of a continuous gesture, `onDidClose` fires (from `viewDidDisappear`) to allow the presenter to terminate the gesture and release any resources held by the row.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `heading` | `String?` | (required) | The optional heading text displayed at the top of the dialog; the initializer declares no default, so callers must pass `nil` explicitly to start with no heading. Settable after initialization; `nil` hides the heading. |
| `rows` | `[NSView]` | (required) | An array of NSView subclasses to render as dialog rows. Passed at initialization only. |
| `width` | `CGFloat` | `340` | The minimum (floor) width of the dialog in points. Dialog expands if row content requires more space. |
| `accessibilityPrefix` | `String` | `"options"` | Prefix for accessibility identifiers applied to the dialog and Done button. Allows multiple dialogs to coexist without ID collisions. |

## Deep Linking

Not applicable: This is an internal UI component used to present options dialogs within an app. It does not handle deep linking or URL routing.

## Localization

The component hardcodes the string `"Done"` as the Done button's title. AppKit does not localize a custom `NSButton` title automatically — a title passed to `NSButton(title:target:action:)` is used verbatim, unlike a small set of system-supplied strings in certain standard dialogs. This component provides no localization hook for that string; a caller that needs a different or localized title has no exposed API to change it. Localization of the heading and row content is entirely the caller's responsibility, since both are supplied by the caller.

## Accessibility Options

Not applicable: The component does not respond to system accessibility display options (Reduce Motion, Increase Contrast, Differentiate Without Color). Row content may respond to these options if implemented by the row views themselves; the dialog container does not enforce or configure them.

## Feature Flags

Not applicable: This component does not use or check feature flags. Feature flag logic is the responsibility of the presenter and the row implementations.

## Analytics

Not applicable: This component does not collect or emit analytics events. Analytics tracking (if needed) must be implemented by the caller or within individual row controls.

## Privacy

Not applicable: This component does not collect, store, or transmit any user data. Any data handled by rows is the responsibility of the row implementations.

## Logging

Not applicable: This component does not emit log messages. Logging (if needed) must be implemented by the caller or row implementations.

## Platform Notes

- **Source (AppKit)**: `OptionsDialogViewController` is an NSViewController subclass implemented in `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/OptionsDialogViewController.swift`. It uses NSStackView for layout, NSButton for the Done button, and NSLayoutConstraint for sizing. The `ThemedLabel` and `ThemedBackgroundView` are AgenticDeveloperHubSDK UI components that provide system-aware theming.
- **SwiftUI**: A SwiftUI version would wrap this NSViewController in a `NSViewControllerRepresentable`, or build an equivalent SwiftUI View using `VStack`, `GroupBox`, and `Button` with similar layout and callback patterns. State would be managed via `@State` or `@ObservedObject` rather than properties.
- **Compose (Android)**: A Compose implementation would host the content in a `Dialog` (or `AlertDialog`) composable, with a `Column` for vertical layout inside it: an optional `Text` for the heading, the row composables, and a `Button` at the bottom for Done. `onDismissRequest` would map to the close callback, and a lambda passed to the Done `Button` would map to `onDone`. Insets would be applied via `Modifier.padding()`.
- **AppKit / UIKit**: On iOS, this would use `UIViewController` with a `UIStackView` (vertical). The Done button would be styled as `UIButton.Configuration.plain()` or `.tinted()`. Presentation would use `UISheetPresentationController` or `UIAlertController` modal style. Sheet detection (`isModalInPresentation`) would replace the macOS window-sizing behavior described above.
- **WinUI 3**: A WinUI 3 implementation would use `ContentDialog` as the native dialog host, with a `StackPanel` (`Orientation="Vertical"`) inside its `Content` for the heading and rows, and `PrimaryButtonText="Done"` bound to a command for the Done action. `ContentDialog` sizes itself to its content automatically, so no manual resize API is needed as rows change — unlike the AppKit floor-width constraint; a `MinWidth` on the root panel can mirror the same floor behavior.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/OptionsDialogViewController.swift` | unverified |

## Design Decisions

1. **Decision**: The component makes no assumptions about how it is presented (sheet, modal window, custom container); the presenter supplies the `onDone` and `onDidClose` callbacks.
   **Rationale**: The component cannot know how closing should be handled by every possible container, and duplicating the layout logic across multiple presentation contexts would mean two places for it to drift apart.
   **Approved**: pending

2. **Decision**: Rows apply their own changes as they are made rather than the component collecting changes and applying them on a commit operation.
   **Rationale**: This is appropriate for settings dialogs where preview is useful and the cost of reverting a change is low. For dialogs with destructive or expensive operations, the caller must add confirmation logic in the row control itself.
   **Approved**: pending

3. **Decision**: The `heading` property is settable and observable via `didSet`, updating the label's text and visibility in real time.
   **Rationale**: Dialogs named after their content (e.g., "Preferences for: FPS Meter") may be renamed while the dialog is presented; a frozen heading would misname the dialog.
   **Approved**: pending

4. **Decision**: The dialog's width uses a `>=` (floor) constraint rather than an exact width.
   **Rationale**: This allows rows wider than the default 340pt to expand the dialog, preventing truncation of long labels or UI elements that should remain fully visible (e.g., a popup with many options). An exact width would sacrifice row compression resistance, leading to truncated content.
   **Approved**: pending

5. **Decision**: The `accessibilityPrefix` parameter namespaces both the dialog's and the Done button's accessibility identifiers.
   **Rationale**: Multiple dialogs can coexist on screen with distinct accessibility IDs, which is essential for UI testing scenarios.
   **Approved**: pending

6. **Decision**: The Done button's key equivalent is set to Return (`"\r"`).
   **Rationale**: Return is the standard macOS convention for confirming dialogs; setting `keyEquivalent = "\r"` makes Done the default action for the Return key, improving keyboard navigation and accessibility.
   **Approved**: pending

7. **Decision**: Each row is pinned to the stack's width minus the left and right insets using a single constraint per row.
   **Rationale**: This ensures consistent indentation and lets row content expand or contract with the dialog without special handling in individual row controls.
   **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The Done button's explicit title, accessibility identifiers, key equivalent, and the source's exclusive use of leading/trailing (never left/right) layout anchors ground the passed statuses; `touch-target-size` and the two hardcoded-string checks fail because the source shows a regular-size `.rounded` bezel button and a literal `"Done"` string with no localization hook; the `partial` statuses reflect behavior — Dynamic Type propagation, exact system-color contrast, initial-focus/focus-trap handling, and translated-text overflow — that this file delegates to `ThemedLabel`/`ThemedBackgroundView` or the caller and so cannot confirm on its own; the controller only lays out rows and reports through `onDone`/`onDidClose` closures with no state machine or data access of its own (separation-of-concerns: passed), and `WindowOptionsDialogTests.swift` instantiates it directly to assert heading render, row-width layout, and Done-button wiring (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and dropped the contradictory may-hide-heading-when-nil requirement; reworded no-change-buffering as a MUST NOT; corrected the tap-target-size and Done-button-localization claims; added Apple HIG references; documented Escape/⌘. behavior; separated the accessibility role from the identifier; resolved the bottom-padding ambiguity and renamed the Loaded-off-screen state to Closed; named viewDidDisappear as the onDidClose hook and clarified the window-resize edge case; reformatted Design Decisions to Decision/Rationale/Approved; added a Compliance table; fixed test-vector tagging and validity and added four missing vectors; merged the duplicate AppKit/UIKit platform note and fixed the Compose and WinUI 3 native dialog APIs; corrected the summary to attribute change-application to rows, not the dialog |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed resizing edge case to match the per-row exact-width equality constraint (floor is container-only); heading Configuration default corrected to (required). Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
