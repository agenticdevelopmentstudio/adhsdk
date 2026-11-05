---
id: da56ecc7-18f6-412e-9368-3beb29309d8d
title: Separator
domain: adhsdk://recipes/separator
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A visual divider line that separates sections horizontally or vertically
  with semantic accessibility markup.
platforms:
- typescript
- web
tags:
- divider
- separator
- layout-primitive
depends-on: []
related:
- adhsdk://recipes/divider
references: []
approved-by: ''
approved-date: ''
---

# Separator

## Overview

The Separator component renders a thin line that visually and semantically separates adjacent content. It is a layout primitive with no interactivity, used to organize sections within a layout. It supports both horizontal and vertical orientations and communicates its orientation to assistive technologies.

A related component, `adhsdk://recipes/divider`, comes from a different source package and renders a semantic `<hr>`-based, horizontal-only line. This Separator instead renders a styled element with `role="separator"` that supports both orientations and is not tied to the `<hr>` element — use Divider where a plain thematic-break line is enough, and Separator where orientation control or ARIA orientation sync is needed.

## Behavioral Requirements

- **semantic-role**: The component MUST expose separator semantics to assistive technology (on web, `role="separator"`).
- **horizontal-orientation**: The component MUST render as a horizontal dividing line by default when orientation is not specified, or when it is set to `"horizontal"`.
- **vertical-orientation**: The component MUST render as a vertical dividing line when orientation is set to `"vertical"`.
- **orientation-sync**: The component MUST communicate its current orientation to assistive technology (on web, via `aria-orientation`) so it always matches the orientation the component is rendering.
- **custom-style-override**: The component MUST accept a mechanism for platform-appropriate style overrides (on web, a `className` prop) and merge it with the component's base styling rather than replacing it.
- **forwarded-props**: The component MUST accept and forward standard platform element properties/attributes to the underlying rendered element (on web, via `...props` spread onto the root element).

## Appearance

- **Thickness**: A hairline — the thinnest visually distinct line the platform can render — expressed as 1px on web (height for horizontal orientation; width for vertical orientation).
- **Full span**: 100% of available width (horizontal) or height (vertical); does not constrain the orthogonal dimension.
- **Background**: Uses the border/separator color token (web: `bg-apt-border` Tailwind utility, mapped to the design system's border token; map to the equivalent border/separator token on other platforms).
- **Border**: None
- **Corner radius**: None
- **Shadow**: None
- **Shrink behavior**: MUST NOT shrink below its hairline thickness inside a flex layout (web: Tailwind `shrink-0`, i.e. `flex-shrink: 0`); it likewise does not expand beyond that thickness.

## States

| State | Appearance change |
|-------|---|
| Horizontal (default) | 1px height, full width, horizontal line |
| Vertical | 1px width, full height, vertical line |

## Accessibility

- **Role**: The component exposes separator semantics to assistive technology (web: `role="separator"`), identifying itself as a separating element.
- **Orientation**: **orientation-sync** MUST hold at all times, communicating to screen reader users whether the separator runs horizontally or vertically.
- **No interactive state**: The separator is not keyboard-navigable and does not receive focus; it is an inert presentational element.
- **Label not required**: No accessible name is needed because the separator's purpose is visual layout, not a labeled interactive control.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|---|---|---|
| separator-001 | semantic-role, horizontal-orientation | No props (defaults) | Renders with separator role and horizontal orientation exposed to assistive technology; on web: `<div role="separator" aria-orientation="horizontal" ...>` with 1px height and full width |
| separator-002 | vertical-orientation, orientation-sync | `orientation="vertical"` | Renders with separator role and vertical orientation exposed to assistive technology; on web: `<div role="separator" aria-orientation="vertical" ...>` with 1px width and full height |
| separator-003 | custom-style-override | `className="custom-class"` (web) | Rendered element includes `custom-class` in its className alongside base styles |
| separator-004 | forwarded-props | `data-testid="my-sep" id="sep1"` (web) | Rendered element includes `data-testid="my-sep"` and `id="sep1"` |
| separator-005 | semantic-role, orientation-sync | `orientation="diagonal"` (unrecognized value, web) | Renders with separator role; `aria-orientation="diagonal"` and `data-orientation="diagonal"` are set verbatim (no validation), but no `data-[orientation=...]` CSS rule matches, so the element receives no explicit height/width beyond `shrink-0` |

## Edge Cases

- **Empty or undefined className**: Component renders with base styles; missing or undefined className does not break rendering.
- **Invalid orientation value**: The source performs no runtime validation of the orientation value; whatever is passed flows directly into `aria-orientation` and the web-only `data-orientation` attribute. Because the web implementation's height/width styling is defined only for the literal values `"horizontal"` and `"vertical"` via `data-[orientation=...]` CSS selectors, an unrecognized value receives neither variant's sizing — the element keeps only `shrink-0` and the border background, with no explicit thickness or span. Callers MUST pass only `"horizontal"` or `"vertical"`; see **orientation-sync**.
- **Width/height override**: If parent layout or custom className sets explicit dimensions orthogonal to the separator's orientation, the separator renders within those constraints.
- **Zero-space layout**: If the separator's orthogonal dimension is constrained to less than 1px, the line may not be visible; the component does not resize itself.

## Configuration

Not applicable: The Separator component has no configuration options. Its appearance is fully determined by the orientation prop and CSS classes.

## Deep Linking

Not applicable: The Separator is a layout primitive without its own screen or navigation target.

## Localization

Not applicable: The Separator contains no user-facing text.

## Accessibility Options

Not applicable: The Separator is a stateless, non-interactive element and does not respond to accessibility display options (motion, contrast, color differentiation).

## Feature Flags

Not applicable: The Separator component has no feature flags.

## Analytics

Not applicable: The Separator is a passive layout element with no user interaction to track.

## Privacy

Not applicable: The Separator does not collect, store, or transmit any data.

## Logging

Not applicable: The Separator component has no logging behavior.

## Platform Notes

- **SwiftUI**: Use `Divider()` for the default horizontal case; for a custom thickness or a vertical line, use `Rectangle().fill(Color.border).frame(height: 1)` (horizontal) or `.frame(width: 1)` (vertical). `Divider()` is already skipped by VoiceOver as a non-interactive layout element, which matches the source's non-interactive semantics — do not add `.accessibilityAddTraits(.updatesFrequently)`; that trait is for content that changes on its own, not a static line.
- **Compose**: Use `HorizontalDivider()` for horizontal or `VerticalDivider()` for vertical orientation (Material 3). Both render a 1dp line; the M3 default divider color token is `MaterialTheme.colorScheme.outlineVariant`, not `surfaceVariant`. No explicit orientation attribute is needed — Compose infers it from the composable used.
- **React/Web**: Use the Separator component (`separator.tsx`). Pass `orientation="horizontal"` or `orientation="vertical"`; the component sets `role="separator"`, keeps `aria-orientation` synced to the prop, and also sets `data-orientation` — used only internally to drive the Tailwind `data-[orientation=...]` height/width variants, not part of the cross-platform contract. Accepts `className` (merged with base styles via `cn`) and forwards all other standard `<div>` props via `...props`.
- **AppKit / UIKit**: Construct a custom `NSView` (macOS) or `UIView` (iOS) with `wantsLayer = true` and set `layer?.backgroundColor = NSColor.separatorColor.cgColor` (macOS) or `backgroundColor = .separator` (iOS) — `NSView` has no `backgroundColor` property of its own, only its layer does. Constrain height to 1pt (horizontal) or width to 1pt (vertical). On macOS, `NSBox` with `boxType = .separator` is a simpler alternative and is already exposed to accessibility as a separator; if using a plain `NSView`/`UIView` instead, set an explicit accessibility role for "separator" — do not omit accessibility markup, since exposing separator semantics (**semantic-role**) is a requirement, not optional.
- **WinUI 3**: Use a `Rectangle` control with `Height="1"` (horizontal) or `Width="1"` (vertical), set `Fill` to the border brush resource, and set `HorizontalAlignment="Stretch"` for horizontal or `VerticalAlignment="Stretch"` for vertical. Set `AutomationProperties.AccessibilityView="Raw"` for a purely decorative line (the property takes `Raw` / `Control` / `Content`, not `AutomationControlType.Pane`); if the separator should instead be discoverable as a grouping element, use `Content` and set `AutomationProperties.Name` accordingly.

## Design Decisions

**Decision**: The separator uses a hairline thickness — the thinnest visually distinct line for the platform — expressed as 1px on web.
**Rationale**: A hairline avoids rendering artifacts and keeps the divider visually unobtrusive across web, mobile, and desktop implementations while letting each platform express it in its own native unit (1px web, 1pt iOS/macOS, 1dp Android) rather than forcing a literal pixel value everywhere.
**Approved**: pending

**Decision**: The component always exposes separator role and orientation to assistive technology, independent of whether the line itself is visually distinguishable.
**Rationale**: Screen reader users should understand the layout's sectional structure even when the divider is subtle or effectively invisible on screen.
**Approved**: pending

**Decision**: The component performs no runtime validation of the orientation value; callers are expected to pass only `"horizontal"` or `"vertical"` (enforced only by the TypeScript type on web).
**Rationale**: Keeps the primitive minimal and avoids runtime overhead for a value that is statically typed at the call site. See **orientation-sync** and the Edge Cases section for the defined appearance when an unsupported value is passed anyway.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`separator.tsx` sets `role="separator"` and keeps `aria-orientation` synced to the `orientation` prop on every render, which is correct ARIA usage for a non-interactive separator. The other Accessibility checks (screen-reader-support, keyboard-navigable, touch-target-size, focus-management) do not apply because the component has no interactive functionality, and dynamic-type-support/contrast-ratio do not apply because it renders no text. `separation-of-concerns` passes because `separator.tsx` is pure presentation with no business logic, and `unit-test-coverage` fails because no test exercises it — its only consumer, `user-card.tsx`, itself has no test.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: cross-link divider recipe and explain the difference; neutralize and rename Behavioral Requirements off must-/should- prefixes with citations updated everywhere; reformat Design Decisions into Decision/Rationale/Approved; convert Compliance to a check table; correct shrink behavior (shrink-0 means it does not shrink) and rename the background bullet to a semantic token; ground the invalid-orientation edge case in actual source/CSS behavior instead of leaving it undefined; fix SwiftUI accessibility trait, AppKit background/accessibility guidance, WinUI AccessibilityView value, and Compose color token in Platform Notes |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added a fifth Conformance Test Vector row covering an unrecognized `orientation` value. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
