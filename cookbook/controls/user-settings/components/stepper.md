---
id: 0eaf03a3-c00b-4f3a-81d7-5bd0560a5274
title: "Stepper"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Number input control with increment and decrement buttons for adjusting numeric values within min/max bounds."
platforms:
  - typescript
  - web
tags:
  - form-input
  - numeric-control
depends-on: []
related: []
references:
  - packages/web/packages/controls/src/user-settings/components/Stepper.tsx
approved-by: ""
approved-date: ""
---

# Stepper

## Overview

A stepper is a numeric input component that allows users to adjust a number by incrementing or decrementing with dedicated buttons, or by directly entering a value. It enforces minimum and maximum bounds and prevents operations that would violate those bounds.

## Behavioral Requirements

- **accept-numeric-value**: Component MUST accept an initial numeric value via the `value` prop.
- **call-onchange-handler**: Component MUST invoke the provided `onChange` handler with the new numeric value when the user increments, decrements, or directly edits the input.
- **clamp-to-bounds**: Component MUST clamp all values to the specified `min` and `max` bounds; values outside the range MUST be automatically adjusted to the nearest boundary.
- **respect-step-size**: Component MUST increment and decrement by the specified `step` amount (default 1).
- **keyboard-arrow-step**: While the input has focus, ArrowUp and ArrowDown MUST adjust the value by `step`, via the native `<input type="number">` spin behavior; the component adds no custom key handling beyond what the browser provides for numeric inputs.
- **disable-decrement-at-min**: Decrement button MUST be disabled when the current value is less than or equal to `min`.
- **disable-increment-at-max**: Increment button MUST be disabled when the current value is greater than or equal to `max`.
- **disable-all-controls-when-disabled**: When the `disabled` prop is `true`, all interactive elements (buttons and input) MUST be disabled and MUST NOT respond to user interaction.
- **support-direct-input**: Component MUST accept direct numeric input via an input field; non-numeric entries MUST be rejected or ignored.
- **support-optional-label**: Component MUST render an optional label element associated with the input field via `htmlFor` attribute when `label` prop is provided.
- **support-optional-hint**: Component MUST render an optional hint or help text below the control when `hint` prop is provided.
- **custom-classname**: Component MAY accept a custom CSS class name via the `className` prop for styling overrides.
- **custom-id**: Component MAY accept a custom element ID via the `id` prop; if not provided, a unique ID MUST be generated automatically.

## Appearance

- **Corner radius**: 4px (control-specific border radius; varies by platform design system)
- **Padding**: Buttons and input inherit field padding from the `{{app_prefix}}` field styling (reference implementation: 8px vertical × 12px horizontal)
- **Font**: 14px regular weight for input value (reference implementation; scale with the app's type tokens)
- **Background**: Input background uses the theme's surface/background color token; button backgrounds inherit from `{{app_prefix}}` field styling
- **Foreground/Text**: Theme text color token (reference implementation: dark text on light backgrounds)
- **Border**: 1px solid, theme border color token; focus state applies the theme's focus outline
- **Shadow**: None (flat design)
- **Min/Max size**: Minimum width determined by button size and input width; no maximum enforced

## States

| State | Appearance change |
|-------|------------------|
| Default | Input visible with both buttons enabled; neutral colors |
| Value at min | Decrement button appears disabled (opacity/color change); increment button enabled |
| Value at max | Increment button appears disabled (opacity/color change); decrement button enabled |
| Disabled | All controls (input, both buttons) appear disabled; text color dimmed; interaction disabled |
| Focused (input) | Blue outline or focus ring applied to input field per platform standards |
| Focused (button) | Blue outline or focus ring applied to focused button |

## Accessibility

- **Role**: The input MUST have `role="spinbutton"` or be a native `<input type="number">` element (preferred). Buttons MUST be implemented as native `<button type="button">` elements; `role="button"` MUST NOT be reasserted via ARIA since it is already implicit on `<button>`.
- **Label**: When a label is provided, the input MUST be associated via `<label htmlFor>` attribute. If no label is provided but hint or context exists, the input SHOULD have an `aria-label` or `aria-labelledby`.
- **Button labels**: Decrement and increment buttons MUST have clear, descriptive `aria-label` attributes, sourced from the localized strings ("Decrement", "Increment"; see Localization). These labels are generic and do not incorporate the field's `label` (see Edge Cases).
- **Announce disabled state**: When a button is disabled, its `disabled` attribute MUST be set; screen readers announce this state automatically.
- **Minimum tap target**: Buttons MUST be at least 44×44pt on iOS and 48×48dp on Android; web buttons SHOULD be at least 44×44px.
- **Keyboard navigation**: Input MUST accept focus and allow direct number entry via keyboard. While focused, ArrowUp/ArrowDown MUST adjust the value by `step` (see **keyboard-arrow-step**); PageUp/PageDown and Home/End are not handled, since native `<input type="number">` elements do not provide that behavior and the component adds no custom key handling. Buttons MUST accept focus and respond to Enter or Space key presses (native `<button>` behavior).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| stepper-001 | accept-numeric-value | value=5 | Input displays "5" |
| stepper-002 | call-onchange-handler | User clicks increment button, value=5, step=1 | onChange called with 6 |
| stepper-003 | call-onchange-handler | User clicks decrement button, value=5, step=1 | onChange called with 4 |
| stepper-004 | clamp-to-bounds | User types "15" in input, min=0, max=10 | onChange called with 10 (value clamped to max) |
| stepper-005 | clamp-to-bounds | User types "-5" in input, min=0, max=10 | onChange called with 0 (value clamped to min) |
| stepper-006 | respect-step-size | User increments, value=0, step=5, max=20 | onChange called with 5 |
| stepper-007 | respect-step-size | User decrements, value=10, step=3, min=0 | onChange called with 7 |
| stepper-008 | disable-decrement-at-min | value=0, min=0 | Decrement button disabled |
| stepper-009 | disable-increment-at-max | value=10, max=10 | Increment button disabled |
| stepper-010 | disable-all-controls-when-disabled | disabled=true | Input, decrement button, increment button all disabled |
| stepper-011 | support-direct-input | User types "42" in input, min=0, max=100 | onChange called with 42 |
| stepper-012 | support-direct-input | User types "abc" in input | Input ignores non-numeric input; value unchanged |
| stepper-013 | support-optional-label | label="Quantity" | Label element rendered and associated with input |
| stepper-014 | support-optional-hint | hint="Enter a value between 1 and 10" | Hint text displayed below stepper |
| stepper-015 | custom-classname | className="my-stepper" | Custom class applied to wrapper element |
| stepper-016 | custom-id | id="order-qty" | Input element has id="order-qty"; label htmlFor="order-qty" |
| stepper-017 | clamp-to-bounds | User types "25" in input, max=20 | Value clamped to 20; onChange called with 20 |
| stepper-018 | keyboard-arrow-step | User presses ArrowUp with input focused, value=5, step=1 | onChange called with 6 (native `<input type="number">` spin behavior) |
| stepper-019 | respect-step-size | User clicks increment, value=0.2, step=0.1 | onChange called with 0.30000000000000004 (no rounding is performed; result reflects raw floating-point addition) |
| stepper-020 | support-direct-input | User clears the input (types ""), value=7, min=5 | onChange called with 5 (empty string parses to 0, then clamped to min) |
| stepper-021 | clamp-to-bounds | User types "5" (first keystroke while entering "50"), min=10 | onChange called with 10 immediately after the first keystroke, before the second digit is typed |

## Edge Cases

- **Null or undefined min/max**: When `min` or `max` is not provided, the component treats them as -Infinity and +Infinity respectively. Clamping with infinite bounds works correctly.
- **Step smaller than 1**: The component supports fractional steps (e.g., step=0.5). Values MUST be clamped correctly; direct input MUST accept decimals matching the step size. The component performs no rounding to the step's precision, so repeated fractional increments can accumulate ordinary IEEE-754 floating-point drift (for example, incrementing from `0.2` by `step=0.1` yields `0.30000000000000004`, not `0.3`; see stepper-019).
- **Step larger than range**: If step size is larger than (max - min), incrementing from min jumps to or beyond max, triggering the max-bounds behavior. This is correct per clamping logic.
- **Direct input of boundary values**: User enters exactly min or max value. Component MUST accept it and MUST NOT reject valid boundary entries.
- **Direct input while at boundary**: User is at max value, types a new number below max, and increments. The new value MUST respect the typed entry and the subsequent increment — each call to the increment/decrement/direct-input handler clamps independently, so the most recently applied value takes precedence over any prior one (see **clamp-to-bounds**).
- **Disabled state with valid/invalid values**: When disabled=true, the component MUST NOT respond to button clicks or input changes regardless of the current value or bounds.
- **Empty or whitespace input**: `Number('')` evaluates to `0` (not `NaN`), so clearing the field is treated as entering `0` and is clamped like any other value (to `min` when `min > 0`); it is not preserved as blank or left unchanged (see stepper-020).
- **Clamping happens per keystroke, not on commit**: Clamping is applied immediately after every change, including each keystroke during direct text entry — not only on blur or Enter. Typing toward a multi-digit value that starts outside the current range (for example typing "5" then "0" to reach "50" when `min=10`) clamps the intermediate "5" up to `10` before the second digit is entered (see stepper-021).
- **Invalid configuration (`min > max`, `step <= 0`, non-finite `value`)**: The component performs no validation on these inputs. When `min > max`, clamping always resolves to `min` regardless of the requested value (`Math.max(min, Math.min(max, n))` collapses to `min` whenever `max < min`). When `step <= 0`, incrementing/decrementing with `step=0` calls `onChange` with the value unchanged, and a negative `step` inverts the buttons' effect (increment decreases the value, decrement increases it). When `value` is `NaN`, the `<= min` / `>= max` comparisons are always false, so neither button is disabled regardless of bounds. No warning is raised in any of these cases.
- **Multiple steppers per page**: Button accessible names are the generic localized strings ("Decrement" / "Increment") and do not include the field's `label`; a screen with more than one stepper has no built-in way to distinguish them by button label alone.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | number | required | Current numeric value |
| `onChange` | (value: number) => void | required | Callback invoked when value changes |
| `min` | number | -Infinity | Minimum allowed value |
| `max` | number | +Infinity | Maximum allowed value |
| `step` | number | 1 | Increment/decrement step size |
| `disabled` | boolean | false | Disables all controls |
| `label` | ReactNode | undefined | Optional label text or element |
| `hint` | ReactNode | undefined | Optional hint or help text |
| `className` | string | undefined | Optional custom CSS class |
| `id` | string | auto-generated | Optional custom element ID |

## Deep Linking

Not applicable: Stepper is a form control component with no standalone URL routing behavior.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `stepper.decrement` | "Decrement" | aria-label for decrement button |
| `stepper.increment` | "Increment" | aria-label for increment button |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | No motion or transitions applied in the component; button and input state changes occur instantly |
| Increase Contrast | Border color and text color SHOULD increase to meet AAA contrast requirements (7:1 minimum); disabled state text SHOULD remain distinguishable |
| Differentiate Without Color | Disabled buttons MUST indicate disabled state via the native `disabled` attribute (browsers render it with reduced opacity and a non-interactive cursor) rather than color alone; the −/+ glyph itself remains visible in both states. Screen readers announce the disabled state independently through the `disabled` attribute (see **screen-reader-support**) — `aria-label` is not a visible cue and MUST NOT be relied on to satisfy this option. |

## Feature Flags

Not applicable: Stepper is a core form component with no feature flag requirements.

## Analytics

Not applicable: The source emits no analytics events. Instrumentation is the consumer's responsibility, layered on top of **call-onchange-handler** (see Design Decisions).

## Privacy

- **Data collected**: The current numeric value only (no sensitive metadata).
- **Storage**: Value is maintained in component state during the session; not persisted by the component itself.
- **Transmission**: No data is transmitted by the component; the consumer (`onChange` handler) determines what is done with the value.
- **Retention**: Value is ephemeral within the component lifecycle; retention depends on the consuming application.

## Logging

Not applicable: The source contains no logging calls. Any logging of value changes is the consumer's responsibility, layered on top of **call-onchange-handler**.

## Platform Notes

- **SwiftUI**: Use `Stepper(value:in:step:)` or a custom composition with `Button` + `TextField` + `HStack` layout. Bind `value` to a `@State` property; the framework handles clamping. Stepper in SwiftUI does not display the numeric value directly—pair it with a Text view or TextField if the value must be visible. For a visible value and manual increment/decrement, compose with `VStack` containing a TextField for direct input and HStack buttons for increment/decrement.

- **Compose**: Implement using `Row` with `IconButton` (decrement/increment) flanking a `TextField`. Use `value` state and `onValueChange` callback. Apply bounds checking with `coerceIn(min, max)`. Set button enabled state conditionally based on current value vs. min/max. Use `BasicTextField` or `OutlinedTextField` for the value display.

- **React/Web**: The reference implementation (`packages/web/packages/controls/src/user-settings/components/Stepper.tsx`) uses a native `<input type="number">` with `<button type="button">` elements flanking it in a flex container. Its own CSS classes are named `aws-field` / `aws-stepper`; a consuming app SHOULD follow the `{{app_prefix}}-field` / `{{app_prefix}}-stepper` naming pattern instead. A `noAutofillProps` helper prevents browser autofill on the input field. Treat the reference implementation as the behavioral contract for this recipe.

- **AppKit / UIKit**: Use `NSStepper` on macOS or `UIStepper` on iOS. Both provide increment/decrement buttons and value management. `UIStepper` does not display the numeric value by default—pair it with a UITextField or UILabel to show the current value. Configure `minimumValue`, `maximumValue`, and `stepValue` properties. Bind target-action or delegation to capture value changes.

- **WinUI 3**: Implement using `NumberBox` control with `Value`, `Minimum`, `Maximum`, and `SmallChange` (step) properties. NumberBox renders spin buttons (increment/decrement) inline with a text input by default. Set `IsEnabled` to manage the disabled state. Handle `ValueChanged` event to invoke the onChange callback. SpinButtonPlacementMode can be set to `Compact` or `Inline` to control button placement.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/Stepper.tsx` | unverified |

## Design Decisions

- **Decision**: All numeric values are clamped to `[min, max]` bounds immediately after any change (button click or each keystroke of direct input).
  **Rationale**: This prevents out-of-range values from being passed to the consumer and avoids state inconsistency.
  **Approved**: pending

- **Decision**: When `min` or `max` is not provided, they default to `-Infinity` and `+Infinity` respectively.
  **Rationale**: This allows unconstrained ranges while simplifying the API (no separate "unbounded" mode).
  **Approved**: pending

- **Decision**: Buttons are disabled when an operation would exceed bounds (`value <= min` disables decrement; `value >= max` disables increment).
  **Rationale**: This prevents repeated clicks from attempting invalid operations and provides clear affordance to users.
  **Approved**: pending

- **Decision**: Non-numeric input is silently ignored via a `Number.isNaN()` check; an empty or whitespace input parses to `0` and is committed like any other value (see Edge Cases).
  **Rationale**: This provides lenient error handling without introducing error states, though it means blank input is treated as zero rather than as "no value."
  **Approved**: pending

- **Decision**: Buttons use `aria-label` for concise, standalone labels ("Decrement", "Increment") rather than `aria-describedby`.
  **Rationale**: The action is self-contained and descriptive, so a short accessible name is sufficient.
  **Approved**: pending

- **Decision**: The stepper emits only `onChange`; it performs no analytics tracking and no logging.
  **Rationale**: A leaf form primitive should not own telemetry — mixing instrumentation into input handling couples unrelated concerns. Consumers that need analytics or logging compose it around **call-onchange-handler**.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The source uses a native `<button type="button">` and `<input type="number">` with correct `aria-label`/`disabled` attributes, so screen-reader-support, keyboard-navigable, and semantic-markup pass; it hardcodes the "Decrement"/"Increment" strings directly in JSX rather than resolving them through the localization keys in this recipe's Localization section, so string-externalization and no-hardcoded-strings fail; and it defines colors, font size, and control dimensions only through CSS classes not shown in the source file, so contrast, type scaling, and tap-target size cannot be confirmed and are marked partial; the only logic is the trivial pure `clamp` helper, kept apart from the render function (separation-of-concerns passed), and `components.test.tsx` exercises increment/decrement and the disabled-at-min bound directly (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case everywhere they're cited; removed unverified Analytics/Logging content (marked Not applicable) and documented that instrumentation is the consumer's responsibility; replaced AWS-specific class names and hex colors with `{{app_prefix}}`/theme-token guidance; reformatted Design Decisions to the Decision/Rationale/Approved form; rebuilt Compliance as a table of cookbook compliance-catalog checks with accurate passed/partial/failed statuses; corrected the button role and Differentiate Without Color claims; cited the reference implementation by path in place of an unidentified source reference; clarified the out-of-range test vectors as typed input rather than an onChange input; and documented native ArrowUp/Down stepping, fractional-step floating-point drift, empty-input-as-zero, per-keystroke clamping, and invalid-configuration (`min > max`, `step <= 0`, NaN) behavior as built. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from React/Web source |
