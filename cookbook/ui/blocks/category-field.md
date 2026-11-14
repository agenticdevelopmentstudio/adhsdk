---
id: 1be6e1bd-ee8c-4247-9020-c0d84356eb10
title: "CategoryField"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Form row for selecting one category from a hierarchy, with rename via modal from breadcrumb display."
platforms:
  - typescript
  - web
tags:
  - form-control
  - category-selection
  - tree-navigation
depends-on:
  - 0c199036-81c3-47c3-9e79-e4b8187ca69a
  - 43c55f5e-d9b3-430b-9026-d0af510fda15
  - 79f7ed30-3193-49bc-856b-d7dd01303baa
  - 526da033-2f0d-4bd7-b2c2-99faba4783a3
related:
  - a3645ff4-19c2-4b30-a828-93a56191f656
references: []
approved-by: ""
approved-date: ""
---

# CategoryField

## Overview

CategoryField is a form row component for selecting a single category from a hierarchy maintained by the owner. It combines autocomplete search (flat names) with a hierarchical browser, and displays the selected value as one or more breadcrumbs showing all filing paths when the category exists in multiple places in the hierarchy (DAG support). When a hierarchy is provided, breadcrumbs are interactive: clicking a breadcrumb crumb opens a modal to rename that category node in-place. The component adapts its terminology to the host's domain via the `noun` prop (e.g., "category", "topic", "tag class").

## Behavioral Requirements

- **render-combobox**: Component MUST render an autocomplete combobox input that accepts free-form text matching against the `options` list.
- **render-browser-button**: Component MUST render a "Choose…" button that opens an entity browser dialog to browse and create options.
- **update-value-on-combobox-change**: Component MUST call `onChange` with the new value when the combobox selection changes.
- **update-value-on-browser-select**: Component MUST call `onChange` with the new value when the entity browser dialog selects an option.
- **accept-value-not-in-options**: Component MUST allow `value` to hold a name not present in the `options` list (e.g., newly created or added by another surface), without requiring a pre-defined option.
- **display-breadcrumbs-when-nodes-provided**: Component MUST display one or more breadcrumb trails showing the filing path(s) of the selected value when a `nodes` hierarchy is provided and `value` resolves to a node.
- **show-all-filing-paths**: Component MUST display one breadcrumb trail per distinct filing path when a category node has multiple parents (DAG structure), up to a maximum of 4 trails (`MAX_TRAILS`), allowing the user to see the category's filing locations without an unbounded walk of a DAG's exponentially many paths. A 5th or later distinct filing path is silently not displayed.
- **path-count-aria-label**: Component MUST use `aria-label="<label> paths"` (plural) when multiple breadcrumb trails are displayed, and `aria-label="<label> path"` (singular) when one trail is displayed.
- **chevron-separators**: Component MUST display a 12px ChevronRight icon between each pair of adjacent breadcrumbs in a trail, with no chevron before the first breadcrumb, to visually separate hierarchy levels.
- **leaf-breadcrumb-accent**: Component MUST render the final breadcrumb in each trail in the leaf-accent color to distinguish the selected node from its ancestors.
- **ancestor-breadcrumb-muted**: Component MUST render non-leaf breadcrumbs in a muted color to de-emphasize ancestors.
- **breadcrumb-truncation**: Component MUST truncate breadcrumb text to prevent overflow on narrow viewports.
- **rename-button-when-onrename-provided**: Component MUST render each breadcrumb as a clickable button when `onRename` is provided and the component is not disabled.
- **static-breadcrumb-without-onrename**: Component MUST render breadcrumbs as static text spans when `onRename` is not provided.
- **static-breadcrumb-when-disabled**: Component MUST render breadcrumbs as static text spans when `disabled={true}`, regardless of whether `onRename` is provided.
- **rename-button-label**: Component MUST set the rename button's `aria-label` to `"Rename <noun> <node.name>"` to announce the category name and action.
- **open-rename-dialog-on-crumb-click**: Component MUST open the CategoryRenameDialog modal when a breadcrumb button is clicked.
- **rename-dialog-receives-node**: Component MUST pass the clicked node, full `nodes` tree, `options` (as the dialog's `extraNames`, so the dialog's duplicate-name guard also rejects a name known to autocomplete but not yet in `nodes`), `noun`, and `onRename` callback to the CategoryRenameDialog. It does not pass `value`.
- **close-rename-dialog-on-confirm-or-cancel**: Component MUST close the CategoryRenameDialog when the user confirms or cancels the rename action.
- **rename-follows-selected**: Component MUST call `onChange` with the new name when a rename succeeds and the renamed node is the currently selected node (`selected.id === renamed.id`), ensuring the field's value follows the node's new name.
- **rename-ignores-unselected**: Component MUST NOT call `onChange` if the renamed node is not the currently selected node.
- **disabled-state**: Component MUST disable both combobox and entity chooser when `disabled={true}`, and MUST NOT allow rename button interaction when disabled.
- **layout-prop**: Component MUST forward the `layout` prop ("stacked" or "inline") to the Field wrapper to control label positioning.
- **classname-prop**: Component MUST apply the `className` prop to the Field wrapper for custom styling.
- **hint-prop**: Component MUST render optional `hint` content passed to the Field wrapper.
- **hide-breadcrumbs-without-trail**: Component MUST NOT render any breadcrumb trail when `value === ""`, or when the `nodes` tree is omitted or empty.
- **combobox-placeholder**: Component MUST set the combobox placeholder to `"Type a <noun>…"` using the `noun` prop.
- **browser-trigger-label**: Component MUST set the entity chooser's trigger button label to `"Choose…"`.
- **browser-input-label**: Component MUST set the entity chooser's input label to `"Filter or add a <noun>"` and placeholder to `"Filter or add a <noun>…"` using the `noun` prop.
- **browser-aria-label-from-label**: Component MUST set the entity chooser's `ariaLabel` to `"Browse <label.toLowerCase()>"`, built from `label` (not `noun`), to indicate the browsing action.

## Appearance

- **Container**: Vertical flex layout (`flex-col`) with 0.5rem gap (`gap-2`) between combobox/chooser row and breadcrumbs.
- **Breadcrumb row**: Horizontal flex layout, wrappable with `flex-wrap`, `items-center`, 0.25rem horizontal gap (`gap-x-1`), 0.125rem vertical gap (`gap-y-0.5`).
- **List items**: Flex row with 0.25rem gap (`gap-1`), `items-center`, `min-w-0` to allow truncation.
- **Chevrons**: 12px size, `shrink-0` (no flex), `text-apt-text-dim` color.
- **Breadcrumb text**: Font monospace, 12px size (`text-xs`), 2% letter spacing (`tracking-[0.02em]`), truncated.
- **Parent breadcrumbs**: `text-apt-text-muted` color.
- **Leaf breadcrumbs**: `text-apt-gold` color.
- **Rename button**: Rounded (`rounded`), monospace font, 12px, 2% letter spacing, no outline, hover brightens to `text-apt-text`, focus shows 2px ring of `apt-gold` at 40% opacity.
- **Input row**: Horizontal flex, `items-stretch`, 0.5rem gap.
- **Combobox wrapper**: `flex-1` to expand.
- **Entity chooser**: `w-44 shrink-0` (fixed width, no flex shrinking).
- **Field wrapper**: Passes through `layout` prop ("stacked" or "inline") for label positioning.

## States

| State | Appearance change | When |
|-------|------------------|------|
| Default | Combobox and chooser inputs are editable, breadcrumbs (if any) are static or interactive buttons. | Initial state when `disabled={false}` and no value or hierarchy conditions inhibit interactivity. |
| Disabled | Combobox and chooser are disabled (grayed out, non-interactive), breadcrumbs render as static text spans. | When `disabled={true}`. |
| No value | Breadcrumb section is hidden; combobox and chooser remain visible and interactive. | When `value === ""`. |
| No hierarchy | Breadcrumb section is hidden even if `value` is set; combobox and chooser are visible. | When `nodes` is omitted or empty. |
| Renaming | CategoryRenameDialog modal is open and centered over the component; combobox and chooser remain visible but input is not focused. | When user clicks a breadcrumb button and `onRename` is defined. |
| Rename success | Dialog closes; breadcrumbs update if the renamed node was selected, and `value` follows the new name via `onChange` (see **rename-follows-selected**). | After the `onRename` callback resolves successfully. |
| Rename error | Dialog behavior on a rejected rename is CategoryRenameDialog's own — see [adhsdk.ingredient.ui.blocks.category-rename-dialog](cookbook:526da033-2f0d-4bd7-b2c2-99faba4783a3). CategoryField's `value` does not change. | When `onRename` callback rejects or throws. |
| Multi-path | Multiple breadcrumb trails are displayed vertically. | When the selected category node has multiple parents in the hierarchy. |

## Accessibility

- **Role**: The breadcrumb section is a navigation landmark (`<nav>` element) with `aria-label` to describe the number and type of paths.
- **Breadcrumb list**: Each trail is a `<ol>` (ordered list) to convey hierarchy structure.
- **Rename button**: Type `button`, has `aria-label="Rename <noun> <node.name>"` to announce the action and the node being renamed.
- **Focus visible**: Rename buttons show `focus-visible:ring-2 focus-visible:ring-apt-gold/40` to provide a visible focus indicator.
- **Chevron separator**: Marked `aria-hidden` because it is decorative and not essential to understanding the structure.
- **Combobox**: Receives `ariaLabel={label}` from the Field's label to identify the control purpose.
- **Entity chooser**: Receives `ariaLabel="Browse <label.toLowerCase()>"` to announce the browsing intent.
- **Semantic structure**: Breadcrumbs use list structure (`<ol>`, `<li>`) to convey hierarchy; this is announced by assistive technology.
- **Label association**: The component is wrapped in a Field that associates the label with the input via `htmlFor` or an external label pattern.
- **Minimum tap target**: The breadcrumb rename buttons are inline text elements (`text-xs`, sized by their content) rather than a discrete tap target of their own; as inline text links they are exempt from the 44×44pt guideline. The Combobox and EntityChooser inputs meet their own minimums independently.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| category-field-001 | render-combobox | Render with default props. | Combobox input is visible and accepts text input. |
| category-field-002 | render-browser-button | Render with default props. | "Choose…" button is visible and clickable. |
| category-field-003 | update-value-on-combobox-change | Type "test" in the combobox and confirm a selection matching an item in `options`. | `onChange` is called once with "test". |
| category-field-004 | update-value-on-browser-select | Click "Choose…", select an option in the entity chooser, confirm the selection. | `onChange` is called once with the selected option's name. |
| category-field-005 | accept-value-not-in-options | Render with `value="custom-name"` where "custom-name" is not in `options` list. | Component displays "custom-name" in combobox without error; breadcrumbs show it if `nodes` includes it. |
| category-field-006 | display-breadcrumbs-when-nodes-provided | Render with `value="leaf"`, `nodes` containing a tree with "leaf" at the end of a trail. | One breadcrumb trail is displayed with ancestors leading to "leaf". |
| category-field-007 | show-all-filing-paths | Render with `value="shared"` where "shared" node has two parents in `nodes`. | Two breadcrumb trails are displayed, each showing a different path to "shared". |
| category-field-008 | path-count-aria-label | Render with one trail; then render with two trails. | `aria-label="<label> path"` (singular) for one trail; `aria-label="<label> paths"` (plural) for two or more trails. |
| category-field-009 | chevron-separators | Render breadcrumb trail with three nodes. | Two ChevronRight icons (12px) are visible between the three breadcrumbs; none appears before the first. |
| category-field-010 | leaf-breadcrumb-accent | Render breadcrumb trail with ancestor and leaf. | Leaf breadcrumb renders in the leaf-accent color token (`text-apt-gold`). |
| category-field-011 | ancestor-breadcrumb-muted | Render breadcrumb trail with three nodes. | First two (ancestor) breadcrumbs render in the muted color token (`text-apt-text-muted`); the third (leaf) renders in the leaf-accent token. |
| category-field-012 | breadcrumb-truncation | Render breadcrumb with very long node name in narrow container. | Text is truncated with ellipsis; no overflow occurs. |
| category-field-013 | rename-button-when-onrename-provided | Render with `onRename` callback and `disabled={false}`. | Each breadcrumb is a `<button>` element. |
| category-field-014 | static-breadcrumb-without-onrename | Render without `onRename` callback. | Breadcrumbs are `<span>` elements, not buttons. |
| category-field-015 | static-breadcrumb-when-disabled | Render with `onRename` callback but `disabled={true}`. | Breadcrumbs are `<span>` elements, not buttons. |
| category-field-016 | rename-button-label | Render breadcrumb button with `noun="category"` and `node.name="taxonomy"`. | Button's `aria-label` is "Rename category taxonomy". |
| category-field-017 | open-rename-dialog-on-crumb-click | Render with `onRename` callback; click a breadcrumb button. | CategoryRenameDialog opens with `open={true}`. |
| category-field-018 | rename-dialog-receives-node | Click a breadcrumb to open rename dialog. | Dialog receives the clicked node via `node` prop, the `nodes` tree, and `options` via `extraNames`; no `value` prop is passed. |
| category-field-019 | close-rename-dialog-on-confirm-or-cancel | Rename dialog is open; user confirms or cancels. | Dialog closes (`renaming` state becomes `null`). |
| category-field-020 | rename-follows-selected | Selected node is renamed from "old" to "new"; confirm rename. | `onChange("new")` is called. |
| category-field-021 | rename-ignores-unselected | Rename a node that is not the currently selected node; confirm. | `onChange` is NOT called; component's value remains unchanged. |
| category-field-022 | disabled-state | Render with `disabled={true}`. | Both combobox and chooser have `disabled={true}` attribute; breadcrumbs are static text, rename buttons are inactive. |
| category-field-023 | layout-prop | Render with `layout="inline"`. | The Field wrapper receives `layout="inline"` and renders its label beside the control instead of above it. |
| category-field-024 | classname-prop | Render with `className="custom-class"`. | The Field wrapper's root element includes `custom-class` in its class list. |
| category-field-025 | hint-prop | Render with `hint="Select a category from the list"`. | The Field wrapper renders "Select a category from the list" below the label. |
| category-field-026 | hide-breadcrumbs-without-trail | Render with `value=""` and `nodes` provided. | Breadcrumb `<nav>` section is not rendered. |
| category-field-027 | hide-breadcrumbs-without-trail | Render with `value="something"` but no `nodes` prop. | Breadcrumb `<nav>` section is not rendered. |
| category-field-028 | combobox-placeholder | Render with `noun="topic"`. | Combobox placeholder is "Type a topic…". |
| category-field-029 | browser-trigger-label | Render with default props. | Entity chooser trigger button label is "Choose…". |
| category-field-030 | browser-input-label | Render with `noun="skill"`. | Entity chooser input label is "Filter or add a skill"; placeholder is "Filter or add a skill…". |
| category-field-031 | browser-aria-label-from-label | Render with `label="Skills"`. | Entity chooser `ariaLabel` is "Browse skills". |
| category-field-032 | hide-breadcrumbs-without-trail | Render with `value="missing"` where no node in `nodes` has that name. | `nodeForName` resolves to `null`; breadcrumb `<nav>` section is not rendered; combobox and chooser remain interactive. |
| category-field-033 | rename-follows-selected | Click a breadcrumb to open the rename dialog; submit a name for which `onRename` rejects. | `onChange` is NOT called and `value`/breadcrumbs are unchanged; the dialog's own error handling is CategoryRenameDialog's — see [adhsdk.ingredient.ui.blocks.category-rename-dialog](cookbook:526da033-2f0d-4bd7-b2c2-99faba4783a3). |
| category-field-034 | disabled-state | Open the rename dialog via a breadcrumb click, then re-render CategoryField with `disabled={true}`. | The dialog remains open; the source does not close it or otherwise alter it on this transition — CategoryField's `renaming` state is independent of `disabled`. |
| category-field-035 | show-all-filing-paths | Render with `value="shared"` where "shared" has 5 parents in `nodes` (5 distinct filing paths). | Only 4 breadcrumb trails are displayed (`MAX_TRAILS`); the 5th filing path is not rendered. |

## Edge Cases

- **Empty `value` with `nodes` provided**: When `value === ""`, breadcrumbs do not render because `nodeForName` returns `null` and `categoryTrails` returns an empty array. MUST hide breadcrumb section (see **hide-breadcrumbs-without-trail**).
- **`value` not found in `nodes`**: When `value` does not match any node in the tree, `nodeForName` returns `null` and breadcrumbs do not render. Component is still usable; the combobox and chooser remain active. MUST allow continued interaction.
- **`options` list and `nodes` tree are disconnected**: The autocomplete suggestions and the hierarchy are independent; a name may exist in `options` but not in `nodes`, or vice versa. MUST not enforce consistency between the two; this allows flexibility for incomplete hierarchies or names that exist elsewhere.
- **Category with multiple parents (DAG)**: When a category node has multiple parents, `categoryTrails` returns multiple trails, up to `MAX_TRAILS` (4). MUST display one `<ol>` per returned trail, each showing the distinct path to the leaf node (see **show-all-filing-paths**). Past 4 distinct filing paths, `categoryTrails` stops walking and later paths are not displayed; the cap exists because a DAG can have exponentially many paths and this is a form row, not a full hierarchy browser.
- **Category renamed while form is in focus**: If `onRename` succeeds, the dialog closes; if the renamed node is selected, the component calls `onChange` with the new name (see **rename-follows-selected**), so breadcrumbs and downstream form state follow the new name. If the renamed node is not selected, the rename does not affect the current value (see **rename-ignores-unselected**).
- **Rename cancelled by user**: When the user closes the rename dialog without confirming, `onClose` is called and `renaming` state is set to `null`. MUST close the dialog without modifying the component's value or breadcrumbs.
- **Rename rejected by callback**: If `onRename` rejects or throws, the dialog's own error handling is CategoryRenameDialog's — see [adhsdk.ingredient.ui.blocks.category-rename-dialog](cookbook:526da033-2f0d-4bd7-b2c2-99faba4783a3). CategoryField's `value` does not change, because `onChange` is only called after a successful rename (see **rename-follows-selected**).
- **Combobox with no matching options**: User types a string that does not match any option in the list. Combobox behavior is determined by the Combobox component; this component passes the typed value through `onChange` when confirmed. MUST allow free-form input.
- **Very long category names**: Category names longer than the viewport width will be truncated by the `truncate` class. MUST prevent text overflow; readability is preserved by focusing on the leaf node name (leaf-accent color draws attention).
- **Narrow viewport with multiple filings**: When breadcrumb trails wrap due to viewport width, the `flex-wrap` class allows trails to stack vertically. MUST display every trail `categoryTrails` returns (up to the `MAX_TRAILS` cap — see **show-all-filing-paths**); the component remains usable and accessible.
- **Disabled state interrupts rename flow**: If `disabled` becomes `true` while a rename dialog is open, the source does not close the dialog or otherwise change its behavior — CategoryField's own `renaming` state is independent of `disabled`. The host is responsible for coordinating the two if it needs different behavior.
- **Rapid successive renames**: Only one CategoryRenameDialog can be open at a time (a single `renaming` state), and the dialog disables its confirm action for the duration of the pending `onRename` call. Together these serialize renames without additional queuing logic in CategoryField.

## Configuration

Not applicable: CategoryField is a form component that does not expose configuration options beyond its props (label, noun, options, nodes, value, callbacks, layout, disabled, className). Behavior is fully specified by props; no runtime configuration is needed.

## Deep Linking

Not applicable: CategoryField is a form control, not a navigational component. Deep linking is handled by the host application, not by the component itself.

## Localization

The `label` and `noun` props are host-supplied and already localizable. The remaining microcopy is hardcoded English in the source and is not currently exposed as overridable props or externalized string keys:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `category-field.browse-trigger` | "Choose…" | EntityChooser trigger button label |
| `category-field.combobox-placeholder` | "Type a {noun}…" | Combobox placeholder |
| `category-field.browser-input-label` | "Filter or add a {noun}" | EntityChooser input label |
| `category-field.browser-input-placeholder` | "Filter or add a {noun}…" | EntityChooser input placeholder |
| `category-field.rename-button-label` | "Rename {noun} {name}" | Breadcrumb rename button `aria-label` |
| `category-field.browser-aria-label` | "Browse {label}" | EntityChooser `ariaLabel` |
| `category-field.path-singular` | "{label} path" | Breadcrumb `<nav>` `aria-label`, one trail |
| `category-field.path-plural` | "{label} paths" | Breadcrumb `<nav>` `aria-label`, multiple trails — a binary singular/plural, not a locale-aware plural rule (see Compliance: `plural-forms`) |

`label.toLowerCase()`, used to build the EntityChooser's `ariaLabel`, is a locale-sensitive casing transform: it must run in the user's locale rather than an invariant-culture lowercase call, since casing rules differ by language (e.g. Turkish dotless/dotted I).

## Accessibility Options

Not applicable: CategoryField does not directly respond to system-level accessibility options like Reduce Motion or Increase Contrast. It delegates to its child components (Combobox, EntityChooser, Field, CategoryRenameDialog), which handle their own accessibility feature support. The host and those child components are responsible for implementing motion, contrast, and other accessibility preferences.

## Feature Flags

Not applicable: CategoryField does not use feature flags. It is always present and functional when rendered.

## Analytics

Not applicable: CategoryField does not emit analytics events. The host is responsible for instrumentation. If the host needs to track category selection, rename actions, or browse-dialog usage, they must wire callbacks at the host level (onChange, onRename callbacks) to their analytics service.

## Privacy

Not applicable: CategoryField is a stateless form component. It does not collect, transmit, or store data beyond what the host passes in and receives via callbacks. Data privacy is the host's responsibility.

## Logging

Not applicable: CategoryField does not perform logging. Debug or diagnostic logging is the host's responsibility.

## Platform Notes

- **React/Web**: The implementation is in `packages/web/packages/ui/src/blocks/category-field.tsx`. Uses React hooks (`useState`) for rename modal state, re-exports `categoryTrails` and `CategoryTreeNode` from `category-tree.ts` for composability, delegates to `Field`, `Combobox`, `EntityChooser`, and `CategoryRenameDialog` components. Breadcrumb accent colors are the `text-apt-gold` (leaf) and `text-apt-text-muted` (ancestor) Tailwind tokens. Breadcrumbs are rendered as semantic lists (`<nav>`, `<ol>`, `<li>`) with proper ARIA roles and labels. Focus management and keyboard interaction are handled by child components.

- **SwiftUI**: A `Picker` cannot do free-form autocomplete against a suggestion list, so build the combobox as a text field bound to a filtered suggestions list (e.g. a `TextField` with a `List` overlay, or `.searchable` feeding filtered results) rather than a `Picker`. Present the entity browser with a `.sheet`. Render each breadcrumb trail as a `List`/`HStack` of `Button`/`Text` rows separated by `Image(systemName: "chevron.right")`. Present the rename interaction with a `.sheet` containing a text field. Use `@State` for the rename target and `.accessibilityLabel` on the crumb buttons.

- **Compose**: Implement as a `Column` containing a `Row` of the text-field combobox and browse button, followed by a plain `Column` (not `LazyColumn` — breadcrumb trails are few and short-lived, and a `LazyColumn` nested inside a form row's own scroll container causes nested-scrolling conflicts) of `Row`s, each a sequence of `Text`/clickable `Text` elements separated by a small chevron `Icon`. Manage the rename target with `mutableStateOf` and present it via `AlertDialog` or a custom `Dialog` composable with a `TextField`. Provide `contentDescription` for every interactive element.

- **AppKit / UIKit**: Use an `NSComboBox`/`UITextField` backed by a filtered suggestions list (a popover table on macOS, an overlay `UITableView` on iOS) for the combobox, and an `NSButton`/`UIButton` labeled "Choose…" to present the browser (a sheet on macOS, a modal view controller on iOS). Lay out each breadcrumb trail as a horizontal `NSStackView`/`UIStackView` of buttons and `NSImageView`/`UIImageView` chevrons. Present the rename interaction as a sheet (macOS) or a modal alert with a text field (iOS). Set `accessibilityLabel` on every rename button.

- **WinUI 3**: Use a `ComboBox` with `IsEditable="True"` bound to the options list, so it accepts free-form text instead of only a closed selection, plus a `Button` for the browser ("Choose…"). Render each breadcrumb trail as a horizontal `StackPanel` of `HyperlinkButton`/`TextBlock` elements separated by a `FontIcon` (a Segoe Fluent chevron glyph) rather than a `Separator`, which draws a full-width divider line, not an inline glyph. Present the rename interaction as a `ContentDialog`. Use `FocusVisualPrimaryBrush`/`FocusVisualSecondaryBrush` for keyboard focus visuals, consistent with Fluent 2's 2px outline. Set `AutomationProperties.Name` on every control.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/category-field.tsx` | unverified |

## Design Decisions

- **Decision**: Present the combobox and entity chooser as a flat list of category names rather than a tree walk.
  **Rationale**: Names are unique per owner across the entire hierarchy, so typing a few characters to find a category is faster than navigating a nested tree; breadcrumbs reveal the hierarchy afterwards, making the flat pick legible and showing every place a multi-filed category sits.
  **Approved**: pending

- **Decision**: Rename a category node directly from its breadcrumb, via a modal, rather than only from a separate management screen.
  **Rationale**: Keeps the hierarchy edit co-located with the form and is faster than switching screens; the modal confirm step prevents a stray click on a breadcrumb from renaming a category everywhere it is used.
  **Approved**: pending

- **Decision**: Use a modal dialog (CategoryRenameDialog) for the rename rather than inline editing of the breadcrumb text.
  **Rationale**: Inline editing would require managing edit state, blur/focus behavior, and validation within CategoryField itself; a modal centralizes that complexity, provides a dedicated space for error messages and retry, and keeps the interaction explicit (open, edit, confirm or cancel).
  **Approved**: pending

- **Decision**: Display every filing path as a separate breadcrumb trail, up to a cap of 4 trails (`MAX_TRAILS`), when a category has multiple parents (DAG), rather than picking one to show or walking the whole DAG unbounded.
  **Rationale**: Answers "where is this category filed?" without requiring navigation or a separate view, and is more discoverable than hiding all but one path; a DAG has exponentially many paths, and past a handful the breadcrumb stops being the thing that made the name legible in what is otherwise just a form row, so `categoryTrails` stops walking at 4.
  **Approved**: pending

- **Decision**: Give leaf breadcrumbs a distinct accent color and ancestor breadcrumbs a muted color.
  **Rationale**: Draws attention to the selected category while de-emphasizing the hierarchy above it, following a common breadcrumb-navigation pattern that aids scanning.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.plural-forms](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d24616b8-d1af-593d-ba01-f51ee4a91ea4) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: `aria-label`s and the `<nav>`/`<ol>`/`<li>`/`<button>` semantics support screen readers and keyboard use directly; `text-apt-gold`/`text-apt-text-muted` are opaque design tokens whose actual contrast the source cannot confirm, and `text-xs` is a rem-based Tailwind class that likely scales with type-size settings but the source does not prove it; the hardcoded English strings (`"Choose…"`, `"Type a …"`, etc.) and the binary `path`/`paths` construction are not externalized or locale-aware, and the flex/gap layout shows no RTL-specific handling; `category-field.tsx` composes `Field`/`Combobox`/`EntityChooser`/`CategoryRenameDialog` and delegates trail-walking to the `categoryTrails` helper in `category-tree`, keeping its own file to composition and event wiring (separation-of-concerns); and `categoryField.test.tsx` plus `categoryTree.test.ts` assert the combobox/browser/rename wiring and the trail-walking helper with meaningful assertions (unit-test-coverage).

## Props

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `label` | `string` | Yes | — | The row's caption, passed to the wrapping `Field`. |
| `noun` | `string` | Yes | — | The singular, lowercase noun used to build the controls' microcopy (e.g. "category"). There is no default; the host must always supply it. |
| `hint` | `React.ReactNode` | No | `undefined` | Optional supporting content passed through to `Field`. |
| `options` | `readonly string[]` | Yes | — | Suggested names for the combobox and entity chooser. A suggestion list, not a closed set — `value` may hold a name that is not in it. |
| `nodes` | `readonly CategoryTreeNode[]` | No | `[]` | The hierarchy (`{ id, name, parentIds }`) that drives breadcrumbs and rename. Omit it and the value renders as the single name it is, with no breadcrumbs. |
| `value` | `string` | Yes | — | The chosen name, or `""` for none. |
| `onChange` | `(next: string) => void` | Yes | — | Called with the new value on a combobox change, an entity-chooser selection, or a rename of the currently selected node. |
| `onRename` | `(node: CategoryTreeNode, nextName: string) => void \| Promise<void>` | No | `undefined` | Renames an existing node from a click on its breadcrumb. May be async. Omit it and breadcrumbs render as static text. |
| `layout` | `"stacked" \| "inline"` | No | Field's own default (`"stacked"`) | Forwarded to `Field` to control label positioning. |
| `disabled` | `boolean` | No | `false` | Disables the combobox, the entity chooser, and breadcrumb rename buttons. |
| `className` | `string` | No | `undefined` | Forwarded to `Field` for custom styling. |

`onRenamed` is not a prop of CategoryField — it is `CategoryRenameDialog`'s own callback (see [adhsdk.ingredient.ui.blocks.category-rename-dialog](cookbook:526da033-2f0d-4bd7-b2c2-99faba4783a3)), which CategoryField wires internally to call `onChange` only when the renamed node is the selected one.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | show-all-filing-paths capped at MAX_TRAILS=4 (T035 added); rename-dialog-receives-node passes extraNames=options not value (T018 corrected). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and merged the duplicate breadcrumb-visibility and chevron requirements; added a Props section and expanded depends-on to the composed ingredients; replaced hardcoded color-token names in requirements with semantic roles, keeping the tokens in Appearance and the React/Web platform note; corrected the appearance, accessibility, states, localization, compliance, and platform-notes sections against the source; reformatted Design Decisions; tightened vague test vectors and added vectors for previously uncovered edge cases. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from web source code |
