---
id: 17433dd1-f3db-4d7b-9f58-997996a2b92e
title: Filtered List
domain: adhsdk://recipes/filtered-list
type: ingredient
version: 1.2.2
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Searchable list component with keyboard navigation and item highlighting.
platforms:
- typescript
- web
tags:
- list
- filtering
- search
- keyboard-navigation
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Filtered List

## Overview

FilteredList is a searchable list component that renders a text input field above a list of items. It filters items based on the input query, supports keyboard navigation with arrow keys and Enter for selection, and maintains a highlight state for the currently focused item. The component is accessible via combobox and listbox ARIA roles and supports custom rendering through callback functions. `total` (the full, unfiltered item count) and the filtered `visible` items are both derived from the `useFilteredList` hook; the empty state differs depending on whether `total` is zero or filtering has simply produced no matches (see **empty-state-when-no-items**, **default-no-matches-message**).

## Behavioral Requirements

- **render-input-field**: Component MUST render a text input field with an optional placeholder that defaults to "Filter…".
- **filter-items**: Component MUST filter the visible items to those matching the query text entered by the user. By default (no `match` override), a match is a case-insensitive substring match: the query and each of `getTitle(item)`, `getSubtitle(item)`, `getDetails(item)`, and any `getSearchableExtras(item)` values are lower-cased, and the item matches if the lower-cased query is a substring of any field. Lower-casing uses the platform's default (locale-sensitive) case folding; consumers needing exact behavior in a specific locale should supply a custom `match` function rather than an invariant-culture comparison. Consumers MAY replace this default entirely via the `match` prop, which receives the item and the already-lower-cased, trimmed query. Filtering logic is implemented in the `useFilteredList` hook.
- **arrow-down-navigation**: When the user presses ArrowDown and visible items exist, component MUST move the highlight to the next item in the visible list, to the first item if no item is currently highlighted, or leave the highlight on the last item if the last item is already highlighted (the highlight does not wrap).
- **arrow-up-navigation**: When the user presses ArrowUp and visible items exist, component MUST move the highlight to the previous item, or clear the highlight if the first item is highlighted.
- **enter-selection**: When the user presses Enter and an item is highlighted, component MUST call the onSelect callback with the highlighted item and prevent the default form submission via the input's own keydown handling. When no item is highlighted, pressing Enter MUST NOT call onSelect; the form's onSubmit handler independently prevents the browser's default submission regardless of highlight state (see **prevent-form-submission**).
- **escape-clears-highlight**: When the user presses Escape and an item is highlighted, component MUST clear the highlight by setting highlightedIndex to -1 and prevent the default action.
- **reset-highlight-on-input-change**: When the user types in the input field, component MUST reset the highlighted item index to -1.
- **clamp-highlight-when-visible-shrinks**: When the visible items list shrinks and the currently highlighted index exceeds the new length, component MUST adjust the highlight to the last item in the visible list, or to -1 if the list is now empty.
- **render-item-list**: Component MUST render all visible items as `<li>` elements within a `<ul>` list with role="listbox".
- **item-role-option**: Each rendered `<li>` item MUST have role="option", identifying it as a listbox option.
- **render-item-title**: When renderItem is not provided, each item MUST render its title via the getTitle callback in a `fl-title` element.
- **render-item-subtitle**: When renderItem is not provided and getSubtitle is provided and returns a value for an item, component MUST render the subtitle in a `fl-subtitle` element.
- **render-item-details**: When renderItem is not provided and getDetails is provided and returns a value for an item, component MUST render the details in a `fl-details` element.
- **custom-item-render**: If renderItem is provided, component MUST call it as `renderItem(item)` — a single-argument callback receiving the visible item and returning a ReactNode — instead of rendering title/subtitle/details directly.
- **clickable-items-when-onselect-provided**: When onSelect is provided, each visible item MUST be rendered as a button that calls onSelect when clicked.
- **mouse-hover-highlight**: When the user moves the mouse over an item, component MUST highlight that item.
- **scroll-active-item-into-view**: When the highlight changes to a new item, component MUST call scrollIntoView with `{ block: 'nearest' }` on the corresponding list item element.
- **input-shows-highlighted-title**: When an item is highlighted, the input field MUST display the title of that item instead of the query text.
- **combobox-aria-expanded**: The input field MUST have aria-expanded set to true when visible items exist, false otherwise.
- **combobox-aria-activedescendant**: The input field MUST have aria-activedescendant set to the ID of the currently highlighted item, or undefined if no item is highlighted.
- **unique-item-ids**: Each list item MUST have a unique ID constructed as `{listId}-{getId(item)}`.
- **option-aria-selected**: Each item MUST have aria-selected="true" when highlighted, "false" otherwise.
- **onhighlight-callback**: When the highlighted item changes, component MUST call the onHighlightChange callback with the new highlighted item or null if no item is highlighted.
- **empty-state-when-no-items**: When total (the unfiltered item count, i.e. items.length) is 0, component MUST display "No items." instead of the list. This message is not affected by emptyContent.
- **default-no-matches-message**: When filtering leaves zero visible items while total > 0, component MUST render the literal text `No matches for "{query}".` as the list's only item.
- **custom-empty-content**: If emptyContent is provided and total > 0 but visible.length is 0 after filtering, component MUST render emptyContent instead of the default no-matches message. emptyContent has no effect when total === 0.
- **render-footer**: If footer is provided, component MUST render it as the last list item.
- **wrap-input-in-form**: Component MUST wrap the input field in a `<form role="search">` element to prevent Safari autofill misclassification.
- **prevent-form-submission**: The form MUST prevent default submission on submit event, regardless of whether an item is highlighted.
- **autofill-prevention**: Component MUST apply noAutofillProps to the input to disable browser autofill.
- **autofocus-on-mount**: Component MUST focus the input on mount when autoFocus is true.
- **arrow-keys-noop-when-no-items**: Component MUST NOT prevent the default behavior for arrow keys if no visible items exist.

## Appearance

- **Corner radius**: Not specified in source; uses CSS classes (fl-input, fl-item, etc.)
- **Padding**: Not specified in source; controlled by CSS classes
- **Font**: Not specified in source; controlled by CSS classes
- **Background**: Not specified in source; controlled by CSS classes
- **Foreground/Text**: Not specified in source; controlled by CSS classes
- **Border**: `.fl-input` has a 1px border by default; on `:focus` its border-color changes to `var(--color-accent, #1e3a5f)` with an added 2px box-shadow ring (`var(--color-accent-dim)`), and `.fl-item-button` shows a background change (no outline) on `:focus-visible` (source: filtered-list.css). Other border details are otherwise controlled by CSS classes.
- **Shadow**: Not specified in source; controlled by CSS classes
- **Min/Max size**: Input is width: 100%; list items are full-width within the root container
- **CSS class structure**:
  - `fl-root`: Root container wrapper
  - `fl-input`: Text input field
  - `fl-list`: Unordered list element
  - `fl-item`: List item element
  - `fl-item--active`: Applied to active/highlighted item
  - `fl-item--clickable`: Applied to items when onSelect is provided
  - `fl-item-button`: Button wrapper around item content when clickable
  - `fl-title`: Title text within an item
  - `fl-subtitle`: Subtitle text within an item
  - `fl-details`: Details text within an item
  - `fl-empty`: Empty state message element
  - `fl-footer`: Footer element

## States

| State | Appearance change | Trigger |
|-------|------------------|---------|
| Default | No item highlighted, input shows query text | Initial state |
| Highlighted | Item has fl-item--active class, input shows item title, aria-selected="true" | Arrow keys, mouse hover |
| Filtered | List shows only matching items, empty state shown if no matches | User types in input |
| Disabled/Empty | "No items." message shown, list not rendered | total === 0 |
| Focused | Input has keyboard focus | User clicks input or autoFocus=true |

## Accessibility

- **Input role**: MUST be `combobox` with aria-controls pointing to the list ID and aria-expanded indicating whether the list has items.
- **Input aria-activedescendant**: MUST point to the currently highlighted item's ID, or be undefined if no item is highlighted.
- **List role**: MUST be `listbox` with a unique id.
- **Item role**: Each item MUST have role="option" (see **item-role-option**) and aria-selected reflecting highlight state.
- **Form role**: MUST be `role="search"` for semantic meaning.
- **Keyboard navigation**: MUST support ArrowUp, ArrowDown, Enter, and Escape keys as specified in Behavioral Requirements.
- **Focus management**: DOM focus MUST remain on the input at all times; the combobox pattern (aria-activedescendant) communicates the highlighted item to assistive technology without moving focus. List items are not part of the tab order (item buttons use tabIndex={-1}); highlight changes via keyboard or mouse hover never move DOM focus to a list item.
- **Label for input**: Component renders no `<label>` element, and `FilteredListProps` has no `aria-label` or `label` field, so the only user-facing description available is the input's placeholder text (default "Filter…", set via the `placeholder` prop); a consumer cannot pass an accessible name through this component's typed props.
- **Minimum touch target size**: Not guaranteed by the component. `.fl-item-button` (source: filtered-list.css) sets only `padding: 0.5rem 0.6rem` with no explicit min-height/min-width, so the rendered hit area depends on content length and any consumer CSS overrides; the component itself does not enforce a 44×44px minimum.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| filtered-list-001 | render-input-field | Initial render | Text input field with placeholder "Filter…" is rendered |
| filtered-list-002 | filter-items | Query "apple" entered | Only items whose title, subtitle, details, or searchable extras contain "apple" (case-insensitive) are visible |
| filtered-list-003 | arrow-down-navigation | No highlight + ArrowDown pressed | First item becomes highlighted |
| filtered-list-004 | arrow-down-navigation | First item highlighted + ArrowDown pressed | Second item becomes highlighted |
| filtered-list-005 | arrow-down-navigation | Last item highlighted + ArrowDown pressed | Highlight remains on last item (does not wrap) |
| filtered-list-006 | arrow-up-navigation | First item highlighted + ArrowUp pressed | Highlight is cleared (index = -1) |
| filtered-list-007 | arrow-up-navigation | Second item highlighted + ArrowUp pressed | First item becomes highlighted |
| filtered-list-008 | enter-selection | Item highlighted + Enter pressed | onSelect callback is called with highlighted item |
| filtered-list-009 | escape-clears-highlight | Item highlighted + Escape pressed | Highlight is cleared |
| filtered-list-010 | reset-highlight-on-input-change | Item highlighted + user types in input | Highlight is reset to -1 |
| filtered-list-011 | clamp-highlight-when-visible-shrinks | Highlight on item 5, query changes to show 3 items | Highlight moves to item 3 (last visible) |
| filtered-list-012 | render-item-list | Items provided via props | The `<ul>` renders with role="listbox" and all visible items render as `<li>` children |
| filtered-list-013 | render-item-title | Item with getTitle callback, renderItem not provided | Title is rendered in fl-title element |
| filtered-list-014 | render-item-subtitle | Item with getSubtitle callback, renderItem not provided | Subtitle is rendered in fl-subtitle element |
| filtered-list-015 | clickable-items-when-onselect-provided | onSelect callback provided | Each item wraps its content in a button element |
| filtered-list-016 | mouse-hover-highlight | User moves mouse over item | Item becomes highlighted, aria-selected="true" |
| filtered-list-017 | scroll-active-item-into-view | Highlight moves to off-screen item | List container scrolls to show the highlighted item |
| filtered-list-018 | input-shows-highlighted-title | Item highlighted | Input value shows item title instead of query |
| filtered-list-019 | combobox-aria-expanded | Visible items exist | Input has aria-expanded="true" |
| filtered-list-020 | combobox-aria-expanded | No visible items | Input has aria-expanded="false" |
| filtered-list-021 | combobox-aria-activedescendant | Item highlighted | Input aria-activedescendant matches item ID |
| filtered-list-022 | unique-item-ids | Multiple items rendered | Each item has unique id: `{listId}-{itemId}` |
| filtered-list-023 | option-aria-selected | Item highlighted | Item has aria-selected="true" |
| filtered-list-024 | option-aria-selected | Item not highlighted | Item has aria-selected="false" |
| filtered-list-025 | onhighlight-callback | Highlight changes | onHighlightChange callback is invoked with new item or null |
| filtered-list-026 | empty-state-when-no-items | total === 0 | "No items." message is displayed instead of the list |
| filtered-list-027 | custom-empty-content | emptyContent provided + zero visible items while total > 0 | Custom emptyContent is rendered instead of the default no-matches message |
| filtered-list-028 | render-footer | footer prop provided | Footer is rendered as last list item |
| filtered-list-029 | wrap-input-in-form | Initial render | Input is wrapped in `<form role="search">` |
| filtered-list-030 | prevent-form-submission | Enter pressed on input, any highlight state | Form submission is prevented via the form's onSubmit handler regardless of whether an item is highlighted |
| filtered-list-031 | autofill-prevention | Input rendered | noAutofillProps applied to prevent browser autofill |
| filtered-list-032 | autofocus-on-mount | autoFocus={true} prop | Input receives focus on mount |
| filtered-list-033 | escape-clears-highlight | Escape pressed with no item highlighted | No highlight change occurs; default action is not prevented (edge case) |
| filtered-list-034 | render-item-details | Item with getDetails callback, renderItem not provided | Details are rendered in fl-details element |
| filtered-list-035 | custom-item-render | renderItem provided | `renderItem(item)` return value is rendered instead of the default title/subtitle/details layout |
| filtered-list-036 | arrow-keys-noop-when-no-items | No visible items, ArrowDown pressed | Default browser behavior is not prevented (no e.preventDefault call); no highlight change occurs |
| filtered-list-037 | default-no-matches-message | Query yields zero visible items, total > 0, no emptyContent | List's only item is the literal text `No matches for "{query}".` |
| filtered-list-038 | item-role-option | Items rendered | Each `<li>` has role="option" |
| filtered-list-039 | enter-selection | Enter pressed with no item highlighted | onSelect is not called; form submission is still prevented by the form wrapper (see prevent-form-submission) |

## Edge Cases

- **Empty item list** (total === 0): Component displays "No items." text and does not render the list element. No keyboard navigation occurs (see **empty-state-when-no-items**).
- **No visible items after filter** (total > 0, visible.length === 0): Empty state message is displayed — custom emptyContent if provided, otherwise the default `No matches for "{query}".` message (see **default-no-matches-message**, **custom-empty-content**).
- **Query is empty string or only whitespace**: Filtering is cleared; all items are visible. Input shows the query text, not a highlighted item's title, until an item is highlighted via keyboard or mouse.
- **Highlight index exceeds visible array**: When visible.length shrinks, highlightedIndex is automatically clamped to the last visible index or -1 if empty (see **clamp-highlight-when-visible-shrinks**).
- **Keyboard navigation with no visible items**: Arrow keys, Enter, and Escape do nothing; the handler returns early without calling preventDefault (see **arrow-keys-noop-when-no-items**).
- **Mouse hover while item is already highlighted via keyboard**: Hover changes highlight to the hovered item; onHighlightChange is called.
- **Escape when no item is highlighted**: No action; default is not prevented.
- **Enter when no item is highlighted**: onSelect is not called and the input's own keydown handler does not call preventDefault; the form's onSubmit still prevents the browser's default submission unconditionally (see **enter-selection**, **prevent-form-submission**).
- **Rapid query changes**: onHighlightChange is only invoked when the resolved highlighted item's reference actually changes between renders, not on every render — tracked via a ref, not a timer, so this is reference-equality change detection rather than debouncing.
- **scrollIntoView unavailable**: Component checks `typeof el.scrollIntoView === 'function'` before calling; if unavailable, the item is not scrolled into view but navigation continues.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `items` | `readonly T[]` | required | The full (unfiltered) item array; its length is `total`. |
| `getId` | `(item: T) => string` | required | Callback to get a unique ID for each item. |
| `getTitle` | `(item: T) => string \| undefined \| null` | required | Callback to get title text for each item; also searched by the default matcher. |
| `getSubtitle` | `(item: T) => string \| undefined \| null` | undefined | Callback to get subtitle text for each item; also searched by the default matcher. |
| `getDetails` | `(item: T) => string \| undefined \| null` | undefined | Callback to get details text for each item; also searched by the default matcher. |
| `getSearchableExtras` | `(item: T) => readonly (string \| undefined \| null)[]` | undefined | Extra strings searched alongside title/subtitle/details by the default matcher. |
| `match` | `(item: T, queryLower: string) => boolean` | default matcher (case-insensitive substring, see **filter-items**) | Overrides the default matcher entirely; receives the item and the already-lower-cased, trimmed query. |
| `initialQuery` | `string` | `""` | Initial value of the query/input text. |
| `placeholder` | string | "Filter…" | Placeholder text for the input field |
| `className` | string | undefined | Optional CSS class name to apply to the root element (appended to "fl-root") |
| `autoFocus` | boolean | false | Whether the input field should receive focus on mount |
| `renderItem` | `(item: T) => ReactNode` | undefined | Optional custom render function for item content; if provided, overrides title/subtitle/details rendering (see **custom-item-render**) |
| `onSelect` | `(item: T) => void` | undefined | Callback invoked when an item is selected via Enter or click; makes items clickable buttons if provided |
| `onHighlightChange` | `(item: T \| null) => void` | undefined | Callback invoked when the highlighted item changes; receives the highlighted item or null |
| `footer` | ReactNode | undefined | Optional element to render as the last list item |
| `emptyContent` | ReactNode | undefined | Optional custom message shown when filtering yields zero visible items while `total > 0`; has no effect when `total === 0` (see **default-no-matches-message**, **custom-empty-content**) |

## Deep Linking

Not applicable: FilteredList is a form-like UI component without a standalone URL or navigation pattern. Deep linking is handled by the consuming application if needed.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `placeholder` | "Filter…" | Input field placeholder; customizable via props |
| `empty.no-items` | "No items." | Shown when total === 0 |
| `empty.no-matches` | "No matches for "{query}"." | Shown when filter returns zero results; customizable via emptyContent prop |

The default filter match lower-cases both the query and each searched field using the platform's default (locale-sensitive) case folding (see **filter-items**); this is appropriate for search-as-you-type but is not a substitute for a linguistically exact comparison, and no invariant-culture-insensitive call is used or recommended for this user-facing text.

## Accessibility Options

- **Reduce Motion**: Not applicable — `scrollIntoView` is called with `{ block: 'nearest' }` and no `behavior` option, so the browser positions the item instantly (the default `behavior: 'auto'`) rather than animating the scroll. There is no motion for a reduced-motion preference to suppress.
- **Increase Contrast**: Component inherits contrast from CSS classes (fl-input, fl-item--active, etc.); no specific component-level support.
- **Differentiate Without Color**: Component uses aria-selected and classes (fl-item--active) to indicate state; CSS implementation should not rely on color alone per WCAG 2.1 AA.

## Feature Flags

Not implemented in source. Component does not have feature flag support.

## Analytics

Not implemented in source. Component does not emit analytics events; tracking is the responsibility of the consuming application via callbacks (onSelect, onHighlightChange).

## Privacy

- **Data collected**: None. Component does not collect, store, or transmit user data.
- **Storage**: No data is persisted by this component.
- **Transmission**: No data is transmitted beyond the host application's own analytics or backend systems (if connected by the consumer).
- **Retention**: Not applicable; no data is retained by this component.

## Logging

Not implemented in source. Component does not emit log messages; logging is the responsibility of the consuming application.

## Platform Notes

- **React/Web**: Component is implemented as a React functional component using hooks (useState, useEffect, useLayoutEffect, useId, useRef). The filtering logic is delegated to the custom `useFilteredList` hook. Styling is applied via CSS class names (fl-*). Component is marked `'use client'` for Next.js client-side rendering. See `/packages/web/packages/controls/src/filtered-list/FilteredList.tsx` and `/useFilteredList.ts` for implementation.
- **SwiftUI**: Use `.searchable(text:)` on the list to provide the filtered input field — the platform's native filter-as-you-type control — bound to a query `@State`. Track the highlighted item in a separate `@State`; do not conflate it with `List` selection, since highlight and selection are distinct concepts in this component. Handle ArrowUp/ArrowDown/Enter/Escape via the `onKeyPress` modifier (not `onKeyDown`, which does not exist in SwiftUI). Use `ScrollViewReader` with `scrollTo` to implement scroll-into-view when the highlight moves. Respect the user's text-size preference via `@Environment(\.dynamicTypeSize)`, the modern replacement for the deprecated `sizeCategory`.
- **Compose**: Start from TextField and LazyColumn composition. Use mutableStateOf for query and highlighted index, kept separate from any selection concept. Implement keyboard navigation via KeyEvent handling and Key.DirectionUp/Key.DirectionDown. Use LazyListState with layoutInfo to implement scroll-into-view behavior. Use Modifier.semantics to set ARIA-like roles and state. Apply Material Design 3 spacing and typography tokens from the theme for appearance.
- **AppKit / UIKit**: For AppKit, use NSSearchField for the input and NSTableView for the list; bind the search field's stringValue to filter the table's data source. The field editor intercepts NSResponder keyDown events before they reach the window, so implement arrow/enter/escape handling via NSTextFieldDelegate's `control(_:textView:doCommandBy:)` rather than overriding keyDown. Track the highlighted row in a separate property, not the table's selection, since highlight and selection are distinct concepts here. For UIKit (iOS), use UISearchController or a custom UISearchBar with UITableViewController; use UITableViewDelegate's didHighlightRowAt (not didSelectRowAt) to mirror the highlight-vs-selection distinction, and UITableView's scrollToRow(at:at:animated:) for scroll-into-view. Apply UIAccessibilityElement roles for accessibility.
- **WinUI 3**: Use `AutoSuggestBox` — the native filter-as-you-type control — for the input instead of a hand-built TextBox, binding its text-changed event to update the filtered item source. Track the highlighted item in a separate property rather than a ListView's SelectedIndex, since highlight and selection are distinct concepts. Implement arrow-key handling via the PreviewKeyDown event, checking for VirtualKey.Up/VirtualKey.Down. Use FrameworkElement.UpdateLayout with ScrollIntoView for scroll-into-view behavior. Apply AutomationProperties (Name, ControlledBy, ItemStatus) to mirror the ARIA roles and aria-selected state.

## Design Decisions

**Decision**: The input is wrapped in a `<form role="search">`.
**Rationale**: This addresses a Safari iOS 26 autofill scoping issue: without a form ancestor, Safari classifies an orphan input field against the entire document and offers the user's contact card as an autofill suggestion, which is undesired. The form is a plain block in `.fl-root`'s column flex and has no visual impact on layout; onSubmit prevents form submission since Enter is already handled by the input's onKeyDown.
**Approved**: pending

**Decision**: onHighlightChange is tracked by item reference, not index, and the callback itself is held in a ref.
**Rationale**: Consumers commonly pass an inline callback; depending on it directly would re-fire the effect on every parent render. Holding the callback in a ref and comparing the resolved highlighted item by reference means the callback fires only when the actual item reference changes — this is reference-equality change detection, not debouncing (no timer is involved) — reducing unnecessary invocations.
**Approved**: pending

**Decision**: ArrowUp on the first highlighted item clears the highlight (index = -1) rather than wrapping to the last item.
**Rationale**: This lets the user escape the list via keyboard and return to the query/input state, rather than cycling back into the list.
**Approved**: pending

**Decision**: Highlight state is local to the component, and the highlighted item's title replaces the query text in the input while highlighted.
**Rationale**: This gives immediate visual feedback about which item Enter would select.
**Approved**: pending

**Decision**: Items are rendered as clickable buttons only when onSelect is provided; without it, items are static (non-button) list content.
**Rationale**: This lets the component serve display-only scenarios where selection is not needed, without forcing button semantics on non-interactive content.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | partial | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | failed | Internationalization |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on the source: the `combobox`/`listbox`/`option` roles, `aria-selected`/`aria-expanded`/`aria-activedescendant`, and full keyboard handling in `FilteredList.tsx` (screen-reader-support, keyboard-navigable, semantic-markup); `.fl-item-button`'s padding-only sizing and the `rem`-based font sizing in `filtered-list.css`, which scale with browser zoom but aren't verified against OS-level text-size settings (touch-target-size, dynamic-type-support); the hardcoded `"Filter…"`, `"No items."`, and `"No matches for…"` strings and the locale-sensitive `toLowerCase()` substring match in `FilteredList.tsx`/`useFilteredList.ts` (string-externalization, no-hardcoded-strings, unicode-support); `.fl-item-button`'s hardcoded `text-align: left` in `filtered-list.css`, which does not adapt for RTL locales (rtl-layout-support); and the component's plain JSX text rendering plus its pure client-side string comparison, with no `dangerouslySetInnerHTML` or `eval` of user input (input-sanitization). `separation-of-concerns` is `passed` because the filtering logic lives entirely in the `useFilteredList` hook, leaving `FilteredList.tsx` only keyboard/highlight view state; `unit-test-coverage` is `passed` because `FilteredList.test.tsx` and `useFilteredList.test.ts` exercise both the component and its hook directly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; added item-role-option and default-no-matches-message requirements; clarified arrow-down non-wrapping, the renderItem signature, and default filter-match semantics (case-insensitive substring across title/subtitle/details/searchable-extras, with locale-sensitive lower-casing noted); fixed the focus-management and touch-target-size contradictions; corrected the Reduce Motion claim and the "debounced" terminology; corrected SwiftUI (.searchable, onKeyPress, dynamicTypeSize), AppKit (doCommandBy:), and WinUI 3 (AutoSuggestBox) platform notes and kept highlight distinct from selection throughout; reformatted Design Decisions to the Decision/Rationale/Approved form; rebuilt the Compliance table with canonical checks; split and added conformance test vectors for coverage gaps |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Fix Reduce Motion accessibility guidance; keep label accessibility gap marker |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from React source |
