---
id: 1cdd9485-95e5-47dd-9346-224b43ce8ab9
title: DevBanner
domain: adhsdk://recipes/dev-banner
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Displays a fixed or static development preview banner with customizable message.
platforms:
- typescript
- web
tags:
- banner
- notification
- development
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# DevBanner

## Overview

DevBanner is a simple notification component that displays a development-stage message to users. It renders as a full-width banner positioned either as a fixed overlay or as part of the document flow. The component is hidden from assistive technology via `aria-hidden` and serves as a visual indicator only.

## Behavioral Requirements

- **message-text**: Component MUST render the message text provided via the `message` prop, or the default message `'Development Preview — Coming Soon!'` when `message` is `undefined` (including when the prop is omitted).
- **position-class**: Component MUST apply a CSS class reflecting the `position` prop value (`'fixed'` or `'static'`) to the container element.
- **default-position**: Component MUST default to `position: 'fixed'` when no `position` prop is provided.
- **base-class**: Component MUST always apply the base class `awt-dev-banner` to the container element, in addition to the position class and any `className` prop.
- **custom-class**: Component MUST accept and apply a `className` prop, which is appended to the component's CSS classes.
- **hidden-from-at**: Component MUST set `aria-hidden="true"` on the root element.

## Appearance

- **Container**: Non-interactive, block-level element with base class `awt-dev-banner`; the container does not intercept pointer/click events.
- **Background**: Dark, semi-transparent (near-black at roughly 40% opacity).
- **Border**: ~2pt solid, warm gold/tan, the same hue as the text.
- **Corner radius**: ~6pt.
- **Shadow/glow**: Soft two-layer gold-tinted glow around the container's edge.
- **Text**: Monospace family, ~0.85rem (relative to the root font size), medium weight, wide letter-spacing, uppercase transform, single line with no wrapping — long text overflows rather than wraps.
- **Foreground/Text color**: Warm gold/tan, matching the border.
- **Padding**: ~0.5rem vertical × 1rem horizontal.
- **Dynamic positioning class**: `awt-dev-banner--{position}` where `{position}` is either `'fixed'` or `'static'`.
  - **Fixed**: Anchored near the top of the viewport, horizontally centered, tilted -8° like a diagonal ribbon, stacked above most other content.
  - **Static**: Rendered inline in the document flow at its natural position, with the same -8° tilt, not anchored to the viewport.
- **Custom classes**: Applied via the `className` prop and appended to the class list.
- **Text content**: Renders the message string directly as a text node within the container.

## States

Not applicable: DevBanner is a non-interactive, static presentation component and does not have interactive states such as pressed, disabled, focused, or loading.

## Accessibility

The component is a non-interactive, decorative status ribbon (it disables pointer events) and is intentionally hidden from assistive technology via `aria-hidden="true"`; screen readers will not announce the banner text, which is visible to sighted users only. See **Design Decisions** for the rationale and its approval status.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dev-banner-001 | message-text | `message="Custom Alert"` | Rendered text equals `"Custom Alert"` |
| dev-banner-002 | message-text | No `message` prop provided (`undefined`) | Rendered text equals `'Development Preview — Coming Soon!'` |
| dev-banner-003 | position-class | `position="fixed"` | Container has class `awt-dev-banner--fixed` |
| dev-banner-004 | position-class | `position="static"` | Container has class `awt-dev-banner--static` |
| dev-banner-005 | default-position | No `position` prop provided | Container has class `awt-dev-banner--fixed` |
| dev-banner-006 | custom-class | `className="my-custom-class"` | Container class list includes `my-custom-class` |
| dev-banner-007 | custom-class | `className=""` (empty string) | Container class list contains only `awt-dev-banner` and the position class (no empty class token) |
| dev-banner-008 | hidden-from-at | Any props | Root element has attribute `aria-hidden="true"` |
| dev-banner-009 | base-class | `position="static"`, `className="extra"` | Container class list includes `awt-dev-banner` alongside `awt-dev-banner--static` and `extra` |
| dev-banner-010 | message-text | `message={null}` | Rendered text is empty; the default message is NOT used (the JS default parameter applies only to `undefined`) |
| dev-banner-011 | message-text | `message=""` | Rendered text is empty (container has no text content) |
| dev-banner-012 | message-text | `message="  padded  "` | Rendered text equals `"  padded  "` (leading/trailing whitespace preserved) |

## Edge Cases

- **Empty message**: `message=""` renders an empty container with no text content.
- **Null message**: `message={null}` bypasses the JS default parameter, which applies only to `undefined`, not `null`; the banner renders with no text content, the same as an empty string.
- **Undefined or omitted message**: Falls back to the default message `'Development Preview — Coming Soon!'`, since the default parameter applies to `undefined` values.
- **Null, undefined, or empty className**: Contributes no class token to the container; the rendered class list contains only the base class and the position class.
- **Whitespace in message**: Leading and trailing whitespace in the message string is preserved and rendered as-is.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `message` | `string \| undefined` | `'Development Preview — Coming Soon!'` | Text content displayed in the banner |
| `position` | `'fixed' \| 'static' \| undefined` | `'fixed'` | Controls CSS positioning behavior via class name |
| `className` | `string \| undefined` | `undefined` | Additional CSS classes applied to the root element |

## Deep Linking

Not applicable: DevBanner is a standalone notification banner and is not designed as a navigation target or deep-linkable resource.

## Localization

| String Key | Default (en) | Context |
|-----------|---------------|---------|
| `dev-banner.default-message` | `Development Preview — Coming Soon!` | Fallback text rendered when no `message` prop is supplied. The source hardcodes this string rather than resolving it from a localization resource (see Compliance: `no-hardcoded-strings`); consumers targeting non-English audiences SHOULD supply a localized `message` instead of relying on the default. |

The container's CSS applies `text-transform: uppercase` to the rendered message. This casing transform is locale-sensitive — for example, Turkish distinguishes dotted/dotless `İ`/`i` under uppercase rules that differ from other Latin-script locales — so translators should verify how their locale's uppercase form renders rather than assuming a simple ASCII mapping.

## Accessibility Options

`aria-hidden="true"` removes the banner from the accessibility tree, but it does not exempt sighted users from other display preferences while reading the banner text.

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable — the component does not animate. |
| Increase Contrast | Text SHOULD meet WCAG AA contrast; see Compliance: `contrast-ratio` (partial — the background is semi-transparent, so effective contrast depends on the underlying page content). |
| Differentiate Without Color | Not applicable — the component conveys no state through color alone. |

## Feature Flags

Not applicable: No feature flags are defined in the source code.

## Analytics

Not applicable: The component does not emit analytics events.

## Privacy

Not applicable: The component does not collect, store, or transmit any user data.

## Logging

Not applicable: The component does not emit log events.

## Platform Notes

- **React/Web**: Files `packages/web/packages/controls/src/dev-banner/DevBanner.tsx` and its co-located `styles/dev-banner.css`. Renders a `<div>` with dynamically constructed class names and `aria-hidden="true"`. Accepts a text message prop and two positional/styling props (`position`, `className`). Uses client-side directive (`'use client'`) for Next.js App Router.
- **SwiftUI**: Implement as a `ViewModifier` (e.g. `DevBannerModifier`) applied via `.overlay(alignment: .top)` for `fixed`, or embedded directly in a `VStack` for `static`. Render the message in a monospaced, uppercase, letter-spaced `Text` with a translucent dark background, gold border and foreground, rounded corners, and a soft glow (`.shadow`); apply a `-8°` `.rotationEffect` to match the ribbon tilt. Since the banner is decorative and non-interactive, apply `.accessibilityHidden(true)` and `.allowsHitTesting(false)`.
- **Compose**: Implement as a composable `DevBanner` using a `Box` overlay aligned to `Alignment.TopCenter` for `fixed` (drawn above other content), or inline in the layout flow for `static`. Style with a translucent dark background, gold border, rounded shape, monospace uppercase `Text` with `letterSpacing`, and `Modifier.graphicsLayer { rotationZ = -8f }` for the tilt. Since the banner is decorative and non-interactive, skip clickable/pointer input handling and hide it from TalkBack with `Modifier.clearAndSetSemantics {}`.
- **AppKit / UIKit**: For UIKit, use a `UIView`/`UILabel` positioned with Auto Layout constraints pinned near the top and centered horizontally for `fixed` (added to the window/overlay), or inline in the view hierarchy for `static`; apply a `CGAffineTransform(rotationAngle:)` of -8° in radians, a translucent dark background, gold border/text color, rounded corners, and a shadow-based glow. Since it is decorative and non-interactive, set `isUserInteractionEnabled = false` and `accessibilityElementsHidden = true` on the container. For AppKit, use an `NSView`/`NSTextField` with equivalent layer styling and the same -8° rotation, and call `setAccessibilityElement(false)` on the container view and its subviews to remove them from the accessibility tree.
- **WinUI 3**: Implement as a `Border`/`TextBlock` inside a `Grid` overlay pinned to the top and horizontally centered for `fixed` (e.g. `HorizontalAlignment="Center"`, `VerticalAlignment="Top"`), or inline in a `StackPanel`/`Grid` row for `static`; apply a `RotateTransform` of -8 degrees, a translucent dark background, gold border/foreground, rounded corners, and a glow effect. Since the banner is decorative and non-interactive, set `IsHitTestVisible="False"` and `AutomationProperties.AccessibilityView="Raw"` on the root element to remove it from the UIA tree. Text binds to a dependency property mirroring the `message` parameter.

## Design Decisions

**Decision**: Hide the banner from assistive technology via `aria-hidden="true"`, treating the development-preview message as a decorative, visual-only notice rather than information all users must receive.
**Rationale**: The container also sets `pointer-events: none` and is styled as a rotated ribbon/badge — evidence it is meant as passive visual chrome, not an interactive or critical alert. If the development status is later judged semantically important to all users, `aria-hidden` should be removed and an appropriate role (e.g. `role="status"`) added instead.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on `DevBanner.tsx` and `dev-banner.css`: font-size is set in `rem` (scales with root size), the default message is a hardcoded string literal with no key/resource lookup, the container renders arbitrary text as a plain JSX text node, and `white-space: nowrap` with no truncation means longer or translated text can overflow rather than wrap; the background is semi-transparent (`rgba(12, 12, 15, 0.4)`), so contrast against arbitrary underlying page content cannot be guaranteed, and `aria-hidden` is applied to a `pointer-events: none` decorative element. `separation-of-concerns` passes because `DevBanner.tsx` only joins classes and renders a static message with no business logic; `unit-test-coverage` fails because no test file exercises `DevBanner`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and added `default-position`/`base-class`; rewrote Compliance as linked catalog checks; reformatted Design Decision to Decision/Rationale/Approved; corrected the null-vs-undefined message and className edge cases with new test vectors; filled Appearance, Platform Notes, Localization, and Accessibility Options with detail grounded in `dev-banner.css`. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
