---
id: e9504a52-046c-4777-9704-20f611cf76f7
title: "FieldFootnote"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Display line under a form control showing either a validation error or hint text, with error taking precedence."
platforms:
  - typescript
  - web
tags:
  - forms
  - validation
  - hint
  - accessibility
depends-on: []
related:
  - 0c199036-81c3-47c3-9e79-e4b8187ca69a
  - c9e70ad4-89c9-4c44-a2d6-a64da32a64af
  - a105b6cf-307d-4156-8b73-468f627f3c9b
  - c5703986-6d14-4341-8719-b89e44f2ab80
references: []
approved-by: ""
approved-date: ""
---

# FieldFootnote

## Overview

FieldFootnote is a display component that renders validation feedback or supplemental information below a form control. It occupies a single line in the layout and shows either an error message (when validation fails) or a hint message (when validation passes or no validation has occurred). The component exists independently so that controls which cannot use the standard Field wrapper (such as checkboxes with custom row layouts) can still display feedback in a consistent position using the same styling.

## Behavioral Requirements

- **error-shown-when-present**: When `error` prop is set to a truthy value, the component MUST render that value in the error presentation (red, monospace, small text).
- **error-takes-precedence**: When both `error` and `hint` props are truthy, the component MUST show only the error, not the hint.
- **hint-shown-without-error**: When `error` prop is not set or is falsy, and `hint` prop is truthy, the component MUST render the hint in the hint presentation (dim text, monospace, small text).
- **renders-nothing-when-empty**: When both `error` and `hint` props are falsy or undefined, the component MUST return null (render nothing).
- **error-id-applied**: When `errorId` prop is provided, the component MUST apply that value as the `id` attribute on the error span element.
- **error-id-only-on-error**: When `errorId` prop is provided, the `id` attribute MUST be applied only to the error span, never to the hint span.
- **caller-class-name-merged**: When `className` prop is provided, the component MUST append it to the default classes; a caller class MUST override any default class it conflicts with.
- **supports-react-node-content**: The component MUST accept any node type (string, element, fragment, or number) in both `hint` and `error` props for rendering when present. A falsy value — including the number `0` or an empty string `""` — is treated as absent rather than rendered; see **renders-nothing-when-empty**.

## Appearance

- **Font**: Monospace (FontFamily.Monospace or platform equivalent), one logical size of 11.2 (0.7rem on web; 11.2 pt/sp/DIP on every other platform — the same size is used everywhere, see Platform Notes)
- **Error color**: error-foreground token (`text-apt-red` Tailwind class on web; map to the platform's semantic error/red color)
- **Hint color**: secondary-foreground token (`text-apt-text-dim` Tailwind class on web; map to the platform's secondary/dim label color)
- **Line height**: Inherits default; no custom line-height specified
- **Padding**: No explicit padding; inherits from ancestor or uses browser default inline span padding (typically zero)
- **Border**: None
- **Shadow**: None
- **Min/Max size**: None; width is determined by content

## States

| State | Appearance change |
|-------|------------------|
| Showing error | Red, monospace, text-[0.7rem] |
| Showing hint | Dim text, monospace, text-[0.7rem] |
| Empty (no error, no hint) | Rendered as null; no DOM element |

## Accessibility

- **Role**: No explicit ARIA role applied. The component is a passive display element and does not interact with the user.
- **Error identification**: The error span carries an optional `id` attribute (via `errorId` prop) so that a form control can reference it with `aria-describedby`, allowing screen readers to announce the error message when the control is focused.
- **Hint handling**: Hints are not assigned an `id` and are not referenced via `aria-describedby` by this component or by its composing wrapper — only the error gets that treatment. In the shipped composition a hint instead becomes part of the control's accessible *name*, not its description: `Field` renders the caption, the control, and `FieldFootnote`'s hint text all inside one native `<label>` element, and a native `<label>` contributes its full text content to the accessible name of whatever it labels. No code in this stack wires a hint's text into a control's accessible description.
- **Semantics**: The component uses a generic `<span>` element; no `role="alert"` or `role="status"` is applied. The error line is not automatically announced on appearance; screen readers announce it when the control with `aria-describedby` is focused.
- **Color dependence**: Error (red) and hint (dim) are currently distinguished only by color; no icon, prefix, or other non-color cue is present in the source. See **Accessibility Options** below for how this behaves under Differentiate Without Color.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| field-footnote-001 | error-shown-when-present | `error="This field is required"`, `hint={undefined}` | Renders a single element with the text "This field is required", using the error-foreground color and the monospace caption text size; no `id` attribute is present |
| field-footnote-002 | error-takes-precedence | `error="Error occurred"`, `hint="Hint text"` | Renders the error text only; the hint text is not present in the output |
| field-footnote-003 | hint-shown-without-error | `error={undefined}`, `hint="Type at least 8 characters"` | Renders a single element with the text "Type at least 8 characters", using the secondary-foreground color and the monospace caption text size; no `id` attribute is present |
| field-footnote-004 | renders-nothing-when-empty | `error={undefined}`, `hint={undefined}` | Returns null; nothing is rendered |
| field-footnote-005 | error-id-applied | `error="Error"`, `errorId="email-error"` | Renders the error element with `id="email-error"` |
| field-footnote-006 | error-id-only-on-error | `hint="Hint"`, `errorId="some-id"` | Renders the hint element with no `id` attribute present |
| field-footnote-007 | caller-class-name-merged | `error="Error"`, `className="custom-class"` | Renders the error element with the caller's `custom-class` present alongside the default classes |
| field-footnote-008 | supports-react-node-content | `error={<strong>Bold error</strong>}` | Renders the error element containing the bold element as a child |

## Edge Cases

- **Empty string error**: `error=""` (falsy) is treated as no error; hint is shown if present. Empty strings are falsy in JavaScript.
- **Empty string hint**: `hint=""` (falsy) is treated as no hint; nothing is rendered if error is also absent.
- **Zero or false**: `error={0}` or `error={false}` are falsy and treated as no error; same for hint. See **supports-react-node-content**.
- **Null/undefined**: Both are falsy and result in no error or hint being shown.
- **className merging collision**: If `className` contains a utility class that conflicts with a default class in the same category (e.g., a caller passing `text-blue-500` when the default is `text-apt-red`), the merge utility resolves the conflict by last-wins — the caller's class is applied after the defaults and therefore takes effect — not by CSS specificity.
- **errorId set but hint renders**: If `errorId` is provided while `error` is falsy, the hint renders instead and carries no `id` (see **error-id-only-on-error**, vector field-footnote-006). A consumer that unconditionally wires a control's `aria-describedby` to `errorId` will then point at an id that does not exist in the DOM whenever only the hint is showing; consumers should apply `aria-describedby={errorId}` only while `error` is actually present.

## Configuration

Not applicable: FieldFootnote has no configuration options. It is a stateless presentation component; all behavior is determined by its props.

## Deep Linking

Not applicable: FieldFootnote is a non-interactive display component with no user navigation or link targets.

## Localization

Not applicable: The component does not define or localize any strings of its own. All text content (error and hint messages) is provided by the caller via props.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; the component has no animation. |
| Increase Contrast | Not applicable; the component defines no custom contrast handling and relies on the platform's default rendering of its color tokens. |
| Differentiate Without Color | Not handled: error and hint are currently distinguished only by color (see **Accessibility**, Color dependence); no icon, prefix, or other non-color cue is added under this setting. |

## Feature Flags

Not applicable: The component has no feature flag logic and is always enabled when imported.

## Analytics

Not applicable: FieldFootnote does not emit or track any analytics events. It is a stateless display component.

## Privacy

Not applicable: FieldFootnote does not collect, store, or transmit any user data. It renders text provided by its caller.

## Logging

Not applicable: The component does not emit debug logs or instrumentation.

## Platform Notes

- **React/Web**: Implemented using a React functional component with `ReactNode` type for content props. Uses the `cn` utility (Tailwind classname merger from `lib/utils`) to append custom classes to the defaults, with a caller class taking effect over any default it conflicts with (last-wins). Text size is `text-[0.7rem]` — the same logical 11.2 size used on every platform. Error and hint colors reference the error-foreground and secondary-foreground tokens, exposed on web as the Tailwind classes `text-apt-red` and `text-apt-text-dim`.
- **SwiftUI**: Implement using a `Text` view with `.font(.system(size: 11.2, weight: .regular, design: .monospaced))` for error and hint. Use `Color` tokens for the error-foreground and secondary-foreground tokens above. Render conditionally: show error if present, else show hint if present, else return `EmptyView()`.
- **Compose**: Implement using a `Text` composable with `fontSize = 11.2.sp`, `fontFamily = FontFamily.Monospace`, and `fontWeight = FontWeight.Normal`. Apply the error-foreground/secondary-foreground color tokens. Render conditionally: if error is not null show it in the error color, else if hint is not null show it in the secondary color, else render nothing.
- **AppKit/UIKit**: On macOS, use `NSTextField` or `NSTextView` (read-only) with `.monospacedSystemFont(ofSize: 11.2, weight: .regular)`. On iOS, use `UILabel` with `.monospacedSystemFont(ofSize: 11.2, weight: .regular)`. Apply the platform color tokens equivalent to error-foreground/secondary-foreground. Render conditionally; update layout when error/hint changes.
- **WinUI 3**: Implement using `TextBlock` with `FontFamily="Consolas"` (or a theme monospace resource), `FontSize="11.2"`, and `FontWeight="Normal"`. Bind `Foreground` to a brush that switches between the error-foreground and secondary-foreground tokens depending on whether error or hint is present. Render conditionally using the `Visibility` property: `Visible` if content exists, `Collapsed` otherwise.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/field-footnote.tsx` | unverified |

## Design Decisions

**Decision**: FieldFootnote does not use the standard `ErrorText` component; it renders its own error/hint spans at one shared size (`font-mono text-[0.7rem]`) instead of `ErrorText`'s `text-sm`.
**Rationale**: `ErrorText` uses `text-sm`, whose metrics differ from the hint text. If an error at `ErrorText`'s size swapped in for a hint at FieldFootnote's size, the differing text size/line height would shift the surrounding layout on the keystroke that made the value invalid. Giving error and hint identical metrics, differing only in color, keeps that swap layout-stable. `ErrorText` separately carries `role="alert"`; FieldFootnote does not, but that is an independent consequence of not reusing `ErrorText`, not a cause of the layout-stability decision — FieldFootnote's error is announced through `errorId`/`aria-describedby` instead (see **Accessibility**).
**Approved**: pending

**Decision**: FieldFootnote is exported as a standalone primitive rather than living only inside `Field`.
**Rationale**: Some form controls — notably checkboxes with custom row layouts — cannot use `Field`'s label structure and must build their own row, but still need to report validation feedback in the same place and words. Extracting FieldFootnote lets both `Field`-wrapped controls and custom-row controls share one implementation, so a fix to the error/hint logic does not have to be made twice and risk drifting between the two call sites.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on the source directly: it renders arbitrary caller-supplied `ReactNode` content with no strings, truncation, or direction-specific styling of its own (the internationalization checks pass), uses a relative `text-[0.7rem]` size with no explicit Dynamic Type binding and named color tokens with no contrast values given (both partial, since the source cannot confirm the rest), and applies no ARIA role while correctly scoping `errorId` to only the error span (semantic-markup passed). `separation-of-concerns` is `passed` because the component is pure presentation implementing only the error/hint precedence over props; `unit-test-coverage` is `failed` because no test exercises `field-footnote.tsx`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Corrected Hint handling: a hint becomes part of the accessible name via Field's shared label, not a described-by description. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and reworded the class-merge and ReactNode requirements platform-neutrally; unified the font size to one logical 11.2 across platforms and replaced the hardcoded WinUI font; named semantic color tokens in place of raw Tailwind class names; reformatted Design Decisions and separated the layout-shift cause from the role="alert" consequence; corrected the hint accessible-description claim and the color-dependence description; replaced the made-up Compliance checks with real accessibility and internationalization checks; fixed test vectors to assert observable outcomes instead of raw class strings; added the errorId/hint edge case; added tags and related links |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from field-footnote.tsx source (drafted by Claude Haiku 4.5) |
