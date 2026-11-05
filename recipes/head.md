---
id: 31198bb7-2270-449e-94c1-026b68d2bc81
title: Head
domain: adhsdk://recipes/head
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Section heading block with optional eyebrow label, title, and content area.
platforms:
- typescript
- web
tags:
- landing
- heading
- layout
- section
depends-on: []
related:
- adhsdk://recipes/lede
references: []
approved-by: ''
approved-date: ''
---

# Head

## Overview

A container for a section's heading that renders an optional eyebrow (contextual label), optional title as an h2, and child content. Used to introduce sections within a layout, typically followed by other content blocks like Lede or body content.

## Behavioral Requirements

- **render-container**: Component MUST render a `div` element with class `lp-head`.
- **conditional-eyebrow**: Component MUST render a `span` element with class `lp-eyebrow` and the eyebrow content only when the `eyebrow` prop is defined (not `undefined`).
- **conditional-title**: Component MUST render an `h2` element containing the title content only when the `title` prop is defined (not `undefined`).
- **render-children**: Component MUST render the `children` prop content within the container when `children` is provided.
- **preserve-order**: Component MUST render child elements in the order: eyebrow (if present), title (if present), children (if present).

## Appearance

Styling is applied via external CSS classes (`lp-head`, `lp-eyebrow`). The source does not define inline styles, colors, typography, spacing, or dimensions. The rules live in `packages/web/packages/landing/src/css/blocks.css` (`.lp-head`, `.lp-eyebrow`, `.lp-eyebrow::before`, `.lp-head h2`, `.lp-head h2 b`).

## States

Not applicable: This is a static container component with no user interaction or interactive states.

## Accessibility

- The title is rendered as an `h2` element, providing semantic structure for document outline and screen reader navigation. On native platforms, the equivalent element MUST carry the platform's heading trait/semantics (see Platform Notes) since there is no HTML tag to carry it implicitly.
- The eyebrow is rendered as a `span` without semantic role, as a sibling of the `h2` rather than nested inside it. When the eyebrow content is important to a reader who lands directly on the section (for example, it is the label a drawer link used to get here), callers SHOULD link the two elements with `aria-describedby` — give the eyebrow `span` an `id` and reference it from the `h2` — rather than relying on visual adjacency alone.
- Child content inherits accessibility characteristics from its own implementation; the component does not alter or wrap accessibility properties of children.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| head-001 | render-container | No props | `<div class="lp-head"></div>` rendered |
| head-002 | conditional-eyebrow, preserve-order | `eyebrow="Section"` | `<div class="lp-head"><span class="lp-eyebrow">Section</span></div>` |
| head-003 | conditional-title, preserve-order | `title="Heading"` | `<div class="lp-head"><h2>Heading</h2></div>` |
| head-004 | render-children, preserve-order | `children={<p>Content</p>}` | `<div class="lp-head"><p>Content</p></div>` |
| head-005 | conditional-eyebrow, conditional-title, render-children, preserve-order | `eyebrow="Nav"`, `title="Title"`, `children={<p>Body</p>}` | `<div class="lp-head"><span class="lp-eyebrow">Nav</span><h2>Title</h2><p>Body</p></div>` |
| head-006 | conditional-eyebrow | `eyebrow={null}` | `<div class="lp-head"><span class="lp-eyebrow"></span></div>` — the `!== undefined` check passes, so the span renders, but `null` produces no child text |
| head-007 | conditional-title | `title=""` | `<div class="lp-head"><h2></h2></div>` — the check passes on the empty string, producing an empty heading |
| head-008 | render-children | `children={0}` | `<div class="lp-head">0</div>` — `0` is a valid `ReactNode` and renders as text |

## Edge Cases

- **Undefined props**: When `eyebrow`, `title`, or `children` are `undefined`, the component skips rendering the corresponding element. The container div is always rendered.
- **Null vs. undefined**: The component uses `!== undefined` checks; passing `null` for any prop will cause it to render (e.g., `<span className="lp-eyebrow">{null}</span>`). This may produce an empty element.
- **Empty string or falsy values**: An empty string `""` satisfies the `!== undefined` check and will be rendered, resulting in empty `span` or `h2` elements or no visible content for children.
- **ReactNode types**: The props accept `ReactNode`, allowing strings, numbers, components, fragments, or arrays. All valid ReactNode types are rendered as-is without additional wrapping.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `eyebrow` | `ReactNode` | `undefined` | Optional eyebrow label rendered as a span with class `lp-eyebrow`. |
| `title` | `ReactNode` | `undefined` | Optional title rendered as an h2 element. |
| `children` | `ReactNode` | `undefined` | Optional content rendered within the container. |

## Deep Linking

Not applicable: This is a layout component, not a screen or navigable entity.

## Localization

Not applicable: The component does not define any static text; all content is provided via props.

## Accessibility Options

Not applicable: This component does not respond to platform-level accessibility display options like Reduce Motion or Increase Contrast; styling is applied via external CSS.

## Feature Flags

Not applicable: This component has no feature flag controls.

## Analytics

Not applicable: This component does not emit analytics events.

## Privacy

Not applicable: This component does not collect, store, or transmit data.

## Logging

Not applicable: This component does not emit diagnostic logs.

## Platform Notes

- **TypeScript/Web**: Defined in `packages/web/packages/landing/src/blocks/Head.tsx`. The component accepts `ReactNode` props and conditionally renders semantic HTML (`h2` for title, `span` for eyebrow) using `!== undefined` guards. Styling comes from `packages/web/packages/landing/src/css/blocks.css` (`.lp-head`, `.lp-eyebrow`).
- **SwiftUI**: Implement as a `VStack` with an optional eyebrow `Text` (small, `.font(.caption)`, accent/secondary color, uppercase) above an optional title `Text` styled `.font(.title2)` — not `.font(.headline)`, which is body-sized rather than the `h2`'s larger display weight — followed by the content view. Apply `.accessibilityAddTraits(.isHeader)` to the title `Text` so it is exposed as a heading, and use `if let`/`@ViewBuilder` to match the conditional rendering.
- **Compose**: Implement as a `Column` with an optional eyebrow `Text` (`MaterialTheme.typography.labelSmall`, accent/secondary color, uppercase) above an optional title `Text` (`MaterialTheme.typography.headlineSmall`), followed by the content. Add `Modifier.semantics { heading() }` to the title `Text` to expose it as a heading, and use conditional composition (`if (title != null) { … }`) to match the conditional rendering.
- **AppKit / UIKit**: Implement as a vertical stack (`UIStackView` on iOS, `NSStackView` on macOS) containing an optional eyebrow label (`UILabel` / `NSTextField`, small caption style, accent/secondary color) and an optional title label (`UILabel` / `NSTextField`, styled `.title2`), plus the content view. On iOS set the title label's `accessibilityTraits = .header`; on macOS give the title `NSTextField` the heading subrole (`NSAccessibility.Subrole` value `AXHeading`) so it is exposed as a heading. Add subviews conditionally based on prop presence.
- **WinUI 3**: Implement as a `StackPanel` with `Orientation="Vertical"` containing an optional eyebrow `TextBlock` (small font, accent/secondary foreground, uppercase) and an optional title `TextBlock` (larger font, `FontWeight="SemiBold"`), plus a content presenter. Set `AutomationProperties.HeadingLevel="Level2"` on the title `TextBlock` so it is exposed as a heading, and use the `Visibility` property to conditionally show/hide the eyebrow and title elements based on whether they are provided.

## Design Decisions

**Decision**: Prop presence is checked with `!== undefined` rather than truthiness.
**Rationale**: This allows falsy values like empty strings, `0`, or `false` to render as content, matching React's own treatment of these as valid children, and preserves the distinction between "prop not provided" (`undefined`) and "prop provided with a falsy value" (render it).
**Approved**: pending

**Decision**: The eyebrow renders as a generic `span` with no semantic role, rather than nested inside the `h2` or auto-linked to it.
**Rationale**: The eyebrow is a visual label that is not always semantically significant; the component leaves it to the caller to add the semantics (see **eyebrow-accessibility** guidance in Accessibility) when the eyebrow content matters to the outline.
**Approved**: pending

**Decision**: The title always renders at a fixed `h2` level; there is no `level` configuration option.
**Rationale**: `Head` is meant to introduce a section directly under a page's single `h1`, so a fixed level keeps every section's document outline consistent; a caller that needs a different level needs a different component, not a prop that could produce a broken outline.
**Approved**: pending

**Decision**: Because presence is checked with `!== undefined` (see above), passing `null` for `eyebrow`/`title` or `""` for `title` still renders the element — an empty `span` or an empty `h2` — rather than skipping it.
**Rationale**: Kept consistent with the presence-check decision above rather than adding a second, different rule for "empty" values; the accessibility cost is that a blank `h2` reaches the screen-reader heading outline, so callers MUST pass `undefined` (omit the prop), not `null` or `""`, when there is no title to show.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The title renders as a native `h2` (semantic-markup), and `blocks.css` sizes the eyebrow and title with `rem`/`vw` units that scale with the root font size (dynamic-type-support). Neither the component nor `.lp-head h2` sets the heading's foreground color — it inherits from the surrounding page — so contrast cannot be confirmed from the source alone (contrast-ratio: partial). `separation-of-concerns` is `passed` because the component is pure presentation over `eyebrow`/`title`/`children` props with no business logic; `unit-test-coverage` is `passed` because `blocks-frame.test.tsx` renders `Head` directly and asserts its eyebrow/title rendering.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, reformatted Design Decisions to three-field form and recorded two new decisions (fixed h2 level, null/empty heading behavior), added a Compliance table, replaced duplicate test vectors with null/empty-string/zero vectors, added platform heading-semantics hooks and tightened Platform Notes precision, pointed Appearance at the exact CSS file, specified the eyebrow-heading ARIA pattern, added tags and a related link to Lede, and normalized frontmatter dates |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from source |
