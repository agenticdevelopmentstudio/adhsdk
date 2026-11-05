---
id: 88dc87c9-8058-446d-9513-acfa618c950f
title: Search Dialog
domain: adhsdk://recipes/search-dialog
type: ingredient
version: 1.2.2
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Modal dialog component for searching and selecting from indexed entries,
  with keyboard navigation and visual result preview.
platforms:
- typescript
- web
tags:
- search
- dialog
- modal
- form
depends-on: []
related:
- adhsdk://recipes/dialog
- adhsdk://recipes/search-dialog-connected
references:
- https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html
approved-by: ''
approved-date: ''
---

# Search Dialog

## Overview

Search Dialog is a modal component that presents a full-screen search interface for discovering and selecting items from an indexed collection. It displays a text input field, live search results grouped by category, and supports both keyboard and pointer interaction. The component is designed for documentation and knowledge base search on the web platform.

## Behavioral Requirements

- **closed-by-default**: The component MUST NOT render to the DOM when the `open` prop is `false`. The entire component tree MUST return `null`.
- **open-as-modal**: When the `open` prop is `true`, the component MUST render as a modal dialog with `role="dialog"` and `aria-modal="true"` on the root container.
- **dismissible-backdrop**: The component MUST render a full-screen backdrop element. Clicking the backdrop MUST invoke the `onClose` callback.
- **focus-input-on-open**: When the `open` prop transitions from `false` to `true`, the input field MUST receive focus once the dialog has rendered. (See **requestAnimationFrame for focus** under Design Decisions for the timing mechanism.)
- **reset-search-state-on-open**: When the `open` prop transitions from `false` to `true`, the component MUST reset the search state to its initial values: empty query, no results, and `state.selectedIndex` reset to `0` — the same value the state starts at and that `setQuery` also resets to on every keystroke, not an unselected/`-1` state. Because the results section only renders when `state.query` is truthy, no row is visibly highlighted right after reset, but the first ranked result becomes pre-selected the instant any results exist, even before an arrow key is pressed.
- **input-row-with-search-icon**: The input row MUST render as a form element containing a search icon (magnifying glass SVG) and an input field with placeholder text. (For the form's `role="search"`, see **search-role-on-form**.)
- **escape-hint**: The input row MUST display a keyboard hint showing "Esc" to indicate the escape key can dismiss the dialog.
- **placeholder-prop**: The component MUST accept an optional `placeholder` prop. If not provided, it MUST default to `"Search documentation..."`.
- **escape-dismisses**: When the user presses the Escape key in the input field, the component MUST immediately invoke `onClose()`.
- **enter-selects-highlighted-result**: When the user presses Enter in the input field, if `state.selectedIndex` is a valid index into `state.results` (the flat, ungrouped, rank-ordered top-20 array), the component MUST invoke `onSelect()` with `state.results[state.selectedIndex]`. If no result is selected, Enter MUST have no other effect. Enter never submits the form (see **prevent-form-submission**). This is rank order, not the grouped-by-section render order used for the highlight — see **highlight-selected-result** and the edge case **Highlight and Enter target can diverge**.
- **delegate-other-keys**: When the user presses any key other than Escape or Enter, the component MUST delegate handling to `state.handleKey(e)`.
- **update-query-on-input**: As the user types in the input field, the component MUST update the search state by calling `state.setQuery(e.target.value)` for each change event.
- **show-results-only-when-querying**: The results section MUST only render when `state.query` is truthy (non-empty string).
- **limit-results-to-twenty**: The component MUST slice results to display at most 20 entries from `state.results`.
- **group-results-by-section**: The component MUST group the top 20 results by `entry.section`. Entries without a section MUST be grouped under `"other"`. Section order follows first appearance among the top 20 results, not alphabetical or any other sort.
- **translate-section-labels**: For each section, the component MUST display the label from `sectionLabels[section]` if provided, otherwise MUST display the section key as-is.
- **empty-state-when-no-results**: When `state.query` is truthy but no results exist (top 20 is empty), the component MUST display a `No results for "{query}"` message.
- **result-title-and-summary**: Each result MUST display `entry.frontmatter.title`. If `entry.frontmatter.summary` exists, it MUST also be displayed below the title.
- **result-as-button**: Each result MUST be rendered as a `<button>` element with `type="button"`. Clicking a result MUST invoke `onSelect(entry)`.
- **highlight-selected-result**: The row at flat position `state.selectedIndex` within the results as GROUPED by section (see **group-results-by-section**) MUST be visually distinguished by applying the `awt-search-dialog__result--selected` CSS class modifier. Because grouping reorders results by section before this position is counted, the highlighted row is not necessarily `state.results[state.selectedIndex]` — see the edge case **Highlight and Enter target can diverge**.
- **stable-result-identity**: Each rendered result MUST derive a stable identity from `entry.slug`, so reconciliation stays correct if the same entries reorder or reappear across renders. (Implemented as the React `key` prop; see **Slug as React key** under Design Decisions.)
- **prevent-form-submission**: The search form wrapper MUST have an `onSubmit` handler that calls `e.preventDefault()`, so an implicit form submission never navigates the page.
- **search-role-on-form**: The form element containing the input field MUST have `role="search"` to declare its semantic purpose.
- **suppress-autofill-suggestions**: The input field MUST NOT trigger the browser's autofill suggestion UI (for example, iOS Safari's "AutoFill Contact" prompt). (See **Form wrapper for autofill suppression** under Design Decisions for the mechanism.)

## Appearance

- **Corner radius**: Not applicable — dialog uses platform default or stylesheet-driven radius; component does not hardcode corner values.
- **Padding**: Controlled via CSS classes (`awt-search-dialog__panel`, `awt-search-dialog__input-row`); not specified in source.
- **Font**: Controlled via CSS classes; not specified in source.
- **Background**: Controlled via CSS classes; source does not specify hardcoded values.
- **Foreground/Text**: Controlled via CSS classes; source does not specify hardcoded values.
- **Border**: Not specified in source code.
- **Shadow**: Not specified in source code.
- **Icon**: Search icon is rendered as inline SVG with `stroke="currentColor"` and `strokeWidth={2}`, allowing CSS-driven theming.

## States

| State | Appearance change |
|-------|------------------|
| Closed (`open: false`) | Component not rendered; does not appear in DOM. |
| Open (empty query) | Input field focused, results section not shown. |
| Open (with query, results found) | Results grouped by section are visible; selected result highlighted. |
| Open (with query, no results) | "No results for "{query}"" message displayed. |
| Result selected (default or via keyboard) | Result button receives `awt-search-dialog__result--selected` class. `selectedIndex` starts at, and every query change resets it to, `0`, so the top-ranked result is pre-selected as soon as results exist — arrow keys move the selection from there. |
| Result hovered | Controlled by CSS; source does not specify hover behavior. |

## Accessibility

- **Role/trait**: Dialog (`role="dialog"`); form with search role (`role="search"`); results are buttons (`type="button"`).
- **Label requirements**: Input has `aria-label="Search"`. Section headings and result buttons derive meaning from text content; no explicit ARIA labels on results.
- **Announce state changes**: The component does not implement live region announcements. Result count and selected result changes are not communicated to screen reader users as the user navigates results or performs searches; the results container carries no `aria-live` or `aria-atomic` attributes in the source.
- **Minimum tap target**: Not specified in source; result buttons and input field target sizes are stylesheet-driven. WCAG 2.5.8 Target Size (Minimum, Level AA) requires 24×24 CSS px; WCAG 2.5.5 Target Size (Enhanced, Level AAA) requires 44×44 CSS px. Platform guidance: 44×44pt minimum on iOS, 48×48dp on Android.
- **Keyboard navigation**: Fully keyboard operable. Input accepts focus; arrow keys (via `state.handleKey`) navigate results; Enter selects; Escape dismisses.
- **Modal semantics**: `aria-modal="true"` tells assistive technology that content outside the dialog is inert; it does not by itself trap focus. The source implements neither a focus trap nor focus restoration to the previously focused element on close (see **Announce state changes** for the related screen-reader gap). Backdrop click and Escape dismiss the dialog (see **dismissible-backdrop**, **escape-dismisses**).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| search-dialog-001 | closed-by-default | `open: false` | Component returns `null`; nothing renders. |
| search-dialog-002 | open-as-modal | `open: true` | Root div has `role="dialog"` and `aria-modal="true"`. |
| search-dialog-003 | dismissible-backdrop | `open: true`, click backdrop | `onClose()` callback is invoked. |
| search-dialog-004 | focus-input-on-open | `open: false` → `true` | Input field is focused after the dialog renders (implementation defers via `requestAnimationFrame`; see Design Decisions). |
| search-dialog-005 | reset-search-state-on-open | `open: false` → `true` | Search state is reset to its initial values: query cleared, no results, `state.selectedIndex` reset to `0` (not `-1`) — nothing is visibly highlighted only because the results section is empty until a query is typed. |
| search-dialog-006 | input-row-with-search-icon | `open: true` | Form renders containing the SVG search icon and the input field (form's `role="search"` verified in search-dialog-032). |
| search-dialog-007 | escape-hint | `open: true` | Keyboard hint element displaying "Esc" is rendered. |
| search-dialog-008 | placeholder-prop | `open: true`, no `placeholder` prop | Input field displays "Search documentation..." placeholder. |
| search-dialog-009 | placeholder-prop | `open: true`, `placeholder: "Find items"` | Input field displays "Find items" placeholder. |
| search-dialog-010 | escape-dismisses | `open: true`, user presses Escape in input | `onClose()` is invoked immediately. |
| search-dialog-011 | enter-selects-highlighted-result | `open: true`, result selected, user presses Enter | `onSelect(selectedEntry)` is invoked; page does not navigate. |
| search-dialog-012 | enter-selects-highlighted-result | `open: true`, `state.selectedIndex: -1` (an out-of-range value the component's own reset/`setQuery` never produce — `state.selectedIndex` otherwise starts at, and resets to, `0` — exercised here as a defensive bounds check), user presses Enter | No callback is invoked; page does not navigate. |
| search-dialog-013 | delegate-other-keys | `open: true`, user presses ArrowDown | `state.handleKey(e)` is called with the keyboard event. |
| search-dialog-014 | update-query-on-input | `open: true`, user types "test" | `state.setQuery()` is called for each keystroke; input value updates. |
| search-dialog-015 | show-results-only-when-querying | `open: true`, `state.query: ""` | Results section is not rendered. |
| search-dialog-016 | show-results-only-when-querying | `open: true`, `state.query: "docs"` | Results section is rendered (or empty state if no results). |
| search-dialog-017 | limit-results-to-twenty | `open: true`, 50 results in `state.results` | Only top 20 results are processed and displayed. |
| search-dialog-018 | group-results-by-section | `open: true`, results with sections `["guides", "api", "api", "guides"]` | Results render as two section groups, in first-occurrence order: `guides`, then `api`. |
| search-dialog-019 | group-results-by-section | `open: true`, result without section property | Result is grouped under `"other"`. |
| search-dialog-020 | translate-section-labels | `open: true`, `sectionLabels: { guides: "How-To Guides" }` | Section displays as "How-To Guides", not "guides". |
| search-dialog-021 | translate-section-labels | `open: true`, `sectionLabels: {}`, section is "api" | Section displays as "api" (no translation provided). |
| search-dialog-022 | empty-state-when-no-results | `open: true`, `state.query: "xyzabc"`, no results | Message displays: `No results for "xyzabc"`. |
| search-dialog-023 | result-title-and-summary | `open: true`, results present | Each result displays `entry.frontmatter.title`. |
| search-dialog-024 | result-title-and-summary | `open: true`, result with summary | Result displays both title and summary below it. |
| search-dialog-025 | result-title-and-summary | `open: true`, result without summary | Result displays title only; summary section not rendered. |
| search-dialog-026 | result-as-button | `open: true`, result visible | Result is a `<button type="button">` element. |
| search-dialog-027 | result-as-button | `open: true`, user clicks result | `onSelect(entry)` is invoked with that result's entry. |
| search-dialog-028 | highlight-selected-result | `open: true`, `state.selectedIndex: 2` | The row at grouped render position 2 (not necessarily `state.results[2]`) has class `awt-search-dialog__result--selected`. |
| search-dialog-029 | highlight-selected-result | `open: true`, `state.selectedIndex: 999` (≥ number of rendered results) | No result is highlighted. |
| search-dialog-030 | stable-result-identity | `open: true`, results rendered, then re-rendered with the same entries reordered | Each result's identity stays tied to its `slug` rather than its position (implementation detail: React `key`; verified via reconciliation, not a DOM attribute). |
| search-dialog-031 | prevent-form-submission | `open: true`, user presses Enter with form focused | Form's `onSubmit` prevents default; no page navigation. |
| search-dialog-032 | search-role-on-form | `open: true` | Form element has `role="search"`. |
| search-dialog-033 | suppress-autofill-suggestions | `open: true` | Input field carries the attributes needed to suppress the browser's autofill suggestion UI (`noAutofillProps` in source; see Design Decisions). |
| search-dialog-034 | enter-selects-highlighted-result, highlight-selected-result | `open: true`, ranked results `[A(guides), B(api), C(api), D(guides)]` (grouped render order: guides → A, D; api → B, C), `state.selectedIndex: 1` | Row D (grouped position 1) is highlighted, but Enter invokes `onSelect(B)` — `state.results[1]` in rank order — not `onSelect(D)`; the highlighted row and the Enter target diverge whenever sections interleave. |

## Edge Cases

- **Empty or null query**: When `state.query` is empty string or not set, results section does not render. Results are generated only when query is truthy. **MUST**.
- **Zero results from search**: When top 20 results array is empty but query is truthy, "No results" message is shown. **MUST**.
- **Large result set**: Component slices to top 20 results; remaining results are discarded and never rendered. Implementor should verify that `state.results` provides results in descending relevance order. **MUST**.
- **Out-of-bounds selectedIndex**: If `state.selectedIndex` is greater than or equal to the number of rendered results, no result is highlighted. Source does not bounds-check selection. Caller is responsible for keeping index in range. **MUST**.
- **Selection is a cursor, not an opt-in pick**: `state.selectedIndex` starts at `0` and both `reset()` and `setQuery()` set it back to `0` — it is never set to `-1` or otherwise cleared by the source. So typing a query and pressing Enter with no arrow key selects and opens the top-ranked result; a consumer or port that models "no selection" after reset/query-change as an explicit empty state (e.g. `-1`) diverges from the source, which always has a selection cursor once results exist.
- **Highlight and Enter target can diverge**: The highlight is applied to the row at flat position `state.selectedIndex` in the GROUPED (by-section) render order, while Enter invokes `onSelect` with `state.results[state.selectedIndex]` in the flat RANK order the results arrived in. These are the same entry only when the results in front of `state.selectedIndex` are not split across sections. Once sections interleave (as in **group-results-by-section**'s own example, `["guides", "api", "api", "guides"]`), the two orders diverge and the highlighted row and the Enter target are different entries (see search-dialog-034). **MUST** be treated as two independent index spaces, not one shared "selected result."
- **Rapid open/close toggle**: Each `open: false → true` transition resets the search state (see **reset-search-state-on-open**). Multiple rapid toggles will reset state multiple times. Intended behavior per source comment. **MUST**.
- **Focus loss and regain**: When dialog closes and `open` prop changes to `false`, component returns `null`. Focus management on reopening is handled per **focus-input-on-open**. **MUST**.
- **Missing entry.slug**: Result rendering derives each item's stable identity from `entry.slug` (see **stable-result-identity**). Caller MUST provide a valid, unique slug for every entry; a missing or duplicate slug is a caller precondition violation, not a supported input.
- **Missing entry.frontmatter.title**: Result displays `entry.frontmatter.title` without defensive checks. If title is missing, undefined or null renders as empty string. **MUST**.
- **Missing section property**: Entries without `entry.section` are grouped under `"other"`. This is explicit behavior per source code. **MUST**.
- **Clicking a result while pressing Enter**: The result button's `onClick` and the input's `onKeyDown` are handlers on different elements. The source implements no cross-element ordering guarantee between them beyond whatever the browser's own event dispatch does; this recipe makes no claim about which fires first.
- **Input type not text**: Source hardcodes `type="text"` on the input element. Caller cannot override input type. **MUST**.
- **Null state object**: Source assumes the `state` prop is always provided and calls its methods directly, without null checks. Caller MUST supply a valid `SearchState` instance; passing `null`/`undefined` is a precondition violation the component does not guard against.
- **Section label not a string**: `sectionLabels` values should be strings. If a value is an object or non-string, it will render via string coercion. Behavior is undefined for non-string values. **SHOULD** provide strings.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `open` | `boolean` | (required) | Controls whether the dialog is rendered and visible. |
| `onClose` | `() => void` | (required) | Callback invoked when user dismisses the dialog (Escape key or backdrop click). |
| `state` | `SearchState` | (required) | Mutable state object managing query, results, and selection. Must implement `reset()`, `setQuery(q)`, `handleKey(e)` methods. |
| `onSelect` | `(entry: SiteEntry) => void` | (required) | Callback invoked when user selects a result. |
| `sectionLabels` | `Record<string, string>` | `{}` | Optional mapping of section keys to display labels. Untranslated section keys appear as-is. |
| `placeholder` | `string` | `"Search documentation..."` | Placeholder text shown in the input field. |

## Deep Linking

Not applicable: component is a modal dialog overlay and does not define its own URL routes or deep links. Deep linking strategy is owned by the parent application that manages the `open` prop.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| aria-label | `"Search"` | Accessible label for the input field. |
| placeholder | `"Search documentation..."` | Default placeholder text in input field; can be overridden by `placeholder` prop. |
| empty-state | `No results for “{query}”` | Message shown when user has typed a query but no results are found. Includes user-entered query string. |
| escape-hint | `"Esc"` | Text displayed in keyboard hint showing how to close the dialog. |

Each string value is hardcoded in the component. To support multiple languages, accept a `strings` (or `labels`) prop mapping each key above to its localized text at the call site, rather than forking the component.

## Accessibility Options

- **Reduce Motion**: Not applicable. Dialog appears immediately without fade-in or transition. If `prefers-reduced-motion` is desired, CSS media query can suppress animations. Component itself does not check the setting.
- **Increase Contrast**: Not applicable. Text color and background contrast are stylesheet-driven. Component does not expose a contrast mode setting. Stylesheet can provide high-contrast variant via CSS media query or theme class.
- **Differentiate Without Color**: Visual distinction of the selected result is CSS-driven, via the `awt-search-dialog__result--selected` class, and may rely on color alone in the current stylesheet. The component does not implement a non-color marker itself. Stylesheet SHOULD add a non-color indicator (for example, a border or a checkmark) so the selected result stays visible without relying on color perception.

## Feature Flags

Not applicable: component does not include conditional logic for feature flags. Enable/disable at the call site by controlling the `open` prop.

## Analytics

| Event | Properties | When |
|-------|-----------|------|
| `search-dialog.opened` | `{}` | Dialog `open` prop transitions from `false` to `true`. |
| `search-dialog.closed` | `{ reason: "escape" \| "backdrop" }` | Dialog closes via Escape or backdrop click. |
| `search-dialog.query_changed` | `{ query: string, length: number }` | User types in the input field; `state.setQuery()` is called. |
| `search-dialog.results_shown` | `{ result_count: number, top_k: number }` | Results are rendered (top 20 are sliced); triggered when query is truthy. |
| `search-dialog.result_selected` | `{ slug: string, section: string, index: number }` | User selects a result via click or Enter. |
| `search-dialog.selection_navigated` | `{ from_index: number, to_index: number }` | User presses arrow key and `state.handleKey()` changes `selectedIndex`. |

Analytics emission is not implemented in the component source. The events above describe integration points a call site MAY wire up around `onClose`, `onSelect`, and `state` mutations — they document a possible data collection contract, not one the component enforces.

## Privacy

- **Data collected**: Query strings entered by the user. Result titles and summaries selected or viewed.
- **Storage**: Query and selection data live only in the caller-owned `SearchState` object, held in React state. No persistence to storage, cookies, or local cache.
- **Transmission**: The `SearchState` object is responsible for making search queries to a backend or index. Component itself does not transmit data; `state.setQuery()` and `state.results` handle the exchange. Call site MUST ensure search backend is privacy-compliant.
- **Retention**: `state` is owned and held by the caller, not by `SearchDialog` — closing the dialog (`open: false`) unmounts the component but does not destroy the caller's `SearchState` instance. The component itself resets query and selection each time `open` transitions from `false` to `true` (see **reset-search-state-on-open**); it keeps no history of its own.

Note: This component is a UI container. Privacy compliance depends entirely on the `SearchState` implementation and the backend search service. The component itself is privacy-neutral.

## Logging

Subsystem: `awt` | Category: `SearchDialog`

| Event | Level | Message |
|-------|-------|---------|
| Dialog opened | debug | `SearchDialog: Opened; query reset.` |
| Query changed | debug | `SearchDialog: Query set to "{query}" (length: {count}).` |
| Results fetched | debug | `SearchDialog: {result_count} results; top 20 grouped into {section_count} sections.` |
| Result selected | info | `SearchDialog: Result selected: {slug} (section: {section}, index: {index}).` |
| Keyboard navigation | debug | `SearchDialog: Arrow key navigation; selected index now {index}.` |
| Dialog dismissed | debug | `SearchDialog: Dialog dismissed via {reason} (escape/backdrop).` |

Logging is not implemented in the component source. The events above describe suggested log points a call site or wrapper MAY add around open/close, query changes, and selection — they document a possible logging contract, not one the component enforces.

## Platform Notes

- **Web/React**: Source code is a React functional component using `useEffect` and `useRef` hooks. The input ref is managed to ensure focus on open. Component uses synthetic events (onChange, onKeyDown, onClick). CSS classes (`awt-search-dialog__*`) drive all styling and layout; no inline styles. The form element prevents iOS Safari autofill by containing the input in a form of its own (documented in source comment). Key implementation details: backdrop click triggers onClose; open prop state change gates the useEffect reset; selectedIndex highlighting is CSS class-based; results are sliced to top 20 before grouping.

- **SwiftUI**: Adapt using SwiftUI's `.searchable()` modifier combined with a `Sheet` for modal presentation. Use `@FocusState` to manage input focus on open. Implement keyboard navigation via `.onKeyPress()` or `onSubmit()`. Group results using a `List` with `Section`. Adapt selection highlighting by binding `selectedIndex` to row state. Replace CSS class modifiers with conditional view properties (e.g., `.background()` conditional on selection).

- **Compose**: Adapt using Compose's `Dialog` composable with `Modifier.fillMaxSize()` for backdrop. Use `BasicTextField` with `Material3` styling for the input. Implement result grouping with `LazyColumn` and section headers via `stickyHeader`. Keyboard navigation is handled by Compose's focus system and `onKeyEvent`. Selected result highlighting uses Compose state (`selectedIndex`). Meet Material Design 3 minimum touch target of 48dp for results and input field. Use Compose Material3's `Icon` composable for the search icon, sized to Material specifications.

- **AppKit / UIKit**: On UIKit, adapt using `UISearchController` or a custom modally-presented view controller, with the presentation providing the backdrop and dismissal. Manage focus transition to the search field on open via `becomeFirstResponder()`. Implement keyboard navigation (arrow keys, Enter, Escape) with `UIKeyCommand` on the presenting view controller — `UITableViewDelegate` does not receive key events. Group results using a sectioned `UITableView` or `UICollectionView` with section headers. Adapt the "No results" empty state to `UIContentUnavailableConfiguration` (iOS 17+) or a custom placeholder view. Replace CSS class modifiers with an `isSelected` flag driving cell appearance. On AppKit, adapt using `NSSearchField` inside an `NSPanel` or a sheet presented via `NSWindow.beginSheet(_:completionHandler:)`; handle Escape and arrow-key navigation in `NSResponder.keyDown(with:)`, group results in an `NSOutlineView` or `NSTableView` with section rows, and drive selection highlighting from `NSTableViewDelegate` row selection.

- **WinUI 3**: Adapt using `AutoSuggestBox` for the input field, presented inside a `ContentDialog` for modal presentation; `ContentDialog` provides the backdrop and dismisses on Escape automatically. Implement result grouping using `ListView.GroupStyle` with `CollectionViewSource` binding. Keyboard navigation (arrow keys) is handled by WinUI's focus engine together with `AutoSuggestBox`'s built-in suggestion list. Selected result highlighting is data-driven via `SelectedItem` binding and a `ControlTemplate` with an alternate style. Minimum touch target on WinUI is 40×40px; use `MinHeight="48"` and `MinWidth="48"` for results and input.

## Design Decisions

- **Top 20 results limit**
  **Decision**: Results are sliced to the first 20 entries (`state.results.slice(0, 20)`) before grouping.
  **Rationale**: Bounds DOM size for display performance while assuming the backing search state returns results in descending relevance order, keeping interaction smooth on large result sets (see **limit-results-to-twenty**). Implementors MUST ensure `state.results` is pre-sorted by relevance.
  **Approved**: pending

- **Reset on open, not on close**
  **Decision**: The search state is reset (`state.reset()`) when `open` transitions from `false` to `true`, not when it transitions from `true` to `false`.
  **Rationale**: `state` is a caller-owned object that persists for as long as the caller keeps it, independent of the dialog's own mount lifecycle. The reset effect depends only on `open` so that typing does not retrigger a reset on every keystroke — resetting on every state change would clobber the user's in-progress query, per the source comment. Resetting on open guarantees a clean slate each time the dialog reappears.
  **Approved**: pending

- **requestAnimationFrame for focus**
  **Decision**: Input focus is deferred to `requestAnimationFrame()` rather than called synchronously on open.
  **Rationale**: Deferring to the next animation frame ensures the input element has been painted to the DOM before focus is requested, since focusing an element before it has rendered can silently fail.
  **Approved**: pending

- **Form wrapper for autofill suppression**
  **Decision**: The input is wrapped in a `<form role="search">` element, not a `<div>`, with an `onSubmit` handler that calls `preventDefault()`.
  **Rationale**: Per the source comment, a field with no form ancestor is scoped for autofill against the whole document, so Safari classifies it from whatever else the page happens to say; giving the field a form of its own is what stopped iOS Safari's "AutoFill Contact" suggestion from appearing above the keyboard, measured on iOS 26 against a production chat input. `role="search"` preserves semantic intent, and `onSubmit` only blocks the navigation an implicit submit would trigger, since Enter is already handled by the input's `onKeyDown` (see **enter-selects-highlighted-result**, **prevent-form-submission**).
  **Approved**: pending

- **Slug as React key**
  **Decision**: Each result uses `entry.slug` as its list-reconciliation key (React's `key` prop) rather than the array index.
  **Rationale**: `entry.slug` is assumed to be a stable identifier per entry, so reconciliation stays correct if results reorder or the same entries reappear across renders (see **stable-result-identity**). This is a rendering-library detail, not a claim any other platform's list view is required to replicate.
  **Approved**: pending

- **Selected index highlighting via CSS class, not inline style**
  **Decision**: The selected result applies the `awt-search-dialog__result--selected` class modifier via a ternary; no inline styles are used for selection appearance.
  **Rationale**: Decouples visual design from component code and lets CSS drive appearance and theme variation (see **highlight-selected-result**).
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | partial | Privacy and Data |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Statuses rest on `SearchDialog.tsx`: keyboard handling (Escape, Enter, arrow-key delegation) and the ARIA attributes present in the source (`role="dialog"`, `aria-modal`, `role="search"`, `aria-label`) give keyboard-navigable and semantic-markup a pass; screen-reader-support and focus-management are partial because the source has no live-region announcements (see **Announce state changes**) and implements neither a focus trap nor focus restoration on close; touch-target-size is partial because sizing is stylesheet-driven and absent from the source; string-externalization fails because every user-facing string (placeholder, empty-state message, escape hint, aria-label) is a hardcoded literal in the component; unicode-support passes because result text renders through standard React text nodes with no encoding restriction; data-minimization passes because the only data handled is the query string the search needs; no-pii-in-logs is partial because logging is not implemented in the source, so the query-containing message template documented under Logging would need redaction if it were ever wired up; separation-of-concerns passes because selection/query state lives in the `useSearchState` model hook, entirely separate from `SearchDialog.tsx`'s rendering; and unit-test-coverage is partial — `SearchDialog.test.tsx`/`SearchDialogConnected.test.tsx` cover open/close, typing, and single-match Enter, but the only Enter test has a single match, so the grouped-highlight-vs-ranked-Enter divergence this revision documents (search-dialog-034) had no prior test vector.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-09-25 | Mike Fullerton | Highlight (grouped) vs Enter (ranked) index divergence documented; selectedIndex resets to 0, not -1. |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed every requirement to subject-only kebab-case and cross-referenced the duplicates it removed; corrected the focus-trap and WCAG tap-target claims in Accessibility; converted Design Decisions to the Decision/Rationale/Approved form and softened unsupported claims within them; rebuilt Compliance as canonical linked checks with partial status where the source can't confirm; corrected Platform Notes API names (WinUI 3, AppKit/UIKit, Compose) and added the missing AppKit mapping; fixed the localization empty-state quoting and its forking advice; reworded the caller-owned state's retention and reset rationale to remove the contradiction; marked Analytics and Logging as unimplemented documentation rather than a caller MUST contract; fixed edge-case bound precision and restated defect-flavored edge cases as caller preconditions; and linked the related dialog and search-dialog-connected recipes. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Clarify review marker with evidence criteria; relabel Platform Notes Windows bullet to WinUI 3; clarify "Not applicable" sections; remove implementation-specific language from Accessibility Options |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
