---
id: 6e0e27bf-5f7d-46bf-85d0-fb5bdf5dab8a
title: "Split View Control"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A control that toggles between tabbed and split layout views, collapsing to tabbed on narrow viewports."
platforms:
  - typescript
  - web
tags:
  - layout
  - view-switcher
  - responsive
depends-on:
  - dffc1431-7386-4acf-94bc-6043c5c7eebc
related: []
references: []
approved-by: ""
approved-date: ""
---

# Split View Control

## Overview

The Split View Control is a pair of toggle groups that manages layout preference (tabbed vs. split) and pane selection (edit vs. preview) in responsive interfaces. On wide viewports (64rem minimum), users can choose between a split layout (two panes side by side) or a tabbed layout (one pane at a time). On narrow viewports, only the tabbed layout is available, though the user's split preference is remembered and restored when the viewport widens. The control is rendered left-aligned below the surface's header rather than within it, as it belongs to the body content it controls.

## Behavioral Requirements

- **layout-toggle-visible-on-wide-viewport**: On viewports ≥ 64rem, the control MUST render a layout toggle group with two options: tabbed (single pane) and split (side by side).
- **layout-toggle-hidden-on-narrow-viewport**: On viewports < 64rem, the control MUST NOT render the layout toggle group.
- **separator-between-toggles-in-tabbed-mode**: When the layout toggle is rendered AND the effective layout is tabbed, the control MUST render a vertical separator (1px, `bg-apt-border` color) between the layout toggle and the pane toggle; it MUST NOT render the separator when the effective layout is split.
- **pane-toggle-visible-only-in-tabbed-layout**: The pane toggle group (edit/preview) MUST render when the effective layout is tabbed and MUST NOT render when the effective layout is split (both panes are already visible).
- **layout-preference-persists-across-viewport-changes**: The user's layout preference MUST be retained when the viewport narrows below 64rem and restored when widening above 64rem.
- **effective-layout-demoted-on-narrow-viewport**: On narrow viewports, the effective layout MUST be "tabbed" regardless of the stored layout preference.
- **edit-label-customizable**: The edit toggle label MUST be customizable via the `editLabel` prop, defaulting to "Edit".
- **preview-label-customizable**: The preview toggle label MUST be customizable via the `previewLabel` prop, defaulting to "Preview".
- **flex-row-layout**: The control MUST render as a flex row with items center-aligned and 0.75rem (gap-3) spacing between children.
- **empty-toggle-selection-ignored**: When a user clicks a toggle group item that is already selected, the toggle group hands back an empty array; the control MUST ignore this event and retain the current selection.
- **layout-toggle-group-aria-label**: The layout toggle group MUST have an `aria-label` that reads `"${subject} layout"` where `subject` is the component-provided context string.
- **pane-toggle-group-aria-label**: The pane toggle group MUST have an `aria-label` that reads `"${subject} pane"`.
- **pane-toggle-aria-controls-container**: Each pane toggle item MUST have an `aria-controls` attribute pointing to the ID (`panesId`) of the pane container element (placed on the container, not on individual hidden panes).
- **layout-toggle-item-accessible-names**: The layout toggle items MUST have matching `title` and `aria-label` values: "Single tabbed view" for the tabbed item, "Side by side view" for the split item.
- **tabbed-icon-is-square**: The tabbed layout toggle MUST display a Square icon.
- **split-icon-is-columns2**: The split layout toggle MUST display a Columns2 icon.
- **edit-icon-is-pencil**: The edit pane toggle MUST display a Pencil icon before its label.
- **preview-icon-is-eye**: The preview pane toggle MUST display an Eye icon before its label.

## Appearance

- **Layout**: Flex row, `items-center` (vertical center alignment), `gap-3` (0.75rem spacing)
- **Toggle groups**: Uses shared ToggleGroup component for both layout and pane toggles
- **Separator**: 1px width, `bg-apt-border` color, height 1.25rem (h-5), only rendered in tabbed mode when layout toggle is visible
- **Icons**: Lucide React icons (Square, Columns2, Pencil, Eye)
- **Responsive**: Layout toggle visibility changes with viewport width (hidden below 64rem); within a wide viewport, the pane toggle and the separator between it and the layout toggle appear only in tabbed mode and disappear in split mode
- **Custom className**: The component MUST accept an optional `className` prop and merge it with the base flex layout using `cn()` utility

## States

| State | Appearance change |
|-------|------------------|
| Wide viewport | Layout toggle and pane toggle both visible if effective layout is tabbed; separator visible between them |
| Narrow viewport | Layout toggle hidden; pane toggle visible (effective layout forced to tabbed) |
| Split layout (wide viewport) | Layout toggle visible; pane toggle hidden (no selection needed when both panes are visible) |
| Tabbed layout (wide viewport) | Layout toggle visible; pane toggle visible; separator visible between them |
| Toggle pressed | The pressed toggle item is visually highlighted by the ToggleGroup component; clicking an already-pressed item is ignored |

## Accessibility

- **Roles**: Each toggle group is a segmented control / buttonset; individual items are toggle buttons
- **Label requirements**: Layout toggle has `aria-label="${subject} layout"`; pane toggle has `aria-label="${subject} pane"`; individual toggle items have `aria-label` and `title` attributes
- **Pane control association**: Pane toggle items have `aria-controls="${panesId}"` pointing to the container element wrapping the two panes (not placed on individual hidden panes)
- **Announce visibility**: The layout toggle is not rendered on narrow viewports, so the control renders a smaller footprint — no aria-hidden needed for the unrendered toggle
- **Title attributes**: Both layout toggle items have `title` attributes for mouse hover: "Single tabbed view" and "Side by side view"
- **Hidden separator**: When the separator is not rendered, it is not in the DOM; no `aria-hidden` needed
- **Minimum touch/click target**: Handled by the ToggleGroup and ToggleGroupItem components; SplitViewControl assumes the underlying component meets the WCAG minimum target size (44×44px) — this is a web component, so iOS and Android platform minimums do not apply

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| split-view-001 | layout-toggle-visible-on-wide-viewport | Wide viewport (≥64rem) | Layout toggle group renders with tabbed and split options |
| split-view-002 | layout-toggle-hidden-on-narrow-viewport | Narrow viewport (<64rem) | Layout toggle group does not render |
| split-view-003 | separator-between-toggles-in-tabbed-mode | Wide viewport, effective layout tabbed | Vertical separator (1px, bg-apt-border) renders between layout and pane toggles |
| split-view-004 | separator-between-toggles-in-tabbed-mode | Wide viewport, effective layout split | Separator does not render |
| split-view-005 | pane-toggle-visible-only-in-tabbed-layout | Effective layout tabbed | Pane toggle group renders with edit and preview options |
| split-view-006 | pane-toggle-visible-only-in-tabbed-layout | Effective layout split | Pane toggle group does not render |
| split-view-007 | layout-preference-persists-across-viewport-changes | User selects split layout on wide viewport, then resize to narrow (<64rem), then resize back to wide (≥64rem) | Layout preference is "split" before narrow, remains "split" during narrow (though effective is "tabbed"), and effective becomes "split" again when widening |
| split-view-008 | effective-layout-demoted-on-narrow-viewport | Viewport narrower than 64rem, layout preference is "split" | Effective layout is "tabbed" |
| split-view-009 | edit-label-customizable | Render with `editLabel="Author"` | Edit toggle label reads "Author" instead of default "Edit" |
| split-view-010 | preview-label-customizable | Render with `previewLabel="Published"` | Preview toggle label reads "Published" instead of default "Preview" |
| split-view-011 | flex-row-layout | Render control in any state | Control renders as a flex row (`flex items-center gap-3`) with center vertical alignment and exactly 0.75rem (`gap-3`) horizontal spacing between children |
| split-view-012 | empty-toggle-selection-ignored | Layout toggle shows "split" selected; user clicks the "split" button again | Selection remains "split", no state change triggered |
| split-view-013 | layout-toggle-group-aria-label | Render with `subject="Editor"` | Layout toggle group has `aria-label="Editor layout"` |
| split-view-014 | pane-toggle-group-aria-label | Render with `subject="Document"` | Pane toggle group has `aria-label="Document pane"` |
| split-view-015 | pane-toggle-aria-controls-container | Render control | Each pane toggle item has `aria-controls` attribute matching the `panesId` from the view state |
| split-view-016 | layout-toggle-item-accessible-names | Render layout toggle on wide viewport | Tabbed toggle has `title="Single tabbed view"` and `aria-label="Single tabbed view"`; split toggle has `title="Side by side view"` and `aria-label="Side by side view"` |
| split-view-017 | tabbed-icon-is-square | Render layout toggle on wide viewport | Tabbed toggle item renders with Square icon |
| split-view-018 | split-icon-is-columns2 | Render layout toggle on wide viewport | Split toggle item renders with Columns2 icon |
| split-view-019 | edit-icon-is-pencil | Render pane toggle in tabbed mode | Edit toggle item renders with Pencil icon before label |
| split-view-020 | preview-icon-is-eye | Render pane toggle in tabbed mode | Preview toggle item renders with Eye icon before label |
| split-view-021 | layout-toggle-visible-on-wide-viewport | Viewport exactly 64rem (the `min-width: 64rem` boundary) | Layout toggle group renders (the ≥ threshold includes the boundary) |

## Edge Cases

- **Empty `subject` string**: `subject` is a required `string` prop; the component does not validate it at runtime. If a caller passes an empty string, `aria-label` values become malformed (e.g., `" layout"`) — a broken accessibility output, not a supported input. The host MUST provide a non-empty `subject`.
- **Undefined or null `subject`**: `subject` is typed as a required `string`; passing `undefined` or `null` past that typing produces `"undefined layout"` or `"null layout"` via string concatenation. The component performs no runtime guard against this. The host MUST provide a string value.
- **Viewport at exactly 64rem**: The media query uses `min-width: 64rem`, so a viewport exactly 64rem wide MUST render the layout toggle (see **layout-toggle-visible-on-wide-viewport**, split-view-021).
- **Viewport narrowing mid-selection**: If the user selects "split" layout, then the viewport narrows below 64rem, the layout preference remains "split", but effective becomes "tabbed" and both toggles behave as if the user were in tabbed mode. Widening restores the split.
- **Rapid toggle clicks**: The component uses `onValueChange` from ToggleGroup; if the user clicks toggles rapidly, the state updates follow the ToggleGroup behavior (empty array from re-clicking is ignored, so the selection is sticky).
- **Missing `panesId`**: `view.panesId` is generated by `useSplitView()` via `useId()` and is always a non-empty string when that hook is used. If a caller constructs a `SplitView` object with an empty `panesId` outside the hook, `aria-controls` values become invalid; the component performs no runtime guard against this. The host MUST use `useSplitView()` (or otherwise supply a valid, non-empty ID).
- **Custom className conflicts**: If the custom `className` includes conflicting Tailwind classes (e.g., `gap-2` when the base is `gap-3`), the specificity and order of classes in the `cn()` call determines the outcome. The behavior follows Tailwind's CSS precedence rules.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `view` | SplitView object | required | State object from `useSplitView()` hook, containing layout, pane, effective, wide, showEditor, showPreview, and panesId |
| `subject` | string | required | Context string describing what is being switched (e.g., "Editor", "Document"), used in aria-labels |
| `editLabel` | string | "Edit" | Label text for the edit toggle item |
| `previewLabel` | string | "Preview" | Label text for the preview toggle item |
| `className` | string | undefined | Optional CSS class name(s) to merge with base flex layout |

## Deep Linking

Not applicable: This component is a control that manages view state within a larger page. It does not itself navigate or respond to deep links; the host page that contains this control responds to deep links and uses the SplitViewControl to switch views.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `editLabel` prop | "Edit" | Label for the edit pane toggle item; passed as a prop, not a key |
| `previewLabel` prop | "Preview" | Label for the preview pane toggle item; passed as a prop, not a key |
| `layout toggle (tabbed)` | "Single tabbed view" | Title and aria-label for the tabbed layout toggle item (hardcoded) |
| `layout toggle (split)` | "Side by side view" | Title and aria-label for the split layout toggle item (hardcoded) |

## Accessibility Options

Not applicable: This component is a control that displays or hides based on viewport width (media query) and responds to user toggles. It does not implement accessibility display options like Reduce Motion, Increase Contrast, or Differentiate Without Color. Those concerns are owned by the ToggleGroup component and the surface that hosts SplitViewControl; if the ToggleGroup responds to these options, SplitViewControl inherits that behavior.

## Feature Flags

Not applicable: This component is not wrapped in or controlled by a feature flag. The host surface that renders this control may gate it behind a feature flag if desired.

## Analytics

Not applicable: This component does not emit analytics events directly. Event tracking is the responsibility of the host surface that manages the `useSplitView` hook and calls `setLayout` and `setPane`. If the host wants to track layout or pane changes, it wraps those setters with analytics calls.

## Privacy

Not applicable: This component does not collect, store, transmit, or retain any user data beyond the ephemeral state object (layout preference and pane selection) passed to it. Those values are primitives and are not sensitive.

## Logging

Not applicable: This component does not emit log messages or diagnostic output. All state transitions are synchronous and handled by the host.

## Platform Notes

- **React/Web**: `SplitViewControl` itself is a presentational component: it takes `view` (the `SplitView` object) and `subject` as props and calls no hooks of its own beyond destructuring. Viewport detection, layout/pane state, and the wide→tabbed demotion all live in the `useSplitView()` hook (in the same file), which calls `useMediaQuery('(min-width: 64rem)')`, `useState`, and `useId`. Both ToggleGroup components expect a `value` array and call `onValueChange` with an array; the component filters empty arrays to implement sticky selection. The separator is a styled div with `h-5 w-px bg-apt-border`. Lucide React supplies the icons.
- **SwiftUI**: Detect the wide breakpoint with a `GeometryReader` measuring the container width against 1024pt (the point equivalent of 64rem) rather than `@Environment(\.horizontalSizeClass)` alone, since a size class does not correspond to a fixed width. State would be held in a view model or parent view using `@State` for layout and pane selection. The control would conditionally render the layout `Picker` and separator based on the measured width. Icons would come from SF Symbols.
- **Compose**: An Android equivalent would use `BoxWithConstraints` or `currentWindowAdaptiveInfo()` to detect viewport width (64rem ≈ 1024dp for baseline density). State would be in a ViewModel using `mutableStateOf`. Both toggle groups would be rendered as Compose segmented controls or custom radio button rows. Lucide icons would need Android equivalents from Material icons or a custom icon library.
- **AppKit / UIKit**: Detect the wide breakpoint with a `GeometryReader` (SwiftUI) or a `ViewThatFits`/size-aware layout that measures the actual view width against 1024pt (the point equivalent of 64rem), rather than `NSApplication.shared.keyWindow?.frame.width` (a fragile global lookup that breaks when the control is not in the key window) or `horizontalSizeClass` alone (an iPad in Split View or a large iPhone in landscape can report a size class that does not match the 1024pt threshold). State would be managed via a coordinator or reactive binding (Combine, SwiftUI, or property observers). The control would render segmented controls or button groups. On iOS, a narrow viewport would hide the layout toggle. The design language follows Apple's segmented picker conventions.
- **WinUI 3**: `Window.Current.Bounds` is unsupported (null) in WinUI 3 desktop apps; detect the wide breakpoint with an `AdaptiveTrigger` in the page's `VisualStateManager`, comparing `XamlRoot.Size.Width` against ~1024px, rather than reading window bounds directly. State would be in a ViewModel using `INotifyPropertyChanged`. Render each toggle group as a WinUI 3 `SegmentedControl` — or as `RadioButtons` arranged horizontally if targeting a WinUI 3 version without `SegmentedControl`. The layout toggle would be hidden on narrow viewports via the same `AdaptiveTrigger`, setting `Visibility.Collapsed`. Icons would come from the Segoe MDL2 Assets font or a custom icon resource. The vertical separator would be a `Border` or `Line` control with `BorderThickness="1,0,0,0"` and `BorderBrush` set to a border token.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/split-view-control.tsx` | unverified |

## Design Decisions

**Decision**: Separate the user's layout preference from the effective layout shown on screen.
**Rationale**: This allows the user's choice to be remembered and restored when the viewport widens, rather than silently demoting to a one-pane experience and losing the choice. This design reduces cognitive friction: the user doesn't have to re-select split after rotating their device or resizing their window.
**Approved**: pending

**Decision**: Ignore the empty array the underlying ToggleGroup emits when a user clicks an already-selected toggle item, by checking `if (picked)` before updating state.
**Rationale**: This implements a segmented control pattern where selection is always maintained, rather than a toggle pattern where clicking twice returns to a deselected state.
**Approved**: pending

**Decision**: Do not render the layout toggle at all on narrow viewports (using a conditional `{wide &&}`), rather than rendering it and disabling it.
**Rationale**: This follows the principle that an affordance you can see but never use (a disabled button) is worse than no affordance at all. Users on small screens see a smaller, simpler control.
**Approved**: pending

**Decision**: Render the separator only when both the layout toggle (wide viewport) and pane toggle (tabbed mode) are visible.
**Rationale**: This visually groups the two controls. In split mode, no pane toggle is needed, so no separator appears.
**Approved**: pending

**Decision**: Point each pane toggle item's `aria-controls` at the container element that wraps both panes, not at the individual pane elements.
**Rationale**: In tabbed mode, only one pane is mounted at a time; an `aria-controls` reference to the hidden pane would be a dangling reference (ignored by assistive technology). Pointing to the container keeps the relationship always valid.
**Approved**: pending

**Decision**: Require a `subject` parameter so that accessible names are context-specific (e.g., "Editor layout" vs. "Document layout").
**Rationale**: This avoids generic, unhelpful labels when multiple SplitViewControls appear on the same page. The host must provide this context.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `split-view-control.tsx`: `aria-label`, `aria-controls`, and the toggle-group/button roles are set explicitly in the source (screen-reader-support, semantic-markup passed); keyboard handling, dynamic-type scaling, color contrast, and touch-target sizing are all delegated to the `ToggleGroup` component and are not implemented in this file, so they cannot be verified here (partial); `editLabel`/`previewLabel` are externalized as props but the layout-toggle `title`/`aria-label` strings ("Single tabbed view", "Side by side view") are hardcoded, so `no-hardcoded-strings` fails and `string-externalization` is only partial; the state (`useSplitView`) lives apart from the rendering component, which is presentation over the hook's output (separation-of-concerns passed), and `splitViewControl.test.tsx` exercises both the hook and the component directly across narrow and wide layouts (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | (generated) | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and merged the redundant separator and pane-toggle render/hide pairs; reformatted Design Decisions into Decision/Rationale/Approved triples; rebuilt the Compliance table against real accessibility and internationalization checks instead of unlinked recipe-quality checks; fixed the wide/narrow breakpoint wording to ≥/< 64rem and added an exactly-64rem test vector; corrected Platform Notes for React/Web (hooks live in `useSplitView`, not the control), WinUI 3 (`Window.Current.Bounds` replaced with `AdaptiveTrigger`/`XamlRoot.Size` and named `SegmentedControl`/`RadioButtons`), SwiftUI and AppKit/UIKit (measured-width threshold instead of `horizontalSizeClass`/`keyWindow` lookups); corrected the Appearance section's "no visual changes" claim; dropped the "defined behavior" framing from the empty/undefined `subject` and missing `panesId` edge cases; trimmed the Accessibility touch-target note to the WCAG web minimum; deleted the speculative "if somehow" ToggleGroup edge case; added `depends-on` for ToggleGroup |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
