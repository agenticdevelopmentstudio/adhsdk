---
id: eeb45f5b-e482-4bea-8827-74f80a1fd21b
title: Explanation
domain: adhsdk://recipes/explanation
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A semantic paragraph wrapper that applies a default style class and accepts
  optional additional CSS classes.
platforms:
- typescript
- web
tags:
- text
- typography
- container
depends-on: []
related:
- adhsdk://recipes/settings-panel
- adhsdk://recipes/group
- adhsdk://recipes/field
- adhsdk://recipes/header
references: []
approved-by: ''
approved-date: ''
---

# Explanation

## Overview

The Explanation component renders explanatory or descriptive text within a semantic paragraph element. It provides a consistent, styled wrapper for text content by applying a default CSS class (`aws-explanation`) and allows consumers to add supplementary styles via an optional `className` prop. This component is used to present contextual information, help text, or clarifying descriptions in user interfaces.

## Behavioral Requirements

- **render-paragraph**: Component MUST render a `<p>` HTML element.
- **apply-default-class**: Component MUST apply the class name `aws-explanation` to the rendered element.
- **render-children**: Component MUST render all provided `children` content inside the paragraph element.
- **accepts-optional-classname**: Component MAY accept an optional `className` prop.
- **combine-classnames**: Component MUST combine the default class name with the optional `className` prop, separated by a space, if `className` is provided.
- **filter-falsy-classnames**: Component MUST filter out falsy or empty class name values before rendering to prevent invalid class attributes.

## Appearance

Visual styling is determined entirely by CSS classes applied to the element. The component applies:

- **Default class**: `aws-explanation`, defined by the `.aws-explanation` rule in the user-settings stylesheet (`packages/web/packages/controls/src/user-settings/styles.css`) and shared with the sibling Panel, Group, Field, Header, Divider, Stack, and Hint components through the `:where(...)` selector at the top of that file.
- **Custom classes**: Additional classes from the `className` prop are applied alongside the default

Appearance properties, from `.aws-explanation` in `styles.css`: margin `0`, color `var(--aws-text-muted)` (resolves through `--color-text-secondary` / `--text-muted` to `#8a8a9a`), font size `0.8rem`, line-height `1.5`. Font family is not set on `.aws-explanation` itself — it inherits `var(--aws-font-sans)` (`system-ui, sans-serif`) from the ancestor `.aws-panel`.

## States

Not applicable: Explanation is a non-interactive presentational component and does not have interactive states such as pressed, focused, or disabled.

## Accessibility

- **Semantic element**: Component MUST use the `<p>` element to maintain semantic meaning for screen readers and document structure.
- **Content accessibility**: Text content rendered as children inherits the color and typography defined by the `.aws-explanation` rule in `styles.css`, which sets its text color from the `--aws-text-muted` design token. Whether the resolved token value meets WCAG 2.1 AA contrast has not been checked — see **Compliance**.
- **Label inheritance**: The paragraph element does not require an explicit label; the rendered text content serves as the semantic label.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| explanation-001 | render-paragraph | `<Explanation>Hello</Explanation>` | Renders as `<p class="aws-explanation">Hello</p>` |
| explanation-002 | apply-default-class | Any props | Rendered element contains class `aws-explanation` |
| explanation-003 | render-children | `<Explanation>Text content</Explanation>` | Text content appears inside the paragraph |
| explanation-004 | accepts-optional-classname | `<Explanation className="custom-class">Text</Explanation>` | Rendered element has both `aws-explanation` and `custom-class` |
| explanation-005 | combine-classnames | `<Explanation className="extra">Content</Explanation>` | Rendered class attribute is `"aws-explanation extra"` |
| explanation-006 | filter-falsy-classnames | `<Explanation className="">Text</Explanation>` | Rendered class attribute is `"aws-explanation"` (empty string filtered out) |
| explanation-007 | render-children | `<Explanation><span>Rich</span> content</Explanation>` | React children (including JSX elements) render correctly inside paragraph |
| explanation-008 | render-paragraph | `<Explanation />` (children omitted) | Renders as `<p class="aws-explanation"></p>` |
| explanation-009 | render-paragraph | `<Explanation>{''}</Explanation>` (empty-string children) | Renders as `<p class="aws-explanation"></p>` |
| explanation-010 | filter-falsy-classnames | `<Explanation className={undefined}>Text</Explanation>` | Rendered class attribute is `"aws-explanation"` |
| explanation-011 | filter-falsy-classnames | `<Explanation className="   ">Text</Explanation>` | Rendered class attribute is `"aws-explanation    "` (whitespace-only string is truthy, so it passes through unchanged) |
| explanation-012 | combine-classnames | `<Explanation className="class1 class2">Text</Explanation>` | Rendered class attribute is `"aws-explanation class1 class2"` (internal whitespace between classes is preserved) |

## Edge Cases

- **Null or undefined children**: Component MUST render an empty paragraph element with class `aws-explanation` when children is null or undefined.
- **Empty children**: Component MUST render an empty paragraph element with class `aws-explanation` when children is an empty string or empty array.
- **Undefined className**: Component MUST treat undefined `className` as absent and render only the default class name.
- **Empty string className**: Component MUST filter out empty string `className` values and render only the default class name.
- **Whitespace-only className**: `filter-falsy-classnames` only removes values that are falsy (`""`, `undefined`, `null`, `false`); a whitespace-only string such as `"   "` is truthy, so it is NOT filtered or trimmed. It passes through untrimmed, and the resulting class attribute contains the default class followed by that whitespace (see explanation-011).
- **Multiple classes in className**: Component MUST preserve spacing between multiple classes provided in the `className` prop (e.g., `"class1 class2"` renders as `"aws-explanation class1 class2"`); internal whitespace within the provided string is not modified (see explanation-012).

## Configuration

Not applicable: Explanation has no configuration options beyond React props (`children` and `className`).

## Deep Linking

Not applicable: Explanation is a text presentation component and does not participate in deep linking or URL routing.

## Localization

Not applicable: Explanation does not contain hard-coded strings. All text content is provided by consumers via `children`.

## Accessibility Options

Not applicable: Explanation has no motion or other platform-accessibility-option-specific behavior. It delegates accessible rendering to the semantic `<p>` element and relies on the shared `aws-explanation` CSS class for typography and color.

## Feature Flags

Not applicable: Explanation has no feature flags. It is always available and has no conditional behavior.

## Analytics

Not applicable: Explanation is a presentational component and does not emit analytics events on its own.

## Privacy

Not applicable: Explanation does not collect, store, or transmit any user data. It renders content provided by consumers without side effects.

## Logging

Not applicable: Explanation does not perform logging or error tracking.

## Platform Notes

- **React/Web**: Source implementation uses JSX with TypeScript. Export the `Explanation` function component with `ExplanationProps` interface defining `children?: ReactNode` and `className?: string`. Combine classes using array filter-and-join pattern to handle falsy values. Reference source file: `packages/web/packages/controls/src/user-settings/components/Explanation.tsx`; class defined by the `.aws-explanation` rule in `styles.css`.
- **SwiftUI**: Implement using a `Text` view sized around 13pt (0.8rem ≈ 12.8px) with `.foregroundStyle(.secondary)` mapping the `--aws-text-muted` token, and line spacing tuned to approximate the 1.5 line-height. Accept content via a `String`/`Text` parameter or `@ViewBuilder`; do not hardcode a font family so the view inherits the ambient font.
- **Compose**: Implement using a `Text` composable with a style around `fontSize = 13.sp`, `lineHeight = 19.5.sp` (1.5x), and `color = MaterialTheme.colorScheme.onSurfaceVariant` mapping `--aws-text-muted`. Accept content as a `String` or `@Composable` lambda and an optional `Modifier` for caller-supplied styling.
- **AppKit / UIKit**: Configure a stock `UILabel` (UIKit) or `NSTextField` (AppKit) through a factory or style-helper function rather than subclassing it: set `numberOfLines = 0`, a ~13pt font, and the platform's secondary/muted label color (mapping `--aws-text-muted`). Pass optional style overrides as parameters to the factory instead of through inheritance.
- **WinUI 3**: Implement using a `TextBlock` whose `Style` is layered with an explicit `BasedOn`, e.g. a `CaptionTextBlockStyle` resource with `BasedOn="{StaticResource BodyTextBlockStyle}"` setting `FontSize="13"` and `Foreground="{ThemeResource TextFillColorSecondaryBrush}"` (mapping `--aws-text-muted`). Accept an optional `Style` property override that layers further on top of that base style, and bind content from a backing property.

## Design Decisions

- **Decision**: Combine class names using an array filter-and-join pattern (`[defaultClass, className].filter(Boolean).join(' ')`).
  **Rationale**: Prevents invalid or malformed `class` attributes (e.g., a trailing double space from a falsy `className`) while keeping the implementation simple and readable.
  **Approved**: pending

- **Decision**: Use a `<p>` element as the component's root, rather than a `<div>` or `<span>`.
  **Rationale**: Preserves semantic meaning in the document outline and ensures screen reader compatibility; `<div>` or `<span>` would lose that semantic information.
  **Approved**: pending

- **Decision**: The `aws-explanation` class is fixed and not configurable per instance.
  **Rationale**: The `.aws-explanation` rule is defined once in the user-settings stylesheet (`styles.css`) and shared with sibling components (Panel, Group, Field, Header, Divider, Stack, Hint) through the `:where(...)` rule, keeping visual consistency across the settings panel; per-instance overrides would fragment that consistency.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`semantic-markup` and `no-hardcoded-strings` rest on `Explanation.tsx` rendering a `<p>` element whose only content is the caller-supplied `children` prop, with no literal user-facing strings in the source. `contrast-ratio` is `partial` because the `aws-explanation` text color (`--aws-text-muted`, set by the `.aws-explanation` rule in `styles.css`) has not been checked against its resolved value for WCAG 2.1 AA contrast. `separation-of-concerns` is `passed` because the component is pure presentation over `children` with no logic beyond a class-name join; `unit-test-coverage` is `failed` because no test exercises `Explanation.tsx`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: removed unsupported AWS Amplify attribution; downgraded contrast-ratio compliance to partial and added internationalization check; removed false prefers-reduced-motion claim; replaced AppKit/UIKit subclassing guidance with a composition-based factory pattern; renamed must-* requirements to subject-only kebab-case everywhere they are cited; added related sibling recipes; corrected the self-contradictory whitespace-className edge case and retitled multiple-classes edge case; removed the unsupported false/null className edge case; added test vectors for null/undefined/empty children and undefined/whitespace-only className; added concrete appearance values (color token, font size, line-height) to Appearance and mapped each Platform Notes bullet onto them; reformatted Design Decisions into Decision/Rationale/Approved form |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Removed five source line-number citations (styles.css:180 etc.), replaced with the .aws-explanation rule name. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
