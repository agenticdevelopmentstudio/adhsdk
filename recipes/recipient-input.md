---
id: d9ad192e-a642-46a2-8b25-b8aac9d9f441
title: RecipientInput
domain: adhsdk://recipes/recipient-input
type: ingredient
version: 1.3.1
status: review
language: en
created: 2026-06-26
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A token input that collects recipients (email/phone/text) into removable chips with optional separate rendering modes and read-only display."
platforms:
  - typescript
  - web
tags:
  - input
  - chips
  - tokens
  - recipients
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# RecipientInput

## Overview

RecipientInput is a controlled token input component in `@adh-sdk/ui` that collects recipients via a text field and displays them as removable chips. It supports three input kinds (email, phone, text) with corresponding light validation, and offers two layout modes: fused (default, single container) and separate (two-part layout with stacked chips and input).

## Behavioral Requirements

Unless a requirement says otherwise, every rule about "the inline input" applies equally to the separate mode's `Input` element below the recipients box — both layout modes share the same tokenize, validate, and `inputMode` logic.

- **tokenize-on-enter**: The component MUST add a new chip when the user presses Enter in the inline input, trimming whitespace and ignoring empty entries.
- **tokenize-on-comma**: The component MUST add a new chip when the user types a comma in the inline input, splitting comma-separated input into multiple chips and trimming each.
- **paste-batch-tokenization**: The component MUST apply the same comma-splitting tokenization to text inserted by paste (or any other input method) as it does to a typed comma, de-duplicating entries within the pasted batch before adding them.
- **tokenize-on-blur**: The component MUST add a new chip when focus leaves the inline input (onBlur), trimming whitespace and ignoring empty entries.
- **dedup-case-insensitive-email**: When `kind="email"`, the component MUST reject duplicate entries case-insensitively; entries `Ada@x.io` and `ada@x.io` are treated as the same recipient.
- **dedup-exact-non-email**: When `kind` is not `"email"`, the component MUST reject duplicate entries using exact string comparison.
- **validate-email**: When `kind="email"`, the component MUST validate each chip against the pattern `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`; invalid chips MUST still be added but MUST render with an error appearance and `aria-invalid="true"`.
- **validate-phone**: When `kind="phone"`, the component MUST validate each chip against the pattern `/^[+]?[\d\s().-]{7,}$/`; invalid chips MUST still be added but MUST render with an error appearance and `aria-invalid="true"`. See **phone-validation-looseness** in Edge Cases: this pattern accepts punctuation/whitespace-only strings with no digits.
- **text-kind-validation**: When `kind="text"`, the component MUST NOT apply validation; all entries are accepted.
- **chip-removal-via-dismiss**: The component MUST remove a chip from the value array when its remove affordance (×) is activated. Removal filters the value array by value equality — see **duplicate-chip-removal** in Edge Cases for the effect when the array holds duplicate values.
- **backspace-removal-fused-mode**: In default (fused) mode, the component MUST remove the last chip when Backspace is pressed with an empty inline input and chips present.
- **backspace-removal-separate-mode**: In separate input mode, the component MUST NOT remove chips via Backspace when the inline input is empty.
- **input-mode-email**: When `kind="email"`, the component MUST set the inline input's `inputMode="email"`.
- **input-mode-phone**: When `kind="phone"`, the component MUST set the inline input's `inputMode="tel"`.
- **input-mode-text**: When `kind="text"`, the component MUST set the inline input's `inputMode="text"`.
- **separate-mode-layout**: When `separateInput=true`, the component MUST render in two distinct parts: a recipients box showing existing chips, and a separate text input below for adding new recipients. Chips in the recipients box remain removable `RemovableChip` elements exactly as in fused mode unless `readOnly` is also set — see Appearance.
- **readonly-mode-display**: When `readOnly=true`, the component MUST NOT render an input field; existing recipients MUST display as static, non-removable chips (Badge elements).
- **disabled-interaction**: When `disabled=true`, the component MUST render in a disabled state (reduced opacity, pointer-events-none) and MUST NOT respond to user input or trigger `onChange`. See **disabled-keyboard-removal** in Edge Cases for a caveat about keyboard-activated remove buttons.

## Appearance

**Default (Fused) Mode:**
- Container: the shared field-shell token (border + field-surface background + corner radius), with a row-wrapping layout; chips and the inline input are co-located in one container.
- Chips: the neutral-chip token for valid entries, the error-chip token for invalid entries, each wrapped in a removable-chip affordance with a trailing × control.
- Inline input: borderless, transparent background, primary-text color; placeholder text (placeholder-text token) shown only when the chip list is empty.

**Separate Input Mode:**
- Recipients box: the same field-shell token as the fused container, with a minimum height so it doesn't collapse when empty, wrapping chips. Chips here are the same removable `RemovableChip` elements as fused mode — the remove affordance works identically — unless `readOnly` is also set, in which case they become static Badges exactly as in Read-Only Mode. Placeholder text ("No recipients yet") shown when empty.
- Input element: rendered separately below the recipients box, using the shared Input primitive at tighter vertical metrics than its default. Omitted entirely when `readOnly=true`.

**Read-Only Mode:**
- No input field is rendered.
- Recipients display with the same neutral-chip / error-chip tokens as the editable modes, without a remove affordance.

**Focus and Disabled:**
- Default mode: the container itself carries the focus-accent token when any descendant is focused.
- Separate mode: focus-accent is carried by the Input primitive's own focus styling, not the recipients box.
- Disabled: the disabled token (reduced opacity, non-interactive) applies to the whole component.

## States

| State | Appearance (semantic) | Mode | Notes |
|-------|-----------------------|------|-------|
| Default | field-shell border, no ring | Both | Container in fused mode or recipients box in separate mode |
| Focus-within | focus-accent border + ring | Fused | Applied when any descendant element receives focus |
| Focused (input) | Input primitive's own focus-accent | Separate | Delegated entirely to the separate Input element |
| Disabled | disabled token (reduced opacity, non-interactive) | Both | Applies to the whole component, chips and input alike |
| Chip (valid) | neutral-chip token | Both | No validation error |
| Chip (invalid) | error-chip token + `aria-invalid` | Both | Validation failed; still added to the value array |
| Empty recipients | placeholder-text ("No recipients yet") | Separate | Fused mode shows its placeholder inside the input instead of a standalone message |

## Accessibility

- Container: `role="group"` with `aria-label` from the `ariaLabel` prop.
- Inline input: `aria-label={`Add to ${ariaLabel}`}` to label the entry field; the same label is applied to the separate mode's `Input`.
- Invalid chips: carry `aria-invalid="true"`.
- Removable chips: each remove control is a real `<button>` with accessible name `Remove ${value}` — for example, a chip holding `ada@x.io` gets a remove button labeled exactly "Remove ada@x.io".
- Tab order: chips render before the input in DOM order, so keyboard focus visits each chip's remove button in `value` array order, then the inline input (fused mode) or the separate `Input` below the recipients box (separate mode). No explicit `tabindex` is set; order follows render order.
- No live-region announcement: the component does not announce chip addition, rejection, or removal to assistive technology. A newly added invalid chip is discoverable via its own `aria-invalid` attribute once focus or a screen reader's browse cursor reaches it, but there is no `aria-live` region confirming the add, reject, or remove action as it happens.
- Differentiate Without Color: see Accessibility Options.
- Input type hints: `inputMode` reflects the `kind` prop to guide mobile keyboards, in both fused and separate modes.

## Conformance Test Vectors

| ID | Requirement | Input | Expected |
|----|-------------|-------|----------|
| T1 | tokenize-on-enter | Type `ada@x.io` and press Enter in fused mode | Neutral chip `ada@x.io` added to value; input clears |
| T2 | tokenize-on-comma | Type `ada@x.io, grace@x.io` and a comma is typed | Two chips added; input clears |
| T3 | paste-batch-tokenization | Paste `a@x.io, A@x.io` into the inline input with `kind="email"` | One chip `a@x.io` added; the pasted duplicate (`A@x.io`, same email case-insensitively) is dropped before being added; input clears |
| T4 | tokenize-on-blur | Type `  ada@x.io  ` and blur the input | Trimmed chip `ada@x.io` added; input clears |
| T5 | dedup-case-insensitive-email | `kind="email"`: add `Ada@x.io` then attempt to add `ada@x.io` | Second entry rejected; one chip remains; input still clears (see Edge Cases) |
| T6 | dedup-exact-non-email | `kind="text"`: add `Ada` then attempt to add `ada` | Both chips added (exact match required) |
| T7 | validate-email | `kind="email"`: add `bad@` | Chip rendered with error appearance + `aria-invalid="true"` but still in value |
| T8 | validate-email | `kind="email"`: add `ada@x.io` | Chip rendered with neutral appearance; no `aria-invalid` |
| T9 | validate-phone | `kind="phone"`: add `12345` (too short) | Chip rendered with error appearance + `aria-invalid="true"` but still in value |
| T10 | validate-phone | `kind="phone"`: add `+1 (555) 123-4567` | Valid; chip rendered neutral |
| T11 | text-kind-validation | `kind="text"`: add `@#$%^` | No validation error; chip neutral |
| T12 | chip-removal-via-dismiss | Fused mode with chips present; click × on a chip | That chip removed from value |
| T13 | chip-removal-via-dismiss | Tab to a chip's remove button and press Enter (or Space) | Same removal as a click; the button is reachable and activatable by keyboard |
| T14 | chip-removal-via-dismiss | `value=["ada@x.io","ada@x.io"]` seeded directly by the parent, `kind="email"`; click × on either chip | Both chips are removed — value becomes `[]` (removal filters by value, not index) |
| T15 | backspace-removal-fused-mode | Fused mode with chips and empty input; press Backspace | Last chip removed |
| T16 | backspace-removal-separate-mode | Separate mode with chips and empty input; press Backspace | Input text behavior only; no chip removed |
| T17 | input-mode-email | `kind="email"` | Inline input has `inputMode="email"` |
| T18 | input-mode-phone | `kind="phone"` | Inline input has `inputMode="tel"` |
| T19 | input-mode-text | `kind="text"` (or unspecified) | Inline input has `inputMode="text"` |
| T20 | separate-mode-layout | `separateInput=true` | Component renders a recipients box and a separate input below it |
| T21 | readonly-mode-display | `readOnly=true` with existing recipients | Recipients display as static Badge chips; no input field shown; no remove control on any chip |
| T22 | readonly-mode-display | `readOnly=true`; attempt any interaction (no input or remove control exists to interact with) | `onChange` is never called |
| T23 | disabled-interaction | `disabled=true`; click a chip's remove control or type in the input | Component appears grayed out; pointer interaction and typing are inert; `onChange` is not called |

## Edge Cases

- **Empty or whitespace-only input on tokenization**: An entry consisting only of spaces is trimmed to an empty string and ignored; no chip is added.
- **Backspace behavior in separate mode**: Backspace while the input is non-empty edits the text; it does not remove chips. Only in fused mode does Backspace with an empty input remove the last chip.
- **Validation does not block addition**: Invalid chips are still added to the value array; the component marks them as invalid via appearance and `aria-invalid` but does not reject them. The consuming feature (e.g., an invitation modal) decides whether to block send.
- **Phone validation looseness**: `validate-phone`'s pattern (`/^[+]?[\d\s().-]{7,}$/`) matches any run of 7 or more characters drawn from digits, whitespace, parentheses, dots, and dashes — including punctuation-and-space-only strings with no digits at all (e.g. `(((( ))))`), which pass as valid with no minimum digit count required. This looseness is intentional, consistent with the advisory-only validation design (see Design Decisions).
- **Duplicate detection scope**: De-duplication is performed case-insensitively for email and exact for other kinds; it compares the input entry against all existing chips in `value`. This applies identically whether entries arrive one at a time (Enter/blur) or as a pasted, comma-separated batch — within a single pasted batch, later duplicates of an earlier entry in the same batch are dropped before any of them are added.
- **Duplicate-chip removal**: `chip-removal-via-dismiss` filters the value array by value equality, not by index or identity. The component's own tokenization always rejects duplicates on entry, so this only matters if the parent seeds the `value` array directly with duplicate strings; in that case, activating the remove control on any one of the matching chips removes every chip with that value, not just the one clicked.
- **Disabled state under readOnly**: `readOnly` alone already renders chips as static Badges with no remove control, so adding `disabled` on top only applies the dimmed, non-interactive appearance to the whole component — it does not further change chip removability, which is controlled solely by `readOnly`.
- **Disabled state and keyboard-activated removal**: `pointer-events-none` (applied when `disabled=true`) blocks mouse and touch interaction with chip remove buttons, but the remove buttons do not carry the HTML `disabled` attribute; a keyboard user who tabs to a remove button can still activate it with Enter or Space, which calls `onChange`. Pointer interaction and typing are otherwise fully inert while disabled.
- **Placeholder behavior in fused mode**: The placeholder text is shown only when the chip list is empty. Once at least one chip is present, the placeholder is hidden.
- **Focus behavior in separate mode**: Each part (recipients box and input) can be styled independently; the recipients box has no focus ring of its own; focus styling applies to the separate Input element.
- **Rejected duplicate clears the input regardless**: When Enter, blur, or a comma commits an entry that turns out to be a duplicate, the typed text is still cleared from the inline input — clearing is unconditional on submit, not conditional on the entry being accepted. No visual or assistive-technology announcement is made when an entry is silently rejected as a duplicate; it simply never appears as a new chip.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `value` | `string[]` | — (required) | Controlled array of recipient strings. The component does not modify this directly; changes flow through `onChange`. |
| `onChange` | `(next: string[]) => void` | — (required) | Called with the updated recipient array on any add or remove. Not called in `readOnly` mode. |
| `kind` | `"email" \| "phone" \| "text"` | `"text"` | Validation mode and input type hints. `"email"` and `"phone"` apply regex validation; `"text"` skips validation. |
| `placeholder` | `string` | `"Add email…"`, `"Add phone…"`, or `"Add…"` (depends on `kind`) | Placeholder text for the inline input. If not provided, a default matching `kind` is used. In separate mode, placeholder is applied to the separate Input. In fused mode, placeholder is shown only when chips list is empty. |
| `ariaLabel` | `string` | — (required) | Accessible label for the container group. Input field label is derived as `Add to ${ariaLabel}`. |
| `disabled` | `boolean` | `false` | When true, all interaction is disabled: chips cannot be removed, input cannot be typed, `onChange` is not called. |
| `className` | `string` | — | Additional CSS classes applied to the root container. |
| `separateInput` | `boolean` | `false` | When true, renders the recipients box and input as two visually distinct stacked elements instead of one fused container. Chips in the recipients box remain removable unless `readOnly` is also set. |
| `readOnly` | `boolean` | `false` | When true, recipients display as static, non-removable Badge chips and no input field is rendered. Useful for displaying fixed recipient lists from the server. `onChange` is never called in this mode. |

## Deep Linking

Not applicable: RecipientInput is a controlled form component without independent routing or deep-linking requirements.

## Localization

| String Key | Default (en) | Context |
|------------|---------------|---------|
| `#localization/remove-label` | `Remove {value}` | Accessible name for a chip's remove button; `{value}` is the recipient string the chip holds. |
| `#localization/placeholder-email` | `Add email…` | Default placeholder when `kind="email"` and no `placeholder` prop is given. |
| `#localization/placeholder-phone` | `Add phone…` | Default placeholder when `kind="phone"` and no `placeholder` prop is given. |
| `#localization/placeholder-text` | `Add…` | Default placeholder when `kind="text"` (or unspecified) and no `placeholder` prop is given. |
| `#localization/empty-recipients` | `No recipients yet` | Shown inside the separate-mode recipients box when `value` is empty. |

None of these strings are currently externalized into resource files — see **string-externalization** and **no-hardcoded-strings** in Compliance.

## Accessibility Options

RecipientInput does not respond to Reduce Motion (there is no animation to reduce) or Increase Contrast (it inherits whatever contrast the underlying `apt-*` design tokens resolve to; no separate high-contrast styling exists). It does not currently respond to Differentiate Without Color either: valid and invalid chips are distinguished primarily by Badge color (`variant="neutral"` vs `variant="error"`), and the only non-color signal is the `aria-invalid` attribute, which is not visible to sighted users — there is no icon, text, or pattern difference between a valid and an invalid chip.

## Feature Flags

Not applicable: RecipientInput is a foundational UI component with no feature-flag gating or opt-in behavior.

## Analytics

Not applicable: RecipientInput is a presentational component that does not emit its own analytics events. Consuming features (e.g., invitation modals) handle logging of user actions and submission outcomes.

## Privacy

Not applicable: RecipientInput is a controlled input component that does not collect, store, transmit, or persist data independently. It is a stateless pass-through; data persistence and transmission are the responsibility of the consuming feature.

## Logging

Not applicable: RecipientInput is a presentational component that does not emit structured logging events. Tokenization, validation outcomes, and submission are logged by consuming features, not by the input component itself.

## Platform Notes

- **React / Web (TypeScript)**: Component implemented at `packages/web/packages/ui/src/components/recipient-input.tsx`. Built from native HTML `<div>`, `<input>`, and composed UI primitives (Badge, RemovableChip, Input). The field-shell token is the shared `fieldShellClass` constant (`rounded-lg border border-apt-border bg-apt-bg`), applied to both the fused container and the separate-mode recipients box, plus `flex flex-wrap items-center gap-1.5 px-2 py-1.5` for chip wrapping. focus-accent is `focus-within:border-apt-gold focus-within:ring-2 focus-within:ring-apt-gold/25`. The disabled token is `pointer-events-none opacity-50`. neutral-chip/error-chip map to Badge's `variant="neutral"` (`border-apt-border text-apt-text-dim`) and `variant="error"` (`border-apt-red text-apt-red`). Integrates with Tailwind CSS. Export: `RecipientInput(props: RecipientInputProps): React.ReactElement`.

- **SwiftUI**: SwiftUI has no built-in token-chip control; wrap the platform's native one instead — `NSTokenField` on macOS or `UISearchTextField`'s `tokens` API on iOS — via `NSViewRepresentable`/`UIViewRepresentable`. Where a hand-built fallback is unavoidable, compose a `TextField` with a wrapping `Layout` (or `LazyVGrid`) for chip rendering, validating each entry against `kind` on submit.

- **Compose (Android Kotlin)**: Lead with Material3 `InputChip` inside a `FlowRow` for the chip layout, paired with `OutlinedTextField` for entry; use each `InputChip`'s trailing icon slot for removal rather than a separate `IconButton`. Validate input according to `kind` and update state via `onValueChange`.

- **AppKit / UIKit (macOS, iOS native)**: Lead with each platform's own token control — `NSTokenField` on macOS, `UISearchTextField`'s `tokens` property on iOS — before falling back to a hand-built version. A hand-built fallback arranges chip buttons in an `NSStackView` (macOS) or `UIStackView` (iOS) above the text field and attaches a target/action (macOS) or gesture recognizer (iOS) to each chip's remove control. Apply border and focus styling via the text field's own bezel/border APIs (`NSTextField`'s bezel style, or a custom `CALayer` border) — not `NSBorderTextField`, which does not exist.

- **WinUI 3**: Lead with the Windows Community Toolkit's `TokenizingTextBox`, which natively renders removable tokens with comma/Enter-style entry, before falling back to a hand-built `TextBox` + `ItemsRepeater` pairing. Focus ring and validation styling use WinUI's `VisualState` theming. Bind the control's text/token collection to state; on a validation trigger (Enter, comma, blur), parse and update the bound token list; remove tokens via the control's built-in removal affordance (or button taps on `ItemsRepeater` items, in the fallback).

## Design Decisions

- **Decision**: Invalid chips are still added to the value array rather than rejected.
  **Rationale**: Validation is advisory, not blocking. Invalid chips are added and marked visually and with `aria-invalid`, letting the consumer decide whether to block send. This keeps the input dumb and reusable across different validation rules a consumer may enforce.
  **Approved**: pending

- **Decision**: Email de-duplication is case-insensitive; other kinds use exact string comparison.
  **Rationale**: Email addresses are case-insensitive in practical routing (`Ada@x.io` and `ada@x.io` are the same recipient). Other input kinds (phone, text) use exact string comparison to preserve user intent. The comparison uses the default `toLowerCase()`, which applies the locale-insensitive (invariant) Unicode case mapping regardless of the runtime's current locale; a port MUST use the equivalent invariant-culture lowercasing — for example `.lowercased()` in Swift, `lowercase(Locale.ROOT)` in Kotlin, or `ToLowerInvariant()` in .NET — not a locale-aware variant, to match this behavior exactly. Under a locale where casing is context-sensitive (e.g. Turkish, where uppercase `I` lowercases to dotless `ı` only under locale-aware folding), a locale-aware port would fold two logically-identical addresses differently and fail to de-duplicate them; the invariant mapping the source uses avoids that.
  **Approved**: pending

- **Decision**: Two layout modes are offered: fused (default) and separate.
  **Rationale**: The default fused layout mimics the Input primitive for consistency. The separate mode allows designs that need to visually emphasize the existing recipient list (e.g., invitation interfaces that show seeded recipients separately from new entries). Both modes share the same tokenization, validation, and `inputMode` logic — see the note at the top of Behavioral Requirements.
  **Approved**: pending

- **Decision**: Read-only mode disables the input and renders chips as Badge instead of RemovableChip.
  **Rationale**: Read-only mode is designed for displaying fixed recipient lists (e.g., backend-seeded selections) without presenting an editable interface. Using Badge instead of RemovableChip signals to users that removal is not available, reducing accidental interaction attempts.
  **Approved**: pending

- **Decision**: Backspace removes the last chip only in fused mode.
  **Rationale**: Backspace removal is a convenience for compact fused layouts. In separate input mode, the recipients box is never focused, so Backspace is applied to the input text, not to tokens. This avoids accidental deletion in two-part layouts.
  **Approved**: pending

- **Decision**: Both layout modes' chip-and-input containers point at the shared `fieldShellClass` field-shell token rather than each typing out the border/background/radius classes.
  **Rationale**: `fieldShellClass` is already the one home for the form-control shell shared with the Input primitive and its siblings; pointing both RecipientInput layouts at it keeps the field look changing in exactly one place and gives users of other input controls a predictable, consistent appearance.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy & Data |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | passed | Privacy & Data |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on `recipient-input.tsx`: `role="group"`/`aria-label`/`aria-invalid` plus native `<button>` remove controls (screen-reader-support, keyboard-navigable, semantic-markup passed); color-only `apt-*` tokens whose resolved contrast isn't visible from this file, and a remove button with no explicit hit-area sizing (contrast-ratio, touch-target-size partial); regex format validation with no injection-specific handling beyond React's default text escaping (input-sanitization partial); a fully consumer-controlled `value` prop with no internal persistence or logging (data-minimization, no-pii-in-logs passed); five strings (`Remove {value}` and the four placeholder/empty-state strings) hardcoded directly in the component (string-externalization, no-hardcoded-strings failed); an unfiltered native `<input>` accepting any Unicode text (unicode-support passed); and default flexbox wrapping with no explicit RTL handling or testing (rtl-layout-support partial). The `EMAIL_RE`/`PHONE_RE` validation, comma-tokenizing, and case-insensitive dedup logic all live inline in the component body rather than a separate module (separation-of-concerns partial); `recipientInput.test.tsx` directly exercises tokenizing on Enter and comma, dedup, Backspace removal, per-chip removal, and invalid-email flagging (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.1 | 2026-09-25 | Mike Fullerton | Fixed locale note: source uses invariant lowercase; ports must match it, not go locale-aware. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename all requirements to subject-only kebab-case and fix "MUST not" to "MUST NOT"; lead Platform Notes native bullets with each platform's real token control and cut each bullet to one real layout choice; clarify that separate-mode chips stay removable unless `readOnly` is set and that inline-input rules apply to the separate `Input`; add paste/duplicate-batch, input-mode-text, valid-email, readOnly/disabled onChange, duplicate-chip-removal, and keyboard-removal test vectors; document the phone-validation punctuation-only looseness, the disabled-state keyboard-removal caveat, and that a rejected duplicate still clears the input; rewrite Localization as linked `#localization/<key>` entries and Accessibility Options to state the real Differentiate Without Color gap instead of "not applicable"; reformat Design Decisions into Decision/Rationale/Approved triples, note the locale-sensitivity of the email dedup casing transform, and point both layout modes at the shared `fieldShellClass` token instead of duplicated class strings; rewrite Appearance/States as semantic tokens with the Tailwind classes moved into the React/Web platform note; rewrite Compliance as linked checks under canonical categories. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Remove "Not applicable" phrasing from Platform Notes non-web bullets; sharpen native platform guidance; relabel Windows bullet to `**WinUI 3**`. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Document `separateInput` and `readOnly` modes; expand behavioral requirements; add missing sections (Deep Linking, Localization, etc.); update Platform Notes to cover all five platforms; fix domain URI. |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial conversion from legacy UI spec. |
