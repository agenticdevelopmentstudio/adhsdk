---
id: 1675b18e-34d5-4d8e-987f-92697539a5e6
title: "Btn"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A pill-shaped call-to-action link component with primary and ghost variants."
platforms:
  - typescript
  - web
tags:
  - button
  - link
  - cta
  - landing
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Btn

## Overview

A pill-shaped call-to-action link component. The `primary` variant (default) is filled with the accent color token (`--lp-accent`), emphasizing the primary user action. The `ghost` variant is outlined only, for secondary actions.

## Behavioral Requirements

- **renders-anchor**: Component MUST render as an HTML anchor (`<a>`) element.
- **supports-href**: Component MUST accept an `href` prop of type `string` and pass it to the anchor element's `href` attribute.
- **supports-children**: Component MUST render the `children` prop as the link text content.
- **supports-variant-prop**: Component MUST accept a `variant` prop with values `'primary'` or `'ghost'`.
- **default-variant**: Component MUST default the `variant` prop to `'primary'` when not specified.
- **applies-btn-class**: Component MUST apply the CSS class `lp-btn` to the anchor element.
- **applies-variant-class**: Component MUST apply the CSS class `lp-btn--{variant}` corresponding to the selected variant.
- **no-extra-props**: Component MUST NOT accept or forward any props beyond `href`, `variant`, and `children`.

## Appearance

Appearance is defined and applied entirely via external CSS classes (`lp-btn`, `lp-btn--{variant}`), not by component props or inline styles. The component does not define color values, spacing, typography, or border properties directly. Visual styling including corner radius, padding, font size, and visual differences between the primary (filled with `--lp-accent`) and ghost (outlined) variants are controlled by the stylesheet that defines these classes.

## States

The component does not manage application-level states (loading, disabled, error). Link elements have inherent browser and CSS states—unvisited, visited, hover, focus, and active (pressed)—which are styled via CSS rules targeting the anchor element or its variant class selectors. The component passes these states through without modification.

## Accessibility

Component renders as a semantic HTML link element (`<a>`), which is inherently keyboard-accessible (Tab to focus, Enter to activate) and screen-reader-accessible. Link text is provided by the `children` prop; no additional `aria-label` or `aria-labelledby` attribute is applied by the component. If the link text is ambiguous, missing, or not descriptive, the parent code is responsible for providing accessible text via `children`.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| btn-001 | renders-anchor | `<Btn href="/path">Click</Btn>` | DOM element is an `<a>` tag |
| btn-002 | supports-href | `href="/signup"` | Rendered `<a>` has `href="/signup"` |
| btn-003 | supports-children | `children="Sign up now"` | Anchor text content is exactly "Sign up now" |
| btn-004 | supports-variant-prop, applies-variant-class | `variant="ghost"` | Anchor `className` is exactly `"lp-btn lp-btn--ghost"` |
| btn-005 | default-variant, applies-variant-class | No `variant` prop | Anchor `className` is exactly `"lp-btn lp-btn--primary"` |
| btn-006 | applies-btn-class | Any valid props | Anchor `className` includes `lp-btn` |
| btn-007 | supports-variant-prop, applies-variant-class | `variant="primary"` (explicit) | Anchor `className` is exactly `"lp-btn lp-btn--primary"` |
| btn-008 | applies-variant-class | `variant` forced past its type to an unsupported string (e.g. `variant={'invalid' as any}`) | Anchor `className` is exactly `"lp-btn lp-btn--invalid"`; no fallback to `primary` occurs |
| btn-009 | no-extra-props | An unrelated prop forced past the type (e.g. `target="_blank"` cast onto the props object) | Rendered `<a>` has no `target` attribute; only `class` and `href` are present |
| btn-010 | supports-children | `children=""` | Anchor renders with no visible text content; the anchor element is still present and navigable |
| btn-011 | supports-href | `href` forced past its type to `undefined` | Anchor's `href` attribute is absent; the link is present but non-functional |

## Edge Cases

- **Empty or missing children**: If `children` is `null`, `undefined`, or an empty string, the link renders with no visible text. This is not an error condition; the anchor is still navigable but semantically incomplete. Parent code is responsible for ensuring meaningful link text.
- **Missing href prop**: `href` is a required prop per TypeScript. If called without `href`, the type system prevents the call. At runtime, if `href` is `undefined`, the anchor's `href` attribute is `undefined`, resulting in a non-functional link. This is a usage error.
- **Invalid variant value**: `variant` is constrained to `'primary' | 'ghost'` by TypeScript. Passing any other string value triggers a type error. At runtime, an invalid variant string produces a class name like `lp-btn--invalid`, which may not match any CSS rules and the link may lack expected styling. This is a usage error.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `href` | `string` | (required) | Target URL or path for the anchor link |
| `variant` | `'primary' \| 'ghost'` | `'primary'` | Visual variant: `'primary'` for filled (accent background), `'ghost'` for outlined |
| `children` | `ReactNode` | (required) | Link text or content rendered inside the anchor |

## Deep Linking

Not applicable: This component is a link renderer. Deep linking is handled by the browser following the `href` prop; the component does not implement routing or deep linking behavior itself.

## Localization

Not applicable: The component renders the `children` prop directly and does not define or manage localization strings. Parent code is responsible for providing localized text via `children`.

## Accessibility Options

Not applicable: The component is a standard semantic link element and does not respond to or require platform-level accessibility display options (reduce motion, increase contrast, differentiate without color). CSS stylesheets may define such responses via media queries.

## Feature Flags

Not applicable: The source code does not define or reference any feature flags.

## Analytics

Not applicable: The component does not emit analytics events or collect metrics. Event tracking is the responsibility of parent code using click handlers or navigation listeners.

## Privacy

Not applicable: The component does not collect, store, transmit, or process any user data or sensitive information.

## Logging

Not applicable: The component does not emit logs or diagnostic messages.

## Platform Notes

- **React/Web** (`packages/web/packages/landing/src/blocks/Btn.tsx`): Functional component that computes `className` as `['lp-btn', \`lp-btn--${variant}\`].join(' ')`. The rendered `className` attribute is always exactly `lp-btn lp-btn--{variant}` (e.g. `lp-btn lp-btn--primary`, `lp-btn lp-btn--ghost`), built this one way — the component does not accept a `className` prop of its own. Styling is external to the component.

- **SwiftUI**: Use `Link(destination:)` with the link text as its label content. Apply `.buttonStyle(.borderedProminent)` and `.tint(.accentColor)` for the primary (filled, accent) variant, and `.buttonStyle(.bordered)` for the ghost (outlined) variant.

- **Compose**: Use `Button` for the primary (filled) variant and `OutlinedButton` for the ghost (outlined) variant, calling `LocalUriHandler.current.openUri(href)` from `onClick` to navigate. Place the link text in the composable's `content` lambda.

- **AppKit / UIKit**: AppKit — use `NSButton` with `bezelStyle` and `bezelColor` set to the accent color for primary, and a borderless/outline bezel for ghost. UIKit — use `UIButton` configured with `UIButton.Configuration.filled()` for primary and `UIButton.Configuration.bordered()` for ghost, setting `configuration.baseBackgroundColor` / `.baseForegroundColor` to the accent color; wire navigation through the button's action/target.

- **WinUI 3**: Use `HyperlinkButton` with `NavigateUri` set from the `href` equivalent and `Content` set to the link text. For primary, set `Background` to the accent brush (e.g. via `AccentButtonStyle`); for ghost, leave `Background` transparent and set `BorderBrush`/`BorderThickness` to render the outline. Apply a `ControlTemplate` if the pill corner radius requires more than the default style provides.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Btn.tsx` | unverified |

## Design Decisions

- **Decision**: Render a native `<a>` (anchor) element rather than a `<button>` with JavaScript navigation.
  **Rationale**: Preserves built-in browser affordances (context menus, link preview, history, keyboard shortcuts like Ctrl/Cmd+click, ability to copy or open in new tab) and maintains semantic correctness for screen readers and SEO.
  **Approved**: pending

- **Decision**: Manage appearance entirely via CSS classes (`lp-btn`, `lp-btn--{variant}`), never via component props or inline styles.
  **Rationale**: Decouples the component from color tokens, theme values, and spacing constants, keeping the component API minimal and letting styling live in centralized stylesheets that can be updated without changing component code.
  **Approved**: pending

- **Decision**: Require both `href` and `children` props, enforced by TypeScript.
  **Rationale**: Ensures every call site supplies a destination and content, catching missing-argument mistakes at compile time. This does not guarantee the content is meaningful or non-empty — `children` accepts `null`, `undefined`, or an empty string at runtime (see **supports-children** and Edge Cases); callers remain responsible for providing descriptive link text.
  **Approved**: pending

- **Decision**: Constrain the `variant` prop to the literal union `'primary' | 'ghost'` via TypeScript.
  **Rationale**: Prevents arbitrary class names and signals the available options clearly to consumers at the type level.
  **Approved**: pending

- **Decision**: Accept exactly three named props (`href`, `variant`, `children`), with no prop spreading or rest capture onto the anchor.
  **Rationale**: Keeps the rendered DOM fully predictable and prevents unvetted attributes (`onClick`, `target`, `rel`, `aria-*`, `className`) from leaking onto the anchor; consumers needing additional anchor behavior should get a dedicated variant or wrapper rather than an open prop surface.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

These statuses rest on the source rendering a plain, unmodified `<a>` element whose only attributes are `href` and `className`, with link text supplied verbatim from `children` (never a hardcoded string); color, contrast, and type sizing are delegated entirely to the external `lp-btn`/`lp-btn--{variant}` stylesheet (see Appearance and States), which is outside this recipe's source and cannot be verified here. Best-practices statuses rest on `Btn` being pure presentation over its `href`/`variant`/`children` props with no embedded logic (separation-of-concerns: passed), and on `blocks-close.test.tsx` directly rendering `Btn` and asserting its variant class output (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; added a no-extra-props requirement with vector and design decision; corrected Platform Notes APIs for SwiftUI, Compose, UIKit/AppKit, and WinUI 3; made test vectors assert exact className strings and added explicit-primary, invalid-variant, empty-children, and missing-href vectors; reformatted Design Decisions into Decision/Rationale/Approved form and weakened the required-props claim to match Edge Cases; replaced the prose Compliance section with a checks table; added tags. |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
