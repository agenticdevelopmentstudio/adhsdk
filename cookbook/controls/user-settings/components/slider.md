---
id: 25816370-14ff-454a-83d4-ebd588a2ff01
title: "Slider"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Labeled range input control that allows users to select a numeric value within a defined minimum and maximum."
platforms:
  - typescript
  - web
tags:
  - form-control
  - input
  - range
depends-on: []
related:
  - dc548100-af44-4d93-9cb9-93c35546e08c
  - a105b6cf-307d-4156-8b73-468f627f3c9b
  - fba584ed-a87c-4223-a4a9-de9c6dd342d3
  - d431934e-d64c-4dcf-bdab-b7c3465ee71b
  - 6f7c9bb6-b6fe-479a-9dbc-3ff174f7fed2
  - 0eaf03a3-c00b-4f3a-81d7-5bd0560a5274
references:
  - https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/range
  - https://www.w3.org/TR/WCAG21/
  - https://www.w3.org/TR/WCAG22/#target-size-minimum
approved-by: ""
approved-date: ""
---

# Slider

## Overview

A slider is a labeled range input control that allows users to select a numeric value by dragging a handle along a track. It supports a configurable minimum and maximum value, optional step increments, and can display a dynamic caption showing the current value. The component wraps the native HTML5 `<input type="range">` element with optional label, hint text, and caption.

## Behavioral Requirements

- **range-input**: Component MUST render an HTML5 `<input type="range">` element with the specified `value`, `min`, `max`, and `step` attributes.
- **accept-value**: Component MUST accept a controlled `value` prop (number) and reflect it in the input element.
- **change-callback**: Component MUST call the `onChange` callback with the new value converted to a number (`Number(event.target.value)`) when the user interacts with the range input.
- **optional-label**: Component MUST render an optional `<label>` element when the `label` prop is provided; the label MUST have an `htmlFor` attribute pointing to the input's ID.
- **optional-hint**: Component MUST render an optional hint text element when the `hint` prop is provided, positioned below the slider.
- **optional-caption**: Component MUST render an optional caption element when the `caption` prop is provided; if `caption` is a function, the component MUST call it with the current `value` and render the result.
- **disabled-state**: Component MUST disable the input element when the `disabled` prop is `true`.
- **default-min**: Component MUST use a default `min` value of `0` when the `min` prop is not provided.
- **default-max**: Component MUST use a default `max` value of `100` when the `max` prop is not provided.
- **default-step**: Component MUST use a default `step` value of `1` when the `step` prop is not provided.
- **generate-id**: Component MUST generate a unique ID for the input when the `id` prop is not provided, using React's `useId` hook.
- **label-association**: Component MUST use the same ID (either provided or generated) for both the input's `id` attribute and the label's `htmlFor` attribute to ensure proper semantic association.
- **apply-classes**: Component MUST apply the CSS classes `aws-field` and `aws-field--slider` to the wrapper element, and MUST append any `className` prop provided.

## Appearance

The component's visual presentation is controlled entirely by CSS. The component itself establishes the following class structure:

- **Wrapper**: `aws-field aws-field--slider` (plus optional custom `className`)
- **Label**: `aws-field__label` — applied to the `<label>` element when present
- **Slider container**: `aws-slider`
- **Input**: `aws-slider__input` — applied to the range input
- **Caption**: `aws-slider__caption` — applied to the caption span
- **Hint**: `aws-field__hint` — applied to the `<p>` element when present

DOM order: the `<label>` (if present) renders first, followed by the `.aws-slider` container (the range input and, if present, the caption `<span>` as siblings inside it), followed by the hint `<p>` (if present) as the last child of the wrapper.

The actual appearance (colors, spacing, dimensions, border radius, shadows) is defined by CSS rules for these classes and is outside the scope of this component's implementation.

## States

| State | Appearance change | Behavioral change |
|-------|------------------|------------------|
| Default | Component rendered normally | User can interact with the range input |
| Disabled | Input element has `disabled` attribute; CSS may apply visual disabled styling | Range input does not respond to user interaction |

## Accessibility

- **Role**: The component uses the semantic HTML5 `<input type="range">` element, which has an implicit role of `slider`.
- **Label association**: When a `label` prop is provided, the component renders a `<label>` element with `htmlFor` pointing to the input's ID (see **label-association**), creating a proper semantic association. No fallback ARIA property (`aria-label`, `aria-labelledby`) is implemented; when `label` is omitted, the control has no accessible name from the component itself.
- **Min/Max exposure**: The `min`, `max`, and `step` attributes are directly set on the input element, making them available to assistive technologies.
- **Value announcements**: Assistive technologies announce the current value and range from the input's native `value`, `min`, and `max` attributes. When `caption` is a function, its formatted output is rendered visually as a sibling `<span>` but is not exposed via `aria-valuetext`, so assistive technology announces only the raw numeric value, not the formatted caption text.
- **Hint association**: The hint paragraph renders as a sibling of the slider container but is not linked to the input via `aria-describedby`; assistive technology does not announce it as a description of the control.
- **Minimum tap/click target**: The range input's rendered size is set entirely by CSS (see Appearance); the source sets no explicit dimensions, so whether a given stylesheet meets a minimum target size cannot be determined here. WCAG 2.2 SC 2.5.8 (Target Size, Minimum, Level AA) requires at least 24×24 CSS pixels; WCAG 2.1 SC 2.5.5 (Target Size, Level AAA) recommends 44×44 CSS pixels as an enhanced target. CSS must enforce whichever level the product targets.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| slider-001 | range-input | value=50, min=0, max=100, step=1 | `<input type="range" value="50" min="0" max="100" step="1">` is rendered |
| slider-002 | accept-value | Controlled component with value=75 | Input element's `.value` DOM property equals `"75"` |
| slider-003 | change-callback | User drags input to value 60 | `onChange` callback is invoked with `60` |
| slider-003a | change-callback | User drags input to value 60 | `onChange` is invoked with an argument whose `typeof` is `'number'` (the raw `event.target.value` string is converted before the callback fires) |
| slider-004 | optional-label | label="Volume" | A `<label>` element is rendered with a `for` attribute (the DOM attribute; `htmlFor` is the React prop name) equal to the input's `id`, and text content "Volume" |
| slider-005 | optional-hint | hint="Adjust volume from 0–100" | Hint text is rendered as `<p class="aws-field__hint">...</p>`, the last child of the wrapper |
| slider-006 | optional-caption (static) | caption="Volume: 50" | Caption "Volume: 50" is rendered as `<span class="aws-slider__caption">...</span>` |
| slider-007 | optional-caption (dynamic) | caption={(val) => `Level: ${val}`}, value=75 | Caption "Level: 75" is rendered (function called with current value) |
| slider-008 | disabled-state | disabled=true | Input has `disabled` attribute; user cannot interact with it |
| slider-009 | default-min | min prop not provided | `min` attribute defaults to `0` |
| slider-010 | default-max | max prop not provided | `max` attribute defaults to `100` |
| slider-011 | default-step | step prop not provided | `step` attribute defaults to `1` |
| slider-012 | generate-id | id prop not provided | Component generates a unique ID using React's `useId`; label (if present) associates to this ID |
| slider-013 | label-association | id="custom-slider", label="Value" | The rendered `<label for="custom-slider">` and `<input id="custom-slider">` share the same ID value |
| slider-014 | apply-classes | className="my-custom-class" | Wrapper has classes `aws-field aws-field--slider my-custom-class` |
| slider-015 | change-callback (boundary) | User drags to min=0 | `onChange(0)` is called |
| slider-016 | change-callback (boundary) | User drags to max=100 | `onChange(100)` is called |
| slider-017 | change-callback (keyboard) | Input focused, user presses ArrowRight (or ArrowUp) | Value increases by one `step`; `onChange` is called with the new numeric value |
| slider-018 | change-callback (keyboard) | Input focused, user presses ArrowLeft (or ArrowDown) | Value decreases by one `step`; `onChange` is called with the new numeric value |
| slider-019 | change-callback (keyboard) | Input focused, user presses Home | Value jumps to `min`; `onChange` is called with `min` |
| slider-020 | change-callback (keyboard) | Input focused, user presses End | Value jumps to `max`; `onChange` is called with `max` |
| slider-021 | change-callback (keyboard) | Input focused, user presses Page Up / Page Down | Value jumps by a browser-defined larger increment; `onChange` is called with the new numeric value |
| slider-022 | disabled-state (keyboard) | disabled=true, input focused, user presses an arrow, Home, End, or Page key | Value does not change; `onChange` is not called |

## Edge Cases

- **Optional label, hint, and caption**: When `label`, `hint`, or `caption` is not provided, the component renders without that element; this is the intended behavior for optional content, not an accidental omission. A falsy-but-defined value, such as `label={0}`, is also treated as "not provided" and will not render — callers who need to display a literal `0` should pass it as a string (e.g., `label="0"`).
- **Caption as function with value change**: When `caption` is a function, it is re-evaluated on every value change; the component passes the current `value` to the function and renders the result. No memoization is applied; if expensive computation is needed, the caller should memoize the function.
- **Step value smaller than range**: If `step` is 1 and the range is 0–100, the user can select any integer in that range. The HTML5 input respects the `step` attribute; any interaction respects the step granularity.
- **`min` greater than `max`, or `value` outside `[min, max]` or off the step grid**: The component performs no validation of these conditions. The browser clamps the displayed value to the nearest valid value for the given `min`/`max`/`step` (see also "Min equal to max" below). Because `onChange` fires only in response to user interaction, passing a `value` the browser will clamp does not itself trigger a callback, so the displayed value can silently diverge from the `value` prop until the user next interacts with the control.
- **Min equal to max**: If `min` and `max` are equal (e.g., both `50`), the range is effectively disabled by browser behavior; the value cannot change. The component does not validate this condition.
- **Custom className concatenation**: A falsy `className` (such as a conditional `undefined`) is omitted from the wrapper's class list rather than rendered as literal text.
- **Disabled state with existing value**: When the `disabled` prop changes from `false` to `true`, the value is not cleared; the current value is retained but the input becomes non-interactive.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | `ReactNode` | `undefined` | Optional label text or element displayed above the input |
| `hint` | `ReactNode` | `undefined` | Optional hint text or element displayed below the slider |
| `value` | `number` | (required) | Current value of the slider; controlled by the parent component |
| `onChange` | `(value: number) => void` | (required) | Callback invoked when the user changes the slider value |
| `min` | `number` | `0` | Minimum value of the slider range |
| `max` | `number` | `100` | Maximum value of the slider range |
| `step` | `number` | `1` | Increment/decrement step when user adjusts the slider |
| `caption` | `ReactNode \| (value: number) => ReactNode` | `undefined` | Optional static content or function that returns dynamic content based on the current value |
| `disabled` | `boolean` | `false` | When `true`, disables the input and prevents user interaction |
| `className` | `string` | `undefined` | Optional additional CSS class name(s) to apply to the wrapper element |
| `id` | `string` | (auto-generated) | Optional ID for the input element; if not provided, a unique ID is generated using React's `useId` |

## Deep Linking

Not applicable: This component is a form control without built-in deep linking support. Deep linking would be implemented at the page or application level, not within the component.

## Localization

The component renders no built-in strings; `label`, `hint`, and `caption` are all provided by the parent as `ReactNode` (or, for `caption`, a function returning one), so string translation is the caller's responsibility. Layout direction is not implemented by the component: the native `<input type="range">` inherits its visual direction from the ambient `dir`/CSS `direction` the browser applies, so RTL mirroring happens automatically only if the surrounding page sets it — the component neither tests nor guarantees this itself. When a `caption` function formats the numeric value (e.g., as a percentage or with a unit), that formatting SHOULD use a locale-aware API (such as `Intl.NumberFormat`) rather than an invariant-culture call, since the formatted string is user-facing.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The component has no animation or transition to suppress; there is nothing for a reduced-motion preference to affect. |
| Increase Contrast | Contrast is controlled entirely by CSS; the component itself does not detect or adjust for `prefers-contrast`. |
| Differentiate Without Color | The component conveys state (value, disabled) through the native slider position and the `disabled` attribute rather than color alone; any additional color-based styling is the responsibility of CSS. |

## Feature Flags

Not applicable: The component does not include conditional logic or feature-gating; no feature flags are present in the source code.

## Analytics

Not applicable: The component does not emit analytics events. Event tracking would be implemented by the parent component using the `onChange` callback.

## Privacy

Not applicable: The component processes only the numeric value of the slider; it does not collect, store, or transmit any personal data or sensitive information.

## Logging

Not applicable: The component does not include any logging or debugging output.

## Platform Notes

- **React/Web**: Implemented in Slider.tsx using React hooks (`useId`). The component wraps the native HTML5 `<input type="range">` with optional label, hint, and caption elements. CSS classes (`aws-field`, `aws-slider`) control visual presentation. `Slider` is the canonical export; `CaptionedSlider` is an alias for the same component (`export const CaptionedSlider = Slider`) kept for backward compatibility — new code should import `Slider`.

- **SwiftUI**: SwiftUI's native `Slider` view is available on both iOS and macOS; start with it. The equivalent ingredient would wrap it with optional `Label`, hint text below, and a caption view that updates based on the slider's `value`. SwiftUI's slider does not natively support custom captions or external labels in the same way; these would be separate views in a `VStack`.

- **Compose**: On Android, start with `Slider` from Material Design 3 Compose. The Material 3 `Slider` composable has no built-in label parameter; render the label as a separate `Text` composable above the slider, and give the control an accessible name with `Modifier.semantics { contentDescription = "..." }`. A dynamic caption/value readout requires a custom `thumb` composable rather than a built-in slot. Adapt the hint as a separate `Text` composable below the slider. Handle the `onValueChange` callback and manage state at the parent level.

- **AppKit / UIKit**: On macOS, use `NSSlider` (AppKit); on iOS, use `UISlider` (UIKit). Both require manual layout of labels and captions as separate UI elements. AppKit's `NSSlider` has limited built-in label support; use an adjacent `NSTextField` for the label. UIKit requires programmatic constraints or SwiftUI wrapping. Neither provides native dynamic caption binding; update the caption view imperatively when the value changes.

- **WinUI 3**: On Windows, use the `Slider` control from the WinUI 3 library (`Microsoft.UI.Xaml.Controls` namespace). WinUI's `Slider` supports a `Header` property for labels but cannot host arbitrary child elements for a caption; render the caption as a sibling `TextBlock` bound to the same value, or format the built-in thumb tooltip with a `ThumbToolTipValueConverter`. Bind the `Value` property to your data model using two-way binding. Use a `TextBlock` below for hints. The slider's visual style respects system contrast and motion settings through `ThemeResource` tokens; no explicit Accessibility Options handling is required at the component level.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/Slider.tsx` | unverified |

## Design Decisions

1. **Decision**: Use the native browser HTML5 `<input type="range">` element rather than a custom-built slider.
**Rationale**: This provides built-in accessibility (semantic role and keyboard support) and cross-browser consistency, but limits visual customization to CSS.
**Approved**: pending

2. **Decision**: Implement the slider as a controlled component — its value is managed entirely by the parent via the `value` prop and `onChange` callback.
**Rationale**: Aligns with React's unidirectional data flow and lets the parent compose validation, formatting, or multi-step workflows.
**Approved**: pending

3. **Decision**: Make the label optional, associating it to the input via `htmlFor` only when provided.
**Rationale**: Supports both labeled and unlabeled use cases while keeping the association correct whenever a label is present; see the label association note under Accessibility for the accessible-name gap this leaves when `label` is omitted.
**Approved**: pending

4. **Decision**: Support the caption as either a static node or a function of the current value.
**Rationale**: Lets the caller display the current value or other state-dependent information without maintaining a separate derived state.
**Approved**: pending

5. **Decision**: Default `min` to `0`, `max` to `100`, and `step` to `1`.
**Rationale**: Provides a useful out-of-the-box integer range (0–100) that covers common cases and can be overridden when a different range is needed.
**Approved**: pending

6. **Decision**: Delegate all visual styling — color, spacing, dimensions, shadows — to CSS classes rather than hard-coding it in the component.
**Rationale**: Keeps styling consistent and centrally managed across the application.
**Approved**: pending

7. **Decision**: Export `Slider` as the canonical component name; keep `CaptionedSlider` as an alias of the same function (`export const CaptionedSlider = Slider`).
**Rationale**: Preserves backward compatibility for existing imports of `CaptionedSlider` while giving new code a single, unambiguous name to import.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The `passed` statuses rest on the native `<input type="range">` role and keyboard semantics, the `id`/`htmlFor` association visible in the source, and the fact that `label`/`hint`/`caption` content is entirely caller-supplied and rendered unmodified. The `partial` statuses reflect that the component has no fallback accessible name when `label` is omitted, and that color, contrast, text sizing, touch-target dimensions, and RTL mirroring are all delegated to CSS rules not present in this source file. `separation-of-concerns` passes because `Slider.tsx` is pure presentation over props with no business logic, and `unit-test-coverage` passes because `components.test.tsx` renders it directly and asserts on its emitted numeric value and dynamic caption.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename Behavioral Requirements to subject-only kebab-case and update every citation; document the missing accessible-name fallback and the hint/aria-describedby and caption/aria-valuetext gaps as facts rather than inventing new required ARIA props; name `Slider` as the canonical export and `CaptionedSlider` as its alias, with a matching Design Decision; correct the touch-target citation to WCAG 2.2 SC 2.5.8 (AA, 24×24) alongside WCAG 2.1 SC 2.5.5 (AAA, 44×44) and add the new reference; remove source-code-literal phrasing from Edge Cases and Accessibility Options and state behavior directly, including native browser clamping for out-of-range, off-step, and min-greater-than-max values; reformat Design Decisions to the Decision/Rationale/Approved form; rebuild Compliance as a catalog-linked table with lowercase statuses; add the missing hint class and DOM order to Appearance; correct `htmlFor`-vs-`for` and value-attribute-vs-property test assertions and add a Number-type vector and keyboard vectors; correct the WinUI 3 namespace and caption approach, the AppKit/UIKit platform split, and the Compose label/caption API; replace the "Not applicable" Localization section with the native RTL-inheritance and locale-aware caption-formatting notes; and link sibling form-control recipes in `related` |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Resolved label accessibility marker: labels are optional as per source code |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
