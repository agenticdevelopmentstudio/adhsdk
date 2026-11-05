---
id: d7a1229c-cf03-436f-8287-d99b52747510
title: ConnectorSVG
domain: adhsdk://recipes/connector-svg
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Renders SVG connector lines between referenced DOM elements with real-time
  position tracking.
platforms:
- typescript
- web
tags:
- ui
- svg
- connector
depends-on:
- adhsdk://recipes/connector-registry
related: []
references: []
approved-by: ''
approved-date: ''
---

# ConnectorSVG

## Overview

ConnectorSVG renders decorative SVG connector lines between pairs of DOM elements identified by reference. Elements are resolved by identifier through a registry supplied via an implicit context dependency rather than a prop (see **element-resolution** and the `adhsdk://recipes/connector-registry` ingredient this component depends on: a snapshot mapping id &rarr; element). The component automatically tracks element positions and recomputes connections when elements resize, the viewport scrolls, or the window resizes, batching recomputation to at most once per frame. Connections are visual-only and hidden from accessibility trees.

## Behavioral Requirements

- **svg-root**: Component MUST render an SVG element with class name `pc-connector-svg`.
- **aria-hidden**: Component MUST set `aria-hidden="true"` on the SVG element.
- **container-reference**: Component MUST accept a reference to the container element and use it as the coordinate origin for all connector calculations.
- **connector-pairs**: Component MUST accept an array of connector pairs, each with `from` and `to` string identifiers.
- **element-resolution**: Component MUST resolve each connector pair's `from` and `to` identifiers to elements using a registry (id &rarr; element lookup) supplied as an implicit dependency rather than a prop; see `adhsdk://recipes/connector-registry`.
- **line-endpoints**: For each resolvable pair, the component MUST draw a line from the center of the source element to the center of the target element.
- **center-coordinates**: The component MUST calculate the center of each element's bounding rectangle and transform coordinates relative to the container element's position (see **container-reference**).
- **unresolved-pair-omission**: If either element in a pair cannot be resolved from the registry, that connection MUST be omitted from the rendered output.
- **endpoint-circles**: Component MUST render a circle at each line endpoint (source and target).
- **source-color**: The stroke color of each connector line, and the fill color of its endpoint circles, MUST be derived from the source element's computed CSS `color` property.
- **stroke-width**: Each connector line MUST render with a 1 pixel stroke width.
- **connector-opacity**: Each connector line's stroke and each endpoint circle's fill MUST render at 0.4 opacity.
- **resize-observer-updates**: Component MUST recompute connector positions whenever any tracked element is resized, detected via ResizeObserver.
- **window-resize-updates**: Component MUST recompute connector positions whenever the window resizes.
- **scroll-updates**: Component MUST recompute connector positions when the window or any ancestor element scrolls, including scroll during the capture phase.
- **recompute-on-input-change**: Whenever the `pairs` input or the registry snapshot changes, the component MUST recompute connector geometry and re-establish position tracking for the current tracked set. The tracked set is the container element plus every element currently resolvable via the registry snapshot's identifiers.
- **raf-batching**: Component MUST batch position recomputation requests using `requestAnimationFrame` to avoid redundant calculations during rapid layout changes.
- **raf-cancellation**: If a scheduled animation frame is still pending when the component unmounts, the component MUST cancel it.
- **teardown**: Component MUST disconnect the ResizeObserver and remove its resize and scroll event listeners when unmounting.
- **empty-pairs**: When `pairs` is an empty array, the component MUST render an empty SVG (no lines or circles).
- **null-container-ref**: When the container reference is not available (`null`), the component MUST abort computation and render an empty SVG.

## Appearance

- **SVG stroke**: 1 pixel width (see **stroke-width**), opacity 0.4 (see **connector-opacity**), color inherited from source element's computed `color` property
- **SVG line**: Straight line connecting element centers
- **Endpoint circles**: Radius 3 pixels, fill color inherited from source element's computed `color` property, opacity 0.4 (see **connector-opacity**)
- **SVG class**: `pc-connector-svg` — this prefix is a fixed, canonical value for this component, not templated via `{{app_prefix}}`

## States

The component has no user-facing state (no pressed, disabled, or focused variants) and its rendering is not driven by user interaction. It does hold internal derived state: computed line and circle geometry, cached and recomputed only on layout-affecting events (see **recompute-on-input-change**, **resize-observer-updates**, **window-resize-updates**, **scroll-updates**).

## Accessibility

Not applicable: This component renders purely decorative connector lines with `aria-hidden="true"`. The lines convey no semantic information and are not interactive.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| connector-001 | svg-root, aria-hidden | frameRef pointing to valid container, pairs = [] | SVG with class "pc-connector-svg" and aria-hidden="true" |
| connector-002 | connector-pairs, element-resolution, line-endpoints | frameRef, pairs = [{from: "el1", to: "el2"}], both elements registered | One line drawn from center of el1 to center of el2 |
| connector-003 | unresolved-pair-omission | frameRef, pairs = [{from: "el1", to: "missing"}] | No line rendered for that pair |
| connector-004 | endpoint-circles | frameRef, pairs = [{from: "el1", to: "el2"}] | Two circles (r=3) rendered, one at each line endpoint |
| connector-005 | source-color | frameRef, source element has computed color = "#ff0000", pairs = [{from: "el1", to: "el2"}] | Line rendered with stroke "#ff0000"; both endpoint circles rendered with fill "#ff0000" |
| connector-006 | center-coordinates, container-reference | frameRef at (100, 200), element at (150, 250) with width=100 height=50 | Line endpoint for that element computed at (100, 75) relative to frameRef origin |
| connector-007 | resize-observer-updates | frameRef, one element resizes from 100×50 to 200×100 | Line endpoints redrawn to new center positions |
| connector-008 | raf-batching | Rapid resize events fire in succession | Only one recomputation occurs via single requestAnimationFrame call |
| connector-009 | raf-cancellation | requestAnimationFrame scheduled, component unmounts before frame executes | No render occurs after unmount |
| connector-010 | window-resize-updates | frameRef, window resize event fires | Connector positions are recomputed |
| connector-011 | scroll-updates | frameRef, scroll event fires on an ancestor element during the capture phase | Connector positions are recomputed |
| connector-012 | teardown | Component unmounts | ResizeObserver is disconnected; window resize and scroll listeners are removed |
| connector-013 | null-container-ref | Container reference resolves to `null` | No computation occurs; SVG renders with no lines or circles |
| connector-014 | empty-pairs | pairs = [] | SVG renders with no lines or circles |
| connector-015 | recompute-on-input-change | pairs prop changes from [{from: "el1", to: "el2"}] to [{from: "el1", to: "el3"}], or the registry snapshot adds "el3" | ResizeObserver is re-established for the new tracked set (frame + el1 + el3) and geometry is recomputed for the new pairs |
| connector-016 | stroke-width, connector-opacity | frameRef, pairs = [{from: "el1", to: "el2"}] | Line rendered with strokeWidth=1 and strokeOpacity=0.4; both endpoint circles rendered with fillOpacity=0.4 |
| connector-017 | center-coordinates | frame at (0, 0), element with width=0 height=0 at (50, 50) | Center computed as (50, 50); connector line still renders using that point as an endpoint |

## Edge Cases

- **Empty pairs array**: See **empty-pairs**.
- **Missing registry entries**: See **unresolved-pair-omission** — an identifier not found in the registry snapshot causes silent omission, not an error.
- **Null container ref**: See **null-container-ref**.
- **Rapid layout changes**: See **raf-batching** — multiple resize or scroll events firing in quick succession are deduplicated so only one recomputation happens per frame.
- **Unmount during scheduled animation frame**: See **raf-cancellation** — a pending frame callback is cancelled to prevent operations on unmounted DOM.
- **Element with zero dimensions**: An element with zero width or height still yields a valid center — for a 0×0 rect at (x, y), the center is (x, y) — and its connector line still renders using that point (see **connector-017**).

## Configuration

Not applicable: The component exposes no configuration options. Behavior is entirely determined by the `frameRef` and `pairs` props, and the registry snapshot provided by the context.

## Deep Linking

Not applicable: This component renders decorative connectors without interactive affordances or internal state that could be deep-linked.

## Localization

Not applicable: The component contains no user-facing strings.

## Accessibility Options

Not applicable: This component is marked as decorative and hidden from accessibility trees. Accessibility display options do not apply.

## Feature Flags

Not applicable: The component has no feature flag gating.

## Analytics

Not applicable: This component is non-interactive and renders no events that warrant analytics instrumentation.

## Privacy

Not applicable: This component does not collect, store, or transmit any data.

## Logging

Not applicable: The component has no significant logging needs. Internal RAF scheduling is an implementation detail.

## Platform Notes

- **React/Web**: Reference implementation uses `requestAnimationFrame` for batched updates, `ResizeObserver` for element tracking, and event listeners on `window` for resize/scroll. Key files: `ConnectorSVG.tsx` with hooks for effect cleanup and state management. Accepts a reference (`RefObject<HTMLDivElement | null>`) to the container element (**container-reference**) and resolves connector pair identifiers via `useRegistrySnapshot()` from an implicit React Context registry (`adhsdk://recipes/connector-registry`), not a prop.
- **SwiftUI**: No native connector component exists. Implement using a custom `Canvas` view that draws `Path` elements with `stroke()` modifiers. Track element frames using `GeometryReader` and anchor preferences to establish connection endpoints, and recompute geometry on layout/size-change notifications (e.g. `onGeometryChange`), batching updates to at most once per frame rather than polling with a timer.
- **Compose**: Implement using a `Canvas` composable that draws connector paths with `drawLine()`. Obtain element positions via layout measurement callbacks or `onGloballyPositioned` modifiers, and recompute on those layout-change callbacks, batching updates to at most once per frame (e.g. via `withFrameNanos`) rather than on a fixed timer.
- **AppKit / UIKit**: Implement using `CAShapeLayer` with `CGPath` (or the platform's native path type — `NSBezierPath` on AppKit, `UIBezierPath` on UIKit). Create a custom view subclassing `NSView` (macOS) or `UIView` (iOS) that recomputes connector geometry when its layout changes (`layout`/`layoutSubviews`, or a bounds-changed notification for scroll views), batching updates to at most once per frame — gated to the next layout pass, not a continuous per-frame poll. Compute element frames using `convert(_:to:)` to transform coordinates relative to the connector view's bounds.
- **WinUI 3**: Implement using a `Canvas` with `Line` and `Ellipse` shapes bound to computed connector endpoints (a `LineSegment` requires a `PathGeometry`/`Path`, so prefer the simpler `Line`/`Ellipse` primitives for a straight connector). Recompute positions on `LayoutUpdated` or `SizeChanged` events for tracked elements, batching to at most one recomputation per `CompositionTarget.Rendering` tick rather than a `DispatcherTimer`.

## Design Decisions

**Decision**: Position updates are batched via `requestAnimationFrame` rather than continuous polling or timers.
**Rationale**: Ensures computations occur at most once per display refresh cycle, minimizing layout thrashing and aligning with browser rendering constraints (see **raf-batching**).
**Approved**: pending

**Decision**: Connector stroke and fill colors are derived from the source element's computed `color` style rather than an explicit color prop, and the SVG is marked `aria-hidden="true"`.
**Rationale**: Deriving color from the source element keeps the interface minimal while allowing per-connector color customization without new props (see **source-color**). The lines are purely decorative and add no semantic value to the document structure; they support visual understanding but do not convey information necessary for keyboard or screen reader users, so hiding them from the accessibility tree is correct (see **aria-hidden**).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

The source renders standard `<svg>`, `<line>`, `<circle>`, and `<g>` elements with `aria-hidden="true"` and no custom or invalid ARIA attributes, so its markup passes semantic-markup. separation-of-concerns is partial because the geometry computation, `requestAnimationFrame` batching, and `ResizeObserver`/scroll tracking are all implemented inline inside `ConnectorSVG.tsx` rather than extracted into standalone functions or hooks, while unit-test-coverage is failed because no test file exercises this component at all.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; promoted edge-case MUSTs (empty-pairs, null-container-ref, unresolved registry entries) to named requirements; added recompute-on-input-change and defined the tracked-element set; declared the connector-registry dependency in depends-on and Overview; reformatted Design Decisions into Decision/Rationale/Approved triplets; replaced the Compliance placeholder with a table listing semantic-markup; split source-color into separate stroke/fill wording and promoted stroke-width and opacity to requirements; fixed the connector-006 coordinate math; added test vectors for window resize, scroll, teardown, null container ref, empty pairs, input-change recompute, stroke/opacity, and zero-dimension elements; made container-reference platform-neutral; reconciled Platform Notes with the no-timer/no-polling design decision and corrected the AppKit/UIKit and WinUI 3 API references; clarified States to describe cached derived geometry instead of "stateless"; documented the pc- class prefix as fixed rather than templated |

