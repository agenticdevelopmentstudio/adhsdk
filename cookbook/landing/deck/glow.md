---
id: b341dd02-fbcb-4da8-b2b6-897807b4ebbc
title: "Glow"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Decorative visual element that renders a glow effect; purely visual with no interaction or semantic meaning."
platforms:
  - typescript
  - web
tags:
  - visual
  - decorative
depends-on:
  - fae23662-e69b-4472-9c7d-049feadf1211
  - 07c437af-a291-4356-bd83-c896bd4facde
related:
  - 05930e64-fa82-49ef-b50d-22d87fa7d182
references: []
approved-by: ""
approved-date: ""
---

# Glow

## Overview

The Glow component is a purely decorative visual element that renders a styled `<div>` with a glow effect. It is excluded from accessibility trees (`aria-hidden="true"`) and serves only as visual enhancement. Visual appearance is entirely managed through CSS classes (base class `lp-glow` plus optional additional classes). When nested inside a centered screen (the hero), the glow's vertical offset is derived from the hero's own `--lp-hero-pad-top` and `--lp-hero-pad-bottom` custom properties (see the hero ingredient) rather than a hardcoded constant. Outside a hero, its default `top` offset reads `--lp-screen-pad-top`, a custom property owned by the Screen ingredient ([adhsdk.ingredient.landing.deck.screen](cookbook:07c437af-a291-4356-bd83-c896bd4facde)), so a host that overrides that property moves the glow with it.

## Behavioral Requirements

- **render-as-div**: Component MUST render a `<div>` element.
- **aria-hidden**: Component MUST set `aria-hidden="true"` on the rendered element.
- **classname-prop**: Component MUST accept an optional `className` prop (`string | undefined`).
- **base-class**: Component MUST always apply the `lp-glow` class to the rendered element.
- **combine-classnames**: The rendered element's class list MUST equal `lp-glow` plus the tokens of `className`, with no empty tokens.

## Appearance

- **Corner radius**: `border-radius: 50%` — combined with equal width and height, this renders a full circle.
- **Padding**: None — the `lp-glow` CSS class declares no padding.
- **Font**: Not applicable (element contains no text)
- **Background**: `background: var(--lp-glow, radial-gradient(circle, rgba(216, 216, 216, 0.1), transparent 65%))` — a soft light-gray radial gradient at 10% opacity, fading to transparent by 65% of the circle's radius.
- **Foreground/Text**: Not applicable (element contains no text)
- **Border**: None — the `lp-glow` CSS class declares no border.
- **Shadow**: None — the `lp-glow` CSS class declares no `box-shadow`.
- **Min/Max size**: Fixed `width: 62rem` and `height: 62rem`. Positioned `absolute`, `left: 50%`, `transform: translate(-50%, -50%)`, `z-index: -1`, `pointer-events: none`. Default vertical offset is `top: calc(var(--lp-screen-pad-top, clamp(5.5rem, 14svh, 9rem)) + 9rem)`; inside a hero (`.lp-screen--center`) it is instead `top: calc(50% + (var(--lp-hero-pad-top, 6.5rem) - var(--lp-hero-pad-bottom, var(--lp-dock-clear, 0px))) / 2)`.

## States

Not applicable: This component is purely decorative and stateless; it does not enter any interactive states.

## Accessibility

Not applicable: The component is explicitly hidden from accessibility trees via `aria-hidden="true"` and carries no semantic role or purpose for assistive technologies.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| glow-001 | render-as-div | None | Component renders as HTML `<div>` element |
| glow-002 | aria-hidden | None | Rendered element includes `aria-hidden="true"` |
| glow-003 | base-class | None | Rendered element has class 'lp-glow' |
| glow-004 | combine-classnames | `className="custom-glow"` | Rendered element has classes 'lp-glow' and 'custom-glow' |
| glow-005 | combine-classnames | `className=""` | Rendered element has class 'lp-glow' only (empty string filtered) |
| glow-006 | combine-classnames | `className={undefined}` | Rendered element has class 'lp-glow' only (undefined filtered) |
| glow-007 | classname-prop, combine-classnames | No className prop | Rendered element has class 'lp-glow' only |
| glow-008 | combine-classnames | `className="a b"` | Rendered element's class attribute is `lp-glow a b`; class list contains the tokens `lp-glow`, `a`, and `b` |
| glow-009 | combine-classnames | `className="   "` (whitespace only) | Rendered element's class attribute is `lp-glow` followed by the whitespace-only string; the browser's class-attribute tokenizer resolves this to the single class-list token `lp-glow` |

## Edge Cases

- **Undefined className**: Falsy; filtered from the combined class list. Element renders with 'lp-glow' only.
- **Empty string className**: Empty string is falsy and filtered. Element renders with 'lp-glow' only.
- **Whitespace-only className**: The string is truthy, so it is not filtered. The rendered `class` attribute becomes `class="lp-glow   "`; a browser's class-attribute tokenizer splits on ASCII whitespace and discards empty tokens, so this resolves to the single token `lp-glow`.
- **Multi-token className**: Each whitespace-separated token supplied in `className` (e.g. `"a b"`) is preserved as its own token in the rendered class list, alongside `lp-glow`.

## Configuration

Not applicable: The component accepts only an optional `className` prop; it has no configurable options or variants.

## Deep Linking

Not applicable: The component is a decorative visual element with no navigational or deep-linking capability.

## Localization

Not applicable: The component contains no text or user-facing strings.

## Accessibility Options

Not applicable: The component is explicitly hidden from accessibility trees and does not respond to accessibility display options.

## Feature Flags

Not applicable: No feature flags control the rendering or visibility of this component.

## Analytics

Not applicable: The component does not emit or track analytics events.

## Privacy

Not applicable: The component does not collect, store, or transmit data.

## Logging

Not applicable: The component does not emit diagnostic logs.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/landing/src/deck/Glow.tsx` as a functional component. Exports a `Glow` function accepting `{ className?: string }`. Combines 'lp-glow' base class with the optional className prop using `[...].filter(Boolean).join(' ')`. The rendered `<div>` is always `aria-hidden`. Visual styling is delegated entirely to the `.lp-glow` rule in `packages/web/packages/landing/src/css/base.css`, with the hero variant's positioning offset derived from the hero's padding custom properties.

- **SwiftUI**: Implement using a transparent `View` with a `RadialGradient` or layered `Canvas` to create the glow effect. Apply `.accessibilityHidden(true)` to exclude from VoiceOver and `.allowsHitTesting(false)` to keep it non-interactive. Match the web values: a circle 62rem across (992pt at a 16px root), filled with a radial gradient from `Color(red: 216/255, green: 216/255, blue: 216/255).opacity(0.1)` at the centre to clear at 65% of the radius (`endRadius` of half the diameter). Centre it horizontally, place it behind the content (`.zIndex(-1)` or `.background`), and offset it from the top by the screen's top padding plus 9rem, or, inside a hero, by half the difference between the hero's top and bottom padding added to the screen's vertical centre.

- **Compose**: Use a `Box` or `Canvas` composable with `Brush.radialGradient` to produce the glow: colour `Color(0xFFD8D8D8)` at 10% alpha at the centre, fading to transparent at 65% of the radius, with no blur. Size it as a fixed 62rem circle (992.dp at a 16px root), centre it horizontally, draw it behind the content (a lower `zIndex`), and offset it from the top by the screen's top padding plus 9rem (inside a hero, centre it on the content as the web rule does). Apply `Modifier.clearAndSetSemantics {}` to hide the purely decorative node from accessibility services.

- **AppKit / UIKit**: On macOS, create an `NSView` subclass with `CAGradientLayer` (radial) or custom drawing for the glow (a 62rem circle, 992pt at a 16px root, with a radial gradient from `NSColor`/`UIColor` white-gray `#D8D8D8` at 10% alpha to clear at 65% of the radius, centred horizontally, placed behind sibling views, and offset from the top by the screen's top padding plus 9rem), call `setAccessibilityElement(false)`, and override `hitTest(_:)` to return `nil` so the view never intercepts clicks. On iOS, use a `UIView` with `CAGradientLayer` or similar, set `isAccessibilityElement = false`, `accessibilityElementsHidden = true`, and `isUserInteractionEnabled = false`.

- **WinUI 3**: Render a `Border` or `Grid` with a `RadialGradientBrush` to create the glow effect: `#D8D8D8` at 10% opacity at the centre, transparent at 65% of the radius, in a fixed circle 62rem across (992 effective pixels at a 16px root), centred horizontally, placed behind the content (a lower `Canvas.ZIndex`), and offset from the top by the screen's top padding plus 9rem. Set `IsHitTestVisible="False"` to prevent interaction. Apply `AutomationProperties.AccessibilityView="Raw"` to remove it from the automation tree (`IsOffscreenBehavior` does not remove an element from the tree).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/deck/Glow.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: The `aria-hidden="true"` attribute is fixed and non-configurable.
**Rationale**: The component has no semantic purpose for assistive technology; there is no case where it should be exposed to the accessibility tree.
**Approved**: pending

**Decision**: Visual appearance is delegated entirely to CSS (base class `lp-glow` plus an optional caller-supplied `className`) rather than exposed through component props.
**Rationale**: Decouples visual design from component logic: visual changes stay in the stylesheet, not in the component's props or logic.
**Approved**: pending

**Decision**: Inside a hero, the glow's vertical offset is computed from the hero's own `--lp-hero-pad-top` / `--lp-hero-pad-bottom` custom properties rather than a hardcoded constant.
**Rationale**: Keeps the glow visually aligned with the hero's content as hero padding changes, so the two measurements cannot drift apart.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`semantic-markup` is `passed` because the source (`Glow.tsx`) sets `aria-hidden` directly on the rendered `<div>`, correctly using ARIA to hide this purely decorative element from the accessibility tree. `separation-of-concerns` is `passed` because the component is pure presentation with no children and no logic beyond a class-name join; `unit-test-coverage` is `passed` because `deck.test.tsx` renders `Glow` directly and covers every vector (glow-001 to 009).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-11-14 | Mike Fullerton | Named --lp-screen-pad-top and Screen as a dependency, removed blur guidance and the hero/related duplicate, gave concrete native geometry and colour values, and fixed the path, Decision wording and Compliance prose. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, named the exact hero padding custom properties and added the hero ingredient as a dependency, linked hero and deck as related, filled in concrete CSS values in Appearance, split Design Decisions into decision/rationale/approved triples, added a Compliance table, corrected the whitespace-only edge case and added multi-token/whitespace-only test vectors, rephrased combine-classnames as an observable outcome, and fixed unsupported/nonexistent APIs in the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
