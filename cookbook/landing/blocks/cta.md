---
id: f98e53f7-ac16-48b0-afa5-544d05bf3f70
title: "Call-to-Action Group"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Container for call-to-action button groups, typically positioned below hero or closer section taglines."
platforms:
  - typescript
  - web
tags:
  - container
  - layout
  - cta
  - landing
depends-on: []
related:
  - fae23662-e69b-4472-9c7d-049feadf1211
  - 688cd8dc-2927-4a8a-9931-807fe283ed01
references: []
approved-by: ""
approved-date: ""
---

# Call-to-Action Group

## Overview

The Cta component is a layout container for grouping call-to-action buttons. It wraps button or link children in a semantic div element and applies consistent spacing and alignment through CSS class styling. Typically positioned below a Hero or Closer component's tagline to group primary and secondary actions.

## Behavioral Requirements

- **renders-children**: Component MUST render all ReactNode children without modification.
- **container-class**: Component MUST apply the `lp-cta` CSS class to its container div.
- **children-untouched**: Component MUST NOT modify or filter props passed to children; all children render with their original props intact.

## Appearance

- **Container element**: `div` with class `lp-cta`
- **Layout**: Horizontal flex row (`display: flex`); children wrap onto additional rows via `flex-wrap: wrap` when they exceed the available width; `justify-content: center` centers the children on each row; `gap: 0.75rem` (~12px, assuming a 16px root) separates children. The axis never switches to vertical — there is no breakpoint that stacks children.
- **Background**: Transparent (no background declared on `.lp-cta`)
- **Padding**: None (`.lp-cta` declares no padding or margin)
- **Border**: None (container only)
- **Shadow**: None (container only)

## States

Not applicable: This component is a static container with no interactive or visual states.

## Accessibility

- **Role**: Generic container (implicit `div` role)
- **Semantics**: The `lp-cta` class does not alter semantic meaning; children determine accessibility tree structure
- **Keyboard navigation**: Not applicable; container is not interactive; keyboard navigation depends on child elements (buttons, links)
- **Screen reader**: Children are exposed directly in the accessibility tree with their own labels and roles
- **Grouping semantics**: `Cta` adds no `role="group"` or `aria-label` of its own — see Design Decisions.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cta-001 | renders-children | Children: `<button>Sign Up</button>` | Output contains `<button>Sign Up</button>` |
| cta-002 | renders-children | Children: multiple buttons, links | All children rendered in order |
| cta-003 | renders-children | Children: null or undefined | Renders empty container |
| cta-004 | container-class | Any children | Rendered div has `className="lp-cta"` |
| cta-005 | children-untouched | Button child with `onClick` handler | Child onClick handler fires on click |
| cta-006 | renders-children | No children provided | Renders `<div className="lp-cta"></div>` with no visible width or height, since `.lp-cta` has no padding or margin and `gap` produces no space with zero or one child |
| cta-007 | children-untouched | Button child with `aria-label`, `data-testid`, and `className` props | All three props reach the rendered child unchanged: `aria-label` and `data-testid` are present, and the child's own `className` is retained |

## Edge Cases

- **Empty children**: Component renders an empty `<div className="lp-cta"></div>` without error. Because `.lp-cta` (`packages/web/packages/landing/src/css/blocks.css`) declares no padding or margin — only `display: flex`, `flex-wrap: wrap`, `gap: 0.75rem`, and `justify-content: center` — and `gap` has no effect with zero or one child, the empty container has no visible size. See **renders-children** and test vector cta-006.
- **Null or undefined children**: Renders empty container (React renders nothing for null/undefined).
- **Multiple children**: All children are rendered in document order within the container.
- **Fragment children**: React.Fragment children are unwrapped; their children render in the container.
- **Text node children**: Plain text or string children render as text nodes within the container.
- **Deeply nested children**: Component does not traverse or modify nested component trees.

## Configuration

Not applicable: Component accepts only the standard `children` prop; no configuration options exist.

## Deep Linking

Not applicable: This component is a layout container without route or navigation semantics.

## Localization

Not applicable: The component renders no user-facing text and requires no localization.

## Accessibility Options

Not applicable: The component does not respond to platform accessibility display options; accessibility behavior is determined by child elements.

## Feature Flags

Not applicable: No feature flag controls this component's behavior.

## Analytics

Not applicable: The component is a container without user interaction. Child elements (buttons, links) trigger their own analytics events.

## Privacy

Not applicable: This component collects and stores no data.

## Logging

Not applicable: No diagnostic logging is implemented for this container component.

## Platform Notes

- **React/Web**: `packages/web/packages/landing/src/blocks/Cta.tsx` — a simple functional component accepting `children: ReactNode` prop; styling applied via `className="lp-cta"`. `.lp-cta` in `packages/web/packages/landing/src/css/blocks.css` sets `display: flex; flex-wrap: wrap; gap: 0.75rem; justify-content: center` — no padding, margin, or breakpoint-driven axis change.
- **SwiftUI**: Implement as a horizontal flow: children laid out left-to-right with ~12pt spacing (matching `gap: 0.75rem`), wrapping onto a new row and centering each row's children when they exceed the available width. A plain `HStack` does not wrap; use a `Layout`-conforming flow container (iOS 16+ / macOS 13+) instead, and never fall back to a `VStack` for narrow widths.
- **Compose**: Implement using `androidx.compose.foundation.layout.FlowRow` with `horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally)` (or equivalent) to reproduce `gap: 0.75rem` and `justify-content: center`; children wrap onto additional rows automatically. Do not use a plain `Row` or `Column`.
- **AppKit / UIKit**: Compose a plain horizontal `NSStackView` / `UIStackView` — never subclass `NSView` / `UIView` — for the common case of children that fit on one row. Because neither stack view wraps natively, back the layout with a flow container (for example, a small custom flow view, or `UICollectionView` with a compositional flow layout) when children must wrap onto additional rows, keeping ~12pt spacing and centered alignment.
- **WinUI 3**: Implement as an `ItemsRepeater` with a horizontal `Microsoft.UI.Xaml.Controls.FlowLayout`, setting `MinItemSpacing` / `MinRowSpacing` to match `gap: 0.75rem` (~12px) and `HorizontalAlignment="Center"`, so buttons wrap onto additional rows instead of clipping. A plain `StackPanel` does not wrap and must not be used.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Cta.tsx` | unverified |

## Design Decisions

**Decision**: Use a generic `div` rather than a `<nav>` or `<section>` element for the container.
**Rationale**: Preserves flexibility for the parent component (Hero, Closer) to determine the semantic context in which the CTA group appears, rather than imposing landmark semantics that may not fit every placement.
**Approved**: pending

**Decision**: The container does not accept a `className` prop and always renders exactly `className="lp-cta"`; consumers cannot merge in their own classes.
**Rationale**: `Cta` (`packages/web/packages/landing/src/blocks/Cta.tsx`) only accepts a `children` prop; there is no `className` merging in the source, matching the component's minimal, styling-owned-by-the-block design.
**Approved**: pending

**Decision**: Grouping semantics for the CTA row (for example `role="group"` with `aria-label`) are left to the parent (`Hero`, `Closer`), not applied by `Cta` itself.
**Rationale**: `Cta` renders a plain `div` with no `role` or `aria-*` attributes; the parent knows the label appropriate to its own tagline and is best positioned to add grouping semantics if one is needed.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The status rests on the source rendering a plain `div` with a single static class (`lp-cta`) and no ARIA roles, states, or properties of its own — nothing for `Cta` to get wrong, and nothing that conflicts with the roles its children (buttons, links) supply. `separation-of-concerns` passes because `Cta.tsx` is pure presentation over its `children` prop with no business logic; `unit-test-coverage` is partial because `Cta` is exercised only inside `blocks-close.test.tsx`'s `Hero` test (asserting `.lp-cta .lp-btn` renders), through a parent component rather than a dedicated test of its own.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source (generated by Claude Haiku 4.5) |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: state concrete `.lp-cta` layout values (flex, wrap, gap, center) across Appearance and Platform Notes; fix AppKit/UIKit to compose stack views instead of subclassing; fix WinUI 3 to a wrapping `FlowLayout`; pick Compose's `FlowRow` and SwiftUI's `Layout` protocol for wrapping fidelity; rename requirements to subject-only kebab-case everywhere they're cited; reformat Design Decisions to the three-line form and add two new decisions (className restriction, grouping semantics); replace Compliance with a real linked check; add Hero/Closer to `related`; broaden tags; retitle to "Call-to-Action Group"; add test vectors for empty children and prop passthrough |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
