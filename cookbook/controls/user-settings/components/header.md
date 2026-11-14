---
id: c2f89e6b-6e86-449b-9955-5bb0da929de3
title: "Header"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A semantic heading wrapper that renders an h2 element with optional CSS class composition."
platforms:
  - typescript
  - web
tags:
  - heading
  - typography
depends-on: []
related:
  - 432e8d4b-43c3-49fd-b481-036a759e7c55
references:
  - https://developer.mozilla.org/en-US/docs/Web/HTML/Element/h2
  - https://www.w3.org/TR/html-aria/
approved-by: ""
approved-date: ""
---

# Header

## Overview

The Header component is a semantic HTML heading wrapper that renders a level-2 heading (`<h2>`) element. It accepts optional content and composes CSS classes per #requirements/class-composition. This component is used to display section headings and page subdivisions with proper semantic meaning for accessibility.

## Behavioral Requirements

- **h2-element**: Component MUST render a semantic `<h2>` HTML element.
- **default-class**: Component MUST always include the `aws-header` CSS class on the rendered element.
- **class-composition**: Component MUST combine the `aws-header` class with any `className` prop provided, filtering out falsy values before joining.
- **children-content**: Component MUST render the content passed via the `children` prop (if any) inside the heading element.
- **classname-prop**: Component MUST accept an optional `className` prop to allow consumer-supplied CSS classes to be applied alongside the default class.

## Appearance

- **Element type**: `<h2>` semantic heading element
- **Default class**: `aws-header`
- **Class composition**: See #requirements/class-composition.
- **Font**: Inherits from parent styling context; specific font weight, size, and color are controlled by CSS class definitions (not the component)
- **Background**: Inherits from parent; no inline styles applied
- **Padding/Margin**: Controlled by CSS classes, not the component
- **Border**: None by default; can be applied via CSS classes
- **Shadow**: None by default; can be applied via CSS classes

## States

| State | Behavior |
|-------|----------|
| Default | Component renders with `aws-header` class and any user-supplied classes; content is visible. |

The Header component is a static, non-interactive element and does not have pressed, disabled, focused, or loading states.

## Accessibility

- **Role**: Implicit `heading` role via native `<h2>` element (heading level 2).
- **Label**: Content passed via `children` prop serves as the heading label; it MUST be meaningful and descriptive of the section it introduces.
- **Semantic structure**: By rendering a native `<h2>` element, the component provides proper outline nesting for screen readers and document outline tools.
- **Announcements**: Screen readers automatically announce this element as a heading at level 2; no additional state announcement is needed.
- **Keyboard navigation**: Not applicable; the component is non-interactive and does not receive focus.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|-------|-------------|-------|----------|
| header-001 | h2-element | Render `<Header>Test</Header>` | DOM contains `<h2>...</h2>` element. |
| header-002 | default-class | Render `<Header>Test</Header>` | Rendered `<h2>` has `aws-header` class. |
| header-003 | class-composition, classname-prop | Render `<Header className="custom">Test</Header>` | Rendered `<h2>` has both `aws-header` and `custom` classes. |
| header-004 | children-content | Render `<Header><span>Child</span></Header>` | Rendered `<h2>` contains the child element. |
| header-005 | class-composition | Render `<Header className={undefined}>Test</Header>` | Rendered `<h2>` has only `aws-header` class; `undefined` is filtered out. |
| header-006 | class-composition | Render `<Header className="">Test</Header>` | Rendered `<h2>` has only `aws-header` class; empty string is filtered out. |

## Edge Cases

- **Null or undefined children**: If `children` is `undefined` or `null`, the heading renders empty but still displays the `<h2>` element with the `aws-header` class. MUST render successfully without error. Consumers MUST NOT render a `Header` with no content: an empty heading has no accessible label and is a barrier for screen reader users (see #accessibility above).
- **Empty className**: If `className` is an empty string or `undefined`, only the `aws-header` class is applied. MUST NOT produce duplicate spaces or malformed class attributes.
- **Multiple className values**: If `className` contains multiple space-separated class names (e.g., `"class1 class2"`), the component MUST preserve all of them when composing with `aws-header`.
- **Special characters in className**: If `className` contains special characters or unusual values, the component MUST pass them through to the DOM without sanitization (delegating to React's default behavior).
- **Non-string children**: If `children` is a React component, element, or other `ReactNode`, the component MUST render it as-is without type checking.

## Configuration

Not applicable: The Header component does not expose configuration options beyond props. All styling is controlled via CSS classes.

## Deep Linking

Not applicable: The Header component is a presentational element without deep linking semantics.

## Localization

Not applicable: The Header component does not render any UI strings of its own. Text content is provided via the `children` prop and is the consumer's responsibility to localize.

## Accessibility Options

Not applicable: The Header component is a static heading and does not respond to platform-specific accessibility display options such as Reduce Motion, Increase Contrast, or Differentiate Without Color.

## Feature Flags

Not applicable: The Header component does not implement feature flags or conditional behavior based on feature flags.

## Analytics

Not applicable: The Header component is non-interactive and does not emit analytics events. If analytics tracking is needed, consumers can instrument their use of the component at a higher level.

## Privacy

Not applicable: The Header component does not collect, store, transmit, or process any user data or sensitive information.

## Logging

Not applicable: The Header component does not perform logging or diagnostic operations.

## Platform Notes

- **React/Web**: Component is implemented in React using JSX, rendering the native `<h2>` HTML element with conditional class composition. Source file: `packages/web/packages/controls/src/user-settings/components/Header.tsx`. The component uses array filter and join pattern to safely compose class names, dropping falsy values.
- **SwiftUI**: Implement using `Text` with `.font(.title2)` for level-2 heading styling. Mark it as a heading for assistive technology with `.accessibilityAddTraits(.isHeader)` (or `.accessibilityHeading(.h2)` where available) so VoiceOver announces it as a heading. Apply the equivalent of the `aws-header` class styling via a custom `ViewModifier`.
- **Compose**: Implement using a `Text` composable styled with `MaterialTheme.typography.headlineSmall` (or the app's level-2 type-scale equivalent) and apply `Modifier.semantics { heading() }` so TalkBack announces it as a heading. Wrap it in a custom composable to encapsulate the default styling and allow class-like composition via modifier chains.
- **AppKit / UIKit**: On iOS, implement using `UILabel` with a heading-appropriate font and set `accessibilityTraits = .header` so VoiceOver announces it as a heading. On macOS, implement using `NSTextField` with a heading-appropriate font and call `setAccessibilityRole(.heading)` on the field to signal heading semantics to VoiceOver. Apply frame constraints and view modifiers to compose the equivalent of the `aws-header` class styling.
- **WinUI 3**: Implement using `TextBlock` with `FontSize` and `FontWeight` set to heading level 2 (typically 18–22pt, semibold), and set `AutomationProperties.HeadingLevel = AutomationHeadingLevel.Level2` for accessibility. `TextBlock` is not a `Control` and has no `ControlTemplate`; instead define a `Style` (`TargetType="TextBlock"`) carrying the default `aws-header`-equivalent styling, and let callers layer additional styling with their own `Style` `BasedOn` that default.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/Header.tsx` | unverified |

## Design Decisions

1. **Decision**: The component renders `<h2>` rather than a generic `<div>`, with the heading level fixed rather than configurable.
**Rationale**: A fixed level-2 heading ensures proper document outline and accessibility for the component's intended use inside `user-settings` sections, which sit at a single, known depth in the page outline (see [adhsdk.ingredient.ui.settings.settings-panel](cookbook:432e8d4b-43c3-49fd-b481-036a759e7c55)). Consumers who need a different heading level should wrap the content or use a different component rather than parameterize this one.
**Approved**: pending

2. **Decision**: The component always includes the `aws-header` class as a fixed, non-removable default identity class.
**Rationale**: `aws-header` represents the component's identity and gives every instance a consistent styling baseline; additional classes are composed alongside it (see #requirements/class-composition) so consumers can customize without losing the base style.
**Approved**: pending

3. **Decision**: Class composition uses a simple array-filter-and-join pattern (`['aws-header', className].filter(Boolean).join(' ')`) rather than conditional rendering or a CSS-in-JS library.
**Rationale**: This keeps the component lightweight and compatible with plain CSS, CSS Modules, and other styling systems. The filter step prevents double spaces when `className` is falsy (see #requirements/class-composition).
**Approved**: pending

4. **Decision**: Children accept any ReactNode.
**Rationale**: `HeaderProps` defines `children?: ReactNode`, which permits any React-renderable content — fragments, components, or strings — without type checking (see #requirements/children-content). This flexibility allows the component to be used in many contexts without modification.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`semantic-markup` passes because the source renders the native `<h2>` element directly, giving it a correct implicit heading role. `dynamic-type-support` is partial because the source applies no font-size styling of its own — it defers text scaling entirely to consumer-supplied CSS classes, which the source cannot verify. `separation-of-concerns` is `passed` because the component is pure presentation over `children` with no business logic; `unit-test-coverage` is `failed` because no test exercises `user-settings/components/Header.tsx` — the candidate tests found by name test unrelated Swift/hub-client and other web code, not this component.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names and promoted className acceptance to a MUST; rewrote Compliance as a table; corrected the SwiftUI, Compose, AppKit, and WinUI 3 platform notes to real APIs; reformatted Design Decisions to Decision/Rationale/Approved and retitled the ReactNode decision; fixed test-vector fragment refs and RFC 2119 casing; added a related link to the settings-panel recipe and a decision recording the fixed heading depth. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
