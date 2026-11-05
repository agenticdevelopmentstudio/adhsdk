---
id: c5703986-6d14-4341-8719-b89e44f2ab80
title: Label
domain: adhsdk://recipes/label
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A semantic form label that pairs with a form control and reflects that control's disabled state.
platforms:
- typescript
- web
tags:
- form-controls
- label
depends-on: []
related:
- adhsdk://recipes/field
- adhsdk://recipes/text-field
- adhsdk://recipes/checkbox
- adhsdk://recipes/select
references: []
approved-by: ''
approved-date: ''
---

# Label

## Overview

The Label component is a reusable HTML `label` element wrapper that applies default Tailwind CSS styling for typography and layout. It is designed as a primitive form label that pairs with form controls via the `htmlFor` attribute or nesting. The component accepts all standard HTML label properties and supports class merging for additional customization.

## Behavioral Requirements

- **renders-label-element**: Component MUST render as an HTML `label` element.
- **forwards-label-props**: Component MUST accept and forward all standard HTML label attributes (`htmlFor`, `id`, event handlers, etc.) via prop spreading.
- **default-typography**: Component MUST render its text at medium weight, small size, with a line-height of 1 (no extra leading), and MUST NOT allow that text to be user-selected.
- **merges-classname**: Component MUST accept a `className` prop and merge it with its default styling using a class merging utility, such that a consumer-supplied class overrides the corresponding default class.
- **peer-disabled-style**: When the label is rendered as a sibling immediately following a peer form control (a control carrying the `peer` class) and that control is disabled, the label MUST render with 50% opacity and a not-allowed cursor. A control nested inside the label, or a peer control that comes after the label rather than before it, does not trigger this style.
- **focuses-associated-control**: Clicking the label's rendered text MUST move focus to (and, for a checkbox or radio control, toggle) the form control it is associated with via `htmlFor` or nesting. This follows from rendering a native `label` element (**renders-label-element**); the component adds no click handling of its own.

## Appearance

- **Corner radius**: None
- **Padding**: None (explicit padding not applied; flexbox layout provides spacing)
- **Font**: Medium weight (font-medium), small size (text-sm), line-height 1 (leading-none)
- **Foreground/Text**: `text-apt-text`, a design system color token defined as `--color-apt-text` in `packages/web/packages/themes/src/tailwind.css` and mapped per theme (e.g. to `--color-text-primary` or `--color-on-surface`)
- **Gap between children**: 2 units (via `gap-2` flex gap)
- **User select**: None (text is not user-selectable)
- **Text alignment**: Flexbox centered vertically on the cross-axis (items-center)

## States

| State | Appearance change |
|-------|------------------|
| Default | Standard text color and cursor |
| Peer Disabled | Cursor changes to `not-allowed`; opacity reduces to 50% |

## Accessibility

The component renders a native `label` element, providing semantic meaning for assistive technologies. Consumers are responsible for associating the label with its form control via the `htmlFor` attribute (matching the control's `id`) or by nesting the form control within the label. The source disables the `jsx-a11y/label-has-associated-control` ESLint rule at the component definition, because the component is a reusable primitive that does not know which control it pairs with; consumers supply the association via `...props`.

- **Role**: Label (native HTML semantic element)
- **Label requirements**: Consumer MUST provide `htmlFor` attribute or nest the associated form control
- **Focus behavior**: Clicking the label moves focus to (and, for checkboxes/radios, toggles) its associated control — see **focuses-associated-control**
- **Announce state changes**: Disabled state is communicated via opacity and cursor change; screen readers perceive this via the peer element's own disabled state, not via the label

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| label-001 | renders-label-element | Render with no props | HTML `label` element in DOM |
| label-002 | forwards-label-props | Pass `htmlFor="input-id"` and `id="label-1"` | Label renders with matching `htmlFor` and `id` attributes |
| label-003 | default-typography | Render with default props | Computed `font-weight: 500`, small-size `font-size`, `line-height: 1`, and `user-select: none` |
| label-004 | merges-classname | Pass `className="custom-class"` | Rendered element has both default classes and `custom-class` |
| label-005 | peer-disabled-style | Render label as a sibling immediately after a peer input; input becomes disabled | Label's computed `opacity` becomes `0.5` and `cursor` becomes `not-allowed` |
| label-006 | peer-disabled-style | Render label as a sibling immediately after a peer input; input is not disabled | Label's computed `opacity` remains `1` and `cursor` remains the default |
| label-007 | focuses-associated-control | Click the label's text when `htmlFor` references an `<input type="checkbox">`'s `id` | The checkbox receives focus and its checked state toggles |

## Edge Cases

- **Missing htmlFor or nesting**: Component renders; however, the label is not semantically associated with a control. This is a consumer error, not a component failure.
- **Empty label text**: Component renders as an empty label element; flexbox layout applies but with no visible content.
- **Multiple children**: Component layout supports multiple children via flexbox with `gap-2` spacing between them.
- **className collision**: The class-merging utility (`cn()`, wrapping `tailwind-merge`) resolves conflicting classes by override, not deduplication: a consumer-supplied class such as `text-lg` replaces the default `text-sm` rather than both being applied.
- **Control nested in label / control after label**: See **peer-disabled-style** — the CSS `:peer` mechanism only matches a later sibling, so a control nested inside the label, or a peer control placed after the label in markup, never triggers the disabled style.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `className` | string | undefined | Additional CSS classes to merge with defaults |
| `htmlFor` | string | undefined | Associates label with form control by its `id` |
| `id` | string | undefined | HTML id attribute for the label element |
| `...props` | all label props | — | All other standard HTML label attributes (event handlers, data attributes, etc.) |

## Deep Linking

Not applicable: Label is a low-level form control primitive without its own deep linking behavior.

## Localization

Not applicable: Label component contains no user-facing strings; localization is the consumer's responsibility via text content passed as children.

## Accessibility Options

Not applicable: Label responds only to the native disabled state of peer elements, which is handled by the form control itself. No additional accessibility display options (Reduce Motion, Increase Contrast, Differentiate Without Color) are directly managed by this component.

## Feature Flags

Not applicable: Label is a primitive component with no feature flags.

## Analytics

Not applicable: Label is a non-interactive primitive; no analytics events are emitted.

## Privacy

Not applicable: Label does not collect or transmit any data.

## Logging

Not applicable: Label does not perform any logging.

## Platform Notes

- **SwiftUI**: Use `LabeledContent`, or a `Form` row's built-in label, to pair label text with a control; for a freestanding label, use plain `Text` in an `HStack` rather than SwiftUI's `Label` view (which is an icon-plus-title view, not a form-control label). Apply `.fontWeight(.medium)` and a small `.font` size. Read the paired control's disabled state from `@Environment(\.isEnabled)` and reduce opacity to match.
- **Compose (Kotlin)**: Use Jetpack Compose's `Text` composable within a `Row` for alignment, gap, and text style. `Text` is not selectable by default — selection requires wrapping it in a `SelectionContainer` — so no extra modifier is needed to prevent selection. Disabled state styling responds to the paired control's enabled state.
- **React/Web**: Direct implementation from the source. Files: `packages/web/packages/ui/src/components/label.tsx`. Exports a named `Label` function component that accepts `React.ComponentProps<"label">`. Applies the Tailwind utility classes `flex items-center gap-2 text-sm font-medium leading-none text-apt-text select-none` plus `peer-disabled:cursor-not-allowed peer-disabled:opacity-50`, merged with a consumer `className` via the `cn()` utility from a sibling `../lib/utils` module.
- **AppKit / UIKit**: Use `NSTextField(labelWithString:)` (macOS), which creates a non-editable, non-selectable label field, or `UILabel` (iOS). Configure font as system font with medium weight and small size. Apply text color to match the design system token. For disabled state, observe the associated control's enabled property and update opacity to match; there is no cursor to manage on iOS, and a plain label needs none on macOS either.
- **WinUI 3**: Use `TextBlock` or a custom `Label` control. Set `FontWeight` to `FontWeights.Medium` (not `Bold`), `FontSize` to a small value (e.g., 12pt), and `Foreground` to the design system text color. `TextBlock` has no `Cursor` property; omit the not-allowed cursor, or, if a custom control needs one, expose it via `ProtectedCursor` in a custom control template. Bind `Opacity` to the associated input control's `IsEnabled` state via a converter or code-behind logic.

## Design Decisions

**Decision**: Use flexbox (`flex items-center gap-2`) rather than block or inline layout.
**Rationale**: Supports flexible alignment of children and spacing, accommodating common patterns like icon + text within a label.
**Approved**: pending

**Decision**: Omit explicit padding at the component level.
**Rationale**: Allows consumers full control over spacing, supporting a wide range of container contexts.
**Approved**: pending

**Decision**: Respond to a peer element's disabled state via the CSS `:peer-disabled` selector rather than accepting a `disabled` prop.
**Rationale**: Avoids double-managing disabled state between the label and its control, and keeps the label primitive simple. See **peer-disabled-style** for the sibling-order precondition this implies.
**Approved**: pending

**Decision**: Accept `htmlFor` without enforcing the association.
**Rationale**: Keeps the component a true primitive; the consumer supplies the association, and the `jsx-a11y/label-has-associated-control` lint suppression signals that this is an intentional contract rather than an oversight.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

The source renders a native `label` element with `htmlFor`/nesting-based focus-forwarding to its control, which is what passes screen-reader-support, keyboard-navigable, and semantic-markup. The `text-sm`/`font-medium` classes and the `text-apt-text` token resolve to values defined outside this file, so the source alone cannot confirm the resulting type scale honors system font-size settings or that the token meets WCAG AA contrast against every theme background (dynamic-type-support, contrast-ratio: partial); the clickable label area's size depends on consumer-supplied content rather than an enforced minimum (touch-target-size: partial). separation-of-concerns passes because `Label` does nothing but forward props/classes onto a native `label` element, with no logic of its own to entangle with anything else. unit-test-coverage fails because no test file in the `ui` package exercises `Label` at all.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-based names and updated all citations; restated styling/disabled requirements and test vectors as behavior, moving Tailwind class names into the React/Web platform note; corrected inaccurate SwiftUI, Compose, AppKit, and WinUI 3 platform APIs and reordered Platform Notes to convention order; added peer-disabled-style sibling-order preconditions, a nested/after-label edge case, and a focuses-associated-control requirement with test vector; reformatted Design Decisions into Decision/Rationale/Approved form and added a Compliance table; corrected the className-collision edge case to override semantics, linked the text-apt-text token to its source, fixed the ESLint provenance reference, rewrote the summary to drop implementation detail, and added sibling recipes to related |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Corrected --color-apt-text source path to packages/web/packages/themes/src/tailwind.css. |
