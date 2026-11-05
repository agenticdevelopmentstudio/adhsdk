---
id: c9bdfe9a-6c8f-44c4-957e-757ecfa2e658
title: Group
domain: adhsdk://recipes/group
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A semantic section component that groups related content with optional title
  and hint.
platforms:
- typescript
- web
tags:
- layout
- grouping
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Group

## Overview

The Group component is a semantic section wrapper for organizing related content. It renders a `<section>` element and optionally displays a title as an h3 heading and a hint as descriptive text, with arbitrary children rendered in a body container. Group is a purely presentational component—it has no interactive states, does not respond to user input, and exists to structure and semantically mark content.

## Behavioral Requirements

- **grouping-container**: Component MUST render a semantic grouping container as its root.
- **title-when-provided**: When a `title` is provided, component MUST render it as a heading scoped to the group.
- **title-when-omitted**: When `title` is not provided or is falsy, component MUST NOT render a title element.
- **hint-when-provided**: When a `hint` is provided, component MUST render it as descriptive text associated with the group.
- **hint-when-omitted**: When `hint` is not provided or is falsy, component MUST NOT render a hint element (see **Edge Cases** for the literal-zero case, which is falsy but still visible).
- **children-in-body**: Children content MUST be rendered inside a body container, distinct from the title and hint.
- **base-style-applied**: Component MUST apply its base styling identity to the root element.
- **custom-style-accepted**: Component MUST accept a caller-supplied style/class extension and combine it with the base styling identity.
- **empty-style-filtered**: When combining style identifiers, empty or falsy values MUST be filtered out before combining.

Platform-specific DOM shape and class names (the `aws-group*` BEM classes, the
`<section>`/`<h3>`/`<p>`/`<div>` elements, and the class-string join/filter
logic) are the React/Web implementation of these requirements — see
**Platform Notes**.

## Appearance

- **Corner radius**: Not specified in component; controlled by CSS
- **Padding**: Determined by CSS classes `aws-group`, `aws-group__title`, `aws-group__hint`, `aws-group__body`
- **Font**: Title renders as `<h3>` (semantic heading); hint renders as `<p>` (semantic paragraph); styling determined by CSS
- **Background**: Not specified in component; controlled by CSS
- **Foreground/Text**: Not specified in component; controlled by CSS
- **Border**: Not specified in component; controlled by CSS
- **Shadow**: Not specified in component; controlled by CSS
- **Min/Max size**: No constraints defined in component

## States

Not applicable: Group is a static, presentational component. It does not have interactive states such as pressed, focused, disabled, or loading. State changes are managed by the content rendered within its children.

## Accessibility

- **Role/trait**: The root element is a semantic `<section>`. A `<section>` is only exposed to assistive technology as a named `region` landmark when it has an accessible name; Group sets no `aria-labelledby`/`aria-label`, and the title `<h3>` has no `id` to reference, so the root currently exposes no landmark role or name — screen readers traverse it as an unnamed generic container.
- **Title heading**: When rendered, the title element is an `<h3>` heading, which contributes to page structure and screenreader heading navigation independently of the section's landmark status above.
- **Hint text**: The hint is rendered as a `<p>` paragraph and is exposed to assistive technology as ordinary text; it is not programmatically associated with the group (e.g. via `aria-describedby`).
- **No ARIA attributes present**: Group renders no ARIA attributes; all exposure to assistive technology comes from the native semantics of `<section>`, `<h3>`, and `<p>`, subject to the landmark-naming limitation noted above.
- **Content accessibility**: Accessibility of Group content depends on the accessibility of its children. Group does not modify or wrap child content in ways that would degrade accessibility.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| group-001 | grouping-container, base-style-applied | Render with default props | Root element is `<section>` with class `aws-group` |
| group-002 | title-when-provided | `title="My Title"` | Renders `<h3 class="aws-group__title">My Title</h3>` |
| group-003 | title-when-omitted | No title prop | No h3 element present |
| group-004 | hint-when-provided | `hint="Descriptive text"` | Renders `<p class="aws-group__hint">Descriptive text</p>` |
| group-005 | hint-when-omitted | No hint prop | No `<p class="aws-group__hint">` element present |
| group-006 | children-in-body | `children="Content"` | Renders `<div class="aws-group__body">Content</div>` |
| group-007 | custom-style-accepted | `className="custom-class"` | Root element has both `aws-group` and `custom-class` |
| group-008 | empty-style-filtered | `className=""` (empty string) | Root element renders only `aws-group`, empty string filtered out |
| group-009 | title-when-provided, hint-when-provided, children-in-body | `title="Title" hint="Hint" children="Body"` | All three elements rendered in correct order: h3, p, div |
| group-010 | custom-style-accepted | `className="foo bar"` (multiple space-separated classes) | Root element renders `aws-group foo bar`; all space-separated classes preserved |
| group-011 | empty-style-filtered | `className={null}` | Root element renders only `aws-group`; `null` is filtered out, no stray whitespace or literal `"null"` |
| group-012 | children-in-body | No `children` prop | `<div class="aws-group__body">` is present and empty |

## Edge Cases

- **Null title**: When `title` is `null` or `undefined`, the component treats it as falsy and does not render a title element.
- **Empty title**: When `title` is an empty string `""`, it is falsy and does not render a title element.
- **Falsy hint**: When `hint` is `null`, `undefined`, `false`, or empty string `""`, nothing renders in its place. When `hint` is the number `0`, the `<p class="aws-group__hint">` wrapper still does not render, but the literal text `0` renders directly inside the `<section>` — the `hint && <p>…</p>` pattern short-circuits to the falsy operand itself, and React renders that bare `0` as a text node.
- **No children**: When `children` is not provided, `undefined`, or `null`, the body div is rendered empty but still present.
- **React node children**: The `title`, `hint`, and `children` props accept `ReactNode`, which may be strings, numbers, elements, fragments, arrays, or null. All valid React node types MUST render correctly.
- **Multiple children**: When `children` is an array (list of React elements), all items MUST render within the body div without modification.
- **Custom className combinations**: When `className` contains multiple space-separated classes, all MUST be preserved and applied to the root element.
- **Null/empty custom className**: When `className` is `null`, `undefined`, or empty string `""`, it MUST be filtered out and not added to the element.

## Configuration

Not applicable: Group has no configuration options beyond its props. It does not expose settings, feature toggles, or runtime configuration.

## Deep Linking

Not applicable: Group is a presentational component with no navigation or deep-linking concerns. Deep linking is managed by the consuming application.

## Localization

Not applicable: Group does not render any static text or UI strings of its own. All user-facing text—title, hint, and children content—is provided by the parent component and may be localized by the application.

## Accessibility Options

Not applicable: Group does not respond to platform accessibility display options such as Reduce Motion or Increase Contrast. It relies on CSS styling controlled by the application theme.

## Feature Flags

Not applicable: Group has no feature flags. It is always enabled and has no conditional rendering based on runtime configuration.

## Analytics

Not applicable: Group is a presentational component and does not emit analytics events. Analytic instrumentation is the responsibility of parent components that use Group.

## Privacy

Not applicable: Group does not collect, store, or transmit any data. It is a stateless presentation layer.

## Logging

Not applicable: Group does not perform any logging. It is a purely presentational component.

## Platform Notes

- **React/Web**: Source file is `packages/web/packages/controls/src/user-settings/components/Group.tsx`. Renders a semantic `<section>` with class `aws-group`. Optional title and hint render as `<h3 class="aws-group__title">` and `<p class="aws-group__hint">`. Children render in `<div class="aws-group__body">`. Supports a custom `className` prop merged with the base class, filtering out empty or falsy values before joining. Styling is CSS-driven via class names; no inline styles.
- **SwiftUI**: Use `Section` when Group appears inside a `Form` or `List` (so it participates in that container's native section chrome); use a `VStack` otherwise. Render an optional `Text` for title styled as a heading, marked with `.accessibilityAddTraits(.isHeader)` so VoiceOver treats it as a heading; render an optional caption `Text` for hint and attach it to the group with `.accessibilityHint(_:)` on the container so VoiceOver associates the hint with the group. Arrange child views below. Differences from web: SwiftUI uses `Section`/`VStack` for semantic grouping instead of `<section>`, text styling is controlled by font modifiers rather than CSS, and layout is vertical-first.
- **Compose**: Use a `Column` or `Surface` to group content. Render optional `Text` for title with heading style and mark it with `Modifier.semantics { heading() }` so it is announced as a heading; render optional `Text` for hint and tie it to the group by setting `Modifier.semantics { contentDescription = hintText }` on the container so assistive tech associates it with the group. Render child composables. Differences: Compose lacks a direct semantic grouping equivalent; use container composition. Layout is column-based. Styling via Material Design tokens.
- **AppKit / UIKit**: Use `NSStackView` (AppKit) or `UIStackView` (UIKit) to group views. UIKit: render an optional `UILabel` for title styled as a heading and set `label.accessibilityTraits = .header` so VoiceOver announces it as a heading; render an optional label for hint and tie it to the group by setting the stack view's `accessibilityHint` from the hint text. AppKit: render an optional `NSTextField` for title styled as a heading; AppKit has no direct heading trait, so also set the stack view's `accessibilityLabel` from the title text; render an optional text field for hint and tie it to the group by setting the stack view's `accessibilityHelp` from the hint text. Differences: Use native stack views for layout; no CSS classes. Accessibility comes from native accessibility APIs on each view.
- **WinUI 3**: Use `StackPanel` with `Orientation="Vertical"` as the root to group content. Render optional `TextBlock` for title with `Style="{StaticResource HeadingTextBlockStyle}"` and set `AutomationProperties.HeadingLevel="Level3"` so Narrator announces it as a heading; render optional `TextBlock` for hint and tie it to the group via `AutomationProperties.DescribedBy` pointing at the hint `TextBlock`. Place child `UIElement` instances in the stack panel. Differences: WinUI uses XAML-defined brushes and styles instead of CSS classes; layout is managed by `StackPanel` properties like `Spacing`; semantic grouping is implicit via panel composition rather than a `<section>` element.

## Design Decisions

**Decision**: Appearance (color, spacing, typography, borders) is left entirely to the caller's CSS; Group applies no inline styles or built-in visual treatment of its own.
**Rationale**: Keeps the component minimal, semantically-correct, and reusable across different design contexts without imposing an opinionated look.
**Approved**: pending

**Decision**: The base class (`aws-group`) and its sub-elements (`aws-group__title`, `aws-group__hint`, `aws-group__body`) follow BEM naming.
**Rationale**: Makes the styling contract predictable and maintainable for consumers writing CSS against the component.
**Approved**: pending

**Decision**: Group accepts a caller-supplied `className` and merges it with the base class rather than replacing it, filtering out empty or falsy values before joining.
**Rationale**: Lets consumers layer additional styling onto Group without having to reimplement or fork the component.
**Approved**: pending

**Decision**: The title always renders as a fixed `<h3>` heading; there is no `headingLevel` prop to vary the depth.
**Rationale**: Matches the component's current usage context; a caller needing a different heading depth restyles or wraps Group rather than reconfiguring it, keeping the contract simple.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on `Group.tsx` rendering semantic `<section>`/`<h3>`/`<p>` elements with no ARIA attributes and no accessible name wired to the section (see **Accessibility**), and on the component deferring all typography, color, and spacing to CSS classes (`aws-group*`) that it does not itself define, so dynamic type and contrast cannot be confirmed from the source. `separation-of-concerns` is `passed` because the component is pure presentation over `title`/`hint`/`children` props with no business logic; `unit-test-coverage` is `failed` because no test exercises `user-settings/components/Group.tsx` — the candidate tests found by name (`AnimTests.swift`, `ConfigTests.swift`, etc.) test unrelated avatar-engine code, not this component.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: platform-neutral behavioral requirements; corrected section-landmark accessibility claim; corrected hint-of-0 edge case; reformatted Design Decisions into Decision/Rationale/Approved entries; added accessibility Compliance table; fixed self-contradictory Appearance corner-radius wording; merged/scoped/added conformance test vectors; clarified SwiftUI `Section` guidance; added heading/hint accessibility wiring to native Platform Notes |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
