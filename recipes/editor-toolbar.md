---
id: 3C65C844-6C3C-43E2-B792-8575F5DDA9CF
title: EditorToolbar
domain: adhsdk://recipes/editor-toolbar
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Semantic HTML toolbar wrapper with flexbox layout and ARIA accessibility
  for text editor surfaces.
platforms:
- typescript
- web
tags:
- toolbar
- layout
- accessibility
- editor
depends-on: []
related: []
references:
- https://www.w3.org/WAI/ARIA/apg/patterns/toolbar/
approved-by: ''
approved-date: ''
---

# EditorToolbar

## Overview

EditorToolbar is a semantic layout wrapper that houses a horizontal control strip for text-editor surfaces (such as the row above a MarkdownEditor's textarea). It provides `role="toolbar"` and `aria-label` semantics for assistive technology, combined with flexbox layout and consistent gap spacing. The component is server-safe—it contains no hooks or client-side logic—and exists purely to establish correct HTML semantics and layout constraints for its children.

## Behavioral Requirements

- **toolbar-role**: Component MUST render a `div` element with `role="toolbar"` to identify itself to assistive technology as a toolbar region.
- **aria-label-prop**: Component MUST accept an `ariaLabel` prop that is passed directly to the `aria-label` attribute of the rendered element.
- **aria-label-default**: Component MUST use the default aria-label value `"Editor toolbar"` when the `ariaLabel` prop is not provided.
- **render-children**: Component MUST render the `children` prop without modification or filtering.
- **class-name-merge**: Component MUST accept a `className` prop and merge it with the component's default layout classes so that a caller's classes can override the defaults.
- **flex-layout**: Component MUST render with `display: flex` to establish flexbox layout for its children.
- **vertical-center**: Component MUST use flexbox alignment to center children vertically (`align-items: center`).
- **child-gap**: Component MUST apply a consistent horizontal gap of `0.375rem` (6 pixels) between direct child elements.

## Appearance

- **Layout**: Flexbox row with horizontal gap
- **Gap spacing**: 0.375rem (6px) between children
- **Vertical alignment**: Children centered vertically
- **Background**: None (transparent by default)
- **Border**: None
- **Shadow**: None
- **Min/Max size**: No constraints applied by the component

## States

Not applicable: EditorToolbar is a pure layout container with no interactive state. It does not respond to user input and has no pressed, disabled, focused, or loading states.

## Accessibility

- **Role**: `toolbar` — identifies the region as a toolbar to assistive technology (see **toolbar-role**). The component establishes this semantic grouping only; see the Design Decisions entry below for what it deliberately does not provide.
- **Accessible name**: MUST be provided via `aria-label`. The default name is `"Editor toolbar"` (see **aria-label-default**), which is announced by screen readers when focus enters or the region is explicitly searched. If a caller explicitly passes `ariaLabel=""`, the component applies it as given rather than falling back — see Edge Cases: **Empty ariaLabel** — which leaves the region with no accessible name; that is a caller error the component does not guard against.
- **Child focus management**: The component does not manage focus; child elements are responsible for their own keyboard and focus behavior. Because `role="toolbar"` alone does not deliver the WAI-ARIA toolbar keyboard pattern (roving tabindex, arrow-key navigation, Home/End), consumers must not expect toolbar keyboard shortcuts from this container — see **keyboard-navigable** in Compliance and the Design Decisions entry below.
- **Minimum tap target**: Not applicable to the container itself; child elements are responsible for meeting touch target size requirements (44×44pt minimum on iOS, 48×48dp minimum on Android, per platform guidelines).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| editor-toolbar-001 | toolbar-role | Render component with default props | `<div role="toolbar" ...>` is present in the DOM |
| editor-toolbar-002 | aria-label-default | Render component without `ariaLabel` prop | Element has `aria-label="Editor toolbar"` |
| editor-toolbar-003 | aria-label-prop | Render with `ariaLabel="Custom toolbar"` | Element has `aria-label="Custom toolbar"` |
| editor-toolbar-004 | render-children | Render with `children={<button>Bold</button>}` | Button element is rendered inside the toolbar |
| editor-toolbar-005 | class-name-merge | Render with `className="custom-class"` | Element has both default classes and `custom-class` applied |
| editor-toolbar-006 | flex-layout | Unit test: render component and inspect the rendered `class` attribute | Class attribute contains `flex` |
| editor-toolbar-007 | vertical-center | Unit test: render component and inspect the rendered `class` attribute | Class attribute contains `items-center` |
| editor-toolbar-008 | child-gap | Unit test: render component and inspect the rendered `class` attribute | Class attribute contains `gap-1.5` |
| editor-toolbar-009 | vertical-center | Playwright: render with tall and short children in a browser; measure each child's bounding-box vertical center | All children's vertical centers match within a 1px tolerance; no baseline drift |
| editor-toolbar-010 | child-gap | Playwright: render with multiple child elements in a browser; measure the gap between adjacent children | Horizontal gap is 6px ± 1px |
| editor-toolbar-011 | child-gap | Playwright: render with `className="gap-4"` and multiple children; measure the gap between adjacent children | Horizontal gap is 16px ± 1px — the caller's `gap-4` overrides the default `gap-1.5` (tailwind-merge resolves the conflict; the later class wins) |

## Edge Cases

- **No children**: Component MUST render successfully with `children={undefined}` or `children={[]}`, producing an empty `<div role="toolbar">` element.
- **Single child**: Component MUST render successfully with a single child; gap spacing is not visible with only one child.
- **Empty ariaLabel**: If `ariaLabel=""` is explicitly passed, component MUST apply the empty string as the aria-label as given — it does not fall back to the default and does not warn. Assistive technology then announces only the role ("toolbar") with no accessible name; callers must not pass an empty string if they want the region to have an accessible name.
- **Multiple className values with conflicting styles**: The `cn()` utility resolves class conflicts using `tailwind-merge`, which is deterministic: within the same Tailwind class group, the later class in the merged argument order wins. A caller's `gap-4` therefore overrides the default `gap-1.5` (see Conformance Test Vector editor-toolbar-011).
- **Server-side rendering**: Component is server-safe; it contains no hooks or client-side logic and MUST render correctly in server-side rendering contexts.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ariaLabel` | `string` | `"Editor toolbar"` | Accessible name for the toolbar, announced by assistive technology |
| `className` | `string` | `undefined` | Optional CSS class string merged with default layout classes |
| `children` | `ReactNode` | `undefined` | Child elements to render inside the toolbar |

## Deep Linking

Not applicable: EditorToolbar is a layout container without deep-linking capabilities. Navigation and routing are managed by child components or parent pages.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `ariaLabel` (default) | `Editor toolbar` | Accessible name announced by screen readers when the caller does not supply `ariaLabel`. This default is a hardcoded English string and is not localized by the component itself; callers rendering in a non-English locale MUST supply a localized `ariaLabel`. |

## Accessibility Options

Not applicable: EditorToolbar is a pure layout component that responds to no accessibility display options (reduce motion, increase contrast, etc.). Child elements are responsible for responding to accessibility options as needed.

## Feature Flags

Not applicable: EditorToolbar is a foundational layout component with no feature flag support. Conditional rendering is handled at the parent level.

## Analytics

Not applicable: EditorToolbar is a layout container with no analytics instrumentation. Analytics for toolbar interactions are managed by child components.

## Privacy

Not applicable: EditorToolbar processes no user data and transmits no information. It is a static layout container.

## Logging

Not applicable: EditorToolbar has no logging. Debugging of toolbar child elements is performed at the child component level.

## Platform Notes

- **React/Web**: Source file `packages/web/packages/ui/src/components/editor-toolbar.tsx`. Renders a `div` with the Tailwind classes `flex items-center gap-1.5`, merged with a caller-supplied `className` via the `cn()` utility (`clsx` + `tailwind-merge`) from the local `lib/utils` module. `tailwind-merge` resolves conflicting utility classes deterministically — within a class group, the later class wins — so a caller's `gap-4` overrides the default `gap-1.5`. Server-safe; no `use client` directive required.
- **SwiftUI**: Start from an `HStack(spacing: 6)`. Native toolbar containers (`.toolbar`, `ToolbarItemGroup`) attach chrome to a `NavigationStack` or window and don't apply to a strip embedded above a text view, so use a plain `HStack` instead. Group it for assistive technology with `.accessibilityElement(children: .contain)` and set the accessible name with `.accessibilityLabel(_:)`.
- **Compose**: Start from a `Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically)`. `Role.ToolBar` does not exist in Compose's semantics API; apply `Modifier.semantics { contentDescription = "Editor toolbar" }` (or the caller-supplied label) to the `Row` instead. Compose's `TopAppBar`/`BottomAppBar` are for app-level chrome, not an in-editor strip, so they don't apply here. Do not use `LazyRow` — toolbar children are a small, fixed set, not a large scrollable dataset.
- **AppKit / UIKit**: Start from an `NSStackView` (AppKit) or `UIStackView` (UIKit) configured with `axis = .horizontal`, `spacing = 6`, and `alignment = .center`. `NSToolbar` (AppKit) and `UIToolbar` (UIKit) attach to a window or navigation bar for app-level chrome and don't apply to a strip embedded above a text view, so use the stack view instead. If using SwiftUI on iOS/macOS, use the native `HStack` above. Apply an accessibility label and container semantics equivalent to `.accessibilityElement(children: .contain)` to the stack view.
- **WinUI 3**: Start from a `StackPanel` with `Orientation="Horizontal"` and `Spacing="6"`. `VerticalAlignment="Center"` on the `StackPanel` positions the panel itself, not its children; set `VerticalAlignment="Center"` on each child instead (or via an implicit `Style` targeting the child type). The `StackPanel` is the toolbar's root — no additional `Grid` or `Border` parent is needed. `CommandBar` supplies built-in overflow/menu chrome for app-level toolbars and isn't a fit for a plain in-editor strip; prefer the `StackPanel`. Set `AutomationProperties.Name` to the equivalent of the `aria-label` prop for UIA accessibility.

## Design Decisions

**Decision**: Render as a headless, minimal wrapper — semantic HTML structure and flexbox layout only, with all visual styling deferred to the caller via `className`.
**Rationale**: This design allows the component to work in any visual context (light mode, dark mode, custom themes) without baking in colors or opinionated styling; its sole responsibility is correct toolbar semantics and consistent child spacing, leaving presentational concerns to the parent or a parent-provided theme.
**Approved**: pending

**Decision**: Use `role="toolbar"` for semantic grouping without implementing the WAI-ARIA toolbar keyboard pattern (roving tabindex, arrow-key navigation, Home/End); focus and keyboard handling are left entirely to child elements.
**Rationale**: The component composes arbitrary, caller-supplied children and cannot know their keyboard semantics in advance. It establishes the `toolbar` region for assistive technology without promising keyboard behavior it doesn't implement — see **keyboard-navigable** in Compliance for the resulting gap.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | failed | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`semantic-markup` is `partial` because the source (`editor-toolbar.tsx`) sets `role="toolbar"` and `aria-label` but does not guard an explicitly empty `ariaLabel`, and the `toolbar` role doesn't fully match the keyboard behavior it implies; `keyboard-navigable` is `failed` because the source has no focus or keyboard handling at all; `no-hardcoded-strings` is `failed` because the default `"Editor toolbar"` string is a literal in the source rather than a localization lookup. `separation-of-concerns` is `passed` because the source is pure layout over props with no business logic; `unit-test-coverage` is `failed` because `markdownSpellcheck.test.tsx` exercises a different control and no test renders `EditorToolbar` itself.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed must-* requirements to subject-only kebab-case; reformatted Design Decisions into Decision/Rationale/Approved form and added a decision documenting the toolbar-role/keyboard-behavior gap; corrected Compliance check names against the catalog and added keyboard-navigable and no-hardcoded-strings; rewrote Platform Notes to drop the Tailwind/`cn()` coupling outside the React/Web note and to address native toolbar controls per platform; split Conformance Test Vectors into unit class assertions and Playwright pixel/gap vectors, adding a vector for className override precedence; reconciled the Accessibility section with the Empty ariaLabel edge case; populated Localization with the hardcoded default string; added the WAI-ARIA toolbar reference; added tags; fixed modified-date quoting |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
