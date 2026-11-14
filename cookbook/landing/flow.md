---
id: 6f5f455d-b744-425d-a21e-494fc18caaf2
title: "Flow"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A non-scrolling content container that holds sequential bands or sections without managing scroll behavior."
platforms:
  - typescript
  - web
tags:
  - layout
  - container
  - landmark
  - landing
depends-on: []
related:
  - e0b59d60-0a56-4bf4-85cb-fb0e58170f8e
  - f8cbc576-a5ef-4e8c-90a0-7d0712b24b72
  - 05930e64-fa82-49ef-b50d-22d87fa7d182
  - 960a1577-bf48-4d56-a93f-aa690853f64f
references: []
approved-by: ""
approved-date: ""
---

# Flow

## Overview

Flow is a container component that wraps a page's sequential content sections — *bands* (see [adhsdk.ingredient.landing.flow.band](cookbook:e0b59d60-0a56-4bf4-85cb-fb0e58170f8e)) — establishing the structural root for that content without implementing scroll behavior itself; scrolling is delegated to the document or a parent container. The component sets `tabIndex={-1}` on its root, making it a valid programmatic focus target without adding it to the default (Tab-key) focus order.

## Behavioral Requirements

- **main-root**: Flow MUST render a `<main>` HTML element as its root.
- **programmatic-focus**: Flow MUST set `tabIndex={-1}` on the root element to make it focusable programmatically while excluding it from the default tab order.
- **render-children**: Flow MUST render its `children` prop directly inside the main element.
- **default-class**: Flow MUST apply the `lp-flow` CSS class to the root element.
- **custom-class**: Flow MUST accept an optional `className` prop and append it to the root element's class list when provided.
- **class-merge**: Flow MUST NOT render empty or undefined classes; only non-falsy class names MUST appear in the final class attribute.
- **no-height-or-overflow**: Flow MUST NOT set explicit height or overflow properties on the root element; these are delegated to the parent or document.
- **no-scroll-ownership**: Flow MUST NOT implement scroll behavior itself; scrolling is the responsibility of the containing document or parent.
- **single-main-landmark**: A page MUST render at most one Flow, since each Flow renders a `<main>` element and HTML permits only one visible `main` landmark per document.

## Appearance

- **Element**: `<main>`
- **Default class**: `lp-flow`
- **Height**: Not constrained; height is determined by content and parent layout.
- **Overflow**: Not set; overflow is handled by the document or parent container.
- **Padding / Margin**: Not set; inherit from `lp-flow` class or parent styles.
- **Background**: Not set; inherit from `lp-flow` class or parent styles.

## States

Not applicable: Flow is a structural container with no interactive states. It does not respond to user input or change its appearance based on state.

## Accessibility

- **Role**: `main` — the `<main>` element provides the semantic role for the primary content of the document.
- **Focusability**: `tabIndex={-1}` (see **programmatic-focus**) makes the root a valid focus target for a scripted `.focus()` call — for example after a client-side route change — without adding it to the sequential (Tab-key) focus order. It makes no claim about what happens when a user clicks on Flow's children.
- **No label**: Flow is a structural container and does not require a label.
- **Keyboard interaction**: Flow itself does not handle keyboard events; scrolling in response to keys (arrow keys, Page Up/Down) is handled by whichever ancestor actually scrolls — normally the document (see **no-scroll-ownership**).

## Conformance Test Vectors

| ID | Requirement | Input | Expected |
|-------|------|--------|----------|
| flow-001 | main-root | `<Flow><div>Content</div></Flow>` | The rendered root element's tag name is `MAIN`. |
| flow-002 | programmatic-focus | `<Flow><div>Content</div></Flow>` | The rendered `<main>` element's `tabindex` DOM attribute is `"-1"`; pressing Tab does not move focus onto it, and calling `.focus()` on it directly succeeds. |
| flow-003 | render-children | `<Flow><p>Hello</p></Flow>` | `<p>Hello</p>` appears inside the rendered `<main>` element exactly as passed. |
| flow-004 | default-class | `<Flow><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow"`. |
| flow-005 | custom-class | `<Flow className="custom"><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow custom"`. |
| flow-006 | class-merge | `<Flow className={undefined}><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow"`, with no extra spaces and no literal `undefined`. |
| flow-007 | no-height-or-overflow | Inspect the rendered `<main>` element's inline `style` attribute | The `style` attribute sets no `height`, `max-height`, or `overflow` value (it is empty or absent); computed styles contributed by the `lp-flow` stylesheet are out of scope for this vector. |
| flow-008 | no-scroll-ownership | Render `<Flow>` with content taller than the viewport; scroll with arrow keys or wheel events | `main.scrollTop` stays `0` throughout while `document.scrollingElement.scrollTop` changes, showing the document — not Flow — owns the scroll position. |
| flow-009 | class-merge | `<Flow className=""><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow"`, not `"lp-flow "`. |
| flow-010 | custom-class | `<Flow className="foo bar"><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow foo bar"`. |
| flow-011 | single-main-landmark | Render two `<Flow>` instances in the same document | `document.querySelectorAll('main').length` is `2`, which the requirement forbids; a conforming page keeps this count at `1`. |

## Edge Cases

- **No children**: Flow accepts zero children. When rendered without children, it produces an empty `<main tabIndex={-1} className="lp-flow"></main>` element. This is valid and used to establish the structural root even when content is added dynamically.
- **Empty className**: When `className` is an empty string, it MUST be filtered out (see **class-merge**). The resulting `class` attribute MUST be `"lp-flow"` only, not `"lp-flow "`.
- **Multiple class names in className prop**: Flow MUST append the entire `className` prop value unchanged (see **custom-class**). If `className="foo bar baz"`, the result MUST be `class="lp-flow foo bar baz"`.
- **Content taller than the viewport**: Flow itself never scrolls (see **no-scroll-ownership**); when Flow's content overflows the viewport, arrow-key and wheel scrolling moves the nearest scrollable ancestor — normally the document — not the Flow root.
- **Focus behavior on empty Flow**: When rendered with no children and thus no interactive elements, calling `.focus()` on the `<main>` element (see **programmatic-focus**) still succeeds — there is nothing else inside it to receive focus instead.
- **Multiple Flow instances on one page**: Rendering more than one Flow produces more than one `<main>` landmark, which HTML permits only one of (see **single-main-landmark**).

## Configuration

Not applicable: Flow has no configuration options. Its behavior is fully determined by its `children` and optional `className` props.

## Deep Linking

Not applicable: Flow is a structural container and does not define or handle deep linking behavior.

## Localization

Not applicable: Flow renders no user-facing strings.

## Accessibility Options

Not applicable: Flow provides no accessibility display options (reduce motion, increase contrast, etc.).

## Feature Flags

Not applicable: Flow MUST NOT gate any of its rendering behind a feature flag.

## Analytics

Not applicable: Flow MUST NOT emit analytics events.

## Privacy

Not applicable: Flow does not collect, transmit, or store any user data.

## Logging

Not applicable: Flow MUST NOT emit log statements.

## Platform Notes

- **TypeScript/Web**: Flow is implemented in `packages/web/packages/landing/src/flow/Flow.tsx`. The component accepts `children` (ReactNode) and optional `className` (string) props, renders a `<main>` element with `tabIndex={-1}`, applies the `lp-flow` class and any custom class names, and delegates all scroll behavior to the document. Styling details (colors, padding, spacing) are defined in the corresponding CSS module for the `lp-flow` class, not in the component itself.
- **SwiftUI**: Flow maps to a `VStack` or `ZStack` root view that does not manage scroll behavior itself. Use `.focusable()` with a bound `@FocusState` value to make the container a programmatic focus target without placing it in the tab/focus-navigation order, and `.accessibilityElement(children: .contain)` to group its content; SwiftUI has no built-in `main`-landmark trait, so there is no closer equivalent to expose. Delegate scrolling to a parent `ScrollView` or the enclosing view hierarchy.
- **Compose**: Flow maps to a `Box` or `Column` composable at the root of the content hierarchy. Do not call `Modifier.verticalScroll()` on the Flow root; instead wrap the entire hierarchy in a parent `Column` with `Modifier.verticalScroll()` if scrolling is needed. Apply `Modifier.focusable()` together with a `FocusRequester` to make the root a programmatic focus target outside the default focus-traversal order, and `Modifier.semantics { ... }` to describe it for accessibility services; Compose has no built-in `main`-landmark semantics property, so there is no closer equivalent. The Box/Column should not specify explicit height or overflow constraints.
- **AppKit / UIKit**: Flow maps to an `NSView` or `UIView` used as the content root. Do not configure scroll behavior on the Flow view itself; use an `NSScrollView` or `UIScrollView` as the parent if scrolling is required. Override `acceptsFirstResponder` (AppKit) to allow programmatic first-responder status without adding the view to the key-view loop — leave it out of `nextKeyView` — and expose it with the accessibility role for the main content area (the landmark-equivalent group role, or corresponding `UIAccessibilityTraits` on iOS). The Flow view itself should not specify a fixed height or clipping behavior.
- **WinUI 3**: Flow maps to a `Grid` or `StackPanel` root element in XAML. Set `IsTabStop="False"` on the root control (or wrap it in a focusable control) to exclude it from the default tab order while still allowing programmatic focus, and set `AutomationProperties.LandmarkType="Main"` for the equivalent landmark semantics. XAML has no `Overflow` property and no CSS-class equivalent for styling — apply the flow's appearance through a named `Style` resource, and leave clipping and scrolling to a parent `ScrollViewer` or the page's scroll context; do not set an explicit `Height` or `MaxHeight` on the Flow root.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/flow/Flow.tsx` | unverified |

## Design Decisions

**Decision**: Set `tabIndex={-1}` on Flow's root `<main>` element instead of leaving it out of the focus API entirely.
**Rationale**: `tabIndex={-1}` (see **programmatic-focus**) makes `<main>` a valid target for a scripted `.focus()` call without adding it to the sequential (Tab-key) focus order, and Flow sets no height or overflow of its own, so scrolling stays the responsibility of the document or the nearest scrollable ancestor (see **no-scroll-ownership**). Every platform implementation MUST preserve both characteristics.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Both statuses rest on the source rendering a semantic `<main>` element and setting `tabIndex={-1}` on it to keep it out of the tab order while still allowing programmatic focus (`packages/web/packages/landing/src/flow/Flow.tsx`). `separation-of-concerns` is `passed` because the component is pure layout over `children` with no business logic; `unit-test-coverage` is `passed` because `flow.test.tsx` renders `Flow` directly and asserts its `<main>`/`tabIndex` behavior.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: corrected the unverified click-focus rationale, phrased not-applicable sections as requirements, added a single-main-landmark requirement and vector, renamed requirements to subject-only kebab-case, added tags and related links, reformatted Design Decisions as Decision/Rationale/Approved, added a Compliance table, fixed RFC 2119 casing, corrected the WinUI 3/AppKit-UIKit/SwiftUI/Compose platform notes, tightened and extended Conformance Test Vectors, and defined "bands" |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
