---
id: 3600088a-a9f6-42ca-81db-43f0eb6ddd79
title: "Markdown Editor Toolbar"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Horizontal toolbar for switching between markdown editor modes and accessing help and file import functions."
platforms:
  - swift
  - macos
  - ios
tags:
  - editor
  - toolbar
  - markdown
depends-on: []
related:
  - d8f2a4c1-9e5b-4a2f-b8c9-e7f3a2d5c1b6
references: []
approved-by: ""
approved-date: ""
---

# Markdown Editor Toolbar

## Overview

The Markdown Editor Toolbar is a horizontal chrome bar that hosts mode selection, help access, and file import controls for a markdown editor. The toolbar adapts its height and presentation style per platform (44pt on iOS, 32pt on macOS) and supports toggling individual button visibility, configurable editor modes, and theme application. A host that provides its own help or import UI can suppress the corresponding buttons.

## Behavioral Requirements

- **mode-selector**: The component MUST render a segmented control displaying all modes in `availableModes`.
- **hide-mode-selector-single-mode**: The component MUST hide the segmented control when `availableModes` contains fewer than 2 entries.
- **empty-mode-list**: When `availableModes` is empty, the component MUST render the segmented control with zero segments and MUST hide it under **hide-mode-selector-single-mode**, with no segment selected. See Change History 1.1.0 for the source trace of this behavior.
- **help-button**: The component MUST render a help button labeled "?" by default.
- **help-button-visibility**: The component MUST respect the `showsHelpButton` property and hide the button when set to false.
- **import-button**: The component MUST render an import button labeled "Open…" by default.
- **import-button-visibility**: The component MUST respect the `showsImportButton` property and hide the button when set to false.
- **mode-change-callback**: The component MUST call `onModeChange` with the newly selected mode when the user taps a mode segment.
- **mode-change-callback-scope**: `onModeChange` MUST fire on any user tap that the platform control reports as its action — including a tap on the segment that is already selected, since the handler applies no equality check before firing — and MUST NOT fire when `mode` is set programmatically, since the `mode` property's `didSet` only re-syncs the control's selection (**sync-selection**) and never invokes the tap handler.
- **sync-selection**: The component MUST update the segmented control's selected segment when the `mode` property changes programmatically.
- **help-callback**: The component MUST call `onSyntaxHelpRequested` when the user taps the help button.
- **import-callback**: The component MUST call `onImport` when the user taps the import button.
- **theme-background**: The component MUST apply the `elevatedSurface` color from a `SemanticPalette` to its background when `applyTheme(_:)` is called.
- **theme-button-tint**: The component MUST apply the `accent` color from a `SemanticPalette` to the help and import buttons' tint color when `applyTheme(_:)` is called.

## Appearance

- **Height**: 44pt (iOS), 32pt (macOS)
- **Layout**: Horizontal stack
- **Spacing**: 8pt between items
- **Padding**: 4pt vertical, 8pt horizontal (applied to stack edges)
- **Background**: Semantic palette `elevatedSurface` color
- **Mode control width**: Intrinsic (segment widths determined by mode label text)
- **Button size**: System button size (intrinsic height constrained by stack alignment to center)
- **Mode control segments**: System segmented control styling (texturedRounded on macOS)
- **Buttons**: System button styling (rounded bezel on macOS, system type on iOS)
- **Spacer**: Flexible space between mode control and buttons, expands to fill available width
- **Dynamic Type / larger accessibility text**: The bar's height (44pt/32pt) is fixed and does not grow with the system text-size setting; only the button and segment titles use system fonts that scale with the content size category. At larger accessibility sizes the labels are what adapts — by shrinking within their intrinsic sizing or, at extreme sizes, truncating — while the bar itself keeps its fixed height. Neither implementation adjusts the bar's height for content size category.

## States

| State | Appearance change |
|-------|------------------|
| Default | All controls rendered; colors from applied theme |
| Help button hidden | Help button and adjacent space removed; other controls unchanged |
| Import button hidden | Import button and adjacent space removed; other controls unchanged |
| Mode selector hidden | Mode control and spacing removed; buttons remain visible |
| Mode control with single item | Mode control hidden; buttons visible |
| No modes available | Segmented control built with zero segments (empty group), hidden via the fewer-than-2 rule; selected segment set to no-segment (iOS `UISegmentedControl.noSegment`) / -1 (macOS) |

## Accessibility

- **Mode control role**: Segmented control. Labeled "Editor Mode" via an explicit accessibility label on macOS (`setAccessibilityLabel`). On iOS, no group-level label is set in source; VoiceOver reads each segment by its own title (the mode's `label`, e.g. "Edit", "Preview", "Split"), since `UISegmentedControl` exposes per-segment titles as accessibility labels by default.
- **Mode control accessibility ID** (macOS): "markdown-editor.mode"
- **Help button role**: Button. Labeled "Markdown Syntax Help" via an explicit accessibility label on macOS. On iOS, no explicit label is set in source; VoiceOver reads the button's own title, "?", which does not convey the button's purpose (see Compliance: screen-reader-support).
- **Help button accessibility ID** (macOS): "markdown-editor.help"
- **Import button role**: Button. Labeled "Open Markdown File" via an explicit accessibility label on macOS. On iOS, no explicit label is set in source; VoiceOver reads the button's own title, "Open…".
- **Import button accessibility ID** (macOS): "markdown-editor.import"
- **Minimum touch target size** (iOS): Apple HIG recommends 44×44pt. The bar's 44pt height minus the stack's 4pt top/bottom padding leaves at most 36pt of vertical space for the arranged controls, so the 44pt minimum is not guaranteed by layout alone (see Compliance: touch-target-size).
- **Keyboard navigation**: All buttons MUST be keyboard-focusable and activatable via Return/Space (platform default).
- **Announcements**: Mode changes MUST be announced to assistive technology when the segmented control selection updates.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| toolbar-001 | mode-selector | availableModes = [.edit, .preview, .split] | Segmented control visible with three segments labeled "Edit", "Preview", "Split" |
| toolbar-002 | hide-mode-selector-single-mode | availableModes = [.split] | Segmented control hidden |
| toolbar-003 | empty-mode-list | availableModes = [] | Segmented control built with zero segments, hidden, no segment selected |
| toolbar-004 | help-button | No special config | Help button ("?") visible |
| toolbar-005 | help-button-visibility | showsHelpButton = false | Help button hidden |
| toolbar-006 | help-button-visibility | showsHelpButton toggled false then true | Help button hidden, then visible again |
| toolbar-007 | import-button | No special config | Import button ("Open…") visible |
| toolbar-008 | import-button-visibility | showsImportButton = false | Import button hidden |
| toolbar-009 | import-button-visibility | showsImportButton toggled false then true | Import button hidden, then visible again |
| toolbar-010 | mode-change-callback | User taps a mode segment other than the selected one | onModeChange callback fired with the new mode |
| toolbar-011 | mode-change-callback-scope | User taps the already-selected mode segment | onModeChange callback fires again with the same mode |
| toolbar-012 | mode-change-callback-scope | mode = .preview set programmatically | onModeChange callback does not fire |
| toolbar-013 | sync-selection | mode = .split (programmatically) | Segmented control's selected segment updates to match |
| toolbar-014 | sync-selection | mode set to a value not present in availableModes | Segmented control's selected segment becomes no-segment (iOS `UISegmentedControl.noSegment` / macOS -1); no segment appears selected |
| toolbar-015 | help-callback | User taps help button | onSyntaxHelpRequested callback fired |
| toolbar-016 | import-callback | User taps import button | onImport callback fired |
| toolbar-017 | theme-background | applyTheme(palette) called | Background color matches palette.elevatedSurface |
| toolbar-018 | theme-button-tint | applyTheme(palette) called (iOS) | Help and import button tint colors match palette.accent |
| toolbar-019 | mode-selector | macOS, default config | Mode control's accessibility label is "Editor Mode" and accessibility identifier is "markdown-editor.mode" |
| toolbar-020 | help-button | macOS, default config | Help button's accessibility label is "Markdown Syntax Help" and accessibility identifier is "markdown-editor.help" |
| toolbar-021 | import-button | macOS, default config | Import button's accessibility label is "Open Markdown File" and accessibility identifier is "markdown-editor.import" |
| toolbar-022 | sync-selection | User changes the mode control's selection | The new selection is announced to assistive technology |

## Edge Cases

- **Empty availableModes**: The segmented control is built with zero segments and hidden under the same rule as the single-mode case (**hide-mode-selector-single-mode**); no segment is selected. The help and import buttons are unaffected. See Change History 1.1.0 for the source trace of this behavior.
- **Mode not in availableModes**: Setting `mode` to a value absent from `availableModes` sets the segmented control to no selected segment (iOS `UISegmentedControl.noSegment` / macOS -1); no segment appears selected until `mode` is set to a value present in `availableModes`.
- **Mode change during presentation**: On iOS, help is presented with `modalPresentationStyle = .formSheet`, a modal presentation that blocks interaction with the presenting view; the mode control cannot be tapped while the sheet is showing, so a mode change during presentation cannot occur. On macOS, `popover.behavior = .transient`, and no code path in `modeChanged()` touches `popover` — tapping the mode control is an interaction outside the popover, which AppKit's transient behavior closes automatically as a side effect of the click; the mode change itself proceeds unaffected.
- **Theme applied before window** (macOS): `applyTheme(_:)` sets `wantsLayer` and the layer's background color at any time; the color takes effect once the view is drawn, so calling it before the toolbar joins a window hierarchy has no visible effect until the window is established.
- **Help requested before window** (macOS): `presentSyntaxHelp` guards on `helpButton.window != nil`; calling it before the toolbar is added to a window hierarchy silently no-ops — no popover is shown and no callback fires.
- **Multiple theme applications**: If `applyTheme(_:)` is called multiple times, each call updates the background color (and, on iOS, the button tint colors) without side effects.
- **Null callbacks**: Callbacks (`onModeChange`, `onImport`, `onSyntaxHelpRequested`) are optional and default to nil. Tapping a button when the callback is nil results in no action.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| availableModes | [MarkdownEditorMode] | MarkdownEditorMode.allCases | Array of modes the user can select from |
| mode | MarkdownEditorMode | .split | Currently selected editor mode |
| showsHelpButton | Bool | true | Whether the help button is visible |
| showsImportButton | Bool | true | Whether the import button is visible |
| onModeChange | ((MarkdownEditorMode) -> Void)? | nil | Callback fired when mode selection changes |
| onImport | (() -> Void)? | nil | Callback fired when import button is tapped |
| onSyntaxHelpRequested | (() -> Void)? | nil | Callback fired when help button is tapped |

## Deep Linking

Not applicable: The toolbar does not respond to deep links; it is a sub-component that receives its state from a parent editor or container.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| markdown-editor.mode-label.edit | "Edit" | Segmented control segment label for the `.edit` mode |
| markdown-editor.mode-label.preview | "Preview" | Segmented control segment label for the `.preview` mode |
| markdown-editor.mode-label.split | "Split" | Segmented control segment label for the `.split` mode |
| markdown-editor.help-title | "?" | Visible title of the help button |
| markdown-editor.help-label | "Markdown Syntax Help" | Accessibility label for help button (macOS) |
| markdown-editor.import-title | "Open…" | Visible title of the import button |
| markdown-editor.import-label | "Open Markdown File" | Accessibility label for import button (macOS) |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | No animations are used by the toolbar itself; presentation of help content respects the presenter's motion preferences. |
| Increase Contrast | Not applicable: The toolbar uses semantic colors from the palette; the host environment applies high-contrast palettes. |
| Differentiate Without Color | Not applicable: All controls are differentiated by label and role, not color alone. |

## Feature Flags

Not applicable: The toolbar is not gated by feature flags.

## Analytics

Not applicable: The toolbar does not fire analytics events directly; hosts that embed it are responsible for logging user interactions if needed.

## Privacy

- **Data collected**: None. The toolbar does not collect, store, or transmit any user data.

## Logging

Not applicable: The toolbar does not emit logging output in its current implementation.

## Platform Notes

- **SwiftUI**: A SwiftUI wrapper around the UIView/NSView would use `UIViewRepresentable` (iOS) or `NSViewRepresentable` (macOS) to embed the native toolbar. Callbacks are mapped to SwiftUI state updates via `@State` or parent-driven properties.
- **Compose (Android)**: Start with a `Row` layout containing a `SegmentedButton` group for modes, a `Spacer` modifier with `Modifier.weight(1f)`, and `IconButton` or `Button` composables for help and import. Mode changes call a callback passed as a lambda. Visibility controlled by simple conditional rendering.
- **React/Web**: A `<div role="toolbar">` with `display: flex` (row) hosts a `radiogroup` of `role="radio"` buttons — one per `MarkdownEditorMode` — for the mode selector, a `flex: 1` spacer `<div>`, and two `<button>` elements for help and import. Selecting a radio calls an `onModeChange` prop with the new mode; the mode selector renders nothing (or `display: none`) when `availableModes.length < 2`. Apply theme colors via CSS custom properties bound to the semantic palette.
- **AppKit / UIKit**: Implemented directly in `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/iOS/Markdown/MarkdownEditorToolbar.swift` (`UIView`) and `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Markdown/MarkdownEditorToolbar.swift` (`NSView`); both expose the same property and callback API. Apply theme via `applyTheme(_:)` after initialization and wire callbacks to your presentation logic. `presentSyntaxHelp` differs by platform: `UIViewController.present` (modal `.formSheet`) on iOS, `NSPopover` on macOS.
- **WinUI 3**: Build the mode selector from a single `RadioButtons` control (`Microsoft.UI.Xaml.Controls.RadioButtons`), one radio per `MarkdownEditorMode`, followed by a flexible spacer and `AppBarButton` controls for help and import. Map the control's `SelectionChanged` event to `onModeChange` by indexing `availableModes` with the control's `SelectedIndex`. Apply theme colors via `Resources` (theme overrides) or direct property assignment. Help presentation uses a `ContentDialog` or `TeachingTip` instead of `NSPopover`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/iOS/Markdown/MarkdownEditorToolbar.swift` | unverified |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Markdown/MarkdownEditorToolbar.swift` | unverified |

## Design Decisions

**Decision**: Use a fixed height per platform — 44pt on iOS, 32pt on macOS.
**Rationale**: iOS follows the Apple HIG standard button height; macOS follows the macOS toolbar standard. The different heights reflect platform conventions, not functional differences.
**Approved**: pending

**Decision**: Hide the segmented control when only one mode is available.
**Rationale**: Reduces visual clutter and simplifies the toolbar when there is nothing to switch between; the mode value is still tracked internally and can be changed programmatically.
**Approved**: pending

**Decision**: Insert a flexible spacer between the mode control and the buttons.
**Rationale**: Ensures the help and import buttons align to the right edge, following common toolbar patterns.
**Approved**: pending

**Decision**: Set explicit accessibility labels for the mode control, help button, and import button on macOS; rely on system title inference on iOS.
**Rationale**: The "?" title is ambiguous for screen readers, so macOS sets explicit labels ("Editor Mode", "Markdown Syntax Help", "Open Markdown File"). iOS has no equivalent explicit labels in source; VoiceOver falls back to reading each control's own title text, which is a real gap for the help button (see Compliance: screen-reader-support).
**Approved**: pending

**Decision**: Present help as a transient `NSPopover` on macOS and a modal sheet on iOS.
**Rationale**: Reflects each platform's norm for supplementary information windows — a dismiss-on-blur popover on macOS, a modal presentation on iOS.
**Approved**: pending

**Decision**: Make all three callbacks (`onModeChange`, `onImport`, `onSyntaxHelpRequested`) optional.
**Rationale**: Lets a host ignore mode changes by leaving `onModeChange` unset, or suppress the help button entirely via `showsHelpButton = false`, without requiring stub callbacks.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | failed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

These statuses rest on: macOS's explicit `setAccessibilityLabel`/`accessibilityID` calls on the mode control and both buttons, against iOS's complete absence of any accessibility-label call, for the partial screen-reader-support; the standard `UIButton`/`NSButton`/`UISegmentedControl`/`NSSegmentedControl` focus and activation behavior for the passed keyboard-navigable; the fixed 44pt/32pt bar height with no content-size-category handling in either source file for the failed dynamic-type-support; the palette-driven `accent`/`elevatedSurface` colors whose literal values live outside this file for the partial contrast-ratio; the 44pt iOS height minus the stack's 4pt top/bottom padding, leaving at most 36pt of usable height, for the failed touch-target-size; the literal `"?"`, `"Open…"`, `"Markdown Syntax Help"`, and `"Open Markdown File"` strings set directly on the controls with no localization lookup for the failed internationalization checks; the intrinsic (non-fixed-width) sizing of the segmented control and buttons for the partial text-expansion-tolerance; and the unmodified default stack-view mirroring behavior, which flips under RTL by system default but is exercised by no test in source, for the partial rtl-layout-support. `separation-of-concerns` passes because both platform views hold only layout-mapping methods (`rebuildModeControl`, `syncSelection`) and closure-based callbacks (`onModeChange`, `onImport`, `onSyntaxHelpRequested`), with no business logic or data access of their own; `unit-test-coverage` fails because no test file references `MarkdownEditorToolbar`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from macOS and iOS source |
| 1.1.0 | 2026-09-22 | Claude Sonnet 5 | Settled the three open review points from source: empty availableModes builds a hidden zero-segment control (traced to rebuildModeControl/syncSelection), and mode changes cannot occur during iOS's modal help sheet and only incidentally close macOS's transient popover |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, added mode-change-callback-scope settling programmatic vs. repeat-tap firing, corrected test-vector mode cases to the real MarkdownEditorMode set and added vectors for empty/out-of-range modes, visibility toggling, and accessibility/announcement coverage, expanded localization keys per visible string and per mode, split the theme-before-window and help-before-window edge cases, added a Dynamic Type note to Appearance and a derived touch-target note to Accessibility, reformatted Design Decisions to Decision/Rationale/Approved, canonicalized the Compliance table with corrected touch-target and screen-reader statuses, merged the two AppKit/UIKit platform notes, added a React/Web platform note, named a single WinUI 3 control, and listed the parent editor in related |
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
