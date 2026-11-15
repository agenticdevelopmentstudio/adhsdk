---
id: 811cc18f-e33a-42bb-bd2d-dfc3dc21bc77
title: "Lede"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Introductory paragraph component that with a constrained measure, used after headings or other content blocks."
platforms:
  - typescript
  - web
tags:
  - typography
  - text
  - landing
  - paragraph
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Lede

## Overview

A paragraph component used for introductory or emphasized text following headings, cards, or other content blocks. The lede renders semantic HTML paragraph markup and accepts optional additional styling via className.

## Behavioral Requirements

- **render-as-paragraph**: Component MUST render as an HTML `<p>` element.
- **render-children**: Component MUST render the provided `children` prop as the paragraph content.
- **apply-lede-class**: Component MUST apply the `lp-lede` CSS class to the rendered element.
- **accept-additional-class**: Component MUST accept an optional `className` prop that is concatenated with `lp-lede`.
- **clean-class-attribute**: The rendered `class` attribute MUST contain no `undefined` or empty-string tokens: falsy `className` values (`undefined`, `null`, `""`) are filtered out before the attribute is joined. A whitespace-only value is truthy and is therefore not filtered (see Edge Cases).
- **constrain-paragraph-measure**: Component MUST constrain the paragraph to a maximum measure of 72 characters (`max-width: 72ch`, defined by the `lp-lede` CSS rule) for readability. `ch` is the width of the `0` glyph of the paragraph's font; the font-family is a host-configurable assumption (the shipped site uses one monospace font-family token), not part of this component.
- **meet-contrast-ratio**: Paragraph text MUST meet WCAG AA contrast (at least 4.5:1) against the background it sits on, using the `--lp-ink-dim` token (fallback `#a0a0a0`). Hosts that override the token or the background own this check.

## Appearance

- **Element**: Semantic `<p>` HTML element
- **Base class**: `lp-lede`
- **Color**: `var(--lp-ink-dim, #a0a0a0)`
- **Font**: weight 300, size `1.02rem`
- **Measure**: `max-width: 72ch` (see **constrain-paragraph-measure** and the 72ch Design Decision); `ch` is the width of the `0` glyph of the paragraph's font, which the host chooses (the shipped site sets one monospace font-family token)
- **Spacing**: `margin-top: 1.15rem` by default; `0.9rem` between two consecutive ledes (`.lp-lede + .lp-lede`); `1.8rem` when a lede is the first child of `.lp-wrap`
- **Text wrapping**: `text-wrap: pretty`
- **Emphasis (`<em>`)**: rendered in `var(--lp-accent-bright, #d8d8d8)` with `font-style: normal` — color signals emphasis instead of italics. This styling is informative only; the component has no requirement for it and no test vector covers it.
- **Additional styling**: Applied via optional `className` prop

## States

Not applicable: Lede is a static presentational component with no interactive or stateful behavior.

## Accessibility

- **Role**: Paragraph (implicit via `<p>` element)
- **Semantic markup**: The component uses semantic HTML paragraph markup, which provides proper document structure for assistive technologies.
- **Content**: Component content is read as-is by screen readers; no additional ARIA labeling required.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| lede-001 | render-as-paragraph | `<Lede>Text</Lede>` | Element is rendered as `<p>` in the DOM |
| lede-002 | render-children | `<Lede>Hello World</Lede>` | Text content "Hello World" appears in paragraph |
| lede-003 | apply-lede-class | `<Lede>Text</Lede>` | Rendered element includes `lp-lede` class |
| lede-004 | accept-additional-class | `<Lede className="extra">Text</Lede>` | Rendered element includes both `lp-lede` and `extra` classes |
| lede-005 | clean-class-attribute | `<Lede className={undefined}>Text</Lede>` | Rendered element class is `lp-lede` only (undefined filtered out) |
| lede-006 | clean-class-attribute | `<Lede className="">Text</Lede>` | Rendered element class is `lp-lede` only (empty string filtered out) |
| lede-007 | Edge Case: whitespace-only className | `<Lede className=" ">Text</Lede>` | Rendered element class attribute is `lp-lede  ` (two spaces): a whitespace-only value is truthy, so it is not filtered and leaves a stray blank token. This documents current behavior and is not a requirement; **clean-class-attribute** covers only `undefined`, `null` and `""`. |
| lede-008 | constrain-paragraph-measure | `<Lede>Text</Lede>` | The `.lp-lede` rule in `blocks.css` declares `max-width: 72ch` (jsdom applies no stylesheets and `getComputedStyle` reports pixels, so assert the rule text, or use a Playwright check of the rendered width) |
| lede-009 | Edge Case: empty children | `<Lede></Lede>` | Component renders `<p class="lp-lede"></p>` with no children guard |
| lede-010 | accept-additional-class | `<Lede className="a b">Text</Lede>` | Rendered element class is `lp-lede a b` |
| lede-011 | meet-contrast-ratio | Rendered paragraph with `--lp-ink-dim` unset (fallback `#a0a0a0`) on the host's page background | The contrast ratio between `#a0a0a0` and the background is at least 4.5:1 |
## Edge Cases

- **Empty children**: If children is empty string or not provided, component renders an empty paragraph; no guard prevents this (lede-009).
- **Null or undefined className**: Optional className prop defaults to undefined; filtered out via **clean-class-attribute**.
- **Empty-string className**: An explicit `className=""` is also falsy and is filtered out the same way, leaving only `lp-lede`.
- **Whitespace-only className**: A className that is only whitespace (e.g. `" "`) is truthy, so **clean-class-attribute** does not filter it; the rendered class attribute keeps the stray whitespace token.
- **Multiple class names in className**: If className contains multiple space-separated class names, all are appended after `lp-lede`.
- **No className provided**: Component renders with only the `lp-lede` class.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `children` | ReactNode | required | The paragraph content |
| `className` | string | undefined | Optional additional CSS class(es) to apply |

## Deep Linking

Not applicable: Lede is a presentational component that does not handle routing or deep linking.

## Localization

Not applicable: Lede contains no text strings of its own. All text content is provided via children prop and subject to host application localization.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Dynamic Type / Font Scaling | Font size (`1.02rem`) and measure (`max-width: 72ch`, see **constrain-paragraph-measure**) are set in relative units, so the rendered paragraph scales with the user's font-size and browser-zoom preference without truncation. |
| Color Contrast | Text renders in the `--lp-ink-dim` token (fallback `#a0a0a0`); it MUST meet WCAG AA contrast against its background (see **meet-contrast-ratio** and **Compliance**). |
| Reduce Motion | Not applicable — Lede has no animation or transition. |

## Feature Flags

Not applicable: Lede is a core presentational component with no feature flag control.

## Analytics

Not applicable: Lede is a presentational component with no interactive behavior to track.

## Privacy

Not applicable: Lede renders provided content without collecting, storing, or transmitting data.

## Logging

Not applicable: Lede is a presentational component with no operational state or error conditions to log.

## Platform Notes

- **React/Web**: Render as `<p>` with `className` attribute; base class `lp-lede`, measure constrained to `max-width: 72ch`. Implementation filters falsy class values before joining with a space; a whitespace-only `className` value is not filtered.
- **SwiftUI**: Use a `Text` view; apply font, size, and color with `.font()` and `.foregroundStyle()` (not the deprecated `.foregroundColor()`), and constrain width with `.frame(maxWidth:)` where `maxWidth = 72 × the width of "0" in the chosen font` to match `lp-lede` styling. `Text` wraps by default.
- **Compose**: Use the `Text` composable, passing `color` directly (or a `style = TextStyle(color = ...)`) — Compose has no `.color()` modifier — along with `fontWeight` and `fontSize` parameters, and `Modifier.widthIn(max = ...)` where the max is 72 × the width of "0" in the chosen font, to match `lp-lede` styling. `Text` wraps by default.
- **AppKit / UIKit**: Use `NSTextField(wrappingLabelWithString:)` (macOS) or `UILabel` with `numberOfLines = 0` (iOS) to match `lp-lede` styling; both wrap by default. Constrain width with a layout constraint of `maxWidth = 72 × the width of "0" in the chosen font`. Configure font, size, and text color properties.
- **WinUI 3**: Use a `TextBlock` control with the `Text` property for content and `TextWrapping="Wrap"`; constrain width with `MaxWidth = 72 × the width of "0" in the chosen font` (rather than `Margin` padding) to match web styling. Set `FontSize`, `FontFamily`, and `Foreground` (color) properties.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Lede.tsx` | confirmed (1.1.2) |

## Design Decisions

**Decision**: Lede is implemented as a standalone component rather than scoped to appear only under a specific heading component (e.g. `Head`).
**Rationale**: The same voice and measure (`max-width: 72ch`, see **constrain-paragraph-measure**) are wanted for the odd paragraph that follows a card grid, a chip list, or another content block, not only the one under a heading.
**Approved**: pending

**Decision**: The paragraph measure is `max-width: 72ch`.
**Rationale**: The CSS comment in `blocks.css` says 72ch is wider than the 60ch a proportional face would want, because a monospace character is narrower than the average proportional one. That reasoning does not hold: in a monospace face every glyph is exactly 1ch wide, so 72ch is exactly 72 characters per line. The value is kept as the shipped measure. Because `ch` follows the host's font, a host that changes the font-family changes the physical width of the measure.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`semantic-markup` and `text-expansion-tolerance` pass because the source renders a plain `<p>` with no fixed width or overflow rule that would truncate wrapped or RTL text; `dynamic-type-support`, `contrast-ratio`, and `rtl-layout-support` are partial because the `lp-lede` CSS uses relative `rem`/`ch` units and `--lp-ink-dim`/`--lp-accent-bright` custom properties whose resolved values and RTL behavior this source cannot fully confirm. `separation-of-concerns` passes because the component is a plain `<p>` wrapper over `children`/`className` with no logic of its own; `unit-test-coverage` passes because `Lede.test.tsx` covers lede-001 to lede-011, with the CSS vectors (lede-008, lede-011) asserted against the stylesheet text.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.2 | 2026-11-14 | Mike Fullerton | Reworded the summary, moved the 72ch rationale to a Design Decision with the monospace reasoning corrected, promoted contrast to the meet-contrast-ratio requirement, made lede-007 informative, fixed lede-008 and lede-009, added vectors for multiple classes and contrast, gave native notes a measure formula, and removed the repeated implementation paths. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case, promote accept-additional-class to MUST, restate class filtering as observable clean-class-attribute with new edge-case vectors, add constrain-paragraph-measure with concrete lp-lede appearance values, reformat design decision, replace Compliance with an applicable-checks table, correct Platform Notes APIs and add wrapping guidance, add accessibility-options text-scaling guidance, unquote frontmatter dates, add tags |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
