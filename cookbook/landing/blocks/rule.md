---
id: 4cd07922-a00d-4029-8cb5-2307463129cc
title: "Rule"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Renders a definition list of term-detail pairs, typically for displaying rules or structured text-based content."
platforms:
  - typescript
  - web
tags:
  - definition-list
  - landing
  - typography
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Rule

## Overview

Rule renders a semantic definition list (`<dl>`) of term-detail pairs. Each pair consists of a term (the label) and a detail (the explanation). The component accepts an array of step objects and renders them in order, delegating all visual styling to CSS. Use this component to display structured textual content such as oversight rules, definitions, guidelines, or any term-definition pattern. Rule SHOULD NOT be used to caption a screenshot or other captured image of a UI; it exists to present genuine text set in the package's own typeface when a feature's UI has not been captured yet.

The name comes from the source component (`Rule.tsx`) and its use for displaying oversight rules; it does not refer to a horizontal rule (`<hr>`). The `steps` prop holds an array of term/detail pairs — independent clauses, not necessarily sequential steps — that render in the order given but carry no required order of their own.

## Behavioral Requirements

- **accept-steps-array**: Component MUST accept a `steps` prop containing an array of `RuleStep` objects.
- **ordered-rendering**: Component MUST render steps in the order provided in the array.
- **render-term-and-detail**: Each step MUST render both a `term` and a `detail` from the `RuleStep` object.
- **accept-react-nodes**: The `term` and `detail` fields MUST accept `ReactNode` values (strings, numbers, booleans, React elements, fragments, or other valid React content).
- **semantic-markup**: Component MUST render as a `<dl>` (definition list) element containing `<dt>` (term) and `<dd>` (detail) child elements.
- **root-class**: Component MUST apply the CSS class `lp-rule` to the root `<dl>` element.
- **keyed-fragment-pairs**: Each term/detail pair MUST render inside a `<Fragment>` keyed by the pair's array index, with no wrapper element around the `<dt>`/`<dd>` pair, so `<dt>` and `<dd>` remain direct children of `<dl>`.

## Appearance

- **CSS class**: `lp-rule`, defined in `packages/web/packages/landing/src/css/blocks.css`, applied to the root `<dl>` element; all visual styling is delegated to this stylesheet.
- **Layout**: two-column grid — a content-sized term column and a flexible detail column — collapsing to a single stacked column below a 34rem viewport width.
- **Term (`<dt>`)**: uppercase, `0.14em` letter-spacing, `0.68rem` font size, muted accent color (`--lp-accent`).
- **Detail (`<dd>`)**: sentence case, `0.85rem` font size (inherited), font-weight 300, primary ink color (`--lp-ink`); an embedded `<b>` uses a brighter accent color and weight 400.
- **Semantic structure**: Markup uses `<dl>`, `<dt>`, and `<dd>` elements; appearance is determined by CSS, not the component.
- **No inline styles**: Component applies no inline styles or className overrides beyond the `lp-rule` class.

## States

Not applicable: Rule is a static, non-interactive component and has no state variations (default, pressed, disabled, focused, loading, etc.).

## Accessibility

- **Semantic markup**: The component uses the semantic `<dl>`, `<dt>`, and `<dd>` elements, which are properly interpreted by screen readers as a definition list structure.
- **Content accessibility**: The accessibility of the term and detail content depends on what is passed as `ReactNode` values. If terms and details contain text, they are announced by screen readers. If they contain interactive elements or images, those elements' own accessibility properties apply.
- **No labels or roles required**: The component itself requires no additional ARIA attributes, roles, or labels; semantic HTML provides sufficient structure.
- **Minimum tap target**: Not applicable — Rule contains no interactive controls and thus no touch targets.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|----|----|
| rule-001 | accept-steps-array, ordered-rendering | `steps={[{term: "A", detail: "First"}, {term: "B", detail: "Second"}]}` | Component renders without error; DOM contains two `<dt>` and two `<dd>` elements in order |
| rule-002 | render-term-and-detail, accept-react-nodes | `steps={[{term: <strong>Bold</strong>, detail: <em>Italic</em>}]}` | The DOM contains `<dt><strong>Bold</strong></dt>` and `<dd><em>Italic</em></dd>` |
| rule-003 | semantic-markup, keyed-fragment-pairs | Any valid steps array | Root element is `<dl>`; direct children are `<dt>` and `<dd>` elements with no wrapper element between them and `<dl>` |
| rule-004 | root-class | Any valid steps array | Root `<dl>` element has the class `lp-rule` |
| rule-005 | accept-steps-array | `steps={[]}` | Component renders an empty `<dl>` element without error |
| rule-006 | accept-steps-array, render-term-and-detail | `steps={[{term: "A", detail: "1"}]}` | DOM contains exactly one `<dt>` (text "A") and one `<dd>` (text "1") |
| rule-007 | render-term-and-detail | `steps={[{term: null, detail: undefined}]}` | Component renders without error; `<dt>` and `<dd>` are present but empty (no text content) |
| rule-008 | accept-react-nodes | `steps={[{term: 42, detail: true}]}` | `<dt>` renders the text "42"; `<dd>` is present and empty (the boolean renders nothing) |
| rule-009 | accept-react-nodes | `steps={[{term: {}, detail: "x"}]}` | Component throws a React error ("Objects are not valid as a React child") instead of rendering |

## Edge Cases

- **Empty steps array**: When `steps` is an empty array, the component MUST render an empty `<dl>` element (no child elements).
- **Single step**: When `steps` contains one step, the component MUST render one `<dt>` and one `<dd>` pair.
- **Large step arrays**: The component has no configured limit on step count; rendering is a single pass over the array, so cost scales with array length. No specific size threshold is benchmarked or asserted as a requirement.
- **Null or undefined steps**: `steps` is a required `RuleStep[]` prop, so the type contract excludes `null` and `undefined` and the component adds no runtime guard. A translation with a weaker type system (or one accepting untyped JSON) MUST treat a missing array as empty rather than crash.
- **Null or undefined term/detail**: If a step's `term` or `detail` is `null` or `undefined`, React renders nothing for that content; the corresponding `<dt>` or `<dd>` element is rendered but empty.
- **Non-ReactNode values**: Numbers and booleans are valid `ReactNode` values — a number renders as text, a boolean renders nothing. A plain object is not a valid `ReactNode`; passing one as `term` or `detail` causes React to throw ("Objects are not valid as a React child") when the component renders.

## Configuration

Not applicable: Rule accepts only the `steps` prop with no configuration options or optional settings.

## Deep Linking

Not applicable: Rule is a static presentational component with no navigation or deep-link capability.

## Localization

Not applicable: Rule contains no hardcoded strings; all text content is passed via the `term` and `detail` fields of the steps array.

## Accessibility Options

- **Reduce Motion**: Not applicable — Rule is a static component with no animation or motion; Reduce Motion preferences do not apply.
- **Increase Contrast**: Not applicable — Rule applies no colors or contrast logic; visual appearance is entirely determined by external CSS.
- **Differentiate Without Color**: Not applicable — Rule applies no color-based distinctions; styling is external.

## Feature Flags

Not applicable: Rule contains no feature-flag logic or conditionally gated behavior.

## Analytics

Not applicable: Rule contains no analytics tracking, event firing, or instrumentation.

## Privacy

Not applicable: Rule collects, transmits, and stores no data.

## Logging

Not applicable: Rule performs no logging or debug output.

## Platform Notes

- **TypeScript / React (Web)**: The source is a functional React component (`Rule`) exported from `packages/web/packages/landing/src/blocks/Rule.tsx`. It accepts a single prop `{ steps: RuleStep[] }`, where `RuleStep` is an interface with `term: ReactNode` and `detail: ReactNode` fields. The component renders a `<dl>` element with class `lp-rule` and maps over the steps array, wrapping each `<dt>`/`<dd>` pair in a `<Fragment key={i}>` keyed by index. Styling is applied via the `lp-rule` CSS class in `packages/web/packages/landing/src/css/blocks.css`.

- **SwiftUI**: Implement using a `Grid` or `VStack` of rows, each pairing a term `Text` and a detail `Text` (or more generally `View`). Use semantic font weights and spacing to distinguish the term (label) from the detail (explanation). Group each term/detail pair as one accessibility element with `.accessibilityElement(children: .combine)` so VoiceOver announces the pair together, mirroring the `<dl>`/`<dt>`/`<dd>` grouping. Map over the steps array and render a row for each step.

- **Compose (Kotlin)**: Use a `Column` for the list of steps. For each step, render a row layout (e.g., `Row` or `Column`) containing the term and detail `Text` composables. Apply `Modifier.semantics(mergeDescendants = true)` to each row so TalkBack announces the term/detail pair as one unit. Apply the appropriate typography and spacing via `Text(text = step.term, ...)` and `Text(text = step.detail, ...)`. If steps become large, use `LazyColumn`.

- **AppKit / UIKit**: On macOS, implement using `NSGridView` or `NSStackView`. On iOS, use `UIStackView`. Avoid `NSTableView`/`UITableViewController`: they pull in scrolling, selection, and cell-reuse chrome that a static presentational block does not need. Bind the steps array to view creation and ensure sufficient vertical spacing between rows for readability.

- **WinUI 3**: Implement using `ItemsControl` bound to the steps array. For each step, define a `DataTemplate` with a `StackPanel` (vertical orientation) or `Grid` containing `TextBlock` elements for the term and detail. Set `AutomationProperties.Name` on the item template's root element (or otherwise merge the automation peer) so Narrator announces the term and detail as one region, mirroring the `<dl>`/`<dt>`/`<dd>` grouping. Apply margin, padding, and font properties via `TextBlock.Margin` and `TextBlock.FontSize` to match the design language.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Rule.tsx` | unverified |

## Design Decisions

**Decision**: Use `<dl>`, `<dt>`, and `<dd>` elements rather than generic `<div>`s.
**Rationale**: Leverages semantic HTML to provide out-of-the-box accessibility for screen readers and assistive technology.
**Approved**: pending

**Decision**: `term` and `detail` accept `ReactNode` rather than `string`.
**Rationale**: Allows consumers to pass not just text but also styled elements, images, links, or other React components, trading compile-time per-field validation for runtime flexibility.
**Approved**: pending

**Decision**: Delegate all visual styling to the `lp-rule` CSS class; the component applies no inline styles, colors, fonts, or sizes.
**Rationale**: Keeps the component pure and confines styling concerns to the stylesheet.
**Approved**: pending

**Decision**: Do not validate the `steps` prop or guard against `null`, `undefined`, or malformed input.
**Rationale**: Consumers are responsible for ensuring `steps` is a valid array of `RuleStep` objects; the TypeScript type contract enforces this at compile time.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Semantic markup passes because the source renders `<dl>`/`<dt>`/`<dd>` directly (`Rule.tsx`); dynamic-type support is partial because the web CSS (`blocks.css`) sizes `dt`/`dd` in `rem` units, which scale with root font size, but the source gives no Dynamic Type guidance for native ports; no-hardcoded-strings passes because `term` and `detail` are supplied entirely by the caller, with no string literals in `Rule.tsx`. `Rule.tsx` is a trivial pure-presentation mapping of `steps` to `dt`/`dd` pairs with no logic of its own (separation-of-concerns passed); `blocks-argument.test.tsx` directly exercises the one-dt/dd-pair-per-step rendering in order (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source code |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case everywhere they're cited; added keyed-fragment-pairs requirement; corrected the non-ReactNode edge case and added test vectors for it and for the single-step and null/undefined-content edge cases; dropped the unmeasurable large-array MUST; reformatted Design Decisions to Decision/Rationale/Approved; replaced Compliance with a real table; named the stylesheet and described term/detail styling; added SwiftUI/Compose/WinUI 3 accessibility-grouping guidance and swapped list-based native controls for static-layout equivalents; clarified the Overview name/ordering and screenshot guidance |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
