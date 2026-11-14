---
id: 335f37a4-cd9e-4575-a78a-8717b34e5a2d
title: "Code"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A block of literal text in monospace, displaying shell transcripts, invocations, or config fragments with horizontal scrolling and no text wrapping."
platforms:
  - typescript
  - web
tags:
  - code-display
  - monospace
  - text-block
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Code

## Overview

The Code component displays literal text in a monospace (mono) typeface without interpretation, wrapping, or markup. It is designed for shell transcripts, command invocations, configuration fragments, and other content where exact formatting and readability are essential. The component scrolls horizontally rather than wrapping long lines, preserving the structure of the original text.

## Behavioral Requirements

- **render-as-preformatted**: The component MUST render text with preserved whitespace and line breaks exactly as provided in the `text` prop.
- **no-wrap**: The component MUST NOT wrap text to fit the container width; it MUST scroll horizontally when content exceeds the available width.
- **accept-string-prop**: The component MUST accept a single `text` prop of type `string` containing the literal content to display.
- **no-markup-interpretation**: The component MUST NOT interpret, parse, or render any markup (HTML, markdown, JSX, or other syntax) within the `text` prop; the entire string MUST be rendered as literal text.
- **use-monospace-font**: The component MUST render text in a monospace typeface appropriate to the deck's design system.

## Appearance

- **Font**: Monospace, `var(--lp-font-mono, ui-monospace, "SF Mono", monospace)`, at `font-size: 0.8rem` and `line-height: 1.85`.
- **Background**: `var(--lp-card, rgba(255, 255, 255, 0.04))`.
- **Foreground/Text**: `var(--lp-ink, #ededed)`.
- **Padding**: `1.1rem` vertical × `1.25rem` horizontal.
- **Corner radius**: `var(--lp-radius, 14px)`.
- **Border**: `1px solid var(--lp-hairline, rgba(216, 216, 216, 0.18))`.
- **Shadow**: None. No shadow is applied by the source.
- **Min/Max size**: No enforced constraints; width grows with content (horizontal scroll as needed); height determined by line count and line-height.
- **Overflow**: Horizontal overflow MUST scroll (`overflow-x: auto`); vertical overflow MUST be visible or scroll as needed.

These are CSS custom properties supplied by the host page/theme, each with the literal fallback value shown; `lp-code` does not resolve them itself.

## States

| State | Appearance change |
|-------|------------------|
| Default | Content is displayed in monospace with deck-defined colors and spacing |
| User selects text | Text selection styling follows deck's text selection color and appearance |
| User scrolls horizontally | Horizontal scrollbar appears (or deck-defined scroll behavior) |

## Accessibility

- **Role/Trait**: The component MUST render as a `<pre>` element (preformatted text block). The `<code>` child indicates the content is code.
- **Label requirements**: A parent heading or caption SHOULD precede the code block to provide context; composing recipes are responsible for supplying it, since this ingredient cannot enforce a host's heading structure. The code block itself does not require an `aria-label` if that context is clear from surrounding content.
- **Announce state changes**: Not applicable; this is a static, read-only component with no interactive state changes.
- **Keyboard navigation**: The code block SHOULD be focusable when its rendered width exceeds the container, so the horizontally scrollable region can be reached and scrolled by keyboard (see the axe `scrollable-region-focusable` check). The current React/Web implementation renders a plain `<pre>` with no `tabIndex`, so this is not yet met — see **keyboard-navigable** in Compliance.
- **Minimum tap target**: Not applicable; the code block is read-only and not directly interactive.
- **Semantic structure**: The `<pre><code>` nesting MUST be preserved to indicate preformatted code to assistive technologies.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| code-001 | render-as-preformatted | `text: "line1\nline2\n  indented"` | Output preserves newlines and leading spaces; renders as three lines with the third indented |
| code-002 | no-wrap | `text: "a very long command that exceeds container width"` | Computed `white-space: pre` on the `<pre>`; the line does not break into multiple lines |
| code-003 | accept-string-prop | `text: "$ echo hello"` | Component renders without error; text appears as `$ echo hello` |
| code-004 | no-markup-interpretation | `text: "# Heading\n**bold** <html>"` | Output renders literally as `# Heading\n**bold** <html>` with no markdown or HTML interpretation |
| code-005 | use-monospace-font | `text: "code"` | Computed `font-family` on the `<pre>` resolves to the mono token (`var(--lp-font-mono)`), distinct from the deck's body `font-family` |
| code-006 | render-as-preformatted (empty-string edge case) | `text: ""` | Renders `<pre><code></code></pre>` with no children; the source sets no `min-height` on `.lp-code` or `.lp-code code`, so the content box collapses to `0` height and only the block's own padding (`1.1rem` top and bottom) and `1px` border remain — visibly shorter than a populated one-line block (`1.48rem`, i.e. `0.8rem × 1.85`), so a layout shift occurs going from empty to non-empty text |
| code-007 | render-as-preformatted (whitespace-only edge case) | `text: "   \t\n  "` | All spaces, the tab, and the newline are preserved exactly; rendered text length and line count match the input |
| code-008 | no-wrap (tabs edge case) | `text: "a\tb\tc"` | Tab renders at the CSS default `tab-size: 8` (not overridden by `lp-code`); columns are not collapsed to a single space |
| code-009 | no-markup-interpretation (Unicode edge case) | `text: "café 日本語 🎉"` | All characters render literally and unmodified, including the emoji and non-Latin script; no transformation or substitution occurs |
| code-010 | no-wrap | `text: "a very long command that exceeds container width"` | Computed `overflow-x: auto` on the `<pre>`; `scrollWidth > clientWidth` once content exceeds the container |

## Edge Cases

- **Empty string**: If `text` is an empty string, the component MUST render an empty `<pre><code>` block. Neither `.lp-code` nor `.lp-code code` sets a `min-height`, so the block's content box collapses to `0` and only its own padding and border remain — shorter than a populated one-line block (`0.8rem × 1.85` ≈ `1.48rem`) — so a layout shift does occur when `text` transitions between empty and non-empty.
- **Whitespace-only input**: If `text` contains only whitespace (spaces, tabs, newlines), the component MUST render and preserve all whitespace exactly as provided.
- **Very long lines**: If a single line exceeds the container width significantly, the component MUST provide horizontal scrolling without breaking the line.
- **Tabs and special characters**: The component MUST preserve tabs, multiple spaces, and other whitespace characters exactly as provided, rendering per CSS `white-space: pre`. Tab width follows the CSS default `tab-size: 8`, which `lp-code` does not override; a host needing a different width must set `tab-size` explicitly.
- **Unicode and non-ASCII characters**: The component MUST render all valid Unicode characters, including emoji and international text, as literal characters without transformation.

## Configuration

Not applicable: the Code component accepts only a single `text` prop and has no configuration options.

## Deep Linking

Not applicable: the Code component is a static display element without associated navigation or state that would warrant a deep link.

## Localization

The `text` prop's content is caller-supplied; translating it is the content provider's responsibility, not this component's. The component does not set `dir` or `direction`, so in a right-to-left locale the `<pre>` inherits right-to-left directionality from its ancestor. That can mirror the block's alignment and reorder bidi-neutral characters within literal text such as shell commands or config fragments — the source does not force left-to-right layout for this content. See **rtl-layout-support** in Compliance.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable; the component does not animate |
| Increase Contrast | The component SHOULD respect the deck's increased-contrast theme if available, rendering text and background with higher contrast ratios. Under `forced-colors: active`, it SHOULD keep the `lp-hairline` border visible and defer to system colors (e.g. `CanvasText` / `Canvas`) rather than the theme's custom background and border tokens, which forced-colors mode overrides. |
| Differentiate Without Color | Not applicable; the component does not rely on color alone to convey information |

## Feature Flags

Not applicable: the Code component has no optional features or feature flags.

## Analytics

Not applicable: the Code component is a passive display element with no user interactions to track.

## Privacy

Not applicable: the Code component does not collect, store, or transmit any data beyond displaying the provided text.

## Logging

Not applicable: the Code component does not perform any operations that warrant logging.

## Platform Notes

- **React/Web**: Implemented as `<pre className="lp-code"><code>{text}</code></pre>`. The `lp-code` class applies the deck's `--lp-font-mono`, `--lp-card`, `--lp-hairline`, `--lp-radius`, and `--lp-ink` custom properties (each with a literal fallback) for font, background, border, corner radius, and text color. The component is a pure presentational component with no state or lifecycle.

- **SwiftUI**: Use `Text(text).font(.system(.body, design: .monospaced)).fixedSize(horizontal: true, vertical: false).textSelection(.enabled)` inside `ScrollView(.horizontal)`, within a container styled with the equivalent of the web `lp-code` tokens (padding, background, corner radius). `.fixedSize(horizontal: true, vertical: false)` is what actually stops wrapping; `.lineLimit(nil)` alone does not.

- **Compose**: Wrap the content in `SelectionContainer` and use `Text(text = text, fontFamily = FontFamily.Monospace, softWrap = false, modifier = Modifier.clip(RoundedCornerShape(8.dp)).background(codeBlockBackground).horizontalScroll(rememberScrollState()).padding(12.dp))`. `softWrap = false` disables wrapping (`Arrangement.Start` does not affect wrapping at all); applying `clip` before `background` keeps the background's corners rounded.

- **AppKit / UIKit**: On AppKit, host an `NSTextView` inside an `NSScrollView` with `hasHorizontalScroller = true`; set `isEditable = false`, `font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)`, and `textContainer.containerSize.width = .greatestFiniteMagnitude` to stop wrapping (`isRichText = false` alone does not). On UIKit, `UITextView` wraps by default, so place a non-wrapping `UILabel`, or a `UITextView` with `isScrollEnabled = false` and `isEditable = false`, inside a horizontal `UIScrollView`. Apply corner radius via the view's `layer.cornerRadius` (a layer property, not a `cornerRadius` view property) and background via `backgroundColor`.

- **WinUI 3**: Use `TextBlock` with `FontFamily="{ThemeResource CodeFontFamily}"` (a theme mono-font resource, not a hard-coded `"Consolas"` or `"Courier New"`), `TextWrapping="NoWrap"`, and `IsTextSelectionEnabled="True"`. Place it in a `ScrollViewer` with `HorizontalScrollBarVisibility="Auto"` for horizontal scrolling. Apply background color via the containing control (e.g., a `Grid` or `Border` with `Background`) and set `Foreground` from the theme.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/blocks/Code.tsx` | unverified |

## Design Decisions

**Decision**: The `text` prop is a plain `string` rather than `children` (`ReactNode`).
**Rationale**: Every other block in this package accepts `ReactNode` so a host can put emphasis or links inside it; here the whole point is that nothing is interpreted, and a `ReactNode` would invite a host to pass marked-up prose that would then render as code. A host that needs formatted content within code should use a separate component or structure.
**Approved**: pending

**Decision**: The component does not wrap text; it scrolls horizontally instead.
**Rationale**: Wrapping hides the real line boundaries, so readers mis-copy or misread multi-line input such as a wrapped shell invocation.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Statuses rest on the React source: `<pre className="lp-code"><code>{text}</code></pre>` correctly nests semantic markup and React's string rendering preserves the full Unicode range without transformation (passed); the `<pre>` carries no `tabIndex` for keyboard scrolling and no `dir`/`direction` override for right-to-left contexts (partial and failed, respectively); and `font-size`/color are theme tokens (`--lp-font-mono`, `--lp-ink`, `--lp-card`) whose resolved scaling and contrast ratio cannot be verified from this source alone (partial). `separation-of-concerns` passes because `Code.tsx` is a 20-line component with no logic beyond rendering its `text` prop into `<pre><code>`. `unit-test-coverage` fails because no test file exercises `Code` in the `landing` package.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Empty-block vector/edge case now describes true 0-height collapse (no min-height in source); Compliance added. |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; named the concrete `lp-code` CSS tokens in Appearance; reformatted Design Decisions into Decision/Rationale/Approved form; rebuilt Compliance with real, linked catalog checks; resolved the empty-string RFC 2119 contradiction and downgraded the unenforceable parent-heading and keyboard-focus MUSTs to SHOULD; split and added Conformance Test Vectors (code-006 to code-010); specified tab-size and documented the RTL/localization gap; corrected the SwiftUI, Compose, AppKit, UIKit, and WinUI 3 platform notes; and added forced-colors guidance to Accessibility Options |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation (drafted by Claude Haiku 4.5) |
