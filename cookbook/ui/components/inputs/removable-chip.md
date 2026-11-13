---
id: 9191eade-c18a-4899-b802-f000a1905c80
title: "RemovableChip"
type: ingredient
version: 1.3.1
status: review
language: en
created: 2026-07-03
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A Badge with a trailing ✕ remove button — the one home for the removable-chip treatment; the ✕ is a real button named removeLabel for AT."
platforms:
  - typescript
  - web
tags:
  - component
  - chip
  - badge
  - removable
  - ui
depends-on:
  - 2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f
related: []
references: []
approved-by: ""
approved-date: ""
---

# RemovableChip

## Overview

The shared `RemovableChip` in `@adh-sdk/ui` — a `Badge` with a trailing ✕ remove
affordance. It is the one home for the "removable chip" treatment (recipient chips,
tag/category chips): rather than each caller re-inventing a badge-plus-✕, they render
this element.

The chip body is the shared `Badge` (so it inherits the badge tone `variant`s and the
mono/uppercase pill styling); the ✕ is a **real `<button>`** carrying `removeLabel`
as its accessible name, so a chip reads to assistive technology as
"`<value>`, Remove `<value>`". Clicking the ✕ invokes the consumer-supplied
`onRemove` callback — the component is stateless, so the consumer owns the list and
decides what removal does (typically filtering the value out of its state).

A single export ships from `@adh-sdk/ui/components/removable-chip`: the
`RemovableChip` component.

## Behavioral Requirements

- **renders-badge-body**: The component MUST render its `children` inside a `Badge` so the chip inherits the badge tone and pill styling.
- **renders-remove-button**: The component MUST render the ✕ affordance as a real `<button type="button">`, not a bare icon or a `<span>`.
- **remove-button-named**: The remove button MUST carry `removeLabel` as its accessible name (`aria-label`).
- **invokes-onremove-on-click**: Clicking the enabled remove button MUST invoke the `onRemove` callback.
- **stateless-removal**: The component MUST NOT mutate or remove itself; it only signals `onRemove`, leaving list state to the consumer.
- **applies-badge-variant**: The component MUST pass its `variant` through to the `Badge` (default `neutral`), so callers MAY tone the chip.
- **disabled-blocks-remove**: When `disabled`, the remove button MUST be a native disabled `<button>` and MUST NOT invoke `onRemove`.
- **remove-icon-decorative**: The ✕ glyph itself MUST be hidden from AT (`aria-hidden`), leaving the button's `aria-label` as the sole accessible name.
- **forwards-chip-props**: The component MUST forward arbitrary span props (`className`, `id`, `data-*`) onto the `Badge` body.
- **keyboard-operable**: The remove button MUST be activatable via keyboard (Enter or Space), invoking `onRemove`, because it is a native `<button>` rather than a non-focusable element with a click handler.

## Appearance

```
┌──────────────────────┐
│  design-review   ✕   │   ← Badge body + trailing ✕ button
└──────────────────────┘
   value            remove
```

- Body: the shared `Badge` with `flex items-center gap-1` merged in, so the label and
  ✕ sit inline with a small gap; the badge supplies the pill (mono, uppercase,
  bordered) and the tone.
- Remove button: `text-apt-text-muted hover:text-apt-text`, `disabled:pointer-events-none`;
  contains a lucide `X` icon sized `11`, marked `aria-hidden`.
- Tone follows the `variant` prop (`neutral` default; also `accent`/`orange`/`blue`/
  `success`/`error`) resolved by `Badge`.
- No raw hex; no `!important`.

## States

| State | Appearance change |
|---|---|
| Rest | Badge in its `variant` tone; ✕ muted (`text-apt-text-muted`) |
| ✕ hover | ✕ brightens to `text-apt-text` |
| ✕ focus-visible | Native button focus indicator on the ✕ |
| Disabled | ✕ disabled + `pointer-events-none` (does not fire `onRemove`). The `Badge` body is unaffected — it keeps rendering its normal `variant` tone; `Badge` receives no `disabled` prop. |

## Accessibility

- The ✕ is a **real `<button type="button">`**, so it is focusable and keyboard-operable
  (Enter/Space) natively — removal is not pointer-only.
- The button's accessible name is `removeLabel` (`aria-label`), which callers typically
  set to a value-specific label such as `` `Remove ${value}` ``. Combined with the badge
  body, each chip reads as "`<value>`, Remove `<value>`" to AT.
- The ✕ glyph is `aria-hidden`, so the icon does not add a second, redundant label —
  the button's `aria-label` is the single accessible name.
- The chip body is a `Badge` (`<span>`); it is not itself interactive, keeping one
  clear action (remove) per chip.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-badge-body, forwards-chip-props | `<RemovableChip removeLabel="Remove x" onRemove={fn} id="c1">x</RemovableChip>` | a `data-slot="badge"` element containing "x" and carrying `id="c1"` |
| T2 | renders-remove-button, remove-button-named | same as T1 | a `<button type="button">` with `aria-label="Remove x"` |
| T3 | invokes-onremove-on-click | click the remove button | `onRemove` called once |
| T4 | stateless-removal | after T3 without consumer re-render | the chip is still in the DOM (removal is the consumer's job) |
| T5 | applies-badge-variant | `variant="success"` | the `Badge` element carries the `border-apt-green` and `text-apt-green` classes |
| T6 | disabled-blocks-remove | `disabled` then click the ✕ | button is `disabled`; `onRemove` NOT called |
| T7 | remove-icon-decorative | inspect the `X` glyph | the icon carries `aria-hidden` |
| T8 | remove-button-named, keyboard-operable (Playwright) | query by role `button` name "Remove x", then press Enter/Space while it has focus | the ✕ is found by its accessible name and `onRemove` fires on Enter/Space |

## Edge Cases

- **Removal is the consumer's job.** The chip never removes itself; it only calls
  `onRemove`. A typical caller filters the value out of its own list state; the chip
  itself is stateless.
- **Disabled chip:** the ✕ is disabled and `pointer-events-none`, so `onRemove` cannot
  fire; the chip stays put.
- **Missing accessible name:** `removeLabel` is required by the type, but the component
  does not validate its value at runtime — an empty string satisfies the type yet leaves
  the button with no meaningful accessible name. Callers pass a non-empty,
  value-specific label (`Remove ${value}`) so multiple chips have distinct button names.
- **Rich children:** `children` may be more than text (e.g. an avatar + name); it all
  renders inside the badge body inline with the ✕.
- **Empty list:** the chip renders nothing special when a list empties — the consumer
  shows its own empty state.
- **Focus after removal:** removing a chip via keyboard unmounts its remove button,
  which drops the current focus. The consumer SHOULD move focus to the next remaining
  chip's remove button, or back to the input that adds items, so a keyboard user is not
  left with focus lost to the document body. See **keyboard-operable**.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `children` | `React.ReactNode` | — | The chip label/content shown in the badge body. |
| `onRemove` | `() => void` | — | Called when the ✕ button is activated. Required. |
| `removeLabel` | `string` | — | Accessible name for the ✕ button (e.g. `Remove ${value}`). Required. |
| `variant` | `"neutral" \| "accent" \| "orange" \| "blue" \| "success" \| "error"` | `"neutral"` | Badge tone. |
| `disabled` | `boolean` | `false` | Disables the ✕ button. |
| `className` | `string` | — | Extra classes for the badge body; merged via `cn()`. |
| `...props` | `Omit<React.ComponentProps<"span">, "children">` | — | Native span props forwarded onto the `Badge`. |

## Deep Linking

Not applicable: RemovableChip is a presentational component with no navigation behavior.

## Localization

RemovableChip hardcodes no user-facing strings itself, but both `children` and
`removeLabel` are caller-supplied, user-facing text. `removeLabel` in particular is a
sentence fragment (e.g. `Remove ${value}`), not just a value substitution, so callers
MUST pass an already-localized string — building it from the current locale's messages,
not a fixed English template.

## Accessibility Options

Not applicable: RemovableChip is a simple presentational element composed of a Badge and a button; it does not respond to platform accessibility display options like Reduce Motion or Increase Contrast.

## Feature Flags

Not applicable: RemovableChip is a foundational UI component with no conditional behavior or feature gates.

## Analytics

Not applicable: RemovableChip is a stateless presentational element; the consumer's `onRemove` handler owns any telemetry or event tracking.

## Privacy

Not applicable: RemovableChip collects no data and transmits nothing; it is a presentational component.

## Logging

No logging. `RemovableChip` is a presentational element; what removal means and any
telemetry belong to the consumer's `onRemove` handler, not the chip.

## Platform Notes

- **SwiftUI**: Compose a `HStack` containing the badge body (background + rounded corner pill using `.background()` and `.clipShape(Capsule())`) and a `Button` with an `Image(systemName: "xmark")`. Apply `.buttonStyle(.plain)` to strip button styling from the remove button. Set `.disabled(disabled)` on the button. Set `.accessibilityLabel(removeLabel)` directly on the `Button` (this is its accessible name — there is no `.accessibilityRemoveAction()` modifier); optionally add `.accessibilityAction(named: Text(removeLabel)) { onRemove() }` on the chip container if a custom rotor action is also wanted. On hover or focus, brighten the icon color; apply the disabled visual state per the States table.
- **Compose**: Build a `Row` with `Modifier.border(1.dp, color)` and `Modifier.clip(RoundedCornerShape(50))` for the pill shape (percent-based, so it stays a pill regardless of height — a fixed `RoundedCornerShape(8.dp)` would not). Render content as `Text`, then an `IconButton` (not a `Button`, which clips at small sizes because of its minimum size and content padding) containing an `Icon` (Material Design `Icons.Default.Close`) with `contentDescription = removeLabel` set on the `Icon` itself. Set `enabled = !disabled` on the `IconButton`. Bind `onClick` to the remove callback. Style icon color as muted by default, brightened on hover/pressed.
- **React/Web**: File: `packages/web/packages/ui/src/components/removable-chip.tsx`. Composes the shared `Badge` (`./badge`) for the body and a lucide `X` icon for the affordance; carries `"use client"`. The remove `<button>`'s `disabled` attribute is the actual guarantee behind **disabled-blocks-remove**; `disabled:pointer-events-none` is a CSS belt-and-suspenders that also blocks pointer interaction while disabled.
- **AppKit / UIKit**: On **AppKit**, create an `NSBox` with `boxType = .custom`, `cornerRadius = 12`, and `borderColor` from the variant tone. Nest an `NSStackView` (horizontal, spacing `4`) inside it containing `NSTextField` (read-only, for content) and `NSButton` (image button) using `NSImage(systemSymbolName: "xmark", accessibilityDescription: nil)` for the glyph. Bind the button's `action` to the remove callback and set `button.accessibilityLabel = removeLabel`. On **UIKit**, create a `UIView` container with `layer.cornerRadius = 12` and `layer.borderColor`; nest a `UIStackView` (horizontal, spacing `4`) with `UILabel` and `UIButton`. Configure the button with `UIImage(systemName: "xmark")` via `setImage(_:for:)`, and bind the remove callback with `addAction(_:for: .touchUpInside)`; set `button.accessibilityLabel = removeLabel`. Set `button.isEnabled = !disabled` in both. Apply the hover and disabled visual states per the States table.
- **WinUI 3**: Create a `Border` with `CornerRadius` set to match the pill styling, wrapping a horizontal `StackPanel` (`Orientation = Horizontal`, `Spacing = 4`). Inside the `StackPanel`, render a `TextBlock` for the content and a `Button` with a `FontIcon` using the glyph `&#xE711;` (WinUI "Cancel" icon) for the remove affordance. Map the button's `Click` event to invoke the source's remove callback. Set `Button.IsEnabled = !disabled`. Use `AutomationProperties.Name` on the button to set the accessible label to `removeLabel`. Apply the hover and disabled visual states per the States table; introduce no additional visual state beyond those it defines.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/removable-chip.tsx` | unverified |

## Design Decisions

**Decision**: Use a real `<button type="button">` for the ✕, not a clickable icon.
**Rationale**: An `aria-label`-carrying native button gives keyboard operability and a clear accessible name for free — a bare icon with an `onClick` would be invisible to AT and keyboard users.
**Approved**: pending

**Decision**: Reuse `Badge` for the chip body instead of restyling.
**Rationale**: The chip body is the shared `Badge`, so it inherits every tone and the established pill styling; the recipe adds only `flex items-center gap-1` and the trailing button, keeping one source of truth for chip appearance.
**Approved**: pending

**Decision**: Make the component stateless.
**Rationale**: The chip signals `onRemove` and nothing else; the consumer owns the list. This keeps the element reusable across any input that lets users remove items from a list, without baking in a list model.
**Approved**: pending

**Decision**: Centralize the badge-plus-✕ treatment in one component.
**Rationale**: Every caller that needs removable items shares identical removal semantics and accessibility rather than each re-deriving them.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

The source names the remove button with `aria-label={removeLabel}` and renders it as a
native `<button>`, so screen-reader-support and keyboard-navigable pass; both `children`
and `removeLabel` are caller-supplied props rather than literals, so no-hardcoded-strings
passes. `contrast-ratio` and `dynamic-type-support` are `partial` because the source
sets only design-token classes (e.g. `text-apt-text-muted`, the badge tone tokens) —
whether those tokens resolve to WCAG AA contrast or scale with system font size is
determined outside this file. `RemovableChip` is a `Badge` composed with a remove button, entirely presentation over props with no business logic (separation-of-concerns passed); no test file exercises it (unit-test-coverage failed).

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.3.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: reword disabled-blocks-remove around the native disabled button and move the CSS detail to Platform Notes; add keyboard-operable requirement and a focus-after-removal edge case; correct the SwiftUI, Compose, and AppKit/UIKit platform APIs and drop invented pressed/cursor states; reorder and relabel Platform Notes; move Badge to depends-on and drop named consumers from Overview and Design Decisions; reformat Design Decisions as Decision/Rationale/Approved; rewrite Compliance with canonical catalog checks; fix the empty-removeLabel edge case and the Localization contradiction; sharpen T5 and T8 test vectors; note badge-body appearance under Disabled. |
| 1.2.0 | 2026-09-22 | Claude Haiku 4.5 | Revise Platform Notes: replace "Not applicable" bullets with concrete translation guidance for SwiftUI, Kotlin, AppKit/UIKit, and WinUI 3. |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Add Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, and Privacy sections as "Not applicable"; fix domain to agenticdevelopercookbook; update status to review. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the Badge-plus-✕ removable chip and its named remove button. |
