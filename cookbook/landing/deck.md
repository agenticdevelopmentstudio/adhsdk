---
id: 05930e64-fa82-49ef-b50d-22d87fa7d182
title: "Deck"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A flow container wrapper that holds screen content without scrolling, enabling document-level scroll control."
platforms:
  - typescript
  - web
tags:
  - layout
  - container
  - landing
  - focus
depends-on: []
related:
  - 6f5f455d-b744-425d-a21e-494fc18caaf2
  - 4d2b7231-1235-49e9-8b7d-1e7507c6eba7
references: []
approved-by: ""
approved-date: ""
---

# Deck

## Overview

Deck is a layout wrapper component that serves as the root container for screen content in a flow-based UI. It does not scroll itself — the browser document handles scrolling — so it carries no height or overflow constraints. Deck is always a `<div>` element with the class `lp-deck` and maintains internal focus without entering the tab order, allowing keyboard navigation to scroll the document instead of being trapped within the component.

## Behavioral Requirements

- **render-children**: Deck MUST render its child content as direct descendants of its root container.
- **no-own-scroll**: Deck MUST NOT scroll itself or constrain its own height or overflow, leaving the document to handle scrolling.
- **merges-style-hook**: Deck MUST apply its own base style hook and merge it with any consumer-supplied style hook, filtering out falsy values before combining them.
- **focusable-not-tabbable**: Deck MUST be focusable programmatically (e.g. by a click inside it) while being excluded from the default sequential tab order.
- **not-a-landmark**: Deck MUST NOT expose a semantic landmark role of its own, since it is designed to sit inside a host shell that already provides the page's main landmark.

## Appearance

Not applicable: Deck is an unstyled structural container. Visual appearance is defined by CSS rules applied to the `.lp-deck` class or to its children.

## States

Not applicable: Deck is a static container with no interactive states (default, pressed, disabled, focused, loading).

## Accessibility

- **Focus management** (`#requirements/focusable-not-tabbable`): A click inside Deck focuses it (or a descendant), which keeps it out of the tab order; from there, arrow keys and Page Down scroll the document rather than being trapped inside Deck.
- **No semantic role**: Deck is a structural container with no accessible role. Its root element must not be changed in a way that introduces an unintended semantic role.
- **Not a landmark** (`#requirements/not-a-landmark`): Deck is not a landmark element. The page's `<main>` landmark, if present, MUST be provided by the host shell outside Deck to avoid nested main elements.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| deck-001 | render-children | `<Deck><span>Content</span></Deck>` | The span is rendered as a child of the root container |
| deck-002 | merges-style-hook | `<Deck/>` | The root container carries only its own base style hook (`lp-deck` on React/Web) |
| deck-003 | merges-style-hook | `<Deck className="custom-class"/>` | The root carries both its base style hook and the consumer's: `lp-deck custom-class` |
| deck-004 | merges-style-hook | `<Deck className={undefined}/>` | The root carries only its base style hook; the falsy value is filtered out |
| deck-005 | focusable-not-tabbable | `<Deck/>` | The root container is focusable (`tabIndex={-1}` on React/Web) but is absent from the default tab order |
| deck-006 | not-a-landmark | `<Deck/>` | The rendered root is a `<div>`, not a `<main>`, and exposes no landmark role |
| deck-007 | render-children | `<Deck>{null}</Deck>` | Deck renders successfully with no child content present (empty, null, or undefined) |
| deck-008 | merges-style-hook | `<Deck className=""/>` | The root carries only its base style hook; the empty-string value contributes nothing |
| deck-009 | merges-style-hook | `<Deck className="a b c"/>` | All three space-separated tokens are preserved alongside the base style hook |
| deck-010 | no-own-scroll | `<Deck/>` | The root container has no height or overflow style constraining its own scroll |
| deck-011 | focusable-not-tabbable | Click inside `<Deck>`, then press ArrowDown or Page Down | Focus lands on the clicked content inside Deck; the subsequent key scrolls the document, not Deck |

## Edge Cases

- **Empty children** (`#requirements/render-children`): Deck MUST render successfully when its child content is empty, null, or undefined.
- **Falsy style-hook values** (`#requirements/merges-style-hook`): Deck MUST filter out falsy style-hook values (null, undefined, false, empty string) before combining them.
- **Multiple class tokens in the style hook** (`#requirements/merges-style-hook`): When the consumer's style hook contains multiple space-separated tokens, Deck MUST preserve all of them when merging with its own base style hook.
- **No consumer style hook supplied** (`#requirements/merges-style-hook`): Deck MUST render with only its own base style hook when the consumer supplies none.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `children` | `ReactNode` | required | The content to render inside the Deck |
| `className` | `string` | `undefined` | Additional CSS class names to apply to the root div |

## Deep Linking

Not applicable: Deck is a layout container, not a routable screen or page.

## Localization

Not applicable: Deck contains no user-facing text or locale-specific content.

## Accessibility Options

Not applicable: Deck is a structural container with no visual styling or interactive elements that respond to accessibility display options (Reduce Motion, Increase Contrast, Differentiate Without Color).

## Feature Flags

Not applicable: Deck is foundational infrastructure, not a user-facing feature subject to feature flag gating.

## Analytics

Not applicable: Deck is a container with no user interaction to track.

## Privacy

Not applicable: Deck does not collect, store, or transmit any data.

## Logging

Not applicable: No logging is implemented in Deck.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/landing/src/deck/Deck.tsx`. The component accepts `children` (ReactNode) and optional `className` (string) props, realizing render-children and merges-style-hook. Class names are filtered and merged using `['lp-deck', className].filter(Boolean).join(' ')`. The root is a `<div>` (not-a-landmark) with `tabIndex={-1}` (focusable-not-tabbable) and no height or overflow styling (no-own-scroll).

- **SwiftUI**: Use a `VStack(spacing: 0)` or another zero-spacing container as the root, with no scroll modifier applied — let the document or an outer scroll view handle scrolling.

- **Compose**: Compose has no direct equivalent of `tabIndex={-1}`: `Modifier.focusable()` alone places the container in the platform's default focus-traversal order, which would defeat focusable-not-tabbable. Use `Modifier.focusRequester(requester).focusTarget()` so the container becomes focusable only through an explicit `requester.requestFocus()` call, without joining tab/d-pad traversal.

- **AppKit / UIKit**: For macOS, use `NSView` or `NSStackView`; for iOS, use `UIView` or `UIStackView`. Neither should scroll — scrolling is handled by the document or an enclosing scroll view. Leave the view's default accessibility role (`NSAccessibility.Role.group` on macOS, or `isAccessibilityElement = false` on iOS) rather than assigning a landmark-like trait, so the container satisfies not-a-landmark.

- **WinUI 3**: `Grid` and `StackPanel` are Panels, not Controls, so `TabIndex`/`IsTabStop` don't behave on them as they do on a `Control`; setting `IsTabStop="false"` also blocks programmatic `Focus()`, defeating focusable-not-tabbable's goal of accepting a click or a programmatic focus call without a tab stop. Host the deck's content in a `Control`-derived container where `IsTabStop="false"` paired with an explicit `Focus(FocusState.Programmatic)` call keeps it out of tab order while still accepting focus; where no such host is available, treat focusable-not-tabbable parity as a known WinUI 3 gap. Ensure the parent window or page provides any required semantic roles (like `AutomationProperties.LandmarkType="Main"`) outside the Deck container, matching not-a-landmark.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/deck/Deck.tsx` | unverified |

## Design Decisions

**Decision**: Deck renders as a `<div>`, not a `<main>` element.
**Rationale**: Deck was initially rendered as a `<main>` element, but every consumer renders Deck as a page inside a host shell that already draws the page's `<main>` landmark, so the two nested landmarks were invalid HTML and announced two "main" regions to a screen reader with no way to tell which held the actual page content. Deck is now a `<div>` to avoid the duplication; a host that does not provide its own main landmark can apply one from outside Deck, which is the only context that knows whether one already exists.
**Approved**: pending

**Decision**: Deck sets `tabIndex={-1}` on its root element (focusable-not-tabbable).
**Rationale**: A click inside Deck focuses it, or a descendant, and keeps it out of the keyboard tab order; from that point, arrow keys and Page Down scroll the document rather than being trapped inside Deck, so the document remains the natural scroll container. See deck-011.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Both statuses rest on the source's deliberate `tabIndex={-1}` focus handling and its `<div>` (not `<main>`) root, documented directly in `Deck.tsx`'s comment block and exercised by its test suite. `separation-of-concerns` passes because `Deck.tsx` is pure presentation over its `children` and `className` props, with no business logic; `unit-test-coverage` passes because `deck.test.tsx` renders `<Deck>` directly and asserts on its output.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and split them into platform-neutral behaviors (render-children, no-own-scroll, merges-style-hook, focusable-not-tabbable, not-a-landmark) with web specifics moved to React/Web notes; rewrote the tabIndex rationale as the concrete click-then-scroll sequence and added matching test vectors deck-007 through deck-011 plus edge-case cross-references; reformatted Design Decisions to Decision/Rationale/Approved; linked real accessibility compliance checks; corrected the Compose, WinUI 3, SwiftUI, and AppKit/UIKit platform notes; added tags and related ingredients. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
