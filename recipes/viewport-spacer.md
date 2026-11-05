---
id: 556f7dbf-2a14-4e97-aaa2-0954c7488e6f
title: ViewportSpacer
domain: adhsdk://recipes/viewport-spacer
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Flex spacer that absorbs leftover vertical space in a ViewportShell, pushing
  siblings downward.
platforms:
- typescript
- web
tags:
- layout
- flex
- viewport
depends-on:
- adhsdk://recipes/viewport-shell
related:
- adhsdk://recipes/viewport-composer
references: []
approved-by: ''
approved-date: ''
---

# ViewportSpacer

## Overview

A flex spacer component that absorbs leftover vertical space inside a `<ViewportShell>`, pushing siblings (typically a `<ViewportComposer>`) to the bottom. The component renders as a flex item that grows to fill available space.

## Behavioral Requirements

- **render-children**: Component MUST render any children passed via the `children` prop, including rendering an empty root element without error when `children` is `null`, `undefined`, or omitted.
- **default-class**: Component MUST apply the CSS class `vp-spacer` to its root element.
- **class-composition**: Component MUST combine the default class `vp-spacer` with a custom `className` when one is provided, separating them with a single space (e.g., `vp-spacer custom-class`); an empty-string `className` MUST NOT add a trailing space, so the root element's class stays `vp-spacer`.
- **fills-remaining-space**: The `vp-spacer` class MUST set `flex: 1 1 0` and `min-height: 0`, so the root element grows to absorb leftover vertical space in a flex-column parent (a `ViewportShell`) and can still shrink below its content size.
- **root-element**: Component MUST render its root as a single `div` element.
- **assistive-tech-invisible**: Component MUST NOT add an ARIA role, an accessible label, or a tab stop to the root element, so it stays invisible to assistive technology.

## Appearance

Not applicable: ViewportSpacer is a layout-only component with no built-in visual styling. Appearance is entirely controlled by CSS classes applied to it and its parent flex container.

## States

Not applicable: ViewportSpacer is a static layout component with no interactive states or state transitions.

## Accessibility

The root element is a plain `div` with no ARIA role, no accessible label, and no `tabindex` — see **assistive-tech-invisible** and **root-element**. It is not a landmark, a live region, or a focusable element, so screen readers and other assistive technology skip over it entirely, exactly as a purely structural spacer should. Accessibility semantics for real content come from ViewportSpacer's children and sibling components, not from ViewportSpacer itself.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| viewport-spacer-001 | render-children | `children={<p>Content</p>}` | Component renders the paragraph element as a child |
| viewport-spacer-002 | root-element, default-class | No props provided | Root element is a `div` with `class="vp-spacer"` |
| viewport-spacer-003 | class-composition | `className="my-custom"` | Root element has `class="vp-spacer my-custom"` |
| viewport-spacer-004 | class-composition | `className="custom-a custom-b"` | Root element has `class="vp-spacer custom-a custom-b"` |
| viewport-spacer-005 | render-children | `children={null}` (or omitted) | Component renders an empty `div` with class `vp-spacer` and no error |
| viewport-spacer-006 | class-composition | `className=""` (empty string) | Root element has `class="vp-spacer"` (empty string does not add a trailing space) |
| viewport-spacer-007 | render-children | `children={<><p>A</p><span>B</span></>}` (fragment with two children) | Component renders both the paragraph and the span |
| viewport-spacer-008 | fills-remaining-space | Rendered as a child of a `.viewport-shell` flex-column container | Root element's computed style has `flex: 1 1 0` and `min-height: 0` |
| viewport-spacer-009 | assistive-tech-invisible | No props (default render) | Root element has no `role`, no `aria-label`/`aria-labelledby`, and no `tabindex` attribute |

## Edge Cases

- **No children**: When no children are passed, the component renders an empty flex item; per **fills-remaining-space**, it still grows to occupy the leftover vertical space (see viewport-spacer-005 and viewport-spacer-008).
- **Empty className**: An empty-string `className` does not add a trailing space to the root element's class attribute, per **class-composition** (see viewport-spacer-006).
- **Null or undefined children**: When `children` is explicitly `null`, `undefined`, or omitted, the component renders an empty root element with no error, per **render-children** (see viewport-spacer-005).
- **Multiple children**: When multiple children are passed (e.g., within a fragment), the component renders all of them, per **render-children** (see viewport-spacer-007).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| children | ReactNode | undefined | Optional content to render inside the spacer |
| className | string | undefined | Optional custom CSS class(es) to apply alongside the default `vp-spacer` class |

## Deep Linking

Not applicable: ViewportSpacer is a layout component without a user-facing URL or deep link target.

## Localization

Not applicable: ViewportSpacer contains no user-facing text or localization strings.

## Accessibility Options

Not applicable: ViewportSpacer is a structural component without interactive elements or visual content that responds to accessibility display options.

## Feature Flags

Not applicable: ViewportSpacer has no feature flag logic in the source code.

## Analytics

Not applicable: ViewportSpacer is a layout component that does not track user interactions or analytics events.

## Privacy

Not applicable: ViewportSpacer does not collect, store, or transmit any data.

## Logging

Not applicable: ViewportSpacer contains no logging or diagnostic output in the source code.

## Platform Notes

- **SwiftUI**: Place a plain `Spacer()` inside the enclosing `VStack`; a `Spacer` already expands to fill the available space along the stack's axis, matching **fills-remaining-space**.
- **Compose**: Use `Spacer(modifier = Modifier.weight(1f))` within a `Column` layout to absorb available vertical space and push siblings downward.
- **React/Web**: The `ViewportSpacer` component as defined in the source. Requires a flex-column parent (`ViewportShell`, `display: flex; flex-direction: column`). The `vp-spacer` class implements **fills-remaining-space** via `flex: 1 1 0; min-height: 0`.
- **AppKit / UIKit**: Add a plain `NSView` (AppKit) or `UIView` (UIKit) as an arranged subview of the enclosing `NSStackView` / `UIStackView` with no intrinsic content size, and set its content-hugging priority to `.defaultLow` (250) and its compression-resistance priority to `.defaultLow` (250) on the stack's axis, so it absorbs the leftover space, matching **fills-remaining-space**. Without a stack view, pin the view with Auto Layout constraints and give its sizing constraint the lowest priority in the view hierarchy.
- **WinUI 3**: Use a `Grid` (not a `StackPanel`, whose children are given unlimited height) with a `RowDefinition Height="*"` for the spacer's row and `Height="Auto"` for every sibling row; the star-sized row absorbs the leftover vertical space, matching **fills-remaining-space**.

## Design Decisions

**Decision**: ViewportSpacer is a pure layout primitive: it accepts only `children` and `className`, delegates all visual styling to CSS, and relies entirely on flex layout (`flex: 1 1 0`, `min-height: 0`) for its behavior.
**Rationale**: Keeping the component's surface minimal maximizes flexibility for consuming code while making the flex-grow behavior predictable and impossible to override accidentally.
**Approved**: pending

**Decision**: Class composition always applies `vp-spacer` first and appends a caller-supplied `className` after a single space, following the common React "base class plus optional override class" pattern.
**Rationale**: This lets consuming code extend or theme the spacer without recreating the base class, and keeps the concatenation logic in one place (**class-composition**).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

This rests on the source rendering a plain `div` with no role, label, or tabindex attributes — correct, minimal markup for a purely structural element. `separation-of-concerns` passes because the component is pure presentation over `children`/`className` with no business logic; `unit-test-coverage` fails because no test exercises it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: add fills-remaining-space, root-element and assistive-tech-invisible requirements grounded in the source CSS and markup; merge the duplicate custom-class requirements into class-composition and remap their vectors; move Edge Case MUST rules into named requirements; populate tags, depends-on and related; unquote the modified date; rewrite Design Decisions in Decision/Rationale/Approved form; replace fabricated Compliance checks with a real accessibility check; correct the SwiftUI, AppKit/UIKit and WinUI 3 platform notes; state real accessibility guidance in place of "Not applicable" |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source |
