---
id: 79f7ed30-3193-49bc-856b-d7dd01303baa
title: "EntityChooser"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-06-26
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Browse/filter/select/add surface for account categories or tags — a single-value picker or a multi-select chip set, composed over ListChooser."
platforms:
  - typescript
  - web
tags:
  - component
  - entity-chooser
  - chooser
  - tags
  - ui
depends-on:
  - 40827b84-406e-4091-951b-9498b2f78253
  - 9191eade-c18a-4899-b802-f000a1905c80
related:
  - 43c55f5e-d9b3-430b-9026-d0af510fda15
  - d9ad192e-a642-46a2-8b25-b8aac9d9f441
  - 00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f26a9468-a15c-4cd2-b944-d39221e7eee2
references: []
approved-by: ""
approved-date: ""
---

# EntityChooser

## Overview

`EntityChooser` is a browse / filter / select / add surface for a list of string
entities — the account's categories or tags. It is a thin composition over
`ListChooser` (`@adh-sdk/ui/components/list-chooser`), which supplies the
disclosed, text-filtered list with a roving keyboard highlight and an "add a new
one" affordance. `EntityChooser` adds only the **selection semantics** on top:

- **single** mode is a one-value picker — selecting (or creating) replaces the
  value, exposed through a unified `string | null` callback.
- **multi** mode maintains an ordered **set**, rendered as removable chips beside a
  `Choose…` trigger whose browser stays open across accepts, so one open can add as
  many entries as needed. Already-selected options are hidden from the browser, so
  a member can't be added twice.

It never re-implements the list or keyboard logic — that lives in `ListChooser`. It
is the editor half of the `[Combobox autocomplete] [Choose…]` field pattern, where a
`Combobox` does inline typeahead and `EntityChooser`'s trigger opens the full
browse/add surface over the same options. It differs from `RecipientInput` (a free-text chip input with no backing
option list or filtered browser) and from `ListChooser` (single-value only, no chip
set, value-bearing trigger).

## Behavioral Requirements

- **accept-single-value**: In single mode, accepting an option or a created entry MUST report it through `onChange(next)` as the new value, replacing any prior one.
- **show-trigger-label-single-when-null**: In single mode, when the value is `null` the trigger MUST show the configured trigger label.
- **show-trigger-value-single**: In single mode, when the value is non-null the trigger MUST show that value.
- **add-to-set-multi**: In multi mode, accepting an option or a created entry MUST append it to the set via `onChange([...value, entry])`.
- **prevent-duplicates-multi**: In multi mode, an entry already in the set MUST NOT be added again — no duplicate and no `onChange`.
- **hide-selected-options-multi**: In multi mode, options already in the set MUST be omitted from the browser's list so they cannot be re-offered.
- **render-removable-chips-multi**: In multi mode, the current set MUST render as chips, each with a control labelled `Remove <value>` that removes that entry via `onChange`.
- **show-empty-hint-multi**: In multi mode, when the set is empty the chip area MUST show the empty-selection hint instead of chips.
- **trigger-label-only-multi**: In multi mode, the trigger MUST always show the configured trigger label, never a member of the set (the inner `ListChooser` value is held at `null`).
- **delegate-list-behavior**: Filtering, the roving-keyboard highlight, OK/Cancel, and add-new MUST be delegated to the embedded `ListChooser`, not re-implemented.
- **block-create-when-disallowed**: When `allowCreate` is false, typed text matching no option MUST NOT be acceptable (no create row shown).
- **respect-disabled**: When `disabled`, the trigger and every chip-remove control MUST be non-interactive.
- **host-mode-renders-trigger-only**: In multi mode with `selectionPlacement="host"`, the component MUST render only the trigger; the caller is responsible for rendering the selected set (via `EntitySelectionChips`).

## Appearance

Single (closed):

```
┌─────────────────────────────┐
│ architecture            ▾   │   ← trigger: the chosen value, or the trigger label
└─────────────────────────────┘
```

Multi:

```
┌──────────┐ ┌──────────┐ ┌───────────┐
│ vision ✕ │ │ rlhf  ✕  │ │ Choose… ▾ │   ← chips (removable) + the add trigger, inline
└──────────┘ └──────────┘ └───────────┘
```

Open (both modes) — the embedded `ListChooser` surface:

```
┌─────────────────────────────┐
│ [ att|                    ]  │   ← filter/add field (focused on open)
├─────────────────────────────┤
│   attention                 │   ← filtered list (selected options omitted in multi)
│ + Add “att”                 │   ← create row, when text matches no option
├─────────────────────────────┤
│              Cancel    OK   │
└─────────────────────────────┘
```

- Trigger, surface, list rows, create row, and button bar are entirely `ListChooser`'s treatment (`apt-border`/`apt-bg`, `apt-gold` highlight + check, `ChevronsUpDown`).
- Chips are the shared `RemovableChip` component with text content and a trailing remove button.
- Multi lays chips and the `Choose…` trigger in one `flex-wrap` row; the trigger is auto-width (`w-auto`) so it sits after the chips rather than filling the row.
- All color via `apt-*` tokens; no raw hex; no `!important`.

## States

| State | Appearance change |
|---|---|
| Single, value set | trigger shows the value; the matching list row shows ✓ when open |
| Single, value null | trigger shows the trigger label (e.g. "Choose…") |
| Multi, empty set | empty-selection hint (e.g. "Nothing selected yet", the default) + the Choose trigger |
| Multi, non-empty set | one chip per entry + the Choose trigger |
| Browser open | `ListChooser` popover: focused field, filtered list, OK/Cancel |
| `allowCreate` off, no match | no create row; OK disabled; Enter a no-op |
| Disabled | trigger + chip-remove controls dimmed and non-interactive |

The control is synchronous over the in-memory `options` prop — loading/error states
belong to the caller that fetches the options (mirroring `ListChooser` /
`RecipientInput`).

## Accessibility

- The embedded `ListChooser` provides the combobox/listbox semantics: trigger `aria-haspopup="listbox"` + `aria-expanded`, the filter field `role="combobox"` with `aria-controls` / `aria-activedescendant`, and `role="listbox"` / `role="option"` rows. Focus moves to the field on open and returns to the trigger on close.
- The trigger is labelled by `ariaLabel`; the filter/add field by `inputLabel` (falling back to `ariaLabel`).
- Multi mode wraps the chips + trigger in a `role="group"` labelled by `ariaLabel`; each chip's remove control is a `<button>` with `aria-label="Remove <value>"`.
- Keyboard operability (arrows, Enter, Esc, OK/Cancel) is inherited unchanged from `ListChooser`.
- Minimum touch target size for trigger and chip-remove controls is expected to be 44×44pt (per platform guidelines); the source sets no explicit sizing for either control, so this rests on inherited styling rather than something the component enforces itself.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | accept-single-value, delegate-list-behavior | single, open, click "engineering" | `onChange("engineering")`; browser closes |
| T2 | accept-single-value | single, type "design", Enter | `onChange("design")`; browser closes |
| T3 | accept-single-value | single, `value="engineering"`, open, click "design" | `onChange("design")`, replacing the prior value; browser closes |
| T4 | block-create-when-disallowed | single, `allowCreate=false`, type "nope", Enter | no `onChange`; no create row shown |
| T5 | show-trigger-value-single | single, `value="research"` | trigger shows "research" |
| T6 | show-trigger-label-single-when-null | single, `value=null` | trigger shows the configured trigger label (e.g. "Choose…") |
| T7 | render-removable-chips-multi, show-empty-hint-multi | multi, `value=[]` then `["vision"]` | empty hint shown; then "vision" chip shown |
| T8 | trigger-label-only-multi | multi, `value=["vision"]`, closed | trigger reads the trigger label (e.g. "Choose…"), not "vision" |
| T9 | add-to-set-multi | multi, `value=["vision"]`, open, click "attention" | `onChange(["vision","attention"])`; browser stays open |
| T10 | hide-selected-options-multi | multi, `value=["vision"]`, open | "vision" option absent; "attention" and others present |
| T11 | render-removable-chips-multi | multi, `value=["vision","attention"]`, click "Remove vision" | `onChange(["attention"])` |
| T12 | prevent-duplicates-multi | multi, `value=["vision"]`, type "vision", Enter | no `onChange` |
| T13 | host-mode-renders-trigger-only | multi, `selectionPlacement="host"` | only the trigger renders; no chip group |
| T14 | respect-disabled | `disabled=true` | trigger non-interactive; chip remove buttons non-interactive |

## Edge Cases

- **Created multi entry already present.** A typed entry equal to an existing member is rejected by the dedupe guard even though it's hidden from the list, so a stale type can't duplicate it.
- **Single free text vs. option.** A single `value` that matches no option still shows on the trigger as free text (inherited from `ListChooser`'s value resolution).
- **Empty options.** With no options, an empty filter shows `ListChooser`'s empty message; typing surfaces the create row when `allowCreate`.
- **Trigger label vs. value.** In multi mode the trigger always reads the trigger label (the inner `ListChooser` value is held at `null`); in single mode it reflects the chosen value.
- **Multi selectionPlacement host mode.** When `selectionPlacement="host"`, the chooser renders only the trigger (`w-auto` removed, `className` applied to trigger); the caller owns rendering `EntitySelectionChips` alongside and manages the selected values independently.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `options` | `readonly string[]` | — | The selectable entities (e.g. the account's categories or tags). |
| `multiple` | `boolean` | `false` | Discriminates single-value vs. multi-select-set mode. |
| `value` | `string \| null` (single) / `string[]` (multi) | — | The current selection. |
| `onChange` | `(next: string \| null) => void` (single) / `(next: string[]) => void` (multi) | — | Fired with the new selection. |
| `ariaLabel` | `string` | — | Required; labels the trigger, the listbox, and (multi) the chip group. |
| `triggerLabel` | `string` | `"Choose…"` | Trigger text (and the placeholder shown when a single value is null). |
| `inputLabel` | `string` | `ariaLabel` | Accessible label for the filter/add field. |
| `placeholder` | `string` | `ListChooser` default | Placeholder for the filter/add field. |
| `allowCreate` | `boolean` | `true` | Whether text matching no option can be accepted as a new entry. |
| `createLabel` | `(text: string) => string` | `ListChooser` default | Builds the create-row label. |
| `emptyLabel` | `string` | `ListChooser` default | Browser "no matches" message. |
| `emptySelectionLabel` | `string` (multi) | `"Nothing selected yet"` | Hint shown when the set is empty. |
| `selectionPlacement` | `"inline" \| "host"` (multi) | `"inline"` | Whether chips render inline with the trigger or are managed by the host component. |
| `disabled` | `boolean` | `false` | Disables the control. |
| `className` | `string` | — | Extra classes (single: the trigger; multi with inline: the chip+trigger group; multi with host: the trigger). |

### `EntitySelectionChips` (the `selectionPlacement="host"` companion)

| Option | Type | Default | Description |
|---|---|---|---|
| `values` | `readonly string[]` | — | Required; the selected set, in order. |
| `ariaLabel` | `string` | — | Required; names the group (the plural noun the set is of, e.g. "Tags"). |
| `onRemove` | `(value: string) => void` | — | Required; called when a chip's remove control is activated. |
| `emptySelectionLabel` | `string` | — | Hint shown in place of chips when the set is empty. Omit to render nothing at all. |
| `disabled` | `boolean` | `false` | Disables every chip's remove control. |
| `className` | `string` | — | Extra classes on the group. |

## Deep Linking

Not applicable: `EntityChooser` is a presentational form control with no deep-link targets. Navigation is owned by consuming pages.

## Localization

`EntityChooser` renders user-provided `options` as-is and takes its display strings through caller-provided props, but three of them fall back to hardcoded English defaults when the caller omits them:

| String Key | Default (en) | Context |
|---|---|---|
| `triggerLabel` | `Choose…` | Trigger text when no `triggerLabel` prop is passed; also what the trigger shows for a `null` single value. |
| `emptySelectionLabel` | `Nothing selected yet` | Multi-mode hint shown when the set is empty and no `emptySelectionLabel` prop is passed. |
| chip `removeLabel` | `Remove <value>` | Built by `EntityChooser`/`EntitySelectionChips` from the chip's value; not itself overridable — a caller localizing `<value>` upstream localizes this label too. |

Callers targeting a non-English locale MUST pass `triggerLabel` and `emptySelectionLabel` explicitly rather than rely on the English defaults.

## Accessibility Options

Not applicable: `EntityChooser` inherits all accessibility behavior from `ListChooser` and does not add platform-specific accessibility display options (Reduce Motion, Increase Contrast, Differentiate Without Color) of its own; these are handled by the embedded control and its dependencies.

## Feature Flags

Not applicable: `EntityChooser` is an unconditional component with no feature flags in the source code.

## Analytics

Not applicable: `EntityChooser` is a presentational form control; it emits no structured analytics events. Event tracking is the responsibility of the caller.

## Privacy

Not applicable: `EntityChooser` does not collect, store, transmit, or retain user data. It passes through user selections to a caller-provided `onChange` callback; no data is persisted or logged by the component.

## Logging

Not applicable: `EntityChooser` emits no structured log events. Logging of user selections is the responsibility of the caller.

## Platform Notes

- **React/Web (TypeScript)**: Source is `packages/web/packages/ui/src/components/entity-chooser.tsx`. The component exports `EntityChooser` (the main control) and `EntitySelectionChips` (a companion for rendering the multi-mode selection outside the chooser when `selectionPlacement="host"`). Both are React functional components using hooks for state management. Import from `@adh-sdk/ui/components/entity-chooser`.
- **SwiftUI**: Start with `Picker` or a custom presentation wrapping `List` with a search/filter field. Mirror the dual-mode dispatch: single uses a standard picker binding, multi uses a `State` set that appends on selection and omits selected values from the list. Render selected items as removable chips using `HStack` with a trailing `Image(systemName: "xmark.circle.fill")` per item.
- **Compose (Kotlin)**: Build on `LazyColumn` for the filtered list with `TextField` for the search input. Single mode: update a mutable state holder; multi mode: maintain a mutable set, append on accept, filter the list to exclude already-selected items. Use Material 3's `InputChip` (with its trailing icon slot) for removable chips. Handle focus transitions (focus to input on open, return focus to trigger on close) via `FocusRequester`.
- **UIKit / AppKit**: On iOS, use `UISearchController` to manage the filtered list within a `UITableViewController` popover. Present modally for consistency with navigation. On macOS, use an `NSSearchField` + `NSTableView` in a popover or sheet. Single mode stores the selection as a string; multi mode as a `Set<String>` or array. Render chips with removable `NSButton` subviews in a wrapping `NSStackView` (NSView-based) or `UIStackView` (UIKit).
- **WinUI 3 (C#)**: Use a single native approach end to end: an `AutoSuggestBox` as the filter/add field, presented inside a `Flyout` anchored to the trigger `Button` (`IsLightDismissEnabled="false"` while the flyout should stay open across accepts, mirroring `keepOpenOnCommit`; closed only via Done/Cancel or Esc). Bind `AutoSuggestBox.ItemsSource` to the filtered options and handle `TextChanged` for filtering and `SuggestionChosen`/`QuerySubmitted` for accept vs. create. For multi mode, bind the selected set to an `ObservableCollection<string>` and render each entry as a `Button` containing a `TextBlock` (the value) and a `SymbolIcon Symbol="Cancel"` (removal), laid out in a wrapping `ItemsRepeater`. `INotifyCollectionChanged` keeps the flyout's list and the chip rendering in sync.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/entity-chooser.tsx` | unverified |

## Design Decisions

- **Decision**: Compose `ListChooser`, don't fork it.
  **Rationale**: All list, filter, roving-keyboard, and add-new behavior is `ListChooser`'s; `EntityChooser` only layers selection semantics (single value vs. set + chips). One authoritative home for the list/keyboard logic; the chooser stays disposable.
  **Approved**: pending
- **Decision**: Multi mode is repeated single-accept, kept open across commits, not a bespoke multi-select.
  **Rationale**: Rather than re-writing `ListChooser` to toggle rows in a persistent selection list (a different keyboard model), multi mode reuses the single-accept engine and passes `keepOpenOnCommit` so the browser stays open after each accept — one open can add as many entries as needed (see **trigger-label-only-multi**, **add-to-set-multi**). The set lives in the parent, and selected options are hidden so the browser never re-offers them. Simpler, fully accessible, zero duplication of keyboard logic.
  **Approved**: pending
- **Decision**: Chips reuse the `RemovableChip` component.
  **Rationale**: So tag editing looks and reads the same everywhere the component is used.
  **Approved**: pending
- **Decision**: Pass `value=null` to the inner `ListChooser` in multi mode.
  **Rationale**: Keeps the trigger reading "Choose…" (an add affordance) rather than echoing a single committed value.
  **Approved**: pending
- **Decision**: Offer a `selectionPlacement="host"` option for layout flexibility.
  **Rationale**: When the chip set is rendered inline with the trigger, a wrapping multi-line group cannot keep a fixed column width. Handing the chips to the host lets the host draw them in a separate area (e.g., a different row or column) and keep the trigger's width stable and aligned with fields above/below.
  **Approved**: pending
- **Decision**: Provide no built-in async state.
  **Rationale**: `options` is a controlled in-memory prop; the caller owns fetching/loading/error — consistent with the sibling form controls.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`screen-reader-support` and `keyboard-navigable` rest on the `aria-label`/role wiring described in Accessibility and the delegation to `ListChooser`'s keyboard model (**delegate-list-behavior**); `touch-target-size` is `partial` because the source sets no explicit sizing for the trigger or chip-remove controls, so compliance depends on inherited styling this file can't verify. `separation-of-concerns` is `passed` because the list/keyboard/add-new logic lives entirely in `ListChooser`, leaving this file only the single/multi selection semantics; `unit-test-coverage` is `passed` because `entityChooser.test.tsx` renders `EntityChooser` directly and exercises both single and multi selection.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Reshaped Design Decisions into `**Decision**`/`**Rationale**`/`**Approved**` line triples, marking each decision's approval status as pending. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename Behavioral Requirements to subject-only kebab-case and narrow forward-allow-create's scope; add show-trigger-value-single, trigger-label-only-multi, and host-mode-renders-trigger-only requirements; resolve the "browser stays open" contradiction between Overview/Design Decisions and the test vectors; add/renumber Conformance Test Vectors for value replacement, the null-trigger case, the multi trigger-label case, and host mode; add an EntitySelectionChips configuration table; rewrite Localization to list the hardcoded default strings; correct the Compliance table to canonical links, add missing accessibility checks, and mark touch-target-size partial; fix WinUI 3 (single native approach, real Symbol names) and Compose (InputChip) Platform Notes and drop the off-platform watchOS aside; move the guideline reference from references to related and set references to []; declare the RemovableChip dependency; remove list-chooser's duplicate related entry; fix the States/Localization empty-hint string mismatch; and remove the app-specific example from Overview. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Revise recipe: fix domain URI, add missing test vectors, document selectionPlacement host mode, clarify Platform Notes with all five platforms, add Edge Cases entry for host mode, refine Behavioral Requirements naming. |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial component + recipe. |
