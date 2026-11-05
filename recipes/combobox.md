---
id: 43c55f5e-d9b3-430b-9026-d0af510fda15
title: Combobox
domain: adhsdk://recipes/combobox
type: ingredient
version: 1.2.1
status: review
language: en
created: '2026-06-26'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Free-text input that reveals matching suggestions as you type — keyboard-selectable, with correct combobox ARIA. Replaces the native datalist."
platforms:
- typescript
- web
tags:
- component
- combobox
- autocomplete
- input
- ui
depends-on: []
related:
- adhsdk://recipes/list-chooser
- adhsdk://recipes/option-menu
references:
- https://base-ui.com/react/components/autocomplete
approved-by: ''
approved-date: ''
---

# Combobox

## Overview

`Combobox` is a free-text input that reveals a popup of matching suggestions as
the user types. The input's text is the value; the suggestions are hints the user
may pick with the keyboard (Up/Down to move, Enter to pick, Esc to close) or the
pointer. It is the accessible replacement for the native `<datalist>` pattern used
ad hoc across sites, giving every site one styled, keyboard-correct autocomplete.

It wraps Base UI's headless `Autocomplete` primitive (`@base-ui/react/autocomplete`)
rather than hand-rolling the keyboard and ARIA: Base UI renders the input with
`role="combobox"` and manages `aria-expanded`, `aria-controls`, and
`aria-activedescendant`, case-insensitive substring filtering, and the floating
popup. The wrapper's job is purely to theme those parts with `apt-*` tokens and
expose a small controlled `value` / `onValueChange` API. It differs from
`ListChooser`, which is a disclosed chooser with a trigger, an always-visible list,
an add-new affordance, and an OK/Cancel commit step.

## Behavioral Requirements

- **renders-combobox-role**: The text input MUST expose `role="combobox"` and, while collapsed, `aria-expanded="false"`.
- **type-reveals-suggestions**: Typing MUST open the popup and show only the suggestions whose text contains the query as a case-insensitive substring.
- **empty-shows-message**: When the query matches no suggestion, the popup MUST show the empty message rather than an empty box.
- **arrow-moves-active**: ArrowDown / ArrowUp MUST move the active suggestion, reflected via `aria-activedescendant` on the input.
- **enter-picks-active**: Enter MUST pick the active suggestion, filling the input with its text via `onValueChange`, and close the popup. When no suggestion is active, Enter MUST leave the input's text unchanged.
- **escape-closes**: Esc MUST close the popup without changing the input's current text.
- **pointer-pick**: A pointer click on a suggestion MUST pick it (fill the input) and close.
- **controlled-value**: The input MUST reflect the `value` prop and report every edit through `onValueChange`.
- **aria-controls-listbox**: While open, the input's `aria-controls` MUST reference the rendered listbox element.
- **disabled-inert**: When `disabled`, the input MUST be non-interactive and MUST NOT open the popup.
- **current-value-marked**: The suggestion row whose text equals the current `value` MUST show a check mark.

## Appearance

```
┌─────────────────────────────┐
│ ap|                         │   ← text input (role="combobox")
└─────────────────────────────┘
┌─────────────────────────────┐
│ ✓ Apple                     │   ← suggestion popup (filtered, anchored to the input)
│   Apricot                   │   ← active row highlighted as you arrow through
└─────────────────────────────┘
```

- Input: the shared `Input` visual language — `apt-border`, `apt-bg` background, `apt-text`, `placeholder:text-apt-text-dim`, `focus-visible` ring `apt-gold/25`.
- Popup: `apt-surface` background, `apt-border`, `shadow-lg`, anchored under the input at the input's width (`--anchor-width`), capped by `--available-height`, scrolls when long.
- Rows: dropdown row treatment — active row `bg-apt-highlight/15`; a check (`apt-gold`) marks the row equal to the current value.
- Empty: muted `apt-text-muted` message.
- No raw hex; no `!important`.

## States

| State | Appearance change |
|---|---|
| Idle / collapsed | input only; `aria-expanded="false"` |
| Focused | `focus-visible` ring `apt-gold/25` |
| Typing, matches | popup open with filtered suggestions |
| Typing, no match | popup open with the empty message |
| Active suggestion | `bg-apt-highlight/15` on the active row; `aria-activedescendant` set |
| Disabled | dimmed; non-interactive; popup cannot open |

The control filters the in-memory `items` prop synchronously, so it owns no
intrinsic loading or error state; a caller fetching suggestions passes the resolved
array (an async caller can show its own spinner alongside).

## Accessibility

- Input: `role="combobox"` with `aria-expanded`, `aria-controls` (the listbox), and `aria-activedescendant` (the active option) — all supplied by Base UI's `Autocomplete.Input`. `ariaLabel` is required and always renders as `aria-label` on the input; a non-empty `aria-label` outranks an external `<label htmlFor>` in accessible-name computation, so pairing an `id` with an external label does not make `ariaLabel` optional or change which text wins as the accessible name.
- Popup list: `role="listbox"`; each suggestion `role="option"` with `data-highlighted` on the active row.
- Keyboard: ArrowDown / ArrowUp move the active option, Enter picks it, Esc closes — handled by the primitive.
- Focus stays in the input throughout (the active option is tracked via `aria-activedescendant`, not DOM focus).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-combobox-role | render | input has `role="combobox"`, `aria-expanded="false"` |
| T2 | type-reveals-suggestions | set query "Vu", open | only "Vue" shown; non-matches absent |
| T3 | aria-controls-listbox | open | input `aria-controls` equals the listbox id |
| T4 | arrow-moves-active, enter-picks-active | open "S", ArrowDown, Enter | `aria-activedescendant` → "Svelte"; value becomes "Svelte"; popup closes |
| T5 | escape-closes | open "V", Esc | `aria-expanded="false"`; value unchanged from before Esc |
| T6 | empty-shows-message | set query "zzz", open | empty message shown; no options |
| T7 | controlled-value | edit text | `onValueChange` fires with the new text |
| T8 | pointer-pick | open "Ap", pointer click the "Apple" row | value becomes "Apple" via `onValueChange`; popup closes |
| T9 | disabled-inert | render with `disabled`, press ArrowDown, then type a character | popup does not open; input does not receive the keystroke |
| T10 | current-value-marked | set `value` to "Vue", open | the "Vue" row shows a check mark; other rows do not |

## Edge Cases

- **Free text with no match.** The typed text remains the value; the popup shows the empty message. The input is not forced to a suggestion.
- **Duplicate suggestion strings.** Each row is keyed by its string value (`key={item}`), so callers MUST de-duplicate `items` before passing them in — duplicate strings would share a React key and produce undefined rendering behavior.
- **Long lists.** The popup scrolls within `--available-height`; the active row scrolls into view via the primitive.
- **Picking equals current text.** Re-picking the row already equal to the value is a no-op edit.
- **Opening method.** In a real browser the popup opens as the user types; programmatic tests open it with an ArrowDown keydown (the first ArrowDown opens, the next highlights).

## Configuration

| Option | Type | Required | Default | Description |
|---|---|---|---|---|
| `items` | `readonly string[]` | Yes | — | Suggestions, filtered case-insensitively as the user types. |
| `value` | `string` | Yes | — | Controlled input text. |
| `onValueChange` | `(value: string) => void` | Yes | — | Fired on every edit and on pick. |
| `ariaLabel` | `string` | Yes | — | Required; labels the input. |
| `placeholder` | `string` | No | — | Input placeholder. |
| `emptyLabel` | `string` | No | `"No matches"` | Popup text when nothing matches. |
| `disabled` | `boolean` | No | `false` | Disables the control. |
| `className` | `string` | No | — | Extra classes for the input. |
| `id` | `string` | No | — | Optional input id (to pair with an external `<label htmlFor>`). |

## Deep Linking

Not applicable: Combobox is a form control embedded in a page, not a routable destination, so deep linking does not apply.

## Localization

All localizable strings (`ariaLabel`, `placeholder`, `emptyLabel`) are passed as component props by the caller, giving full control over localization; the only source-side default is `emptyLabel = "No matches"`, which callers should override for non-English locales. Substring filtering as the user types is delegated entirely to Base UI's `Autocomplete` primitive, which does a simple case-insensitive comparison; the wrapper does not override this, so locale-specific casing rules (for example, the Turkish dotted/dotless `I`) are not specially handled — Base UI's default comparison is accepted as-is.

## Accessibility Options

| Option | Behavior |
|---|---|
| Reduce Motion | Not applicable — the wrapper applies no transition or animation classes to the input or the popup; open/close is an immediate mount/unmount. |
| Increase Contrast | The focus-visible ring (`ring-apt-gold/25`) and the active-row tint (`bg-apt-highlight/15`) are translucent overlays; under Increase Contrast they SHOULD render as solid, higher-contrast fills so the focus and active states stay distinguishable against `apt-surface` / `apt-bg`. |
| Differentiate Without Color | The active row is also identified via `aria-activedescendant` / `data-highlighted`, not color alone; the current-value row adds a check-mark glyph rather than relying on color alone. |

## Feature Flags

Not applicable: Combobox is a presentational component with no feature toggles or runtime configuration flags.

## Analytics

Not applicable: This component is a presentational form control that emits no structured analytics events.

## Privacy

Not applicable: Combobox is a presentational form control; it does not collect, store, or transmit user data.

## Logging

No logging. Combobox is a presentational form control; it emits no structured log events.

## Platform Notes

- **Web (React)**: New file `packages/web/packages/ui/src/components/combobox.tsx`. Wraps Base UI's headless `Autocomplete` primitive. Export covered by the existing `./components/*` wildcard in `packages/web/packages/ui/package.json`. Dependency on `@base-ui/react/autocomplete` already present in `@adh-sdk/ui`. The popup is sized to Base UI's `--anchor-width` and capped by `--available-height` CSS custom properties, so it always matches the input's width and stays within the viewport at any breakpoint without component-specific responsive code.
- **SwiftUI**: Use a `TextField` with the `.textInputSuggestions` modifier (or `.searchSuggestions` when composed with `.searchable`) to present suggestions without handing focus to a `Menu`; bind the text to the input value and drive the suggestion list from a locally filtered `[String]`. Track the highlighted suggestion with local state and mirror Base UI's `aria-activedescendant` pattern by moving `.accessibilityFocused` to the highlighted suggestion view.
- **Compose**: Use `ExposedDropdownMenuBox` with an editable `TextField` as its anchor and its `ExposedDropdownMenu` for the suggestion list; filter suggestions on text change, dismiss on pick or Escape via `onDismissRequest`, and expose the active item through `Modifier.semantics` so assistive tech has an equivalent to `aria-activedescendant`.
- **AppKit / UIKit**: On AppKit, use `NSComboBox` (or an `NSTextField` with its built-in completion API) rather than hand-rolling a popover — both already provide native filtering, keyboard navigation, and `NSAccessibilityComboBoxRole`. UIKit has no native combobox equivalent, so pair a `UITextField` with an anchored `UITableView`/`UICollectionView` popover, and mirror the combobox semantics explicitly by exposing the field with `UIAccessibilityTraits` (e.g. `.adjustable`) and an `accessibilityValue` that announces the active suggestion, rather than an unnamed "ARIA equivalent."
- **WinUI 3**: Use `AutoSuggestBox` with its built-in filtering and suggestion list: bind `ItemsSource` to the filtered items, handle `TextChanged` (checking `args.Reason == AutoSuggestionBoxTextChangeReason.UserInput` so programmatic text changes don't re-filter), handle `SuggestionChosen` to fill the text on pick, and handle `QuerySubmitted` for the Enter-key commit. Keyboard navigation (Up/Down, Enter, Escape) is handled by `AutoSuggestBox`'s built-in roving focus.

## Design Decisions

**Decision**: Wrap the headless primitive, don't hand-roll. Combobox ARIA (`role`, `aria-expanded`, `aria-controls`, `aria-activedescendant`), roving activation, filtering, and floating-popup positioning are handled by Base UI's `Autocomplete`.
**Rationale**: Reimplementing these would be error-prone and inconsistent with the rest of `@adh-sdk/ui`, which already composes Base UI primitives.
**Approved**: pending

**Decision**: Replace the native `<datalist>` pattern rather than use it directly.
**Rationale**: `<datalist>` cannot be styled to match the design system, and its screen-reader and keyboard support varies significantly across browsers; a themed, keyboard-correct wrapper gives every site one consistent, accessible autocomplete instead.
**Approved**: pending

**Decision**: Autocomplete, not Combobox/Select. Base UI's `Autocomplete` primitive is used rather than the selection-oriented `Combobox`.
**Rationale**: The value is the free text the user types (datalist semantics), not a fixed selection from a set of options, so `Autocomplete` is the matching primitive.
**Approved**: pending

**Decision**: Suggestions are plain strings, not `{value, label}` objects.
**Rationale**: Plain strings mirror the `<datalist>` pattern this component replaces; richer item shapes belong to `ListChooser` / `OptionMenu`.
**Approved**: pending

**Decision**: The wrapper adds theme only, no additional behavior beyond styling and the controlled `value`/`onValueChange` surface.
**Rationale**: Keeping the wrapper disposable and easy to track against upstream Base UI changes.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | Security |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`passed` rows (role/ARIA wiring, roving `aria-activedescendant` focus, Unicode-safe string handling, and text rendered only as JSX text nodes rather than `dangerouslySetInnerHTML`) are shown directly in the source; `partial` rows (dynamic type via Tailwind's rem-based `text-sm`, the `apt-*` token contrast ratios, and the hardcoded `emptyLabel` default) depend on values the source alone can't confirm or leaves as an overridable default; `touch-target-size` is `failed` because the suggestion rows (`px-2 py-1.5` with `text-sm`) render well under the 44×44pt / 48×48dp minimum. `separation-of-concerns` passes because `combobox.tsx` does nothing but forward props onto `@base-ui/react`'s `Combobox` primitive with Tailwind classes, carrying no business logic of its own. `unit-test-coverage` passes because `src/__tests__/combobox.test.tsx` exercises the component with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | ariaLabel now required/always-wins; restored on-main "recipe" wording; Compliance best-practices added. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: replaced nonexistent WinUI 3 `AutoSuggestBox` members and hand-rolled SwiftUI/AppKit/UIKit notes with real native controls; reformatted Design Decisions into Decision/Rationale/Approved blocks and added one for `<datalist>`'s shortcomings; replaced unsupported verification claims in the Web and AppKit/UIKit notes with grounded statements; added a Required column and rule to Configuration for `ariaLabel`; built a real Compliance table; fixed the active-row `apt-highlight`/`apt-gold` contradiction between Appearance/States and the source; clarified `escape-closes` and `enter-picks-active` wording; required de-duplicated `items` in Edge Cases; added `current-value-marked` requirement and test vector; added `pointer-pick`, `disabled-inert`, and Esc-unchanged test vectors; filled in Localization and Accessibility Options. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Add missing template sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy) as not applicable; fix domain URI to use agenticdevelopercookbook scheme; expand Platform Notes with cross-platform guidance. |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial component + recipe. |
