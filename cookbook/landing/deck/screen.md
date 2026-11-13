---
id: 07c437af-a291-4356-bd83-c896bd4facde
title: "Screen"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Full-viewport-height container for deck slides with optional background glow and content alignment."
platforms:
  - typescript
  - web
tags:
  - deck
  - layout
  - viewport
depends-on:
  - b341dd02-fbcb-4da8-b2b6-897807b4ebbc
related:
  - 05930e64-fa82-49ef-b50d-22d87fa7d182
references:
  - https://developer.mozilla.org/en-US/docs/Web/HTML/Element/section
  - https://developer.mozilla.org/en-US/docs/Web/CSS/vh
approved-by: ""
approved-date: ""
---

# Screen

## Overview

Screen is a full-viewport-height container component for use in a scrollable or snap-scrolled deck of slides. Each screen serves as a snap point and can hold arbitrary content. The component supports optional background glow and flexible vertical alignment of content within the viewport height.

## Behavioral Requirements

- **render-children**: Component MUST render its children.
- **render-semantic-element**: Component MUST render as either `<section>` (landmark) or `<div>` (non-landmark) based on the `as` prop.
- **apply-base-class**: Component MUST apply the `lp-screen` class to the root element.
- **center-alignment**: Component MUST apply the `lp-screen--center` class when `align` is set to `'center'`.
- **merge-classname**: Component MUST merge the optional `className` prop with the base classes (`lp-screen`, and `lp-screen--center` when applicable) by concatenation; it does not deduplicate, so a `className` that repeats a base class produces a class list with that token twice.
- **render-glow**: Component MUST render a `<Glow />` component as the first child when `glow` is `true`, and MUST NOT render it when `glow` is `false` or omitted.
- **accept-id**: Component MUST apply the optional `id` prop to the root element when provided.
- **snap-point-viewport-height**: Component MUST establish itself as a full-viewport-height scroll-snap point via the `lp-screen` class, which sets `min-height: 100vh` and `scroll-snap-align: start` (`css/base.css`).

## Appearance

Component applies layout and styling through CSS classes (`lp-screen`, `lp-screen--center`). The `lp-screen` class also fixes the screen's minimum height and its scroll-snap participation — see **snap-point-viewport-height**. Beyond that contract, visual appearance depends on the host stylesheet. Component itself does not prescribe:

- Corner radius
- Padding
- Typography
- Colors
- Borders
- Shadows

These are all delegated to the host's CSS implementation.

## States

Not applicable: Screen is a static container with no interactive states.

## Accessibility

- **Semantic role**: When rendered as `<section>` (`as: 'section'`), the element only becomes a `region` landmark once it has an accessible name; without one, assistive technology exposes it as a generic section, not a landmark. When rendered as `<div>` (`as: 'div'`), there is no implicit role. Role depends solely on the `as` prop — CSS classes and stylesheets have no effect on ARIA semantics.
- **Label requirement**: Screen accepts no `aria-label`, `aria-labelledby`, or other pass-through attribute on its root element beyond `id`, `align`, `as`, `className`, and `glow`. Consequently, a `<section>` rendered by Screen has no accessible name through Screen's own props — hosts that need a labelled landmark region MUST provide that name outside Screen's public API.
- **Content accessibility**: Screen does not define accessibility for its children; child components are responsible for their own accessible implementation.

## Conformance Test Vectors

| ID | Requirement | Input | Expected |
|----|-------------|-------|----------|
| screen-001 | render-children | `children: <p>Content</p>` | Element tree includes the `<p>` element |
| screen-002 | render-semantic-element | `as: 'section'` or omitted | Root element is `<section>` |
| screen-003 | render-semantic-element | `as: 'div'` | Root element is `<div>` |
| screen-004 | apply-base-class | Any props | Root element has `lp-screen` in its class list |
| screen-005 | center-alignment | `align: 'center'` | Root element has both `lp-screen` and `lp-screen--center` in class list |
| screen-006 | center-alignment | `align: 'top'` or omitted | Root element has `lp-screen` class but not `lp-screen--center` |
| screen-007 | merge-classname | `className: 'custom-class'` | Root element has `lp-screen` and `custom-class` in class list |
| screen-008 | merge-classname | `className: 'lp-screen extra'` | Root element's class attribute contains `lp-screen` twice (e.g. `lp-screen lp-screen extra`); a DOM `classList` treats the duplicate token as a no-op |
| screen-009 | render-glow | `glow: true` | First child of root element is the Glow component |
| screen-010 | render-glow | `glow: false` or omitted | No Glow component is rendered |
| screen-011 | render-glow | `glow: true, children: null` | First child of root element is still the Glow component; Glow's presence does not depend on `children` |
| screen-012 | accept-id | `id: 'slide-1'` | Root element has `id="slide-1"` |
| screen-013 | snap-point-viewport-height | Any props | The `lp-screen` class's computed style resolves to `min-height: 100vh` and `scroll-snap-align: start` |
| screen-014 | render-children | `children: null` or `children: undefined` | Root element renders with no additional content beyond any Glow output |
| screen-015 | render-children | `children: []` (empty array) | Root element renders with no additional content, same as `null` or `undefined` |

## Edge Cases

- **Null or undefined children**: The root element always renders regardless of `children`; there is no case where the component itself does not render. React renders `null`/`undefined` children as nothing, so the rendered output is the root element plus, if `glow: true`, the Glow component. See screen-014.
- **Empty children array**: An empty array renders the same as `null` or `undefined` — nothing — so the root element renders with no additional content. See screen-015.
- **Glow with no children**: Component MUST render Glow when `glow: true`, independent of whether `children` is null, undefined, or empty; Glow's presence depends only on the `glow` prop. See screen-011.
- **Multiple class collisions**: If `className` contains `lp-screen` or `lp-screen--center`, the merge logic (see **merge-classname**) concatenates all classes without deduplication, producing a class list with duplicate tokens; a DOM `classList` treats duplicate tokens as a no-op, and host stylesheet SHOULD rely on CSS cascade to manage any remaining style conflicts. See screen-008.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `align` | `'top' \| 'center'` | `'top'` | Vertical alignment of content within the viewport. |
| `as` | `'section' \| 'div'` | `'section'` | Semantic element type for the root. |
| `className` | `string` | — | Additional CSS class to merge with base classes. |
| `glow` | `boolean` | `false` | Whether to render a Glow component behind the content. |
| `id` | `string` | — | Optional HTML id attribute for the root element. |
| `children` | `ReactNode` | — | Required content to render inside the screen. |

## Deep Linking

Not applicable: Screen is a container component with no built-in route or deep linking support. Deep linking behavior is the responsibility of the host application and the content within each screen.

## Localization

Not applicable: Screen is a structural container with no user-facing text or strings.

## Accessibility Options

Not applicable: Screen does not animate and does not respond to motion preferences.

## Feature Flags

Not applicable: Screen does not implement feature flags.

## Analytics

Not applicable: Screen does not emit or track events.

## Privacy

Not applicable: Screen does not collect, store, or transmit user data.

## Logging

Not applicable: Screen does not implement logging.

## Platform Notes

- **React/Web** (source): Screen is a functional component that conditionally renders a semantic element (`<section>` or `<div>`) based on the `as` prop. It applies BEM-style classes (`lp-screen`, `lp-screen--center`) for styling and optionally renders the Glow component as the first child. Layout and visual appearance are entirely CSS-driven, defined in a separate stylesheet (`css/base.css` per the source comment).

- **SwiftUI**: Inside a `ScrollView` with `.scrollTargetBehavior(.paging)`, size each screen with `.containerRelativeFrame(.vertical)` so it occupies exactly one viewport height and acts as a paging/snap point. Conditionally overlay a background glow view (via `.background()` or a custom shape) when the glow property is true. Apply conditional padding or alignment modifiers to implement the center vs. top alignment behavior.

- **Compose**: Inside a `LazyColumn`, size each screen item with `Modifier.fillParentMaxHeight()` — `fillMaxHeight()` has no bounded height to fill inside a scrolling container — so each screen is exactly one viewport tall, or use a `VerticalPager` page directly. Conditionally render a canvas-based glow in the background using `drawBehind { }`. Use `contentAlignment` to position children at the top or center of the box.

- **AppKit / UIKit**: Use a container view (or view controller) that holds the glow layer and the content as subviews, rather than subclassing `NSView`/`UIView`. Configure it with `translatesAutoresizingMaskIntoConstraints = false`, constrained to fill the parent view's bounds, with an optional background glow `CALayer` or subview placed behind the content. Use Auto Layout constraints or a `UIStackView`/`NSStackView` to position child views according to the alignment property.

- **WinUI 3**: Size each screen to the height of the enclosing `ScrollViewer`'s viewport (e.g. bind `Height` to `ScrollViewer.ViewportHeight` or a converted `ActualHeight`) rather than `Height="*"` on a bare `Grid`, since star sizing only applies inside `RowDefinition`/`ColumnDefinition`. Build the glow with a Composition radial gradient brush (`CompositionRadialGradientBrush`) or a XAML `RadialGradientBrush`, not `BlurEffect`, which is a WPF-only API with no WinUI 3 equivalent. Use `VerticalAlignment` to position child elements at the top (`Top`) or center (`Center`).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/deck/Screen.tsx` | unverified |

## Design Decisions

**Decision**: Visual appearance is delegated entirely to CSS (base classes `lp-screen` and `lp-screen--center`) rather than exposed through component props.
**Rationale**: Keeps component logic minimal and lets host applications customize styling without modifying the component code.
**Approved**: pending

**Decision**: `glow` is an optional boolean prop (default `false`) rather than leaving ordering to the host.
**Rationale**: Placing a `<Glow />` before or after Screen's other children is order-sensitive; making `glow` a prop lets Screen guarantee the correct order automatically. The default is `false` because lighting every screen in a deck is a host-level design decision, not a component default.
**Approved**: pending

**Decision**: The `as` prop lets Screen render as either a landmark (`<section>`) or a generic container (`<div>`).
**Rationale**: Gives the host control over information architecture without requiring an extra wrapper element around Screen.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Partial because Screen correctly switches between `<section>` and `<div>` based on the `as` prop (`Screen.tsx`), but exposes no `aria-label`/`aria-labelledby` prop and forwards no other attributes to its root, so a host using `as: 'section'` as a landmark cannot give that element an accessible name through Screen's own API. `separation-of-concerns` passes because `Screen.tsx` is pure presentation over props with no business logic of its own, and `unit-test-coverage` passes because `deck.test.tsx` renders it directly and asserts on its id, class, tag, and glow-ordering behavior.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and elevated render-glow/accept-id to MUST, added glow as a dependency and deck as related, unquoted the modified date, added a snap-point-viewport-height requirement and test vector for the min-height/scroll-snap-align CSS contract, resolved the as-default and null/empty-children contradictions and dropped the untestable invalid-align/invalid-as edge cases, corrected merge-classname to describe concatenation without deduplication and added a class-collision test vector, corrected the section-landmark wording in Accessibility and added a Compliance table, reformatted Design Decisions into decision/rationale/approved triples, and fixed the invalid WinUI 3 APIs, vague SwiftUI/Compose guidance, and AppKit/UIKit subclassing note in Platform Notes |
| 1.0.0 | 2026-09-22 | — | Initial creation |
