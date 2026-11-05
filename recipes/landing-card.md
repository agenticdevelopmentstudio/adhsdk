---
id: 01947259-4883-44e1-a047-6b4e463cb422
title: Landing Card
domain: adhsdk://recipes/landing-card
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'A single tile in a landing page card grid: optional kicker label, required
  title heading, and prose content.'
platforms:
- typescript
- web
tags:
- landing
- card
- layout
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Landing Card

## Overview

A landing page card presents a discrete piece of information in a grid layout. It consists of three stacked layers: an optional kicker (small contextual label), a required title heading, and required prose or content. The component is semantic HTML and class-based styling; styling and layout are handled by the container (`Cards` grid) and the card's own CSS classes.

## Behavioral Requirements

- **render-title**: Component MUST render the `title` prop as an `<h3>` heading.
- **render-children**: Component MUST render the `children` prop as the card's content, immediately after the title.
- **support-optional-kicker**: Component MUST accept an optional `kicker` prop and render it only when defined (not `undefined`).
- **render-kicker-before-title**: When `kicker` is provided, it MUST render before the `<h3>` title in the DOM.
- **use-card-class**: The root element MUST have the class name `lp-card`.
- **use-kicker-class**: When rendered, the kicker element MUST have the class name `lp-card__kicker`.
- **accept-react-nodes**: The `kicker`, `title`, and `children` props MUST accept any React `ReactNode` (elements, strings, numbers, fragments, etc.), not only strings.
- **tolerate-nullish-title**: Component MUST NOT crash when `title` is `null` or `undefined`; it renders an empty `<h3>` in that case.
- **tolerate-nullish-children**: Component MUST NOT crash when `children` is `null` or `undefined`; it renders the card with an empty content area in that case.

## Appearance

- **Root element**: `<div>` with class `lp-card`
- **Kicker element**: `<span>` with class `lp-card__kicker` (conditional)
- **Title element**: `<h3>` (semantic heading, no class)
- **Content**: Direct children rendered after the title
- **Spacing and styling**: Controlled by CSS classes `lp-card` and `lp-card__kicker`; this recipe does not specify colors, typography, padding, or visual hierarchy (those are stylesheet concerns)

## States

| State | Appearance change |
|-------|------------------|
| Default (kicker undefined) | Kicker element absent from DOM |
| Default (kicker defined) | Kicker element rendered |
| Loading | Not applicable: component is static presentation; content loading is the parent's concern |
| Disabled | Not applicable: component is not interactive |

## Accessibility

- **Role**: The root is a generic container (`<div>`); the `<h3>` title establishes semantic structure for screen readers.
- **Heading level**: Title always renders as `<h3>` (see **render-title**); the component exposes no way to change this. Consumers MUST place the card where an `<h3>` fits in the page's heading hierarchy (for example, within a section introduced by `<h2>`), rather than expecting the card to adapt to a different level.
- **Label requirements**: Title text MUST be meaningful and describe the card's subject. If `title` is an icon or symbol, it MUST be accompanied by accessible text (either in the prop or wrapping element).
- **Kicker labeling**: Kicker text SHOULD provide context (e.g., "Preview", "Latest", "23 specialists"). Screen readers will encounter it before the title due to DOM order. If kicker is interactive content (a link), the consumer MUST ensure the kicker and title together form a descriptive label.
- **Content accessibility**: Content (`children`) MUST be accessible HTML; this component imposes no restrictions but does not enhance accessibility for complex children — responsibility remains with the consumer.
- **Minimum tap target**: Not applicable: component is not interactive; if children contain interactive elements, those MUST meet 44×44pt (iOS) / 48×48dp (Android) / 44×44px (web) minimum tap targets per platform guidelines.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| landing-card-001 | render-title | `title="Explore Stories"` | Output contains `<h3>Explore Stories</h3>` |
| landing-card-002 | render-children | `children="Browse our collection"` | Output contains text node "Browse our collection" after the title |
| landing-card-003 | support-optional-kicker, render-kicker-before-title | `kicker="Preview"` | Output contains `<span class="lp-card__kicker">Preview</span>` before the `<h3>` |
| landing-card-004 | support-optional-kicker | `kicker={undefined}` (or omitted) | Kicker `<span>` absent from DOM |
| landing-card-005 | use-card-class | Any props | Root `<div>` has class `lp-card` |
| landing-card-006 | use-kicker-class | `kicker="Label"` | Kicker span has class `lp-card__kicker` |
| landing-card-007 | accept-react-nodes | `title={<em>Dynamic</em>}` | Title renders the React element inside the `<h3>` |
| landing-card-008 | accept-react-nodes | `children={<ul><li>Item</li></ul>}` | Children render the list elements after the title |
| landing-card-009 | tolerate-nullish-title | `title={null}` (or `undefined`) | Output contains an empty `<h3></h3>`; no error thrown |
| landing-card-010 | tolerate-nullish-children | `children={null}` (or `undefined`) | Card renders the root `<div>` and `<h3>` with no content after the title; no error thrown |

## Edge Cases

- **Null or undefined title**: `title` is typed `ReactNode` (not optional) in the prop signature, but the component does not guard against nullish values; see **tolerate-nullish-title**.
- **Empty string kicker**: `kicker=""` is falsy in JavaScript, but the guard tests strictly for `undefined` (`kicker === undefined`), not truthiness, so an empty string still renders the kicker element with empty content. Outcome: `<span class="lp-card__kicker"></span>` appears in the DOM.
- **Null or undefined children**: `children` is typed `ReactNode` (not optional) in the prop signature, but the component does not guard against nullish values; see **tolerate-nullish-children**.
- **Whitespace-only children**: If `children="   "` (whitespace only), it renders as-is; no trimming occurs. Outcome: Whitespace appears as content.
- **Very long title or kicker text**: No line-breaking or truncation is defined at the component level; layout is CSS-driven. Outcome: Text overflows or wraps per the `lp-card` stylesheet rules.
- **Interactive content in title or children**: A consumer MAY place links, buttons, or form fields inside the card. The component MUST NOT prevent or restrict this. Outcome: Interactive elements are rendered and functional.
- **React Fragment as children**: If `children={<>Item 1<span>Item 2</span></>}` (Fragment), React renders the fragment's children directly. Outcome: Both items appear after the title.

## Configuration

Not applicable: Component accepts only `kicker`, `title`, and `children` props. There are no feature flags, configuration options, or env-var-controlled behavior.

## Deep Linking

Not applicable: Landing Card is a presentation component on a landing page, not a navigable view. Deep linking is a page-level concern.

## Localization

Not applicable: Component renders user-provided content as-is; localization of the kicker, title, and children is the consumer's responsibility.

## Accessibility Options

Not applicable: Component is static presentation and does not respond to system accessibility options (Reduce Motion, Increase Contrast, etc.). Consumers providing interactive or animated children are responsible for honoring these options.

## Feature Flags

Not applicable: Component has no feature-flagged behavior or optional functionality.

## Analytics

Not applicable: Component is not interactive and does not emit events. Analytics for user interaction with card content (if children include links or buttons) is the consumer's responsibility.

## Privacy

Not applicable: Component does not collect, store, or transmit any data.

## Logging

Not applicable: Component performs no operations that warrant logging.

## Platform Notes

- **TypeScript / Web (React)**: Component is `Card.tsx` in `packages/web/packages/landing/src/blocks/`. Render as a semantic `<div>` with class `lp-card`, optional `<span class="lp-card__kicker">`, `<h3>` for title, and children. Styling is CSS-driven via `lp-card` and `lp-card__kicker` classes.
- **SwiftUI**: Start with a `VStack` to layer kicker, title, and content. Use `Text` for kicker (if present, apply smaller font and secondary color), `Text` with `.font(.title3)` for title (matching `<h3>` semantic weight) and `.accessibilityAddTraits(.isHeader)` so assistive technology recognizes it as a heading, and a `@ViewBuilder content: () -> Content` parameter for the card's body. Apply a Card style or custom `.background()` modifier. No class-based styling; use SwiftUI's modifier system for appearance.
- **Compose**: Use a `Column` to stack elements. Render a `Text` for optional kicker (if present, styled smaller and secondary), a `Text` for title with `style = MaterialTheme.typography.headlineSmall` (the tier-3 heading role matching SwiftUI's `.title3`) and `Modifier.semantics { heading() }` so assistive technology recognizes it as a heading, and a `content: @Composable () -> Unit` slot invoked after the title. Apply Material Design 3 card styling using `Card` or `Surface` with appropriate padding and elevation.
- **AppKit / UIKit**: For AppKit, use an `NSView` with vertical `NSStackView` layout; for UIKit, use `UIView` with vertical `UIStackView`. Add optional `NSTextField(labelWithString:)`/`UILabel` for kicker (if present, small font), `NSTextField(labelWithString:)`/`UILabel` with heading weight for title — on UIKit, set the title label's `accessibilityTraits` to include `.header` so it reads as a heading — and a content view. Apply background color and border per design. No class-based styling; use native layout and appearance APIs.
- **WinUI 3**: Use a `Grid` with single column and auto-sized rows. Add optional `TextBlock` with `Style="{StaticResource CaptionTextBlockStyle}"` and `Foreground` set to secondary color for kicker (if present). Add `TextBlock` with `Style="{StaticResource SubtitleTextBlockStyle}"` for title and set `AutomationProperties.HeadingLevel="Level3"` on it so assistive technology recognizes it as a heading. Add content control(s) below. Apply `CornerRadius` and `Background` to the root Grid or a `Border` wrapper. Bind kicker visibility to a converter that collapses it when `null`.

## Design Decisions

**Decision**: Kicker renders as a `<span>`, not a `<div>`.
**Rationale**: The kicker is a small inline label, so `<span>` is more semantic than `<div>` and does not start a new block-level section.
**Approved**: pending

**Decision**: Title always renders as `<h3>` (see **render-title**), and the component exposes no way to change the heading level.
**Rationale**: Card title is a tertiary heading (after page and section titles); consumers place the card where an `<h3>` fits in the document's heading hierarchy rather than the component adapting to a different level.
**Approved**: pending

**Decision**: Kicker is omitted entirely when `undefined`, not rendered with empty content.
**Rationale**: This avoids empty DOM nodes and simplifies CSS selectors; the conditional `{kicker === undefined ? null : ...}` ensures no render when absent.
**Approved**: pending

**Decision**: No styling concerns (colors, padding, font sizes, shadows, borders) live in the component; they are delegated to the `lp-card` and `lp-card__kicker` CSS classes.
**Rationale**: This keeps the component focused on structure and props, making it reusable across design systems.
**Approved**: pending

**Decision**: Children render directly, with no wrapper and no assumptions about content type.
**Rationale**: This maximizes flexibility; consumers control the layout and styling of prose, images, or other content.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Card.tsx renders semantic HTML (`<h3>`, `<span>`, `<div>`) with no ARIA misuse; text scaling and color contrast are delegated entirely to the `lp-card` and `lp-card__kicker` CSS classes, which this source file does not define, so those two statuses cannot be verified from the component itself. `separation-of-concerns` passes because the component is pure presentation over its `kicker`/`title`/`children` props with no business logic; `unit-test-coverage` passes on `blocks-frame.test.tsx`'s `Cards` suite, which exercises the title/kicker rendering directly, including the kicker-omitted case.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, promoted nullish title/children handling to named requirements with test vectors, reworded the heading-level MUST so it no longer asks the consumer for behavior the component doesn't expose, reformatted Design Decisions to Decision/Rationale/Approved, replaced Compliance with an accessibility checks table, fixed WinUI 3's hardcoded font styles and added native heading traits across platforms, corrected the AppKit label API and two inaccurate edge-case descriptions, and added tags |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from Card.tsx source |
