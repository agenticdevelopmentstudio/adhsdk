---
id: c9c48e65-6905-4035-b8e1-e053219599f1
title: DocBreadcrumbs
domain: adhsdk://recipes/doc-breadcrumbs
type: ingredient
version: 1.3.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Semantic breadcrumb trail for documentation navigation, always with home
  crumb first.
platforms:
- typescript
- web
tags:
- navigation
- breadcrumb
- documentation
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# DocBreadcrumbs

## Overview

DocBreadcrumbs renders a semantic breadcrumb trail for document navigation. It always includes a home crumb and an ancestor trail, with the current page (last crumb) rendered as plain text rather than a link. When the component is at the root (no ancestors), it renders nothing to avoid showing a redundant "Home" link pointing to the current page.

## Behavioral Requirements

- **render-navigation-element**: Component MUST render a `<nav>` element with `aria-label="Breadcrumb"`.
- **include-home-crumb**: Component MUST always include a home crumb as the first item, rendered as a link to `homeHref` (default `"/"`).
- **render-crumbs-list**: Component MUST render crumbs as an ordered list (`<ol>`) with each crumb as a list item (`<li>`).
- **render-current-as-text**: Component MUST render the last crumb (current page) as plain text, not a link.
- **render-ancestors-as-links**: Component MUST render all crumbs except the last as links to their `path` values.
- **separate-crumbs**: Component MUST visually separate crumbs with a "/" character.
- **render-nothing-at-root**: Component MUST return `null` when `crumbs` array is empty (no ancestors).
- **accept-custom-link-component**: Component MUST accept an optional `LinkComponent` prop and use it for all links instead of plain `<a>` elements.
- **accept-custom-home-label**: Component MUST accept an optional `homeLabel` prop to override the default "Home" label.
- **accept-custom-home-href**: Component MUST accept an optional `homeHref` prop to override the default "/" destination for the home crumb.
- **accept-crumbs-array**: Component MUST accept a required `crumbs` prop containing an array of objects with `label` (`ReactNode`) and `path` (string) properties, ordered root-first.
- **forward-html-attributes**: Component MUST accept and forward remaining HTMLAttributes to the `<nav>` element.

## Appearance

- **Font family**: monospace (font-mono)
- **Font size**: extra-small (text-xs)
- **Text color**: dim secondary color (`var(--color-text-dim)`)
- **Link hover color**: secondary color (`var(--color-text-secondary)`)
- **Separator color**: border color (`var(--color-border)`)
- **Margin**: 4 units bottom (mb-4)
- **Gap between items**: 1 unit (gap-1)
- **Crumb layout**: horizontal flex with centered items

## States

| State | Appearance change |
|-------|------------------|
| Default | Text in dim color (`var(--color-text-dim)`) |
| Root | Component does not render (returns null) |
| Link hover | Link text changes to secondary color (`var(--color-text-secondary)`) |

## Accessibility

- **Role**: Navigation landmark (`<nav>` element)
- **Label**: ARIA label "Breadcrumb" identifies the navigation region
- **Semantic structure**: Uses `<ol>` (ordered list) and `<li>` (list items) for proper document outline
- **Current page indicator**: Last crumb is rendered as plain text (not a link) to indicate it is the current page
- **Link semantics**: All ancestor links use the `LinkComponent` to maintain proper link semantics
- **Keyboard navigation**: All links MUST be keyboard accessible: a native `<a>` element — the default `LinkComponent` — is tabbable and activatable with Enter with no extra work; a custom `LinkComponent` MUST preserve that same native behavior.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| breadcrumb-001 | render-navigation-element | `crumbs={[{label:"Docs", path:"/docs"}]}` | Renders `<nav aria-label="Breadcrumb">` |
| breadcrumb-002 | include-home-crumb | `crumbs={[{label:"Docs", path:"/docs"}]}` | First item is a link to `/` with label "Home" |
| breadcrumb-003 | render-crumbs-list | `crumbs={[{label:"Docs", path:"/docs"}]}` | Uses `<ol>` and `<li>` elements |
| breadcrumb-004 | render-current-as-text | `crumbs={[{label:"Docs", path:"/docs"}, {label:"API", path:"/docs/api"}]}` | Last crumb "API" is plain text, not a link |
| breadcrumb-005 | render-ancestors-as-links | `crumbs={[{label:"Docs", path:"/docs"}, {label:"API", path:"/docs/api"}]}` | First crumb "Docs" is a link to "/docs" |
| breadcrumb-006 | separate-crumbs | `crumbs={[{label:"Docs", path:"/docs"}]}` | "/" character appears between home and first crumb |
| breadcrumb-007 | render-nothing-at-root | `crumbs=[]` | Component returns null (renders nothing) |
| breadcrumb-008 | accept-custom-link-component | `crumbs={[{label:"Docs", path:"/docs"}]} LinkComponent={CustomLink}` | Uses CustomLink instead of DefaultDocLink |
| breadcrumb-009 | accept-custom-home-label | `crumbs={[{label:"Docs", path:"/docs"}]} homeLabel="Dashboard"` | Home link displays "Dashboard" instead of "Home" |
| breadcrumb-010 | accept-custom-home-href | `crumbs={[{label:"Docs", path:"/docs"}]} homeHref="/app"` | Home link points to "/app" instead of "/" |
| breadcrumb-011 | accept-crumbs-array | `crumbs={[{label:"Docs", path:"/docs"}, {label:"Guides", path:"/docs/guides"}]}` | Both crumbs render in correct order |
| breadcrumb-012 | forward-html-attributes | `crumbs={[{label:"Docs", path:"/docs"}]} data-testid="breadcrumb"` | `<nav>` element has `data-testid="breadcrumb"` |

## Edge Cases

- **Empty crumbs array**: When `crumbs.length === 0`, component returns null (no render). This avoids displaying a redundant "Home" link pointing to the current page. See **render-nothing-at-root**.
- **Single crumb**: When `crumbs` has exactly one element, it renders as: Home / [CrumbLabel] (where CrumbLabel is plain text).
- **Deeply nested breadcrumbs**: All crumbs except the last are rendered as links; the implementation does not enforce a maximum nesting depth.
- **Missing crumb properties**: Every crumb MUST supply both a `label` and a `path` — the `crumbs` prop type declares both fields as required and non-nullable, so a crumb that omits either, or supplies `null` for one, is a compile-time error at the call site and never reaches the component. The component performs no runtime check for this; the type already excludes the case.
- **Empty strings in crumbs**: If a crumb has an empty `label`, it renders as an empty text node between separators. If `path` is empty, the link's `to` attribute MAY be set to an empty string — the component performs no validation and passes the value through unchanged.
- **Null or undefined crumbs prop**: `crumbs` MUST be a required, non-nullable array; passing `null` or `undefined` is a compile-time error at the call site, not a case the component handles at runtime. The empty array is the one defined "nothing to show" input, and the component MUST treat it as such (see **render-nothing-at-root**), so an absent trail collapses to nothing rather than to a bare "Home" link.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `crumbs` | `{ label: ReactNode; path: string }[]` | (required) | Array of breadcrumb objects, ordered root-first. Last crumb is the current page. |
| `homeLabel` | `ReactNode` | `"Home"` | Label displayed for the always-present first crumb. |
| `homeHref` | `string` | `"/"` | URL destination for the home crumb. |
| `LinkComponent` | `DocLinkComponent` | `DefaultDocLink` | Custom link component to replace the default. Receives `to: string` (the destination), an optional `children: ReactNode`, and any other anchor attribute except `href` (including `className`). The default, `DefaultDocLink`, renders a plain `<a href={to}>{children}</a>`. |

## Deep Linking

Not applicable: DocBreadcrumbs is a presentational component for documenting the navigation path. Deep linking is handled by the host application's router, not by this component.

## Localization

Not applicable: DocBreadcrumbs is passed localized `label` values in the `crumbs` array and `homeLabel` prop by the caller. The component itself contains no strings to translate.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: component performs no animations. |
| Increase Contrast | Partial: hovered links respond to the platform's contrast color tokens (`var(--color-text-secondary)`), but the token pairing itself is not verified against WCAG contrast ratios by this component. |
| Differentiate Without Color | Partial: an ancestor link and the current-page crumb are distinguished by semantics (link vs. plain text) and by hover-only color change; at rest, an unvisited link and the current crumb are not distinguished by anything but color. |

## Feature Flags

Not applicable: DocBreadcrumbs contains no feature-gated behavior. The host application MAY conditionally render or hide the entire breadcrumb navigation using its own feature flags.

## Analytics

Not applicable: DocBreadcrumbs is a passive presentation layer. The host application's `LinkComponent` implementation owns responsibility for tracking clicks on breadcrumb links.

## Privacy

Not applicable: DocBreadcrumbs renders no sensitive data. It displays only the navigation path provided by the host application.

## Logging

Not applicable: DocBreadcrumbs does not emit any log messages. Debug output is delegated to the `LinkComponent` implementation.

## Platform Notes

- **React/Web**: Source is React 18+ component using hooks. Styled with Tailwind CSS classes and CSS custom properties. Uses semantic HTML `<nav>`, `<ol>`, `<li>` elements and ARIA labels. Accepts `HTMLAttributes<HTMLElement>` for `<nav>` element and custom `LinkComponent` for routing integration. Render conditionally based on router/navigation context via the `crumbs` array passed by the caller.
- **SwiftUI**: SwiftUI has no native breadcrumb control, so build the trail from primitives: an `HStack` with the home link, then a `ForEach` over the ancestors rendering each as its own `Link` or `Button`, and the final element as `Text` (not a link). Keep each link a separate, individually focusable accessibility element — do not wrap the row in `.accessibilityElement(children: .combine)`, which would merge every crumb into one non-selectable element and make the individual links unreachable.
- **Compose**: Compose has no native breadcrumb control. Render ancestor crumbs as an annotated string with `LinkAnnotation.Clickable` per segment (the modern replacement for the deprecated `ClickableText`), or as separate `Text` composables with `Modifier.clickable`; render the current page as plain `Text`. Apply Material 3 color tokens for text dimming and hover/pressed states, and give each link its own `Role.Button`/`Role.Link` semantics rather than merging the row into one semantic node.
- **AppKit / UIKit**: Neither framework has a native breadcrumb control or the SwiftUI `.accessibilityElement(children: .combine)` modifier. Implement as a custom `NSView` or `UIView` subclass. Use `NSAttributedString` or `UILabel` for the static current-page text, and `NSButton`/a custom tap handler (AppKit) or a tappable `UILabel`/`UIButton` (UIKit) for ancestor links, each exposed as its own accessibility element (`NSAccessibilityElement` with `accessibilityLabel`/`accessibilityRole` on AppKit; `isAccessibilityElement` with `accessibilityTraits = .link` on UIKit) rather than one combined element. Apply platform system colors for text and link states.
- **WinUI 3**: Use the native `BreadcrumbBar` control (Windows App SDK / WinUI 3), bound to an `ItemsSource` built from the crumbs array, handling `ItemClicked` for ancestor crumbs and letting `BreadcrumbBar` render the last item as the current, non-clickable node. Apply `ThemeResource` brushes (XAML has no CSS custom properties) for the text-dim and text-secondary equivalents. `BreadcrumbBar` provides keyboard focus and automation support natively, so no separate `AutomationProperties` wiring is needed beyond `AutomationProperties.Name` on the control itself.

## Design Decisions

**Decision**: When at the root (empty crumbs), the component returns null rather than showing a single "Home" link.
**Rationale**: This avoids redundant navigation UI pointing to the current page and keeps the breadcrumb visually useful only when there is an ancestor trail to show.
**Approved**: pending

**Decision**: The last crumb is always rendered as plain text instead of a link.
**Rationale**: This follows web breadcrumb conventions (e.g., WAI-ARIA examples) and prevents users from "clicking" to reload the current page.
**Approved**: pending

**Decision**: The component deliberately does not derive breadcrumbs from the URL or page slug; crumbs are caller-supplied.
**Rationale**: Each site has its own URL structure and labeling convention (e.g., cookbook's `slugToBreadcrumbs` title-cases domain segments; another site might look labels up in a manifest). Deriving them here would bake one site's URL convention into the toolkit. Responsibility for breadcrumb construction belongs to the host application.
**Approved**: pending

**Decision**: The component accepts a `LinkComponent` prop instead of hardcoding native `<a>` elements.
**Rationale**: This allows host applications to integrate their own router (Next.js Link, React Router, etc.) without the toolkit imposing a routing library dependency.
**Approved**: pending

**Decision**: Use `<nav>`, `<ol>`, and `<li>` elements with an ARIA label.
**Rationale**: Ensures breadcrumb navigation is properly announced and indexed by assistive technology and search engines.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Semantic structure and the landmark label come directly from the rendered `<nav aria-label="Breadcrumb">`, `<ol>`, and `<li>` markup. Keyboard operability is `partial`: the default `LinkComponent` renders a plain `<a href>`, which is natively keyboard-operable, but the component hands rendering to whichever `LinkComponent` the host injects and cannot guarantee that a custom one preserves the same behavior. `separation-of-concerns` passes because `DocBreadcrumbs` renders the caller-supplied `crumbs` array with no derivation logic of its own; `unit-test-coverage` passes because `docBreadcrumbs.test.tsx` imports `DocBreadcrumbs` directly and exercises its behavior with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename all requirements to subject-only kebab-case, correct the SwiftUI/Compose/AppKit-UIKit/WinUI 3 platform notes to real native APIs, define the `DocLinkComponent` contract and default `<a>` rendering, unify the crumb `label` type as `ReactNode` everywhere, resolve the separator and hover-state contradictions, add the missing `crumbs` prop to two test vectors, mark keyboard-navigable compliance `partial` and downgrade the two color-dependent accessibility options, reformat Design Decisions into Decision/Rationale/Approved rows, link Compliance rows to canonical check IDs, drop source-file citations from Edge Cases, and unquote frontmatter dates |
| 1.2.0 | 2026-09-22 | Mike Fullerton | State the crumb shape the props type requires, and the empty-array fallback, as Edge Cases requirements |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Refine open questions on crumb property and type validation |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
