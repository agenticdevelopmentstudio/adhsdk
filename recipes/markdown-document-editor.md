---
id: d8f2a4c1-9e5b-4a2f-b8c9-e7f3a2d5c1b6
title: "Markdown Document Editor"
domain: adhsdk://recipes/markdown-document-editor
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A markdown source editor with live preview, responsive layout toggling between split and tabbed views, and debounced rendering."
platforms:
- typescript
- web
- swift
- macos
- ios
tags: 
  - markdown
  - editor
  - form-input
  - live-preview
depends-on:
  - adhsdk://recipes/markdown-editor
  - adhsdk://recipes/markdown-editor-toolbar
  - adhsdk://recipes/markdown-reading-palette
  - adhsdk://recipes/split-view-control
related: []
references: []
approved-by: ''
approved-date: ''
---

# Markdown Document Editor

## Overview

A markdown document editing component that pairs a source editor with a live preview pane. The component responds to viewport width: on wide viewports it displays editor and preview side-by-side in a split view; on narrow viewports it switches to a tabbed interface showing one pane at a time. Preview rendering is debounced to avoid expensive recalculation on every keystroke. The component remembers the user's last chosen layout mode and restores it when the viewport widens again.

## Behavioral Requirements

- **render-editor-pane**: The component MUST render a text editor pane for markdown content input.
- **render-preview-pane**: The component MUST render a preview pane showing the rendered markdown output.
- **sync-content-to-preview**: The component MUST update the preview pane when the editor content changes.
- **debounce-preview-render**: The component MUST debounce preview rendering by 300 milliseconds to defer expensive rendering operations beyond keystroke velocity.
- **skip-redundant-content-update**: The component MUST NOT trigger a preview re-render or restart the debounce timer when the host sets the content to the same string it already holds.
- **split-layout-above-threshold**: The component MUST display editor and preview side-by-side once the viewport crosses the platform's own split-view breakpoint: a fixed 700pt width on Apple platforms (`splitWidthThreshold`), or the `(min-width: 64rem)` media query on web (`SPLIT_MIN_WIDTH`, inherited from `SplitViewControl`'s `SPLIT_VIEW_MIN_WIDTH`) — 1024px at the browser's default root font size, not a 700px number. Crossing the breakpoint only makes Split *available*; on web the component still opens tabbed by default at any width unless `defaultLayout` requests split explicitly (see **accept-initial-layout**), whereas on Apple the platform's own default mode preference is already Split.
- **tabbed-layout-below-threshold**: The component MUST display editor and preview as tabs (one visible at a time) when the viewport width is below the platform's split-view breakpoint (700pt on Apple, 1024px on web).
- **layout-mode-toggle**: The component MUST provide a control allowing the user to switch between the modes available for the current viewport width and preview availability (Split, Edit, Preview).
- **preserve-layout-preference**: The component MUST remember the user's last deliberately chosen layout mode and restore it when the viewport transitions to a wider state that can accommodate the preferred mode (e.g., if the user chooses Preview on a narrow viewport, widening to split-capable width restores Preview rather than defaulting to Split).
- **clamp-mode-to-available-set**: When the viewport narrows (or preview availability turns off) and the currently active layout mode is no longer offered, the component MUST resolve to the user's last deliberately chosen mode if that mode is still in the new available set, and MUST otherwise fall back to Edit mode. (E.g., narrowing from split-capable width while in Split mode, with no prior Preview preference, clamps to Edit; narrowing while the user's last deliberate choice was Preview keeps Preview, since Preview remains available down to the two-mode set.)
- **empty-preview-placeholder**: The component MUST display a placeholder message (e.g., "Nothing to preview yet.") when the preview pane is shown and the editor content is empty or contains only whitespace.
- **suppress-preview-live-region**: The component MUST set `aria-live="off"` on the preview pane's content region, so screen readers do not re-announce the entire rendered document every time the preview updates after the debounce fires.
- **accept-optional-header**: The component MUST accept an optional header element to be rendered above the editor and preview panes, positioned outside both panes (header is a document-level concern, not a view-specific one).
- **accept-optional-overlay**: The component MUST accept an optional overlay element to be rendered inside the editor pane's positioning context (e.g., for a typeahead listbox or drag affordance that must position relative to the textarea).
- **accept-preview-class-name**: The component MUST accept an optional CSS class name to be applied to the preview pane for styling (e.g., to match the editor pane's vertical bulk when the layout is not full-height).
- **accept-theme-id**: The component MUST accept an optional theme identifier to control the reading theme used by the preview pane (passed to the MarkdownReadingPalette; defaults to that palette's own default theme if omitted).
- **accept-subject-label**: The component MUST accept an optional subject string to be used as the accessible name for the layout mode toggle's two toggle groups (defaults to "Editor"; e.g., "Note Editor", "Discussion Editor") to disambiguate when multiple markdown editors appear on the same page.
- **accept-initial-layout**: The component MUST accept an optional initial layout mode to open in on a viewport wide enough to support it; a viewport too narrow to support it always opens tabbed regardless of this setting (web: `defaultLayout`, defaults to tabbed).
- **accept-initial-tab**: When opening in tabbed layout, the component MUST accept an optional initial pane to display (web: `defaultTab`, forwarded to the split-view control's pane selection), defaulting to the editor pane.
- **preview-availability-flag**: The component SHOULD accept an optional flag that disables preview mode entirely, restricting the component to Edit-only mode and hiding preview-related toolbar controls (Apple: `isPreviewAvailable`, defaults to `true`). The Web implementation does not yet expose this control.
- **forward-editor-props**: The component MUST consume `header`, `defaultLayout`, `defaultTab`, `subject`, `overlay`, `previewClassName`, `fill`, and `themeId` itself, and MUST forward every other prop of the underlying markdown editor component — including `value`, `onChange`, `label`, `onUpload`, and `toolbarExtras` — unmodified to the editor pane. `value` is also read internally to drive the debounced preview render, and `fill` is both consumed (to size the panes row) and passed through to the editor pane; neither is filtered out of the forwarded set.
- **fill-by-default**: The component MUST fill its container by default (fill defaults to true), accepting content height from its container; the component SHOULD accept a fill-false option to size the editor by row count instead.
- **touch-target-minimum**: Every layout-mode and tab-toggle button in the toolbar MUST have a touch target of at least 44×44pt on iOS, 48×48dp on Android, or 44×44px on the web.

## Appearance

- **Layout container**: Flex column with gap between header, control strip, and panes row. No horizontal scroll.
- **Panes row**: Flex row with gap between panes. Min-width 0 to enable flex shrinking on overflow. Min-height varies by fill mode.
- **Editor pane**: Flex column, flex-1 to fill available width in split mode. On narrow viewports (tabbed mode), displays conditionally.
- **Preview pane**: Flex column, flex-1 to fill available width in split mode. On narrow viewports (tabbed mode), displays conditionally. Border (1px), rounded corners (md), background color inherited from theme.
- **Split layout**: Editor pane takes 50% width, preview pane takes 50% width, gap between them. Both stretch to fill container height.
- **Tabbed layout**: One pane visible at a time, fills available space.
- **Min-height floor (fill mode)**: When fill is true, the panes row has a minimum height floor of 14rem (224px) so the editor's textarea has enough room to write in. When fill is false, no floor is applied; sizing follows the textarea's row count.

## States

| State | Description |
|-------|-------------|
| Default | Both panes visible (split layout) or editor pane visible (tabbed, default tab). |
| Editor tab active | On narrow viewports: editor pane is visible, preview is hidden. Toolbar shows "Editor" tab as selected. |
| Preview tab active | On narrow viewports: preview pane is visible, editor is hidden. Toolbar shows "Preview" tab as selected. |
| Preview rendering | After content change, debounce timer is active. Preview pane shows stale rendered content (or empty state) until debounce fires. |
| Preview ready | Debounce has fired, preview has been re-rendered with current editor content. |
| Empty content | Editor is empty or contains only whitespace. Preview pane displays placeholder message. |
| Disabled preview | The preview-availability flag is off (Apple: `isPreviewAvailable=false`) or equivalent. Only edit mode is available; preview pane is not shown; toolbar does not offer preview or split options. |
| Focused editor | Editor textarea has focus. |
| Focused overlay | Optional overlay element (e.g., typeahead listbox) has focus; overlay is positioned within the editor pane's context. |

## Accessibility

- **Role**: The component is a container. Panes inside are not exposed as separate roles; the editor pane contains a text input control for markdown source, the preview pane contains rendered content exposed as a document or article (per platform).
- **Label for layout toggle**: The toolbar's two toggle groups (for split/tabbed/preview/editor switches) use the `subject` prop as their accessible name (e.g., `aria-label="Editor layout"`, `aria-label="Note Editor layout"`). Defaults to "Editor" if not specified. This ensures a screen-reader user navigating the rotor can distinguish between multiple editors on the same page.
- **Preview pane live region**: See **suppress-preview-live-region**. The preview pane's content region is explicitly marked `aria-live="off"`, which prevents screen readers from re-announcing the entire rendered document every time the preview updates after the debounce (300ms after each keystroke). Announcements of specific interactive elements within the preview (links, headings, etc.) are handled by assistive technology's document navigation, not live region updates.
- **Empty state placeholder**: The "Nothing to preview yet." placeholder message is screen-reader accessible as regular text content within the preview pane.
- **Keyboard navigation**: The layout toggle buttons and mode toggles in the toolbar are keyboard navigable. Tab order follows the visual layout: toolbar controls precede the panes. The editor textarea is focusable and editable via keyboard. Content in the preview pane is navigable via standard document navigation (headings, links, etc.) if it is a live document view.
- **Focus management**: The component does not programmatically move focus when the user switches layout modes. The previously focused control (e.g., the editor textarea, or an overlay it hosts) keeps focus if it remains visible in the new layout. If it becomes hidden — for example, an overlay tied to the editor pane when a tabbed layout switches to the preview tab — the component does not redirect focus anywhere in particular; focus follows whatever the platform does by default for a focused control that disappears (e.g., falls to the document body on web, or to the next key view on Apple platforms).
- **Overlay positioning context**: An optional overlay (typeahead listbox, etc.) is positioned relative to the editor pane's frame, not the window. Screen readers will announce the overlay's content as it appears; the overlay's own accessibility is the responsibility of the overlay component.
- **Touch target size**: See **touch-target-minimum**.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| markdown-editor-001 | render-editor-pane, render-preview-pane | Mount component with `value=""` | Both editor and preview panes are rendered in the DOM. Editor text input is empty; preview shows the empty-state placeholder. |
| markdown-editor-002 | sync-content-to-preview, debounce-preview-render | Mount component, type "# Hello" into editor | After 300ms, preview pane updates to show rendered `<h1>Hello</h1>` (or platform equivalent). |
| markdown-editor-003 | split-layout-above-threshold | Mount component wide enough to cross the platform's split-view breakpoint — 800pt on Apple (`splitWidthThreshold` is 700pt, and Split is Apple's own default mode), or a viewport of at least 1024px on web (e.g. 1100px), since web's `SPLIT_MIN_WIDTH` media query is `(min-width: 64rem)`, not 700px — with preview available | Editor and preview panes are displayed side-by-side, each taking 50% of the panes row's width. Mounting at 800px on web stays tabbed instead: 800px is below web's 1024px breakpoint, and web's `defaultLayout` is `'tabbed'` regardless of width; see markdown-editor-004. |
| markdown-editor-004 | tabbed-layout-below-threshold | Mount component at 600 units wide with preview available | Editor and preview are shown as tabs. Only one pane is visible at a time. (True on both platforms: 600 is below both the 700pt Apple threshold and the 1024px web threshold.) |
| markdown-editor-005 | layout-mode-toggle | Mount component; locate toolbar | Toolbar displays mode toggle control(s). User can click to switch between available modes. |
| markdown-editor-006 | preserve-layout-preference | Mount in tabbed mode narrower than the platform's split-view breakpoint (e.g. 600 units), user deliberately selects the Preview tab, then widen past the breakpoint — to 800pt on Apple, or to at least 1024px on web (e.g. 1100px) | Because Preview is still offered once wide, the mode resolves to Preview, not Split: the preview pane is shown, the editor pane stays hidden, and the toolbar's mode control shows Preview selected. Widening only to 800px on web does not cross its 1024px breakpoint and so does not exercise this transition at all. |
| markdown-editor-007 | clamp-mode-to-available-set | Mount in Split mode with preview available, wide enough to cross the platform's breakpoint — 800pt on Apple (Split is that platform's own default mode preference), or at least 1024px on web with `defaultLayout="split"` (web's own default is tabbed, so Split must be requested explicitly) — then narrow below the breakpoint (e.g. to 600 units) | Narrowing drops Split from the available set (only Edit and Preview remain). Split was the active/preferred mode and is no longer available, so the component clamps deterministically to Edit. The Split option is unavailable in the toolbar. |
| markdown-editor-008 | empty-preview-placeholder | Mount component with `value=""`, visible in split or preview-only mode | Preview pane displays "Nothing to preview yet." (or its localized equivalent). |
| markdown-editor-009 | suppress-preview-live-region | Mount component; enable screen reader; edit content | After the debounce fires, the screen reader does NOT announce the entire rendered preview document. Only new/changed elements or interactive controls within the preview are navigable via standard document nav (e.g., heading rotor, link list). |
| markdown-editor-010 | accept-optional-header | Mount with `header={<div>Document Title</div>}` | Header element is rendered above the control strip and panes. |
| markdown-editor-011 | accept-optional-overlay | Mount with `overlay={<div>Typeahead</div>}` while editor is focused; overlay is conditionally shown | Overlay is positioned inside the editor pane's positioning context. Overlay is visible only when the editor pane is visible (tabbed mode: overlay disappears when the user switches to the preview tab). |
| markdown-editor-012 | accept-preview-class-name | Mount with `previewClassName="custom-class"` | Preview pane element has the custom class applied in addition to its default classes. |
| markdown-editor-013 | accept-theme-id | Mount with `themeId="dark"` | Preview pane renders with the "dark" reading theme (passed to MarkdownReadingPalette). |
| markdown-editor-014 | accept-subject-label | Mount two instances with `subject="Note Editor"` and `subject="Comment Editor"` | Each instance's toolbar toggle groups have unique accessible names built as `${subject} layout`: "Note Editor layout" and "Comment Editor layout" (screen readers can distinguish them). Default subject is "Editor" if omitted, yielding "Editor layout". |
| markdown-editor-015 | forward-editor-props | Mount with `value="test"`, `onChange={callback}`, `label="Body"` | Props are forwarded to the editor pane. Content is "test"; onChange fires when the user edits; label is applied to the text input. |
| markdown-editor-016 | fill-by-default | Mount with no `fill` prop | Component expands to fill container height (fill defaults to true). The min-height floor is applied. |
| markdown-editor-017 | fill-by-default | Mount with `fill={false}` | Component sizes by textarea row count. No height-based floor is applied. |
| markdown-editor-018 | debounce-preview-render | Mount component, type to start the debounce timer, then unmount the component (or turn off preview availability) before 300ms elapses | The pending render is cancelled. It does not run, and nothing throws once the component is gone. |
| markdown-editor-019 | preview-availability-flag | Mount with the preview-availability flag true and in Preview mode, then set the flag to false | Only Edit mode is available; the layout switches to Edit and the toolbar no longer offers Preview or Split. Setting the flag back to true restores the previous mode preference. |
| markdown-editor-020 | debounce-preview-render | Type 10 characters in quick succession | The debounce timer resets on every keystroke; the preview renders once, 300ms after the last keystroke, not once per character. |
| markdown-editor-021 | skip-redundant-content-update | Set the content prop to the exact string it already holds | No re-render and no debounce restart occurs. |

## Edge Cases

- **Empty or null content**: When the editor content is empty, `null`, or contains only whitespace (spaces, tabs, newlines), the preview pane shows the empty state placeholder and does NOT attempt to render markdown.
- **Rapid keystroke stream**: User types 10 characters in quick succession. Debounce is reset for each keystroke. Preview renders once, 300ms after the user stops typing (not after each character).
- **Debounce cancellation**: User types, debounce timer starts. Before 300ms elapses, the component is unmounted or the preview is disabled. The pending render is cancelled and does not run.
- **Programmatic content updates**: If the host programmatically sets the `value` prop to a new string (not user typing), the debounce timer starts, and preview renders 300ms later (same as keystroke). Per **skip-redundant-content-update**, setting the `value` prop to the same string it already holds does NOT trigger a re-render.
- **Mode change during debounce**: User edits, debounce starts. Before debounce fires, user switches from edit mode to preview mode. Debounce still fires on schedule; preview updates on completion.
- **Viewport resize during layout transition**: Preview re-rendering is driven solely by content changes, not by layout changes. Resizing the viewport (e.g., from split-capable width down to tabbed width) does not itself trigger a preview re-render or reset the debounce timer; only edits to the content do.
- **Preview disabled toggle**: The preview-availability flag changes from `true` to `false`. Only edit mode is available. If the user was viewing preview, the layout switches to edit. Setting the flag back to `true` restores the previous mode preference.
- **Overlay focus while tabbed**: User is in edit mode on a narrow viewport with an overlay (e.g., typeahead) open. User clicks the preview tab. The overlay unmounts along with the editor pane (it belongs to editing and is only rendered while the editor pane is visible). Per **focus-management**, the component does not redirect focus itself; the previously focused control's focus falls to whatever the platform does by default for a focused control that disappears.

## Configuration

Not applicable: this component does not accept configuration options beyond its props (`defaultLayout`, `defaultTab`, `subject`, `overlay`, `previewClassName`, `themeId`, the Apple-only `isPreviewAvailable`, and forwarded editor props). No separate configuration object is needed.

## Deep Linking

Not applicable: this component is a pane within a document editor, not a top-level navigation target. Deep linking is the responsibility of the host application (which may deep link to a document containing this editor).

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `markdown-document-editor.preview.empty` | "Nothing to preview yet." | Shown in the preview pane when the editor content is empty or whitespace-only (**empty-preview-placeholder**). |
| `markdown-document-editor.subject.default` | "Editor" | Default accessible-name subject for the layout toggle groups when `subject` is not provided (**accept-subject-label**). |

Both strings are hardcoded literals in the source today rather than routed through an i18n layer; localizing them means introducing these keys at the call sites above. Beyond these two strings, and any button labels contributed by the composed `MarkdownEditorToolbar` and `MarkdownReadingPalette` (covered by their own recipes), this component renders no other user-facing text of its own.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component has no animated transitions. The 300ms preview debounce is a timing delay before a re-render, not motion, so it is unaffected by this setting. Pane switching (tabbed mode) is an instant, non-animated change. |
| Increase Contrast | Preview pane inherits contrast from MarkdownReadingPalette theme (e.g., "dark" or "high-contrast" theme). Host application may pass a high-contrast themeId prop. |
| Differentiate Without Color | If the layout toggle buttons use color alone to indicate state, add additional visual indicators (e.g., icon, checkmark, underline) to communicate the active mode without relying on color. |

## Feature Flags

Not applicable: this component does not have built-in feature flags. If the host application needs to gate the component's availability or specific features (e.g., preview availability), they should use the preview-availability flag and conditional rendering.

## Analytics

Not applicable: this component does not emit analytics events. The host application is responsible for tracking user interactions (e.g., "user switched to preview mode", "user edited markdown document"). If needed, the host can attach event listeners to the onChange callback and toolbar callbacks.

## Privacy

Not applicable: the component does not collect or transmit any user data beyond passing the markdown content to the preview renderer, which operates locally. No data leaves the device.

## Logging

Not applicable: this component does not perform any logging. Internal state changes (render scheduling, debounce timing, layout changes) are implementation details and not exposed via logging APIs.

## Platform Notes

- **Web (React/TypeScript)**: Implemented in `packages/web/packages/markdown/src/components/MarkdownDocumentEditor.tsx`. Uses React hooks (`useState`, `useEffect`) for state management. Debounce is implemented with a custom `useDebounced` hook — a `useEffect` that starts a `setTimeout` and clears it on cleanup or dependency change, so a fresh keystroke and an unmount both cancel the pending render the same way. Layout state is managed by `useSplitView` from `@adh-sdk/ui/blocks/split-view-control`. `SPLIT_MIN_WIDTH` is exported, but it is the media-query string `(min-width: 64rem)` (1024px at the default root font size), not a 700px value; the component also opens tabbed by default (`defaultLayout = 'tabbed'`) at any width unless a host requests split explicitly. `fill={true}`/`fill={false}` and `className` are this platform's spelling of the platform-neutral **fill-by-default** and pass-through-class requirements above; forward all other props to the underlying `MarkdownEditor` component via spread (`...editor`). This implementation does not yet expose a preview-availability flag (**preview-availability-flag**); a host needing edit-only mode must conditionally render the whole component instead.

- **SwiftUI**: For SwiftUI adoption, start from a view that composes `TextEditor` for markdown input and a markdown renderer view for preview. Track the current layout mode with `@State`, and read the viewport width from a `GeometryReader` (or a container's proposed size). Debounce the 300ms preview render with `.task(id: content) { try? await Task.sleep(for: .milliseconds(300)); ... }` — a new `content` value cancels the previous task automatically under Swift's structured concurrency, so no manual work-item bookkeeping is needed. Model the split-view state (current mode, preferred mode, available modes) as an `@Observable` object so it persists the user's mode preference the same way `MarkdownEditorController.preferredMode` does. Conditionally show editor and preview views based on layout mode and available width.

- **Compose (Android)**: For Compose adoption, start with a `Column` or `Box` composable containing editor and preview regions. Use a `State<String>` for the markdown content and a `State<LayoutMode>` for the current layout. Implement the debounce with `LaunchedEffect(content) { delay(300); ... }`, which Compose automatically cancels and restarts when `content` changes. Read the viewport width from `LocalWindowInfo.current.containerSize` (or a `WindowSizeClass` breakpoint), not the nonexistent `WindowInfo.widthDp`, and compare it against the 700dp threshold. Conditionally render editor and preview composables based on layout mode (split shows both in a `Row`, tabbed shows one in a `Column` with a tab selector).

- **AppKit / UIKit**: Implemented in `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/Shared/Markdown/MarkdownEditorController.swift`. Inherits from `PlatformViewController` (macro that dispatches to `NSViewController` on macOS or `UIViewController` on iOS). Uses `NSTextView` / `UITextView` for markdown input via the `MarkdownTextPane` component. Preview is a child view controller (`MarkdownViewerController`). Layout is driven by `NSLayoutConstraint` (AutoLayout); constraints are rebuilt in `applyPanes()` whenever the layout mode changes. Debounce is implemented with `DispatchQueue.main.asyncAfter` and `DispatchWorkItem` cancellation. Viewport width threshold check is `view.bounds.width >= Self.splitWidthThreshold` (700pt). Preference persistence is via the `preferredMode` private property, resolved through `resolvedMode(for:in:)` on every mode change and every layout pass. Exposes preview availability via the public `isPreviewAvailable` property (**preview-availability-flag**), whose `didSet` recomputes `availableModes` and re-clamps `mode` through that same `resolvedMode` helper.

- **WinUI 3**: For WinUI 3 adoption, build a `UserControl` containing a source-editing surface — a plain `TextBox` for basic markdown entry, or a `WebView2` hosting a JavaScript editor (e.g. CodeMirror or Monaco) if in-pane syntax highlighting is wanted — and a preview pane rendered with a second `WebView2` fed HTML from a .NET markdown-to-HTML converter (e.g. Markdig used purely as a parser, not as the editing surface — it has no text-editing UI of its own). Bind the editor's text to a `Content` property and the preview's HTML to the `WebView2`'s `NavigateToString`. Observe the `ActualWidth` of a `Grid` column via `SizeChanged` to detect the viewport width and switch layout modes against the 700px threshold. Debounce with a `DispatcherTimer` (`Interval` = 300ms; stop and restart it when content changes). Use a `ComboBox` or segmented toggle-button group to switch between layout modes, storing the user's mode preference in a view-model property that survives layout changes, and bind the preview pane's `Visibility` to the current mode.

## Design Decisions

1. **Decision**: Debounce the preview render by 300ms after the last content change.
   **Rationale**: `MarkdownRenderer` re-runs the full unified + Shiki syntax-highlighting pipeline on every content change; running that per keystroke would run the pipeline once per character instead of once per pause. 300ms is roughly eighteen frames at 60fps — long enough that the pipeline doesn't run on every character, short enough that the preview still feels responsive. The editor itself gives the author immediate visual feedback; the preview catches up once they pause or stop typing.
   **Approved**: pending

2. **Decision**: Use a per-platform split-layout breakpoint below which each pane would be too narrow for readable prose — 700pt on Apple, and web's inherited `(min-width: 64rem)` (1024px) `SplitViewControl` breakpoint, rather than a single 700-unit number on both platforms.
   **Rationale**: Below the breakpoint, a split view leaves each pane too narrow for readable prose (roughly 40–50 characters per column at typical font sizes), so tabbed layout is enforced instead of a technically-present-but-unusable split. The web breakpoint is `SplitViewControl`'s own shared threshold rather than a value this component chose independently, so it does not match Apple's 700pt figure.
   **Approved**: pending

3. **Decision**: On a layout change, restore the user's last deliberately chosen mode if it's still available in the new set; otherwise fall back to Edit.
   **Rationale**: This honors user intent — choosing Preview on a narrow viewport and then widening the window keeps Preview active rather than defaulting to Split — while giving one deterministic outcome (Edit) for the case where the preferred mode isn't available. Only an explicit user choice (clicking a toggle) updates the preference; a layout-driven fallback does not, which prevents mode "drift" across resizes. See **clamp-mode-to-available-set** and **preserve-layout-preference**.
   **Approved**: pending

4. **Decision**: Explicitly set `aria-live="off"` on the preview pane's content region.
   **Rationale**: Announcing the entire rendered document every 300ms would create constant, overwhelming screen-reader noise. Screen-reader users instead navigate the preview's content structure (headings, links, etc.) on demand, using standard document navigation techniques.
   **Approved**: pending

5. **Decision**: Render the optional `header` outside both panes, above the control strip.
   **Rationale**: Document identity fields (title, slug, categories, etc.) belong to the document, not to a particular view of its body.
   **Approved**: pending

6. **Decision**: Position the optional `overlay` inside the editor pane's positioning context.
   **Rationale**: This keeps a typeahead listbox or similar affordance positioned against the textarea, hides it automatically when the editor pane is hidden in tabbed mode, and scopes its z-order to the editor so it never overlaps the preview pane in split mode.
   **Approved**: pending

7. **Decision**: Default to fill-mode true, unlike the underlying editor component's own fill-mode-false default.
   **Rationale**: Both layouts (split and tabbed) are designed to fill their container height by construction; a fill-false override exists for hosts that need fixed-height sizing (e.g., the notebook's NoteFields component).
   **Approved**: pending

8. **Decision**: Apply a 14rem (224px) minimum height floor to the panes row in fill mode.
   **Rationale**: Without a floor, a container shorter than the editor's minimum needs would let the panes shrink to zero height, and all content would overflow. 14rem leaves the textarea roughly 10rem after the label and toolbar take their share — a body that's actually usable for writing. In fill-false mode, sizing follows the textarea's row count instead, so no floor is needed.
   **Approved**: pending

9. **Decision**: Guard programmatic content updates against no-op re-renders.
   **Rationale**: Prevents infinite loops when a host echoes the current value back to the component; a change to a genuinely different string still flows through and triggers the debounce as normal. See **skip-redundant-content-update**.
   **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy & Data |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best-practices |

Statuses rest on the source: the preview pane's content region is explicitly `aria-live="off"` (screen-reader-support passed); neither source file contains any code that programmatically moves focus when the layout mode changes (focus-management passed, matching the Accessibility section above); this component's own container adds no ARIA role or landmark of its own, and the rendered-content role comes from the delegated `MarkdownRenderer` / `MarkdownViewerController` (semantic-markup partial); the "Nothing to preview yet." placeholder and the default "Editor" subject are both literal strings in the source with no i18n key or lookup (no-hardcoded-strings and string-externalization failed); markdown content is handed to the delegated renderer/viewer components, and sanitization of the resulting HTML is their responsibility, not verifiable from this source (input-sanitization partial); and the component holds and forwards only the content, theme, and layout props the host already supplies, collecting nothing additional and sending nothing over the network (data-minimization passed). `separation-of-concerns` passes: this component owns only layout-mode state and debounced content sync, delegating rendering to `MarkdownRenderer`/`MarkdownViewerController`, split-view mechanics to `SplitViewControl`/`useSplitView`, and editing to `MarkdownEditor` — each an independently versioned module with no circular dependency back into this one. `unit-test-coverage` passes: `markdownDocumentEditor.test.tsx` (web) and `MarkdownEditorControllerTests.swift` (Apple) each exercise this component/controller directly, beyond the vectors table's minimum. Touch-target sizing and keyboard roving are governed by the composed `SplitViewControl` and `MarkdownEditor`/`MarkdownEditorToolbar` recipes, not re-assessed here. User Safety is omitted because this component neither moderates nor publicly displays content; it hands authored markdown to a renderer it does not own.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web (MarkdownDocumentEditor.tsx) and Apple (MarkdownEditorController.swift) sources. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case, fixed the debounce-timing and aria-live contradictions, resolved the focus-management and mode-clamp contradictions with deterministic rules, added missing requirements for isPreviewAvailable/defaultLayout/defaultTab and a promoted touch-target requirement, reformatted Design Decisions into Decision/Rationale/Approved triples, replaced the Compliance and Localization "Not applicable" placeholders with real tables, corrected inaccurate Compose/WinUI 3/SwiftUI platform guidance, added conformance vectors for debounce cancellation/preview-toggle/rapid-keystroke/no-op-update coverage, and cleaned up stray test-implementation detail and dead edge cases. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed split/tabbed-layout thresholds: web uses SPLIT_MIN_WIDTH media query (1024px), not 700px, and defaults tabbed; vectors 003/004/006/007 and Design Decision 2 corrected; accept-subject-label vector uses ${subject} layout format (subject="Note Editor" not "Note"). |
