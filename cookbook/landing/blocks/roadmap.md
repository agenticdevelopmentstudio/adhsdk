---
id: e7060a14-3f66-429a-9ea5-288f1fe5a76f
title: "Roadmap"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Container separating planned features visually from shipped ones, with optional label."
platforms:
  - typescript
  - web
tags:
  - landing
  - layout
  - roadmap
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Roadmap

## Overview

A layout container that visually separates a roadmap section (planned or future features) from other content. The component wraps an eyebrow label and child content in a dedicated container, ensuring structural separation rather than relying on prose caveats. The eyebrow label is optional; when absent, no span element is rendered to avoid empty markup and unintended visual spacing.

## Behavioral Requirements

- **render-container**: Component MUST render a div with class `lp-roadmap` as the root element.
- **render-eyebrow-when-present**: Component MUST render a span with class `lp-eyebrow` containing the `eyebrow` prop's value whenever `eyebrow` is any value other than `undefined` (including `null`, `""`, `false`, or any other ReactNode).
- **eyebrow-omitted-when-absent**: Component MUST NOT render an eyebrow span element when the `eyebrow` prop is exactly `undefined` (prop omitted).
- **render-children**: Component MUST render all child content within the root container.
- **eyebrow-precedes-children**: Component MUST render the eyebrow span (when present) before `children` within the root container.

## Appearance

- **Container class**: `lp-roadmap` — styling applied via CSS class
- **Eyebrow class**: `lp-eyebrow` — applied to optional label span when rendered
- **Spacing**: Managed by stylesheet; no inline padding or margin specified in component

## States

Not applicable: Roadmap is a static layout container with no interactive states or internal state transitions.

## Accessibility

- **Role**: Container (implicit `div` semantics) — no explicit role required for a layout wrapper.
- **Eyebrow label**: Renders as a bare `<span className="lp-eyebrow">` with no ARIA role or label association (no `role="group"`/`aria-labelledby`) tying it to the children that follow; it is a decorative visual label, not a semantic heading or landmark (see Design Decisions). It SHOULD still be text content or an accessible ReactNode so any text it carries is exposed to assistive technology like adjacent inline text.
- **Child content**: Component does not impose accessibility requirements on children; children remain independently accessible.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| roadmap-001 | render-container | No props (only children) | Root div with class `lp-roadmap` rendered |
| roadmap-002 | render-eyebrow-when-present | eyebrow="Planned Agents" | Span with class `lp-eyebrow` containing "Planned Agents" rendered inside container |
| roadmap-003 | eyebrow-omitted-when-absent | eyebrow={undefined} or eyebrow prop omitted | No `.lp-eyebrow` element rendered; container div rendered directly with children |
| roadmap-004 | render-children | children={<span>Test content</span>} | Span containing "Test content" rendered inside roadmap container |
| roadmap-005 | render-eyebrow-when-present, render-children, eyebrow-precedes-children | eyebrow="Planned", children={<div>List</div>} | Eyebrow span rendered first, then children div, both inside roadmap container |
| roadmap-006 | render-eyebrow-when-present | eyebrow={null} | `.lp-eyebrow` span rendered (empty content) because `null` is not `undefined` |
| roadmap-007 | render-eyebrow-when-present | eyebrow="" | `.lp-eyebrow` span rendered with empty text content |

## Edge Cases

- **Undefined eyebrow**: When eyebrow is `undefined` (or the prop is omitted), no `.lp-eyebrow` span is rendered — see **eyebrow-omitted-when-absent**. This prevents empty markup and unwanted spacing caused by an empty `<span className="lp-eyebrow"></span>`.
- **Null eyebrow**: When eyebrow is `null`, the span is still rendered — see **render-eyebrow-when-present** — because `null` is not `undefined`. React displays no visible content for a `null` child, so the span appears empty but is present in the markup.
- **Empty-string eyebrow**: When eyebrow is `""`, the span is rendered — see **render-eyebrow-when-present** — with no visible text content, but the span element and its styling still occupy markup.
- **Falsy non-undefined eyebrow (e.g. `false`, `0`)**: Same as `null` and `""` — any value other than `undefined` renders the span per **render-eyebrow-when-present**; only `undefined` triggers omission.
- **Multiple or complex children**: Component renders all children as-is; no validation or transformation is applied.
- **No children**: Component renders the container and optional eyebrow with no child content inside.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `eyebrow` | `ReactNode` (optional) | `undefined` | Optional label rendered in a `<span className="lp-eyebrow">` above `children`. Omitted entirely from markup when `undefined`; rendered (possibly empty) for any other value. |
| `children` | `ReactNode` (required) | — | Content rendered inside the `.lp-roadmap` container, after the eyebrow. |

## Deep Linking

Not applicable: Roadmap is a layout container, not a navigable destination or page section that would require deep linking support.

## Localization

Not applicable: Component contains no user-facing strings; text content is provided via the eyebrow prop and child nodes by the parent.

## Accessibility Options

Not applicable: Component is a static layout container with no animated transitions, motion-dependent interactions, color-dependent indicators, or interactive state feedback that would require Reduce Motion, Increase Contrast, or Differentiate Without Color support.

## Feature Flags

Not applicable: Component has no feature flag gating; it is always available when imported.

## Analytics

Not applicable: Component is a container with no user interaction or state changes to track.

## Privacy

Not applicable: Component stores no data, makes no network requests, and transmits no information.

## Logging

Not applicable: Component has no internal state, lifecycle events, or error conditions that would warrant logging.

## Platform Notes

- **TypeScript/React/Web**: Files `packages/web/packages/landing/src/blocks/Roadmap.tsx`. Renders a `div` with class `lp-roadmap` and conditionally renders an optional `span` with class `lp-eyebrow`. When eyebrow prop is undefined, the span element is omitted entirely rather than rendered empty to avoid unintended layout gaps.
- **SwiftUI**: Use a `VStack` with optional top section containing a `Text` view styled as an eyebrow label. Use `@ViewBuilder` or conditional rendering (`if eyebrow != nil { ... }`) to omit the label section entirely when no eyebrow is provided, preserving layout spacing.
- **Compose**: Use a `Column` with optional top `Text` composable for the eyebrow, conditionally rendered. Omit the eyebrow composable entirely when not provided to prevent layout shifts from empty slots.
- **AppKit / UIKit**: Use `NSStackView` (AppKit, vertical axis) or `UIStackView` (UIKit, vertical axis). Add an optional `NSTextField` (AppKit) or `UILabel` (UIKit) for the eyebrow label as the first arranged view, removing it from the stack when no eyebrow is provided rather than hiding it invisibly.
- **WinUI 3**: Use a `StackPanel` with vertical orientation. Add an optional `TextBlock` at the top for the eyebrow label, removing it entirely from the panel's Children when no eyebrow is provided to avoid vertical spacing artifacts from an empty element.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Roadmap.tsx` | unverified |

## Design Decisions

**Decision**: Omit the eyebrow `<span className="lp-eyebrow">` entirely when the `eyebrow` prop is `undefined`, rather than rendering an empty element.
**Rationale**: Structural separation should be visible and intentional — a reader who sees the eyebrow knows the section is labeled, and its absence means there is no label. An invisible empty span would create a layout gap the HTML source cannot explain, making the component harder to debug and test.
**Approved**: pending

**Decision**: The component does not validate or transform child content; it simply wraps `children` as given.
**Rationale**: Parent components are responsible for ensuring children are appropriate for a roadmap section; adding validation here would duplicate concerns owned by the caller.
**Approved**: pending

**Decision**: The eyebrow span carries no ARIA role or label association (no `role="group"`/`aria-labelledby`) tying it to the children that follow.
**Rationale**: The eyebrow is a decorative visual label styled via `.lp-eyebrow`, not a heading or landmark; treating a bare `<span>` as one would overstate its semantics. Screen reader users encounter the eyebrow's own text (when present) and the children as ordinary sibling content within the `.lp-roadmap` div.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Font scaling and color contrast are governed by the `.lp-roadmap`/`.lp-eyebrow` stylesheet, which `Roadmap.tsx` does not include, so those two checks cannot be confirmed from the source alone, and semantic-markup is partial because the component renders plain `div`/`span` elements with no incorrect ARIA usage but also no role or label association tying the eyebrow to its children, per the eyebrow's decorative-label design decision. `Roadmap.tsx` is a trivial pure-presentation wrapper over props with no logic beyond the `eyebrow === undefined` branch (separation-of-concerns passed); `blocks-argument.test.tsx` directly exercises both the eyebrow-present and eyebrow-absent cases (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case and update all citations, add eyebrow-precedes-children requirement, fix null/empty-string eyebrow contradiction and add their test vectors, correct roadmap-003's assertion to check for the eyebrow class rather than any span, document decorative (non-semantic) eyebrow labeling, reformat Design Decisions into Decision/Rationale/Approved blocks, populate the Compliance table with applicable accessibility checks, document the eyebrow/children props under Configuration, add tags, unquote modified date |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
