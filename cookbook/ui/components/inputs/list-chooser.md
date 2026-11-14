---
id: 40827b84-406e-4091-951b-9498b2f78253
title: "ListChooser"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-06-26
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Disclosed chooser whose single field filters a list and adds new entries, with arrow-keyed highlight, OK/Cancel, and full keyboard control."
platforms:
  - typescript
  - web
tags:
  - component
  - list-chooser
  - chooser
  - ui
  - form-control
depends-on:
  - 4d0e04ff-39eb-472c-93a0-8070f1b64a6a
related:
  - 43c55f5e-d9b3-430b-9026-d0af510fda15
  - 4d0e04ff-39eb-472c-93a0-8070f1b64a6a
references:
  - https://www.w3.org/WAI/ARIA/apg/patterns/combobox/
  - https://www.w3.org/WAI/WCAG21/Understanding/focus-visible.html
  - https://www.w3.org/WAI/WCAG21/Understanding/target-size.html
approved-by: ""
approved-date: ""
---

# ListChooser

## Overview

`ListChooser` is a single-select "pick from a list, or add a new one" control. A trigger button discloses a popover containing one text field plus a filtered list and an OK / Cancel button bar. The field does double duty: typing narrows the list to case-insensitive substring matches, and text that matches no item can be accepted as a brand-new entry (when `allowCreate`). Arrow keys move a roving highlight through the filtered list and preview the highlighted label in the field; Enter / OK accept the current selection or entry; Esc / Cancel close without committing.

It is the keyboard-and-mouse foundation for "choose or create" pickers (first use: the research category/tag UI). It is built by composing the same primitives as `OptionMenu` — `Popover` (surface), `Input` (the field), `Button` (OK / Cancel) — with a hand-managed roving selection, rather than forking `OptionMenu`: that control has a fixed list with a separate editable "Other" row at the bottom, while this control's single field _is_ both the filter and the add-new field. It differs from `Combobox` (`@adh-sdk/ui/components/combobox`), an inline free-text input with a typeahead dropdown and no trigger, list, or OK/Cancel commit step.

## Behavioral Requirements

- **trigger-opens-surface**: Activating the trigger (click, Enter, or Space) MUST open the popover.
- **opens-with-field-focused**: On open, the filter/add field MUST receive focus so the user can type immediately.
- **type-narrows-list**: Typing in the field MUST narrow the list to items whose label contains the typed text as a case-insensitive substring.
- **arrow-roves-highlight**: ArrowDown / ArrowUp MUST move a roving highlight through the filtered list (and the create row when present). From no highlight, ArrowDown enters at the first row and ArrowUp enters at the last row; once a row is highlighted, ArrowUp at the first row and ArrowDown at the last row hold in place — no wrap between rows.
- **highlight-syncs-into-field**: While a list item is highlighted, the field MUST display that item's label (the highlight is previewed in the field); typing again replaces the preview with the typed text and clears the highlight.
- **enter-accepts-highlighted-item**: When a list item is highlighted, Enter MUST accept it via `onChange` with `isNew:false`, then close.
- **enter-accepts-typed-entry**: When nothing is highlighted, the trimmed text is non-empty and has no exact case-insensitive label match, and `allowCreate` is set, Enter MUST accept the trimmed text via `onChange` with `isNew:true`, then close.
- **typed-text-resolves-to-exact-item**: When nothing is highlighted and the trimmed text equals an item label (case-insensitive), accept MUST resolve to that item with `isNew:false`, never a new entry.
- **create-unavailable-when-disabled**: When `allowCreate` is false, text matching no item MUST NOT be acceptable — no create row, OK disabled, Enter a no-op.
- **escape-cancels**: Esc MUST close the surface without firing `onChange`.
- **ok-mirrors-enter**: The OK button MUST be equivalent to Enter and MUST be disabled whenever nothing is acceptable.
- **cancel-mirrors-escape**: The Cancel button MUST be equivalent to Esc.
- **pointer-click-commits**: A pointer click on a list row (or the create row) MUST accept it immediately and close.
- **focus-returns-on-close**: On any close, focus MUST return to the trigger.
- **empty-message-when-no-match**: When no item matches and creation is unavailable, the list MUST show the empty message.
- **shift-enter-dismiss-in-keep-open-mode**: When `keepOpenOnCommit` is true, Shift+Enter MUST close the popover; plain Enter still accepts and keeps the popup open.
- **focused-state-styling**: The trigger MUST show a visible focus indicator meeting WCAG 2.4.7 (Focus Visible) — a 2px focus ring distinct from the unfocused border — in addition to the platform-native focus ring where the host platform provides one.

## Appearance

Closed:

```
┌─────────────────────────────┐
│ Choose a framework…      ▾  │   ← trigger button (committed label or placeholder) + chevron
└─────────────────────────────┘
```

Open:

```
┌─────────────────────────────┐
│ [ sv|                     ]  │   ← filter/add field — focused on open
├─────────────────────────────┤
│   SvelteKit                 │   ← filtered list (narrowed by the field text)
│ + Add "sv"                  │   ← create row: shown whenever the trimmed text is non-empty
│                              │     and has no exact case-insensitive label match — here "sv"
│                              │     substring-matches "SvelteKit" but isn't an exact match, so
│                              │     the create row appears alongside the filtered item
├─────────────────────────────┤
│              Cancel    OK   │   ← button bar; OK disabled until something is acceptable
└─────────────────────────────┘
```

- **Trigger**: Same visual language as `Select` / `Input` — `apt-border`, `apt-bg` background, `focus-visible` ring `apt-gold/25`, `ChevronsUpDown` glyph in `apt-text-muted`. Height 36px (9 units at 4px scale). Text is `apt-text`, truncated if long. On disabled state, opacity is reduced to 50% and cursor becomes `not-allowed`.
- **Surface**: `Popover` content with 8px padding (2 units). Minimum width 256px (64 units). The filter/add field uses the shared `Input` component styling. List rows use dropdown row treatment — keyboard highlight `bg-apt-highlight/15`, pointer hover `bg-apt-highlight/10`, text `apt-text`, corner radius `md` (6px). The committed row's check icon is `apt-gold`, all other icons are `apt-text-muted`. Row padding is vertical 6px × horizontal 8px (1.5 units × 2 units).
- **Create row**: A `Plus` glyph (14px, `apt-text-muted`) plus the `createLabel(text)` text, using the same row treatment as filtered items.
- **Button bar**: Separated from the list by an `apt-border` top rule (1px). Uses shared `Button` component — Cancel `variant="ghost"`, OK `variant="default"` (gold background). Buttons are small size, 32px height. Flex layout with gap 8px (2 units), justified to the end. Padding top 8px (2 units).
- **Empty message**: Shown when no items match and creation is unavailable. Text is `apt-text-muted`, 14px font size, padding 8px × 2 units.
- **Max list height**: 240px (60 units); overflow-y auto beyond that.
- **No raw hex; no `!important`**.

## States

| State | Appearance change |
|---|---|
| Trigger closed | Label = committed value (item label or free text) or `triggerPlaceholder`; chevron always shown |
| Trigger focused | `focus-visible` ring 2px `apt-gold/25`, border color unchanged |
| Trigger disabled | Opacity 50%, cursor `not-allowed`, non-interactive |
| Trigger hover | Border color `apt-border-strong` (on enabled trigger only) |
| Open, no highlight | Field shows the typed text; no row highlighted |
| Open, item highlighted | `bg-apt-highlight/15` on the roving row; field previews its label; `aria-activedescendant` points to that option |
| Open, committed row visible | ✓ (Check) icon shown in `apt-gold` on the committed item's row; `aria-selected="true"` on that option |
| No exact case-insensitive label match (trimmed text non-empty), `allowCreate` | Create row shows in addition to any items the filter still matches (e.g. typing "sv" leaves "SvelteKit" in the list and still shows "+ Add \"sv\""); OK enabled |
| Filter matches nothing, no create | Empty message ("No matches") shown; OK disabled |
| Nothing acceptable | OK button disabled, Cancel always enabled |
| Listbox max height exceeded | Vertical scroll enabled on list container |

The control is synchronous over the in-memory `items` prop, so it has no intrinsic loading or error state; a caller fetching items owns those and passes the resolved array (mirroring `OptionMenu` / `RecipientInput`).

## Accessibility

- **Trigger**: `<button>` with `aria-haspopup="listbox"`, `aria-expanded={open}`, `aria-label={ariaLabel}`. Must be keyboard accessible (Enter, Space to open).
- **Filter/Add field**: `<input>` with `role="combobox"` (completes WAI-ARIA combobox pattern). Labeled by `aria-label={inputLabel ?? ariaLabel}`. Has `aria-controls={listId}` pointing to the list container, `aria-autocomplete="list"`, and `aria-activedescendant` pointing to the currently highlighted option (or undefined if no highlight).
- **List container**: `<div role="listbox">` with `aria-label={ariaLabel}`. Scrollable area with `max-height` constraint.
- **List rows**: Each row is a `<button role="option">`. Has `aria-selected="true"` on the committed row (when its value matches), `aria-selected="false"` on all others. The roving highlight is not expressed via `aria-selected`, only via `aria-activedescendant` on the combobox field. Create row is also `role="option"` with `aria-selected="false"`.
- **Focus management**: Focus moves to the field when the popover opens. On close, focus returns to the trigger.
- **Touch target size**: Rows and buttons SHOULD aim for a 44×44pt target size (11×11 units at the 4px scale) per WCAG 2.5.5 and platform HIG guidance. The current implementation is smaller than that: the trigger is a fixed 36px (`h-9`, 9 units) and list rows are `py-1.5 px-2` (6px vertical padding around 14px text, roughly 26–30px tall).
- **Keyboard paths**: All interactions (open, filter, navigate, accept, dismiss) are fully keyboard-accessible without requiring a mouse.
- **Icon labeling**: Decorative icons (chevrons, check, plus) have `aria-hidden="true"`.

## Conformance Test Vectors

Fixture `items` used by every vector below:

| value | label |
|---|---|
| `sveltekit` | `SvelteKit` |
| `react` | `React` |
| `vuejs` | `Vue.js` |
| `angularjs` | `AngularJS` |
| `solidjs` | `SolidJS` |

`navCount` for this fixture with no filter is 5 (or 6 when the create row is also showing).

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | type-narrows-list | open, type "sv" | filtered list narrows to `SvelteKit` only; the other four items are removed from the visible list |
| T2 | empty-message-when-no-match | `allowCreate=false`, type "zzz" | no options; empty message ("No matches") shown |
| T3 | arrow-roves-highlight, highlight-syncs-into-field | open (no filter), ArrowDown ×2, ArrowUp ×1 | highlight moves index 0 (`SvelteKit`) → 1 (`React`) → 0 (`SvelteKit`); `aria-activedescendant` tracks the highlighted option at each step; field shows the highlighted item's label at each step |
| T4 | enter-accepts-highlighted-item | open, ArrowDown ×1 (highlights `SvelteKit`), Enter | `onChange("sveltekit", { isNew:false })` fired; popover closes |
| T5 | escape-cancels | open, type "test", Esc | no `onChange` fired; listbox closes |
| T6 | enter-accepts-typed-entry | open, type "  Angular  ", Enter | `onChange("Angular", { isNew:true })` fired (text trimmed; "Angular" has no exact case-insensitive match — `AngularJS` is a substring match only); popover closes |
| T7 | pointer-click-commits | open, type "Solid", click create row | `onChange("Solid", { isNew:true })` fired ("Solid" has no exact match — `SolidJS` is a substring match only); popover closes |
| T8 | typed-text-resolves-to-exact-item | open, type "react" (exact case-insensitive match to the `react`/`React` item), Enter | `onChange("react", { isNew:false })` fired — resolves to the item's `value`, not the typed string |
| T9 | create-unavailable-when-disabled | `allowCreate=false`, type "Nope", Enter | no `onChange` fired; nothing happens |
| T10 | ok-mirrors-enter | open, type "Vue", click OK | `onChange("Vue", { isNew:true })` fired ("Vue" has no exact match — the fixture's label is `Vue.js`, not `Vue`); popover closes |
| T11 | cancel-mirrors-escape | open, type "test", click Cancel | no `onChange` fired; popover closes |
| T12 | trigger-opens-surface | click trigger | popover opens |
| T13 | opens-with-field-focused | click trigger | field receives focus (can type immediately) |
| T14 | focused-state-styling | trigger has focus | 2px focus-visible ring visible on the trigger (WCAG 2.4.7) |
| T15 | shift-enter-dismiss-in-keep-open-mode | `keepOpenOnCommit=true`, open, ArrowDown ×1 (highlights `SvelteKit`), Enter, then Shift+Enter | first Enter fires `onChange("sveltekit", { isNew:false })` and popover stays open, with query and highlight reset to their initial (opened) state; Shift+Enter then closes the popover without firing `onChange` |
| T16 | ok-mirrors-enter | open, no filter, no item highlighted | OK button is disabled — trimmed text is empty, so nothing is acceptable yet |
| T17 | focus-returns-on-close | click trigger to open, then Esc | focus returns to the trigger button |
| T18 | (see edge case: Disabling the component) | `disabled=true`, attempt to click/activate the trigger | popover does not open; `aria-expanded` stays `false` |
| T19 | escape-cancels, cancel-mirrors-escape | `keepOpenOnCommit=true`, open, Esc (and, separately, click Cancel) | popover closes without firing `onChange`, same as when `keepOpenOnCommit` is false |
| T20 | arrow-roves-highlight | open (no filter, `navCount=5`), ArrowUp ×1 (from no highlight) | highlight jumps to index 4 (`SolidJS`, the last row); a further ArrowDown ×1 holds at index 4 (no wrap to index 0 or to no-highlight) |
| T21 | highlight-syncs-into-field, type-narrows-list | open, ArrowDown ×1 (highlights `SvelteKit`, field previews "SvelteKit"), then type "x" — the previewed text is not selected, so the keystroke appends to it | highlight clears to no-highlight; field shows "SvelteKitx"; list re-filters by "sveltekitx" (no items match; create row shows) |
| T22 | pointer-click-commits | open (no filter), click the `React` row | `onChange("react", { isNew:false })` fired; popover closes |

## Edge Cases

- **Highlight preview vs. filter**: Filtering uses the typed text, not the previewed highlight, so arrow-navigating a single match does not collapse the list; typing again replaces the preview and re-filters. Changing the query resets highlight to -1.
- **Value resolution on the trigger**: If `value` equals an `items[i].value`, the trigger shows that item's label. Else if `allowCreate` is true and `value` is not `null`, the trigger shows `value` verbatim as free text — this includes an empty string or a whitespace-only string, since `value` is never trimmed for this comparison. Otherwise (`value` is `null`, or `allowCreate` is false with no item match) the trigger shows `triggerPlaceholder`. Only `null` counts as "nothing chosen"; an empty string is treated as a committed (if unusual) free-text value whenever `allowCreate` is true.
- **Whitespace handling**: The typed text is trimmed before matching (`text.trim().toLowerCase()`) and before being accepted as a new entry. Whitespace-only text (e.g., "   ") is not acceptable for new entries.
- **Empty `items` array**: With no items, an empty filter shows the empty message regardless of `allowCreate` — creation requires non-empty trimmed text, so an empty filter never surfaces the create row. Typing surfaces the create row once `allowCreate` is true and the trimmed text is non-empty.
- **Clamping at list boundaries**: exact transitions, given `navCount` rows (items + create row when shown): from no highlight (`highlight = -1`), ArrowDown moves to index 0 (first row) and ArrowUp moves to index `navCount - 1` (last row) — entering from either direction lands at that direction's natural end. Once a row is highlighted, ArrowUp at index 0 holds at index 0 (no wrap to -1 or to `navCount - 1`), and ArrowDown at index `navCount - 1` holds at `navCount - 1` (no wrap to 0 or to -1). No wrapping occurs once a row is highlighted.
- **Case-insensitive substring matching**: The filter compares `query.trim().toLowerCase()` against `item.label.toLowerCase().includes(...)`. For example, against the fixture in Conformance Test Vectors, a query "e" matches `SvelteKit`, `React`, and `Vue.js` (all contain "e" case-insensitively).
- **Exact-match resolution**: When the user types text that exactly matches (case-insensitive) an item's label, pressing Enter accepts that item with `isNew:false`, not a new entry. Matching is done on the trimmed, lowercased text.
- **Committed value with allowCreate**: When `allowCreate` is true and `value` is a non-null string that does not match any item value, the trigger shows the free text, and this "committed but not a known item" state is preserved across renders so the parent can track new entries.
- **Creating when a filter is active**: When `allowCreate` is true and the trimmed text has no exact case-insensitive label match, the create row appears with the `createLabel(text)` label (using the current trimmed text) alongside any items the filter still matches — it is not limited to the case where the filter matches nothing. Clicking or accepting it commits the typed text.
- **keepOpenOnCommit mode**: One rule covers dismissal in every mode: Esc, Cancel, and — only when `keepOpenOnCommit` is true — Shift+Enter all close the popover without committing. When `keepOpenOnCommit` is true, a plain accept (Enter, OK, or row click) does not close the popover; instead it calls `onChange`, resets the query and highlight to their initial state (as if the popover just opened), and keeps focus in the field — Shift+Enter is the keyboard way to signal "I'm done" without reaching for Escape or the mouse. When `keepOpenOnCommit` is false, Shift+Enter behaves exactly like plain Enter: it accepts (if something is acceptable) and closes, the same as any other accept in that mode. The parent is responsible for removing the committed item from `items` if desired.
- **Disabling the component**: When `disabled` is true, the trigger button is non-interactive, `aria-expanded` is not managed (stays false), and the open-change handler returns early without opening the popover.
- **Focus return behavior**: When the popover closes (via Esc, Cancel, or an accept when `keepOpenOnCommit` is false), the `Popover` component (Base UI) automatically returns focus to the trigger button.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `items` | `ListChooserItem[]` | — | The selectable items array (`{ value: string, label: string }`). Must not contain duplicate `value` fields. |
| `value` | `string \| null` | — | Committed value: an item's `value`, free text (when `allowCreate`), or null (nothing chosen). This is a controlled prop; changes must come via `onChange`. |
| `onChange` | `(value: string, meta: { isNew: boolean }) => void` | — | Fired when the user accepts a selection. `isNew` is true when the value is typed text, false when it is an item. |
| `allowCreate` | `boolean` | `true` | Whether text matching no item can be accepted as a new entry. When false, only items in the list are acceptable. |
| `ariaLabel` | `string` | — | Required. Labels the trigger button and the listbox for assistive technology. |
| `inputLabel` | `string` | `ariaLabel` | Accessible label for the filter/add field. Falls back to `ariaLabel` if not provided. |
| `placeholder` | `string` | `"Filter or add…"` | Placeholder text shown in the filter field when it is empty. |
| `triggerPlaceholder` | `string` | `"Select…"` | Text shown on the trigger when `value` is null (nothing committed). |
| `okLabel` | `string` | `"OK"` | Accept button label. |
| `cancelLabel` | `string` | `"Cancel"` | Cancel / dismiss button label. |
| `createLabel` | `(text: string) => string` | `` `Add “${text}”` `` | Function that builds the create-row label from the typed text. Example: `(text) => `Add “${text}”`` becomes "Add “React”" when text is "React" |
| `emptyLabel` | `string` | `"No matches"` | Message shown when no item matches the filter and creation is unavailable. |
| `keepOpenOnCommit` | `boolean` | `false` | When true, accepting a selection keeps the popover open for adding multiple entries; Shift+Enter or Esc/Cancel closes. When false, any accept closes the popover. |
| `disabled` | `boolean` | `false` | When true, the trigger is non-interactive and the component cannot be opened. |
| `className` | `string` | — | Extra CSS class(es) applied to the trigger button for custom styling. |

## Deep Linking

Not applicable: ListChooser is a form control component without inherent URL semantics. Deep linking to a chooser state (open/closed, highlighted item, filter text) is handled by the parent page/screen, not the component itself.

## Localization

All labels, placeholders, and messages (`placeholder`, `triggerPlaceholder`, `okLabel`, `cancelLabel`, `createLabel`, `emptyLabel`, `ariaLabel`, `inputLabel`) are accepted as props, so the parent can supply localized strings for any language. Each prop's default value (`"Filter or add…"`, `"Select…"`, `"OK"`, `"Cancel"`, `` `Add “${text}”` ``, `"No matches"`) is English text baked into the component signature — a caller targeting another locale MUST override every default it uses rather than rely on it.

Filtering and exact-match resolution lowercase both the query and item labels (`.toLowerCase()`) for case-insensitive comparison. Casing is a locale-sensitive transform (e.g. Turkish dotless-ı), so this comparison may not behave as expected for every locale. Callers with locale-specific casing needs should pre-normalize `items` labels rather than relying on JavaScript's default, locale-unaware `toLowerCase()`.

## Accessibility Options

Not applicable: ListChooser is a presentational control without intrinsic support for platform accessibility display options (Reduce Motion, Increase Contrast, Differentiate Without Color). The parent component or design system MAY apply these settings to the underlying `Button`, `Input`, and `Popover` primitives.

## Feature Flags

Not applicable: ListChooser is a presentational UI control, not a feature that requires gating or conditional delivery. Feature flags belong to the parent application or feature set.

## Analytics

Not applicable: ListChooser is a presentational form control. Analytics instrumentation (event tracking, property logging) is the parent component's responsibility. The component emits no structured event data.

## Privacy

Not applicable: ListChooser does not collect, store, or transmit any data. All values, including free-text entries, are controlled via props and callbacks. The parent is responsible for handling any privacy or consent concerns related to the data it provides or collects via the component.

## Logging

No structured logging. ListChooser is a presentational form control; it emits no log events. Diagnostic logging (if needed) belongs to the parent or consuming application.

## Platform Notes

- **React/Web (`packages/web/packages/ui/src/components/list-chooser.tsx`)**: A React hook-based component using `Popover`, `Input`, and `Button` primitives from the same package. The roving selection is hand-managed via state (`highlight` index). Uses `aria-activedescendant` to express the highlighted option. The field has `role="combobox"` per WAI-ARIA combobox pattern. Focus enters the field on open via `requestAnimationFrame` (deferring until after the popover's own mount/layout); on close, focus returns to the trigger via the base `Popover` component's own focus management. Filtering is synchronous substring matching over the in-memory `items` array; no async behavior.

- **SwiftUI (iOS/macOS)**: Use a `Button` trigger with `.popover(isPresented:)` for the disclosed surface. Use `@FocusState` to focus the filter `TextField` on open, and `.onKeyPress(.upArrow)` / `.onKeyPress(.downArrow)` / `.onKeyPress(.return)` / `.onKeyPress(.escape)` on the field to drive the roving highlight and commit/cancel. A `List` (or `ScrollView` + `LazyVStack`) renders the filtered rows, with separate `Button` views for OK/Cancel. Filter case-insensitive substrings using `String.localizedCaseInsensitiveContains()`. The create row is a separate conditional row in the list.

- **Kotlin/Jetpack Compose (Android)**: Start from `OutlinedTextField` (trigger when closed) + `Popup` or `DropdownMenu` (surface). Use a `LazyColumn` for the filtered items. State management mirrors web: `highlightedIndex`, `query`, `isOpen` as `MutableState`. `ArrowUp` / `ArrowDown` key handling via `KeyEvent` in the field's `onKeyEvent` callback. Focus the field on open with a `FocusRequester`, calling `.requestFocus()` inside a `LaunchedEffect(Unit)` (or an open-triggered callback) rather than during composition. The create row is a separate `DropdownMenuItem` or composable button. Filter strings using `contains(ignoreCase = true)`. Button bar uses `Row` with `Button` composables for OK/Cancel.

- **AppKit / UIKit**: AppKit — an `NSPopover` anchored to an `NSButton` trigger, containing an `NSTextField` (filter/add field), an `NSTableView` (filtered rows), and a bottom `NSStackView` of `NSButton`s for OK/Cancel; the roving highlight is a manually tracked selected-row index, with arrow keys handled by overriding `keyDown(with:)` on the field or table. UIKit — a `UIPopoverPresentationController` presenting a view controller with a `UITextField`, `UITableView`, and a button bar; arrow-key support requires a hardware keyboard and explicit `UIKeyCommand` registration (e.g. `UIKeyCommand(input: UIKeyCommand.inputUpArrow, ...)`).

- **WinUI 3**: Start from a `Flyout` (not `Popup`) anchored to the trigger `Button`, containing a `TextBox` (the filter/add field), a `ListView` (the filtered rows), and a `StackPanel` of `Button` controls (OK/Cancel). Filter with an `AdvancedCollectionView` (from the Windows Community Toolkit) — or a hand-filtered `ObservableCollection` — using a predicate built on `string.Contains(..., StringComparison.OrdinalIgnoreCase)`; WinUI's `ComboBox` has no `Filter` property (that is WPF's `CollectionViewSource.Filter`), so this filtering must be custom. A `Flyout` does not auto-focus its content on open, so explicitly call `filterTextBox.Focus(FocusState.Programmatic)` in the `Flyout.Opened` handler. Arrow-key roving highlight and Enter/Escape handling go in the `TextBox`'s `PreviewKeyDown` handler. Create row is conditionally shown based on `AllowCreate` and whether the trimmed text has no exact match.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/list-chooser.tsx` | unverified |

## Design Decisions

**Decision**: Compose `OptionMenu`'s primitives (`Popover`, `Input`, `Button`), don't fork it.
**Rationale**: The roving selection, `aria-activedescendant`, and Popover-with-trigger shape are shared with `OptionMenu`, but the single field that both filters and creates is a distinct interaction. Subclassing `OptionMenu` (fixed list + bottom "Other" row) would have entangled two models; composing the same primitives keeps each control single-responsibility.
**Approved**: pending

**Decision**: Filter on typed text; preview the highlight separately.
**Rationale**: Keeping the filter query separate from the previewed highlight label means arrow-navigation never re-filters the list out from under the user. Users can arrow through matches without the list collapsing, and typing again replaces the preview and re-filters.
**Approved**: pending

**Decision**: Selection and commit are distinct actions.
**Rationale**: Moving the highlight never fires `onChange`; only an accept (Enter, OK, or row click) commits. This allows users to explore the list without side effects, matching standard form control behavior.
**Approved**: pending

**Decision**: No built-in async state.
**Rationale**: `items` is a controlled in-memory prop, so loading/error belong to the caller — consistent with sibling form controls like `OptionMenu` and `RecipientInput`. This keeps the component presentational and predictable.
**Approved**: pending

**Decision**: Esc, Cancel, and — in keep-open mode — Shift+Enter are the three ways to dismiss; plain Enter never dismisses in keep-open mode.
**Rationale**: In multi-select ("collect a set") mode, plain Enter adds another entry without closing, so a separate keyboard signal for "I'm done" is needed alongside Esc and Cancel. Shift+Enter fills that role, completing the keyboard accessibility matrix without adding a new modal state. Outside keep-open mode, every accept already closes the popover, so Shift+Enter there is indistinguishable from plain Enter — it still accepts and closes.
**Approved**: pending

**Decision**: Exact-match text resolution.
**Rationale**: If the trimmed, lowercased user input exactly matches an item's label, it resolves to that item with `isNew:false`, not a new free-text entry. This prevents accidental duplication when a user types an existing item's full name.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source (`list-chooser.tsx`): its ARIA roles/attributes and keyboard handlers (`role="combobox"`/`listbox`/`option`, `aria-activedescendant`, `aria-selected`, `aria-hidden` on icons, `onInputKeyDown`) support screen-reader and keyboard checks; its fixed `h-9` trigger and `py-1.5 px-2` rows fall short of the 44×44pt touch-target check; its color-token classes (`apt-gold`, `apt-text`, etc.) can't be verified for contrast or Dynamic-Type scaling from this file alone; all strings are props but the defaults are hardcoded English; and `truncate` on labels clips rather than accommodates expanded translated text, with no explicit `dir`-aware handling for RTL. `separation-of-concerns` is partial because the filter/highlight/commit/accept/move business logic is defined as named functions but still lives inline inside the `ListChooser` component body rather than in an extracted hook or module; `unit-test-coverage` passes on `listChooser.test.tsx`'s thorough exercise of filtering, keyboard navigation, add-new, OK/Cancel, `keepOpenOnCommit`, and the trigger label.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Fixed empty-items edge case to require non-empty trimmed text before the create row shows; fixed createLabel default/example to curly quotes; fixed T21 to reflect that typing appends to the unselected preview text. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: resolve the keep-open dismissal contradiction (Esc/Cancel/Shift+Enter all close; Shift+Enter equals plain Enter when not in keep-open mode); define create-row visibility as "trimmed text non-empty with no exact case-insensitive label match" and apply it in the callout, States table, and edge cases; spell out exact ArrowUp/ArrowDown transitions at no-highlight, first, and last rows; add external references (APG combobox pattern, WCAG 2.4.7, 2.5.5); correct wrong/nonexistent SwiftUI, Compose, and WinUI 3 APIs and add the missing AppKit/UIKit platform note; convert Compliance to the required linked-check table; reformat Design Decisions into Decision/Rationale/Approved entries; narrow T16's citation to `ok-mirrors-enter`; add an `items` fixture table and rewrite the test vectors for consistency with it, plus new vectors for focus-returns-on-close, the disabled trigger, Esc/Cancel in keep-open mode, boundary clamping, preview-clearing on typing, and clicking an existing row; fix the 44×44pt touch-target unit math and downgrade it to SHOULD to match the actual 36px implementation; correct the Localization section's "no fixed text" claim and note the locale-sensitivity of the `toLowerCase()` casing transform; make focused-state-styling testable against a single WCAG 2.4.7 criterion; resolve the trigger value-resolution contradiction using the source's actual null-only placeholder rule; and move internal names (`handleOpenChange`, `isCommittedNew`, `requestAnimationFrame`) out of the cross-platform Accessibility/Edge Cases text. |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Expand platform notes with guidance for Swift, Kotlin, and WinUI 3 implementations; add missing template sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy); clarify appearance specs with specific measurements and color tokens; add focused-state-styling requirement and T14, T15, T16 test vectors; document Shift+Enter behavior in keep-open mode. |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial component + recipe. |
