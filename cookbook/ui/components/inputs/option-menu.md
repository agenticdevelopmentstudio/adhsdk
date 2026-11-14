---
id: 4d0e04ff-39eb-472c-93a0-8070f1b64a6a
title: "OptionMenu"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-06-26
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Single-select popup menu with full keyboard navigation and an optional editable Other free-text item."
platforms:
  - typescript
  - web
tags:
  - component
  - option-menu
  - menu
  - ui
depends-on:
  - c61a220c-b63e-4dcd-a12b-715de20f7b5d
  - 0f5b7167-b375-4f44-977b-566f720a453d
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
related:
  - fba584ed-a87c-4223-a4a9-de9c6dd342d3
  - bf49f12b-61cd-4e34-b395-0b6e5fe715a2
references: []
approved-by: ""
approved-date: ""
---

# OptionMenu

## Overview

`OptionMenu` is a single-select "popup menu": a trigger button that discloses a
list of choices with full keyboard navigation, plus an optional editable
**"Other"** item as the last entry. It is a general-purpose popup menu for forms
(example: a "How did you hear about us?" field with a free-text fallback). It
is built by composing existing primitives — `Popover` (surface), `Input` (the
Other field), `Button` (the OK affordance) — with a hand-managed roving
**selection** so the keyboard model below is exact. It deliberately does **not**
build on `DropdownMenu` / Base-UI menu: menu roles hijack typeahead and focus and
fight an embedded text input. It is distinct from the rail filter `PopupMenu`
block (`@adh-sdk/ui/blocks/popup-menu`), which keeps its own `allLabel`/`onNew`
filter semantics and is unchanged.

## Behavioral Requirements

- **trigger-opens-on-activation**: When the trigger is focused, Enter / Space / ArrowDown MUST open the surface.
- **open-initializes-selection**: On open, the highlighted selection MUST initialize to the committed item if any, else to the first item (see **other-input-focused-on-open** for where keyboard focus lands when `allowOther`, which is independent of this highlight).
- **arrow-nav-clamps**: When open, ArrowDown / ArrowUp MUST move the selection down/up, clamped at the ends (no wrap).
- **enter-commits-list-item**: When a list item is selected, Enter MUST commit it via `onChange` with `isOther:false`, then close and return focus to the trigger.
- **pointer-click-commits**: A pointer click on a row MUST commit that row immediately and close.
- **escape-closes-without-commit**: Esc MUST close the surface without firing `onChange`.
- **click-outside-closes-without-commit**: A pointer press outside the surface MUST close it without firing `onChange`, inherited from the `Popover` primitive's default outside-press behavior.
- **tab-unsupported**: The surface MUST NOT trap focus and defines no Tab handling; Tab is left to native browser focus order rather than a menu-style focus trap.
- **home-end-unsupported**: Home and End MUST NOT change the selection; they are not handled.
- **typeahead-unsupported**: Character keys MUST NOT perform typeahead selection, per the Overview's rationale for not building on menu roles.
- **focus-returns-on-close**: On any close, focus MUST return to the trigger.
- **selection-not-commit**: Changing the roving selection MUST NOT fire `onChange`; only a commit (Enter, OK, or row click) fires it.
- **check-marks-committed-value**: While open, the check (✓) MUST mark the committed value.
- **resolves-committed-value**: The committed value MUST resolve as follows: an item whose `value` matches wins; else, when `allowOther` and `value` is non-null, Other wins and its input prefills with `value`; else nothing is committed. When the committed value is Other, opening MUST highlight Other and mark it active.
- **other-input-focused-on-open**: When `allowOther`, the Other input MUST receive focus immediately on open (caret ready to type), regardless of which row **open-initializes-selection** highlights — keyboard focus and the roving highlight are independent and need not point at the same row.
- **typing-moves-check-to-other**: Typing in the Other input MUST set the selection to Other and move the check to Other live, before commit.
- **ok-enabled-when-nonempty**: The OK button MUST be enabled iff the Other input is non-empty after trim.
- **keys-act-on-selection**: Enter, ArrowDown and ArrowUp act on the roving selection, not on which element holds keyboard focus. While the Other input is focused but the selection is a list item (for example on open with `allowOther`, or after the pointer moved the highlight), Enter MUST commit that list item with `isOther:false` and ArrowDown MUST move the selection down from it; typing in the input first sets the selection to Other (see **typing-moves-check-to-other**), after which Enter commits the Other text. ArrowUp from the focused Other input always follows **arrowup-from-other-moves-to-list**.
- **arrowup-from-other-moves-to-list**: ArrowUp from the Other input MUST move the selection to the last list item above Other and blur the input.
- **arrowdown-from-last-item-to-other**: ArrowDown from the last list item MUST return the selection to Other and re-focus the input.
- **enter-commits-other-when-nonempty**: When Other is the active selection and its input is non-empty, Enter MUST commit the trimmed text via `onChange` with `isOther:true`, then close.
- **enter-noop-when-other-empty**: When Other is active but the input is empty, Enter MUST be a no-op (matching the disabled OK).
- **other-row-label-inert**: A pointer click on the Other row's label text MUST NOT commit or change the selection; only the input and OK button act on Other.
- **ok-equals-enter-for-other**: Clicking OK MUST be equivalent to Enter while Other is active with non-empty input.
- **no-items-no-op-navigation**: With an empty `items` list and `allowOther` false, the surface has no rows and arrow keys and Enter MUST be no-ops. With an empty `items` list and `allowOther` true, Other is the only row; ArrowUp from the Other input does nothing, since there is no list item above it.
- **disabled-blocks-interaction**: When `disabled`, the trigger MUST NOT open the surface; the disabled trigger is skipped by both pointer and keyboard (a disabled `<button>` receives neither).

## Appearance

Closed:

```
┌─────────────────────────────┐
│ Search engine            ▾  │   ← trigger button (label = current value or placeholder) + chevron
└─────────────────────────────┘
```

Open, no "Other":

```
┌─────────────────────────────┐
│ Search engine            ▴  │
├─────────────────────────────┤
│ ✓ Search engine             │   ← checkmark = committed value
│   Social media              │   ← highlighted row = roving selection
│   Blog post                 │
│   Newsletter                │
└─────────────────────────────┘
```

Open, with editable "Other" as the last item:

```
┌─────────────────────────────┐
│   Search engine             │
│   …                         │
│   Word of mouth             │
│ ✓ Other                     │   ← check moves here once the user types
│   [                      ]  │   ← text input — focused on open
│   [          OK          ]  │   ← disabled until the input is non-empty
└─────────────────────────────┘
```

- Trigger: same visual language as `Select`/`Input` — surface-role border and background, focus ring in the accent tone, chevron icon in the muted-text tone.
- Surface: `Popover` content; rows use the dropdown row treatment — highlighted row uses the accent tone at low opacity, text in the default tone, check icon in the accent tone.
- Other input: shared `Input`. OK: shared `Button`, small size, accent (default) variant, full width of the surface, `disabled` when empty.
- Spacing from the standard space scale; small corner radius. No raw hex values; no style overrides that bypass the token system.

See **React/Web** under Platform Notes for the concrete design tokens this implementation uses.

## States

| State | Appearance change |
|---|---|
| Trigger closed | label = committed value or placeholder; chevron down |
| Trigger focused | accent focus ring |
| Trigger disabled | dimmed; non-interactive |
| Open, no selection committed | no row checked; first row highlighted (or Other, if there are no items and `allowOther`); when `allowOther`, keyboard focus moves to the Other input regardless of which row is highlighted |
| Open, row highlighted | accent at low opacity on the roving row |
| Open, committed row | ✓ on the committed row |
| Other empty | OK disabled |
| Other non-empty | OK enabled; ✓ on Other |

## Accessibility

- Trigger: `<button>` with `aria-haspopup="listbox"`, `aria-expanded`, `aria-label={ariaLabel}`.
- Surface: the `role="listbox"` container itself (not a row) owns `aria-activedescendant`, pointing at the currently highlighted option's `id`; rows are `role="option"` with `aria-selected` on the committed row and `data-highlighted` on the selection.
- Other row: also `role="option"`, `aria-selected` mirroring whether Other is committed; it additionally contains a labeled `<input>` (`aria-label` from `otherLabel`) and the OK `<button>` (native `disabled` while the input is empty; a disabled button leaves the tab order, so it is skipped by Tab and not clickable) — an option row with focusable descendants, which departs from a plain listbox/option tree (see **screen-reader-support** in Compliance).
- Focus returns to the trigger on close.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | arrow-nav-clamps, enter-commits-list-item | open, ArrowDown ×2, Enter | the right item commits, surface closes |
| T2 | escape-closes-without-commit | open, Esc | no `onChange`; trigger refocused |
| T3 | pointer-click-commits | click a row | that row commits, closes |
| T4 | other-input-focused-on-open | open with `allowOther` | Other input is focused |
| T5 | ok-enabled-when-nonempty | type into Other | OK enabled; empty → disabled |
| T6 | typing-moves-check-to-other | type into Other | check moves to Other |
| T7 | enter-commits-other-when-nonempty | type "Foo", Enter | commits "Foo" with `isOther:true` |
| T8 | arrowup-from-other-moves-to-list | ArrowUp from Other input | selection to last list item; input blurred |
| T9 | resolves-committed-value, check-marks-committed-value | controlled `value` = an item | that item resolves checked |
| T10 | resolves-committed-value, check-marks-committed-value | controlled `value` = Other free text | Other checked, input prefilled |
| T11 | trigger-opens-on-activation | trigger focused and closed, Enter (also Space, ArrowDown) | surface opens |
| T12 | focus-returns-on-close | open, Escape | no `onChange`; DOM focus returns to the trigger |
| T13 | selection-not-commit | open, ArrowDown to move the highlight, no further key | no `onChange` fired |
| T14 | arrowdown-from-last-item-to-other | open with `allowOther`, ArrowDown to the last list item, ArrowDown again | selection moves to Other; input re-focused |
| T15 | enter-noop-when-other-empty | Other active, input empty, Enter | no `onChange`; surface stays open |
| T16 | ok-equals-enter-for-other | type "Foo" into Other, click OK | commits "Foo" with `isOther:true`, identical to Enter (T7) |
| T17 | arrow-nav-clamps | open (no `allowOther`), ArrowUp while the first item is highlighted | highlight stays on the first item (no wrap) |
| T18 | arrow-nav-clamps | open (no `allowOther`), ArrowDown while the last item is highlighted | highlight stays on the last item (no wrap) |
| T19 | open-initializes-selection | open with a committed item, before any key press | that item is highlighted immediately (independent of T9's check) |
| T20 | click-outside-closes-without-commit | open, press the pointer outside the surface | no `onChange`; surface closes |
| T21 | disabled-blocks-interaction | `disabled`, click the trigger and press Enter on it | surface stays closed; `aria-expanded` stays `false` |
| T22 | tab-unsupported | open with `allowOther`, press Tab | focus moves per native order and is not trapped in the surface; selection unchanged |
| T23 | home-end-unsupported | open, ArrowDown once, press Home then End | highlight stays on the second row; no `onChange` |
| T24 | typeahead-unsupported | open, type "S" with the surface focused | highlight does not move; no `onChange` |
| T25 | focus-returns-on-close | open, click a row | `onChange` fires; DOM focus returns to the trigger |
| T26 | keys-act-on-selection | open with `allowOther` and no committed value (input focused, first item highlighted), Enter | commits the first item with `isOther:false`, not the empty Other input |
| T27 | keys-act-on-selection | open with `allowOther` (input focused, first item highlighted), ArrowDown | selection moves to the second item |
| T28 | no-items-no-op-navigation | `items=[]`, `allowOther` false, open, ArrowDown, ArrowUp, Enter | no rows; no `onChange`; surface stays open |
| T29 | other-row-label-inert | open with `allowOther`, click the "Other" label text | no `onChange`; selection and check unchanged |
| T30 | resolves-committed-value | `value` is the Other free text and `allowOther`, open | Other is highlighted and checked; input prefilled with `value` |
## Edge Cases

- **Value resolution** (see **resolves-committed-value**). If `value` equals some `items[i].value`, that item is the committed/checked row. Else if `allowOther` and `value` is non-null, Other is the committed row and its input prefills with `value`. Else nothing is checked.
- Free text identical to an item value resolves to the item; callers needing to distinguish should avoid colliding labels. The component does not correct the earlier `onChange`: it fires with the typed text and `isOther:true`, but once the caller passes that text back as `value`, the reopened menu checks the item row, not Other, and the Other input stays empty. A caller that stores `isOther` should re-derive it from `items` rather than trust the earlier flag.
- Empty `items` without `allowOther`: the surface shows no rows, and arrow keys and Enter do nothing (see **no-items-no-op-navigation**).
- ArrowUp from the Other input with no items: no effect; selection stays on Other and the input keeps focus.
- ArrowDown while Other is already the selection: stays on Other (clamped) and re-focuses the input.
- Pointer click on the Other row's label text: no effect (see **other-row-label-inert**).
- Opening when the committed value is Other free text: Other is highlighted and active, and the input is prefilled and focused.
- Enter, ArrowUp and ArrowDown while the Other input is focused but a list item is selected: see **keys-act-on-selection**.
- `value = null` → nothing is checked.
- `allowOther = false` with no matching item → nothing is checked.

## Configuration

| Option | Type | Required | Default | Description |
|---|---|---|---|---|
| `items` | `OptionMenuItem[]` | yes | none | The selectable items (`{ value, label }`). |
| `value` | `string \| null` | yes | none | Committed value: an item value, free text (when `allowOther`), or null. |
| `onChange` | `(value: string, meta: { isOther: boolean }) => void` | yes | none | Fired on commit; `isOther` true when from the Other input. |
| `allowOther` | `boolean` | no | `false` | Enables the editable Other row. |
| `otherLabel` | `string` | no | `"Other"` | Label for the Other row. |
| `otherPlaceholder` | `string` | no | none | Placeholder for the Other input. |
| `placeholder` | `string` | no | none | Trigger text when `value` is null. |
| `ariaLabel` | `string` | yes | none | Required; labels the trigger + listbox. |
| `disabled` | `boolean` | no | `false` | Disables the control. |
| `className` | `string` | no | none | Extra classes. |
## Deep Linking

Not applicable: This is a UI component, not a full application feature that requires deep linking.

## Localization

Most user-facing strings are passed via props (`ariaLabel`, `otherLabel`, `placeholder`, `otherPlaceholder`), letting callers localize at point of use. The **OK** button's label is the exception: it is hard-coded as `"OK"` with no prop to override it, so a caller cannot localize that one string (see **no-hardcoded-strings** in Compliance).

## Accessibility Options

Not applicable: This component uses no animations that respond to accessibility preferences.

## Feature Flags

Not applicable: This is a library component with no feature-flag gating.

## Analytics

Not applicable: This is a presentational form control that does not emit analytics events.

## Privacy

Not applicable: This component handles no sensitive data and emits no telemetry.

## Logging

No logging. OptionMenu is a presentational form control; it emits no structured log events.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/ui/src/components/option-menu.tsx`. Uses a hand-managed `aria-activedescendant` selection model (tracked in component state) rather than menu roles or roving `tabindex`: DOM keyboard focus stays on the `role="listbox"` container (or the Other `<input>`) while `aria-activedescendant` points at the virtually highlighted option, letting an embedded text input coexist without focus/keyboard conflicts. The component composes `Popover`, `Input`, and `Button` primitives and manages focus via `useRef` and `requestAnimationFrame` to ensure surface focus after arrow navigation. Design tokens: trigger uses `apt-border`/`apt-surface`, `focus-visible` ring `apt-gold/25` (the accent focus ring in States), chevron (`ChevronsUpDown`) in `apt-text-muted`; rows highlight with `bg-apt-highlight/15` (the accent at low opacity in States), text `apt-text`, check icon `apt-gold`; OK is `size="sm"`, `variant="default"`; spacing from the `--space-*` scale, corners `--shape-corner-small`, no raw hex, no `!important`. Start from the source and build platform equivalents using the selection model described in Design Decisions.
- **SwiftUI**: Use a `Button` trigger with the `.popover` modifier, since `Menu` cannot host a text field. Hand-manage keyboard navigation via `onKeyPress` callbacks. Use `@FocusState` to track which element should have focus after each navigation action. The selection pattern is the same as web: track highlighted index in state, separate from what is committed.
- **Compose**: Use a `Popup` (or a `Box` surface) anchored to the trigger, since `DropdownMenu` cannot host a text field. Implement keyboard navigation via `Modifier.onPreviewKeyEvent` or a custom state machine tracking the highlighted selection. Use `FocusRequester` to move focus between the input and the list after arrow keys. Match the web component's separation of selection (transient highlight) from commitment (firing `onChange`).
- **AppKit / UIKit**: On iOS (UIKit), present a `UIViewController` as a popover (`UIPopoverPresentationController`), since `UIMenu` cannot host a text field; manage keyboard shortcuts via the responder chain and `UIKeyCommand`. On macOS (AppKit), use an `NSPopover` containing the list and input, and manage arrow/Enter/Escape handling via the responder chain's `keyDown(with:)` and `NSEvent`, not `UIKeyCommand` (an AppKit-only surface has no `UIKeyCommand`). The critical invariant is the same across all platforms: selection moves independently of commit, and only commit fires the `onChange` callback.
- **WinUI 3**: Use a `Flyout` (not `MenuFlyout`, which cannot host a `TextBox`) for the list surface. For the "Other" input, embed a `TextBox` in the flyout with a `Button` for OK. Implement keyboard navigation via `PreviewKeyDown` events on the flyout, tracking selection in app state. Ensure focus management transitions focus between list items and the input as appropriate. The selection/commitment model must match the source: the highlighted selection never fires `onChange`, only user intent (Enter, click, or OK click) does.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/option-menu.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: Hand-manage the selection (highlighted row) in component state, independent of DOM focus, instead of building on `DropdownMenu` / Base-UI menu roles.
**Rationale**: Menu roles hijack typeahead and focus and fight an embedded text input; tracking selection in state lets arrow keys work whether DOM focus is on the listbox surface or in the Other input.
**Approved**: pending

**Decision**: Keep selection and commit distinct — selection is a transient highlight that never fires `onChange`; only a commit (Enter, OK, row click) fires `onChange` and closes.
**Rationale**: Lets users browse the list with arrow keys (including into and out of the Other input) without side effects, so only a deliberate action commits a value.
**Approved**: pending

**Decision**: Hard-code the OK button label ("OK") rather than expose an `okLabel` option.
**Rationale**: The source has no `okLabel` prop, so the label cannot be localized today; this is recorded as known debt (the failed `no-hardcoded-strings` check) until an `okLabel` option is added.
**Approved**: pending
## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`keyboard-navigable` and `focus-management` pass on the trigger's Enter/Space/ArrowDown activation, the full arrow/Enter/Escape/OK keyboard model, and focus returning to the trigger on close. `screen-reader-support` and `semantic-markup` are partial because the source's Other row is a `role="option"` that contains a focusable `<input>` and `<button>`, a nesting that departs from a plain listbox/option tree (see Accessibility). `no-hardcoded-strings` fails because the OK button's label is hard-coded with no prop (see Localization). The keyboard-nav/selection state machine is defined as local functions inline in the component body rather than an extracted hook (separation-of-concerns: partial), while `optionMenu.test.tsx` renders `OptionMenu` and exercises arrow-nav commit, click commit, Escape, and the Other-row input with real assertions (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.1.2 | 2026-11-14 | Mike Fullerton | Added requirements and test vectors for the unsupported keys, outside click, disabled, focus return and the key behavior while Other is focused, filled in edge cases, added a Required column, and replaced concrete tokens in States, the replace-the-menu platform notes, and the wrong aria-disabled claim. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: name Tab/click-outside/Home-End/typeahead behavior, resolve the selection-vs-focus ordering with `allowOther`, correct WinUI 3/Compose/AppKit-UIKit platform APIs, add `depends-on`/`related` links, add a Compliance table, reformat Design Decisions, generify the Overview's app-specific example, fix the internal roving-tabindex/aria-activedescendant contradiction, correct the Localization claim about the OK label, add missing test vectors and remap T9/T10, describe Appearance with semantic roles, and document the disabled-trigger requirement. |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Add full optional sections (marked Not applicable where appropriate), fix domain URI to use agenticdevelopercookbook, and expand Platform Notes with translation guidance for all platforms. |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial conversion from legacy UI spec. |
