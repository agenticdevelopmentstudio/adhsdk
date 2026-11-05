---
id: fcc6d4c4-d83e-402a-857c-fbd0aff91113
title: Stack
domain: adhsdk://recipes/stack
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Vertical and horizontal layout containers that arrange children with flexible
  gap, alignment, and justification.
platforms:
- typescript
- web
tags:
- layout
- flexbox
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Stack

## Overview

VStack and HStack are layout containers that arrange child elements in a vertical or horizontal direction using CSS Flexbox. They provide a flexible gap property, alignment control via `alignItems`, and justification control via `justifyContent`. Both components render as non-semantic `div` elements — a `div` has no ARIA semantics, so it adds no role or landmark to the accessibility tree — and accept custom CSS classes and inline styles for further customization. No prop other than `children`, `gap`, `align`, `justify`, `className`, and `style` is read or forwarded to the root element.

## Behavioral Requirements

- **render-children**: Both VStack and HStack MUST render all child elements passed via the `children` prop.
- **apply-gap-prop**: The component MUST apply the `gap` prop as a CSS `gap` property; when `gap` is a number, it MUST be converted to a pixel string (e.g., `16` becomes `"16px"`); when `gap` is a string, it MUST be applied as-is.
- **gap-omitted-when-unset**: When the `gap` prop is not provided, the computed inline style MUST have no `gap` declaration.
- **apply-align**: The component MUST apply the `align` prop directly to the CSS `alignItems` property.
- **apply-justify**: The component MUST apply the `justify` prop directly to the CSS `justifyContent` property.
- **apply-inline-styles**: The component MUST merge provided `style` prop values with layout-specific styles, giving precedence to `style` prop values when both are present.
- **apply-class-names**: The component MUST apply the base class name `aws-stack` to the root element; MUST apply either `aws-stack--v` for VStack or `aws-stack--h` for HStack; MUST append the `className` prop if provided.
- **no-rest-prop-forwarding**: The component MUST NOT forward any prop other than `children`, `gap`, `align`, `justify`, `className`, and `style` to the root element; `id`, `role`, `aria-*`, and any other attribute cannot be set through Stack's props.
- **render-non-semantic-div**: The component SHOULD render a `div` element for flexible, CSS-class-based styling; because a `div` carries no ARIA semantics, this renders a non-semantic element that adds no role or landmark to the accessibility tree.

## Appearance

- **Container element**: `<div>`
- **Display**: `flex` (set by `aws-stack` class or equivalent)
- **Gap**: Customizable via `gap` prop; defaults to `undefined` (no gap)
- **Alignment**: Customizable via `align` prop (maps to `alignItems`); defaults to `undefined`
- **Justification**: Customizable via `justify` prop (maps to `justifyContent`); defaults to `undefined`
- **Direction**: VStack uses column; HStack uses row (set by `aws-stack--v` or `aws-stack--h` class)
- **Padding**: None by default; customizable via inline `style` prop

## States

Not applicable: Stack is a non-interactive layout container and does not have interaction states.

## Accessibility

- **Role**: Stack renders a plain `<div>` with no ARIA role. Stack does not forward `role` or other rest props (see **no-rest-prop-forwarding**), so consuming code cannot set a role through Stack itself.
- **Keyboard navigation**: Not applicable; Stack is a layout primitive and does not handle keyboard interaction. Child elements within the Stack maintain their native keyboard behavior.
- **Screen reader**: Stack does not obscure the semantic meaning of child elements. The root `div` carries no role or landmark, so it is invisible to the accessibility tree (see **render-non-semantic-div**).
- **Labels**: Not applicable; Stack is a layout container and carries no label. Child interactive elements within the Stack MUST maintain their own labels.
- **Semantic structure**: Stack is transparent to the document outline because the root `div` adds no role or landmark (see **render-non-semantic-div**). Child elements MUST maintain their semantic value (headings, buttons, etc.).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|----|----|
| stack-001 | render-children | VStack with two child divs | Both child elements rendered in the DOM |
| stack-002 | apply-gap-prop (number) | VStack with `gap={16}` | Inline style has `gap: "16px"` |
| stack-003 | apply-gap-prop (string) | VStack with `gap="1rem"` | Inline style has `gap: "1rem"` |
| stack-004 | gap-omitted-when-unset | VStack with no `gap` prop | The inline style has no `gap` declaration |
| stack-005 | apply-align | HStack with `align="center"` | Inline style has `alignItems: "center"` |
| stack-006 | apply-justify | VStack with `justify="space-between"` | Inline style has `justifyContent: "space-between"` |
| stack-007 | apply-inline-styles | VStack with `style={{ padding: '10px' }}` | Inline styles merged; rendered element includes `padding: 10px` |
| stack-008 | apply-class-names (VStack) | VStack with `className="custom"` | Root element has classes: `aws-stack aws-stack--v custom` |
| stack-009 | apply-class-names (HStack) | HStack with `className="custom"` | Root element has classes: `aws-stack aws-stack--h custom` |
| stack-010 | render-non-semantic-div | Both VStack and HStack | Root element is a `<div>` tag with no `role` or landmark attribute |
| stack-011 | render-children (undefined children) | VStack with `children={undefined}` | Root `<div>` renders with the layout classes and no child nodes |
| stack-012 | render-children (empty array) | VStack with `children={[]}` | Root `<div>` renders with the layout classes and no child nodes |
| stack-013 | apply-gap-prop (zero, number) | VStack with `gap={0}` | Inline style has `gap: "0px"` |
| stack-014 | apply-gap-prop (zero, string) | VStack with `gap="0"` | Inline style has `gap: "0"` |
| stack-015 | apply-inline-styles (conflicting style) | VStack with `gap={8}`, `align="center"`, `style={{ gap: '2rem', alignItems: 'flex-start' }}` | Inline style has `gap: "2rem"` and `alignItems: "flex-start"` |
| stack-016 | apply-class-names (empty className) | VStack with `className=""` | Class attribute is `"aws-stack aws-stack--v"` with no empty or extra whitespace tokens |
| stack-017 | no-rest-prop-forwarding | VStack rendered with an unsupported prop forced onto it (e.g. `{ id: 'x' } as any`) | Root element has no `id` attribute |

## Edge Cases

- **Undefined children**: If `children` is `undefined` or `null`, the component MUST render an empty div with layout classes applied.
- **Empty children array**: If `children` is an empty array, the component MUST render an empty div with layout classes applied.
- **Gap as zero**: If `gap={0}`, the component MUST apply `gap: "0px"`; if `gap="0"`, it MUST apply `gap: "0"`.
- **Conflicting inline styles**: If `style` contains `gap`, `alignItems`, or `justifyContent`, those values MUST take precedence over the `gap`/`align`/`justify` props, because `style` is spread last when merging.
- **Empty or absent className**: If `className` is not provided or is an empty string, the class attribute contains no empty or extra whitespace tokens.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `children` | `ReactNode` | `undefined` | Child elements rendered inside the stack. |
| `gap` | `number \| string` | `undefined` | Spacing between children. Numbers convert to pixel strings; strings are applied as-is. |
| `align` | `CSSProperties['alignItems']` (CSS keyword union, or any string) | `undefined` | Maps to the CSS `alignItems` property. |
| `justify` | `CSSProperties['justifyContent']` (CSS keyword union, or any string) | `undefined` | Maps to the CSS `justifyContent` property. |
| `className` | `string` | `undefined` | Appended after the base `aws-stack` and direction classes. |
| `style` | `CSSProperties` | `undefined` | Merged into the computed inline style last, taking precedence over `gap`/`align`/`justify`. |

No other props are accepted. `id`, `role`, `aria-*`, and any other attribute are not forwarded to the root element (see **no-rest-prop-forwarding**).

## Deep Linking

Not applicable: Stack is a layout container with no standalone URL representation or deep linking capability.

## Localization

Not applicable: Stack contains no user-facing strings or locale-dependent behavior.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: Stack defines no motion. |
| Increase Contrast | Not applicable; Stack is a layout container with no colors or contrast requirements. |
| Differentiate Without Color | Not applicable; Stack does not rely on color to convey information. |

## Feature Flags

Not applicable: Stack is a foundational layout component and does not require feature flags.

## Analytics

Not applicable: Stack is a non-interactive layout container and does not generate user events.

## Privacy

Not applicable: Stack does not collect, store, or transmit any user data.

## Logging

Not applicable: Stack is a layout primitive with no logging requirements in the source code.

## Platform Notes

- **React/Web**: Implemented as functional components in `Stack.tsx`. VStack renders a div with `aws-stack--v` class; HStack renders a div with `aws-stack--h` class. Gap conversion from number to pixel string is handled by the `gapValue()` utility. Styles are merged inline using spread syntax, with the `style` prop taking precedence. Classes are filtered and joined using a simple boolean filter to avoid empty strings. Only the props defined on `StackProps` are read; the components never spread additional rest props onto the root element, so `id`, `role`, and `aria-*` are never forwarded.
- **SwiftUI**: Implement using the native `VStack(alignment:spacing:)` and `HStack(alignment:spacing:)` initializers. Map `gap` to the initializer's `spacing` parameter — SwiftUI has no `.spacing()` modifier. Map `align` to the initializer's `alignment` parameter. SwiftUI's `VStack`/`HStack` have no `justifyContent` equivalent; approximate `justify` with `Spacer()` views placed between or around children (see Design Decisions for which control wins when a platform can't represent both `gap` and `justify` independently).
- **Compose (Android)**: Implement using Jetpack Compose's `Column` (for VStack) and `Row` (for HStack) composables. Map `gap` to the `verticalArrangement` (Column) or `horizontalArrangement` (Row) parameter, using `Arrangement.spacedBy()`. Map `align` to the `horizontalAlignment` (Column) or `verticalAlignment` (Row) parameter — this is the cross-axis alignment, opposite of the axis `gap` uses. `Arrangement.spacedBy()` (from `gap`) and `Arrangement.SpaceBetween` (from `justify`) both set the same `Arrangement` parameter and cannot be applied together; per Design Decisions, `gap` takes precedence and `justify` is dropped when both are set.
- **AppKit / UIKit**: Use `NSStackView` (macOS) or `UIStackView` (iOS) as the container. Set the `axis` property to `.vertical` for VStack or `.horizontal` for HStack. Map `gap` to the `spacing` property; map `align` to the `alignment` property; map `justify` to the `distribution` property (using `.fillEqually`, `.equalCentering`, or `.fill` as appropriate). A `distribution` other than `.fill` can override the visual effect of `spacing`, so per Design Decisions, `gap` (spacing) takes precedence and `justify` is approximated with the closest available distribution.
- **WinUI 3**: Implement using XAML `StackPanel`. Set `Orientation="Vertical"` for VStack or `Orientation="Horizontal"` for HStack. Map `gap` to the `Spacing` property, a `double` (not an integer). `StackPanel` has no `justifyContent` equivalent — there is no native way to distribute or justify children within it; where `justify` must be honored, use a `Grid` with star-sized (`*`) rows or columns instead. Custom classes are not applicable to `StackPanel`; apply styling via a XAML `Style` resource (there is no "CSS-in-XAML").

## Design Decisions

**Decision**: The `gap` prop accepts either a number or a string.
**Rationale**: Numeric values are converted to pixels; string values allow any CSS unit (rem, em, %, etc.). This accommodates both fixed-pixel spacing and responsive relative sizing.
**Approved**: pending

**Decision**: The `style` prop is spread last in the merged styles object, giving it precedence over layout-derived styles.
**Rationale**: This allows consumers to override gap, alignment, or justification when needed without modifying the component.
**Approved**: pending

**Decision**: The className array is filtered to remove falsy values (empty strings) before joining.
**Rationale**: This prevents malformed class strings and ensures clean DOM output.
**Approved**: pending

**Decision**: When `gap` is undefined, the CSS `gap` property is not set.
**Rationale**: This allows default styling from the CSS class definitions to apply, reducing redundant inline style declarations.
**Approved**: pending

**Decision**: On platforms where the native layout primitive maps `gap` and `justify` onto the same property (Compose `Arrangement`, `NSStackView`/`UIStackView` `distribution`), `gap` takes precedence; `justify` is approximated with the closest available distribution, or dropped.
**Rationale**: The React/Web source applies `gap` and `justifyContent` as independent CSS properties with no conflict between them; a priority is needed only where a platform's API cannot represent both independently.
**Approved**: pending

**Decision**: The base class name `aws-stack` is a fixed string literal in the source, not a template variable or configurable prop.
**Rationale**: `Stack.tsx` hardcodes the prefix and exposes no mechanism for consumers to override it; the `aws` prefix predates this recipe and its origin is not documented in the source.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

This rests on the source rendering a plain `<div>` with no `role` or other ARIA attribute, and never forwarding `role` or other rest props onto it (see **no-rest-prop-forwarding**); `VStack`/`HStack` are pure presentation over props with only a trivial `gapValue` helper (separation-of-concerns passed), and no test file exercises `Stack.tsx` — the candidate tests matched by name are unrelated Swift and avatar-engine files (unit-test-coverage failed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and updated all citations; rewrote semantic-div claims as non-semantic-div and fixed the Accessibility section's role-forwarding contradiction; added a `no-rest-prop-forwarding` requirement and a Configuration props table; added edge-case test vectors and fixed stack-004's observability; deleted the redundant "missing direction class" edge case; corrected the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes and documented gap/justify precedence; reformatted Design Decisions into the Decision/Rationale/Approved form and documented the hardcoded `aws-stack` prefix; built the Compliance table; and marked Reduce Motion not applicable |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
