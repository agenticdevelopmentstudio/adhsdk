---
id: 98444e89-1044-43a7-9ec5-75da579c528a
title: "Versus"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Side-by-side comparison of two options, emphasizing the active choice."
platforms:
  - typescript
  - web
tags:
  - comparison
  - layout
  - landing
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Versus

## Overview

`Versus` displays two panels side by side, presenting a comparison between two options or approaches. The component visually distinguishes the "us" (active) side from the "them" (reference) side through styling, allowing users to quickly grasp the contrast at a glance. Each panel contains a title, an optional one-line lede, and optional bullet points.

## Behavioral Requirements

- **render-both-sides**: Component MUST render exactly two panels, one for the "them" option and one for the "us" option.
- **render-required-title**: Component MUST render the title from each `VersusSide` as an h3 element.
- **render-optional-lede**: Component MUST render the lede as a paragraph element whenever `lede` is defined (not undefined); this includes an explicitly empty value, since the component checks only presence, not emptiness. See **Design Decisions** for why.
- **render-optional-points**: Component MUST render points as a bullet list only if `points` is defined and has length greater than zero; a defined-but-empty list renders nothing.
- **distinguish-sides**: Component MUST apply a distinguishing visual marker to the "us" panel that differs from the "them" panel, marking "us" as the active/highlighted option.
- **consistent-side-structure**: Both panels MUST produce the same element structure for the same shape of props — "us" and "them" render identically for a given `title`/`lede`/`points` combination.
- **fixed-side-order**: Component MUST render "them" before "us" in reading/DOM order; the order does not adapt to text direction (no right-to-left handling).
- **stack-below-breakpoint**: Component MUST switch from a two-column to a single-column layout when the container is too narrow to fit two columns at their minimum width, stacking "them" above "us".

## Appearance

- **Layout**: Two columns of equal width, arranged horizontally, when there's room for both; collapses to a single stacked column ("them" above "us") below a minimum width — see **stack-below-breakpoint**.
- **Column spacing**: Gap between panels determined by platform design guidelines
- **Title styling**: h3 element with inherited typography; assumes Versus sits under a page section already at h2 or above — see **Accessibility**.
- **Lede styling**: Paragraph element with top margin, styled as introductory text
- **Points styling**: Unordered list with bullet markers, items as li elements
- **Visual distinction**: "us" panel receives highlighting (background, border, or accent color); "them" panel uses neutral styling
- **Padding**: Consistent padding within each panel
- **Background**: Platform-dependent; typically neutral for "them", accent or highlight for "us"

## States

| State | Appearance change |
|-------|------------------|
| Default | Both panels visible, side by side; "them" neutral, "us" highlighted |
| Narrow container | Single stacked column; "them" above "us", both keep their normal content |
| No lede | Paragraph element absent; title and points (if present) render normally |
| No points | List element absent; title and lede (if present) render normally |
| No lede or points | Only title renders in the panel |

## Accessibility

- **Role**: Each side is a div container; title is an h3 heading; lede is a paragraph; points are a list.
- **Semantic structure**: Title renders as a fixed h3; this assumes Versus is placed under a page section already at h2 (or otherwise one level above), so the heading sequence isn't skipped. The component does not offer a configurable heading level. Assistive technologies announce list structure for points.
- **Label requirements**: Titles are read as headings; lede provides context; bullet points are announced as list items.
- **Non-visual distinction**: The component provides no text label, `aria-label`, or semantic-role difference between "us" and "them" beyond the differing marker class (see **distinguish-sides**) — the distinction is visual only (border, background, glow). A non-visual cue, if needed, is the surrounding page's responsibility, not this component's; see **Differentiate Without Color** below.
- **Minimum tap target**: Panels are containers; no interactive tap targets within this component itself.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|----|----|
| versus-001 | render-both-sides | `them: { title: "Option A" }`, `us: { title: "Option B" }` | Two panels rendered, each with its title in an h3 |
| versus-002 | render-required-title | `them: { title: "Text" }` | h3 element contains "Text" |
| versus-003 | render-optional-lede | `{ lede: "Introduction" }` | Paragraph element renders with "Introduction" |
| versus-004 | render-optional-lede | `lede` omitted entirely | No paragraph element in panel |
| versus-005 | render-optional-points | `{ points: ["Point 1", "Point 2"] }` | Unordered list with two li elements |
| versus-006 | render-optional-points | `{ points: [] }` or `points` omitted | No list element in panel |
| versus-007 | distinguish-sides | `them` and `us` provided | "us" panel carries a distinct marker class (`lp-versus__us`) from "them" (`lp-versus__them`); the two receive different border and background styling |
| versus-008 | render-optional-lede | `lede` passed as an explicitly empty value instead of omitted | Content is defined but empty; a styled empty paragraph still renders — defined-but-empty is not treated as absent |
| versus-009 | consistent-side-structure | Both sides given identical props | Both panels render with identical element structure |
| versus-010 | fixed-side-order | `them` and `us` provided | "them" panel precedes "us" panel in DOM/reading order |
| versus-011 | stack-below-breakpoint | Container narrower than two minimum-width columns plus gap | Layout switches to a single column; "them" panel appears above "us" panel |

## Edge Cases

- **Missing or null title**: `title` is a required prop; omitting the key entirely is a compile-time TypeScript error. An explicit `null` or `undefined` value is permitted by the `ReactNode` type (which includes both) and renders as an empty heading — nothing renders inside the h3.
- **Empty title**: Title is rendered as provided; an empty string produces an empty h3.
- **Empty lede value**: If `lede` is defined as an empty value (e.g. an empty string), a paragraph still renders — see **render-optional-lede**. Callers should omit `lede` entirely to avoid an empty paragraph.
- **Empty points array**: If `points` is defined as an empty array, no list renders — see **render-optional-points**.
- **Single point**: `points: ["Only one"]` renders a list with one item.
- **Very long content**: Component imposes no length limits; overflow is handled by CSS or the parent container.
- **Rich content in lede or points**: `lede` and each point accept arbitrary content, not just plain text — inline formatting or nested elements are supported wherever the platform's content-value type allows it.
- **Missing "us" or "them" prop**: Both `them` and `us` are required; omitting either is a compile-time TypeScript error.
- **Right-to-left locale**: Rendering order is unaffected by text direction — see **fixed-side-order**. The component provides no RTL-specific layout adaptation.

## Configuration

Not applicable. Component accepts `them` and `us` props of type `VersusSide`; no configuration options or feature flags are present.

## Deep Linking

Not applicable. Component is a presentational element with no associated URL or deep link pattern.

## Localization

Not applicable. Component renders user-provided content; localization is the caller's responsibility. Titles, ledes, and points MAY contain localized strings. Reading order does not adapt for right-to-left locales — see **fixed-side-order**.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable. Component is static and does not animate. |
| Increase Contrast | Component rendering does not adapt. Platform CSS or theme must apply contrast enhancement. |
| Differentiate Without Color | Component rendering does not adapt. Platform CSS or theme must ensure "us" and "them" sides are distinguishable without relying on color alone. |

## Feature Flags

Not applicable. Component has no feature flag configuration.

## Analytics

Not applicable. Component is presentational and does not emit user interaction events.

## Privacy

Not applicable. Component does not collect, store, or transmit data.

## Logging

Not applicable. Component does not emit structured logs.

## Platform Notes

- **SwiftUI**: Use an `HStack` with two equal-width sections (`.frame(maxWidth: .infinity)` on each), switching to a `VStack` below a size-class breakpoint so "them" stacks above "us". Apply `.fontWeight(.bold)` to titles. Use conditional rendering (`if let lede`) for the optional lede. Highlight the "us" side with a background color or border via `.background()`/`.overlay()`. Manage semantic context through `.accessibilityElement()` and `.accessibilityLabel()`.
- **Compose**: Use a `Row` with two equal-weight children (`Modifier.weight(1f)`) for side-by-side layout, switching to a `Column` below a width breakpoint so panels stack. Render titles as `Text` with heading semantics (`Modifier.semantics { heading() }`). Conditionally render `Text` for the lede and a `Column` for points. Apply `Modifier.background()` to distinguish "us" from "them". Panels aren't interactive, so they don't need `focusable()`; expose the distinction to assistive tech via `Modifier.semantics` if needed.
- **React/Web**: Render two `<div>` containers through a CSS grid (`display: grid; grid-template-columns: repeat(auto-fit, minmax(18rem, 1fr))`), which collapses to a single column — "them" above "us" in DOM order — once the container can't fit two 18rem-minimum columns; `gap` sets the spacing between them. Apply the class contract `.lp-versus__them` and `.lp-versus__us` as the styling hooks (border, background, and title/lede color overrides). Use conditional rendering (`{lede !== undefined && <p>...}`) to show optional content — this checks presence, not emptiness. The component applies no additional ARIA role; it relies on the surrounding page's own landmark structure.
- **AppKit / UIKit**: Use `NSStackView` (macOS) or `UIStackView` (iOS) with axis `.horizontal`, switching to `.vertical` below a width threshold so "them" stacks above "us". Render the title as `NSTextField` (macOS, non-editable, bezel-less) or `UILabel` (iOS) with heading typography (`.accessibilityTraits = .header` on iOS). Conditionally add lede and points subviews. Apply background color or `CALayer.borderWidth`/`borderColor` to mark the "us" side as active. Use Auto Layout constraints, or the stack view's own distribution, to keep both columns equal width.
- **WinUI 3**: Render a `Grid` with two `ColumnDefinition`s each `Width="*"`, inside a parent that switches to stacked `RowDefinition`s below a width threshold. Place a `TextBlock` for the title using a theme heading text style (e.g. `{StaticResource BodyStrongTextBlockStyle}`) rather than hard-coded `FontSize`/`FontWeight`. Conditionally render a `TextBlock` for the lede and an `ItemsControl` for points. Apply a theme accent brush (e.g. `{ThemeResource AccentFillColorDefaultBrush}`) to the "us" side and a theme-neutral brush (e.g. `{ThemeResource CardBackgroundFillColorDefaultBrush}`) to "them", rather than hard-coded colors. Use `Padding`/`Margin` to control spacing within and between panels.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Versus.tsx` | unverified |

## Design Decisions

**Decision**: Both panels render through a single shared implementation rather than duplicated markup per side.
**Rationale**: Reduces the risk of divergent rendering between "us" and "them" — a fix applied to the shared implementation automatically applies to both sides, and both panels are guaranteed identical structure for the same props (see **consistent-side-structure**).
**Approved**: pending

**Decision**: `lede` is checked only for presence (`!== undefined`), not emptiness; `points` is checked for both presence and non-zero length. An explicitly empty `lede` (e.g. an empty string) still renders a styled empty paragraph; an explicitly empty `points` array renders nothing.
**Rationale**: The component can't distinguish an intentionally empty value from a caller mistake, so it renders whatever is defined. Callers who want no lede or no points must omit the prop entirely rather than pass an empty value (see **render-optional-lede**, **render-optional-points**).
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`dynamic-type-support` and `semantic-markup` rest on the component rendering title/lede/points through semantic `h3`/`p`/`ul`/`li` elements sized in `rem`; `contrast-ratio` is partial because panel colors resolve from CSS custom properties whose final contrast depends on the consuming theme; `string-externalization` and `unicode-support` pass because the component defines no string literals of its own and renders whatever content it's given; `rtl-layout-support` fails because the component always renders "them" before "us" with no direction-aware logic (see **fixed-side-order**). `separation-of-concerns` passes because both `Versus` and its shared `Panel` helper are pure presentation over props with no business logic, and `unit-test-coverage` passes on `blocks-argument.test.tsx`'s exercise of layout, the optional lede, the optional points (including an empty array), and a bare-heading side.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: resolved the empty-content contradiction into one rule under render-optional-lede; moved caller guidance for omitting empty props out of Behavioral Requirements; rewrote the non-visual-distinction and identical-structure claims to match source; added fixed-side-order and stack-below-breakpoint requirements with vectors; corrected the SwiftUI/Compose/AppKit/WinUI platform notes and named the React/Web class contract; filled in the Compliance table; reformatted Design Decisions; removed React-specific jargon; added tags; fixed modified-date quoting |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
