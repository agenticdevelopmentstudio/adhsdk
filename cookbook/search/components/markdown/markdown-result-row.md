---
id: abd8ebe3-468d-4dda-8da2-cb00a97ae84c
title: "Markdown Result Row"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A search result row displaying markdown document metadata with per-kind variants, highlighting, and expanded touch targets."
platforms:
  - typescript
  - web
tags:
  - search-results
  - markdown-documents
depends-on: []
related:
  - 2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f
references:
  - https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
approved-by: ""
approved-date: ""
---

# Markdown Result Row

## Overview

The Markdown Result Row is a specialized search result component designed to display indexed markdown documents (papers, research, articles) within a search results list. It combines universal scaffolding with per-kind customization: the layout, spacing, and interaction model remain constant, while visual indicators (badge variant and subtitle source) adapt to the document kind via a renderer registry. The component integrates into roving-tabindex-managed lists where exactly one row is the active keyboard stop, and also supports standalone rendering outside list context.

**Inputs**: `hit: PaperSearchHit` (required — `id`, `title`, `publicRoute`, `author: { slug, displayName }`, `category`, `tags`, `snippet`, `createdAt`, `updatedAt`, `kind`); `href: string` (required — the hit's public page URL, built by the host); `query: string` (required — the active free-text search query used for highlighting); `selected: boolean` (required); `onSelect: (hit) => void` (required); `active?: boolean` (optional — roving-tabindex state: `true`, `false`, or `undefined` for standalone rendering); `controlRef?: Ref<HTMLElement>` (optional — forwarded to the select button for external focus management).

## Behavioral Requirements

- **render-title**: Component MUST render the document title from `hit.title`, defaulting to the string "Untitled" when the title is null or empty.
- **highlight-title**: Component MUST wrap query-matching terms in the title with `<mark>` elements styled as search highlights; exact match boundaries are determined by `splitHighlightSegments(text, query)`.
- **render-per-kind-badge**: Component MUST render a Badge component using the variant and label supplied by `kindRendererFor(hit.kind).badge`; a missing or unrecognized `hit.kind` MUST fall back to a default renderer and MUST NOT throw.
- **render-snippet**: Component MUST render a snippet (or subtitle) derived from `kindRendererFor(hit.kind).rowSnippet(hit)`, trimmed of leading and trailing whitespace; if the trimmed snippet is empty, the snippet section MUST NOT be rendered.
- **highlight-snippet**: When the snippet is rendered, Component MUST highlight query-matching terms within it with `<mark>` elements, using the same `splitHighlightSegments(text, query)` mechanism as the title.
- **limit-snippet-lines**: Component MUST clamp snippet display to a maximum of 2 lines using CSS line clamping; line overflow MUST be indicated by ellipsis.
- **render-tags**: Component MUST render each entry in `hit.tags` as a separate element prefixed with `#` (not comma-joined); if `hit.tags` is empty, the tags section MUST NOT be rendered.
- **render-category**: Component MUST render the `hit.category` as an optional uppercase label; if `hit.category` is null or empty, the category section MUST NOT be rendered.
- **render-author-display**: Component MUST display author attribution as "by [displayName]" when `hit.author.displayName` is a non-empty string; if displayName is null or empty after trimming, the name portion falls back to `@[slug]`, rendering as "by @[slug]".
- **render-updated-date**: Component MUST display the updated date, preceded by the literal separator " · Updated ", in the format produced by `formatDate(hit.updatedAt)` (e.g. "Jun 24, 2026") when `hit.updatedAt` is present; if `hit.updatedAt` is absent, the date MUST NOT be rendered.
- **bind-select-callback**: Component MUST invoke `onSelect(hit)` when the button is clicked, passing the entire hit object.
- **highlight-selected-state**: Component MUST render a visually distinct border state when `selected` is true; the selected state MUST use the design system's accent color token for the border (`apt-gold` on web); when false, borders MUST use a neutral color token and MAY show a hover state.
- **indicate-pressed-state**: Component MUST set the `aria-pressed` attribute to the value of `selected`, correctly indicating to assistive technology whether the row is selected.
- **implement-roving-tabindex**: Component MUST support roving tabindex for list integration: when `active` is true, `tabIndex` MUST be 0; when `active` is false, `tabIndex` MUST be -1; when `active` is undefined, the native tab order MUST be used (no tabindex attribute).
- **forward-ref-to-button**: Component MUST forward the `controlRef` to the internal button element, enabling external focus management by the containing list.
- **manage-link-tabindex**: Component MUST apply the same roving-tabindex logic to the "View paper" link as the select button; both elements MUST share the same tabindex value at all times.
- **enlarge-link-touch-target**: Component MUST ensure the "View paper" link's clickable/tappable target is at least 24 CSS px tall across the link's full width, meeting WCAG 2.2 SC 2.5.8 (Target Size, Minimum), independent of the visible link text's size.
- **set-link-href**: Component MUST render the "View paper" link with `href` set to the prop value, allowing navigation to the public paper page.
- **escape-content**: Component MUST render title and snippet content as React nodes (never `dangerouslySetInnerHTML`), ensuring user-controlled text is escaped by React's default behavior.
- **render-rounded-corners**: Component MUST apply the `--radius-lg` design token (8px) to the root article and the `--radius-md` design token (~6px) to interactive focus rings; the per-kind Badge applies its own corner radius (see [adhsdk.ingredient.ui.controls.badge](cookbook:2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f)).

## Appearance

- **Container**: Rounded article element with flex column layout, 8px gaps between sections, 8px corner radius (`--radius-lg` token), 1px border, 16px padding
- **Background**: Neutral background color (`apt-bg`); selected state uses accent border color (`apt-gold`)
- **Border**: 1px width; neutral color (`apt-border`) in default state; accent color (`apt-gold`) when selected; hover state shows strong border (`apt-border-strong`)
- **Button (select control)**: Flex column, 8px gap, text-left alignment, no default outline, `--radius-md` corner radius, rounded focus ring (2px) in accent color with 25% opacity
- **Badge**: Per-kind variant from renderer; self-aligned to start
- **Title (h3)**: Base font size (16px), semibold weight, text color (`apt-text`)
- **Highlight mark**: Gold background at 25% opacity (`apt-gold/25`), small rounded corners, horizontal padding (0.125rem), text color matches body (`apt-text`)
- **Category label**: 1px border, neutral border color, 8px horizontal padding, 4px vertical padding, monospace font, 12px size, uppercase, letter-spacing 0.08em, dim text color (`apt-text-dim`)
- **Snippet**: 14px size, muted text color (`apt-text-muted`), maximum 2 lines with ellipsis clamp
- **Tags**: List with 4px gaps, 12px font size, muted text color
- **Footer (author + date)**: Flex wrap with justified spacing, 12px gap (horizontal and vertical), 12px font size, dim text color; author name in muted text; "View paper" link in accent color with underline offset (8px) and hover underline
- **Link touch target overlay**: Invisible pseudo-element, full width, 24px height, centered vertically (using `top: 50%` and `-translate-y-1/2`)

## States

| State | Appearance change |
|-------|------------------|
| Default (unselected) | Neutral border, no accent styling |
| Selected | Gold border, visual emphasis |
| Hover (unselected) | Border transitions to strong neutral color (`apt-border-strong`) |
| Focused (button) | 2px focus ring in accent color with 25% opacity |
| Focused (link) | 2px focus ring in accent color with 40% opacity |
| Active (roving tabindex) | Button and link are keyboard-accessible (tabIndex = 0) |
| Inactive (roving tabindex) | Button and link are keyboard-skipped (tabIndex = -1) |

## Accessibility

- **Role**: `<article>` element (not an ARIA landmark role) containing a button (select control) and an anchor (view paper link); button has `aria-pressed` attribute
- **Button label**: The button's entire content (badge, title, snippet, tags) acts as its label; no explicit aria-label is added
- **Link text**: "View paper" provides the link's accessible label
- **Keyboard navigation**: Button and link participate in roving tabindex when `active` is defined; Tab navigation skips inactive rows (tabIndex = -1) in list context; Standalone renders (active = undefined) use natural tab order
- **Focus indicators**: Visible focus ring (2px, 25% opacity on button, 40% opacity on link) with accent color
- **Touch target size**: Link touch target is enlarged to 24px height via invisible overlay per WCAG 2.2 SC 2.5.8 (Target Size, Minimum); button has full-width touch area inherited from flex layout
- **Mark highlights**: `<mark>` elements are semantic and not styled to remove contrast; highlight styling (gold background, 25% opacity) maintains sufficient contrast with text
- **Color as sole indicator**: Selection state is currently conveyed by border color alone (`apt-gold` vs. neutral); no additional non-color affordance (icon, background fill, thicker border) is present, which may not satisfy WCAG 1.4.1 for users who cannot distinguish the two border colors

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mrr-001 | render-title | `hit.title = "My Document"` | Renders h3 with text "My Document" |
| mrr-002 | render-title | `hit.title = null` or empty string | Renders h3 with text "Untitled" |
| mrr-003 | highlight-title | `hit.title = "Search results", query = "search"` | Title renders with "Search" wrapped in `<mark>` element |
| mrr-004 | highlight-title | `hit.title = "No match", query = "xyz"` | Title renders with no `<mark>` elements |
| mrr-005 | render-per-kind-badge | `hit.kind = "paper"` with registered renderer | Badge renders with variant and label from renderer.badge |
| mrr-006 | render-per-kind-badge | `hit.kind = "unknown"` or unregistered | Component does not throw; renders with default renderer badge |
| mrr-007 | render-snippet | `renderer.rowSnippet(hit) = "  Some text  "` | Snippet renders as "Some text" (trimmed) |
| mrr-008 | render-snippet | `renderer.rowSnippet(hit) = ""` (empty after trim) | Snippet section is not rendered |
| mrr-009 | highlight-snippet | `snippet = "Find results fast", query = "results"` | Snippet renders with "results" wrapped in `<mark>` |
| mrr-010 | limit-snippet-lines | Snippet contains 4+ lines of text | CSS clamp limits visible lines to 2; overflow indicated by ellipsis |
| mrr-011 | render-tags | `hit.tags = ["tag1", "tag2"]` | Renders two separate elements, "#tag1" and "#tag2" (no comma separator) |
| mrr-012 | render-tags | `hit.tags = []` | Tags section is not rendered |
| mrr-013 | render-category | `hit.category = "Research"` | Renders uppercase label "RESEARCH" in styled capsule |
| mrr-014 | render-category | `hit.category = null` or empty string | Category section is not rendered |
| mrr-015 | render-author-display | `hit.author.displayName = "Jane Doe"` | Renders "by Jane Doe" |
| mrr-016 | render-author-display | `hit.author.displayName = ""` or null, `hit.author.slug = "jdoe"` | Renders "by @jdoe" |
| mrr-017 | render-updated-date | `hit.updatedAt = ISO 8601 date string` | Renders " · Updated {formatDate(hit.updatedAt)}" (e.g. " · Updated Jun 24, 2026") after the author line |
| mrr-018 | render-updated-date | `hit.updatedAt = null` or undefined | Date portion of footer is not rendered |
| mrr-019 | bind-select-callback | User clicks the button | `onSelect(hit)` is called with the hit object |
| mrr-020 | highlight-selected-state | `selected = true` | Border color is accent (`apt-gold`) |
| mrr-021 | highlight-selected-state | `selected = false` | Border color is neutral; hover state applies strong border |
| mrr-022 | indicate-pressed-state | `selected = true` | `aria-pressed="true"` on button element |
| mrr-023 | indicate-pressed-state | `selected = false` | `aria-pressed="false"` on button element |
| mrr-024 | implement-roving-tabindex | `active = true` | Button and link have `tabIndex={0}` |
| mrr-025 | implement-roving-tabindex | `active = false` | Button and link have `tabIndex={-1}` |
| mrr-026 | implement-roving-tabindex | `active = undefined` | No tabindex attribute set; natural tab order applies |
| mrr-027 | forward-ref-to-button | `controlRef` is a React ref object | `controlRef.current` points to the button DOM element |
| mrr-028 | manage-link-tabindex | `active = true` (button's tabIndex is 0) | Link element also has `tabIndex={0}` |
| mrr-029 | enlarge-link-touch-target | "View paper" link is rendered | Invisible `::after` overlay covers full link width with 24px height |
| mrr-030 | enlarge-link-touch-target | User touches link near but outside text bounds | Touch target is activated if within the 24px overlay zone |
| mrr-031 | set-link-href | `href = "/paper/123"` | Link element has `href="/paper/123"` |
| mrr-032 | escape-content | `hit.title` contains `<script>alert('xss')</script>` | Content is rendered as text, script is not executed |
| mrr-033 | render-rounded-corners | Component is rendered | Article, badge, and focus rings display consistent rounded corners |

## Edge Cases

- **Empty title and null title**: Component defaults to "Untitled"; no visual distinction between the two.
- **Empty query string**: `splitHighlightSegments("text", "")` returns the full text with no marks; title and snippet render without highlights.
- **Null hit.category**: Category section is not rendered; layout does not reserve space for it.
- **Empty hit.tags array**: Tags section is not rendered; footer layout adapts.
- **Very long title**: Wraps onto multiple lines with no truncation (title is unclamped; the container grows to fit).
- **Very long snippet**: Clamped to 2 lines via CSS line-clamp (**limit-snippet-lines**); overflow is truncated with an ellipsis.
- **Very long author displayName or slug**: Author text may wrap within its footer area; no ellipsis applied (browser wraps).
- **Missing hit.author.displayName and hit.author.slug**: Component renders "@undefined" or similar; no error handling for missing author fields.
- **Very long category name**: Category capsule text may overflow; rendering depends on browser and container width (Tailwind's `whitespace-nowrap` is not applied to category, allowing wrap).
- **Future-dated hit.updatedAt**: `formatDate` is called as-is; output depends on the formatter's handling of future dates (no special case defined in component).
- **Roving tabindex with active = undefined**: This occurs only for standalone rendering outside list context — a list that manages roving tabindex always passes an explicit `active` boolean. The native tab order applies with no overriding tabindex logic.

## Configuration

Not applicable: Component is a presentation-only element with no configuration options. All visual and behavioral variation is driven by props and the per-kind renderer registry.

## Deep Linking

Not applicable: Component does not handle deep linking. Navigation to the paper is driven by the `href` prop passed by the parent; the "View paper" link delegates to the browser's standard link navigation.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `markdown-result-row.untitled` | Untitled | Fallback title when `hit.title` is null or empty |
| `markdown-result-row.author-prefix` | by | Prefix for author attribution |
| `markdown-result-row.updated-prefix` | · Updated | Separator + prefix before the formatted updated-at date |
| `markdown-result-row.view-paper-link` | View paper | Text label for the public link |

All other text (title, snippet, tags, category, author name) is sourced from the data object (`hit`) and not localized by the component. Localization of data content is the responsibility of the backend or indexing layer. The updated date's formatting locale (`en-US`) is currently hardcoded in `formatDate` rather than derived from the user's locale — see Compliance (`locale-aware-formatting`).

## Accessibility Options

- **Reduce Motion**: Not applicable. Component is static; no animations are defined (transitions in the Tailwind `transition-colors` class are applied to the border color on state change, but no explicit animation keyframes are used). Reduce Motion preferences do not require special handling.
- **Increase Contrast**: Not applicable. Component uses design tokens from the `apt-*` system; contrast requirements are managed at the token level, not within this component.
- **Differentiate Without Color**: Not applicable. Selection state is indicated by both color (border) and structural change (visual containment); color is not the sole indicator.

## Feature Flags

Not applicable: Component has no feature flags. All rendering is conditional on data props; no feature gates are used.

## Analytics

Not applicable: Component does not emit or track analytics events. Event tracking (view, interaction) is the responsibility of the parent container or list manager.

## Privacy

- **Data collected**: None. Component is a pure presentation layer.
- **Storage**: No data is stored.
- **Transmission**: No data is transmitted by the component. The `href` prop is set by the parent; navigation is handled by the browser.
- **Retention**: No data retention considerations.

## Logging

Not applicable: Component does not emit log messages. Logging of search result interactions is the responsibility of the parent container.

## Platform Notes

- **React/Web** (TypeScript source): The component is rendered as an `<article>` with a nested `<button>` and `<a>` sibling for interactive controls (preserving valid and accessible DOM structure); styling uses Tailwind utility classes scoped to the `apt-*` design token system. The `Highlighted` helper function uses `splitHighlightSegments` utility to locate query matches and wraps them in `<mark>` elements; React's default escaping prevents XSS. Per-kind customization is pluggable via `kindRendererFor(hit.kind)` registry. Roving tabindex is managed externally by the list container; this component respects the `active` prop to set `tabIndex` accordingly. The link's touch target is enlarged via CSS `::after` pseudo-element (invisible overlay), implementing WCAG 2.2 SC 2.5.8 without changing the visual layout.
- **SwiftUI**: A SwiftUI equivalent would use a `VStack` with sections for badge, title, snippet, tags, category, and footer. The per-kind badge variant and subtitle source would map to SwiftUI view parameters; a passed-in `selected: Bool` parameter (not `@State`, since selection is owned by the parent list, mirroring the `selected` prop here) would track selection. Roving focus would be managed by SwiftUI's `.focusable()` and `FocusState` mechanisms. The enlarged link touch target would be implemented as a larger transparent overlay frame behind the link text, or by increasing the native button frame size. Title and snippet highlighting would require attributed strings or custom text rendering to apply inline styling (background highlight color, rounded corners) to matched segments.
- **Compose** (Android): A Compose equivalent would use a `Column` with `Row` layouts for header (badge + title), category, snippet, tags, footer. Per-kind customization would be factored into a composable parameter block (badge variant, snippet source). Selected state would modify border color and stroking; state would be held in a `MutableState` or via ViewModel. Roving tab/focus would use Compose's `FocusRequester` with `Modifier.focusRequester()` / `Modifier.focusable()` (not the deprecated `focusModifier()`). The link's touch target would be enlarged by padding the clickable `Modifier.clickable()` area or by wrapping in a larger `Box`. Highlighted text segments in title and snippet would use `AnnotatedString` with `SpanStyle` for background highlights and rounding.
- **AppKit / UIKit**: A UIKit/AppKit equivalent would use `UIStackView` (iOS) or `NSStackView` (macOS) with `UIView`/`NSView` subviews for badge, title, snippet, tags, category, and footer. Per-kind badge variant would be a delegate or registry lookup. Selected state would modify the border (using a `CAShapeLayer` or `UIBezierPath` for rounded borders) and background. Keyboard focus (roving tabindex simulation) would use `UIView.canBecomeFocused`, `setNeedsFocus()`, or `becomeFirstResponder()` on relevant subviews. The link's touch target would be enlarged by overriding `hitTest(_:with:)` or by applying a larger `UIButton` frame. Text highlighting for matched query terms would use `NSMutableAttributedString` with background color and paragraph style attributes applied to specific ranges.
- **WinUI 3**: A WinUI 3 equivalent would be a custom `UserControl` for a single row (not an `ItemsControl`, which templates a collection of items rather than one row). Per-kind badge variant would be resolved with a switch expression or `DataTemplateSelector` keyed on kind (not a `ComboBox`, which implies user selection rather than a lookup). Selected state would modify the `BorderBrush` and `BorderThickness` properties of a `Border` element wrapping the content. Keyboard focus (roving tabindex) would be managed by setting `Focus()` on the selected row's button or by manipulating `TabIndex` on each row's button and link; the parent list manager would coordinate roving focus. The link's touch target would be enlarged by applying a `Padding` thickness to the link's parent layout or by using `PointerEntered`/`PointerExited` hit-testing with a custom clickable overlay area. Text highlighting for matched query terms in title and snippet would use a `RichTextBlock` with `Run` elements styled with `Foreground` and `Background` properties, or a custom control that composes a `TextBlock` (which is sealed and cannot be subclassed) with an overlay for highlight spans.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/search/src/components/markdown/MarkdownResultRow.tsx` | unverified |

## Design Decisions

- **Decision**: The `active` prop supports three states (`true`, `false`, `undefined`).
  **Rationale**: This allows the component to integrate seamlessly into managed lists (where `active` controls the tabindex) and also render standalone (where `undefined` preserves natural tab order), avoiding forcing list context on every use case.
  **Approved**: pending

- **Decision**: Badge variant and snippet source are resolved via the `kindRendererFor(hit.kind)` registry rather than hard-coded per kind.
  **Rationale**: This allows new document kinds to be added by registering a renderer without modifying the component itself.
  **Approved**: pending

- **Decision**: Highlights are applied via semantic `<mark>` elements and React node children, never `dangerouslySetInnerHTML`.
  **Rationale**: Ensures that user-controlled text from `hit.title`, snippet, and `hit.tags` cannot introduce XSS vulnerabilities.
  **Approved**: pending

- **Decision**: The "View paper" link's visible text stays at 12px while its clickable area is enlarged to a 24px-tall zone using an invisible `::after` overlay.
  **Rationale**: This preserves the visual design while meeting WCAG 2.2 SC 2.5.8 and follows the idiom already used by the active-filter chip's × button.
  **Approved**: pending

- **Decision**: The select button and "View paper" link are rendered as sibling elements (button followed by link in the footer), not nested.
  **Rationale**: Preserves valid DOM structure and allows independent keyboard focus and interaction, avoiding the complexity of nested interactive controls.
  **Approved**: pending

- **Decision**: `kindRendererFor(hit.kind).rowSnippet(hit).trim()` is called to remove leading/trailing whitespace from the per-kind snippet.
  **Rationale**: Ensures consistent rendering regardless of formatter output.
  **Approved**: pending

- **Decision**: When `hit.title` is null or empty, the component renders "Untitled" as a fallback label.
  **Rationale**: Ensures that every row has a visible title, making the list navigable even for documents with missing or empty titles.
  **Approved**: pending

- **Decision**: The row's select control uses `aria-pressed` (a toggle-button pattern) rather than `role="option"` / `aria-selected` (a listbox pattern) to convey selection.
  **Rationale**: Each row is an independently focusable `<button>` whose tabindex is managed externally by roving-tabindex, not a native `listbox`/`option` structure; `aria-pressed` reflects the button's two-state toggle semantics without requiring the containing list to implement full listbox role and keyboard conventions.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on the source: roving tabindex is fully implemented and exercised by test vectors (keyboard-navigable: passed); the button's accessible name is verbose because an `<h3>`, badge, and tags sit inside it, the 24px touch-target overlay is smaller than platform touch minimums (44×44pt/48×48dp), the focus ring's opacity-based color hasn't been verified against a 3:1 non-text contrast requirement, and Tailwind's rem-based text sizing only partially matches OS-level Dynamic Type behavior (all: partial); `formatDate` hardcodes the `'en-US'` locale and the labels ("Untitled", "by", "Updated", "View paper") are hardcoded English strings rather than externalized resources (both: failed); date formatting, highlighting, and per-kind rendering live in separate `lib`/`registry` modules rather than inline in the component (separation-of-concerns: passed), while no test file exercises `MarkdownResultRow` itself (unit-test-coverage: failed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and split snippet highlighting into its own requirement; tightened tag/author/date/touch-target/corner-radius wording to observable, testable outcomes; replaced Compliance with a real check table; reformatted Design Decisions and added one for the aria-pressed choice; corrected accessibility-role, WCAG-reference, and platform-notes inaccuracies; resolved the title/snippet overflow and roving-tabindex edge-case contradictions; fixed Localization keys; documented component inputs; linked the Badge recipe. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
