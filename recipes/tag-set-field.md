---
id: a3645ff4-19c2-4b30-a828-93a56191f656
title: TagSetField
domain: adhsdk://recipes/tag-set-field
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A form control for editing a set of short labels from a growing vocabulary,
  combining autocomplete search and browse/create affordances.
platforms:
- typescript
- web
tags:
- form-control
- tag-editing
- vocabulary-management
depends-on:
- adhsdk://recipes/field
- adhsdk://recipes/combobox
- adhsdk://recipes/entity-chooser
related:
- adhsdk://recipes/category-field
references: []
approved-by: ''
approved-date: ''
---

# TagSetField

## Overview

A form control that manages a set of short labels (tags) drawn from a growing vocabulary. The component pairs an autocomplete search field for quick selection of known labels with a browse/create dialog for exploring the full vocabulary and minting new labels. Selected labels render as removable chips in a separate row below the controls, visually anchoring the component as a tag editor rather than two disconnected inputs.

This component extracts a pattern used consistently across features that manage tagged entities (e.g., research document tags and work item labels) so the interaction affordance and commit behavior remain uniform across the application.

## Behavioral Requirements

- **display-label**: Component MUST display the `label` prop as the field's caption, via the shared `Field` component.
- **hint-prop**: Component MUST display the optional `hint` prop if provided, via the shared `Field` component.
- **render-combobox**: Component MUST render a `Combobox` control in the top row for autocomplete search.
- **render-entity-chooser**: Component MUST render an `EntityChooser` control in the top row to the right of the Combobox for browsing and creating labels.
- **show-filtered-suggestions**: Component MUST filter the `options` list to exclude any item already present in the `value` array and pass the filtered list to the Combobox.
- **accept-exact-match-in-combobox**: Component MUST add an item to `value` and call `onChange` with the updated array when the Combobox's `onValueChange` fires with text that exactly matches an item in `options` and is not already in `value`. This is the sole acceptance path — there is no separate "confirm" step; the event fires identically whether the match came from clicking a suggestion, pressing Enter on a highlight, or the typed text simply reaching an exact match mid-keystroke (see **case-sensitive-exact-match** and the "typing a prefix of a longer option" edge case).
- **case-sensitive-exact-match**: The exact-match check (`options.includes(next)`) MUST be case-sensitive and MUST NOT trim whitespace; `"Foo"` or `" foo "` do not match an option `"foo"`.
- **clear-combobox-on-acceptance**: Component MUST clear the Combobox text field after adding an item via exact match.
- **no-create-on-enter**: Component MUST NOT add an item to `value` when the Combobox receives text that does not exactly match any item in `options`, even if the user presses Enter; only the EntityChooser's `allowCreate` row creates new labels.
- **render-chips-row**: Component MUST render selected items as removable chips below the control row using `EntitySelectionChips`.
- **render-chips-from-value**: Component MUST render all items in the `value` array as chips, maintaining their order.
- **remove-chip-on-delete**: Component MUST remove an item from `value` and call `onChange` with the updated array when the user clicks the remove action on a chip.
- **empty-chips-row-renders-nothing**: When `value` is empty, `EntitySelectionChips` (given no `emptySelectionLabel`) MUST render nothing at all — no chips-row element in the DOM, not an empty one — so a field with no selection yet costs no height; there is no "No tags yet" label or placeholder row.
- **pass-label-to-chips**: Component MUST pass the `label` prop as the `ariaLabel` to `EntitySelectionChips`.
- **pass-label-to-chooser**: Component MUST pass the `label` prop as the `ariaLabel` to `EntityChooser`.
- **noun-in-placeholders**: Component MUST build every piece of microcopy from the singular `noun` prop: the Combobox's `ariaLabel` (`Add a ${noun}`) and `placeholder` (`Add a ${noun}…`), and the EntityChooser's `inputLabel` (`Filter or add a ${noun}`) and `placeholder` (`Filter or add a ${noun}…`).
- **pass-disabled-to-controls**: Component MUST propagate the `disabled` prop to the Combobox, the EntityChooser, and `EntitySelectionChips`.
- **accept-layout-prop**: Component MUST pass the optional `layout` prop (`"stacked"` or `"inline"`, default `"stacked"`) to the shared `Field` component.
- **accept-classname-prop**: Component MUST pass the optional `className` prop to the shared `Field` component.
- **options-as-suggestion**: Component MUST treat the `options` list as a suggestion list, not a closed set; items in `value` may exist outside `options` (newly created labels or additions from other surfaces).
- **maintain-value-order**: Component MUST preserve the order of items in the `value` array; no sorting or reordering is applied.

## Appearance

- **Layout**: Two rows in a vertical flex container with an 8px gap between them (`flex flex-col gap-2`). Top row (`flex w-full items-stretch gap-2`): Combobox and EntityChooser side by side, 8px gap. Bottom row: the chips group, spanning the full field width.
- **Combobox width**: Flexible (`flex-1`); grows to fill whatever width the EntityChooser leaves.
- **EntityChooser width**: Fixed at 176px (`w-44`), and it does not shrink (`shrink-0`) — the Combobox, not the chooser, absorbs any extra or missing space.
- **Chips row**: Spans the full field width; renders nothing visually when `value` is empty.
- **Disabled state**: Combobox, EntityChooser, and each chip's remove control render with platform-appropriate disabled styling.

## States

| State | Appearance change |
|-------|------------------|
| Default | Both controls enabled; Combobox text field empty or shows partial search text. |
| Active (Combobox focused) | Combobox shows focus ring; suggestion dropdown visible if text matches partial options. |
| Active (EntityChooser opened) | EntityChooser dialog open; Combobox in background. |
| Item added | Combobox text field cleared; chip appears in chips row. |
| Item removed | Chip removed from chips row; if last chip, row renders empty. |
| Disabled | Both Combobox and EntityChooser render disabled; no interaction possible. |

## Accessibility

- **Role**: The component is a grouped form control. The shared `Field` component provides an accessible label via the `label` prop. Each sub-control (Combobox, EntityChooser, EntitySelectionChips) provides its own accessible role and label.
- **Combobox label**: Set via `ariaLabel={`Add a ${noun}`}` (see **noun-in-placeholders**).
- **EntityChooser label**: Set via `ariaLabel={label}` (the field-level label) to associate it with the field.
- **Chips group label**: Set via `ariaLabel={label}` on `EntitySelectionChips` to announce the group.
- **Keyboard navigation**: Combobox, EntityChooser, and the chips' remove controls are each individually keyboard-accessible; TagSetField adds no keyboard handling of its own. Chip removal's specific keyboard behavior is `EntitySelectionChips`'s own — see `adhsdk://recipes/entity-chooser`.
- **Item addition is not announced**: The component does not emit an ARIA live-region announcement when an item is added. Screen-reader users only perceive the change through the Combobox's own text clearing and the new chip entering the DOM — neither of which is an explicit announcement. This is a real gap in the source, not a documented feature.
- **Item removal is not announced**: Likewise, removing a chip only updates `value` and re-renders the chip list; no live-region announcement accompanies it.
- **Minimum tap target**: Combobox input and EntityChooser trigger button SHOULD meet platform minimum touch target size (44×44pt on iOS, 48×48dp on Android, typically 44px on web).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tag-set-001 | render-combobox, render-entity-chooser, render-chips-row | Render with `label="Tags"`, `noun="tag"`, `options=["foo", "bar"]`, `value=[]`. | Two controls render in the top row; no chips-row element exists below them (see **empty-chips-row-renders-nothing**). |
| tag-set-002 | show-filtered-suggestions | `options=["foo", "bar", "baz"]`, `value=["foo"]`. | Combobox suggestions are filtered to `["bar", "baz"]`; "foo" is not offered. |
| tag-set-003 | accept-exact-match-in-combobox | Precondition `options=["foo", "bar"]`, `value=["foo"]`. The Combobox's text becomes exactly "bar" (typed, or the result of clicking a suggestion — both raise the same `onValueChange` event). | `onChange` is called once with `["foo", "bar"]`. |
| tag-set-004 | clear-combobox-on-acceptance | Precondition `options=["foo", "bar"]`, `value=["foo"]`. Combobox text reaches the exact match "bar" (as in tag-set-003). | Combobox text field is cleared to empty. |
| tag-set-005 | no-create-on-enter | Precondition `options=["foo", "bar"]`, `value=[]`. User types "newlabel" (not an exact match to any option) and presses Enter. | `onChange` is NOT called; the Combobox text remains "newlabel". |
| tag-set-006 | render-chips-from-value | `value=["foo", "bar", "baz"]`. | Three chips render in the chips row, in order: "foo", "bar", "baz". |
| tag-set-007 | remove-chip-on-delete | `value=["foo", "bar", "baz"]`; user clicks remove on chip "bar". | `onChange` is called with `["foo", "baz"]`; the "bar" chip is removed. |
| tag-set-008 | empty-chips-row-renders-nothing | `value=[]`. | No chips-row element exists in the DOM at all — `EntitySelectionChips` renders nothing. |
| tag-set-009 | noun-in-placeholders | `noun="label"`. | Combobox `ariaLabel` is "Add a label" and placeholder is "Add a label…"; EntityChooser `inputLabel` is "Filter or add a label" and placeholder is "Filter or add a label…". |
| tag-set-010 | pass-disabled-to-controls | `disabled=true`. | Combobox, EntityChooser, and `EntitySelectionChips` all receive `disabled={true}`. |
| tag-set-011 | accept-layout-prop | `layout="inline"`. | The shared `Field` component receives `layout="inline"`; the caption renders beside the controls instead of above them. |
| tag-set-012 | options-as-suggestion | `options=["foo", "bar"]`, `value=["foo", "baz"]` (`"baz"` not in `options`). | Combobox suggestions show only `["bar"]`; `"baz"` still renders as a chip (a label created elsewhere). |
| tag-set-013 | maintain-value-order | `value=["third", "first", "second"]` (inserted out of alphabetical order). | Chips render in order: "third", "first", "second" — no sorting is applied. |
| tag-set-014 | display-label | `label="Field Caption"`. | The `Field` wrapper displays "Field Caption" as the row's caption. |
| tag-set-015 | hint-prop | `hint="Help text"`. | The `Field` wrapper displays "Help text" below or beside the caption. |
| tag-set-016 | accept-exact-match-in-combobox, case-sensitive-exact-match | Precondition `options=["bar", "barn"]`, `value=[]`. User types "b", "a", "r" one keystroke at a time. | The instant the text equals "bar" exactly, `onChange` is called with `["bar"]` and the field clears — before the user can continue typing toward "barn". There is no separate select/confirm step; this is the same acceptance path as tag-set-003. |
| tag-set-017 | case-sensitive-exact-match | Precondition `options=["foo"]`, `value=[]`. User types "Foo". | `onChange` is NOT called; `"Foo"` does not exactly equal `"foo"`. The Combobox text remains "Foo". |
| tag-set-018 | case-sensitive-exact-match | Precondition `options=["foo"]`, `value=[]`. User types `" foo "` (leading/trailing spaces). | `onChange` is NOT called; the untrimmed string does not exactly equal `"foo"`. The Combobox text remains `" foo "`. |
| tag-set-019 | pass-label-to-chips | `label="Field Caption"`, `value=["foo"]`. | `EntitySelectionChips` receives `ariaLabel="Field Caption"`. |
| tag-set-020 | pass-label-to-chooser | `label="Field Caption"`. | `EntityChooser` receives `ariaLabel="Field Caption"`. |
| tag-set-021 | accept-classname-prop | `className="custom-class"`. | The `Field` wrapper's root element includes `custom-class` in its class list. |

## Edge Cases

- **Empty options list**: If `options=[]` and `value=[]`, the component renders with both controls enabled. The Combobox shows no suggestions; the EntityChooser's browse list is empty (`allowCreate` remains available if EntityChooser supports it).
- **Empty value array**: If `value=[]`, no chips-row element exists in the DOM at all (see **empty-chips-row-renders-nothing**). The component is ready to accept new selections.
- **Value contains items not in options**: If `value=["custom"]` and `"custom"` is not in `options`, the component displays the chip anyway — the label was created outside this component or by another surface (see **options-as-suggestion**). The Combobox continues to filter `options` normally.
- **Large value array**: No explicit limit is defined in the source; the component maintains all items and renders all chips. Performance depends on the parent's render optimization and on `EntitySelectionChips`'s own implementation.
- **Duplicate item attempted via Combobox**: If `value=["foo"]` and the user types "foo" again, **show-filtered-suggestions** has already removed "foo" from the suggestion list, so there is nothing left to match — the duplicate is prevented by omission, not by a separate check.
- **Typing a prefix of a longer option**: If `options=["bar", "barn"]`, typing toward "barn" passes through the exact match "bar" on the way — and that match is accepted immediately (see **accept-exact-match-in-combobox**, **case-sensitive-exact-match**, tag-set-016). The component has no notion of "still typing"; any exact match is taken the instant it occurs.
- **Rapid add/remove cycles**: The component responds to each `onChange` callback; no debouncing or batching is applied. If the parent re-renders with a new `options` list before a Combobox `onValueChange` event fires, the suggestion list is recalculated immediately.
- **Very long label text**: The component delegates text truncation and overflow behavior to the Combobox and `EntitySelectionChips` sub-components; no truncation is applied at the TagSetField level.
- **Chip removal while disabled**: `disabled` propagates to `EntitySelectionChips` as well as to the Combobox and EntityChooser (see **pass-disabled-to-controls**). Whether the remove affordance is actually inert when disabled is `EntitySelectionChips`'s own behavior — see `adhsdk://recipes/entity-chooser`.
- **Disabled while EntityChooser dialog open**: If `disabled` changes to true while dialog is open, component propagates the change to EntityChooser, which handles state (likely closes or disables the dialog).
- **Combobox partial text + blur**: If user enters partial text "fo" in Combobox and blurs the field without selecting a match, text remains; no auto-acceptance occurs.
- **Concurrency**: Not applicable — this is a single-threaded UI component controlled by React's render loop and event handler serialization.
- **Offline**: Not applicable — the component manages local state only and makes no network requests.

## Configuration

Not applicable: TagSetField is a controlled component with no configurable runtime options of its own — the `options`, `value`, `onChange`, and textual props (`label`, `noun`, `hint`) fully define its state and behavior, aside from the Combobox's local input text (see **React/Web** in Platform Notes). No configuration file or feature flag is required.

## Deep Linking

Not applicable: TagSetField is a form control within a larger page and is not independently navigable via deep links. Deep linking targets the containing page/form, not the component itself.

## Localization

The `label` and `noun` props are host-supplied and already localizable. The remaining microcopy is hardcoded English in the source and is not currently exposed as overridable props or externalized string keys — concatenating `noun` into a fixed English sentence shape (`"Add a ${noun}…"`) also assumes English grammar (e.g. the indefinite article "a"), which will not read correctly in every target language without further work:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `tag-set-field.combobox-aria-label` | `Add a ${noun}` | Combobox `ariaLabel` |
| `tag-set-field.combobox-placeholder` | `Add a ${noun}…` | Combobox placeholder |
| `tag-set-field.chooser-input-label` | `Filter or add a ${noun}` | EntityChooser `inputLabel` |
| `tag-set-field.chooser-placeholder` | `Filter or add a ${noun}…` | EntityChooser placeholder |
| (from Field) | (parent-provided) | `label` and `hint` are provided by the parent and are not localized by this component. |

The component constructs microcopy dynamically from the `noun` prop and does not maintain a separate string catalog. All other user-facing text originates from parent props.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Component does not apply motion within its own render. Sub-components (Combobox, EntityChooser, EntitySelectionChips) are responsible for respecting OS reduce-motion preferences. |
| Increase Contrast | Component does not apply contrast changes; sub-components handle contrast adjustments. |
| Differentiate Without Color | Component uses text and icons provided by sub-components; no color-only differentiation is introduced by TagSetField. |

## Feature Flags

Not applicable: Component does not check feature flags or conditional logic based on flags. Enabling/disabling the component is the parent's responsibility.

## Analytics

Not applicable: Component does not emit analytics events. Parent forms that use TagSetField are responsible for tracking user interactions (e.g., tag added, tag removed) if needed.

## Privacy

Not applicable: Component does not collect, store, or transmit data. Tag labels are managed by the parent and passed as props; no sensitive data is processed or logged by TagSetField itself.

## Logging

Not applicable: Component does not emit debug or error logs. Logging is delegated to parent forms and sub-components (Combobox, EntityChooser).

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/ui/src/blocks/tag-set-field.tsx` as a functional component. The two-row layout is Tailwind flexbox: `flex flex-col gap-2` for the outer container, `flex w-full items-stretch gap-2` for the control row, `flex-1` on the Combobox, and `w-44 shrink-0` on the EntityChooser. State is local (`text`, the Combobox's in-progress search string); suggestions are computed via `useMemo`. The Combobox's `onValueChange` fires on every keystroke and on every suggestion pick with no distinction between the two; the component treats an exact match against `options.includes(next)` as acceptance regardless of how the text got there (see **accept-exact-match-in-combobox**). Sub-components (`Field`, `Combobox`, `EntityChooser`, `EntitySelectionChips`) are imported from the same UI package and are responsible for their own styling and accessibility.

- **SwiftUI**: Build a `View` with a `TextField` bound to the local search text plus an inline suggestion list or popover shown while text is present — not `.searchable()`, which attaches search chrome to a `List`/`NavigationStack` rather than an inline field. Suggested items are a computed `var` (not `@State`, since they are fully derived from `options` and the current selection) that filters out already-selected values. Add to the selection only when the text exactly matches an offered suggestion (see **accept-exact-match-in-combobox**, **case-sensitive-exact-match**); use plain `String` equality, not a case- or whitespace-insensitive comparison. Present the entity chooser with `.sheet(isPresented:)`. Render selected tags with a custom flow `Layout` (SwiftUI's `Layout` protocol) of removable capsules below the search field. Pass `disabled` via `.disabled()` to the text field, the chooser button, and each chip's remove button.

- **Compose**: Implement with a `Column` (a fixed two-row layout does not need `LazyColumn`) containing a `Row` with an `ExposedDropdownMenuBox`-based text field for the autocomplete search and a `Button` that opens the entity-chooser dialog. Compute filtered suggestions with `remember { derivedStateOf { ... } }`, excluding already-selected items, and add to the selection only on an exact text match (see **accept-exact-match-in-combobox**). Render selected tags as a `FlowRow` of `InputChip` components using each chip's trailing icon slot for the remove action — `AssistChip` has no built-in dismiss affordance. Propagate `enabled` to the text field, the dialog trigger, and every chip.

- **AppKit / UIKit**: On macOS, use an `NSTokenField`, or an `NSSearchField` with a completions menu bound to the filtered suggestion list, paired with an `NSButton` ("Choose…") that presents the entity chooser as a sheet (`NSSearchController` does not exist as an AppKit type). On iOS, use a `UITextField` with an overlay `UITableView` of suggestions — not `UISearchController`, which is built for a navigation-bar search experience rather than an inline form field — paired with a `UIButton` presenting the chooser as a modal view controller. Render selected tags in a horizontal wrapping `NSStackView`/`UIStackView` (or custom flow view) of removable chip views. The disabled state disables the search input, the chooser button, and each chip's remove control.

- **WinUI 3**: Use a single `AutoSuggestBox` bound to the filtered suggestions via `ItemsSource`, so one control handles both typing and picking a suggestion. Hook `SuggestionChosen` (a pick) and `QuerySubmitted` (Enter), and in both, add to the selection only when the submitted text exactly matches an item in `ItemsSource` (see **accept-exact-match-in-combobox**) — a plain `TextBox`'s `TextChanged` event fires on every keystroke and cannot express **no-create-on-enter**. Pair it with a fixed-width `Button` ("Choose…") opening the entity chooser. Bind the selected tags to an `ItemsRepeater` (not a `GridView`, which adds selection semantics the chips don't need), rendering each as a `Button` with a close-icon glyph. Set `IsEnabled` on the `AutoSuggestBox`, the chooser button, and each chip's close button when disabled.

## Design Decisions

- **Decision**: Keep the Combobox (autocomplete) and EntityChooser (browse/create) as two separate controls rather than one combined control.
  **Rationale**: They answer different user questions — autocomplete serves someone who already knows the label's name, while the chooser serves someone browsing. Separating them avoids the cognitive load of a mode switch inside one input, and lets the chooser offer creation without conflating "I typed something new" with "I want to create it."
  **Approved**: pending

- **Decision**: Do not create a new label on Enter in the Combobox; require the exact-match acceptance path or the EntityChooser's `allowCreate` row.
  **Rationale**: The source checks for an exact match against `options` before adding anything (see **accept-exact-match-in-combobox**, **no-create-on-enter**). Typing a label name that is not yet in the vocabulary and pressing Enter does not create it — minting a label is the chooser's explicit `allowCreate` action. This avoids accidentally creating labels from typos and keeps creation intent explicit.
  **Approved**: pending

- **Decision**: Render the chips as a sibling row below the control row, not nested inside the EntityChooser's column.
  **Rationale**: Nesting caused layout wrap and misalignment with other form controls (e.g. CategoryField): "No tags yet" text took the first line and pushed the trigger to a second line, 56px below the trigger it should align with, and adding a single tag re-broke the alignment the same way. A full-width row of its own spans the width the chips actually need and leaves the right column exactly one trigger wide in every state.
  **Approved**: pending

- **Decision**: Treat the `options` list as a suggestion list, not a closed set.
  **Rationale**: Items in `value` may exist outside `options` because labels are created by the EntityChooser or by other surfaces in the application (see **options-as-suggestion**). This keeps tag management consistent across the application without requiring this component to sync or reload the vocabulary.
  **Approved**: pending

- **Decision**: Build all microcopy from a singular, lowercase `noun` prop instead of hardcoding "tag".
  **Rationale**: Lets the component be reused for other entity types (e.g. "label", "keyword", "category") without code changes, keeping the interaction pattern uniform across features that manage tagged entities (see **noun-in-placeholders**).
  **Approved**: pending

- **Decision**: Preserve the `value` array's order exactly as the parent provides it — no sorting or canonical reordering.
  **Rationale**: Lets the parent control tag order (e.g. by insertion time, custom ranking, or an external system) (see **maintain-value-order**).
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on the source: `ariaLabel` props reach the Combobox, EntityChooser, and EntitySelectionChips directly and each sub-control provides its own keyboard support, but this component adds no ARIA live-region announcement on add/remove, and chip-removal keyboard behavior is EntitySelectionChips's own to confirm; no color, contrast, or type-scale tokens are set at this level (all delegated to Tailwind utility classes and sub-components, which this source cannot confirm); every placeholder and label string is a hardcoded English template literal built from `noun`, not an externalized key; and the fixed 176px EntityChooser width could truncate a longer translated string, which this component does nothing to accommodate; the acceptance-matching logic (`onText`, the `suggestions` filter) is inline in the component rather than extracted apart from rendering (separation-of-concerns partial), and `tagSetField.test.tsx` exercises the autocomplete-acceptance rule, the chooser's add/remove/mint paths, and the layout fix directly (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Renamed empty-chips-row-renders-blank to -renders-nothing; matches source's no-DOM-element behavior. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case, merged the duplicate exact-match/onChange requirements, renamed the empty-chips-row requirement to match its actual behavior, and added a case-sensitivity requirement; corrected the acceptance-trigger wording and test vectors (exact text match, not click/Enter) and added vectors for a prefix-of-a-longer-option, case/whitespace handling, and previously uncovered className/chip-aria-label requirements, each with full input-state preconditions; expanded disabled propagation and noun-based microcopy to cover EntitySelectionChips and the Combobox aria-label; reformatted Design Decisions to the three-line form; replaced the "Not applicable" Compliance section with a table; corrected invalid APIs in the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes; resolved the "stateless" contradiction with the local Combobox text state; fixed the `{{noun}}` template-variable syntax to `${noun}`; expanded depends-on/related to the composed ingredients and CategoryField; renamed the two malformed edge-case bullets; and switched frontmatter dates to bare ISO form. |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
