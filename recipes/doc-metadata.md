---
id: 26c4eb3c-9af9-4092-9546-bb5c5532b59c
title: DocMetadata
domain: adhsdk://recipes/doc-metadata
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Right-aligned definition list for rendering document frontmatter metadata
  fields.
platforms:
- typescript
- web
tags:
- metadata
- definition-list
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# DocMetadata

## Overview

DocMetadata is a stateless display component that renders document frontmatter fields in a right-aligned definition list. Each field is a `DocMetadataField`:

```ts
interface DocMetadataField {
  label: ReactNode
  value: ReactNode
}
```

The component detects `Array.isArray(value)`: array values wrap as a flex group, scalar values render inline. The component renders nothing when the fields array is empty.

## Behavioral Requirements

- **dl-root**: Component MUST render as an HTML `<dl>` (definition list) element.
- **label-value-pairs**: Component MUST render each field as a label (`<dt>`) paired with its value (`<dd>`).
- **empty-renders-nothing**: Component MUST return `null` when the `fields` prop is an empty array.
- **array-values-wrap**: Component MUST detect when a field value is an array and render array items wrapped in a `<span>` element with flex layout properties.
- **scalar-values-direct**: Component MUST render non-array field values as-is without additional wrapping.
- **style-override-merge**: Component MUST merge a host-supplied style override with its defaults.
- **attribute-passthrough**: Component MUST accept and apply additional HTML `<dl>` attributes via the `...rest` spread parameter.

## Appearance

- **Corner radius**: 0 (none; element is a list structure)
- **Padding**: 0 × 0 (no internal padding; gap-0.5 controls spacing between rows)
- **Font**: monospace font family, 11px size
- **Background**: transparent (inherited from parent)
- **Foreground/Text**: Labels use `--color-text-dim` CSS variable; values use `--color-text-secondary` CSS variable
- **Spacing**: 0.5 (4px) vertical gap between rows; 2 (8px) horizontal gap between label and value within a row; 3 (12px) horizontal gap between wrapped array items
- **Layout**: Each field is its own row — a flex container (`gap-2`) pairing one `<dt>` with its `<dd>`, right-aligned; rows stack vertically inside the outer flex column (`flex-col`, `items-end`, `gap-0.5`). Array values wrap inside their `<dd>` as a separate flex group with end justification.
- **Margin**: 24px (mb-6) below the component

## States

| State | Appearance change |
|-------|------------------|
| Default (fields present) | Renders `<dl>` with all fields visible |
| Empty (fields array is empty) | Renders nothing (returns `null`) |

## Accessibility

The component uses semantic HTML (`<dl>`, `<dt>`, `<dd>` elements) to represent label-value pairs. The definition list structure correctly expresses the relationship between labels and values for assistive technologies. Font size of 11px is below recommended minimums for body text; this is acceptable as the component displays metadata annotations rather than primary content. The component is not interactive and requires no additional ARIA attributes.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-metadata-001 | empty-renders-nothing | `{ fields: [] }` | Component returns `null` and renders no DOM element |
| doc-metadata-002 | dl-root | `{ fields: [{ label: "Status", value: "active" }] }` | Renders `<dl>` element in the DOM |
| doc-metadata-003 | label-value-pairs | `{ fields: [{ label: "Version", value: "1.0.0" }] }` | Renders `<dt>` containing "Version" and `<dd>` containing "1.0.0" |
| doc-metadata-004 | array-values-wrap | `{ fields: [{ label: "Tags", value: ["ui", "form"] }] }` | Renders `<span>` with flex layout containing two items right-aligned with 3 (12px) horizontal gap |
| doc-metadata-005 | scalar-values-direct | `{ fields: [{ label: "Author", value: "Jane Doe" }] }` | Value "Jane Doe" renders directly in `<dd>` without additional wrapper |
| doc-metadata-006 | style-override-merge | `{ fields: [{ label: "Status", value: "active" }], className: "custom-class" }` | `<dl>` element includes both default classes and "custom-class" |
| doc-metadata-007 | attribute-passthrough | `{ fields: [{ label: "Status", value: "active" }], "data-testid": "metadata", id: "doc-meta" }` | `<dl>` element has `data-testid="metadata"` and `id="doc-meta"` attributes |

## Edge Cases

- **Empty fields array**: Component returns `null`; no DOM render occurs.
- **Null or undefined values**: The component passes `field.value` straight through with no special-casing (see **scalar-values-direct**); a `null` or `undefined` value therefore renders as an empty `<dd>` — React's normal behavior for a nullish child, not an unhandled error path.
- **ReactNode values in arrays**: Array items are rendered as React fragments; any valid ReactNode (strings, components, elements) render correctly.
- **Special characters and markup in values**: Scalar values render as text; markup is escaped. Array item values depend on ReactNode content; if a value is a React element, it renders as intended by the host.
- **Very long labels or values**: The component applies no truncation or text overflow handling; content wraps or overflows according to the browser's default behavior and the parent container's width.
- **Dynamic field changes**: The component is stateless; re-rendering with new fields updates the DOM.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `fields` | `DocMetadataField[]` | (required) | Array of label-value pairs to display. Component renders nothing when empty. |
| `className` | `string` | `undefined` | Optional CSS class name(s) to merge with default Tailwind classes. |
| (HTML attributes) | `HTMLAttributes<HTMLDListElement>` | — | All standard `<dl>` attributes (e.g., `id`, `data-*`, `aria-*`) are accepted via rest spread. |

## Deep Linking

Not applicable: DocMetadata is a non-interactive display component with no deep-linking capability.

## Localization

Not applicable: The component does not render any text strings. All labels and values are provided by the host application, which is responsible for localization.

## Accessibility Options

Not applicable: The component is not interactive and does not respond to accessibility display options such as motion reduction or contrast enhancement. It delegates all text rendering to its container and parent theme.

## Feature Flags

Not applicable: The component contains no conditional rendering or feature-gated behavior.

## Analytics

Not applicable: The component is stateless and non-interactive; it generates no events to track.

## Privacy

Not applicable: The component does not collect, store, or transmit any data. The host application is responsible for managing the sensitivity of data passed as field values.

## Logging

Not applicable: The component performs no logging or error reporting.

## Platform Notes

- **SwiftUI**: Start with a `VStack` containing `HStack` rows for each field pair. Each row pairs a `Text` label in `.tertiary` foreground (mapping `--color-text-dim`) with a `Text` value in `.secondary` foreground (mapping `--color-text-secondary`). For array values, nest the value's items in an `HStack` with right alignment. Use `.font(.system(size: 11, design: .monospaced))` for the 11px monospace effect, with full wrapping based on layout needs.

- **Compose**: Use a `Column` with right alignment (`Modifier.align(Alignment.End)`). For each field, create a `Row` containing two `Text` composables — the label styled with `MaterialTheme.colorScheme.onSurfaceVariant` (mapping `--color-text-dim`) and the value with `MaterialTheme.colorScheme.onSurface` (mapping `--color-text-secondary`). For array values, place the items in `FlowRow(horizontalArrangement = Arrangement.End)`, right-aligned. Apply `fontFamily = FontFamily.Monospace` and `fontSize = 11.sp`.

- **React/Web**: Uses semantic `<dl>` and `<dd>` elements with Tailwind utility classes. The layout is a flex column with right alignment and 4px row gaps. The `style-override-merge` requirement is implemented via the `cn()` utility, which merges the optional `className` prop with the component's default Tailwind classes. Leverages CSS custom properties (`--color-text-dim`, `--color-text-secondary`) for colors, allowing theme injection at the document root. Array values wrap in a `<span>` with `flex flex-wrap justify-end gap-x-3` for right-aligned flow layout.

- **AppKit / UIKit**: Use `NSStackView` (macOS) or `UIStackView` (iOS) with vertical distribution and right alignment. For each field, create a horizontal stack containing a label `NSTextField`/`UILabel` in `NSColor.tertiaryLabelColor`/`UIColor.tertiaryLabel` (mapping `--color-text-dim`) and a value field in `NSColor.secondaryLabelColor`/`UIColor.secondaryLabel` (mapping `--color-text-secondary`). Monospace styling uses `NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)` on macOS or `UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)` on iOS. Array values nest in a separate horizontal stack with right alignment and adequate spacing.

- **WinUI 3**: Use a `StackPanel` with `Orientation="Vertical"` and `HorizontalAlignment="Right"`. Each field row is a horizontal `StackPanel` pairing a `TextBlock` label styled with `TextFillColorTertiaryBrush` (mapping `--color-text-dim`) and a `TextBlock` value styled with `TextFillColorSecondaryBrush` (mapping `--color-text-secondary`). Apply `FontFamily="Cascadia Mono"` (or a theme resource) and `FontSize="11"` for monospace. For array values, use an `ItemsRepeater` with its `ItemsPanel` set to a wrap layout, right-aligned.

## Design Decisions

**Decision**: The component is intentionally minimal and stateless — it accepts pre-formatted data from the host and renders it with no transformation.
**Rationale**: Labels and values come from the host; the component's sole job is layout and styling.
**Approved**: pending

**Decision**: Render the field list as a semantic `<dl>` element with `<dt>`/`<dd>` pairs.
**Rationale**: Definition lists are the correct HTML structure for label-value metadata.
**Approved**: pending

**Decision**: Right-align the entire component.
**Rationale**: Right alignment positions the metadata visually as supplementary annotation, not primary content.
**Approved**: pending

**Decision**: Use an 11px monospace font for labels and values.
**Rationale**: Monospace at this size is a conventional pattern for document metadata, distinguishing frontmatter from prose body text.
**Approved**: pending

**Decision**: Wrap array values as a right-aligned flex group instead of forcing horizontal scroll or truncation.
**Rationale**: Allows the component to handle multi-valued fields (tags, references, platforms) cleanly within the row.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | failed | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Semantic-markup passes because the source renders proper `<dl>`/`<dt>`/`<dd>` elements; contrast-ratio is partial because the label and value colors are unresolved theme CSS variables (`--color-text-dim`, `--color-text-secondary`) whose computed ratio the source cannot tell you; dynamic-type-support fails because the source hardcodes a fixed 11px font size (`text-[11px]`) that does not scale with system text-size settings. `separation-of-concerns` passes because `DocMetadata` renders the caller-supplied `fields` with no formatting logic of its own; `unit-test-coverage` passes because `docMetadata.test.tsx` imports `DocMetadata` directly and exercises its behavior with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; added the `DocMetadataField` type before requirements; converted Compliance to a table; split Design Decisions into Decision/Rationale/Approved entries; corrected the Appearance margin, added the array-item gap, and clarified per-field row layout; fixed Platform Notes APIs (SwiftUI font size, Compose FlowRow, WinUI ItemsRepeater, native monospace fonts, color-token mappings); fixed test-vector syntax; clarified null/undefined value passthrough as deterministic, not unguarded. |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
