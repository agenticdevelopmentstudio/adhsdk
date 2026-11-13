---
id: ee901ea5-cf3e-4276-8367-0693911bc02e
title: "Markdown Reading Palette"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Server-safe wrapper that applies a reading theme palette to markdown content."
platforms:
  - typescript
  - web
tags:
  - markdown
  - theming
  - styling
depends-on: []
related:
  - 316aed50-a6cb-4ece-977c-8d6dacb2186b
references: []
approved-by: ""
approved-date: ""
---

# Markdown Reading Palette

## Overview

A server-safe React wrapper component that applies a reading theme palette to markdown content. The component sets theme-aware CSS custom properties (`--mdv-*`), data attributes for theme identification, and layout classes on a container around markdown children. It is designed to be used within async React Server Components without converting them to Client Components.

## Behavioral Requirements

- **render-children**: Component MUST render `children` prop without modification or transformation.
- **theme-data-attributes**: Component MUST set `data-mdv-theme` attribute to the theme's ID and `data-mdv-shiki-variant` attribute to the theme's syntax highlighting variant.
- **theme-palette-style**: Component MUST apply the theme's color palette as inline CSS custom properties via the `style` prop.
- **content-class**: Component MUST apply the `adh-mv-content` class to the wrapper element. This class provides load-bearing styles for background color, text color, padding, and overflow behavior that enable markdown content to be readable within its host context.
- **classname-merge**: Component MUST merge the `className` prop with `adh-mv-content` using the `cn` utility function, preserving both the theme-driven layout classes and any caller-supplied layout classes (e.g., sizing, borders, rounding).
- **theme-id-prop**: Component SHOULD accept an optional `themeId` prop. When provided, the component MUST use that theme ID; when omitted, the component MUST default to `DEFAULT_THEME_ID`.
- **data-slot-forwarding**: Component SHOULD accept an optional `data-slot` prop to enable callers to set a DOM identity marker for testing, styling, or selection purposes. When provided, this prop MUST be forwarded directly to the wrapper element's `data-slot` attribute.
- **server-safe**: Component MUST be server-safe, with no React hooks, no client-only APIs (e.g., browser globals, event handlers), and no "use client" directive. The component MUST be compatible with async React Server Components.

## Appearance

MarkdownReadingPalette does not define its own visual dimensions, spacing, or colors. It always applies the same static `adh-mv-content` class — that class name never changes — plus the selected theme's `--mdv-*` custom properties as inline `style`. Only those custom-property values vary by theme; see `packages/web/packages/markdown/src/themes/palettes.ts` for the four built-in palettes (dark, light, sepia, github).

## States

Not applicable: MarkdownReadingPalette is a static, non-interactive wrapper component with no stateful behaviors (no pressed, focused, disabled, or loading states).

## Accessibility

MarkdownReadingPalette renders no interactive elements of its own, but it does set the foreground (`--mdv-text`) and background (`--mdv-bg`) colors that decide the contrast of everything rendered inside it (see **content-class**, **theme-palette-style**). Every theme applied through this component MUST meet WCAG AA contrast (4.5:1 for normal text) between `--mdv-text` and `--mdv-bg`. All four built-in themes clear this by a wide margin: dark ≈15.7:1, light ≈15.9:1, sepia ≈13.6:1, github ≈15.8:1. See [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) under Compliance. Accessibility of the markdown content itself (semantic HTML, ARIA) remains the responsibility of the markdown renderer (e.g., MarkdownRenderer), not this wrapper.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| palette-001 | render-children | `<MarkdownReadingPalette><div>Hello</div></MarkdownReadingPalette>` | Rendered output includes `<div>Hello</div>` unchanged |
| palette-002 | theme-data-attributes | `themeId="dark"` (registry theme `dark`, `shikiVariant: "dark"`) | Rendered div has `data-mdv-theme="dark"` and `data-mdv-shiki-variant="dark"` |
| palette-003 | theme-palette-style | `themeId="dark"` (registry theme `dark`'s palette) | Rendered div `style` prop includes `"--mdv-bg": "#0c0c0f"` and `"--mdv-text": "#e8e6e3"` |
| palette-004 | content-class | No className prop supplied | Rendered div has class `adh-mv-content` |
| palette-005 | classname-merge | `className="border rounded"` | Rendered div class attribute includes both `adh-mv-content` and `border rounded` |
| palette-006 | theme-id-prop, data-slot-forwarding | `themeId="light"`, `data-slot="markdown-preview"` | Rendered div has `data-mdv-theme="light"` and `data-slot="markdown-preview"` |
| palette-007 | theme-id-prop | No `themeId` prop supplied | Rendered div uses the `DEFAULT_THEME_ID` (`"dark"`) theme |
| palette-008 | server-safe | Component rendered via `renderToString` inside an async server component | `renderToString` succeeds without throwing, and the component's source file contains no `"use client"` directive and no React hook imports |
| palette-009 | render-children | `<MarkdownReadingPalette>{null}</MarkdownReadingPalette>` | Wrapper div renders with the theme applied and no child content |
| palette-010 | theme-data-attributes, theme-palette-style | `themeId="not-a-real-theme"` | `getThemeById` does not throw; rendered div has `data-mdv-theme="dark"` (the `DEFAULT_THEME_ID` fallback theme) and that theme's palette applied |
| palette-011 | classname-merge | `className="   "` (whitespace only) | Rendered div `class` attribute is exactly `adh-mv-content` |

## Edge Cases

- **Null or empty children**: When children is `null`, `undefined`, or an empty array, the component MUST render the wrapper div with the theme applied. The wrapper div renders but contains no child content. See palette-009.
- **No themeId provided**: When no `themeId` prop is supplied, the component MUST use the `DEFAULT_THEME_ID` constant from the themes registry. See palette-007.
- **Invalid themeId**: When a `themeId` is provided but does not match any entry in the themes registry, `getThemeById` MUST NOT throw — it returns the theme identified by `DEFAULT_THEME_ID` instead, and the component renders using that fallback theme's data attributes and palette (**theme-data-attributes**, **theme-palette-style**). See palette-010.
- **Empty or whitespace-only className**: When `className` is an empty string or contains only whitespace, the rendered wrapper element's `class` attribute MUST be exactly `adh-mv-content`. See palette-011.
- **Multiple class names in className prop**: When `className` contains multiple classes (e.g., `"border rounded-lg shadow"`), all classes MUST be preserved in the merged output. See palette-005.

## Configuration

Not applicable: MarkdownReadingPalette does not expose configuration options beyond its props interface (themeId, className, data-slot).

## Deep Linking

Not applicable: MarkdownReadingPalette is a non-interactive wrapper component with no navigation, routing, or deep linking behavior.

## Localization

Not applicable: MarkdownReadingPalette contains no user-facing text strings, labels, or messages requiring localization.

## Accessibility Options

Not applicable: MarkdownReadingPalette is a non-interactive wrapper component that does not respond to platform accessibility display settings (reduce motion, increase contrast, differentiate without color). Accessibility concerns are handled by the markdown renderer and the host application's theme selection.

## Feature Flags

Not applicable: MarkdownReadingPalette has no feature flags; it is always enabled when imported.

## Analytics

Not applicable: MarkdownReadingPalette is a non-interactive wrapper component with no user actions or events to track. Analytics instrumentation, if needed, belongs in the host component that uses this wrapper or in the markdown renderer.

## Privacy

Not applicable: MarkdownReadingPalette does not collect, transmit, or store any user data or sensitive information. It is a pure presentational wrapper with no network requests or data handling.

## Logging

Not applicable: MarkdownReadingPalette has no operational logging. Error handling (e.g., invalid theme IDs) is delegated to the `getThemeById` function and theme registry.

## Platform Notes

- **React/Web**: Exported from `packages/web/packages/markdown/src/components/MarkdownReadingPalette.tsx`. Server-safe by design — no React hooks, no "use client" directive, compatible with async RSCs. Receives theme from the `getThemeById` function in the themes registry. Merges className via `cn` utility from `@adh-sdk/ui/lib/utils`.
- **SwiftUI**: A SwiftUI wrapper reads theme colors from the environment (a custom `EnvironmentKey` or `EnvironmentObject`) and applies them to its content via `.background()` and `.foregroundStyle()`. The equivalent of `data-mdv-theme` for testing/selection MUST be an `.accessibilityIdentifier()` on the wrapper view.
- **Compose**: A Compose wrapper reads the theme from a `CompositionLocal` and applies it via `Box`/`Surface`, using `backgroundColor` from `MaterialTheme.colorScheme` (or the custom palette) and `contentColor` for text. The equivalent of `data-mdv-theme` for testing/selection MUST be a `Modifier.testTag()` on the wrapper.
- **AppKit / UIKit**: A UIKit wrapper sets `layer.backgroundColor` and its content's text color via `UIColor`, with Auto Layout constraints supplying the padding. AppKit applies the same pattern with `NSView.layer.backgroundColor` and `NSColor`. The equivalent of `data-mdv-theme` for testing/selection MUST be `accessibilityIdentifier`.
- **WinUI 3**: A WinUI 3 wrapper applies theme colors to a `Grid` or `StackPanel`'s `Background` and to child elements' `Foreground`, sourced from a `ResourceDictionary` or a bound theme object. The equivalent of `data-mdv-theme` for testing/automation MUST be `AutomationProperties.AutomationId` or a custom attached property — not `x:Name` (fixed at compile time, can't be set dynamically) or `Tag` (invisible to UI Automation).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/markdown/src/components/MarkdownReadingPalette.tsx` | unverified |

## Design Decisions

**Decision**: The component is written without hooks or client-only APIs so it can be used within async React Server Components.
**Rationale**: This constraint is a feature, not a limitation — it allows async server-rendered document views to use this wrapper without client-side hydration overhead. Callers that need client-side behavior should wrap this component in a Client Component of their own.
**Approved**: pending

**Decision**: The component merges the caller's `className` with `adh-mv-content` via `cn`, rather than replacing one or the other.
**Rationale**: This allows callers to supply layout modifiers (sizing, borders, rounding) while preserving the theme-driven layout class. The `adh-mv-content` class is load-bearing for background, padding, and overflow — removing it would break readability.
**Approved**: pending

**Decision**: The component accepts `data-slot` as a prop rather than hardcoding a value like `"markdown-reading-palette"`.
**Rationale**: The component is a generic reading surface reused under different names by different hosts (e.g., `MarkdownDocumentEditor`'s preview pane uses `"markdown-preview"`, while a future caller might use something else). Taking the slot as a prop lets each host name it according to its context.
**Approved**: pending

**Decision**: The component calls `getThemeById(themeId)` at render time rather than caching or memoizing the lookup.
**Rationale**: This keeps the component simple and ensures it reflects the current `themeId` prop on each render, without introducing component state.
**Approved**: pending

**Decision**: The component does not validate `themeId` or wrap `getThemeById` in a try/catch of its own.
**Rationale**: `getThemeById` already handles an unrecognized id by falling back to the `DEFAULT_THEME_ID` theme instead of throwing, so a markdown reading surface never fails to render over a stale or unrecognized theme id. Because the fallback lives in `getThemeById`, the component needs no error-handling logic of its own.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

This rests on the four built-in themes' `--mdv-text`/`--mdv-bg` pairs in `themes/palettes.ts`, each of which computes to at least a 13.5:1 WCAG contrast ratio; contrast for any theme added later is the themes registry's responsibility, not this wrapper's runtime behavior. `separation-of-concerns` passes because the component is a pure presentation wrapper that delegates theme lookup to `getThemeById` from `../themes/registry`, with no business logic of its own; `unit-test-coverage` fails because no test file references `MarkdownReadingPalette`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; corrected the invalid-theme-id edge case and design decision 5 to match `getThemeById`'s actual no-throw fallback; removed the unsupported dynamic-theme-switching claim from design decision 4; generalized design decision 1's app reference; reformatted Design Decisions to Decision/Rationale/Approved; rewrote Compliance with a real linked check; rewrote Appearance and Accessibility to describe the static class and the theme's contrast requirement; made the server-safe test vector concrete; rephrased the whitespace-className edge case around the component's own output; relabeled Platform Notes to React/Web and fixed the WinUI 3 equivalent of `data-mdv-theme`; added markdown-renderer to related; unquoted the modified date; added test vectors for null children, invalid theme id, and whitespace className |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from source |
