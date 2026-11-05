---
id: 0f5b7167-b375-4f44-977b-566f720a453d
title: Input
domain: adhsdk://recipes/input
type: ingredient
version: 1.2.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Single-line text input field with theme support, autofill handling, and validation
  state display.
platforms:
- typescript
- web
tags:
- form-control
- input
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Input

## Overview

A single-line text input field component that serves as the basic text capture element in forms. It supports multiple input types (text, email, password, etc.), themed colors via Material Design 3 tokens, focus and validation states, and accessibility features including aria-invalid support. The component enforces consistent styling across all text-based input fields in the application.

## Behavioral Requirements

- **input-type**: Component MUST support specifying the input type (text, email, password, number, etc.) so the underlying platform control applies the type-appropriate keyboard, masking, and validation behavior.
- **placeholder**: Component MUST display placeholder text when the field is empty, styled as visually de-emphasized (dimmed) text distinct from entered content.
- **autofill-token**: Component MUST accept an autofill-token prop (HTML `autocomplete`) and, when no valid token is provided (absent, explicitly `undefined`, or `"off"`), apply the following opt-out attributes so no supported password manager offers to fill or save the field: `autocomplete="off"`, `data-form-type="other"` (Dashlane), `data-1p-ignore` (1Password), `data-lpignore` (LastPass), `data-bwignore` (Bitwarden), `data-protonpass-ignore` (Proton Pass). When a real token is provided, none of these opt-out attributes are applied and the token passes through unchanged.
- **selection-styling**: Component MUST style user-selected/highlighted text with a tinted background distinct from the field's own background.
- **dom-prop-forwarding**: Component MUST accept and forward all standard native text-input props (value, onChange, onBlur, etc.) to the underlying platform control.
- **field-shell-styling**: Component MUST apply the same base field shell styling (rounded corners, border, background) used by sibling field controls, so all field-shaped controls stay visually consistent.
- **width-constraint**: Component MUST fill its container's available width without overflowing a flex or grid layout when its content is long.
- **classname-merging**: Component MUST accept caller-supplied style overrides and merge them with the component's internal styling, with the caller's styling taking precedence.

## Appearance

- **Corner radius**: 8px (lg), defined by `rounded-lg` class on fieldShellClass
- **Padding**: 8px vertical × 12px horizontal (py-2 px-3), adjusted for 36px total height with text-sm
- **Font**: 400 weight, 14px size, inherits family from page defaults (text-sm)
- **Background**: `apt-bg` token (light/dark adapted via theme)
- **Foreground/Text**: `apt-text` token (light/dark adapted via theme)
- **Border**: 1px solid `apt-border` token (light/dark adapted via theme)
- **Shadow**: None
- **Min/Max size**: Minimum height 36px (h-9); width constrained by container (w-full, min-w-0)

## States

| State | Appearance change |
|-------|------------------|
| Default | Border: `apt-border`, background: `apt-bg`, text: `apt-text` |
| Focus (focus-visible) | Border: `apt-gold`; 2px `apt-gold/25` outer ring around the field for depth |
| Disabled | Opacity reduced to 50%, cursor becomes "not-allowed", pointer events disabled |
| Invalid (aria-invalid) | Border: `apt-red`; 2px `apt-red/25` outer ring around the field |
| Placeholder (text absent) | Text color: `apt-text-dim` for reduced visual weight |

## Accessibility

- **Role/trait**: HTML input element with role="textbox" (implicit); supports type attribute for specialized roles (search, password)
- **Label requirements**: MUST be associated with an external `<label>` element using matching `id` and `for` attributes; the component itself does not provide a label
- **Announce state changes**: Component supports `aria-invalid="true"` attribute to signal validation errors to screen readers; invalid state MUST be applied at the form/page level alongside visual indicator
- **Announce disabled state**: Native HTML disabled attribute automatically communicated by assistive technology
- **Minimum tap target**: 36px height (h-9) meets the WCAG 2.5.8 minimum of 24px; it does not meet Android's 48dp or iOS's 44pt native minimums, so native ports MUST size the control to their own platform's minimum tap target
- **Keyboard support**: Native HTML input keyboard navigation; focus indicator visible via `focus-visible:ring` and border color change

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| input-001 | input-type | `type="email"` | HTML input element has type="email" attribute |
| input-002 | input-type | `type="password"` | HTML input element has type="password" attribute |
| input-003 | placeholder | `placeholder="Enter name"` | Placeholder text visible when field empty, styled with `text-apt-text-dim` |
| input-004 | autofill-token | `autoComplete="email"` | Autofill token applied; password managers can detect field |
| input-005 | autofill-token | `autoComplete={undefined}` | Off-attribute set applied (`autocomplete="off"`, `data-form-type="other"`, `data-1p-ignore`, `data-lpignore`, `data-bwignore`, `data-protonpass-ignore`); password managers blocked |
| input-006 | selection-styling | Text highlighted by user | Selected text background: `apt-gold/30` (30% opaque gold) |
| input-007 | dom-prop-forwarding | `value="test"` onChange={handleChange} | value prop passed through; onChange callback fires on input |
| input-008 | field-shell-styling | Rendered on page | Field has rounded corners (8px), 1px border, and `apt-bg` background |
| input-009 | width-constraint | Within 200px container | Field width matches container (100%), does not overflow |
| input-010 | classname-merging | `className="custom-class"` | Both default classes and custom-class applied to element |
| input-011 | #states/focus | User tabs to field or clicks | Border color changes to `apt-gold`; 2px `apt-gold/25` outer ring visible around the field |
| input-012 | #states/disabled | `disabled={true}` | Opacity 50%, cursor not-allowed, no pointer events |
| input-013 | #states/invalid | `aria-invalid="true"` | Border color: `apt-red`; 2px `apt-red/25` outer ring visible around the field |

## Edge Cases

- **Empty or null input value**: Component renders with empty field; placeholder text visible if provided; no error state unless `aria-invalid="true"` is set externally
- **Very long input text**: Component uses `min-w-0` to prevent flex/grid overflow; text scrolls horizontally within field rather than pushing container
- **Autofill with undefined token**: `autoComplete={undefined}` is destructured and not spread, then `noAutofillPropsFor(undefined)` returns the off-attribute set to prevent password manager intrusion; this is the correct behavior for fields that should not autofill
- **Autofill with explicit token (e.g., "email")**: Helper returns nothing to overwrite; explicit token written before spread wins; password managers can detect and populate
- **Disabled state combined with other states**: Disabled MUST override all other interactive states; focus ring and hover are not visible when disabled
- **Disabled state with aria-invalid**: Both classes applied; visual indicators show both states; disabled state takes precedence in user interaction

## Configuration

Not applicable: Input component does not expose configuration options. Its appearance and behavior are determined entirely by HTML attributes (type, autoComplete, disabled, value, etc.) and CSS classes applied by the component implementation.

## Deep Linking

Not applicable: Input component has no independent deep-link target; navigation to a field, if any, is the responsibility of the page or form that contains it.

## Localization

Not applicable: Input component does not emit localizable text. Placeholder text, labels, and validation messages are provided by the parent form and are the responsibility of the consuming application to localize.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Component applies `transition-colors` to the field, animating border/ring color changes on focus and validation-state changes; this transition is not gated by `prefers-reduced-motion` (no `motion-reduce:transition-none` is applied in source) |
| Increase Contrast | Inherits higher-contrast token values through M3 theme tokens (`apt-border`, `apt-gold`, `apt-red`); no additional component logic needed |
| Differentiate Without Color | Default vs. an active state (focus or invalid) is distinguished by the presence of the border/ring itself, not color alone; focus and invalid are distinguished from each other by hue (gold vs. red) only — `aria-invalid` carries the corresponding signal to assistive technology, which does not depend on color |

## Feature Flags

Not applicable: Input component does not have feature flag logic. Feature flagging of form submissions or validation behavior belongs at the form level, not at the individual field component.

## Analytics

Not applicable: Input component does not emit analytics events. Event tracking for user input, form submission, and validation errors is the responsibility of the consuming form component.

## Privacy

Not applicable: Input component does not collect, store, or transmit data. It is a presentational form control. Data handling, encryption, and transmission are the responsibility of the consuming application and form handler.

## Logging

Not applicable: Input component does not perform logging. Debug logging for input values, state changes, or autofill behavior is the responsibility of the consuming application and form component.

## Platform Notes

- **React/Web**: The component is implemented as a functional component using React hooks. It uses Tailwind CSS for styling, M3 token utilities for theming (via `apt-*` classes mapped to CSS variables injected by `<AdhThemeStyle/>`), and the `cn()` utility (from `lib/utils`: `clsx` composes the class list and `tailwind-merge` resolves conflicting Tailwind utility classes) for class merging. It destructures `className`, `type`, and `autoComplete` out of the forwarded props, applies the shared `fieldShellClass` constant (`rounded-lg border border-apt-border bg-apt-bg`) plus a fixed list of Tailwind utility classes (`flex h-9 w-full min-w-0 px-3 py-2 text-sm text-apt-text transition-colors outline-none`, `placeholder:text-apt-text-dim`, `selection:bg-apt-gold/30`, `focus-visible:border-apt-gold focus-visible:ring-2 focus-visible:ring-apt-gold/25`, `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50`, `aria-invalid:border-apt-red aria-invalid:ring-2 aria-invalid:ring-apt-red/25`), and merges any caller `className` last through `cn()` so caller styling wins. The `noAutofillPropsFor()` helper enforces autofill rules by applying browser/password-manager autofill prevention attributes when no explicit autofill token is provided. Source: `packages/web/packages/ui/src/components/input.tsx`.
- **SwiftUI**: Start from SwiftUI's native `TextField` or `SecureField` (for password input). Apply the M3-mapped border color with an overlay of a stroked `RoundedRectangle` (`.border()` cannot draw rounded corners), and set text and background colors with `.foregroundStyle` and `.background` calling the project's design-token accessor (SwiftUI has no built-in `Color(token:)` initializer). Drive the gold border/ring from `.focused($isFocused)` and the red border/ring from an `isInvalid` flag; both use the same ring treatment and differ only by color, so also carry a corresponding accessibility trait or error text for users who cannot distinguish focus from invalid by hue alone. For autofill, iOS handles password/credential autofill natively via `textContentType`; when no real token applies, set `textContentType(nil)` (or `.none`) to opt the field out, matching the web's off-attribute behavior.
- **Compose (Android)**: Start from Material Design 3 `OutlinedTextField` or `BasicTextField`. Apply M3 theme colors for container, border, text, and placeholder, driving the focus/invalid border+ring from `isFocused`/`isError` state (again, the same ring shape differing only by color — pair it with a non-color signal for invalid). For autofill, use `Modifier.semantics { contentType = ContentType.Password }` (or the appropriate `ContentType`) when a real token applies — `Modifier.autofill()`/`AutofillType` is the older, superseded Compose autofill API; when no token applies, omit `contentType` or set `importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_NO` to opt the field out, matching the web's off-attribute behavior.
- **AppKit / UIKit**: For macOS (AppKit), use `NSTextField` with custom cell styling to apply M3 token colors and rounded borders, swapping border color for focus (`becomeFirstResponder`) and invalid states. For iOS (UIKit), use `UITextField` with `UITextFieldDelegate` (`textFieldDidBeginEditing`/`textFieldDidEndEditing`) and a custom `UIView` subclass for border/background styling to match M3 tokens, driving the same focus/invalid border+ring styling. iOS/macOS handle password autofill natively via `textContentType`; when no real token applies, set `textContentType = nil` to opt the field out, matching the web's off-attribute behavior.
- **WinUI 3**: Start from `TextBox` in the `Microsoft.UI.Xaml.Controls` namespace. Apply M3 token colors via `Foreground`, `Background`, and `BorderBrush`. Drive the focus border/ring from the control's built-in focused visual state (or by overriding the `TextControlBorderBrushFocused` resource), not `PointerEntered` (a hover event, not a focus event), and drive the invalid state the same way through a bound `BorderBrush`/error resource. Use `AutomationProperties.Name` for accessibility labeling. For disabled state, set `IsEnabled="false"`. WinUI has no direct autofill-prevention equivalent to the web's opt-out attributes; approximate the "no token blocks autofill" requirement with `IsSpellCheckEnabled="False"` and an explicit `InputScope` to discourage OS input suggestions. Corner radius is 8 effective pixels (`CornerRadius="8"`) to match web.

## Design Decisions

**Decision**: Destructure `autoComplete` out of the forwarded props before spreading the remaining props onto the input.
**Rationale**: The component sets `autoComplete` explicitly — either the caller's token or the value `noAutofillPropsFor()` computes — before the trailing `{...props}` spread. If `autoComplete` were left inside `props`, that trailing spread would re-apply whatever value the caller passed and silently erase the computed value. Destructuring removes it from the tail spread entirely, so the earlier, correctly computed value always wins; this holds identically whether the caller omitted `autoComplete` or passed it explicitly as `undefined`, since both reach the same code path with the same result once destructured.
**Approved**: pending

**Decision**: Share a single `fieldShellClass` constant for the field-shape styling (border, rounded corners, background) across sibling field controls (Textarea, Select, and other field-shaped controls such as choosers, chip boxes, and segmented toggles).
**Rationale**: Centralizing the shell class means a single edit updates the shell appearance everywhere it is used, keeping every field-shaped control visually consistent without each one re-declaring the same classes.
**Approved**: pending

**Decision**: Theme all color values through `apt-*` Tailwind utility classes mapped to Material Design 3 role variables injected by `<AdhThemeStyle/>`.
**Rationale**: This allows light/dark theme adaptation and token updates without changing component code, and aligns with the Material Design 3 system's color-role-based approach.
**Approved**: pending

**Decision**: Apply `min-w-0` to override the default `min-width: auto` flex/grid item behavior.
**Rationale**: Without it, long text or wide content would push the container wider than intended in flex/grid layouts; this is a necessary constraint for predictable layout in complex forms.
**Approved**: pending

**Decision**: Use a dual visual indicator (border color change plus an outer ring) for both the focus-visible and invalid states.
**Rationale**: The ring adds visual depth and makes the state change visible even where a border-color change alone would be subtle. It does not, by itself, distinguish focus from invalid for a user who cannot perceive the gold/red hue difference — that distinction is currently carried by color (hue) alone, with `aria-invalid` providing the corresponding non-visual signal to assistive technology.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`keyboard-navigable` passes because the source renders a native HTML `<input>`, which is keyboard-operable by default with no custom key handling to verify. `screen-reader-support`, `contrast-ratio`, and `touch-target-size` are `partial`: the source itself provides no accessible name (an external `<label>` is required), its M3 color tokens are resolved outside this file so contrast can't be confirmed here, and its fixed 36px height meets the WCAG 2.5.8 minimum but not Android's or iOS's native minimums. `separation-of-concerns` passes because the component is a thin themed wrapper over the native `<input>` with no business logic beyond the `autoComplete`-precedence guard; `unit-test-coverage` passes on `autofill.test.tsx`'s direct exercise of that autofill opt-out/token behavior against `Input`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rewrote Behavioral Requirements as platform-neutral behavior and moved implementation detail (spread operator, `cn()`, `fieldShellClass`, Tailwind classes) into the React/Web note; renamed requirements to subject-only kebab-case and updated all citations, including the Conformance Test Vectors' state rows; listed the exact autofill opt-out attributes; corrected the `cn()` attribution (`clsx` + `tailwind-merge`) and cut the unsupported Deep Linking claim; corrected the tap-target minimum, the focus/invalid "inner shadow" (actually an outer ring), and the color-only Differentiate-Without-Color claim; corrected Design Decisions 1 and 2 against source and reformatted all five to Decision/Rationale/Approved; clarified the Reduce Motion transition; corrected the WinUI, SwiftUI, and Compose Platform Notes and added invalid-state and no-token-autofill parity across all native platforms; replaced Compliance's blanket "Not applicable" with a table of applicable checks |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Remove review marker from Compliance section; replace with concrete "Not applicable" statement |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
