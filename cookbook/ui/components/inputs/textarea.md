---
id: 1e323e69-44d2-4a15-a11e-22a68e8e6a8c
title: "Textarea"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Multi-line text input field with focus, disabled, and validation error states."
platforms:
  - typescript
  - web
tags:
  - form-input
  - text-entry
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Textarea

## Overview

Textarea is a wrapper around the native HTML `<textarea>` element that provides consistent styling and state management across the application. It renders a multi-line text input field with support for disabled state, focus indication, and validation error states. The component is themed using token utilities (`apt-*`) and is designed to match the sibling Input and Card components.

## Behavioral Requirements

- **textarea-root**: The component MUST render an HTML `<textarea>` element as its root node.
- **prop-forwarding**: The component MUST accept and forward all standard HTML textarea props (e.g., `value`, `onChange`, `placeholder`, `disabled`, `rows`, `cols`) to the underlying textarea element via spread props.
- **custom-classname**: The component MUST accept a `className` prop and merge it with the default styles, so both apply unless they conflict, in which case the custom class wins.
- **autocomplete-control**: The component MUST accept an `autoComplete` prop to control browser autocomplete behavior, and MUST forward it to the textarea element.
- **autofill-suppression**: The component MUST suppress password manager and autocomplete manager decoration based on the `autoComplete` value, even though textareas are never credentials.
- **fieldshell-base-styles**: The component MUST apply the shared field-shell base visual treatment (border, background, corner radius) also used by the Input component.
- **min-height**: The component MUST set a minimum height of 64px.
- **full-width**: The component MUST set width to 100% of its container.
- **padding**: The component MUST apply padding of 12px horizontally and 8px vertically.
- **font-size**: The component MUST use a 14px font size.
- **text-color**: The component MUST apply the `text-apt-text` token color to the textarea text.
- **color-transition**: The component MUST smoothly transition color changes during state transitions (focus, disabled, invalid).
- **outline-removal**: The component MUST remove the default browser focus outline, since the component provides its own focus indicator.
- **placeholder-styling**: The component MUST render placeholder text using the dimmed text token color (`apt-text-dim`).
- **focus-indicator**: The component MUST show a focus indicator when `focus-visible` state is active, consisting of a border change to `apt-gold` and a 2px ring with `apt-gold/25` opacity.
- **disabled-state**: The component MUST disable pointer events, show a not-allowed cursor, and reduce opacity to 50% when the `disabled` attribute is present.
- **invalid-state**: The component MUST change the border and ring color to `apt-red` with `apt-red/25` ring opacity when the `aria-invalid` attribute is set to `true`.
- **data-slot**: The component MUST set the `data-slot="textarea"` attribute on the root textarea element for testing and targeting purposes.

## Appearance

- **Corner radius**: Inherited from `fieldShellClass` (no explicit override in source).
- **Padding**: 8px vertical × 12px horizontal (py-2 px-3).
- **Font**: weight regular (default), size 14px (text-sm).
- **Background**: Inherited from `fieldShellClass` (no explicit override in source).
- **Foreground/Text**: `apt-text` token color.
- **Border**: Inherited from `fieldShellClass` with state-driven overrides (golden on focus, red on invalid).
- **Shadow**: Inherited from `fieldShellClass` (no explicit override in source).
- **Min/Max size**: Minimum height 64px; full width (100%); no maximum enforced.
- **Placeholder text**: Uses `apt-text-dim` token color for reduced visibility.

## States

| State | Appearance change |
|-------|------------------|
| Default | Text color `apt-text`, placeholder dimmed, standard border and background from `fieldShellClass` |
| Focused | Border and 2px ring change to `apt-gold`, ring opacity 25% |
| Disabled | Opacity reduced to 50%, cursor changed to not-allowed, pointer events disabled |
| Invalid (`aria-invalid="true"`) | Border and 2px ring change to `apt-red`, ring opacity 25% |
| Placeholder visible | Text color `apt-text-dim` |

## Accessibility

- **Role/trait**: Implicit `textbox` role (native HTML textarea).
- **Label requirements**: The component MUST be associated with a label via `<label htmlFor="id">`, `aria-label`, or `aria-labelledby`. Wrapping the field in a `<fieldset>` alone does not label it — the surrounding component or form context is responsible for providing one of these mechanisms.
- **Announce state changes**: The component uses `aria-invalid` to communicate validation errors; assistive technologies announce this state when set to `true`.
- **Minimum tap target**: The component MUST meet a minimum touch target height of 44×44pt; the default `min-h-16` (64px) minimum height satisfies this at every viewport width.
- **Keyboard navigation**: The component supports standard textarea keyboard behavior: Tab for focus, arrow keys for navigation, Enter for line breaks (no special intercept).
- **Focus indication**: The focus-visible state provides a visible focus indicator via a border and ring color change. Whether this meets WCAG 2.1 Level AA contrast and visibility standards depends on the underlying `apt-gold` token's contrast against the background (see Compliance) — this component does not define that contrast itself.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| textarea-001 | textarea-root | Render component | Root node is an HTML `<textarea>` element |
| textarea-002 | custom-classname | `className="custom-class"` | Custom class is applied alongside default styles |
| textarea-003 | prop-forwarding | `value="text" placeholder="Enter text"` | Props are forwarded to textarea element and text/placeholder appear |
| textarea-004 | min-height | Render component, measure DOM | Minimum height is 64px or equivalent |
| textarea-005 | full-width | Render in a fixed-width container | Textarea fills 100% of container width |
| textarea-006 | focus-indicator | Focus textarea via keyboard or click | Border and ring color change to golden; ring opacity visible |
| textarea-007 | disabled-state | `disabled={true}` | Pointer events are disabled, cursor is not-allowed, opacity is 50% |
| textarea-008 | invalid-state | `aria-invalid="true"` | Border and ring color change to red; ring opacity visible |
| textarea-009 | autofill-suppression | Render component with no `autoComplete` prop, inspect DOM attributes | Rendered attributes include `autocomplete="off"`, `data-form-type="other"`, `data-1p-ignore="true"`, `data-lpignore="true"`, `data-bwignore="true"`, `data-protonpass-ignore="true"` |
| textarea-010 | data-slot | Render component, query `[data-slot="textarea"]` | Element is found via attribute selector |
| textarea-011 | autofill-suppression | `autoComplete="off"` | Same six suppression attributes as textarea-009 are present |
| textarea-012 | autocomplete-control, autofill-suppression | `autoComplete="email"` | Rendered attribute is `autocomplete="email"`; none of the five vendor ignore attributes (`data-form-type`, `data-1p-ignore`, `data-lpignore`, `data-bwignore`, `data-protonpass-ignore`) are present |
| textarea-013 | padding | Render component, measure computed style | Padding is 12px horizontal, 8px vertical |
| textarea-014 | font-size | Render component, measure computed style | Font size is 14px |
| textarea-015 | text-color | Render component, measure computed style | Text color matches the `apt-text` token value |
| textarea-016 | placeholder-styling | Render with `placeholder="Enter text"` and no value | Placeholder text renders in the `apt-text-dim` token color |
| textarea-017 | outline-removal | Focus the textarea | No native browser outline is rendered; only the component's own border/ring focus indicator is visible |
| textarea-018 | color-transition | Toggle `disabled`, `aria-invalid`, or focus state | The border/ring color change is animated via a CSS transition, not an instant snap |
| textarea-019 | custom-classname | `className="w-1/2"` (conflicts with the default `w-full`) | Rendered class list contains a single width utility (`w-1/2`); `tailwind-merge` removes the conflicting default rather than both classes coexisting |

## Edge Cases

- **Empty textarea**: The component renders and accepts an empty string or undefined value without error. Placeholder text is visible when the field is empty.
- **Very long text input**: The component does not impose a maximum length via source code; form context is responsible for enforcing length limits via the `maxLength` prop if needed. Text will wrap within the textarea and scroll vertically if it exceeds the visible area.
- **Null value**: Passing `value={null}` triggers a React warning (`value` prop on `textarea` should not be `null`); use `""` to clear the field or `undefined` for an uncontrolled textarea instead. `value={undefined}` is accepted without warning, and the textarea remains empty or shows placeholder text.
- **Concurrent focus and disabled state**: A disabled `<textarea>` is not focusable at all — `disabled:pointer-events-none` blocks pointer interaction but is not what prevents focus. Attempting to focus a disabled textarea programmatically or via pointer has no effect, so the focus-visible styling never applies. This is standard HTML behavior.
- **Rapid state changes**: If `disabled`, `aria-invalid`, or `className` props change rapidly, the component applies changes synchronously; CSS transitions smooth color changes via `transition-colors`.
- **Custom className override**: If `className` includes a class that conflicts with a default (e.g., `w-1/2` conflicting with the default `w-full`), `cn()`'s `tailwind-merge` step detects the conflict and drops the default class, leaving only the custom one. Precedence comes from tailwind-merge's conflict resolution, not CSS specificity — both classes are single-class selectors of equal specificity. See test vector textarea-019.
- **`autoComplete="off"` with manager suppression**: When `autoComplete="off"` is passed, `noAutofillPropsFor("off")` returns the same suppression attributes as when `autoComplete` is left `undefined` (see **autofill-suppression**). Both the `autocomplete="off"` attribute and the vendor-specific ignore attributes are applied.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `className` | string | (empty) | Additional CSS classes merged with default styles |
| `autoComplete` | string | (undefined) | Controls browser autocomplete behavior; forwarded to textarea and used to suppress manager decoration |
| All standard textarea props | (various) | (native defaults) | `value`, `onChange`, `placeholder`, `disabled`, `rows`, `cols`, `maxLength`, `readonly`, `spellCheck`, `wrap`, etc. |

## Deep Linking

Not applicable: Textarea is a form input component and does not handle routing or deep linking directly. The containing form or page context manages navigation.

## Localization

Not applicable: Textarea does not render any product text. Placeholder text, labels, and validation messages are provided by the containing form context and MUST be localized there.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The source has no `motion-reduce:` variant, so `transition-colors` runs regardless of the `prefers-reduced-motion` preference — color transitions are not made instantaneous when the setting is enabled. |
| Increase Contrast | Implementations SHOULD ensure the chosen token colors (`apt-text`, `apt-gold`, `apt-red`) meet WCAG AA contrast ratios against the background. Token definitions are responsible for maintaining contrast, not this component. |
| Differentiate Without Color | The focus indicator differentiates via both color (golden border/ring) and a visible ring shape, satisfying the requirement for focus. The invalid state (red border/ring) relies on color alone in this source; callers SHOULD pair `aria-invalid` with associated error text (e.g. via `aria-describedby`) to give it a non-color cue too. |

## Feature Flags

Not applicable: Textarea does not implement feature flags. The component is always enabled; enable/disable behavior is controlled by the `disabled` prop at the form or application level.

## Analytics

Not applicable: Textarea does not emit analytics events. Change and interaction tracking is the responsibility of the containing form context.

## Privacy

Not applicable: Textarea is a stateless wrapper around the native HTML element. It does not collect, store, or transmit data. Privacy and data handling are the responsibility of the form context and backend.

## Logging

Not applicable: Textarea does not emit structured logs. Debugging textarea state (focus, value, errors) is handled by the browser's built-in developer tools and the containing form's logging strategy.

## Platform Notes

- **React/Web**: This ingredient is implemented directly in web React. Source: `packages/web/packages/ui/src/components/textarea.tsx`. The component uses Tailwind utility classes (`min-h-16 w-full px-3 py-2 text-sm transition-colors outline-none`, plus `focus-visible:`, `disabled:`, and `aria-invalid:` state variants) merged via the `cn` (`clsx` + `tailwind-merge`) utility, and inherits `fieldShellClass` from the Input component for shared base styling. The `noAutofillPropsFor` helper (`packages/web/packages/ui/src/lib/autofill.ts`) returns the suppression attribute set when `autoComplete` is `undefined` or `"off"`, and an empty object for any other value.
- **SwiftUI**: Implement using `TextEditor` as the foundation. TextEditor provides multi-line text editing; wrap it in a container that applies border and ring styling for focus and error states. Disable interaction using `.disabled()` modifier when disabled. For the invalid state, use `.accessibilityValue(Text("Invalid entry"))` or an accessibility hint describing the error, rather than a nonexistent `AccessibilityElement` API. Use `lineLimit(nil)` for unrestricted vertical growth; use `.frame(minHeight: 64)` for the minimum height.
- **Compose (Android)**: Implement using `OutlinedTextField` with `singleLine = false` to enable multi-line mode. Apply Material Design 3 token colors (equivalent to `apt-text`, `apt-gold`, `apt-red`) for text, focus, and error states. `OutlinedTextField` is already focusable by default, so `Modifier.focusable()` is unnecessary; use `FocusRequester` only if programmatic focus is required. Render the invalid state via the `isError` parameter together with `Modifier.semantics { error("Invalid entry") }` so assistive technology announces it. Minimum height should be ~64dp; use `Modifier.heightIn(min = 64.dp)`.
- **UIKit / AppKit**: On iOS, use `UITextView` with a custom border/background view and delegate-based focus handling. Apply a border color change on `UITextViewDelegate.textViewDidBeginEditing`. For disabled state, set `isEditable = false` and apply opacity. Minimum height ~64pt. On macOS, use `NSTextView` in an `NSScrollView` with similar styling and state management; NSTextView does not have a native `disabled` state, so handle it via `isEditable` and visual feedback.
- **WinUI 3**: Implement using `TextBox` with `AcceptsReturn="True"` and `TextWrapping="Wrap"` to enable multi-line editing. Apply token-based colors to `Foreground`, `Background`, and `BorderBrush` properties. Use `VisualState` groups to define appearance for Normal, Focused, Disabled, and Error states. Set `MinHeight` to ~64 (device-independent pixels) and `Width` to "Auto" or a container-fill constraint. WinUI has no `aria-invalid` attribute; announce the error state via `AutomationProperties` (e.g. `AutomationProperties.Notification` or `HelpText`) together with an error `VisualState` that changes `BorderBrush`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/textarea.tsx` | unverified |

## Design Decisions

**Decision**: The component inherits its base visual treatment from `fieldShellClass`, the same base used by the Input component.
**Rationale**: This keeps visual consistency across form fields and centralizes updates to the shared style layer in one place.
**Approved**: pending

**Decision**: The component accepts an `autoComplete` prop and combines it with `noAutofillPropsFor(autoComplete)` to prevent password-manager and autocomplete-manager decoration, without removing the ability to opt back in.
**Rationale**: Textareas are never credentials, but managers still decorate them when the surrounding page reads like a form. `noAutofillPropsFor` returns the full suppression attribute set (`autocomplete="off"` plus the vendor-specific ignore attributes) when `autoComplete` is `undefined` or `"off"` (trimmed and compared case-insensitively), and returns no suppression attributes at all when `autoComplete` is set to any other value — a real autofill token such as `"email"` or `"current-password"` — handing the field back to managers so a form that genuinely wants autofill can opt back in by naming a token.
**Approved**: pending

**Decision**: The component applies `transition-colors` to smooth color changes during state transitions (focus, disabled, invalid).
**Rationale**: This improves perceived responsiveness without requiring JavaScript or animation libraries. The source defines no `motion-reduce:` variant, so this transition does not respect the `prefers-reduced-motion` preference (see Accessibility Options and Compliance).
**Approved**: pending

**Decision**: The component uses the native `aria-invalid` attribute to communicate validation errors.
**Rationale**: This approach is semantic, testable, and accessible; it does not invent a custom error state property.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: it renders a native `<textarea>` with `data-slot`, `aria-invalid`-driven state styling, and a fixed 64px minimum height regardless of viewport (semantic-markup, keyboard-navigable, and touch-target-size passed), and it forwards all user-facing text via props with nothing hardcoded (no-hardcoded-strings passed); but it defers label association to the caller and defines no explicit contrast values or `motion-reduce:` variant (screen-reader-support and contrast-ratio partial, reduced-motion failed); the component is a themed pass-through of native `<textarea>` props with no logic beyond the autofill opt-out (separation-of-concerns passed), and `autofill.test.tsx` renders `Textarea` directly and asserts on its autocomplete-opt-out attributes (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; corrected the reduced-motion, disabled-focus, className-specificity, and WCAG-AA claims; gave the invalid state a non-color-cue recommendation; moved Tailwind/JS implementation details out of requirement text and into Platform Notes; reformatted Design Decisions and specified the autoComplete undefined/off/token tri-state behavior; replaced the Compliance section with a checks table; added test vectors for autoComplete forwarding and suppression, padding, font size, text color, placeholder, outline removal, transitions, and className dedup; corrected the null-value edge case and an unbalanced-backtick label; fixed the label and tap-target accessibility guidance; corrected the SwiftUI, Compose, and WinUI 3 platform-note APIs; fixed "This ingredient" terminology; unquoted `modified` |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
