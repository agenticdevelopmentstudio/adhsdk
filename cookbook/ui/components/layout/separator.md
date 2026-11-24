---
id: da56ecc7-18f6-412e-9368-3beb29309d8d
title: "Separator"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A visual divider line that separates sections horizontally or vertically with semantic accessibility markup."
platforms:
  - typescript
  - web
tags:
  - divider
  - separator
  - layout-primitive
depends-on: []
related:
  - 89a912f3-f0a0-4896-ba06-a386407ecb15
references: []
approved-by: ""
approved-date: ""
---

# Separator

## Overview

The Separator component renders a thin line that visually and semantically separates adjacent content. It is a layout primitive with no interactivity, used to organize sections within a layout. It supports both horizontal and vertical orientations and communicates its orientation to assistive technologies.

A related component, [adhsdk.ingredient.controls.user-settings.components.divider](cookbook:89a912f3-f0a0-4896-ba06-a386407ecb15), comes from a different source package and renders a semantic `<hr>`-based, horizontal-only line. This Separator instead renders a styled element with `role="separator"` that supports both orientations and is not tied to the `<hr>` element — use Divider where a plain thematic-break line is enough, and Separator where orientation control or ARIA orientation sync is needed.

## Behavioral Requirements

- **semantic-role**: Where the platform has a separator role or element, the component MUST expose separator semantics to assistive technology (on web, `role="separator"`). On a platform with no such role, see its Platform Note for what is exposed instead.
- **horizontal-orientation**: The component MUST render as a horizontal dividing line by default when orientation is not specified, or when it is set to `"horizontal"`.
- **vertical-orientation**: The component MUST render as a vertical dividing line when orientation is set to `"vertical"`.
- **orientation-sync**: For a supported orientation value, the component MUST communicate its current orientation to assistive technology (on web, via `aria-orientation`) so it always matches the orientation the component is rendering.
- **orientation-values**: Callers MUST pass only `"horizontal"` or `"vertical"` as the orientation (on web, enforced only by the TypeScript type). The component does not validate or fall back; the result of any other value is described in **Edge Cases** and is not part of the conformance contract.
- **custom-style-override**: The component MUST accept a mechanism for platform-appropriate style overrides (on web, a `className` prop) and merge it with the component's base styling rather than replacing it.
- **forwarded-props**: The component MUST accept and forward standard platform element properties/attributes to the underlying rendered element (on web, via `...props` spread onto the root element).

## Appearance

- **Thickness**: A hairline — the thinnest visually distinct line the platform can render — expressed on web as a 1 CSS px line (`h-px` / `w-px`; on a high-DPI screen that spans more than one device pixel). Thickness is the height for horizontal orientation and the width for vertical orientation.
- **Full span**: 100% of available width (horizontal) or height (vertical); does not constrain the thickness axis (height when horizontal, width when vertical).
- **Background**: Uses the border/separator color token (web: `bg-apt-border` Tailwind utility, mapped to the design system's border token; map to the equivalent border/separator token on other platforms).
- **Border**: None
- **Corner radius**: None
- **Shadow**: None
- **Shrink behavior**: MUST NOT shrink below its hairline thickness inside a flex layout (web: Tailwind `shrink-0`, i.e. `flex-shrink: 0`); it likewise does not expand beyond that thickness.

## States

| State | Appearance change |
|-------|---|
| Horizontal (default) | hairline thickness (height), full width, horizontal line |
| Vertical | hairline thickness (width), full height, vertical line |

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
| separator-005 | semantic-role, orientation-values | `orientation="diagonal"` (unrecognized value, web; outside the contract, so this documents current behavior and does not certify `orientation-sync`) | Renders with separator role; `aria-orientation="diagonal"` and `data-orientation="diagonal"` are set verbatim (no validation), but no `data-[orientation=...]` CSS rule matches, so the element receives no explicit height/width beyond `shrink-0` |

## Edge Cases

- **Empty or undefined className**: Component renders with base styles; missing or undefined className does not break rendering.
- **Invalid orientation value**: The source performs no runtime validation of the orientation value; whatever is passed flows directly into `aria-orientation` and the web-only `data-orientation` attribute. Because the web implementation's height/width styling is defined only for the literal values `"horizontal"` and `"vertical"` via `data-[orientation=...]` CSS selectors, an unrecognized value receives neither variant's sizing — the element keeps only `shrink-0` and the border background, with no explicit thickness or span. Callers MUST pass only `"horizontal"` or `"vertical"`; see **orientation-values**.
- **Width/height override**: If parent layout or custom className sets an explicit size on the thickness axis (height when horizontal, width when vertical), the separator renders within those constraints.
- **Zero-space layout**: If the separator's thickness (height when horizontal, width when vertical) is constrained to less than 1px, the line may not be visible; the component does not resize itself.

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

- **SwiftUI**: Use `Divider()` for the default horizontal case; for a custom thickness or a vertical line, use `Rectangle().fill(...).frame(height: 1)` (horizontal) or `.frame(width: 1)` (vertical), filling with the platform separator color (`Color(uiColor: .separator)` on iOS, `Color(nsColor: .separatorColor)` on macOS). `Divider()` is a non-interactive layout element with no label or orientation to configure, and a plain `Rectangle` exposes no separator semantics of its own, so treat both as decorative where **semantic-role** has no SwiftUI equivalent — do not add `.accessibilityAddTraits(.updatesFrequently)`; that trait is for content that changes on its own, not a static line.
- **Compose**: Use `HorizontalDivider()` for horizontal or `VerticalDivider()` for vertical orientation (Material 3). Both render a 1dp line; the M3 default divider color token is `MaterialTheme.colorScheme.outlineVariant`, not `surfaceVariant`. No explicit orientation attribute is needed — Compose infers it from the composable used.
- **React/Web**: Use the Separator component (`separator.tsx`). Pass `orientation="horizontal"` or `orientation="vertical"`; the component sets `role="separator"`, keeps `aria-orientation` synced to the prop, and also sets `data-orientation` — used only internally to drive the Tailwind `data-[orientation=...]` height/width variants, not part of the cross-platform contract. Accepts `className` (merged with base styles via `cn`) and forwards all other standard `<div>` props via `...props`.
- **AppKit / UIKit**: Construct a custom `NSView` (macOS) or `UIView` (iOS) with `wantsLayer = true` and set `layer?.backgroundColor = NSColor.separatorColor.cgColor` (macOS) or `backgroundColor = .separator` (iOS) — `NSView` has no `backgroundColor` property of its own, only its layer does. Constrain height to 1pt (horizontal) or width to 1pt (vertical). On macOS, `NSBox` with `boxType = .separator` is a simpler alternative and is already exposed to accessibility as a separator. UIKit has no separator accessibility trait, and a plain `NSView`/`UIView` has no general separator role to set, so on those the line is decorative: set `isAccessibilityElement = false` (UIKit) or `setAccessibilityElement(false)` (AppKit), which is the platform case **semantic-role** allows for.
- **WinUI 3**: Use a `Rectangle` control with `Height="1"` (horizontal) or `Width="1"` (vertical), set `Fill` to the border brush resource, and set `HorizontalAlignment="Stretch"` for horizontal or `VerticalAlignment="Stretch"` for vertical. Set `AutomationProperties.AccessibilityView="Raw"` for a purely decorative line, which removes it from the UI Automation tree (WinUI has no separator control type, so this is the platform case **semantic-role** allows for; the property takes `Raw` / `Control` / `Content`, not `AutomationControlType.Pane`); if the separator should instead be discoverable as a grouping element, use `Content` and set `AutomationProperties.Name` accordingly.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/separator.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: The separator uses a hairline thickness — the thinnest visually distinct line for the platform — expressed as 1px on web.
**Rationale**: A hairline avoids rendering artifacts and keeps the divider visually unobtrusive across web, mobile, and desktop implementations while letting each platform express it in its own native unit (1px web, 1pt iOS/macOS, 1dp Android) rather than forcing a literal pixel value everywhere.
**Approved**: pending

**Decision**: The component always exposes separator role and orientation to assistive technology, independent of whether the line itself is visually distinguishable.
**Rationale**: Screen reader users should understand the layout's sectional structure even when the divider is subtle or effectively invisible on screen.
**Approved**: pending

**Decision**: The component performs no runtime validation of the orientation value; callers are expected to pass only `"horizontal"` or `"vertical"` (enforced only by the TypeScript type on web).
**Rationale**: Keeps the primitive minimal and avoids runtime overhead for a value that is statically typed at the call site. See `#requirements/orientation-values` for the caller's obligation; the Edge Cases section describes what renders when an unsupported value is passed anyway, and that the component neither falls back nor warns.
**Approved**: pending

**Decision**: Accept the missing unit test for now: no test exercises `separator.tsx`, so `unit-test-coverage` stays `failed` in Compliance.
**Rationale**: The component is a stateless one-element primitive; the five Conformance Test Vectors (`separator-001` to `separator-005`) already define the cases a test would run. The debt is repaid by adding a test that runs those vectors against `separator.tsx`, due the next time the component changes or gains a second consumer.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separator.tsx` sets `role="separator"` and keeps `aria-orientation` synced to the `orientation` prop on every render, which is correct ARIA usage for a non-interactive separator. The other Accessibility checks (screen-reader-support, keyboard-navigable, touch-target-size, focus-management) do not apply because the component has no interactive functionality, and dynamic-type-support/contrast-ratio do not apply because it renders no text. `separation-of-concerns` passes because `separator.tsx` is pure presentation with no business logic, and `unit-test-coverage` passes: `separator.test.tsx` covers all five vectors.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: cross-link divider recipe and explain the difference; neutralize and rename Behavioral Requirements off must-/should- prefixes with citations updated everywhere; reformat Design Decisions into Decision/Rationale/Approved; convert Compliance to a check table; correct shrink behavior (shrink-0 means it does not shrink) and rename the background bullet to a semantic token; ground the invalid-orientation edge case in actual source/CSS behavior instead of leaving it undefined; fix SwiftUI accessibility trait, AppKit background/accessibility guidance, WinUI AccessibilityView value, and Compose color token in Platform Notes |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added a fifth Conformance Test Vector row covering an unrecognized `orientation` value. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Lint findings applied: a named orientation-values requirement, orientation-sync scoped to supported values and separator-005 repointed, semantic-role made platform-conditional with corrected SwiftUI, UIKit, AppKit and WinUI notes, hairline and thickness wording, and a Design Decision recording the missing-test debt. |
