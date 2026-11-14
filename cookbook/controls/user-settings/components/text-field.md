---
id: dc548100-af44-4d93-9cb9-93c35546e08c
title: "Text Field"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Single-line and multi-line text input field with label, hint, and autofill prevention by default (a caller-supplied token opts back in)."
platforms:
  - typescript
  - web
tags:
  - form
  - input
depends-on: []
related:
  - a105b6cf-307d-4156-8b73-468f627f3c9b
  - 43c55f5e-d9b3-430b-9026-d0af510fda15
references: []
approved-by: ""
approved-date: ""
---

# Text Field

## Overview

A text input field component for web that supports single-line text input, multi-line textarea, labels, helper text (hints), and configurable autofill behavior. The component wraps native HTML `<input>` and `<textarea>` elements and manages their interaction with browser autofill mechanisms. Two variants are provided: `TextField` for general text input and `SecureTextField` for password and sensitive token storage.

## Behavioral Requirements

- **render-input-element**: The component MUST render either an HTML `<input>` element (when `multiline` is `false` or omitted) or an HTML `<textarea>` element (when `multiline` is `true`).
- **bind-value**: The component MUST bind the `value` prop to the input element's `value` attribute.
- **call-on-change**: The component MUST invoke the `onChange` callback with the current input value (string) whenever the user types into the field.
- **render-label**: When a `label` prop is provided, the component MUST render an HTML `<label>` element with `htmlFor` attribute matching the input element's `id`.
- **generate-id**: The component MUST use an explicitly supplied `id` prop for the input element when present, and otherwise MUST generate a unique ID using React's `useId` hook and apply it to the input element.
- **accept-placeholder**: The component MUST pass the `placeholder` prop to the input element.
- **respect-disabled**: The component MUST apply the `disabled` attribute to the input element when the `disabled` prop is `true`.
- **render-hint**: When a `hint` prop is provided, the component MUST render a `<p>` element containing the hint text after the input element.
- **apply-classname**: The component MUST accept a `className` prop and append it to its root element's class list.
- **support-text-types**: The `TextField` component MUST support `type` values of `'text'`, `'email'`, `'url'`, and `'tel'`, with `'text'` as the default.
- **handle-multiline**: When `multiline` is `true`, the component MUST render a `<textarea>` element with `rows="4"` instead of an `<input>` element.
- **apply-autofill-token**: When `autoComplete` is defined and, after trimming and lowercasing, is not `'off'`, the component MUST pass the original `autoComplete` value through unchanged to the input element's `autoComplete` attribute and MUST NOT apply the autofill-prevention attributes. There is no fixed allowlist of tokens — any non-`'off'` value qualifies (e.g. `'email'`, `'tel'`, `'url'`, `'name'`).
- **prevent-autofill-default**: When `autoComplete` is `undefined`, or trims/lowercases to `'off'`, the component MUST apply autofill-prevention attributes (`autoComplete: 'off'`, `data-form-type: 'other'`, `data-1p-ignore: 'true'`, `data-lpignore: 'true'`, `data-bwignore: 'true'`, `data-protonpass-ignore: 'true'`) via the `noAutofillPropsFor` helper.
- **always-prevent-password-manager**: The `SecureTextField` component MUST always apply the same six autofill-prevention attributes via `noAutofillProps` and MUST NOT accept an `autoComplete` prop.
- **mask-password-input**: The `SecureTextField` component MUST render an `<input type="password">` to visually mask the input value on screen.
- **apply-semantic-css-classes**: The component MUST apply CSS classes to structure the component: `'aws-field'` on the root, `'aws-field--text'` for both variants, `'aws-field--secure'` additionally for `SecureTextField`, `'aws-field__label'` on the label, `'aws-field__input'` and `'aws-field__textarea'` on input/textarea respectively, and `'aws-field__hint'` on the hint paragraph.

## Appearance

- **Corner radius**: `0.375rem`, set by `.aws-field__input` in `packages/web/packages/controls/src/user-settings/styles.css`.
- **Padding**: `0.5rem` vertical × `0.65rem` horizontal, set by `.aws-field__input`.
- **Font**: The input inherits the surrounding font (`font: inherit`) at `font-size: 0.9rem`. The label uses `font-size: 0.8rem`, `font-weight: 500`, uppercase, `letter-spacing: 0.04em`. The hint uses `font-size: 0.75rem`.
- **Background**: `var(--aws-bg)` (resolves to `var(--color-surface, var(--bg, #0c0c0f))`).
- **Foreground/Text**: The input uses `color: inherit`; the label and hint use `var(--aws-text-muted)`.
- **Border**: `1px solid var(--aws-border)`; focus changes it to `var(--aws-accent)`; disabled drops opacity to `0.55`.
- **Shadow**: None; the stylesheet applies no shadow to `.aws-field__input`.
- **Min/Max size**: The input is `width: 100%` with no min/max; the textarea additionally sets `min-height: 4.5rem` and `resize: vertical`, on top of the fixed `rows={4}` set by the component.

## States

| State | Appearance change |
|-------|------------------|
| Default | Input or textarea rendered normally with base styling applied via `.aws-field__input` or `.aws-field__textarea`. |
| Disabled | `disabled` attribute applied to input/textarea; `.aws-field__input:disabled` drops opacity to `0.55`. |
| Focused | `.aws-field__input:focus` sets `border-color: var(--aws-accent)`; component does not apply inline focus styles. |
| Placeholder visible | When `placeholder` prop is provided and input is empty, browser renders the placeholder text. |
| With label | When `label` prop is provided, a `<label>` element is rendered above the input. |
| With hint | When `hint` prop is provided, hint text is rendered below the input in a `<p>` element. |
| Multiline | Textarea element with `rows={4}` rendered instead of input element when `multiline` is `true`. |
| SecureTextField | Additional `'aws-field--secure'` class applied; input type is always `'password'`; autofill always prevented. |

## Accessibility

- **Role/Trait**: The component renders a native HTML `<input>` or `<textarea>` element, which have implicit `textbox` role. When a `<label>` is present, it is associated via `htmlFor` attribute matching the input's `id`.
- **Label requirements**: A `label` prop MAY be provided and is rendered as a `<label>` element associated to the input via `htmlFor`. No label is rendered if the `label` prop is omitted or falsy. The component's prop interface does not accept `aria-label`, `aria-labelledby`, or any other rest props, so there is no way to attach an accessible name to the input through this component when `label` is omitted.
- **Announce state changes**: The `disabled` state is communicated to assistive technologies via the `disabled` attribute on the input element; no additional ARIA attributes are set by the component.
- **Minimum tap target**: Target size is defined by CSS; the component does not enforce a minimum size. WCAG 2.1 Success Criterion 2.5.5 Target Size (Enhanced, Level AAA) recommends interactive targets be at least 44×44 CSS pixels; this spec follows the AAA recommendation (SC 2.5.5) rather than the AA minimum in SC 2.5.8 (24×24px). CSS styling SHOULD ensure this.
- **Hint association**: Hint text is rendered in a `<p>` element but is not explicitly associated to the input via `aria-describedby`; neither the input nor the hint paragraph exposes an id a caller could wire together, so this association cannot currently be added from outside the component (see **Design Decisions**).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| text-field-001 | render-input-element, bind-value, call-on-change | `<TextField value="hello" onChange={...} multiline={false} />` | Component renders an `<input>` element with `value="hello"`. |
| text-field-002 | call-on-change | Starting from `<TextField value="hello" onChange={...} />`, the user pastes "world" at the end of the input in a single paste action. | `onChange` is invoked once, with `"helloworld"` as the argument. |
| text-field-003 | render-label, generate-id | `<TextField label="Name" value="" onChange={...} />` | Component renders `<label htmlFor="[generated-id]">Name</label>` and `<input id="[generated-id]" />`. |
| text-field-004 | accept-placeholder | `<TextField placeholder="Enter text" value="" onChange={...} />` | Component renders `<input placeholder="Enter text" />`. |
| text-field-005 | respect-disabled | `<TextField value="" onChange={...} disabled={true} />` | Component renders `<input disabled />`. |
| text-field-006 | render-hint | `<TextField value="" onChange={...} hint="Helper text" />` | Component renders `<p>Helper text</p>` after the input. |
| text-field-007 | handle-multiline | `<TextField value="" onChange={...} multiline={true} />` | Component renders `<textarea rows={4} />` instead of `<input />`. |
| text-field-008 | support-text-types | `<TextField value="" onChange={...} type="email" />` | Component renders `<input type="email" />`. |
| text-field-009 | apply-autofill-token | `<TextField value="" onChange={...} autoComplete="email" />` | Component renders `<input autoComplete="email" />` with none of `data-form-type`, `data-1p-ignore`, `data-lpignore`, `data-bwignore`, `data-protonpass-ignore` present. |
| text-field-010 | prevent-autofill-default | `<TextField value="" onChange={...} />` (no `autoComplete`) | Component renders the input with `autoComplete="off"`, `data-form-type="other"`, `data-1p-ignore="true"`, `data-lpignore="true"`, `data-bwignore="true"`, `data-protonpass-ignore="true"`. |
| text-field-011 | always-prevent-password-manager | `<SecureTextField value="" onChange={...} />` | Component renders `<input type="password" />` with the same six autofill-prevention attributes as text-field-010, and no `autoComplete` prop exists to override them. |
| text-field-012 | apply-semantic-css-classes | `<TextField value="" onChange={...} />` | Root `<div>` has class list `aws-field aws-field--text`. |
| text-field-013 | apply-semantic-css-classes | `<TextField value="" onChange={...} />` | The `<input>` element has class `aws-field__input`. |
| text-field-014 | apply-semantic-css-classes | `<SecureTextField value="" onChange={...} />` | Root `<div>` has class list `aws-field aws-field--text aws-field--secure`. |
| text-field-015 | apply-semantic-css-classes | `<SecureTextField value="" onChange={...} />` | The `<input type="password">` element has class `aws-field__input`. |
| text-field-016 | apply-classname | `<TextField value="" onChange={...} className="custom" />` | Root element's class list is `aws-field aws-field--text custom`. |
| text-field-017 | generate-id | `<TextField id="custom-id" value="" onChange={...} />` | Component renders `<input id="custom-id" />`; `useId`'s generated value is not used. |
| text-field-018 | prevent-autofill-default | `<TextField value="" onChange={...} autoComplete="off" />` | Component treats `"off"` the same as an omitted `autoComplete`: the same six autofill-prevention attributes as text-field-010 are applied. |
| text-field-019 | mask-password-input | `<SecureTextField value="" onChange={...} />` | Component renders `<input type="password" />`. |
| text-field-020 | render-label, render-hint | `<TextField label="Name" value="" onChange={...} hint="Helper text" />` | DOM order is `<label>`, then `<input>`, then the hint `<p>` — the label precedes the input and the hint follows it. |

## Edge Cases

- **Empty string input**: When `value` is an empty string, the component MUST render the input element with an empty value and display any provided `placeholder` text.
- **Null or undefined label**: When `label` is `null`, `undefined`, or falsy, no `<label>` element is rendered.
- **Null or undefined hint**: When `hint` is `null`, `undefined`, or falsy, no hint `<p>` element is rendered.
- **Large text input**: When `value` contains many characters (e.g., >10,000), the component MUST display all of them without truncation; overflow behavior (scrolling, wrapping) is controlled by CSS.
- **Multiline with many rows**: When `multiline` is `true` and `value` contains many lines, the textarea MUST display all lines; it has a fixed `rows={4}` and SHOULD scroll vertically if content exceeds visible height (CSS-controlled).
- **Rapid onChange calls**: When the user types quickly, `onChange` callbacks MUST be invoked in sequence for each keystroke; no debouncing or throttling is performed by the component.
- **Disabled input interaction**: When `disabled` is `true`, user interactions (typing, focus) with the input MUST be blocked by the browser's native input element behavior.
- **AutoComplete and password fields**: SecureTextField MUST always prevent autofill to avoid password managers saving API keys or tokens as the site password; this behavior is not configurable.
- **ID collision with external labels**: When an external `<label>` exists with the same `htmlFor` as the generated or provided `id`, both labels will reference the same input; callers MUST avoid duplicate labels.

## Configuration

| Option | Type | Default | Applies To | Description |
|--------|------|---------|------------|-------------|
| `label` | `ReactNode` | `undefined` | Both | Optional label text or node displayed above the input. |
| `hint` | `ReactNode` | `undefined` | Both | Optional helper text or node displayed below the input in a `<p>` element; passing block-level content produces invalid HTML, so keep it to inline content. |
| `value` | `string` | (required) | Both | Current text value; controlled by caller. |
| `onChange` | `(value: string) => void` | (required) | Both | Callback invoked when input value changes. |
| `placeholder` | `string` | `undefined` | Both | Placeholder text shown when input is empty. |
| `multiline` | `boolean` | `false` | TextField (typed on `SecureTextFieldProps` too, but `SecureTextField`'s implementation never reads it and always renders a single-line masked `<input>`) | When `true`, renders a `<textarea>` instead of `<input>`. |
| `disabled` | `boolean` | `false` | Both | When `true`, input is disabled and user cannot interact with it. |
| `className` | `string` | `undefined` | Both | Optional CSS class name(s) to append to root element. |
| `id` | `string` | (auto-generated) | Both | Optional ID for the input element; generated via `useId()` if omitted. |
| `type` | `'text' \| 'email' \| 'url' \| 'tel'` | `'text'` | TextField only | Input type for single-line TextField. |
| `autoComplete` | `string` | `undefined` | TextField only | Autofill token (e.g., `'email'`, `'tel'`) to enable password manager integration; omit or use `'off'` to prevent autofill. `SecureTextField` accepts no equivalent prop — see **always-prevent-password-manager**. |

## Deep Linking

Not applicable: This is a foundational form component without its own deep link targets. Deep linking is handled by the page or view that embeds this component.

## Localization

Not applicable: The component renders user-provided `label` and `hint` content; localization of these strings is the caller's responsibility. The component itself contains no hard-coded user-facing strings.

## Accessibility Options

Not applicable: The component does not directly respond to platform accessibility display options (reduce motion, increase contrast, differentiate without color). These are handled by the CSS styling layer (`.aws-field__input` class) and the browser's native input element behavior.

## Feature Flags

Not applicable: The component does not check or respond to feature flags. Feature-flagging of this component, if needed, is handled by the caller.

## Analytics

Not applicable: The component does not emit analytics events. Callers are responsible for instrumenting user interactions (focus, blur, input) if analytics are needed.

## Privacy

Not applicable: TextField is a generic form input that does not collect, store, or transmit data on its own. Callers using this component for sensitive data (passwords, API keys, personal information) are responsible for secure handling, transmission, and storage per their privacy and security requirements.

## Logging

Not applicable: The component does not emit diagnostic logs. Logging of user input or field state, if needed, is the caller's responsibility.

## Platform Notes

- **Web (React)**: Implemented in TypeScript/React; exports `TextField` (text input with configurable type) and `SecureTextField` (password-masked input). Uses React's `useId` hook for ID generation, semantic HTML (native `<input>` and `<textarea>`), and CSS class-based styling. The six attributes applied by `noAutofillProps`/`noAutofillPropsFor` (`autoComplete: 'off'`, `data-form-type: 'other'`, `data-1p-ignore: 'true'`, `data-lpignore: 'true'`, `data-bwignore: 'true'`, `data-protonpass-ignore: 'true'`) are what stop 1Password, LastPass, Bitwarden, and Proton Pass from offering to save the field, since `autocomplete="off"` alone does not.
- **SwiftUI**: Start from `TextField` for `TextField` and `SecureField` for `SecureTextField`. The placeholder string is the first initializer argument (`TextField("placeholder", text: $value)`), not a `.placeholder()` modifier — that modifier does not exist. Apply `.disabled()` for the disabled state and an `onChange` closure (or `.onChange(of:)`) to observe edits; there is no equivalent to "CSS class names via modifiers," so match `.aws-field__input`'s appearance (radius, padding, colors) with `.textFieldStyle()`, `.padding()`, `.background()`, and `.cornerRadius()`. Use `@FocusState` to manage focus, analogous to `:focus`. Handle autofill via `.textContentType(_:)`: pass the matching type (`.emailAddress`, `.telephoneNumber`, `.URL`, `.name`) when a real token is supplied. For `SecureField`, never set a credential-implying content type (avoid `.password`) so password managers do not offer to save it as the site's password.
- **Compose (Android)**: Use `BasicTextField` or `OutlinedTextField` from Compose Material 3. Provide label and hint (`supportingText`), configure `KeyboardOptions` for input type, and bind edits via `onValueChange`. Apply the disabled state via the `enabled` parameter. Compose automatically manages Material 3 touch target sizes. Handle autofill via the `contentType` semantics property (`Modifier.semantics { contentType = ContentType.EmailAddress }`, etc.), not `keyboardOptions.keyboardType` — keyboard type only selects the IME layout and has no effect on autofill. To keep a masked field from being offered for password-manager save, avoid setting a credential `contentType` (`Password`/`NewPassword`) on it.
- **AppKit / UIKit**: Start from `NSTextField` (macOS) or `UITextField` (iOS); for multiline use `NSTextView` (AppKit) or `UITextView` (UIKit). Apply the disabled state via `isEnabled = false` on both `NSTextField` and `UITextField` — not `isEditable`/`isSelectable`, which only affect whether text can be edited while the control remains visually enabled. Bind value via target-action or Combine/KVO. For password masking, use `NSSecureTextField` (AppKit) or `UITextField.isSecureTextEntry = true` (UIKit). Set `textContentType` (`UITextContentType.emailAddress`, `.telephoneNumber`, `.URL`, `.name`) when a real autofill token is supplied; leave it unset for `SecureTextField`'s equivalent so password managers do not offer to save the value as the site's password.
- **WinUI 3**: Use `TextBox` for single-line and multi-line input (`AcceptsReturn="True"` with `TextWrapping="Wrap"` for multiline), and `PasswordBox` — not a configured `TextBox` — for `SecureTextField`, since `PasswordBox` is the control that masks input. Set `Header` for labels and `PlaceholderText` for placeholders. Bind `Text` (or `PasswordBox.Password`) via two-way binding. Implement the disabled state via `IsEnabled`. Use the `InputScope` enum (`Email`, `TelephoneNumber`, `Url`) to hint the software keyboard for a real autofill token. Style via `Style` resources (`<Style TargetType="TextBox">` / `<Style TargetType="PasswordBox">` setting `Padding`, `BorderBrush`, `BorderThickness`, `CornerRadius`), not CSS-equivalent inline properties. Keep `PasswordBox` a plain secret field — do not wire it into Credential Manager suggestion flows — so Windows does not offer to save it.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/TextField.tsx` | unverified |

## Design Decisions

**Decision**: TextField is a fully controlled component; the caller MUST manage the `value` state and invoke `onChange` to update it.
**Rationale**: This pattern requires more boilerplate but provides explicit control and integrates cleanly with form libraries and state management.
**Approved**: pending

**Decision**: When no `id` is provided, React's `useId` hook generates a unique ID for the label-input pair.
**Rationale**: `useId` is stable across a component's own renders and exists specifically to produce IDs that match between server and client during SSR hydration, so label association works without caller intervention.
**Approved**: pending

**Decision**: The component uses `noAutofillPropsFor(autoComplete)` to conditionally apply six autofill-prevention attributes (`autoComplete: 'off'`, `data-form-type: 'other'`, `data-1p-ignore: 'true'`, `data-lpignore: 'true'`, `data-bwignore: 'true'`, `data-protonpass-ignore: 'true'`). The helper trims and lowercases `autoComplete` and applies the six attributes whenever the result is `undefined` or `'off'`; any other value is treated as a real token and withholds all six.
**Rationale**: This preserves password manager integration when a real autofill token is passed, but prevents unwanted autofill in generic fields by default. There is no enumerated allowlist of tokens — any non-`'off'` value is honored, so the caller is responsible for passing a token the browser recognizes (`email`, `tel`, `url`, `name`, etc.).
**Approved**: pending

**Decision**: `SecureTextField` does not accept an `autoComplete` prop; `type="password"` and the full `noAutofillProps` set are always applied and are not configurable.
**Rationale**: Password managers should never save settings secrets (API keys, tokens) as the website's password; this is a security-first design decision.
**Approved**: pending

**Decision**: The component uses a boolean `multiline` prop rather than a separate `TextArea` component.
**Rationale**: This reduces component count and makes the two variants feel like a single configurable entity, though it does add a branching render path.
**Approved**: pending

**Decision**: When `multiline` is `true`, the textarea has a hardcoded `rows={4}`.
**Rationale**: This provides a reasonable default but may not suit all use cases; callers can override via CSS (setting the `height` property).
**Approved**: pending

**Decision**: The hint is rendered as a plain `<p>` element without explicit ARIA association (e.g., `aria-describedby`).
**Rationale**: The component owns both the input's `id` and the hint element, so this is a component-level gap rather than something a caller can complete externally — callers needing this association currently have no way to add it through this component's props.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | failed | Security |
| [adc.check.user-safety.abuse-prevention](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b5685271-fbb7-5160-aeb5-9884034fc2d4) | failed | User Safety |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | User Safety |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on: the source's native `<input>`/`<textarea>` semantics and keyboard operability (passed); the missing `aria-label`/`aria-labelledby` pass-through and unassociated hint (Accessibility rows marked partial); the CSS-controlled properties (contrast, dynamic type, touch target, RTL, text expansion) living outside this component's source (partial); the component performing no validation, sanitization, or rate limiting on typed input, per its own "Rapid onChange calls" edge case (Security and User Safety rows marked failed); the autofill-prevention default requiring an explicit opt-in token (User Safety `safe-defaults` passed); and all label/hint/placeholder text being caller-supplied with no strings hardcoded in the component (Internationalization rows marked passed); `TextField`/`SecureTextField` are pure presentation over props with no business logic of their own (separation-of-concerns passed), and `components.test.tsx` exercises `onChange`, the multiline-textarea branch, and the password-input rendering directly (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case, corrected the `useId` and autofill-token design-decision claims, cited WCAG SC 2.5.5 instead of the document alone, replaced the "Not applicable" Compliance section with a real check table, reformatted Design Decisions into Decision/Rationale/Approved triplets, fixed frontmatter dates, added related sibling-recipe links, corrected and split the CSS-class test vectors, fixed the `text-field-009` requirement citation and the single-onChange claim in `text-field-002`, added test vectors for explicit `id`, `autoComplete="off"`, `SecureTextField` masking alone, and label/hint ordering, narrowed `bind-value` to remove its overlap with `call-on-change`, documented `SecureTextField`'s accepted configuration, corrected the Appearance section with real stylesheet values, and fixed the SwiftUI/Compose/AppKit-UIKit/WinUI 3 platform notes including password-manager-save prevention for every platform. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
