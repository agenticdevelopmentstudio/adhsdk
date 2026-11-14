---
id: 6f7c9bb6-b6fe-479a-9dbc-3ff174f7fed2
title: "Choice Slider"
type: ingredient
version: 1.3.2
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A slider control that selects from a discrete set of labeled choices."
platforms:
  - typescript
  - web
tags:
  - form-input
  - selection-control
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Choice Slider

## Overview

A choice slider is a slider control that lets users select one value from a discrete set of labeled options. It's useful when presenting 3–7 mutually exclusive choices where the options have a natural order and occupy limited space. Unlike a dropdown or radio buttons, the slider makes all choices immediately visible and suggests progression or spectrum. The component combines a discrete range/slider control with a label, caption showing the current selection, and optional hint text.

## Behavioral Requirements

- **accept-choice-array**: Component MUST accept an ordered collection of `Choice<T>` objects, each with a `value` property (string or number) and a `label` property (presentable content, e.g. text or a small view).
- **maintain-value-in-range**: When the `value` prop is passed, the component MUST find the matching choice by value and position the control at its index. If no match is found, it MUST default to the first choice (index 0).
- **fire-change-callback**: When the user changes the selection, the component MUST call the `onChange` callback with the `value` property of the newly selected choice, not the index.
- **display-current-label**: The component MUST display the `label` of the currently selected choice.
- **render-discrete-control**: The component MUST render a native discrete range/slider control with exactly `choices.length` selectable positions (one per choice), so only one choice can be selected at a time.
- **respect-disabled-state**: When the `disabled` prop is true, the control MUST be disabled, preventing user interaction.
- **render-label**: If a `label` prop is provided, the component MUST render it and MUST associate it with the control (e.g. a native label-for-control association) so assistive technology can read it as the control's accessible name.
- **render-hint**: If a `hint` prop is provided, the component MAY render it as additional descriptive text below the control.
- **custom-styling**: The component MAY accept a platform-appropriate styling hook (e.g. a `className` on web) and apply it to the root container alongside the component's required base style classes.
- **custom-id**: If an identifier (e.g. an `id` prop on web) is provided, the component MAY use it for the control. Otherwise, it MUST generate a unique identifier internally.

## Appearance

- **Container**: Uses class `aws-field` and `aws-field--choice-slider`. A `div` wrapping label, slider, caption, and hint.
- **Label**: When present, styled with class `aws-field__label`. Inline text color and size inherit from `<label>` defaults.
- **Slider wrapper**: Uses class `aws-slider`. Contains the range input and caption.
- **Range input**: Uses class `aws-slider__input`. Standard HTML range input styling; appearance varies by browser and platform.
- **Caption**: Uses class `aws-slider__caption`. Displays the selected choice's label. Positioned adjacent to or below the range input (layout depends on CSS not specified in source).
- **Hint**: Uses class `aws-field__hint`. Positioned below the slider when present. Styled as paragraph element.

## States

| State | Appearance change |
|-------|------------------|
| Default | Range input is interactive; caption displays current choice label. |
| Disabled | Range input has `disabled` attribute; pointer interaction disabled (browser default styling applied). |
| Focused | Range input receives keyboard focus; browser default focus indicator visible. |

## Accessibility

- **Role**: The range input has the implicit ARIA role `slider`.
- **Labeling**: Per **render-label**, if a `label` prop is provided, it MUST be associated with the range input via `<label htmlFor={fieldId}>`, where `fieldId` is the `id` prop or the `useId()` fallback. The `label` prop is optional, and when it is omitted the source sets no `aria-label`, no `aria-labelledby` and no `title` on the input, so the slider renders with no accessible name in that case.
- **Keyboard support**: The range input MUST support arrow key navigation (left/right to decrease/increase value) per HTML range input spec. No additional keyboard handling required.
- **Screen reader announcement**: The source sets no `aria-valuetext` on the range input, so assistive technology announces the raw numeric value — the choice index, `0` through `choices.length - 1` — and never the choice label. The `aws-slider__caption` span that carries the label is a sibling of the input and is not referenced by `aria-describedby`, `aria-labelledby` or any other relation, so it is not announced with the value either.
- **Touch target size**: The source sets no thumb size. `styles.css` gives `.aws-slider__input` only `flex: 1`, `min-width: 0`, `cursor: pointer` and `accent-color: var(--aws-accent)`, and declares no `::-webkit-slider-thumb`, `::-moz-range-thumb`, `height` or `width` rule anywhere, so the thumb is the user agent's native range thumb at its default size, tinted by the `--aws-accent` token. Native range thumb sizes vary by browser and are not guaranteed to meet a minimum interactive target. An implementation MUST keep the platform's native range thumb rather than substituting a custom one, MUST tint it using the `--aws-accent` token, and MUST ensure the resulting hit area meets at least 24×24 CSS px (WCAG 2.5.8 Target Size Minimum), enlarging the thumb's hit area with padding if the platform's native default falls short.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| choice-slider-001 | accept-choice-array, display-current-label | choices = [{value: "a", label: "Option A"}, {value: "b", label: "Option B"}], value = "a" | Component renders without error; caption displays "Option A" |
| choice-slider-002 | maintain-value-in-range | value = "b", choices = [{value: "a", label: "A"}, {value: "b", label: "B"}, {value: "c", label: "C"}] | Slider positioned at index 1; caption displays "B" |
| choice-slider-003 | maintain-value-in-range | value = "unknown", choices = [{value: "a", label: "A"}, {value: "b", label: "B"}] | Slider positioned at index 0; caption displays "A" (first choice is default) |
| choice-slider-004 | fire-change-callback | Slider moved from index 0 to index 1, choices = [{value: "opt-1", ...}, {value: "opt-2", ...}] | onChange called once with argument "opt-2" |
| choice-slider-005 | display-current-label | value = "c", choices = [{value: "a", label: "Label A"}, {value: "b", label: "Label B"}, {value: "c", label: "Label C"}] | Caption element displays text "Label C" |
| choice-slider-006 | render-discrete-control | choices.length = 5 | Range input has min="0", max="4", step="1" |
| choice-slider-007 | respect-disabled-state | disabled = true | Range input element has disabled attribute; user cannot interact with slider |
| choice-slider-008 | render-label | label = "Select preference" | Label element rendered with htmlFor pointing to range input id |
| choice-slider-009 | render-hint | hint = "Choose your preferred option" | Hint text rendered in paragraph with class aws-field__hint |
| choice-slider-010 | custom-id | id = "my-slider" | Range input has id="my-slider" |
| choice-slider-011 | render-discrete-control, edge case: Empty choices array | choices = [] | Range input renders inert with min="0", max="0"; caption is empty; onChange is never invoked |
| choice-slider-012 | maintain-value-in-range, edge case: Single choice | choices = [{value: "only", label: "Only Option"}], value = "only" | Range input has min="0", max="0" (slider cannot move); caption displays "Only Option" |
| choice-slider-013 | fire-change-callback; Keyboard support (Accessibility) | choices = [{value: "a", label: "A"}, {value: "b", label: "B"}, {value: "c", label: "C"}], value = "a", input focused, ArrowRight pressed once | Slider moves to index 1; onChange called once with argument "b" |
| choice-slider-014 | maintain-value-in-range, edge case: Number vs. string values | choices = [{value: 1, label: "One"}, {value: 2, label: "Two"}], value = "1" (string) | Strict-equality match fails against both entries; slider positioned at index 0; caption displays "One" |
| choice-slider-015 | fire-change-callback, edge case: onChange called during render | choices = [{value: "a", label: "A"}, {value: "b", label: "B"}], component re-rendered with a new `value` prop and no user interaction | onChange is not invoked |

## Edge Cases

- **Empty choices array**: `choices: Choice<T>[]` accepts an empty array and the source adds no guard against it. An implementation MUST render an inert range input (`min="0"`, `max="0"`) with an empty caption for an empty `choices` array, MUST NOT throw, and MUST NOT invoke `onChange`.
- **Single choice**: If `choices.length === 1`, the range input has `max="0"`, preventing any slider movement. The single choice is always selected and displayed. This is valid but may confuse users; no error state defined.
- **Null or undefined value prop**: When `value` is undefined, `findIndex` returns -1, and `Math.max(0, -1)` yields 0, selecting the first choice by default. This is a safe fallback.
- **Null or undefined label or hint**: If `label` is falsy, the label element is not rendered (conditional render). If `hint` is falsy, hint paragraph is not rendered. This is correct.
- **Number vs. string values**: The component compares `c.value === value` without type conversion. If choices contain numeric values but `value` is a string (or vice versa), the comparison fails and the first choice is selected. No type coercion is performed.
- **onChange called during render**: The `onChange` callback is only called in response to the `input` event on the range element. It is not called during render or on prop changes.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | ReactNode | undefined | Optional label text or element displayed above the slider. |
| `hint` | ReactNode | undefined | Optional hint text or element displayed below the slider. |
| `value` | string \| number | (required) | The currently selected choice value. SHOULD match one of the choice values; if no match is found, the component falls back to the first choice rather than erroring (see **maintain-value-in-range**). |
| `onChange` | function | (required) | Callback invoked with the selected choice's value when the slider moves. |
| `choices` | `Choice<T>[]` | (required) | Array of selectable options. Each choice has a `value` and `label`. |
| `disabled` | boolean | false | When true, slider interaction is disabled. |
| `className` | string | undefined | Optional additional CSS class(es) to apply to the root container. |
| `id` | string | (auto-generated) | Optional custom ID for the range input. If omitted, a unique ID is generated via `useId()`. |

## Deep Linking

Not applicable: Component is a form field, not a routable page.

## Localization

Not applicable: Component does not manage translatable strings. The `label`, `hint`, and choice `label` properties are provided by the consumer; localization is the consumer's responsibility.

## Accessibility Options

The component responds to accessibility display options through browser defaults and CSS framework styling:

- **Reduce Motion**: The browser's range input may use default animations for thumb movement. The source component adds no custom animation; browser and CSS framework Reduce Motion handling applies to the range input and caption.
- **Increase Contrast**: The browser's range input appearance and the CSS framework (via `aws-slider__input` and `aws-slider__caption` classes) respond to platform contrast settings. The component does not apply specific contrast overrides beyond framework defaults.
- **Differentiate Without Color**: Selection is conveyed via the slider thumb position and the visible caption label text, not color alone. The caption provides text-based indication independent of visual position.

## Feature Flags

Not applicable: Component is a library ingredient, not a feature behind a flag.

## Analytics

Not applicable: Component does not emit analytics events. Event tracking is the consumer's responsibility via the `onChange` callback.

## Privacy

Not applicable: Component does not collect, store, or transmit user data.

## Logging

Not applicable: Component does not perform logging. Debugging is handled via the platform's standard developer tooling (e.g. React DevTools on web).

## Platform Notes

- **SwiftUI**: Implement using `Slider(value:in:step:)` with `value` bound to a `Double` that is rounded to `Int` on read (`in: 0...Double(choices.count - 1)`, `step: 1`). Track the rounded index in state and derive the current choice from it. Render the current choice's label in a `Text` view, and lay out label + control + caption + hint in a `VStack` (or `LabeledContent` for the label association). Disabled state via `.disabled(isDisabled)` modifier.

- **Compose**: Use `Slider` composable with `value`, `onValueChange`, `valueRange = 0f..maxOf(0, choices.size - 1).toFloat()`, and `steps = maxOf(0, choices.size - 2)` to enforce discrete steps; when `choices.size <= 1` the range is degenerate (`0f..0f`), so render the slider disabled/inert rather than passing a negative `steps` value. Convert the `value` to `Int` to index into the choices array. Render the current choice label in a `Text` composable. Apply `enabled` parameter to the slider for the disabled state. Use `Modifier.padding()` and `Modifier.fillMaxWidth()` for spacing and layout.

- **React/Web**: Implement as in the source using an HTML `<input type="range">` element with `min="0"`, `max` equal to `choices.length - 1`, and `step="1"`, wrapped in a container. Bind `value={currentIndex}` and call `onChange` with `choices[newIndex].value` on the input's `input`/`onChange` event. Associate an optional `label` with the input via `<label htmlFor={fieldId}>`, where `fieldId` is the `id` prop or a `useId()` fallback. Accept `label` and `hint` as `ReactNode` for flexibility. Style using CSS classes (`aws-field`, `aws-field--choice-slider`, `aws-slider`, `aws-slider__input`, `aws-slider__caption`, `aws-field__hint`).

- **AppKit / UIKit**: On macOS, use `NSSlider` with `minValue = 0`, `maxValue = choices.count - 1`, `numberOfTickMarks = choices.count`, and `allowsTickMarkValuesOnly = true` to enforce discrete steps (`NSSlider` has no `isIntegral` property, so tick-mark snapping alone provides the discreteness). Add an `NSTextField` to display the current choice label. On iOS, `UISlider` does not support discrete steps natively; round `value` to the nearest integer in the `.valueChanged` action and call `setValue(_:animated:)` to snap the thumb back to that rounded position. For iOS, a segmented control (`UISegmentedControl`) may be more appropriate if screen space permits.

- **WinUI 3**: Use `Slider` control with `Minimum = 0`, `Maximum = choices.Count - 1`, `StepFrequency = 1`, and `SnapsTo = SnapsTo.StepValues` to enforce discrete stepping (`SnapPointsType.MandatoryWithinRange` belongs to `ScrollViewer`, not `Slider`). Bind the slider's `Value` to an index variable. Use a `TextBlock` to display the current choice's label. Apply `IsEnabled` binding for the disabled state. Use `StackPanel` for layout (label, slider, caption, hint). Localization of the `label`/`hint`/choice labels is the consumer's responsibility, consistent with the Localization section — do not resource them with `x:Uid`/RESX inside this control.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/ChoiceSlider.tsx` | unverified |

## Design Decisions

- **Decision**: The control's positioning is index-based (0 to `choices.length - 1`) while the `onChange` callback exposes the selected choice's `value`, not its index.
  **Rationale**: This decouples choice order from choice identity, so callers can reorder choices without breaking `onChange` handling, at the cost of an index → value translation that is not explicit in the prop types.
  **Approved**: pending

- **Decision**: When `value` does not match any choice, the component selects the first choice (index 0) rather than throwing or rendering nothing; no dev-time warning is logged.
  **Rationale**: This fail-safe avoids undefined rendering for an invalid `value`, at the cost of silently masking a caller error. See **maintain-value-in-range** and the Configuration section's `value` entry, which record this as the single, non-contradictory contract.
  **Approved**: pending

- **Decision**: `value` is matched against `choice.value` using strict equality (`===`); no type coercion is performed between string and number values.
  **Rationale**: Preserves type safety and predictable matching, at the cost of surprising a caller who mixes numeric and string choice values across renders.
  **Approved**: pending

- **Decision**: When `disabled` is true, only the range control receives the `disabled` attribute; the label and hint continue to render as normal, non-disabled elements.
  **Rationale**: Matches standard HTML form behavior, where disabling an input does not implicitly disable its associated label. Consumers should not expect clicking the label to focus the now-disabled control.
  **Approved**: pending

- **Decision**: The control announces only its numeric index to screen readers; the selected choice's label is visual-only and is not included in `aria-valuetext` or otherwise related to the input for announcement.
  **Rationale**: The source sets no `aria-valuetext` and does not relate the caption to the input via `aria-describedby` or `aria-labelledby`, so no textual value is exposed to assistive technology today. See the Accessibility section's "Screen reader announcement" item.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on `ChoiceSlider.tsx` and `styles.css`: the native `<input type="range">` gives keyboard operability and an implicit `slider` role with a native `<label>` association for free (passed), font sizes in `styles.css` (`aws-field__label`, `aws-field__hint`, `aws-slider__caption`) use `rem` units that scale with the browser's root font size (passed for dynamic type); but the missing `aria-valuetext` and the missing fallback accessible name for the label-less case (see the Accessibility section's "Labeling" and "Screen reader announcement" items) make screen-reader support partial, the unset thumb size against theme-driven `--aws-accent`/`--aws-border`/`--aws-text-muted` colors makes touch-target size and contrast ratio partial (the source cannot guarantee either from its CSS alone), and the component never hardcodes or transforms consumer-supplied text (label/hint/choice labels pass through as opaque `ReactNode`/string content) so hardcoded-strings and Unicode handling pass while text-expansion tolerance is partial, since the flex layout has no explicit overflow handling verified for very long translated labels; the only business logic — mapping the range input's index to a `choices` entry and clamping an out-of-range `value` to the first choice — is a single self-contained block with no presentation or data-layer coupling (separation-of-concerns); and `components.test.tsx`'s `ChoiceSlider` suite asserts that logic end to end, driving the range input and checking both the emitted value and the displayed caption (unit-test-coverage).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.2 | 2026-09-25 | Mike Fullerton | Wrapped Choice<T>[] in code span; added best-practices compliance rows. |
| 1.3.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: behavioral requirements restated platform-neutral and renamed to subject-only kebab-case, with render-label promoted to MUST; value-match contract contradiction between Configuration and requirements resolved to the documented fallback; Design Decisions reformatted to Decision/Rationale/Approved; Compliance table added; Edge Cases narration replaced with observable behavior and new test vectors added for empty/single choice, keyboard input, type mismatch, and prop-only updates; Platform Notes API errors fixed for SwiftUI, Compose, AppKit, UIKit, and WinUI 3; status set to draft pending the two open accessibility gaps |
| 1.2.0 | 2026-09-22 | Claude Opus 5 | Thumb sizing and empty-choices behavior restated as fact from `styles.css` and the source (tooling: Claude Opus 5); two accessibility gaps retained |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Revision pass Phase 1: gap triage across Accessibility and Edge Cases (tooling: Claude Haiku 4.5) |
| 1.0.0 | 2026-09-22 | (cookbook update) | Initial creation |
