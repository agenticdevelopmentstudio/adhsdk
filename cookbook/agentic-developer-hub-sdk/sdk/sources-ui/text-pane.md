---
id: 61f589a9-d32f-4e9b-85db-1f9aa0eee009
title: "Markdown Text Pane"
type: ingredient
version: 1.2.3
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A scrollable plain-text pane for editing Markdown source (it does not render Markdown), with theme support and a unified macOS/iOS API."
platforms:
  - swift
  - macos
  - ios
tags:
  - text-input
  - editor
  - markdown
depends-on: []
related:
  - d8f2a4c1-9e5b-4a2f-b8c9-e7f3a2d5c1b6
  - 8f2e1c9d-7a4b-4c2e-9d8e-5f6c7d8e9f0a
references: []
approved-by: ""
approved-date: ""
---

# Markdown Text Pane

## Overview

The Markdown Text Pane is a lightweight container that wraps platform-native text editing controls (`NSTextView` on macOS, `UITextView` on iOS) with a unified API. "Markdown" in the name means the pane edits Markdown source; it never renders or previews Markdown. It hosts plain-text editing with undo support, in-pane find on macOS only, and theme application via semantic color palettes. The component is designed for document surfaces that remain in focus for extended reading and editing sessions, as opposed to inline or transient input fields.

## Behavioral Requirements

- **initialize-with-editability**: The component MUST initialize with an `editable` parameter that determines whether text editing is allowed (true = editable, false = read-only).
- **provide-editability-property**: The component MUST provide an `isEditable` property that reads and modifies the underlying text view's edit mode at runtime.
- **report-text-changes**: The component MUST fire the `onTextChange` callback with the current plain-text content whenever the user edits the text. The callback receives the complete current string, not a delta.
- **silent-programmatic-set**: Setting the `text` property MUST NOT trigger the `onTextChange` callback. Programmatic text assignment exists to enable controllers that render from `onTextChange` to update the pane without re-entrancy loops.
- **provide-text-property**: The component MUST provide a `text` property that reads and sets the pane's plain-text content. Reading returns the complete string; empty panes return an empty string (never null).
- **support-attributed-text**: The component MUST support reading and setting attributed (styled) text via `attributedText` (read-only) and `setAttributedText(_:)` (write). Attributes set this way are display-only styling that reads back unchanged; formatting entered by the user (typing or pasting) is plain text, per **use-plain-text-mode**.
- **support-focus**: The component MUST provide a `focus()` method that moves keyboard focus to the underlying text view and returns a boolean indicating success. A pane without focus does not receive keystrokes because the internal text view is private.
- **support-theme**: The component MUST accept a `SemanticPalette` via `applyTheme(_:)` to customize colors and font. Theme application MUST update the background, text foreground, cursor color and code font (not body font) on both platforms. On macOS it MUST also set the selection background and selection foreground; on iOS, selection is tinted only through `tintColor`, which takes the palette's cursor color, and no separate selection foreground is set.
- **disable-smart-substitutions-ios**: On iOS, the component MUST disable `autocorrectionType`, `smartQuotesType`, and `smartDashesType` to prevent automatic text transformations inappropriate for code/markdown content.
- **disable-smart-substitutions-macos**: On macOS, the component MUST disable automatic quote substitution, dash substitution, spelling correction, and text replacement to prevent automatic text transformations.
- **allow-undo-macos**: On macOS, the component MUST support the undo system (`allowsUndo = true` on the text view).
- **preserve-default-undo-ios**: On iOS, the component MUST NOT disable or replace the text view's `undoManager`; the platform's default undo behavior (e.g. shake-to-undo, hardware Cmd+Z) MUST remain available.
- **use-plain-text-mode**: The component MUST operate in plain-text mode. Rich text editing, markdown parsing, and styled rendering are explicitly not in scope.
- **scroll-vertically**: The component MUST support vertical scrolling. On macOS, the scroll view provides this; on iOS, the text view provides built-in scrolling.
- **hide-scrollers-macos**: On macOS, the scroll view MUST use overlay scrollers that auto-hide when not in use. The scroll view MUST have no visible border.
- **bounce-vertically-ios**: On iOS, the text view MUST bounce when scrolled past the content end.
- **selectable-when-read-only**: The text view MUST remain selectable (`isSelectable = true`) whether or not the pane is editable, so read-only content can be selected and copied.
- **use-8pt-insets**: The component MUST apply 8pt insets (edges) around the text content, matching the document-surface intent rather than the tighter 6pt used by the toolkit's Quick Note field.
- **enable-find-bar-macos**: On macOS, the component MUST enable the text view's built-in find bar (`usesFindBar = true`, `isIncrementalSearchingEnabled = true`) so Cmd+F opens in-pane search. The iOS variant exposes no equivalent — see the **Design Decisions** entry on this asymmetry.

## Appearance

- **Corner radius**: None; square edges
- **Padding (insets)**: 8pt on all edges (top, left, bottom, right)
- **Font**: Semantic code font from the applied theme — `applyTheme(_:)` takes the whole `SemanticPalette` and sets the text view's font to `palette.font(.code)`
- **Background**: Window background semantic color from the applied theme
- **Foreground/Text**: Primary text semantic color from the applied theme
- **Border**: None
- **Shadow**: None
- **Min/Max size**: No enforced constraints; size is determined by the parent container

## States

| State | Appearance change |
|-------|------------------|
| Default | Unfocused: cursor hidden; text displayed. Focus is never automatic (see **support-focus**) |
| Read-only (not editable) | Cursor hidden; selection still visible; text still scrollable |
| Focused | Cursor blinks and accepts keyboard input |
| Unfocused | Cursor hidden; text and selection remain visible |
| Themed | Background, text color, cursor color, and selection colors updated per palette |

## Accessibility

- **Role/trait**: Text area / rich text input (depending on platform accessibility framework)
- **Label requirements**: The pane itself has no built-in label, and its public API provides no member through which a caller could set one — `textView` is private in both variants, so the standard `UIAccessibility`/`NSAccessibility` label mechanisms are not reachable through this component's surface. See the accessibility gap under **Compliance**.
- **Announce state changes**: The read-only state transition (toggling `isEditable`) is not automatically announced. The parent is responsible for signaling mode changes to accessibility systems if needed.
- **Minimum tap target**: On iOS, the text view itself is the touch target; its size is determined by its container. The 44×44pt minimum SHOULD be respected by the parent container.
- **Keyboard navigation**: The text view supports standard keyboard navigation (arrows, home/end, page up/down, etc.) on both platforms.
- **Selection and copy**: Text selection and copy/paste are supported on both platforms via standard gestures and keyboard shortcuts.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mtpane-001 | initialize-with-editability | `MarkdownTextPane(editable: true)` | Pane is created and text editing is enabled |
| mtpane-002 | initialize-with-editability | `MarkdownTextPane(editable: false)` | Pane is created and text editing is disabled |
| mtpane-003 | provide-editability-property | Set `pane.isEditable = true` on a read-only pane | Text editing becomes enabled; user can edit |
| mtpane-004 | provide-editability-property | Set `pane.isEditable = false` on an editable pane | Text editing becomes disabled; user cannot edit |
| mtpane-005 | report-text-changes | User types "Hello" into an editable pane | `onTextChange` is called with "Hello" |
| mtpane-006 | silent-programmatic-set | Set `pane.text = "Programmatic"` directly | `onTextChange` is not called |
| mtpane-007 | provide-text-property | Set `pane.text = "Sample text"` then read `pane.text` | Returns "Sample text" exactly |
| mtpane-008 | provide-text-property | Create pane without setting text, read `pane.text` | Returns empty string "" (not nil) |
| mtpane-009 | support-attributed-text | Set `pane.setAttributedText(styled)` where styled includes bold/italic attributes | Read `pane.attributedText` returns the styled text with attributes preserved |
| mtpane-010 | support-focus | Call `pane.focus()` on an onscreen pane | Returns true; keyboard focus moves to text view; user keystrokes are received |
| mtpane-011 | support-focus | Call `pane.focus()` on a pane without a window | Returns false; no focus change occurs |
| mtpane-012 | support-theme | On macOS, call `applyTheme(palette)` with a palette defining windowBackground, primaryText, cursor, selection, selectionText, and code font | Text view background, text color, insertion point color, selection highlight colors, and font are updated |
| mtpane-027 | support-theme | On iOS, call `applyTheme(palette)` with the same palette | Background, text color and font are updated; the selection UI is tinted with the palette's cursor color and no separate selection foreground is set |
| mtpane-013 | disable-smart-substitutions-ios | On iOS, user types a quote character | No smart quote substitution occurs |
| mtpane-014 | disable-smart-substitutions-ios | On iOS, user types two hyphens | No smart dash substitution occurs |
| mtpane-015 | disable-smart-substitutions-macos | On macOS, user types a quote character | No smart quote substitution occurs |
| mtpane-016 | allow-undo-macos | On macOS, user edits text then presses Cmd+Z | Text reverts to prior state; undo is available |
| mtpane-017 | use-plain-text-mode | Paste rich formatted text into the pane | Text is pasted as plain text; formatting is stripped |
| mtpane-018 | scroll-vertically | Pane contains content taller than its bounds | Vertical scrolling is available to reveal off-screen content |
| mtpane-019 | hide-scrollers-macos | On macOS, scroll a large document and then remain still | Scroll indicator appears momentarily and then auto-hides |
| mtpane-020 | bounce-vertically-ios | On iOS, scroll vertically past content end | Text view bounces back to content boundary |
| mtpane-021 | use-8pt-insets | Set `pane.text = "X"` in a laid-out pane and measure where the first line sits relative to the pane's bounds | The first line's top edge is 8pt below the pane's top edge on both platforms, and the text starts at least 8pt from the leading edge (the text container's line fragment padding adds to the 8pt horizontally). A unit test inside the module may instead read the private text view's inset, which equals 8pt on every edge |
| mtpane-022 | enable-find-bar-macos | On macOS, press Cmd+F while the pane is focused | The text view's find bar opens for in-pane search |
| mtpane-023 | preserve-default-undo-ios | On iOS, edit text then invoke the system undo (e.g. shake gesture, or Cmd+Z with a hardware keyboard) | Text reverts to the prior state; the pane does not intercept or disable the system `undoManager` |
| mtpane-024 | disable-smart-substitutions-macos | On macOS, user types two hyphens | No smart dash substitution occurs |
| mtpane-025 | disable-smart-substitutions-macos | On macOS, user types a misspelled word | No automatic spelling correction is applied |
| mtpane-026 | disable-smart-substitutions-macos | On macOS, user types a recognized text-replacement shortcut | No automatic text replacement occurs |
| mtpane-028 | hide-scrollers-macos | On macOS, inspect the pane's scroll view border | The scroll view draws no border; the text runs edge to edge |
| mtpane-029 | selectable-when-read-only | Create `MarkdownTextPane(editable: false)`, then select text and copy | Text can be selected and copied although it cannot be edited |
| mtpane-030 | disable-smart-substitutions-ios | On iOS, user types a misspelled word | No autocorrection is applied |
## Edge Cases

- **Empty text**: Reading `text` when the pane is empty returns an empty string (never nil). Setting `text = ""` clears all content without firing `onTextChange`.
- **Null/nil text**: The API surface does not expose nil values. `UITextView.text` and `NSTextView.string` are always safe-unwrapped in the implementation, so read operations never return null.
- **Rapid successive edits**: User performs multiple edits in quick succession. Each edit fires `onTextChange` independently; no debouncing or throttling is performed. The caller is responsible for debouncing if needed.
- **Very large text**: Pane contains megabytes of text. The implementation uses native text views without pagination or virtual scrolling, so rendering performance depends on platform capabilities. No explicit size limits are enforced.
- **Programmatic text set while user is editing**: Caller sets `text` programmatically while the user is actively editing. The text immediately updates without firing `onTextChange`, potentially discarding in-flight edits. This is the expected behavior per the re-entrancy safeguard design.
- **Theme change mid-edit**: `applyTheme()` is called while text is being edited. Colors and font update immediately; the text view remains editable with no interruption.
- **Focus request off-screen**: User calls `focus()` on a pane that is not in the visible window hierarchy. On iOS, `becomeFirstResponder()` returns `false` when the view has no window — UIKit requires the view to be attached to a window to become first responder, so no focus change occurs. On macOS, `window?.makeFirstResponder(textView)` returns `false` if `window` is `nil`, with the same result.
- **Read-only to editable transition during selection**: User selects text, then the pane transitions to read-only. Selection remains visible. Transitioning back to editable preserves the selection. User can type to replace it.
- **Attributed text with no attributes**: Read `attributedText` when `text` is plain with no styling applied. Returns an `NSAttributedString` with no attributes attached to the characters.

## Configuration

Not applicable: Markdown Text Pane has no configuration options beyond the `editable` parameter passed at initialization and the subsequent `isEditable` property.

## Deep Linking

Not applicable: Markdown Text Pane is a container component with no deep-linking support. Deep linking, if needed, is the responsibility of the controller that hosts this pane.

## Localization

Not applicable: Markdown Text Pane displays user-supplied text and system UI elements (e.g., cursor, selection highlighting) that are inherently localized by the platform. The component itself contains no user-facing strings.

## Accessibility Options

- **Reduce Motion**: This component performs no animation of its own; text-view caret blinking is native platform behavior outside this component's control and is unrelated to the Reduce Motion setting. No special handling is required.
- **Increase Contrast**: The parent controller is responsible for choosing a high-contrast palette when applying the theme. The pane respects whatever foreground and background colors are provided.
- **Differentiate Without Color**: Text selection is drawn with `applyTheme`'s own selection colors, not a platform-chosen highlight: on macOS `applyTheme` sets `selectedTextAttributes` from the palette's selection background and selection text roles, and on iOS it tints the built-in selection UI via `tintColor` from the palette's cursor color. Whether the highlight is distinguishable without relying on color alone is therefore the palette's responsibility, not the platform's.

## Feature Flags

Not applicable: Markdown Text Pane is a low-level container component with no feature flags.

## Analytics

Not applicable: Markdown Text Pane is a presentational component with no built-in analytics. The parent controller is responsible for logging user interactions (e.g., open, edit, save) as appropriate for the application.

## Privacy

Not applicable: Markdown Text Pane does not collect, store, or transmit data. It operates entirely on text provided by the caller and fires no network requests.

## Logging

Not applicable: Markdown Text Pane performs no logging of its own. Platform text views may emit internal debug logs for text input handling, but these are not controlled by this component.

## Platform Notes

- **SwiftUI**: SwiftUI has no built-in bridge for `NSTextView`/`UITextView`. Wrap `MarkdownTextPane` directly as an `NSViewRepresentable` (macOS) / `UIViewRepresentable` (iOS) struct — not a view modifier. Expose `text` as `@Binding var text: String`, `onTextChange` as a closure property invoked from the `Coordinator`'s delegate callback, and `isEditable`/`focus()` as forwarded members. The `Coordinator` MUST guard against re-entrant updates: writing an incoming `text` binding change into the pane must not re-trigger `onTextChange` (mirroring **silent-programmatic-set**), and relaying `onTextChange` back into the binding must not cause `updateNSView`/`updateUIView` to write it straight back into the text view.

- **React/Web**: Use a `<textarea>` with `spellcheck="false"` and `autocomplete="off"`, 8px padding, and `readOnly` for the non-editable mode. Fire `onTextChange` from the `input` event, and suppress it around programmatic writes to `value` with a flag (mirroring **silent-programmatic-set**), since a programmatic assignment to `value` does not fire `input` but a framework re-render may.

- **Compose (Android)**: The Android equivalent starts with `BasicTextField` from Compose. Configure it with `keyboardOptions = KeyboardOptions(autoCorrectEnabled = false, capitalization = KeyboardCapitalization.None)` — `autoCorrect` is deprecated in favor of `autoCorrectEnabled` — apply `Modifier.padding(8.dp)`, and expose callbacks for text changes and focus via Compose state management (`remember { mutableStateOf(...) }` / `FocusRequester`). Smart-quote substitution is a platform IME setting outside the app's control, not something this component configures. Give the field its own scrolling with `Modifier.verticalScroll(rememberScrollState())` on the `BasicTextField`/its container, rather than nesting it in a `LazyColumn`, which is for lists of items, not for scrolling a single text field's overflow.

- **AppKit / UIKit**: `MarkdownTextPane.swift` exists in two variants with an identical API (property names, callback signature, init parameter): one in `SourcesUI/macOS/Markdown/` and one in `SourcesUI/iOS/Markdown/`. On macOS, start from `NSTextView` and wrap it in `NSScrollView` with `autohidesScrollers = true` and `borderType = .noBorder`. On iOS, use `UITextView` directly with `alwaysBounceVertical = true` and `autocorrectionType = .no`. Both set `isSelectable = true`; macOS also sets `isRichText = false` (`UITextView` has no such property and is plain unless `allowsEditingTextAttributes` is enabled, which it is not). Only macOS enables the find bar (`usesFindBar = true`, `isIncrementalSearchingEnabled = true`). Inset the text container by 8pt. Attach a delegate to capture text changes and fire the callback, taking care not to recurse on programmatic text assignment.

- **WinUI 3**: Start with `TextBox` from the `Microsoft.UI.Xaml.Controls` namespace — plain `TextBox`, not `RichEditBox`, to match the source platform's plain-text commitment; set `AcceptsReturn = True` and `TextWrapping = TextWrapping.Wrap` for a multi-line editing surface, and rely on `TextBox`'s own scrolling rather than wrapping it in a `ScrollViewer`. Disable autocorrect with `IsSpellCheckEnabled = false` and `IsTextPredictionEnabled = false`. Apply an 8-unit `Padding` (not `Margin`, which sits outside the control) around the text content. `TextChanged` fires on any text mutation, including a programmatic write to `Text` — mirror **silent-programmatic-set** with a suppression flag (e.g. `_isSettingProgrammatically`) set around programmatic assignment and checked before forwarding to the `onTextChange` equivalent. Map `isEditable` to the built-in `IsReadOnly` dependency property (inverted) rather than introducing a new one.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/iOS/Markdown/MarkdownTextPane.swift` | confirmed (1.2.3) |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Markdown/MarkdownTextPane.swift` | confirmed (1.2.3) |

## Design Decisions

**Decision**: Use 8pt insets on all edges instead of the 6pt used by the toolkit's Quick Note field (per the comments in `MarkdownTextPane.swift`).
**Rationale**: The wider gutter signals that the pane is a document surface intended for longer reading/editing sessions, not an ephemeral note; see **use-8pt-insets**. The difference is visually intentional and MUST NOT be "fixed" to match other components.
**Approved**: pending

**Decision**: Support only plain text — no rich text, markdown parsing, or styled rendering.
**Rationale**: This constraint simplifies the API, reduces platform-specific rendering complexity, and aligns with the use case of hosting markdown source files, which are plain text; see **use-plain-text-mode**. Styled rendering and markdown preview are the responsibility of parent controllers.
**Approved**: pending

**Decision**: The `text` setter does not fire `onTextChange`.
**Rationale**: This is load-bearing for controllers that re-render from text changes; see **silent-programmatic-set**. A controller that receives `onTextChange`, processes it, and writes the result back via `text =` must not re-enter its own callback, or a feedback loop is inevitable.
**Approved**: pending

**Decision**: Focus is an explicit `focus()` method, not automatic first-responder on initialization.
**Rationale**: This prevents unwanted keyboard display (especially on iOS) and gives the parent window/modal control over focus order; see **support-focus**.
**Approved**: pending

**Decision**: Enable the find bar (`usesFindBar`, `isIncrementalSearchingEnabled`) on macOS only; the iOS variant exposes no find UI.
**Rationale**: This reflects platform UX conventions — the iOS variant relies on the platform's standard text selection and copy flow instead; see **enable-find-bar-macos**. The asymmetry is intentional.
**Approved**: pending

**Decision**: Enable `allowsUndo` on macOS; on iOS, rely on `UITextView`'s default undo behavior rather than adding a custom undo stack.
**Rationale**: The asymmetry reflects platform capabilities and macOS's deeper undo integration. The pane MUST NOT disable the default iOS undo manager; see **allow-undo-macos** and **preserve-default-undo-ios**.
**Approved**: pending

**Decision**: Accept that the pane exposes no accessible name for now: the text view is private and no label-forwarding member exists, so a caller cannot name it.
**Rationale**: Adding one means a public API change (for example a member that forwards to the text view's accessibility label), which the source does not yet have. The gap is recorded as a failed screen-reader-support check in Compliance rather than hidden; the fix is a label-forwarding member, after which the check is re-evaluated.
**Approved**: pending

**Decision**: "Markdown" in the title, tag and class name refers to the content the pane edits, not to rendering.
**Rationale**: The pane is plain-text only (**use-plain-text-mode**); rendering and preview belong to the controllers above it. The Overview and summary say so up front so readers do not expect a rendered view.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | failed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.platform-compliance.platform-design-language](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/cbd07fee-ca18-58a8-bb2f-0f8a6b83ac1c) | passed | Platform Compliance |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform Compliance |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`keyboard-navigable`, `focus-management`, `platform-design-language`, and `native-controls-preference` rest on the source wrapping the native `NSTextView`/`UITextView` directly, with the explicit, delegate-driven `focus()` path (mtpane-010/011); `unicode-support` and `input-sanitization` rest on the plain-text-only design (**use-plain-text-mode**), which stores and echoes text without parsing or executing it; `dynamic-type-support`, `contrast-ratio`, `touch-target-size`, and `rtl-layout-support` are `partial` because the source delegates font, color, sizing, and bidi behavior to the caller's palette/container and to native `UITextView`/`NSTextView` defaults, which this ingredient cannot verify; `data-minimization` rests on the Privacy section's confirmation that the component collects, stores, and transmits nothing beyond the text the caller provides. `separation-of-concerns` is passed because both variants are pure presentation over the native text view — no parsing, formatting, or business logic lives in either file, and rendering (Markdown parsing/highlighting) is handled elsewhere by the controllers above this pane; `unit-test-coverage` is partial: `MarkdownTextPaneInputTests` (iOS and macOS) and `MarkdownViewerControllerTests` were joined by `SDK/TestsUI/Shared/Markdown/MarkdownTextPaneConformanceTests.swift`, compiled into both test bundles, which covers every vector (shared, AppKit-only and UIKit-only suites) except two skipped on iOS: the iOS half of mtpane-010, because keyboard focus needs a key window and the keyboard focus engine, and mtpane-023, because shake-to-undo and hardware Cmd+Z cannot be driven from a unit test. Several vectors (mtpane-013 to 020, 024 to 026, 028, 030) are asserted as the text view or scroll view configuration that produces the behavior, not by simulating the keystroke, paste or scroll gesture.

The component provides no accessible name. `textView` is private in both variants, and the public API (`text`, `attributedText`, `isEditable`, `focus()`, `applyTheme(_:)`) exposes no label-setting member, so a caller has no way to give the pane an accessible name — `UITextView`/`NSTextView` still supply their native role (text view/text area) and read their content back as the value, but not a name (see **screen-reader-support** above, marked failed, and the accepted gap in Design Decisions).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.3 | 2026-11-14 | Mike Fullerton | Clarified that Markdown means editing source, split theme selection per platform, resolved the attributed-text contradiction, made the accessible-name gap and test coverage honest, and added vectors for read-only selection, the no-border clause and iOS autocorrect. |
| 1.2.2 | 2026-09-25 | Mike Fullerton | Selection highlight is palette-driven, not platform-chosen; support-theme, Themed row, mtpane-012, and Differentiate Without Color corrected. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; added enable-find-bar-macos and preserve-default-undo-ios with test vectors; completed the macOS substitution test vectors and fixed the insets vector to assert `textContainerInset` instead of "baseline"; corrected the `applyTheme` signature citation and named each platform's cursor-color property; rewrote the Accessibility label bullet, Reduce Motion bullet, and Differentiate Without Color bullet to match the source; gave the iOS focus-off-screen edge case a definite result; corrected the SwiftUI, Compose, and WinUI 3 platform notes; reformatted Design Decisions to the three-field form; replaced the Compliance prose with a checks table while keeping the accessible-name gap as a marker; unquoted `modified`; linked the sibling recipes that host this pane |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Compliance: narrowed the accessibility review marker to the missing fact (no accessible name, `textView` is private with no label-forwarding member) and what would settle it |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
