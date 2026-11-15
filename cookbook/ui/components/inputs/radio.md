---
id: 3b509297-83b2-4a5b-a331-56d0d4be548d
title: "Radio"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Single-selection control in a group where users pick one option from multiple mutually exclusive choices."
platforms:
  - typescript
  - web
tags:
  - form
  - selection
  - radio-button
depends-on: []
related:
  - d431934e-d64c-4dcf-bdab-b7c3465ee71b
  - a105b6cf-307d-4156-8b73-468f627f3c9b
  - 0c199036-81c3-47c3-9e79-e4b8187ca69a
references: []
approved-by: ""
approved-date: ""
---

# Radio

## Overview

A radio button is a single-selection control used within a radio group to allow users to select exactly one option from a set of mutually exclusive choices. This ingredient covers `RadioGroupItem`, the individual control; the `RadioGroup` container's layout, spacing, and cross-item keyboard navigation are documented in [adhsdk.ingredient.controls.user-settings.components.radio-group](cookbook:d431934e-d64c-4dcf-bdab-b7c3465ee71b). Built on Base UI radio primitives (`@base-ui/react/radio-group`, `@base-ui/react/radio`) with theme tokens for styling.

## Behavioral Requirements

- **indicate-selection**: RadioGroupItem MUST display a visual indicator (filled dot) when selected.
- **hide-indicator-when-unselected**: The inner indicator MUST NOT be visible when the radio button is unselected.
- **single-selection**: Within a RadioGroup, selecting one RadioGroupItem MUST deselect any previously selected item, so at most one item in the group is selected at a time.
- **disabled-state**: RadioGroupItem MUST be disableable; a disabled item MUST ignore pointer clicks and keyboard input (Space/Enter). Because `RadioPrimitive.Root` renders as a native `<button type="button">`, the disabled state is exposed through the native `disabled` attribute together with `aria-disabled` and `data-disabled`, so the wrapper's `disabled:` opacity/cursor utilities match and the control is visually dimmed.
- **focus-visible**: RadioGroupItem MUST display a focus-visible border and ring styling when focused via keyboard navigation.
- **space-selects**: RadioGroupItem MUST become selected when it has keyboard focus and the user presses Space.
- **theme-token-styling**: RadioGroupItem MUST use the toolkit's border, background, and accent theme tokens to visually distinguish its default, checked, and focused states.
- **color-transitions**: RadioGroupItem MUST transition color changes smoothly rather than switching state colors abruptly.

## Appearance

- **Size**: 16×16px (size-4 in Tailwind)
- **Corner radius**: Fully rounded (50% / `rounded-full`)
- **Padding**: None (control is sizing-based)
- **Font**: N/A (no text in the control itself; label text is external)
- **Background**: `apt-bg` (theme token for default state background)
- **Border**: 1px solid `apt-border` (default state); 1px solid `apt-gold` when checked or focused
- **Ring**: 2px, `apt-gold` at 25% opacity, shown on focus-visible only
- **Indicator**: 8×8px inner circle, `apt-gold` when checked; hidden when unchecked
- **Shadow**: None
- **Min/Max size**: Fixed at 16×16px; shrink-0 prevents size changes due to flex containers
- **Transition**: All color changes transition smoothly via CSS transitions

## States

| State | Appearance change |
|-------|------------------|
| Default | 16×16px circle, `apt-border` border, `apt-bg` background, no indicator |
| Checked | Border changes to `apt-gold`, inner `apt-gold` dot appears (8×8px) |
| Focused | Border and ring added with `apt-gold`, ring opacity set to 25% |
| Disabled | Dimmed (`disabled:opacity-50`, `disabled:cursor-not-allowed`, `disabled:pointer-events-none` match the native `disabled` attribute on the `<button>` root); also carries `aria-disabled="true"` and `data-disabled`; toggling is also blocked by Base UI's internal guards |
| Checked + Disabled | Checked appearance (border/dot) combined with the Disabled row's dimmed, `disabled`/`aria-disabled`/`data-disabled` state |

## Accessibility

- **Role/trait**: Radio button (ARIA `role="radio"` on a native `<button type="button">` rendered by Base UI RadioPrimitive.Root, with Base UI's hidden input for form submission)
- **Label requirements**: Labels are external to the RadioGroupItem; the form must associate labels via standard form patterns (e.g., `<label htmlFor="radio-id">` or wrapping)
- **Announce state changes**: Checked/unchecked state is announced by assistive technology via the ARIA radio role
- **Minimum tap target**: The 16×16px control alone is below the WCAG 2.5.8 (AA) minimum target size of 24×24 CSS pixels. Label association with a `role="radio"` button is not native, so consumers MUST ensure the label (or an equivalent wrapping hit area) extends the clickable region to at least 24×24px.
- **Keyboard navigation**: RadioGroupItem supports Space to select while focused (see **space-selects**) and shows a visible focus indicator (see **focus-visible**). Arrow-key navigation between items and the group's single Tab stop are managed by the RadioGroup container — see [adhsdk.ingredient.controls.user-settings.components.radio-group](cookbook:d431934e-d64c-4dcf-bdab-b7c3465ee71b).
- **Focus indicator**: Visible focus ring (gold border and ring) provides keyboard focus indication

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| radio-001 | indicate-selection | RadioGroupItem with checked state | Filled `apt-gold` dot visible inside the 16×16px circle |
| radio-002 | hide-indicator-when-unselected | RadioGroupItem with unchecked state | No indicator dot visible |
| radio-003 | single-selection | Two RadioGroupItems in a group; item A is checked, then item B is selected | Item A's indicator disappears as item B's appears; only one item is checked |
| radio-004 | disabled-state | Disabled RadioGroupItem receives a pointer click | Checked state does not change; no selection callback fires |
| radio-005 | disabled-state | Disabled RadioGroupItem holds focus and receives Space or Enter | Checked state does not change; no selection callback fires |
| radio-006 | focus-visible | RadioGroupItem with keyboard focus | `apt-gold` border and 2px ring at 25% opacity visible |
| radio-007 | space-selects | Unchecked RadioGroupItem holds keyboard focus and receives Space | Item becomes checked |
| radio-008 | theme-token-styling | RadioGroupItem in default state | Border color is `apt-border`, background is `apt-bg` |
| radio-009 | color-transitions | RadioGroupItem state change from unchecked to checked | Computed `transition-property` includes `color`/`border-color`/`background-color` and `transition-duration` is greater than 0 |
| radio-010 | no-initial-selection | RadioGroup rendered with neither `value` nor `defaultValue` set | No RadioGroupItem in the group renders its selected indicator |
| radio-011 | value-matches-no-item | RadioGroup's `value` does not match any item's `value` | No RadioGroupItem displays as checked |
| radio-012 | all-items-disabled | Every RadioGroupItem in the group has `disabled` set | No item can be selected via pointer or keyboard; each carries the native `disabled` attribute, `aria-disabled="true"` and `data-disabled`, and renders dimmed through the `disabled:` utilities |
| radio-013 | disabled-item-already-checked | A RadioGroupItem is both checked and disabled | Item shows the selected indicator combined with the disabled item's native `disabled`, `aria-disabled` and `data-disabled` state, dimmed through the `disabled:` utilities |
| radio-014 | boundary-values | RadioGroupItem rendered inside a shrinking flex container | Item stays fixed at 16×16px (`shrink-0` prevents resizing) |

## Edge Cases

- **No initial selection**: When neither `value` nor `defaultValue` is set on the group, no RadioGroupItem in the set renders its selected indicator.
- **Value matches no item**: When the group's `value` does not match any item's `value`, no RadioGroupItem displays as checked; this is a valid state, e.g., before a default is chosen.
- **All items disabled**: When every RadioGroupItem in the group has `disabled` set, none can be selected via pointer or keyboard; each root is a native `<button>` carrying `disabled`, `aria-disabled="true"` and `data-disabled`, so every item renders dimmed.
- **Disabled item already checked**: A RadioGroupItem can be both checked and disabled simultaneously; it shows the selected indicator combined with the disabled item's non-interactive, dimmed state (see States: Checked + Disabled).
- **Boundary values**: Size is fixed at 16×16px via `shrink-0`; no resizing or scaling occurs even inside a shrinking flex container.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` (RadioGroup) | string | — | The controlled selected value for the group; the RadioGroupItem whose own `value` matches renders as checked |
| `defaultValue` (RadioGroup) | string | `undefined` | Initial selected value for an uncontrolled group |
| `onValueChange` (RadioGroup) | `(value: string) => void` | `undefined` | Callback invoked with the new value when the user selects a different item |
| `name` (RadioGroup) | string | auto-generated | Shared form field name applied to all items in the group |
| `disabled` (RadioGroup) | boolean | `false` | Disables every RadioGroupItem in the group |
| `value` (RadioGroupItem) | string | required | The value this item represents; compared against the group's `value` to determine checked state |
| `disabled` (RadioGroupItem) | boolean | `false` | Disables this individual item; disabling is additive, so an item is disabled if either the item or its group is disabled |
| `className` (RadioGroup) | string | `undefined` | Additional CSS classes applied to the RadioGroup container |
| `className` (RadioGroupItem) | string | `undefined` | Additional CSS classes applied to the RadioGroupItem |

## Deep Linking

Not applicable: Radio buttons are form controls within a page context, not independent navigable endpoints.

## Localization

Not applicable: The radio button control itself contains no user-facing text. Labels and option text are provided by the consuming form and are externally localized.

## Accessibility Options

- **Reduce Motion**: The `transition-colors` class applies a brief color-only fade (no transform or motion), so it is treated as exempt from Reduce Motion policies; the component does not itself read `prefers-reduced-motion`. Consumers whose design system wants zero transition can override with `transition-none` in their stylesheet.
- **Increase Contrast**: The `apt-gold` and `apt-border` tokens are theme-specific; high-contrast themes should override token values to ensure sufficient contrast (WCAG AA non-text contrast, SC 1.4.11: 3:1 for UI components).
- **Differentiate Without Color**: Not applicable; the component uses both color (gold vs. border) and shape (dot appears/disappears) to indicate state, providing non-color differentiation.

## Feature Flags

Not applicable: The component is a stable UI primitive with no experimental or feature-flagged behavior in the source.

## Analytics

Not applicable: The component itself emits no analytics events. Event tracking is the responsibility of the form or page consuming the radio group.

## Privacy

- **Data collected**: None; the component does not collect or log user data.
- **Storage**: None; state is ephemeral and managed in memory by React.
- **Transmission**: None; the component does not transmit data.
- **Retention**: Not applicable; no data is retained.

## Logging

Not applicable: The component does not implement logging. Debug logging is the responsibility of the consuming application.

## Platform Notes

- **React/Web**: Source uses Base UI `RadioGroup` and `Radio` primitives via `@base-ui/react/radio-group`. RadioGroupItem wraps `RadioPrimitive.Root`, rendered as a native `<button type="button">` (`nativeButton`), styled with the `apt-border`/`apt-bg`/`apt-gold` Tailwind theme tokens; `transition-colors` provides the smooth color transition and `focus-visible:ring-2 focus-visible:ring-apt-gold/25` renders the focus ring. The Indicator (hidden when unchecked via `data-[unchecked]:hidden`) shows as an 8×8px gold dot when checked. Reference: `packages/web/packages/ui/src/components/radio.tsx`.
- **SwiftUI**: On macOS, use `Picker` with `.pickerStyle(.radioGroup)`, which renders true radio buttons with built-in mutual exclusivity and keyboard navigation. iOS has no native SwiftUI radio-group style; use a `List` whose selected row shows a trailing checkmark (`Image(systemName: "checkmark")`) instead. Color tokens and the focus ring translate to SwiftUI's `.tint`/appearance modifiers and focus state.
- **Compose**: Android Material Design 3 provides the `RadioButton` composable. Color tokens (`apt-gold`, `apt-border`) map to `RadioButtonDefaults.colors(selectedColor, unselectedColor)`, which is the Material 3 API for radio button color states.
- **AppKit / UIKit**: macOS uses `NSButton(radioButtonWithTitle:)` with shared target/action for mutual exclusivity, or custom views. UIKit has no native radio control; use a `UITableView`/list row with a checkmark accessory (`.checkmark` accessory type) for the selected row rather than `UISegmentedControl`, which represents a different interaction pattern. Focus and disabled states follow platform HIG conventions.
- **WinUI 3**: Windows uses the `RadioButtons` group control (not loose `RadioButton` elements with `GroupName`), which provides built-in arrow-key navigation and a single tab stop for the whole group. Control templates override default appearance to match design tokens; focus states are managed via `VisualStateManager` with custom border and shadow brushes bound to color tokens.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/radio.tsx` | confirmed (1.1.2) |

## Design Decisions

- **Size**
  **Decision**: RadioGroupItem renders at 16×16px (Tailwind `size-4`).
  **Rationale**: Matches the toolkit's compact control sizing; this is below the WCAG 2.5.8 (AA) minimum target size of 24×24 CSS pixels, so consumers MUST ensure the associated `<label>` (or an equivalent wrapping hit area) extends the clickable region to at least 24×24px — a click on a label associated through Base UI's wiring is how a pointer user reaches the control.
  **Approved**: pending

- **Color transitions**
  **Decision**: `transition-colors` is applied to all state changes (checked and focused; disabled has no color change).
  **Rationale**: Provides visual feedback without jarring state shifts, following modern UI conventions. The transition is a brief color fade only, with no transform or motion, so it is treated as exempt from Reduce Motion policies rather than something the component must gate on `prefers-reduced-motion`; a consuming design system that wants zero transition can override with `transition-none`.
  **Approved**: pending

- **Focus ring**
  **Decision**: The focus-visible state uses a 2px ring (`ring-2`) at 25% opacity of `apt-gold`, in addition to the 1px `apt-gold` border.
  **Rationale**: Provides sufficient visibility without overwhelming the control, balancing accessibility with design aesthetic.
  **Approved**: pending

- **Disabled state**
  **Decision**: `RadioGroupItem` carries `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50`. Because the root is now a native `<button type="button">`, a disabled item carries the native `disabled` attribute (alongside `aria-disabled="true"` and `data-disabled`), so these utilities match and the item is visibly dimmed; selection is also blocked by Base UI's internal pointer/keyboard guards.
  **Rationale**: This is the wrapper's styling, shared with the other form controls; the native-button root (see Native button root) is what makes it take effect.
  **Approved**: pending

- **Native button root**
  **Decision**: `RadioPrimitive.Root` renders a native `<button type="button">` (`nativeButton`, `render={<button type="button" />}`) instead of Base UI's default `<span role="radio">`.
  **Rationale**: Base UI 1.5's span radio swallows Space inside a group: its composite Space handler prevents the keydown before RadioRoot's `onClick`, which bails on `defaultPrevented`, so Space never selected. A native button takes the `click()` path, so Space selects (radio-007), and it also lets the `disabled:` utilities match.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

These statuses rest on the source's use of Base UI's semantic radio primitives and native label-click/Space-select behavior (screen-reader-support, semantic-markup, keyboard-navigable), its theme tokens having no literal color values and its fixed 16×16px size being below the 24×24px minimum (contrast-ratio and touch-target-size as partial), and its color-only, non-transform `transition-colors` (reduced-motion). `separation-of-concerns` passes because `radio.tsx` only themes and composes Base UI's `Radio`/`RadioGroup` primitives, with no selection or focus logic of its own. `unit-test-coverage` is partial: `radio.test.tsx` covers every vector except radio-009 (computed transition styles need the compiled stylesheet, absent in jsdom), so the check stays partial; radio-007 (Space selects) now passes because the root is a native button.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from Base UI radio primitives |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: scoped this file to RadioGroupItem only, moving group spacing/layout out and linking radio-group/checkbox/field via `related`; corrected WCAG citations (SC 2.5.8 24×24px target, SC 1.4.11 3:1 contrast); made theme-token and color-transition requirements platform-neutral with Tailwind specifics moved to the React/Web platform note; added `single-selection` and `space-selects` requirements with test vectors and rewrote the disabled-state vectors to test ignored interaction instead of class names; replaced the SwiftUI/UIKit/Compose/WinUI platform notes with real, correct APIs; corrected the Compliance check IDs and expanded coverage; reformatted Design Decisions into Decision/Rationale/Approved form; replaced the Configuration table with Base UI's real API; replaced filler edge cases with real ones and added their test vectors; resolved the Reduce Motion contradiction between Accessibility Options and Design Decisions. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Disabled state: no dimming, aria/data-disabled+tabindex=-1; added best-practices rows. |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Said ingredient not recipe, made disabled additive, corrected the ARIA role and label wording, named the edge-case vectors, made radio-009 measurable, split the className row and dropped the leading slash. |
