---
id: 4cd07922-a00d-4029-8cb5-2307463129cc
title: "Rule"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
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

Rule renders a semantic definition list (`<dl>`) of term-detail pairs. Each pair consists of a term (the label) and a detail (the explanation). The component accepts an array of step objects and renders them in order, delegating all visual styling to CSS. Use Rule to present structured text such as oversight rules, definitions or guidelines, especially when a feature's UI has not been captured yet. Don't use Rule to caption a screenshot or other captured image of a UI.

The name comes from the source component (`Rule.tsx`) and its use for displaying oversight rules; it does not refer to a horizontal rule (`<hr>`). The `steps` prop holds an array of term/detail pairs — independent clauses, not necessarily sequential steps — that render in the order given but carry no required order of their own.

## Behavioral Requirements

- **accept-steps-array**: Component MUST accept a `steps` prop containing an array of `RuleStep` objects.
- **ordered-rendering**: Component MUST render steps in the order provided in the array.
- **render-term-and-detail**: Each step MUST render both a `term` and a `detail` from the `RuleStep` object.
- **accept-react-nodes**: The `term` and `detail` fields MUST accept rich content, not only plain text. In the web source that means any `ReactNode` value (strings, numbers, booleans, React elements, fragments).
- **semantic-markup**: Component MUST render as a `<dl>` (definition list) element containing `<dt>` (term) and `<dd>` (detail) child elements.
- **root-class**: Component MUST apply the CSS class `lp-rule` to the root `<dl>` element.
- **keyed-fragment-pairs**: Each term/detail pair MUST render as siblings with no wrapper element around the `<dt>`/`<dd>` pair, so `<dt>` and `<dd>` remain direct children of `<dl>`. (The React/Web note says how the source achieves this.)

- **empty-steps-render-empty-list**: When `steps` is empty, Component MUST render an empty list container with no term or detail children.
- **missing-steps-treated-as-empty**: A port whose type system or input format allows a missing `steps` value MUST treat it as an empty array rather than fail. The web source relies on its type contract and adds no guard.
## Appearance

- **CSS class**: `lp-rule`, defined in `packages/web/packages/landing/src/css/blocks.css`, applied to the root `<dl>` element; all visual styling is delegated to this stylesheet.
- **Source of truth**: `blocks.css` is the full reference for every value; the list below copies the values a port needs and the stylesheet wins if they disagree.
- **Container**: `1px` border in `--lp-hairline` (fallback `rgba(216, 216, 216, 0.18)`), corner radius `--lp-radius` (fallback `14px`), background `--lp-rule-bg` (fallback `rgba(16, 16, 16, 0.65)`), padding `1.2rem 1.35rem`, font size `0.85rem`, line height `1.8`.
- **Layout**: two-column grid — a content-sized term column and a flexible detail column — with a `1.1rem` column gap and a `0.5rem` row gap, baseline-aligned. A wrapped detail stays inside its own column. Below a 34rem viewport width it collapses to a single stacked column with a `0.15rem` row gap, and each `<dd>` gets a `0.6rem` bottom margin.
- **Term (`<dt>`)**: uppercase, `0.14em` letter-spacing, `0.68rem` font size, muted accent color (`--lp-accent`, fallback `#9a9a9a`).
- **Detail (`<dd>`)**: sentence case, `0.85rem` font size (inherited), font-weight 300, primary ink color (`--lp-ink`, fallback `#ededed`); an embedded `<b>` uses a brighter accent color (`--lp-accent-bright`, fallback `#d8d8d8`) and weight 400.
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
| rule-003 | semantic-markup, keyed-fragment-pairs | Any valid steps array | Root element is `<dl>`; direct children are `<dt>` and `<dd>` elements with no wrapper element between them and `<dl>` (the React `key` is not observable in the DOM and is not checked) |
| rule-004 | root-class | Any valid steps array | Root `<dl>` element has the class `lp-rule` |
| rule-005 | empty-steps-render-empty-list | `steps={[]}` | Component renders an empty `<dl>` element without error |
| rule-006 | accept-steps-array, render-term-and-detail | `steps={[{term: "A", detail: "1"}]}` | DOM contains exactly one `<dt>` (text "A") and one `<dd>` (text "1") |
| rule-007 | render-term-and-detail | `steps={[{term: null, detail: undefined}]}` | Component renders without error; `<dt>` and `<dd>` are present but empty (no text content) |
| rule-008 | accept-react-nodes | `steps={[{term: 42, detail: true}]}` | `<dt>` renders the text "42"; `<dd>` is present and empty (the boolean renders nothing) |
| rule-009 | accept-react-nodes | `steps={[{term: {}, detail: "x"}]}` | Informational, web-only: React itself throws ("Objects are not valid as a React child"); Rule adds no behavior here and ports need not reproduce it |

| rule-010 | missing-steps-treated-as-empty | A port is given a missing (absent or null) `steps` value | Renders an empty list, no failure (not applicable to the typed web source) |
## Edge Cases

- **Empty steps array**: See #requirements/empty-steps-render-empty-list: an empty `<dl>` element with no child elements.
- **Single step**: One step renders one `<dt>` and one `<dd>` pair, following #requirements/render-term-and-detail.
- **Large step arrays**: The component has no configured limit on step count; rendering is a single pass over the array, so cost scales with array length. No specific size threshold is benchmarked or asserted as a requirement.
- **Null or undefined steps**: `steps` is a required `RuleStep[]` prop, so the type contract excludes `null` and `undefined` and the component adds no runtime guard. A translation with a weaker type system (or one accepting untyped JSON) follows #requirements/missing-steps-treated-as-empty.
- **Null or undefined term/detail**: If a step's `term` or `detail` is `null` or `undefined`, React renders nothing for that content; the corresponding `<dt>` or `<dd>` element is rendered but empty.
- **Non-ReactNode values**: Numbers and booleans are valid `ReactNode` values — a number renders as text, a boolean renders nothing. A plain object is not a valid `ReactNode`; passing one as `term` or `detail` causes React to throw ("Objects are not valid as a React child") when the component renders. This is React's own behavior, not something Rule does, and it is web-only.

## Configuration

Not applicable: Rule accepts only the `steps` prop with no configuration options or optional settings.

## Deep Linking

Not applicable: Rule is a static presentational component with no navigation or deep-link capability.

## Localization

Not applicable: Rule contains no hardcoded strings; all text content is passed via the `term` and `detail` fields of the steps array.

## Accessibility Options

- **Reduce Motion**: Not applicable — Rule is a static component with no animation or motion; Reduce Motion preferences do not apply.
- **Increase Contrast**: Rule has no contrast logic of its own, but its stylesheet sets the term text in muted `--lp-accent` (fallback `#9a9a9a`) at `0.68rem` uppercase on a translucent dark background (`--lp-rule-bg`). That small muted text is the weakest contrast in the block and has not been measured here. In a high-contrast mode, a host SHOULD set `--lp-accent` to the full ink color and `--lp-hairline` to an opaque value; native ports SHOULD use the platform's high-contrast text color for terms.
- **Differentiate Without Color**: Not applicable — Rule applies no color-based distinctions; terms differ from details by case, size and letter-spacing as well as color.

## Feature Flags

Not applicable: Rule contains no feature-flag logic or conditionally gated behavior.

## Analytics

Not applicable: Rule contains no analytics tracking, event firing, or instrumentation.

## Privacy

Not applicable: Rule collects, transmits, and stores no data.

## Logging

Not applicable: Rule performs no logging or debug output.

## Platform Notes

- **React/Web**: The source is a functional React component (`Rule`) exported from `packages/web/packages/landing/src/blocks/Rule.tsx`. It accepts a single prop `{ steps: RuleStep[] }`, where `RuleStep` is an interface with `term: ReactNode` and `detail: ReactNode` fields. The component renders a `<dl>` element with class `lp-rule` and maps over the steps array, wrapping each `<dt>`/`<dd>` pair in a `<Fragment key={i}>` keyed by index (the Fragment keeps `<dt>`/`<dd>` direct children of `<dl>`; the key is a React detail with no DOM trace). Styling is applied via the `lp-rule` CSS class in `packages/web/packages/landing/src/css/blocks.css`.

- **SwiftUI**: Implement using a `Grid` or `VStack` of rows, each pairing a term `Text` and a detail `Text` (or more generally `View`). Use semantic font weights and spacing to distinguish the term (label) from the detail (explanation). Group each term/detail pair as one accessibility element with `.accessibilityElement(children: .combine)` so VoiceOver announces the pair together, mirroring the `<dl>`/`<dt>`/`<dd>` grouping. Map over the steps array and render a row for each step. Keep the web's two-column layout: a content-sized term column and a flexible detail column (for example `Grid` with a fixed-width first column), so wrapped detail text stays in its own column; below roughly 34rem (about 544pt of width) stack term over detail in one column. Use text styles (`.caption` for terms, `.callout` or `.body` for details) so Dynamic Type scales the text.

- **Compose (Kotlin)**: Use a `Column` for the list of steps. For each step, render a row layout (e.g., `Row` or `Column`) containing the term and detail `Text` composables. Apply `Modifier.semantics(mergeDescendants = true)` to each row so TalkBack announces the term/detail pair as one unit. Apply the appropriate typography and spacing via `Text(text = step.term, ...)` and `Text(text = step.detail, ...)`. If steps become large, use `LazyColumn`. Keep the web's two-column layout: a `Row` whose term column has an intrinsic width and whose detail takes the remaining weight, so wrapped text stays in its own column; below about 544dp of width stack term over detail. Size text in `sp` so system font scaling applies.

- **AppKit / UIKit**: On macOS, implement using `NSGridView` or `NSStackView`. On iOS, use `UIStackView`. Avoid `NSTableView`/`UITableViewController`: they pull in scrolling, selection, and cell-reuse chrome that a static presentational block does not need. Bind the steps array to view creation and ensure sufficient vertical spacing between rows for readability. Keep the web's two-column layout: a fixed-width term column and a flexible detail column, collapsing to a stacked column below about 544pt of width. Use text styles (`NSFont.preferredFont(forTextStyle:)` on macOS, `UIFont.preferredFont(forTextStyle:)` with `adjustsFontForContentSizeCategory = true` on iOS) so system text size applies. Group each term/detail pair for accessibility: on macOS expose one `NSAccessibilityElement` per pair whose label combines term and detail; on iOS set `isAccessibilityElement = true` on a container view per pair with a combined `accessibilityLabel` (or set `shouldGroupAccessibilityChildren` on the stack).

- **WinUI 3**: Implement using `ItemsControl` bound to the steps array. For each step, define a `DataTemplate` with a `StackPanel` (vertical orientation) or `Grid` containing `TextBlock` elements for the term and detail. Set `AutomationProperties.Name` on the item template's root element (or otherwise merge the automation peer) so Narrator announces the term and detail as one region, mirroring the `<dl>`/`<dt>`/`<dd>` grouping. Bind `AutomationProperties.Name` to the combined term + detail text. Keep the web's two-column layout with a `Grid` whose first column is `Auto` width and second is `*`, so wrapped detail stays in its column; use a `VisualStateManager` `AdaptiveTrigger` at about 544epx to stack term over detail. Apply margin and padding via `TextBlock.Margin`, and use the `CaptionTextBlockStyle` and `BodyTextBlockStyle` theme styles instead of fixed `FontSize` so system text scaling applies.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Rule.tsx` | confirmed (1.1.2) |

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

**Decision**: The web source does not validate the `steps` prop or guard against `null`, `undefined`, or malformed input; a port without a compile-time type contract treats a missing `steps` as an empty array.
**Rationale**: In TypeScript the type contract enforces a valid `RuleStep[]` at compile time, so a guard would be dead code. Ports that accept untyped input (JSON, dynamic languages) lose that contract and so MUST fall back to empty (see missing-steps-treated-as-empty).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

- semantic-markup passed: the source renders `<dl>`/`<dt>`/`<dd>` directly (`packages/web/packages/landing/src/blocks/Rule.tsx`).
- dynamic-type-support partial: the web CSS (`packages/web/packages/landing/src/css/blocks.css`) sizes `dt`/`dd` in `rem` units, which scale with the root font size. The Platform Notes now give native text-scaling guidance, but no native port exists to verify it.
- no-hardcoded-strings passed: `term` and `detail` are supplied entirely by the caller, with no string literals in `Rule.tsx`.
- separation-of-concerns passed: `Rule.tsx` is a trivial pure-presentation mapping of `steps` to `dt`/`dd` pairs with no logic of its own.
- unit-test-coverage partial: `packages/web/packages/landing/src/__tests__/blocks-argument.test.tsx` covers rule-001 to rule-009 with passing tests. rule-010 is skipped because it describes a missing `steps` value, which the typed web source cannot receive.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source code |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case everywhere they're cited; added keyed-fragment-pairs requirement; corrected the non-ReactNode edge case and added test vectors for it and for the single-step and null/undefined-content edge cases; dropped the unmeasurable large-array MUST; reformatted Design Decisions to Decision/Rationale/Approved; replaced Compliance with a real table; named the stylesheet and described term/detail styling; added SwiftUI/Compose/WinUI 3 accessibility-grouping guidance and swapped list-based native controls for static-layout equivalents; clarified the Overview name/ordering and screenshot guidance |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Downgraded unit-test-coverage to partial with per-check basis, stated the full stylesheet values and two-column layout, added empty/missing-steps requirements, reworded the Increase Contrast note, made rule-009 informational, and added native text-scaling, grouping and layout guidance. |
