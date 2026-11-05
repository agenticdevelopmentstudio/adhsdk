---
id: b5b27bc2-99b2-469e-9dd4-e446b0157444
title: Reveal
domain: adhsdk://recipes/reveal
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Fades and lifts content into place as it enters the viewport.
platforms:
- typescript
- web
tags:
- animation
- viewport
- scroll
depends-on: []
related:
- adhsdk://recipes/band
- adhsdk://recipes/bleed
- adhsdk://recipes/flow
- adhsdk://recipes/flow-hero
- adhsdk://recipes/site-footer
- adhsdk://recipes/site-header
references:
- https://developer.mozilla.org/en-US/docs/Web/API/Intersection_Observer_API
approved-by: ''
approved-date: ''
---

# Reveal

## Overview

Reveal is a wrapper component that fades and lifts its children into place as they enter the viewport. It uses the Intersection Observer API to detect when the wrapped element becomes visible and transitions it from a hidden state to a visible state. The component preserves accessibility by rendering content in its visible (finished) state by default; JavaScript enhancements only apply the hidden state after the component mounts.

## Behavioral Requirements

- **visible-by-default**: The initial render MUST be the resting (visible) state. Arming only happens after mount, so a reader with JavaScript disabled never sees a hidden state.
- **viewport-entry-detection**: The component MUST use the Intersection Observer API to detect when the wrapped element enters the viewport.
- **arm-below-fold**: On mount, the component MUST check whether the element's top offset is already less than `window.innerHeight`. If so, the component MUST NOT create an Intersection Observer and MUST NOT apply the armed indicator — the element is treated as already revealed. Otherwise the component arms and creates the observer.
- **delayed-reveal-margin**: The Intersection Observer MUST be configured with a bottom root margin that delays the reveal until the element's top edge is 12% of the viewport height above the bottom (`rootMargin: '0px 0px -12% 0px'`). A negative bottom margin shrinks the observer's root rect, so this fires later than an unmodified (0-margin) observer would — not earlier.
- **one-way-reveal**: The component MUST disconnect the Intersection Observer immediately after the first intersection is detected; the element MUST NOT re-arm or re-hide when scrolled past.
- **armed-state-indicator**: While armed (observing but not yet shown), the wrapper MUST carry an observable marker distinguishing it from the resting state (see Platform Notes for the web implementation).
- **base-state-indicator**: The wrapper MUST always carry an observable base-state marker, independent of armed/revealed state (see Platform Notes for the web implementation).
- **classname-prop**: The component MAY accept an optional prop to let consumers add custom classes to the wrapper element.
- **children-forwarding**: The component MUST render its children as-is within the wrapper element.

## Appearance

- **Corner radius**: None (transparent wrapper)
- **Padding**: None (transparent wrapper)
- **Font**: Inherited from children
- **Background**: Transparent (no background applied by component)
- **Foreground/Text**: Inherited from children
- **Border**: None
- **Shadow**: None
- **Min/Max size**: None (size determined by children)
- **Resting state**: opacity 1, no transform
- **Armed state**: opacity 0, `translateY(22px)`
- **Transition**: opacity and transform, 0.7s, `cubic-bezier(0.2, 0.7, 0.3, 1)`

## States

| State | Appearance change |
|-------|------------------|
| Default (visible on page load) | Opacity 1, no transform; no animation occurs |
| Armed (below viewport, observing) | Opacity 0, `translateY(22px)`; awaiting intersection |
| Revealed (intersected viewport) | Transitions from armed to resting values over 0.7s (`cubic-bezier(0.2, 0.7, 0.3, 1)`, opacity and transform); observer disconnects |

## Accessibility

- **Role/trait**: None on the wrapper; the component is transparent and forwards semantic meaning to children.
- **Label requirements**: No label needed; the wrapper carries no semantic role.
- **Announce state changes**: Not applicable; state transitions are visual only and do not affect assistive technology.
- **Minimum tap target**: Not applicable; the component itself is not interactive.
- **Graceful degradation**: With JavaScript disabled, the server-rendered resting state is what ships, so content is never lost. The component does not guard against a missing `IntersectionObserver` global before constructing one in **arm-below-fold**; see Compliance.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| reveal-001 | visible-by-default | Component with children, JavaScript enabled, mounted but before any observer fires | Children render immediately in the resting state (full opacity, no transform) |
| reveal-002 | arm-below-fold | Component with children initially below viewport (top offset ≥ `window.innerHeight`), mounted | Armed indicator is applied to the wrapper (web: `lp-reveal--armed`); children are in the hidden state defined for the platform |
| reveal-003 | viewport-entry-detection, one-way-reveal | Component in armed state, user scrolls element into viewport | Intersection Observer fires; observer disconnects; armed indicator is removed (web: `lp-reveal--armed` removed); transition to the resting/visible state occurs |
| reveal-004 | one-way-reveal | Component revealed, user scrolls element out of viewport | Observer stays disconnected; element remains visible; no re-arming or re-hiding occurs |
| reveal-005 | armed-state-indicator | Component mounted below viewport | Armed indicator (web: `lp-reveal--armed` class) is present on the wrapper |
| reveal-006 | base-state-indicator | Component at any state | Base indicator (web: `lp-reveal` class) is always present on the wrapper |
| reveal-007 | classname-prop | Component below viewport at mount, with a custom class supplied | Custom class is included in the wrapper's class list alongside the base indicator and, while armed, the armed indicator |
| reveal-008 | children-forwarding | Component with children `<img src="..." />`, `<p>Text</p>` | Children are rendered as-is within the wrapper |
| reveal-009 | arm-below-fold | Component already on screen at mount (top offset less than `window.innerHeight`) | No Intersection Observer is created; no armed indicator is applied; children remain visible throughout the session |
| reveal-010 | delayed-reveal-margin | Component armed, user scrolls until the element's top edge is 12% of the viewport height above the bottom edge | Intersection Observer fires at that point; an unmodified (0-margin) observer would already have fired earlier, at the element's first visible pixel |

## Edge Cases

- **Already on screen at mount**: see **arm-below-fold**. This prevents the blank-out flicker that would occur if the element were armed and then immediately intersected.
- **Root margin offset**: see **delayed-reveal-margin**.
- **Null ref**: If the ref is null when the effect runs (component was unmounted before effect execution), the effect returns early and does not proceed with observation.
- **Multiple child updates**: The component re-renders if children change. The ref to the wrapper element is stable; the observer (if created) remains active unless already disconnected by intersection.
- **Window resize**: The Intersection Observer automatically adapts to viewport changes; no resize listener is needed.
- **Cleanup on unmount**: The cleanup function disconnects the observer if one was created, preventing memory leaks.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| children | ReactNode | (required) | The content to reveal as it enters the viewport |
| className | string | undefined | Optional custom CSS class to add to the wrapper element alongside `lp-reveal` |

## Deep Linking

Not applicable: Reveal is a visual enhancement wrapper with no navigable state or deep-link target.

## Localization

Not applicable: Reveal contains no user-facing text strings.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | `prefers-reduced-motion` media query in CSS neutralizes the transform and transition; the component still arms and unarms (state changes occur), but the element appears instantaneously without animation. Handled entirely in CSS, not in JavaScript. |
| Increase Contrast | Not applicable; Reveal does not render text or interactive elements. |
| Differentiate Without Color | Not applicable; Reveal does not use color alone to convey state. |

## Feature Flags

Not applicable: Reveal is a foundational component with no opt-in or opt-out behavior.

## Analytics

Not applicable: Reveal is a transparent wrapper with no user interaction or event of its own.

## Privacy

Not applicable: Reveal does not collect, store, or transmit any user data.

## Logging

Not applicable: Reveal does not emit diagnostic events or logs.

## Platform Notes

- **TypeScript/React (source)**: Implemented in `packages/web/packages/landing/src/flow/Reveal.tsx`. Wraps children in a `div` with ref forwarding; `useState` tracks the armed/shown flags; `useEffect` runs the Intersection Observer logic described above. The wrapper always carries the `lp-reveal` base class, and while armed it also carries `lp-reveal--armed`. Custom classes from the `className` prop are merged with the base classes by filtering out empty strings and joining, producing a clean class list for CSS selectors. The animation values (opacity, translate, duration, easing) live in `flow.css`, not in the component.
- **SwiftUI**: Track the armed/shown state with `@State`, driven by the `onScrollVisibilityChange(threshold:)` modifier rather than manual `GeometryReader` polling. Render children in the resting state by default; apply the fade-plus-vertical-offset transition (matching the values in Appearance) only once armed and only after the modifier reports the view has become visible.
- **Compose**: Track position with `Modifier.onGloballyPositioned`, comparing the reported bounds against the viewport to decide whether to arm. Do not use `AnimatedVisibility` for the resting state, since its default `enterTransition` starts hidden and would violate **visible-by-default**; instead drive `Modifier.graphicsLayer` (alpha and translationY) from the same armed/shown state, defaulting to the visible values.
- **AppKit / UIKit**: Observe scroll position via the same intersection-style check (element bounds against the enclosing scroll view's visible rect), evaluated on scroll and on layout. Apply the fade-plus-vertical-offset transition with `CABasicAnimation` on `opacity`/`transform`, matching the web timing values. Render the view in the resting (visible) state by default; only add the hidden/armed state after the check determines it starts below the fold.
- **WinUI 3**: Use `FrameworkElement.EffectiveViewportChanged` to detect when the element's effective viewport changes, rather than polling `ActualHeight` or the parent scroll position. Apply a `Storyboard` with `DoubleAnimation` on `Opacity` and `TranslateTransform.Y`, matching the web timing values. Set the control's default state to fully visible (`Opacity="1"`, no translate) so it appears immediately; apply the hidden/armed state only if `EffectiveViewportChanged` reports the element starts below the fold.

## Design Decisions

**Decision**: Render children in the visible, resting state on initial render.
**Rationale**: Hiding content by default and revealing it conditionally is a content-loss bug if JavaScript fails; a reader with JS disabled sees the finished page, not a blank one. See **visible-by-default**.
**Approved**: pending

**Decision**: Disconnect the Intersection Observer immediately after the first intersection; a reveal is a one-way transition.
**Rationale**: Re-hiding content that has scrolled past is a well-known anti-pattern that makes pages feel broken. See **one-way-reveal**.
**Approved**: pending

**Decision**: Read `prefers-reduced-motion` from a CSS media query rather than in JavaScript.
**Rationale**: This keeps a single source of truth: if the media query in the stylesheet omits animation, the browser's preference is respected without re-reading it in code. The component still arms and unarms; the transition is neutralized.
**Approved**: pending

**Decision**: Configure the Intersection Observer with a bottom root margin of -12% of the viewport height.
**Rationale**: This delays the reveal until the element's top edge is 12% of the viewport height above the bottom — later than an unmodified (0-margin) observer, which would already fire at the element's first visible pixel — so the fade-in reads as a deliberate reveal rather than firing the instant the element's edge appears. See **delayed-reveal-margin**.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | passed | Accessibility |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | partial | Reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`reduced-motion` is grounded in the `prefers-reduced-motion` media query in `flow.css`, which neutralizes both the opacity and the transform of the armed state; `graceful-degradation` is partial because `Reveal.tsx` always renders the resting state when JavaScript never runs, but constructs a new `IntersectionObserver` unconditionally once armed, with no guard for an environment where the API is undefined. separation-of-concerns passes because `Reveal.tsx` owns only observation and armed/revealed class-toggling, leaving the fade-and-lift animation and the reduced-motion override to `flow.css` and rendering children as-is. unit-test-coverage is partial: `flow.test.tsx`'s `Reveal` block covers only the resting-visible render and the armed-class toggle; no test drives the `IntersectionObserver` itself, so `arm-below-fold`, `delayed-reveal-margin`, and `one-way-reveal` are untested.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Renamed early-reveal-margin to delayed-reveal-margin and corrected direction: -12% bottom margin fires later, not earlier. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and fixed RFC-2119 casing, promoted edge-case details (arm-below-fold, early-reveal-margin) into named requirements with test vectors and corrected two test-vector mappings, added concrete Appearance values from `flow.css`, made requirements platform-neutral and moved web class names into the React/Web platform note, aligned native platform notes to real viewport APIs and a consistent fade-plus-translate animation, reformatted Design Decisions and dropped the implementation-detail entry, replaced the Compliance section with a real table, filled `related` with sibling landing/flow recipes and switched frontmatter dates to bare ISO values, corrected the summary's unsupported performance claim, and corrected an Accessibility claim that contradicted the source's lack of an IntersectionObserver-availability guard |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from web source |
