---
id: f8b8792e-12f2-4ca1-80a8-9ae7f2c5b31d
title: "Color Picker"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A controlled form field component that allows users to select a color using the native color picker and displays the hex value."
platforms:
  - typescript
  - web
tags:
  - form
  - color
  - input
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Color Picker

## Overview

The Color Picker is a form field component that wraps the native HTML5 `<input type="color">` element. It presents a native color picker interface to the user and displays the selected color's hex value. The component accepts a controlled `value` prop and fires an `onChange` callback when the user selects a new color. An optional label and hint text provide context and guidance.

## Behavioral Requirements

- **render-label**: The component MUST render a label element associated to the input when a `label` prop is provided.
- **accept-value**: The component MUST accept a `value` prop containing a valid hex color string (e.g., `#ff0000`); the native color input normalizes any accepted value to a 6-digit lowercase hex string (`#rrggbb`).
- **fire-change**: The component MUST invoke the `onChange` callback with the new hex color string, as reported by the native input in lowercase `#rrggbb` form, when the user selects a color from the picker.
- **render-hex-display**: The component MUST display the `value` prop verbatim, as text adjacent to the picker; this text is not normalized by the native input — only the input element itself receives the browser's lowercase `#rrggbb` sanitization.
- **support-disabled**: The component MUST respect a `disabled` prop and prevent interaction when `true`.
- **render-hint**: The component MUST render hint text when a `hint` prop is provided.
- **generate-id**: The component MUST generate a unique `id` for the color input if no `id` prop is provided.
- **hide-hex-from-assistive-tech**: The component MUST mark the hex value display with `aria-hidden="true"` to prevent duplicate announcements by screen readers.
- **accept-classname**: The component MAY accept a `className` prop to allow custom CSS classes to be applied to the field container.

## Appearance

- **Corner radius**: Follows the native color input's platform-default corner radius; no override is applied.
- **Padding**: The field container uses the design system's standard field padding token; the color swatch and hex text sit inline with the field's default inline spacing.
- **Font**: The hex display inherits the field's body text token.
- **Background**: The native color input uses its platform-default background; the hex display inherits the field's background token.
- **Foreground/Text**: The hex value text uses the field's default text-color token.
- **Border**: The native color input uses its platform-default border.
- **Shadow**: None by default.
- **Min/Max size**: The native color input uses its platform-default dimensions; the field container may constrain overall width via layout, not a fixed size.

## States

| State | Appearance change |
|-------|------------------|
| Default | Color input displays current value; hex value shown as text |
| Disabled | Color input visually disabled; color input interaction blocked |
| Focused | Native input focus ring displayed (user agent dependent) |

## Accessibility

- **Role**: `<input type="color">` has no dedicated ARIA role mapping in the HTML-AAM spec; browsers and assistive technologies expose it inconsistently (for example, as a generic color well rather than a `textbox`). The `label` is associated to the input via `htmlFor` matching the input's `id`.
- **Label requirements**: When a `label` prop is provided, it MUST be associated to the input via `htmlFor` matching the input's `id`.
- **Hex value announcement**: The hex value display is marked `aria-hidden="true"`, on the assumption that the color input's own accessible state already conveys the value when it changes. That assumption is not verified across every browser/AT pairing, so some combinations may not announce the color at all once it is hidden from the accessibility tree.
- **Minimum tap target**: The native color input button itself has user-agent-defined sizing; the label and hint text are not interactive tap targets.
- **Keyboard navigation**: The native HTML color input supports standard keyboard interaction (Tab to focus, Enter/Space to open picker on supporting browsers).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| color-001 | render-label | label="Choose Color" | Label element rendered with matching htmlFor |
| color-002 | accept-value | value="#FF0000" | Input value normalized and set to "#ff0000" |
| color-003 | fire-change | User selects RGB (0, 255, 0) from the picker | onChange callback invoked with "#00ff00" |
| color-004 | render-hex-display | value="#FF0000" | Hex text "#FF0000" (the raw `value` prop, unchanged) displayed next to picker |
| color-005 | support-disabled | disabled={true} | Input is disabled and not interactive; onChange is not invoked |
| color-006 | render-hint | hint="Select brand color" | Hint text is rendered in the field |
| color-007 | generate-id | No id prop supplied | Unique id generated and applied to input |
| color-008 | hide-hex-from-assistive-tech | Any state | Hex display has aria-hidden="true" |
| color-009 | accept-classname | className="custom-class" | Custom class applied to container div |

## Edge Cases

- **Empty or invalid value**: The component performs no validation or parsing of `value`; it passes the prop straight through to the native `<input type="color">`. Per the HTML value-sanitization algorithm, any value that is not a valid 6-digit lowercase hex color — including an empty string — is reset to `#000000` by the browser itself; the component does not detect or surface this fallback. The hex text display is unaffected by this sanitization: it always shows the raw `value` prop (see **render-hex-display**), so an empty or non-lowercase `value` renders a swatch showing `#000000` next to hex text that does not match it, until a controlled parent updates `value` from `onChange`'s already-lowercased argument.
- **Null or undefined label/hint**: Component gracefully skips rendering label or hint if props are not provided; no error or empty placeholder is shown.
- **Disabled with active focus**: On some platforms, a disabled input may retain focus; the browser's native input handles this state.
- **Rapid value changes**: Multiple onChange calls in quick succession (e.g., from drag in the picker) are all propagated immediately; the component does not debounce.

## Configuration

Not applicable. The component accepts configuration through its props (`label`, `hint`, `value`, `onChange`, `disabled`, `className`, `id`); no separate configuration object is used.

## Deep Linking

Not applicable. This is a form field component within a larger form or dialog; deep linking is not a relevant use case.

## Localization

The component itself contains no hardcoded strings. The `label` and `hint` props are ReactNode and can be localized strings passed by the parent. The hex value display is language-neutral (hex format is universal).

## Accessibility Options

- **Reduce Motion**: Not applicable. The component does not use motion or animations; it relies on the native color input's behavior, which respects system motion preferences via the user agent.
- **Increase Contrast**: Applicable. The hex value text (`.aws-color__hex`) must meet at least the WCAG AA minimum contrast ratio of 4.5:1 against its background; the component itself sets no color and depends entirely on the `.aws-color__hex` CSS class to meet this minimum.
- **Differentiate Without Color**: Not applicable. The component does not use color alone to convey state; the disabled state is enforced by the native input's disabled attribute.

## Feature Flags

Not applicable. The component has no feature flag guards; it is always available.

## Analytics

Not applicable. The component itself does not emit analytics events; the parent form or application layer is responsible for tracking color selection if needed.

## Privacy

- **Data collected**: None directly by the component. The `value` prop and `onChange` callback are controlled by the parent; any data retention or transmission is the responsibility of the parent application.
- **Storage**: Not applicable.
- **Transmission**: Not applicable.
- **Retention**: Not applicable.

## Logging

Not applicable. The component does not emit diagnostic logs; browser DevTools and the native color input's behavior provide visibility into state.

## Platform Notes

- **SwiftUI**: On iOS and macOS, use `ColorPicker` from SwiftUI (`ColorPicker(_ label:, selection:)`) to wrap SwiftUI's native color picker. Bind the selection to a `@State` variable and handle `onChange` semantics via SwiftUI's reactive model. Label and value are natively supported.
- **Compose**: Jetpack Compose has no built-in color-picker composable. Implement one with a custom composable (e.g., a color wheel or swatch grid built from `Canvas`/`Box`) or a third-party library. Bind state via `remember { mutableStateOf(...) }`, expose an `onValueChange` callback, and render the label and hex text as sibling `Text` composables.
- **React/Web**: The web implementation uses the native HTML5 `<input type="color">` in `packages/web/packages/controls/src/user-settings/components/ColorPicker.tsx`. The component is a controlled React component; it renders `.aws-field` and `.aws-color` container classes, associates the label via `htmlFor`, and displays the hex value in `.aws-color__hex`. CSS classes are applied from the `aws-*` namespace (AgenticWebStack design system).
- **AppKit / UIKit**: On macOS with AppKit, use `NSColorWell` for system color picking; bind its `.color` property and handle its action when the user changes the color. On iOS with UIKit (14+), use `UIColorWell` for a compact well control, or `UIColorPickerViewController` for a full color-picker sheet, and handle changes via `UIColorPickerViewControllerDelegate` (`colorPickerViewControllerDidSelectColor:`) or the well's `.selectedColor`. Implement the label and hex value display in custom views.
- **WinUI 3**: On Windows with WinUI 3, use the native `ColorPicker` control from `Microsoft.UI.Xaml.Controls`. Bind the `Color` property with a two-way binding, handle the `ColorChanged` event for `onChange` semantics, and display the hex value in a separate `TextBlock`. Apply Fluent 2 design system styling via theme resources.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/ColorPicker.tsx` | unverified |

## Design Decisions

- **Decision**: Display the color's hex value rather than RGB.
  **Rationale**: Hex is the standard representation for web colors, matches developer expectations, and is more compact in the form than an RGB triplet.
  **Approved**: pending

- **Decision**: Mark the hex value display (`.aws-color__hex`) with `aria-hidden="true"`.
  **Rationale**: The value duplicates state already exposed through the color input itself, so hiding the plain-text span avoids a redundant announcement in browsers/AT pairs where the input's accessible state already conveys the value on change. This assumes typical Chromium/WebKit + VoiceOver/NVDA behavior and has not been verified against every browser/AT combination.
  **Approved**: pending

- **Decision**: Use the native `<input type="color">` rather than a custom color-picker UI.
  **Rationale**: Leverages user-agent-provided UX, reduces bundle size, and ensures consistent behavior across browsers without building custom picker/canvas logic.
  **Approved**: pending

- **Decision**: Require both `value` and `onChange` props, making this a controlled component.
  **Rationale**: Keeps the parent in full control of color state, enabling validation, side effects, and multi-field coordination without the component owning any internal state.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: the native input is keyboard-focusable and operable with no custom handling needed (passed); the ambiguous ARIA role and the unverified `aria-hidden` assumption on the hex text mean screen-reader and ARIA semantics are only partially certain (partial); text color, contrast, and control sizing all depend on the external `.aws-*` CSS classes that the component references but does not define, so those cannot be confirmed from the source alone (partial); and the component's `label`/`hint` props are plain `ReactNode` with no string literals in the source (passed). separation-of-concerns passes because `ColorPicker.tsx` is pure presentation over its `value`/`onChange`/`label`/`hint` props with no logic beyond an id fallback and a class-name join, and unit-test-coverage passes because `components.test.tsx`'s `ColorPicker` suite exercises the `onChange` emission with a meaningful assertion.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Corrected render-hex-display: shows raw value prop verbatim, not native-input-normalized lowercase. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case names and updated every citation, corrected the ARIA role and aria-hidden announcement claims in Accessibility, corrected the Compose/AppKit-UIKit/WinUI 3 platform notes to name real native APIs, specified the accepted hex format and the native fallback for empty/invalid values, normalized hex casing across requirements and test vectors, added a disabled-state onChange assertion and dropped an unstated layout claim in the test vectors, reworded the Disabled state row, marked Increase Contrast applicable, replaced the CSS-coupled Appearance section with platform-neutral tokens, reformatted Design Decisions into Decision/Rationale/Approved form, added a Compliance table, and added tags |
