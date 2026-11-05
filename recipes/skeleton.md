---
id: 4a3761c5-5809-43c9-9a45-6f91fe82ae97
title: Skeleton
domain: adhsdk://recipes/skeleton
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A loading placeholder component that displays a pulsing block to indicate
  content is loading.
platforms:
- typescript
- web
tags:
- loading
- placeholder
- animation
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Skeleton

## Overview

The Skeleton component is a loading placeholder that displays a pulsing block. It signals to users that content is being loaded. The component is a simple wrapper around a `<div>` that applies animation and styling via CSS classes. Size the skeleton by passing a `className` prop or using inline styles.

## Behavioral Requirements

- **render-as-div**: Component MUST render as an HTML `<div>` element.
- **slot-attribute**: Component MUST render with a `data-slot="skeleton"` attribute.
- **pulsing-animation**: Component MUST apply a continuous pulsing opacity animation to signal a loading state.
- **rounded-corners**: Component MUST apply a medium corner radius.
- **surface-background**: Component MUST apply the secondary surface background color token.
- **class-merge**: Component MUST accept and merge a `className` prop with its built-in classes via a class composition utility (`cn()` in the source, backed by `clsx` and `tailwind-merge`).
- **html-passthrough**: Component MUST accept and forward standard HTML `div` attributes (`id`, `style`, `aria-*`, etc.) to the rendered element.
- **sized-by-props**: Component MAY accept sizing through the `className` prop or an inline `style` prop, allowing consumers to define width and height.
- **reduced-motion-support**: Component MUST allow the pulsing animation to be suppressed under the user's reduced-motion preference; a consumer supplies a variant-scoped override (e.g. `motion-reduce:animate-none`) through `className`, and class-merge (see **class-merge**) preserves it alongside the built-in `animate-pulse` class rather than stripping either.
- **aria-hidden-while-loading**: Component SHOULD be rendered with `aria-hidden="true"`, forwarded via html-passthrough (see **html-passthrough**), while a parent element carries `aria-busy="true"`, so assistive technology reads the container's busy state instead of the placeholder's empty markup.

## Appearance

- **Background**: Secondary surface color token (Material 3 `surface-container-high` role, injected at runtime by the active theme)
- **Corner radius**: Medium — 0.8× the design system's base radius token (0.4rem / 6.4px with this repo's default `--radius: 0.5rem`)
- **Animation**: Continuous pulsing opacity animation — 2s duration, `cubic-bezier(0.4, 0, 0.6, 1)` easing, opacity cycles 1 → 0.5 → 1, infinite (Tailwind's default `pulse` keyframe, unmodified by this design system)
- **Padding**: None — the element is block-level with no padding
- **Border**: None
- **Shadow**: None
- **Min/Max size**: None (sized by the consumer via `className` or inline styles)

## States

| State | Appearance change |
|-------|-------------------|
| Default | Pulsing opacity animation applied continuously |
| Reduced motion (opt-in) | Static — no pulse — when the consumer applies a `motion-reduce:animate-none` override via `className`; not automatic (see **reduced-motion-support**) |

Not applicable: The Skeleton component is a static, non-interactive loading indicator with no focus, pressed, or disabled states.

## Accessibility

- **Role**: Presentational; the component assigns no ARIA role itself (see **aria-hidden-while-loading**).
- **Label requirements**: None from the component itself. A consumer applying **aria-hidden-while-loading** SHOULD also set `aria-busy="true"` on the parent that shows the placeholder, so assistive technology reads the container's busy state rather than the skeleton's empty markup.
- **Announce state changes**: Delegated to the parent's `aria-busy` state; the skeleton itself announces nothing.
- **Keyboard interaction**: Not applicable. This is a non-interactive element.

The component renders a plain `div` with no `aria-hidden`, `aria-busy`, or role attribute of its own; per **aria-hidden-while-loading**, suppressing the placeholder or announcing loading status is left entirely to the consumer (see Design Decisions).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|-------|--------|-------|----------|
| skeleton-001 | render-as-div, slot-attribute | Render `<Skeleton />` | Element in DOM with tag name `DIV` and `data-slot="skeleton"` attribute |
| skeleton-002 | pulsing-animation, rounded-corners, surface-background | Render `<Skeleton />` and inspect computed style | Computed `animation-name` is not `"none"` (the pulse keyframe is applied), computed `border-radius` equals the medium radius token's resolved value, and computed `background-color` equals the secondary surface token's resolved value |
| skeleton-003 | class-merge, pulsing-animation, rounded-corners | Render `<Skeleton className="w-12 h-12" />` | Computed width/height reflect the custom sizing classes, while computed `animation-name` and `border-radius` still show the built-in pulsing animation and corner radius |
| skeleton-004 | html-passthrough | Render `<Skeleton id="loader" data-testid="skeleton-1" />` | Element has attributes `id="loader"` and `data-testid="skeleton-1"` |
| skeleton-005 | html-passthrough | Render `<Skeleton style={{ width: '100px', height: '100px' }} />` | Element has `style` attribute with specified width and height |
| skeleton-006 | pulsing-animation | Render `<Skeleton />` and read the computed `animation-name` and its `@keyframes` | `animation-name` resolves to a pulse keyframe whose rule cycles opacity `1 → 0.5 → 1`, with `animation-iteration-count: infinite` |
| skeleton-007 | reduced-motion-support | Render `<Skeleton className="motion-reduce:animate-none" />` under a `prefers-reduced-motion: reduce` media context | Computed `animation-name` is `"none"` |
| skeleton-008 | aria-hidden-while-loading, html-passthrough | Render `<Skeleton aria-hidden="true" />` inside a parent with `aria-busy="true"` | The skeleton element has `aria-hidden="true"`; the parent's `aria-busy="true"` is unaffected |

## Edge Cases

- **Empty className prop**: When `className` is `undefined`, `null`, or an empty string, the component SHOULD apply only its built-in pulsing animation, corner radius, and surface background (see **pulsing-animation**, **rounded-corners**, **surface-background**).
- **Invalid CSS class names in className**: The component MUST accept any string in the `className` prop without validation or error handling. Invalid class names are silently passed through; rendering behavior depends on whether the CSS classes exist.
- **Very large dimensions**: No minimum or maximum size constraints exist. The component renders at any size specified via `className` or `style`.
- **Rendering in disabled or read-only contexts**: Not applicable. The component is not interactive.
- **Animation performance**: The pulsing animation runs continuously by default. Under `prefers-reduced-motion`, the component does not disable itself automatically; a consumer suppresses it via the **reduced-motion-support** override.

## Configuration

Not applicable: The Skeleton component accepts no configuration options beyond `className` and standard HTML attributes.

## Deep Linking

Not applicable: The Skeleton component is a presentational UI element with no navigation or deep-linking semantics.

## Localization

Not applicable: The Skeleton component renders no text and does not require localization.

## Accessibility Options

The source does not read `prefers-reduced-motion` itself. The pulsing animation is not suppressed automatically; per **reduced-motion-support**, a consumer opts in via a `motion-reduce:animate-none` override in `className`, which class-merge preserves alongside the built-in `animate-pulse` class.

## Feature Flags

Not applicable: The Skeleton component uses no feature flags or conditional rendering.

## Analytics

Not applicable: The Skeleton component triggers no analytics events.

## Privacy

Not applicable: The Skeleton component collects, stores, or transmits no user data.

## Logging

Not applicable: The Skeleton component produces no logging output.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/ui/src/components/skeleton.tsx`. Renders a `<div data-slot="skeleton">` with the Tailwind classes `animate-pulse rounded-md bg-apt-surface-2`, merged with any consumer `className` via `cn()` (`clsx` + `tailwind-merge`). Standard HTML `div` attributes are spread onto the element. `animate-pulse` is Tailwind's default 2s `cubic-bezier(0.4, 0, 0.6, 1)` infinite opacity pulse (1 → 0.5 → 1); `rounded-md` resolves to `0.4rem` (0.8× this design system's `--radius: 0.5rem` token); `bg-apt-surface-2` maps to the Material 3 `surface-container-high` role. Reduced motion is opt-in: pass `motion-reduce:animate-none` in `className`.
- **SwiftUI**: Use a `RoundedRectangle(cornerRadius:)` filled with the surface-2 token color. Animate opacity between `1.0` and `0.5` with `.animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: …)`, gated on `@Environment(\.accessibilityReduceMotion)` — when reduce motion is on, hold opacity at `1.0` instead of animating.
- **Compose**: Use a `Box` with a `Modifier.background(...)` and `RoundedCornerShape(...)`, animating alpha via `rememberInfiniteTransition().animateFloat(initialValue = 1f, targetValue = 0.5f, animationSpec = infiniteRepeatable(tween(...), RepeatMode.Reverse))`. Check the system animator duration scale (`Settings.Global.ANIMATOR_DURATION_SCALE` via `ContentResolver`) and skip the animation when it is zero.
- **AppKit / UIKit**: Use `NSView` (AppKit) or `UIView` (UIKit) with a `CABasicAnimation` on `opacity` (`1.0` → `0.5`), ~1s duration, `autoreverses: true`, `repeatCount: .infinity`. Check `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` (AppKit) or `UIAccessibility.isReduceMotionEnabled` (UIKit) and skip adding the animation when true.
- **WinUI 3**: Use a `Border` or `Rectangle` with `CornerRadius`, animating `Opacity` with a `DoubleAnimation` (`From="1.0"`, `To="0.5"`, `AutoReverse="True"`, `RepeatBehavior="Forever"`). Check `UISettings.AnimationsEnabled` and skip the animation when false. Reference Fluent 2 surface tokens for the background color.

## Design Decisions

**Decision**: Use a continuous pulsing opacity animation rather than background-color shifts or position changes.
**Rationale**: Opacity pulsing is a simple, performant animation that does not distort layout.
**Approved**: pending

**Decision**: Provide no built-in width or height; sizing is left entirely to the consumer via `className` or inline styles.
**Rationale**: Keeps the component flexible across use cases (e.g. a small avatar skeleton vs. a large content block) without the component needing to know the shape of what it stands in for.
**Approved**: pending

**Decision**: The component sets no ARIA role and does not apply `aria-hidden` itself; a consumer opts in via **aria-hidden-while-loading** (`aria-hidden="true"` on the skeleton, `aria-busy="true"` on the parent).
**Rationale**: The skeleton is a purely visual placeholder with no semantics of its own; composing the loading announcement belongs to the container that knows what content is loading, using the html-passthrough mechanism the component already provides.
**Approved**: pending

**Decision**: The pulsing animation is not suppressed automatically under the user's reduced-motion preference; a consumer opts in via a `motion-reduce:animate-none` override in `className`.
**Rationale**: The source does not read `prefers-reduced-motion` itself, but class-merge (backed by `clsx` and `tailwind-merge`) preserves a variant-scoped override alongside the built-in `animate-pulse` class, so the capability exists without changing the component's default appearance.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

The source applies Tailwind's `animate-pulse` unconditionally with no `prefers-reduced-motion` handling (reduced-motion: failed), and assigns no ARIA role or `aria-hidden` of its own, relying on the consumer for the aria-hidden/aria-busy contract described in **aria-hidden-while-loading** (semantic-markup: partial). `separation-of-concerns` passes because `skeleton.tsx` is a pure presentational div with no business logic, and `unit-test-coverage` fails because no test exercises it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: made requirements/appearance/vectors platform-neutral, moving Tailwind class names into the React/Web platform note; renamed requirements to subject-only kebab-case; reformatted Design Decisions into Decision/Rationale/Approved form; replaced the "Not applicable" Compliance section with a table; added a consumer-side aria-hidden-while-loading requirement (the component-side ARIA question stays open); added a reduced-motion-support requirement and test vector; fixed nonexistent/mismatched Platform Notes APIs (SwiftUI, Compose); corrected frontmatter `modified` quoting |
| 1.0.1 | 2026-09-22 | Claude Haiku 4.5 | Fix Reduce Motion marker; clarify screen-reader gap |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source code |
