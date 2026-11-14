---
id: 688cd8dc-2927-4a8a-9931-807fe283ed01
title: "Closer"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A centered container block that serves as the final call to action, positioned after hero content."
platforms:
  - typescript
  - web
tags:
  - layout
  - container
  - call-to-action
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Closer

## Overview

The Closer component is a container block that renders a centered call-to-action section: it wraps a title (rendered as an h2 heading) and arbitrary child content, and supports an optional CSS class name merged onto the root element for additional styling integration with parent layouts.

Usage note: Closer is typically composed as the concluding element after hero or introductory content on a page (see `Contact`, which composes it to add a mailto and colophon), but that placement is a caller decision — the component itself renders the same way regardless of where it sits on the page.

## Behavioral Requirements

- **render-title**: The component MUST render the `title` prop as the first child within an h2 element.
- **render-children**: The component MUST render the `children` prop after the title element.
- **apply-lp-closer-class**: The component MUST apply the CSS class `lp-closer` to its root div element.
- **merge-optional-classname**: When a `className` prop is provided, the component MUST merge it with the base `lp-closer` class (base first) and MUST NOT emit leading, trailing, or doubled whitespace in the resulting className when `className` is empty or absent.

## Appearance

- **Structure**: Block-level container rendered as a `<div>`. The component applies no inline styles itself; all visual treatment comes from the `lp-closer` CSS class in `packages/web/packages/landing/src/css/blocks.css`.
- **Background**: Transparent — no background rule is set on `.lp-closer` or `.lp-closer h2`.
- **Padding**: `.lp-closer` sets `padding-top: var(--lp-gap, clamp(3.75rem, 8vw, 6.5rem))`; no other padding is applied.
- **Border**: `.lp-closer` sets `border-top: 1px solid var(--lp-hairline, rgba(216, 216, 216, 0.18))`; there is no border on any other edge.
- **Text alignment**: `.lp-closer` sets `text-align: center`. The title's `h2` additionally sets `text-wrap: balance` and a responsive `font-size: clamp(1.5rem, 4vw, 2.4rem)` with `font-weight: 200`.
- **Width**: 100% of container — default block-level `<div>` behavior; `.lp-closer` sets no explicit width.

## States

The Closer component is a static presentational component with no interactive states. Not applicable: no pressed, focused, loading, or disabled states are supported.

## Accessibility

- **Semantic structure**: The component uses an h2 heading element for the title, providing proper document outline hierarchy.
- **Title labeling**: The title prop establishes context for the section. Screen readers announce the h2 and its content as a heading.
- **Content containment**: Child content is contained within the same block, creating a single logical section for screen readers.
- **Keyboard navigation**: Not applicable — the component is non-interactive. Keyboard focus may enter child elements if they are interactive.

## Conformance Test Vectors

| ID | Requirement | Input | Action | Expected |
|----|-----------|----|--------|----------|
| closer-001 | render-title | `title="Get Started"`, `children=<div>form</div>` | Render component | h2 element contains text "Get Started" |
| closer-002 | render-children | `title="Call"`, `children=<button>Sign Up</button>` | Render component | Button element is rendered after the h2 |
| closer-003 | apply-lp-closer-class | `title="X"`, `children=null` | Render component | Root div has className containing "lp-closer" |
| closer-004 | merge-optional-classname | `title="X"`, `className="custom-styling"` | Render component | Root div className equals "lp-closer custom-styling" |
| closer-005 | merge-optional-classname | `title="X"`, `className=""` | Render component | Root div className equals "lp-closer" (no trailing space) |
| closer-006 | merge-optional-classname | `title="X"`, `className=undefined` | Render component | Root div className equals "lp-closer" |
| closer-007 | render-children | `title="X"`, `children=null` | Render component | Component renders without error; no content follows the h2 |
| closer-008 | render-title | `title=<span>Ready?</span>`, `children=null` | Render component | h2 element contains the rendered `<span>Ready?</span>` element |

## Edge Cases

- **Empty title**: When `title=""` is passed, the component still renders an h2 element (satisfying **render-title**), but it contains no text. Callers SHOULD NOT pass an empty title — an empty heading is confusing for screen reader users navigating by heading — but the component itself does not guard against it.
- **Null or undefined children**: When `children` is null or undefined, the component MUST render the div and h2 without error (**render-children**). No child content renders below the title. See vector closer-007.
- **Empty className**: When `className=""` is provided, `.filter(Boolean)` removes it, leaving only "lp-closer" in the final className (**merge-optional-classname**).
- **Undefined className**: When `className` is not provided, only "lp-closer" is applied to the root element (**merge-optional-classname**).
- **ReactNode composition**: The `title` and `children` props accept any valid ReactNode (strings, elements, fragments, arrays). The component renders them without modification. Expected: Component MUST accept and render ReactNode values without error. See vector closer-008.

## Configuration

Not applicable: the component accepts no configuration beyond its three props (title, children, className). Configuration is handled via CSS class definitions and parent layout composition.

## Deep Linking

Not applicable: the Closer component is a layout container with no inherent link target or navigation functionality.

## Localization

Not applicable: the component has no hardcoded text. The `title` prop is passed by the caller and may be localized by the parent application.

## Accessibility Options

Not applicable: the component is a static container without interactive features or display modes that respond to accessibility settings.

## Feature Flags

Not applicable: the component has no conditional rendering or feature-gated behavior.

## Analytics

Not applicable: the Closer component is a presentational container. Event tracking is handled by child components or parent code.

## Privacy

Not applicable: the component collects no user data and transmits no information.

## Logging

Not applicable: the component performs no operations that require event logging.

## Platform Notes

- **TypeScript / Web (React)**: Implemented in `packages/web/packages/landing/src/blocks/Closer.tsx`. The component uses a functional component signature, accepts ReactNode props for title and children, merges className via `[base, className].filter(Boolean).join(' ')` to avoid leading, trailing, or doubled whitespace, and renders a semantic h2 for the title within a `<div className="lp-closer">`; all visual styling (centering, border, spacing) comes from `.lp-closer` in `css/blocks.css`.

- **SwiftUI**: Use a `VStack` with `.frame(maxWidth: .infinity, alignment: .center)` and `.multilineTextAlignment(.center)` for centering. Render the title as `Text` with `.font(.title2)` and `.accessibilityAddTraits(.isHeader)` so it is announced as a heading rather than merely styled like one. Accept a `@ViewBuilder` closure for children, and expose styling as a `ViewModifier` (or a custom `Style` protocol) rather than a CSS class name string.

- **Compose**: Use a `Column` with `Modifier.fillMaxWidth()` and `horizontalAlignment = Alignment.CenterHorizontally`. Render the title as `Text` with `style = MaterialTheme.typography.headlineSmall` and `Modifier.semantics { heading() }` so accessibility services expose it as a heading. Define the content parameter as `content: @Composable ColumnScope.() -> Unit`. Accept styling as a `Modifier` parameter rather than a CSS class name string.

- **AppKit / UIKit**: Use a vertical `UIStackView` / `NSStackView` (axis `.vertical`), centered horizontally within its superview. Render the title as `UILabel` / `NSTextField` with `UIFont.preferredFont(forTextStyle: .headline)` and `accessibilityTraits = .header` so VoiceOver exposes it as a heading. Accept a content view (or view array) for children, and expose styling as a reusable style/appearance function rather than a CSS class name string.

- **WinUI 3**: Use a `StackPanel` with `Orientation="Vertical"`, stretched to its container (`HorizontalAlignment="Stretch"`) — a `StackPanel`'s own `HorizontalAlignment` centers the panel, not the text inside it — with `TextAlignment="Center"` set on the title and child text elements. Render the title as a `TextBlock` using `SubtitleTextBlockStyle` with `AutomationProperties.HeadingLevel="Level2"` for heading semantics, rather than a hardcoded font size. Define a content property for child elements, and expose styling as a `Style` resource rather than a CSS class name string.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Closer.tsx` | unverified |

## Design Decisions

- **h2 as title element**

  **Decision**: The component always renders the title within an h2 heading and does not expose a heading-level parameter.
  **Rationale**: Provides semantic structure and establishes a consistent position in the screen reader outline; the component assumes it is always a section-level conclusion.
  **Approved**: pending

- **className merge strategy**

  **Decision**: The className prop is merged with the base class via `[base, className].filter(Boolean).join(' ')`, with `lp-closer` always placed first.
  **Rationale**: `.filter(Boolean)` drops falsy values so an empty or undefined `className` produces no leading, trailing, or doubled whitespace, letting callers pass conditional class names without manual trimming. `lp-closer` is placed first only to produce a deterministic, testable className string — class order in the attribute has no effect on CSS specificity.
  **Approved**: pending

- **No default styling within the component**

  **Decision**: The Closer component applies no inline styles. All visual styling, including centering, spacing, and the border, is delegated to the `lp-closer` CSS class.
  **Rationale**: Allows consumers to fully control appearance via CSS and avoids inline/CSS style conflicts.
  **Approved**: pending

- **ReactNode flexibility**

  **Decision**: Both `title` and `children` accept ReactNode and are passed through without transformation or cloning.
  **Rationale**: Supports rich content (not just strings) and enables complex compositions in parent layouts.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on the source: `<h2>{title}</h2>` is correct semantic markup; `.lp-closer h2` uses a `clamp()`-based responsive `font-size` (partial confidence on dynamic type, since the component sets no fixed pixel size but the full scaling chain isn't visible from the component alone); `title`/`children` are always caller-supplied ReactNode with no strings owned or hardcoded by the component; and `.lp-closer`'s `text-align: center` and lack of directional (left/right) properties impose no RTL-breaking layout, while `h2`'s `text-wrap: balance` and the paragraph's `max-width: 48ch` suggest — but cannot fully confirm — tolerance for expanded translated text. separation-of-concerns passes because `Closer.tsx` is pure presentation over its `title`/`children`/`className` props with no logic of its own, while unit-test-coverage is partial: no test renders `Closer` directly, and it is exercised only indirectly through `Contact`'s `.lp-closer` assertion in `blocks-close.test.tsx`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: cite the real `lp-closer`/`lp-closer h2` CSS in Appearance instead of an unsupported source-comment claim, correct the Border description (a border-top is applied) and drop the false CSS-specificity claim from the className design decision, reformat Design Decisions into Decision/Rationale/Approved form, add a Compliance table (accessibility + internationalization), replace the web-only "CSS class name string" platform-note pattern with each native platform's own styling hook and add heading-semantics guidance, fix the WinUI StackPanel/TextAlignment mismatch and the Compose ColumnScope type, rename requirements to subject-only kebab-case and fold filter-empty-strings into merge-optional-classname, add test vectors for null children and ReactNode title, soften the empty-title edge case to a caller SHOULD NOT, and move "positioned after hero content" out of Overview into a usage note. |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation (drafted by Claude Haiku 4.5) |
