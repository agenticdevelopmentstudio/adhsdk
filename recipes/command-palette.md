---
id: 059093ee-8776-4e6a-b2a2-3fe1e20c2ee9
title: Command Palette
domain: adhsdk://recipes/command-palette
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Transient overlay dialog for keyboard-driven command execution over grouped
  items without internal filtering.
platforms:
- typescript
- web
tags:
- command-palette
- keyboard-navigation
- dialog
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Command Palette

## Overview

The Command Palette is a transient overlay dialog that presents a keyboard-navigable list of grouped commands. A user types in a search field to filter results (filtering is performed by the host, not the component), then navigates and selects items via keyboard or mouse. The palette does not persist state — it closes immediately after an item is selected, and reopening resumes no previous search. It is designed to answer the interaction "I know what I want by name, not by location."

### Props and Types

**`CommandPaletteProps`**

| Prop | Type | Required | Default |
|------|------|----------|---------|
| `open` | `boolean` | required | — |
| `onOpenChange` | `(open: boolean) => void` | required | — |
| `query` | `string` | required | — |
| `onQueryChange` | `(query: string) => void` | required | — |
| `groups` | `CommandGroup[]` | required | — |
| `ariaLabel` | `string` | required | — |
| `placeholder` | `string` | optional | `"Search…"` |
| `loading` | `boolean` | optional | `false` |
| `error` | `string \| null` | optional | `null` |
| `emptyLabel` | `string` | optional | `"No matches"` |
| `footer` | `React.ReactNode` | optional | `undefined` (no footer rendered) |

**`CommandGroup`**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | `string` | required | |
| `label` | `string` | required | Group heading text; rendered only when `items` is non-empty. |
| `items` | `CommandItem[]` | required | |

**`CommandItem`**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | `string` | required | |
| `label` | `string` | required | The line the user reads and picks. |
| `description` | `string` | optional | A second, dimmer line. |
| `badge` | `string` | optional | Short leading tag. |
| `hint` | `string` | optional | Right-aligned trailing text. |
| `icon` | `React.ReactNode` | optional | |
| `keywords` | `string` | optional | Matched by `filterCommandItems`; never rendered. |
| `onSelect` | `() => void` | required | Runs on Enter or click; the palette closes immediately after. |

## Behavioral Requirements

- **accept-open-prop**: Component MUST render the dialog when the `open` prop is `true`, and hide it when `open` is `false`.
- **open-change-on-dismiss**: Component MUST call `onOpenChange(false)` when the user dismisses the dialog — via Escape (delegated to the Dialog primitive, since the component adds no Escape handler of its own) or by selecting an item. When dismissal is triggered by selecting an item, `onOpenChange(false)` is called before the item's `onSelect()` callback runs.
- **display-query**: Component MUST display the value of the `query` prop in the search input field.
- **query-change-callback**: Component MUST call `onQueryChange(value)` when the user types in the search input field.
- **render-groups-in-order**: Component MUST render groups in the order provided; a group with zero items is dropped entirely, including its heading, while a group with one or more items renders both its heading and its items.
- **render-items-in-group-order**: Component MUST render items within each group in the order provided.
- **reset-highlight-to-first-item**: Component MUST highlight the first item in the flattened list (across all groups) when the dialog opens, and MUST reset the highlight to the first item whenever the set of displayed items changes (measured by comparing item IDs across all groups) or whenever the dialog transitions from `open: false` to `open: true`.
- **arrow-navigation**: Component MUST move the highlight up (ArrowUp) and down (ArrowDown) through the flattened list of items, wrapping around at the ends.
- **home-end-navigation**: Component MUST move the highlight to the first item on Home and to the last item on End.
- **run-on-enter**: Component MUST run the highlighted item's `onSelect` callback and close the dialog when Enter is pressed.
- **run-on-click**: Component MUST run an item's `onSelect` callback and close the dialog when the item is clicked.
- **update-highlight-on-hover**: Component MUST move the highlight to an item when the user hovers over it.
- **scroll-highlighted-item-into-view**: Component MUST scroll the highlighted item into view using the nearest scrolling behavior when it is off-screen.
- **display-loading-state**: Component MUST display a loading indicator and "Searching…" text below the item list when `loading` is `true`, without clearing the item list.
- **display-error-message**: Component MUST display the `error` prop as inline error text in the list area when `error` is not `null`.
- **display-empty-state**: Component MUST display the `emptyLabel` (default "No matches") when all groups are empty, the list is not loading, and `error` is `null`.
- **render-footer-when-provided**: Component MUST render the `footer` prop in a footer strip separated by a top border when `footer` is not `undefined`.
- **no-internal-filtering**: Component MUST NOT filter the groups or items provided; filtering is the host's responsibility.
- **truncate-long-text**: Component MUST truncate an item's `label` and `description` with a CSS ellipsis when they overflow their row, rather than wrapping or growing the row.
- **no-reserved-space-for-missing-icon-badge**: Component MUST NOT reserve layout space for an item's `icon` or `badge` when it is not provided.
- **focus-input-on-open**: Component MUST focus the search input when the dialog opens.
- **use-placeholder**: Component SHOULD display the `placeholder` prop (default "Search…") as the input field's placeholder text.

## Appearance

- **Corner radius**: 6px (from Tailwind's `rounded-md` on item buttons)
- **Padding**: Dialog content has no padding; internal sections own their own (input section: 12px vertical, 10px right, 12px left; item list: 8px; footer: 8px vertical, 12px horizontal)
- **Font**: Item text is 14px (text-sm), section labels are text-sm, footer is 12px (text-xs)
- **Background**: Dialog uses default modal overlay; item list background inherits from container; highlighted items show `apt-highlight/15` overlay; hover shows `apt-highlight/10`
- **Foreground/Text**: Primary text `apt-text`, muted text `apt-text-muted`, dimmed text `apt-text-dim`, section labels use muted color
- **Border**: Top border on input section (1px `apt-border`), top border on footer section (1px `apt-border`)
- **Shadow**: Delegated to Dialog primitive
- **Min/Max size**: Dialog max-width is 576px (`max-w-xl`); positioned at 12% from top; list max-height is 50vh with vertical scroll overflow; input uses padding-left 36px to accommodate leading icon

## States

| State | Appearance change |
|-------|------------------|
| Default | First item highlighted with semi-transparent highlight background |
| Highlighted | Current item — set via keyboard navigation or by hovering it (see **update-highlight-on-hover**) — shows `apt-highlight/15` background; other items show default |
| Hover | Hovering a non-highlighted item immediately moves the highlight to it; the item then shows the `apt-highlight/15` highlighted background |
| Loading | Loading indicator (spinner) and "Searching…" text appear below the item list; existing items remain visible |
| Error | Error message text appears in the list area with error styling |
| Empty | Empty state text (default "No matches") appears when no items are shown and not loading |

## Accessibility

- **Role**: The search input has `role="combobox"`; the item list container has `role="listbox"`; each group is a `role="group"` container; each item is a `<button>` element with `role="option"` (the explicit ARIA role overrides the button's implicit semantics for assistive tech).
- **Label requirements**: The `ariaLabel` prop MUST be provided; it labels the dialog (`DialogTitle`, visually hidden via `sr-only`), the combobox input (`aria-label`), and the listbox (`aria-label`). Each group's visible heading (rendered by `SectionLabel`) is marked `aria-hidden`, so sighted users see it but assistive tech does not; the group's accessible name instead comes from `aria-label={group.label}` on the `role="group"` container. Item labels are the button's text content.
- **Keyboard support**: All keyboard interactions (ArrowUp, ArrowDown, Home, End, Enter, Escape) are fully supported.
- **Announce state changes**: The combobox's `aria-activedescendant` tracks the currently highlighted option's id (unset when there is no current item); `aria-expanded="true"` is present on the input whenever the dialog is open (the input only renders while open); `aria-controls` connects the input to the listbox; `aria-autocomplete="list"` signals the combobox pattern.
- **Minimum tap target**: Items are buttons with padding `py-1.5 px-2` (approximately 24px tall × full width). This meets WCAG 2.5.8 Target Size (Minimum) at 24×24 CSS pixels, but not the 44×44pt HIG/Android touch-target size.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cp-001 | accept-open-prop | `open: false` | Dialog is not rendered or is hidden |
| cp-002 | accept-open-prop, focus-input-on-open | `open: true` | Dialog is visible and input receives focus |
| cp-003 | open-change-on-dismiss | User presses Escape | `onOpenChange(false)` is called |
| cp-004 | open-change-on-dismiss, run-on-enter | User selects an item via Enter | `onOpenChange(false)` is called, then item's `onSelect()` is called |
| cp-005 | display-query | `query: "test"` | Input field shows "test" |
| cp-006 | query-change-callback | User types "foo" in input | `onQueryChange("foo")` is called for each keystroke |
| cp-007 | render-groups-in-order | `groups: [{id: "g1", …}, {id: "g2", …}]` | Group headings appear in order g1, then g2 |
| cp-008 | render-groups-in-order | `groups: [{id: "g1", items: []}, {id: "g2", items: [{…}]}]` | Only g2 heading is rendered; g1 is dropped entirely |
| cp-009 | render-groups-in-order | Group with 0 items | Group heading is not rendered |
| cp-010 | render-groups-in-order | Group with 1+ items | Group heading is rendered |
| cp-011 | reset-highlight-to-first-item | Dialog opens with 3 items | First item is highlighted |
| cp-012 | reset-highlight-to-first-item | Item list changes from [A, B, C] to [X, Y] | Highlight moves to X (first of new list) |
| cp-013 | arrow-navigation | Highlight on item 1 of 3, press ArrowDown | Highlight moves to item 2 |
| cp-014 | arrow-navigation | Highlight on item 3 of 3, press ArrowDown | Highlight wraps to item 1 |
| cp-015 | arrow-navigation | Highlight on item 1 of 3, press ArrowUp | Highlight wraps to item 3 |
| cp-016 | home-end-navigation | Highlight on item 2, press Home | Highlight moves to item 1 |
| cp-017 | home-end-navigation | Highlight on item 1, press End | Highlight moves to item 3 |
| cp-018 | run-on-enter | Highlight on item with `onSelect`, press Enter | `onSelect()` is called and dialog closes |
| cp-019 | run-on-click | Item is visible and user clicks it | `onSelect()` is called and dialog closes |
| cp-020 | update-highlight-on-hover | Highlight on item 1, user hovers item 2 | Highlight moves to item 2 |
| cp-021 | scroll-highlighted-item-into-view | Highlight on item outside viewport | Item scrolls into view with nearest block align |
| cp-022 | display-loading-state | `loading: true`, items list populated | Spinner and "Searching…" appear below items; items remain visible |
| cp-023 | display-error-message | `error: "Network error"` | Error message displays in list area |
| cp-024 | display-empty-state | `groups: []`, `loading: false`, `error: null` | "No matches" (or custom `emptyLabel`) displays |
| cp-025 | render-footer-when-provided | `footer: <div>Help text</div>` | Footer strip renders at bottom with top border |
| cp-026 | no-internal-filtering | `groups` contain items whose labels do not contain "xyz"; `query: "xyz"` | Every provided item still renders; no client-side filtering occurs |
| cp-027 | reset-highlight-to-first-item | `open: true`, user selects item (closes), `open: true` again | Highlight resets to first item |
| cp-028 | truncate-long-text | Item with a `label`/`description` longer than the row width | Text is truncated with an ellipsis; the row does not wrap or grow |
| cp-029 | no-reserved-space-for-missing-icon-badge | Item with `icon: undefined`, `badge: undefined` | No empty space is rendered where the icon/badge would be |
| cp-030 | arrow-navigation | Exactly one item, press ArrowDown then ArrowUp | Highlight stays on the single item both times (wraps to itself) |
| cp-031 | display-error-message, display-loading-state | `loading: true` and `error: "Network error"` together | Both the error text and the loading indicator are visible |

## Edge Cases

- **Empty groups list**: When `groups: []`, the list displays the empty state — see **display-empty-state**.
- **All groups empty**: When every group has zero items, the list displays the empty state and no heading is ever rendered — see **render-groups-in-order**, **display-empty-state**.
- **Single item**: When exactly one item exists, ArrowUp and ArrowDown both wrap to the same item — see **arrow-navigation** (cp-030).
- **Loading with items**: When `loading: true` and items are present, both the items and the loading indicator are visible; the items are NOT replaced — see **display-loading-state**.
- **Error with items**: When `error` is set and items are present, both are visible — see **display-error-message**.
- **Error and loading together**: When both `error` and `loading` are truthy, both the error text and the loading indicator render, following the render order of the source — see **display-error-message**, **display-loading-state** (cp-031).
- **Null error state**: When `error` is explicitly `null`, no error text renders. When `error` is `undefined`, it defaults to `null` and no error renders — see **display-error-message**.
- **Query with no matching items**: If the host does not filter its groups and provides `query: "xyz"` with items that don't match it, every item still renders — this is source behavior, not the component's responsibility — see **no-internal-filtering** (cp-026).
- **Very long labels**: Item labels and descriptions are truncated with CSS — see **truncate-long-text**.
- **Icon or badge absent**: When `icon` or `badge` are undefined, no space is reserved for them — see **no-reserved-space-for-missing-icon-badge**.
- **Reopening resets highlight, not query**: When `open` transitions from `true` to `false` to `true`, the highlight resets to the first item (see **reset-highlight-to-first-item**), but `query` remains as the host left it — it is not cleared by the component.

## Configuration

Not applicable: CommandPalette receives all configuration through props (`CommandPaletteProps`) and does not have external configuration options.

## Deep Linking

Not applicable: CommandPalette is an overlay component without its own route or deep-link URI. Deep linking to a command would be the host's responsibility (routing to the appropriate section of the app and triggering the selected command).

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| placeholder | "Search…" | Input field placeholder when query is empty |
| emptyLabel | "No matches" | Empty state message when no items are shown |
| loadingLabel | "Searching…" | Loading indicator label; hardcoded in source |

These strings are passed as props or have hardcoded defaults in the source. Localization is the host's responsibility.

## Accessibility Options

- **Reduce Motion**: Not applicable; CommandPalette does not use transitions or animations that respond to prefers-reduced-motion.
- **Increase Contrast**: Not applicable; CommandPalette does not have a built-in contrast mode; host may apply custom CSS to meet contrast requirements.
- **Differentiate Without Color**: Highlight state is shown by a background-color change (`apt-highlight/15` on the current item, `apt-highlight/10` on hover) and by the `aria-selected` attribute. `aria-selected` is exposed to assistive technology only — it provides no visual cue, so a sighted user who cannot distinguish the highlight color currently has no other way to tell which item is active.

## Feature Flags

Not applicable: CommandPalette does not gate its functionality behind feature flags. All features are always active.

## Analytics

Not applicable: CommandPalette does not emit analytics events. The host is responsible for tracking when items are selected or when the palette is opened/closed.

## Privacy

Not applicable: CommandPalette does not collect, store, or transmit user data. The query string is a controlled prop passed by the host and is the host's responsibility to manage.

## Logging

Not applicable: CommandPalette does not emit logs. Debugging is delegated to host-level instrumentation or React DevTools inspection.

## Platform Notes

- **SwiftUI**: Use a ZStack with a semi-transparent overlay (`.background(.black.opacity(0.2))`) behind a VStack for the input and list. Implement keyboard navigation using `.onKeyPress()` or `.keyboardShortcut()`. Use `List` with `@State var activeIndex` tracking the highlighted row. Horizontal list groups require explicit `Section` headers; only render when the section has items. Implement scrolling with `.scrollPosition(id:anchor:)` and `ScrollViewReader`. No native combobox role; approximate the accessible structure with `.accessibilityLabel()` / `.accessibilityValue()` and appropriate `.accessibilityAddTraits()` on the input and highlighted row.
- **Compose**: Use a `Dialog` with a `TextField` for input and a `LazyColumn` for the list. Implement highlight tracking with `var activeIndex by remember { mutableStateOf(0) }`. Use `focusRequester` and `FocusManager` to manage keyboard focus and ArrowUp/Down navigation. Render group headers as `item()` entries with conditional visibility. Implement scroll-into-view with `LazyListState.scrollToItem()`.
- **React/Web**: This is the source platform; the other platform notes describe how to reproduce its behavior. Behavior is a contract with the reference implementation (`packages/web/packages/ui/src/blocks/command-palette.tsx`): a controlled input drives all state, the Dialog primitive supplies the overlay and Escape handling, keyboard handling lives in the input's `onKeyDown`, and ARIA `listbox` / `option` / `group` roles provide the accessible structure.
- **AppKit / UIKit**: For macOS (AppKit), use `NSPanel` with a search field (`NSSearchField`) and a table view (`NSTableView`) or outline view. Implement keyboard navigation with `keyDown(_:)`. Use `NSAccessibility` attributes to mark the search field as a combobox and table rows as options. For iOS (UIKit), the overlay would be a `UIViewController` presented modally with a `UISearchBar` and a `UITableViewController`, though command palettes are less common on mobile.
- **WinUI 3**: Use a `ContentDialog` with a `TextBox` for the search input and an `ItemsRepeater` or `ListView` for the command list. Implement keyboard navigation in `KeyDown` event handlers on the TextBox, moving selection through the list using `SelectedIndex`. Render group headers as template items with conditional visibility (binding to `group.Items.Count > 0`). Use `ListView.ScrollIntoView(item)` to scroll the selected item into view. Bind `TextBox.Text` to query state; bind list selection to highlight state.

## Design Decisions

**Decision**: The search query is a controlled prop (`query` / `onQueryChange`), not internal state — the component never filters its own `groups`.
**Rationale**: This decoupling lets a host integrate server-side search (remote results already filtered by the server) without a local filter silently discarding matches whose label doesn't contain the query. For hosts that filter local groups themselves, the package exports `filterCommandItems(items, query)`: it trims and lowercases `query`, returns `items` unchanged when the trimmed query is empty, and otherwise keeps items whose `label`, `keywords`, `badge`, and `description` (joined, case-insensitively) contain the query substring.
**Approved**: pending

**Decision**: The first item in the flattened list is always preselected; the palette never opens with nothing highlighted.
**Rationale**: This shortens the interaction to two steps — type, then press Enter — the most common palette interaction, rather than requiring an extra arrow-down before Enter does anything.
**Approved**: pending

**Decision**: The highlight resets to the first item both when the displayed item set changes and separately when the dialog transitions from closed to open (see **reset-highlight-to-first-item**).
**Rationale**: The signature-based reset (keyed on item IDs) stops the highlight drifting to an unintended item when the list updates mid-interaction. The open-triggered reset stops a reopened palette from resuming the previous selection, avoiding an accidental re-run of the last selected command.
**Approved**: pending

**Decision**: A `loading: true` state does not replace the rendered list.
**Rationale**: Stale results are more useful than an empty pane. The loading indicator sits below the current results, signaling that more are coming without hiding what the user already has.
**Approved**: pending

**Decision**: Groups render in the order provided, and a group with zero items is dropped entirely — both its heading and its row (see **render-groups-in-order**).
**Rationale**: This lets a host declare groups unconditionally without cluttering the UI with empty sections.
**Approved**: pending

**Decision**: The component does not add its own Escape handler.
**Rationale**: The Dialog primitive already closes on Escape, so a second handler here would be a second definition of "how this closes" (see **open-change-on-dismiss**).
**Approved**: pending

**Decision**: `scrollIntoView()` is called with optional chaining (`?.`).
**Rationale**: jsdom, used in test suites, does not implement `scrollIntoView`. An unguarded call would throw in every host's test suite; optional-calling makes the scroll a cosmetic nicety that's simply absent in tests rather than a test blocker.
**Approved**: pending

**Decision**: ArrowDown at the end of the list wraps to the first item, and ArrowUp at the start wraps to the last (see **arrow-navigation**).
**Rationale**: Wrapping is more useful than "nothing happens," letting users cycle through short lists without reaching for the mouse.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | failed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | failed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

These statuses rest on: the source's ARIA roles and attributes plus `autoFocus` and the `onKeyDown` handlers (`screen-reader-support`, `keyboard-navigable`, `semantic-markup`); the ~24px-tall item rows from `py-1.5 px-2` (`touch-target-size`); the design-token colors and the Dialog primitive's focus trap, neither of which this file can verify (`contrast-ratio`, `focus-management`, `dynamic-type-support`); the `placeholder`/`emptyLabel` props versus the hardcoded `"Searching…"` string (`string-externalization`, `no-hardcoded-strings`); plain-text rendering with no character filtering (`unicode-support`); the `truncate` CSS class applied to long labels and descriptions, which clips rather than accommodates expanded text (`text-expansion-tolerance`); and the physical-direction Tailwind classes (`pl-9`, `left-6`, `pr-10`) used for the input and its icon (`rtl-layout-support`). separation-of-concerns passes because the matching rule (`filterCommandItems`) is exported as a standalone pure function outside the component, leaving only ordinary highlighted-row bookkeeping inline, and unit-test-coverage passes because `commandPalette.test.tsx` exercises structure, keyboard navigation, mouse/keyboard interplay, loading/empty/error states, and `filterCommandItems` itself with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: merged the first-item/reopen preselection requirements and the group-order/heading requirements and the escape/onOpenChange requirements into single named requirements; renamed every requirement to subject-only kebab-case; added a Props and Types section covering `CommandPaletteProps`, `CommandGroup`, and `CommandItem`; specified the `filterCommandItems` contract in Design Decision 1; reformatted Design Decisions to the Decision/Rationale/Approved form; added a Compliance table; fixed the `max-w-xl` pixel value and the 44pt tap-target claim; corrected the ARIA structure and the Differentiate Without Color description; fixed the States table's hover contradiction; corrected Design Decision 2's keystroke count; fixed the SwiftUI/Compose/WinUI 3 platform-note APIs; promoted four untraced edge-case MUSTs to named requirements with test vectors; added vectors for input focus and dismiss/onSelect callback order; rewrote cp-026 to assert concretely; reframed the React/Web platform note as a reference-implementation contract instead of a hardcoded path and hook list |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
