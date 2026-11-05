---
id: 28436339-4eda-46e9-b45f-f58a26949641
title: Doc Table of Contents
domain: adhsdk://recipes/doc-table-of-contents
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Sticky right-rail component displaying a scrollable list of document headings
  with active-heading highlight.
platforms:
- typescript
- web
tags:
- navigation
- documentation
- scrollspy
depends-on: []
related: []
references:
- https://developer.mozilla.org/en-US/docs/Web/CSS/position
- https://developer.mozilla.org/en-US/docs/Web/API/Element/scrollIntoView
approved-by: ''
approved-date: ''
---

# Doc Table of Contents

## Overview

The Doc Table of Contents is a sticky, scrollable navigation rail positioned to the right of a document. It displays a list of the document's headings, indented by heading depth, with a visual marker (accent color border and bold text) indicating which section the user is currently viewing as the document scrolls. It smooth-scrolls the page when a heading is clicked. The component renders nothing when the heading list is empty, making it suitable for variable-length documents.

## Behavioral Requirements

- **accept-headings-array**: Component MUST accept a `headings` array of `HeadingEntry` objects containing at minimum an `id`, `text`, and `depth` property for each heading.
- **render-nothing-when-empty**: Component MUST render nothing (return null) when the `headings` array is empty or all headings are filtered by `excludeIds`.
- **filter-headings**: Component MUST filter headings based on the optional `excludeIds` iterable, excluding any heading whose `id` is in the set.
- **track-active-heading**: Component MUST track which heading is currently in the viewport using a scrollspy mechanism and highlight it as the active heading.
- **show-active-heading-styling**: Component MUST render the active heading with an accent-colored left border (1px width), primary text color, and medium font weight.
- **show-inactive-heading-styling**: Component MUST render inactive headings with a transparent left border (maintaining alignment), dim text color, and regular font weight.
- **hover-inactive-headings**: Component MUST change inactive heading text color to secondary on hover to indicate interactivity.
- **indent-by-depth**: Component MUST indent headings based on depth: depth-3 headings MUST have 6 units (1.5 rem) of left padding; all other headings MUST have 3 units (0.75 rem).
- **scroll-page-on-click**: Component MUST smooth-scroll the document to the target heading's element when clicked, preventing default link behavior.
- **use-custom-title**: Component MUST accept an optional `title` prop (ReactNode) and MUST default to "On this page" when not provided.
- **transition-colors**: Component MUST apply a CSS transition effect (150ms) to color and border changes when the active state changes.
- **respect-custom-classname**: Component MUST accept an optional `className` prop and merge it with the component's default classes without losing the sticky positioning or layout structure.
- **accept-html-attributes**: Component MUST accept standard HTML element attributes (spread via `...rest` on the aside element) and apply them to the component's root element.
- **use-monospace-title**: Component MUST render the title in monospace font, uppercase, small size (10px), medium weight, and dim color.
- **hide-below-xl**: Component MUST hide on screens smaller than the XL breakpoint and show only on XL and larger screens.
- **be-sticky-positioned**: Component MUST use CSS sticky positioning, offsetting from the top by the value of the CSS custom property `--adh-header-height` (defaulting to 3.5rem if not defined).
- **have-fixed-width**: Component MUST have a fixed width of 14 rem (56 units) and MUST NOT grow or shrink.
- **have-left-border**: Component MUST render a left border (1px width) on the heading list using the `--color-border-subtle` custom property.
- **use-custom-properties**: Component MUST use CSS custom properties (`--color-accent`, `--color-text-primary`, `--color-text-dim`, `--color-text-secondary`, `--color-border-subtle`) for all colors and MUST NOT use hardcoded color values.

## Appearance

- **Corner radius**: None; component uses only sharp edges.
- **Padding**: Vertical 2 rem (8 units) × horizontal 1 rem (4 units) on the container; individual headings use vertical 0.125 rem (0.5 units) and horizontal padding based on depth (0.75 rem / 3 units, or 1.5 rem / 6 units for depth-3 headings).
- **Font**: Title uses monospace, 10px, medium weight, uppercase. Headings use sans-serif, small size (14px), regular weight (inactive) or medium weight (active).
- **Background**: Transparent; no background color is applied.
- **Foreground/Text**: Title uses `--color-text-dim`. Inactive headings use `--color-text-dim` with hover state to `--color-text-secondary`. Active heading uses `--color-text-primary` and font-medium.
- **Border**: Left border on the heading list uses `--color-border-subtle` (1px width). Individual headings have a left border that is 1px wide and is transparent (inactive) or uses `--color-accent` (active).
- **Shadow**: None.
- **Min/Max size**: Fixed width 14 rem; does not grow or shrink. Height is viewport height minus header height with overflow-y-auto scrolling.

## States

| State | Appearance change |
|-------|------------------|
| Default | Inactive heading with dim text, transparent border. |
| Inactive (on hover) | Text color changes from dim to secondary; border remains transparent. |
| Active | Left border changes to accent color; text color changes to primary; font weight changes to medium. |
| Scrolled out of view | Heading remains in list; active marker updates as viewport changes. |

## Accessibility

- **Role**: The component renders as an `<aside>` (supplementary content region). The heading list renders as an unordered list (`<ul>`) with anchor links (`<a href="#id">`).
- **Label requirements**: The component's title (rendered as an `<h4>`) serves as the region label. Heading links MUST have accessible text derived from the heading content (the `heading.text` property).
- **Keyboard navigation**: All heading links MUST be keyboard-accessible via Tab and Enter (standard anchor link behavior). Focus indicators are browser-supplied.
- **Announce state changes**: Screen readers will announce heading links as navigational anchors. The active heading's increased font weight and color are visual affordances; the actual "current page location" is conveyed by the user's scroll position and the anchor link target.
- **Minimum tap target**: Heading links SHOULD meet a minimum touch target of 44×44 pt. This implementation's row height (0.125 rem vertical padding plus 14px text) is smaller than that; this is a layout constraint inherited from the document's fixed-width rail design, accepted here for inline text links within a document body (see **Compliance**).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-toc-001 | accept-headings-array | `headings=[{id:"h1", text:"Introduction", depth:2}, {id:"h2", text:"Methods", depth:2}]` | Component renders a list with two anchor links. |
| doc-toc-002 | render-nothing-when-empty | `headings=[]` | Component returns null; no HTML is rendered. |
| doc-toc-003 | filter-headings | `headings=[{id:"h1", text:"Title", depth:1}, {id:"h2", text:"Appendix", depth:2}]`, `excludeIds=["h1"]` | Component renders only the "Appendix" link; "Title" is hidden. |
| doc-toc-004 | track-active-heading | User scrolls document so heading with id "h2" is in viewport. | Component's scrollspy hook identifies "h2" as active; link receives active styling. |
| doc-toc-005 | show-active-heading-styling | Heading with id "h1" is active. | Link renders with accent-colored left border, primary text color, medium font weight. |
| doc-toc-006 | show-inactive-heading-styling | Heading with id "h2" is inactive. | Link renders with transparent left border, dim text color, regular font weight. |
| doc-toc-007 | hover-inactive-headings | User hovers over an inactive heading link. | Text color changes to secondary. |
| doc-toc-008 | indent-by-depth | `headings=[{id:"h1", text:"Intro", depth:2}, {id:"h2", text:"Subsection", depth:3}]` | "Intro" link has 0.75 rem (3 units) left padding; "Subsection" link has 1.5 rem (6 units) left padding. |
| doc-toc-009 | scroll-page-on-click | User clicks a heading link with `href="#h2"`. | Page smooth-scrolls to the element with id "h2"; link's default behavior is prevented. |
| doc-toc-010 | use-custom-title | `title="Table of Contents"` | Component renders the custom title instead of the default "On this page". |
| doc-toc-011 | use-custom-title (default) | No `title` prop provided. | Component renders "On this page". |
| doc-toc-012 | transition-colors | User scrolls to change the active heading. | CSS transition effect smooths the color and border changes over approximately 150ms. |
| doc-toc-013 | respect-custom-classname | `className="my-custom-class"` | Component renders the aside with its default sticky positioning and layout intact, plus the custom class also applied. |
| doc-toc-014 | accept-html-attributes | `data-testid="toc"` | Component renders the aside with the `data-testid` attribute set to "toc". |
| doc-toc-015 | use-monospace-title | Component is rendered. | Title renders in font-mono, 10px, medium weight, uppercase, dim color. |
| doc-toc-016 | hide-below-xl | Screen width is 800px (below XL breakpoint, typically 1280px in Tailwind). | Component does not render (hidden by `hidden xl:block`). |
| doc-toc-017 | be-sticky-positioned | User scrolls the document past the component's initial position. | Component remains visible and sticky, offset from the top by `--adh-header-height`. |
| doc-toc-018 | have-fixed-width | Component is rendered. | Component width is exactly 14 rem (224px); does not scale with content. |
| doc-toc-019 | use-custom-properties | Component is rendered in a themed environment providing `--color-accent`, `--color-text-primary`, etc. | All colors derive from CSS custom properties; component respects theme changes. |

## Edge Cases

- **Empty headings array**: Component returns null and renders no HTML. This is by design; empty documents have no navigation targets.
- **All headings excluded**: If `excludeIds` excludes every heading in the array, no headings remain and the component returns null.
- **Heading with no matching element**: If a heading's id does not correspond to an element in the DOM (e.g., the heading list includes an id that was not rendered), no scroll occurs and no error is thrown.
- **Very long heading text**: The link renders as a block element with default (`normal`) white-space, inside `<li>`s in the rail's `w-56 overflow-y-auto` aside. The component never truncates the text, and a multi-word heading wraps onto additional lines within the 14 rem width rather than overflowing it. A single unbreakable token long enough to exceed that width still does not spill visibly outside the rail: because the aside already sets `overflow-y: auto`, the browser computes its `overflow-x` as `auto` too, so any such overflow scrolls inside the rail instead.
- **Rapid scroll events**: The active heading is recalculated as the document scrolls, based on `useScrollSpy`'s intersection band (see the scrollspy Design Decision below) rather than which heading is literally closest to the viewport top. If headings are closely spaced the active marker may flip rapidly; no debounce delays the update.
- **Click on active heading**: Clicking an already-active heading scrolls to it again. The smooth-scroll behavior is re-triggered.
- **Custom title is empty or null**: If `title` is an empty string or null, the component still renders the `<h4>` element, but it will be empty.
- **CSS custom properties not defined**: The component uses fallback values only for `--adh-header-height` (3.5rem); other custom properties have no fallbacks. If the theme does not define `--color-accent`, the browser will use the initial (transparent/black) color.
- **Screen resizes from below XL to XL**: Component transitions from hidden to visible. No re-render or data loss occurs; the component's state is preserved.

## Configuration

Not applicable: The component accepts a fixed set of props for content and styling. No additional configuration options are exposed.

## Deep Linking

Not applicable: The component does not implement deep-linking beyond rendering `#id` hrefs for structure. Clicking a heading link calls `preventDefault()` and smooth-scrolls to the target element instead of following the anchor, so the browser's default hash-update behavior does not run and the URL's hash does not change on click. Loading the page with a heading's `#id` already in the URL is not handled by this component.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `doc-toc.title` | "On this page" | Default title when the `title` prop is not provided. |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Component SHOULD respect the `prefers-reduced-motion` media query; the `transition-colors` class on heading links SHOULD be disabled when reduce-motion is enabled. |
| Increase Contrast | Component color tokens (`--color-accent`, `--color-text-primary`, etc.) SHOULD be adjusted by the theme to meet contrast ratios. Component does not control this. |
| Differentiate Without Color | Active headings rely on color to indicate state. The component SHOULD apply a visual indicator (e.g., bold text, border) in addition to color. Currently, the component uses both color and font-weight (medium) to indicate the active state, satisfying this requirement. |

## Feature Flags

Not applicable: The component has no feature flags. All behaviors are always enabled.

## Analytics

Not applicable: The component does not emit analytics events. Analytics integration is the responsibility of the document or application layer.

## Privacy

Not applicable: The component does not collect, store, or transmit personal data. It operates entirely on client-side document state.

## Logging

Not applicable: The component does not emit logging events. Debugging can be performed via browser developer tools (inspecting the scrollspy state and active heading).

## Platform Notes

- **SwiftUI**: On iOS and macOS, implement using a `List` of navigation links to document section identifiers. Use `ScrollViewReader` to scroll the list to keep the active section visible. Replicate the scrollspy behavior using a `GeometryReader` and `onScrollGeometryChange` modifier to track which section is currently in the viewport. Apply the accent color and a medium-weight font to the active link. Respect the surrounding safe-area insets for edge padding.
- **Compose**: On Android, implement using a vertical `LazyColumn` of `TextButton` components bound to document heading ids. Use `LazyListState.animateScrollToItem()` for smooth scrolling. Implement scrollspy by observing the main document's scroll position (e.g., via `ScrollState` or a `NestedScrollConnection`) and updating the active heading state. Apply the Material Design 3 accent color and a medium-weight label style to the active link; use the regular-weight label style for inactive links.
- **AppKit / UIKit**: On macOS (AppKit), implement using an `NSOutlineView` or vertical stack of `NSButton` components. On iOS (UIKit), use a `UITableView` with custom cells for each heading link. Implement scrollspy by observing the main document's scroll position (e.g., via `UIScrollViewDelegate` or `Combine` publishers). Apply the tint color and a medium-weight font to the active link. Use `UIView.animate()` for color transitions. On iPad, present as a sidebar; on iPhone, present as a drawer or modal.
- **WinUI 3**: On Windows, implement using a `ListView` or `ItemsStackPanel` of `HyperlinkButton` controls bound to document heading URIs. Set `VerticalAlignment="Stretch"` and `Width="224"` (14 rem). Use a `ScrollViewer` for overflow. Implement scrollspy by handling the `ScrollViewer.ViewChanged` event on the main document and updating the selected item based on the document's scroll offset. Apply the accent color and `FontWeights.Medium` to the selected link; use `TextFillColorPrimaryBrush` for the active link and `TextFillColorSecondaryBrush` for inactive links. Use `ThemeShadow` for any elevation if needed. Respect the system's `HighContrast` setting by using dynamic brushes from the theme resource dictionary.

## Design Decisions

- **Decision**: The rail has a fixed width of 14 rem, and long heading text wraps onto additional lines rather than being truncated.
  **Rationale**: A fixed width aligns with the document's grid and keeps the rail's layout predictable; the component neither truncates long text nor lets it escape the rail, so it wraps within that width instead (an unbreakable token long enough to still exceed it scrolls inside the rail, since the aside's `overflow-y: auto` makes its `overflow-x` compute to `auto` as well).
  **Approved**: pending

- **Decision**: The title renders in monospace font.
  **Rationale**: Monospace distinguishes the title as "component chrome" rather than document content, following design conventions for supplementary UI.
  **Approved**: pending

- **Decision**: Heading depth is represented via left padding, not a tree hierarchy or nested list.
  **Rationale**: The document's heading outline is already visible in the main content, so a flat, indented list is enough to convey structure in the rail.
  **Approved**: pending

- **Decision**: The component indents based on heading depth but never hides or skips headings at deep nesting levels; all headings are included in the list.
  **Rationale**: Omitting deep headings would make the rail an incomplete map of the document.
  **Approved**: pending

- **Decision**: The active heading is the first heading, in document order, whose element intersects a viewport band tracked via `useScrollSpy`'s `IntersectionObserver` (`rootMargin: "-80px 0px -60% 0px"`) — from 80px below the viewport top down to 60% of the viewport height. There is no debounce, so the marker can flip rapidly when headings sit close together; but when no heading intersects the band (scrolled deep into a long section, or past the last heading), the hook deliberately keeps the last active heading rather than clearing it — a sticky fallback, not the absence of one.
  **Rationale**: A band rather than a single line tolerates ordinary scroll jitter without flip-flopping between two adjacent headings, and holding the last position when nothing intersects the band avoids blanking the "on this page" marker while the reader is still inside a section.
  **Approved**: pending

- **Decision**: Clicking a heading smooth-scrolls the page instead of jumping instantly, and default link navigation is prevented, so the URL hash does not update.
  **Rationale**: A smooth scroll improves the reader's sense of where the click took them and reduces visual jarring; the component takes over the scroll itself instead of relying on default browser hash-navigation.
  **Approved**: pending

- **Decision**: All color values are sourced from CSS custom properties, never hardcoded.
  **Rationale**: This lets the component respect theme changes and adapt to light/dark mode without prop drilling or conditional styling.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | failed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | failed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on the source's plain anchor-link markup (`<aside>`, `<ul>`, `<a href>`) for the passed accessibility checks; its unconditional `transition-colors` and small `py-0.5` row height for the failed accessibility checks; its CSS-custom-property colors and fixed `text-[10px]` title size for the accessibility partials; its physical `pl-`/`border-l`/`pr-` classes and fixed 14 rem width with no text wrapping for the failed internationalization checks; its JSX text rendering (no character filtering) for `unicode-support`; and its hardcoded `"On this page"` default, overridable only via a caller-supplied prop rather than a resource lookup, for `string-externalization` and `no-hardcoded-strings`. `separation-of-concerns` passes because active-heading tracking is delegated to the standalone `useScrollSpy` hook rather than implemented inline in the render body; `unit-test-coverage` passes because `docTableOfContents.test.tsx` imports `DocTableOfContents` directly and exercises its behavior with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed scrollspy Design Decision/edge case to describe useScrollSpy's actual band + first-in-order + sticky-fallback logic instead of closest-to-top with no sticky; fixed long-heading-text edge case/decision to describe wrapping, not horizontal overflow. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case everywhere they're cited; reformatted Design Decisions into Decision/Rationale/Approved triplets; replaced the "Not applicable" Compliance section with a real table; corrected Platform Notes API names (WinUI `ScrollViewer.ViewChanged` and modern theme brushes, SwiftUI safe-area guidance, Compose typography); resolved contradictions between sections (fixed vs. minimum width, ellipsis vs. overflow, indent depth vs. "proportional," scrollspy debounce, the Deep Linking section's claim about URL hash updates); added rem values alongside Tailwind units; fixed an RFC 2119 keyword misuse; removed implementation-detail leaks (variable and hook names, a CSS class constant, "not currently implemented" status prose) in favor of observable behavior; declined findings that would have added behavior the source does not implement |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
