---
id: dffc1431-7386-4acf-94bc-6043c5c7eebc
title: ToggleGroup
domain: adhsdk://recipes/toggle-group
type: ingredient
version: 1.2.1
status: review
language: en
created: '2026-07-03'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A segmented control — mutually-exclusive option buttons on the field shell; gold fill marks the pressed item."
platforms:
- typescript
- web
tags:
- component
- toggle-group
- segmented-control
- forms
- ui
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# ToggleGroup

## Overview

The shared `ToggleGroup` in `@adh-sdk/ui` — a segmented control, i.e. a row of
mutually-exclusive option buttons (e.g. a light/dark/system theme switcher, or a
left/center/right alignment picker). It is built on Base UI's `ToggleGroup` +
`Toggle` primitives so it stays consistent with the family's other base-ui
primitives (radio/switch), and it is themed entirely from `apt-*` tokens: the group
sits on the shared field shell and the pressed item takes a gold fill.

Two exports ship from `@adh-sdk/ui/components/toggle-group`:

- `ToggleGroup` — the container. It renders the Base UI `ToggleGroup` on the
  `fieldShellClass` (border + `apt-bg`) as an `inline-flex w-fit` row with `gap-1 p-1`.
- `ToggleGroupItem` — one option button. It renders the Base UI `Toggle`, styled as an
  `h-8` pill that shows muted text at rest, brightens on hover, takes a
  `focus-visible` gold ring, and — when pressed (`data-[pressed]`) — fills gold with
  `apt-bg` text.

Base UI's value model is always `string[]`. For a **single-select** control (the
common segmented-control case) leave `multiple` at its default (false) and pass
`value={[selected]}`; in `onValueChange` read `next[0]` and ignore the empty array
(clicking the already-pressed item would otherwise deselect it — a segmented control
always keeps one selection). Both props forward straight through to the Base UI
primitive, so multi-select and uncontrolled use are available by setting `multiple`
and/or `defaultValue`.

## Behavioral Requirements

- **renders-item-toggle-buttons**: The component MUST render each `ToggleGroupItem` as a real, focusable toggle button carrying its `value`.
- **marks-selected-item-pressed**: The component MUST mark the item whose `value` is in the group's current value as pressed (`data-[pressed]`).
- **pressed-item-gold-fill**: The pressed item MUST show the gold fill treatment (`bg-apt-gold` with `text-apt-bg`), visually distinct from the muted rest state.
- **emits-value-on-select**: Selecting an item MUST call `onValueChange` with the group's next value array.
- **single-select-via-value-array**: When driven single-select (`value={[selected]}`, `multiple` unset), the component MUST reflect exactly the one item in that array as pressed.
- **keyboard-operable**: A focused item MUST be operable by keyboard (arrow-key roving focus between items and Enter/Space activation), per the Base UI ToggleGroup primitive.
- **focus-visible-ring**: A keyboard-focused item MUST show a visible focus ring (`focus-visible:ring-2 ring-apt-gold/40`).
- **disabled-item-inert**: A disabled item MUST NOT respond to pointer input, MUST be skipped during roving keyboard navigation, and MUST render dimmed (`opacity-50`, `pointer-events-none`).
- **forwards-group-and-item-props**: The component MUST forward arbitrary props (incl. `aria-label`, `className`, `multiple`, `defaultValue`) to the underlying Base UI group and item primitives.
- **single-select-keeps-selection**: When driven single-select (`value={[selected]}`, `multiple` unset), the consumer MUST ignore the empty array from `onValueChange` (the deselect case) so the group keeps exactly one item pressed at all times.

## Appearance

```
┌─────────────────────────────────┐   field shell (border + apt-bg, p-1)
│ ┌───────┐ ┌────────┐ ┌────────┐ │
│ │ Left  │ │ Center │ │ Right  │ │   Center pressed → gold fill
│ └───────┘ └────────┘ └────────┘ │
└─────────────────────────────────┘
   muted     GOLD       muted
```

- Group: `fieldShellClass` (`rounded-lg border border-apt-border bg-apt-bg`) +
  `inline-flex w-fit items-center gap-1 p-1`; extra classes merge via `cn()`.
- Item: `inline-flex h-8 min-w-8 items-center justify-center gap-1.5 rounded-md px-3`,
  `text-sm font-medium`, `text-apt-text-muted` at rest, `hover:text-apt-text`.
- Pressed item: `data-[pressed]:bg-apt-gold data-[pressed]:text-apt-bg`.
- Focus: `focus-visible:ring-2 focus-visible:ring-apt-gold/40`.
- Icons inside items are sized `size-4`, `shrink-0`, `pointer-events-none`.
- No raw hex; no `!important`.

## States

| State | Appearance change |
|---|---|
| Rest (unpressed) | Muted text (`text-apt-text-muted`) on the transparent pill |
| Hover | Text brightens to `text-apt-text` |
| Focus-visible | Gold focus ring (`ring-2 ring-apt-gold/40`) |
| Pressed (selected) | Gold fill: `bg-apt-gold` + `text-apt-bg` |
| Pressed + hover | Pressed treatment holds: `data-[pressed]:text-apt-bg` wins over `hover:text-apt-text`, so hovering a pressed item keeps legible text on the gold fill |
| Disabled | `opacity-50`, `pointer-events-none` |

## Accessibility

- Built on Base UI `ToggleGroup` + `Toggle`, so items are real toggle buttons with
  correct pressed semantics and roving-focus keyboard support (arrow keys move focus
  between items; Enter/Space activates) out of the box.
- The pressed/selected item is conveyed via the Base UI toggle's pressed state, not
  color alone — the `data-[pressed]` gold fill is the visual layer on top of it.
- Focus is shown with a visible `focus-visible` gold ring built from tokens.
- The group SHOULD carry an `aria-label` (or `aria-labelledby`) naming what is being
  chosen — the demo uses `aria-label="Alignment"` — since a bare group of buttons is
  ambiguous to AT.
- Disabled items are exposed as disabled and are not focusable/operable.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-item-toggle-buttons | render group with items `left`/`center`/`right` | three focusable toggle buttons, one per value |
| T2 | marks-selected-item-pressed, single-select-via-value-array | `value={["center"]}` | the `center` item has `data-pressed`; the others do not |
| T3 | pressed-item-gold-fill | `value={["center"]}` | the pressed item carries `bg-apt-gold` + `text-apt-bg` |
| T4 | emits-value-on-select | click the `right` item | `onValueChange` called with `["right"]` |
| T5 | single-select-via-value-array | in the demo, click `right` then read `next[0]` | selection becomes `right`; exactly one item pressed |
| T6 | keyboard-operable (Playwright) | focus first item, press ArrowRight then Enter | focus moves to next item; that item activates |
| T7 | focus-visible-ring (Playwright) | tab focus onto an item | item shows `ring-2 ring-apt-gold/40` |
| T8 | disabled-item-inert | render an item with `disabled` and click it | no `onValueChange`; item renders `opacity-50` |
| T9 | single-select-keeps-selection | in the demo, click the already-pressed `right` item | `onValueChange` is called with `[]`; the single-select consumer ignores the empty array and its selection stays at `right` |
| T10 | disabled-item-inert, keyboard-operable | render `left`/`center` (disabled)/`right`, focus `left`, press ArrowRight | focus moves to `right`, skipping the disabled `center` item |

## Edge Cases

- **Deselect guard (single-select):** clicking the already-pressed item makes Base UI
  emit an empty array; the single-select consumer reads `next[0]` and ignores the
  empty array so the control always keeps exactly one selection (see the demo).
- **Value not among items:** if `value` names a value no item carries, no item is
  pressed until a valid value is selected.
- **Multi-select:** setting `multiple` lets the value array hold several values; each
  matching item shows pressed independently.
- **Uncontrolled use:** passing `defaultValue` (instead of `value`) lets Base UI own
  the selection state internally.
- **All items disabled:** the group renders but nothing is operable.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `value` | `string[]` | — | Controlled selection. Single-select: pass `[selected]`. |
| `onValueChange` | `(next: string[]) => void` | — | Fired with the next value array; single-select reads `next[0]`. |
| `defaultValue` | `string[]` | — | Uncontrolled initial selection (Base UI owns state). |
| `multiple` | `boolean` | `false` | Allow more than one pressed item. |
| `className` | `string` | — | Extra classes for the group shell; merged via `cn()`. |
| `...props` | Base UI `ToggleGroup.Props` | — | All group props (incl. `aria-label`, `disabled`) forwarded. |

`ToggleGroupItem` props:

| Option | Type | Default | Description |
|---|---|---|---|
| `value` | `string` | — | The value this item represents in the group. |
| `disabled` | `boolean` | `false` | Makes the item inert and dimmed. |
| `className` | `string` | — | Extra classes for the item pill; merged via `cn()`. |
| `...props` | Base UI `Toggle.Props` | — | All toggle props forwarded; `children` may include an icon + label. |

## Deep Linking

Not applicable: ToggleGroup is a shared component within a React library, not a top-level page or feature.

## Localization

ToggleGroup itself defines no user-facing strings, but it forwards whatever text a consumer
passes straight through with no translation layer of its own. Consumers MUST pass localized
item labels (the `children` of each `ToggleGroupItem`) and a localized `aria-label` (or
`aria-labelledby`) on the group, per **forwards-group-and-item-props**.

## Accessibility Options

ToggleGroup does not implement dedicated Reduce Motion, Increase Contrast, or Differentiate
Without Color handling of its own. The rest/hover/pressed treatments in the source
(`hover:text-apt-text`, `data-[pressed]:bg-apt-gold`, `transition-colors`) are plain color and
transition utilities with no `prefers-reduced-motion` or `forced-colors` media query, so their
behavior under those OS settings is whatever the browser applies by default, not an
accommodation Base UI or the component makes.

## Feature Flags

Not applicable: ToggleGroup is a shared component; feature gating belongs to the consumer application.

## Analytics

Not applicable: ToggleGroup is a presentational control; telemetry belongs to the consumer's `onValueChange` event handler.

## Privacy

Not applicable: ToggleGroup is a presentational control with no data collection, storage, or transmission.

## Logging

No logging. `ToggleGroup` is a presentational control; the meaning of a selection and
any telemetry belong to the consumer's `onValueChange` handler, not the control.

## Platform Notes

- **React/Web**: File: `packages/web/packages/ui/src/components/toggle-group.tsx`. Built on `@base-ui/react/toggle-group` + `@base-ui/react/toggle`; the group sits on `fieldShellClass` exported from `./input`, keeping it visually aligned with the other field-shell inputs. Carries `"use client"` (Base UI interactivity). Demo: `ui-showcase` Topic `toggle-group` (regenerate `sources.generated.ts` after source changes via `gen-sources.py`). Token-driven so it themes with the rest of `@adh-sdk/ui`.
- **SwiftUI**: Start from `Picker` with `.pickerStyle(.segmented)`, which already supplies roving keyboard focus and accessibility for free — do not reach for `.keyboardShortcut()`, which binds a specific key/character shortcut, not arrow-key navigation. Apply a border using `.border()`, and tint the selected segment from the toolkit's gold accent token (its Apple theme equivalent of `apt-gold`) rather than a hardcoded `Color` literal.
- **Compose**: Start from Material 3's `SingleChoiceSegmentedButtonRow` with `SegmentedButton` children, which supply pressed/selected state, focus, and arrow-key handling out of the box — drop manual `Modifier.focusable()` + key handlers. Track selection in a `mutableStateOf` and apply the toolkit's gold accent token to the selected button instead of a literal gold background.
- **AppKit / UIKit**: Use `NSSegmentedControl` (macOS) or `UISegmentedControl` (iOS), which already provide roving keyboard focus, activation, and a built-in pressed/selected state — no `UIKeyCommand` or custom appearance proxy needed (`NSSegmentedControl` has none). Tint the selected segment via `selectedSegmentBezelColor` (AppKit) or `selectedSegmentTintColor` (UIKit), set from the toolkit's gold accent token. Implement disabled state via the control's built-in `isEnabled` property.
- **WinUI 3**: Use the Windows Community Toolkit `Segmented` control, or `RadioButtons`/`ListView` with `SelectionMode="Single"` — each already supplies pressed/selected items with roving keyboard focus built in. Avoid composing an `ItemsControl` with plain `Button` items, which has no pressed/selected visual state and would need manual `KeyDown` handling. Bind to a view-model property for selection and apply the toolkit's gold accent token to the selected item via a `VisualState` or resource override.

## Design Decisions

**Decision**: Use Base UI's `ToggleGroup` + `Toggle` primitives rather than a bespoke button row.
**Rationale**: Reusing the Base UI primitive gives correct pressed semantics and roving-focus keyboard support for free and keeps the control consistent with the family's other base-ui primitives (radio/switch).
**Approved**: pending

**Decision**: Build the group container on the shared `fieldShellClass`.
**Rationale**: Borrowing the field shell lets a segmented control read as a peer of the other form fields rather than a loose row of buttons.
**Approved**: pending

**Decision**: Treat single-select as a `value={[selected]}` convention on the same component rather than a separate variant.
**Rationale**: Base UI's value is always `string[]`; documenting the `value={[selected]}` + `next[0]` + ignore-empty pattern lets one component cover both single- and multi-select instead of forking a single-select variant.
**Approved**: pending

**Decision**: Give the pressed item a single gold fill treatment (`bg-apt-gold` + `text-apt-bg`).
**Rationale**: A single, token-only pressed treatment reads clearly against the muted rest state without per-item color rules.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | partial | Platform Compliance |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Passed and partial rest on the source: Base UI's `ToggleGroupPrimitive`/`TogglePrimitive` give real button semantics, pressed state, and roving keyboard focus (screen-reader-support, keyboard-navigable, native-controls-preference); the `apt-*` token classes theme light/dark but carry no `forced-colors` rule or verified contrast ratio (contrast-ratio, platform-theming partial); the item's `h-8 min-w-8` size is below the 44×44 this check names (touch-target-size partial); and the component's own source defines no literal user-facing strings (no-hardcoded-strings); `ToggleGroup`/`ToggleGroupItem` are thin themed wrappers around Base UI primitives with no logic of their own (separation-of-concerns passed), and there is no test file dedicated to this source — it is exercised only through `splitViewControl.test.tsx`'s parent component, which clicks its rendered buttons but never asserts on its own pressed-state styling (unit-test-coverage partial).

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: point platform notes at native segmented controls and theme tokens instead of hand-rolled widgets and literal colors; correct the accessibility-options contrast claim; rewrite Compliance with real catalog checks; reformat Design Decisions as Decision/Rationale/Approved triplets; add single-select-keeps-selection and extend disabled-item-inert; add a Pressed+hover state and two conformance vectors; clarify Localization for consumer-supplied labels; trim the summary. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Complete recipe with all template sections; add platform notes for SwiftUI, Compose, AppKit/UIKit, WinUI 3; mark non-applicable sections. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the Base UI segmented control and its single-select convention. |
