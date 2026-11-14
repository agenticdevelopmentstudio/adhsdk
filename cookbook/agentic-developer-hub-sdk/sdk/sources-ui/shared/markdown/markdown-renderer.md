---
id: 316aed50-a6cb-4ece-977c-8d6dacb2186b
title: "Markdown Renderer"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Converts markdown content to formatted output with syntax-highlighted code blocks and semantic palette theming."
platforms:
  - typescript
  - web
  - swift
  - macos
  - ios
tags:
  - markdown
  - text-rendering
  - syntax-highlighting
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Markdown Renderer

## Overview

The Markdown Renderer converts raw markdown strings to formatted output suitable for display. On Apple platforms, it produces `NSAttributedString` with semantic palette styling; on web platforms, it produces sanitized HTML with theme-aware CSS variables. Both implementations support CommonMark plus the GFM extensions this component relies on (tables, strikethrough) — see **render-markdown** — including headers, lists, blockquotes, code blocks with optional syntax highlighting, and inline formatting.

Constructs outside that core surface are handled per platform rather than uniformly:

- **Images**: (Apple) `AttributedString(markdown:)` has no image presentation intent, so image syntax is not rendered as an embedded image. (Web) standard CommonMark images render as sanitized `<img>` elements (`src`/`srcSet`/`alt`/`width`/`height` are in the sanitize allowlist).
- **Raw HTML**: (Apple) not part of the grammar `AttributedString(markdown:)` consumes, so it surfaces as literal text. (Web) dropped before the sanitizer — `remark-rehype` runs with `allowDangerousHtml: false`, so embedded raw HTML/script never reaches `rehype-sanitize` or the output.
- **Hard line breaks**: (Apple) not modeled as a distinct block or run intent, so a hard break's whitespace stays literal text within its paragraph. (Web) rendered as `<br>`, which the sanitize schema allows.
- **Autolinks**: both platforms render them as ordinary links — Apple via `run.link`, Web via `<a>` — but only Web restricts the destination to a protocol allowlist (`http`, `https`, `mailto`, `tel`), enforced by `rehype-sanitize`'s `protocols.href` schema; Apple has no equivalent scheme check anywhere in `MarkdownRenderer`, so `AttributedString(markdown:)` copies whatever scheme the source contains — including `javascript:`, `file:`, or an arbitrary custom scheme — verbatim into the `.link` attribute for both autolinks and bracketed links.

Parsing is resilient on Apple: partial markdown renders as far as parsing succeeds rather than failing entirely (see **parse-resilient**). On web, a *pipeline* failure instead surfaces as an explicit error pane rather than degraded output (see **emit-error-pane**). Code block syntax highlighting is optional: Apple accepts a `CodeHighlighter` injected by the host application, while web hard-wires Shiki internally with no injection point exposed — see the highlighter Design Decision below.

## Behavioral Requirements

- **render-markdown**: MUST parse and render valid CommonMark + GFM markdown (tables, strikethrough) including headers (levels 1–6), unordered and ordered lists, blockquotes, thematic breaks, code blocks, and inline formatting (bold, italic, strikethrough, code spans, links, autolinks). Images, raw HTML, and hard line breaks are outside this core surface — see Overview for how each is handled per platform.
- **parse-resilient**: (Apple) MUST render partial markdown when `AttributedString(markdown:)` encounters syntax errors or incomplete input (`failurePolicy: .returnPartiallyParsedIfPossible`); degradation MUST be to plaintext, never to empty output or loss of readable content. (Web) a markdown *syntax* irregularity does not fail outright — `remark-parse` does not throw on malformed markdown — but a *pipeline* failure from another stage (e.g. the Shiki highlighter) is not degraded to partial output; it surfaces as the error pane instead. See **emit-error-pane**.
- **support-extended-attributes**: (Apple) MUST enable Foundation's markdown extended-attribute syntax (`allowsExtendedAttributes: true` in `AttributedString.MarkdownParsingOptions`) so inline attribute runs (e.g. `^[text]` `(key: "value")`) parse successfully instead of falling back to plaintext. The renderer does not read or apply the parsed attribute values itself — enabling the option only keeps the syntax from breaking parsing. No web equivalent: the remark/rehype pipeline has no analogous extended-attribute syntax.
- **respect-code-language**: MUST preserve the language hint from fenced code blocks and provide it to the syntax highlighter (Apple: `CodeHighlighter.highlight(_:language:palette:)`; Web: Shiki's per-block language via `@shikijs/rehype`, falling back to plain-text tokenization for an unrecognized language, `fallbackLanguage: 'text'`).
- **apply-palette-styling**: MUST apply semantic palette styling including font roles (title, heading, body, code), color roles (text, secondaryText, accent, divider, controlBackground), and paragraph indentation for nested structures. (Apple) indentation is computed as `(listDepth + quoteDepth) × MarkdownBlockMetrics.indentStep`. (Web) nested indentation relies on the browser's default `<ul>`/`<ol>`/`<blockquote>` nesting via CSS, not a component-computed indent value.
- **preserve-block-boundaries**: MUST report or track block boundaries with correct separation: blank line between top-level blocks, single newline between list items or table rows within the same structure. (Apple) tabs separate cells within the same table row, via `NSTextTab` stops. (Web) table rows and cells are structural `<tr>`/`<td>` elements; there is no tab-character separator to preserve.
- **quote-identity**: MUST preserve the identity and nesting of blockquotes so that color styling can be applied to entire quote regions without leaking into adjacent quotes. (Apple) identity comes from the outermost `.blockQuote` `PresentationIntent` component's identity. (Web) each `<blockquote>` element is already its own DOM node, so there is no equivalent identity-tracking model to implement.
- **table-identity**: MUST preserve table identity across row sequences so that row indices do not collide when two tables are adjacent. (Apple) identity comes from the enclosing `.table` intent's identity. (Web) each `<table>` element is already its own DOM node.
- **handle-missing-highlighter**: (Apple) MUST fall back to unstyled monospaced code when the injected `CodeHighlighter` is absent or returns nil. (Web) there is no "missing highlighter" state — Shiki is always initialized internally; the closest equivalent is an unrecognized fenced-code language, which Shiki tokenizes as plain text (`fallbackLanguage: 'text'`) rather than fully unstyled code. A highlighter/pipeline failure is instead a full pipeline failure — see **emit-error-pane**.
- **handle-trailing-newline**: (Apple) MUST remove a fenced code block's trailing newline before rendering, to prevent a double blank line before the next block (`renderCodeBlock`'s `raw.hasSuffix("\n")` trim). Web's rehype/shiki pipeline does not carry this trailing-newline artifact, so there is no equivalent trim.
- **embed-inline-styles**: (Apple) MUST apply inline formatting (bold, italic, strikethrough, underline for links, color for inline code and links) as attributes embedded directly on each `NSAttributedString` run, without a separate `NSAttributedString.Key`-indexed style dictionary or stylesheet object. (Web) the equivalent is emitting semantic inline elements (`<strong>`, `<em>`, `<del>`, `<a>`, `<code>`); styling is driven by the package's theme CSS classes, not inline `style` attributes, except the Shiki-generated CSS variables scoped to code blocks.
- **sanitize-html**: (Web) MUST pass rendered HTML through `rehype-sanitize` (allowlist schema) before output; `remark-rehype`'s `allowDangerousHtml: false` additionally drops embedded raw HTML before it can ever reach the sanitizer.
- **mark-loading-state**: (Web) SHOULD indicate rendering phase with an accessible loading indicator (`aria-busy="true"`, `aria-live="polite"`).
- **emit-error-pane**: (Web) SHOULD render an error pane (`role="alert"`) on pipeline failure rather than injecting unsanitized or partial HTML.

## Appearance

- **Font styling**:
  - Headers: title font (level 1, bold), heading font (level 2, bold), heading font (level 3), body font with bold (levels 4–6)
  - Body text: semantic body font
  - Code spans and code blocks: semantic code font (monospaced)
  - Table headers: semantic body font with bold
- **Colors**:
  - Primary text: supplied textColor parameter or theme primary text
  - Blockquote text: secondary text color
  - Code block background: controlBackground color
  - Link text: accent color with underline
  - Thematic break rule: divider color
- **Spacing**:
  - List indentation: one indent step per nesting level (e.g., `MarkdownBlockMetrics.indentStep`)
  - Blockquote indentation: one indent step per nesting level
  - Table columns: (Apple) a fixed number of evenly spaced tab stops (`MarkdownBlockMetrics.tableColumnCount`, `MarkdownBlockMetrics.tableColumnWidth` per column) applies to every table regardless of its actual column count — a table with more columns than the constant does not receive tab stops beyond it. (Web) column count and width come from each table's own `<td>`/`<th>` structure, styled by CSS, not a fixed constant.
  - Paragraph indentation: applied via `NSParagraphStyle` (headIndent, firstLineHeadIndent) or CSS margin/padding
  - Tab stops for list markers: one indent step beyond list indentation for text alignment
- **Min/Max size**: No intrinsic minimum or maximum; renders to the width of its container.

## States

| State | Appearance change |
|-------|------------------|
| Default | Content rendered with full styling |
| Rendering | (Web) Subtle inline "Rendering…" indicator |
| Error | (Web) Centered error pane with explanation |
| Highlighted code block | Code block uses syntax highlighter output if available; monospaced fallback otherwise |
| Unhighlighted code block | Code block rendered in monospaced code font with controlBackground |

## Accessibility

- **Role/trait**: (Apple) headers are rendered with distinct display fonts per level (title/heading/body-bold, see Appearance) via `PresentationIntent.header(level:)`, but this conveys the role visually only — no separate accessibility heading-level trait is attached to the `NSAttributedString`; exposure to VoiceOver depends on the surrounding `Text`/`NSTextView` wrapper, not this component. Links carry link role via `NSAttributedString.Key.link`. (Web) headers render as real `<h1>`–`<h6>` elements, which expose accessible heading levels natively; links render as `<a href>`.
- **Label requirements**: Headings MUST be emitted with their semantic level (Apple: `presentationIntent` header level driving `headerFont(level:)`; Web: real `<h1>`–`<h6>` tags) to preserve document structure for screen readers. Links MUST retain their `href`. (Web) Images MUST retain their `alt` text. (Apple) images are not rendered as embedded content by this component (see Overview), so no alt-text requirement applies to it.
- **Announce state changes**: (Web) Loading state MUST be announced via `aria-live="polite"` and `aria-busy="true"`. Error state MUST use `role="alert"`.
- **Contrast**: Links rendered in text MUST meet minimum contrast (WCAG AA, 4.5:1) via palette/theme colors; no additional tap-target requirement applies since inline links carry no click-target sizing independent of the surrounding text.
- **Keyboard navigation**: (Web) Links MUST be keyboard-navigable via Tab and Enter (native `<a>` behavior). Tables carry no focusable content — GFM task-list checkboxes render as `disabled` `<input>` elements — so no keyboard tab order applies to them; screen readers read table cells in source (DOM) order, left-to-right within each row.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| markdown-renderer-001 | render-markdown | `"# Heading 1\n## Heading 2"` | Output with semantic heading styles (Apple: title font for h1, heading font for h2; Web: `<h1>`/`<h2>`) |
| markdown-renderer-002 | render-markdown | `"- Item 1\n- Item 2\n  - Nested"` | Unordered list with bullet markers, indented nesting, newline between items (Apple: tab-stop bullets with headIndent; Web: nested `<ul><li>`) |
| markdown-renderer-003 | render-markdown | `"1. First\n2. Second"` | Ordered list with numeric markers (1., 2.), newline between items (Apple: `"1.\t"` marker; Web: `<ol><li>`) |
| markdown-renderer-004 | render-markdown, quote-identity | `"> Quote\n> More"` | Blockquote text in secondaryText color, indented, single quote identity for the entire block (Apple: one `quoteIdentity` shared by both lines; Web: one `<blockquote>`) |
| markdown-renderer-005 | render-markdown | `"---"` | Thematic break rendered as divider-colored rule string (Apple) or `<hr>` (Web) |
| markdown-renderer-006 | render-markdown, respect-code-language | `` "```swift\nprint(\"hi\")\n```" `` | Code block in code font with controlBackground (Apple) or a Shiki-highlighted `<pre><code>` (Web); language hint "swift" provided to the highlighter in both cases |
| markdown-renderer-007 | render-markdown | `"**bold**"` | Bold applied via font weight (Apple: `applying(bold: true)`; Web: `<strong>`) |
| markdown-renderer-008 | render-markdown | `"*italic*"` | Italic applied via font style (Apple: `applying(italic: true)`; Web: `<em>`) |
| markdown-renderer-009 | render-markdown | `"~~strike~~"` | Strikethrough applied (Apple: `.strikethroughStyle` = `NSUnderlineStyle.single.rawValue`; Web: GFM strikethrough renders as `<del>`, which is in the sanitize tag allowlist) |
| markdown-renderer-010 | render-markdown | `` "`code`" `` | Inline code in code font with controlBackground (Apple); Web renders an inline `<code>` element (visual styling comes from the package's theme CSS, not verified from these sources) |
| markdown-renderer-011 | render-markdown | `"[link]` `(http://example.com)"` | Link in accent color with underline and `NSAttributedString.Key.link` (Apple); Web renders `<a href="http://example.com">`, `http` allowed by the sanitize protocol allowlist |
| markdown-renderer-012 | render-markdown, preserve-block-boundaries, table-identity | `"\| a \| b \|\n\|---\|---\|\n\| c \| d \|"` | Table with header row (bold), body rows (Apple: cells separated by tabs, rows separated by newlines, single `tableIdentity`; Web: `<table><thead><tr><th>`/`<tbody><tr><td>`) |
| markdown-renderer-013 | parse-resilient | `"# Heading\nIncomplete **bold"` | Heading rendered with title font; `Incomplete **bold` renders as plain body-font text with the literal `**` characters intact — the unterminated strong-emphasis run never closes, so no bold styling is applied and no characters are dropped |
| markdown-renderer-014 | support-extended-attributes | (Apple) `^[Attributed]` immediately followed by `(customKey: "value")` (one string, no space) | Parses successfully via `allowsExtendedAttributes: true` (no fallback to plaintext); rendered text is "Attributed" — the `customKey` value is not applied to `.font`/`.foregroundColor` because the renderer does not read arbitrary attribute keys |
| markdown-renderer-015 | handle-missing-highlighter | (Apple) `` "```js\nvar x = 1\n```" `` (no highlighter injected) | Code block rendered in monospaced font with controlBackground, no syntax colors |
| markdown-renderer-016 | handle-trailing-newline | (Apple) `` "```\ncode\n```" `` | Code output with trailing newline removed, no double blank line before the next block |
| markdown-renderer-017 | apply-palette-styling | `"- Level 1\n  - Level 2\n    - Level 3"` | (Apple) Each nested item's `NSParagraphStyle.headIndent` increases by one `MarkdownBlockMetrics.indentStep` per level; three levels produce three distinct indent values. (Web equivalent not verifiable from these sources — indentation is CSS-driven list nesting.) |
| markdown-renderer-018 | embed-inline-styles | `"[**bold link**]` `(http://example.com)"` | (Apple) The run's attributes dictionary carries `.font` (bold), `.foregroundColor` (accent), `.underlineStyle`, and `.link` together on one run — no separate style-dictionary object is referenced. (Web) Renders as nested `<a href="http://example.com"><strong>bold link</strong></a>` — inline formatting is expressed as semantic nested elements, not inline `style` attributes |
| markdown-renderer-019 | sanitize-html | (Web) Raw markdown with `<script>` tag | Output HTML with the script tag removed (dropped by `remark-rehype`'s `allowDangerousHtml: false` before it can reach `rehype-sanitize`), never executed |
| markdown-renderer-020 | mark-loading-state | (Web) Initial render | Loading state with `aria-busy="true"` and `aria-live="polite"` |
| markdown-renderer-021 | emit-error-pane | (Web) Pipeline failure (e.g. the shared Shiki highlighter fails to initialize) | Error pane rendered via React (not `dangerouslySetInnerHTML`), `role="alert"` applied. An unrecognized fenced-code language does NOT trigger this — it falls back to plain-text tokenization (`fallbackLanguage: 'text'`); see **handle-missing-highlighter** |
| markdown-renderer-022 | render-markdown | `""` | (Apple) `AttributedString(markdown: "")` succeeds; output `NSAttributedString` has zero length. (Web) `matter("")` yields empty content; the processed `html` is an empty string, with no error |
| markdown-renderer-023 | apply-palette-styling | (Apple) Unordered list nested 12 levels deep | Renders without crash or truncation; `headIndent` grows linearly (12 × `indentStep`) — `BlockShape.listDepth` has no maximum enforced by the shape-computation loop |
| markdown-renderer-024 | sanitize-html | (Web) `"---\ntitle: Test\n---\n# Heading"` | Rendered `html` begins with `<h1 ...>Heading</h1>`; no `---` delimiter or YAML content appears anywhere in `html` — `gray-matter` strips the frontmatter block before the unified pipeline ever sees it |
| markdown-renderer-025 | quote-identity | `"> Quote 1\n\n> Quote 2"` | Two separate blockquote regions in the output, separated by a blank line; each carries a distinct `quoteIdentity` in its `RenderedBlock` (Apple) so color styling applied to one cannot bleed into the other |
| markdown-renderer-026 | table-identity | `"\| a \|\n\|---\|\n\| b \|\n\n\| c \|\n\|---\|\n\| d \|"` | Two adjacent one-column tables are not joined: the second table's header row is separated from the first table's body row by a blank line, because `tableIdentity` differs between them even though both rows have `tableRow != nil` |
| markdown-renderer-027 | render-markdown | `"#"` | Both platforms treat a lone `#` as a valid, empty level-1 ATX heading per CommonMark — not as literal text |
| markdown-renderer-028 | render-markdown | Two concurrent render calls with different content for the same component instance | (Apple) Each call to `render(_:palette:textColor:)` returns an independent `NSAttributedString` computed purely from its own arguments; no shared mutable state is read or written. (Web) if `content` changes again before the first `processMarkdown` call resolves, the effect's `cancelled` flag suppresses the stale result, so only the latest content's output reaches `setRender` |

## Edge Cases

- **Null or empty input**: Empty string MUST render as empty output — see markdown-renderer-022. Null input (if applicable per language) MUST be treated as empty string or raise a caught error.
- **Boundary values**: Deeply nested structures (10+ levels of list or blockquote nesting) MUST render with proper indentation — see markdown-renderer-023. Single-character markdown (e.g., `"#"`) is valid CommonMark (an empty heading), not incomplete input — see markdown-renderer-027.
- **Concurrent access**: Components are immutable/stateless — Apple: a `Sendable` struct with no mutable stored state; Web: a function component whose only state (`useState`) is local to one render cycle, not shared across calls. Multiple concurrent render calls with different content MUST NOT interfere — see markdown-renderer-028.
- **Error states**: Parser that encounters syntax errors MUST degrade to plaintext, not crash or omit content (Apple; see **parse-resilient**). Highlighter that returns nil MUST fall back to unstyled monospaced code (Apple; see **handle-missing-highlighter**). (Web) Pipeline failure MUST display the error pane (see **emit-error-pane**), not expose raw or partial HTML — this is the observable failure signal described in Logging, not a console log.
- **Offline or disconnected state**: (Web) If the shared Shiki highlighter fails to initialize or a highlight pass throws, the whole `processMarkdown` call rejects and the component renders the error pane (see **emit-error-pane**) — not a partial or unstyled document. An unrecognized code-fence language is a *separate, smaller* case: it degrades to plain-text tokenization for that one block (`fallbackLanguage: 'text'`), not a pipeline failure. No network retry is required in either case.
- **Adjacent blockquotes**: Two adjacent blockquote blocks MUST carry distinct identities so color styling does not bleed between them — see markdown-renderer-025.
- **Adjacent tables**: Two consecutive tables with different row counts MUST NOT be joined into one; table identity preserves the boundary — see markdown-renderer-026.
- **Frontmatter**: (Web) Raw markdown may include YAML frontmatter; it MUST be stripped before processing — see markdown-renderer-024.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `highlighter` | `(CodeHighlighter)?` / `undefined` | `nil` / not provided | (Apple) Optional injected syntax highlighter for fenced code blocks. If nil, code blocks render in unstyled monospaced font. (Web) Shiki highlighter is hard-wired internally; no configuration exposed. |
| `palette` | `SemanticPalette` | Required | (Apple) Semantic color and font palette providing platform-appropriate styling. |
| `textColor` | `PlatformColor` | Required | (Apple) Base text color for the rendered output. |
| `content` | `string` | Required | (Web) Raw markdown string (frontmatter stripped by component). |

## Deep Linking

Not applicable: Markdown Renderer is a content-display component, not a navigation target. Individual document sections (headers) may support deep linking at the container level.

## Localization

Not applicable: Markdown Renderer renders user-supplied content; localization is the responsibility of the content source, not the renderer.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Code highlighting and rendering do not use animation; no change required. |
| Increase Contrast | (Web) CSS variables supplied by theme should honor contrast requirements; renderer uses them as-is. (Apple) SemanticPalette colors should meet contrast requirements; renderer applies them as supplied. |
| Differentiate Without Color | Links and code are differentiated by underline (links) and background (code) in addition to color. Blockquotes use indentation in addition to color. |

## Feature Flags

Not applicable: Markdown Renderer has no feature-flag-gated behavior.

## Analytics

Not applicable: Markdown Renderer is a stateless rendering component; analytics is the responsibility of the container that invokes it.

## Privacy

Not applicable: Markdown Renderer processes content supplied by the container and produces display output. No data is collected, transmitted, or retained.

## Logging

Not applicable: Markdown Renderer does not emit console/debug logging by design. (Apple) Parse failures and highlighter failures degrade silently to a plaintext or monospaced-fallback output — see **parse-resilient** and **handle-missing-highlighter**; the `render` function never throws. (Web) a pipeline failure is not logged either, but it IS surfaced as an observable failure signal: the component transitions to its error render state and displays an accessible error pane (`role="alert"`) instead of silently degrading — see **emit-error-pane**. Debug output, if needed, is the responsibility of the injected highlighter or calling code.

## Platform Notes

- **SwiftUI**: Wrap `NSAttributedString` output in `Text(AttributedString(nsAttributedString))` or use a custom `NSAttributedString` view wrapper. The struct is `Sendable` for use in `@Observable` or async contexts. Palette and textColor are passed as parameters; no direct SwiftUI view styling is needed.
- **Compose**: Build a composable that accepts the markdown string plus a palette parameter (mirroring `palette`/`textColor`), walks the same block/run structure, and maps it to a Jetpack Compose `Text` with `AnnotatedString`. Use `SpanStyle` for bold, italic, strikethrough, code spans, and links, and `ParagraphStyle` for list and blockquote indentation per nesting level. Material `ColorScheme` roles substitute for `SemanticPalette` colors (e.g. `onSurface`/`onSurfaceVariant`/`surfaceVariant` for primary text, blockquote text, and code block background). Fenced code blocks render in `FontFamily.Monospace`, using an injected highlighter's styled spans when available and falling back to unstyled monospaced text otherwise, matching the source's fallback behavior.
- **React/Web**: Use the `MarkdownRenderer` component exported from the package. Pass raw markdown as the `content` prop. Rendering is async; initial state shows "Rendering…" with appropriate ARIA attributes. On error, an error pane is displayed. CSS variables are emitted by the processor for theme switching without re-render.
- **AppKit / UIKit**: Call `MarkdownRenderer.render(_:palette:textColor:)` to produce `NSAttributedString`, then display via `NSTextView` (macOS) or `UITextView` (iOS). Optionally inject a `CodeHighlighter` for syntax highlighting. The method is thread-safe (Swift concurrency `Sendable`).
- **WinUI 3**: Use `RichTextBlock` with `Paragraph` blocks and `Run`/`Bold`/`Italic`/`Hyperlink` inlines, or drive the same output from a Markdown-to-XAML mapping that walks the renderer's block/run structure. `Run.Foreground` and `TextElement.FontFamily`/`FontWeight` carry the palette's text, heading, and code colors and fonts; `Paragraph.Margin` carries list and blockquote indentation per nesting level; `Hyperlink.Foreground` plus its default underline carry link styling. Fenced code blocks render inside a `Paragraph` with a monospaced `Run` and a `Border` background for `controlBackground`, with syntax highlighting delegated to a highlighting service analogous to Apple's `CodeHighlighter` protocol and falling back to unstyled monospaced text when no highlighter is supplied.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/Shared/Markdown/MarkdownRenderer.swift` | unverified |
| web | `packages/web/packages/markdown/src/components/MarkdownRenderer.tsx` | unverified |

## Design Decisions

**Decision**: The Apple parser uses `failurePolicy: .returnPartiallyParsedIfPossible` to degrade incomplete or malformed markdown to plaintext, and a parse failure there is never fatal.
**Rationale**: This ensures that streaming edits and user input errors do not result in empty or corrupted output on Apple platforms. Web's `remark-parse` also does not throw on malformed markdown syntax, but a *pipeline* failure (e.g. Shiki) is deliberately not degraded on web — it surfaces as the error pane instead (see **emit-error-pane**), which is the intended web behavior, not an inconsistency with this Apple-only decision.
**Approved**: pending

**Decision**: Blockquote and table identities are tracked separately (via `PresentationIntent` component identity) to allow per-block styling (e.g. coloring an entire blockquote) without ambiguity when structures are adjacent.
**Rationale**: This is essential for correct rendering of complex nested and adjacent structures — see **quote-identity** and **table-identity**.
**Approved**: pending

**Decision**: Apple accepts syntax highlighting as an optional `CodeHighlighter` protocol supplied by the host application; web hard-wires Shiki internally with no injection point exposed.
**Rationale**: Apple avoids shipping a large grammar stack in a framework customers embed, and lets the host provide custom highlighting behavior. Web instead standardizes on Shiki so every consumer gets the same highlighting and dual-theme CSS variables without per-app wiring; the trade-off is that a web host cannot substitute its own highlighter.
**Approved**: pending

**Decision**: Apple produces `NSAttributedString` (native to UIKit/AppKit rendering); web produces HTML (native to DOM rendering).
**Rationale**: Both apply semantic palette styling, but the output format is optimized for the platform's native rendering pipeline.
**Approved**: pending

**Decision**: HTML output is always passed through `rehype-sanitize` (allowlist schema) before injection into the DOM, and `remark-rehype` never emits raw/dangerous HTML for it to sanitize around.
**Rationale**: The component never exposes unsanitized HTML to `dangerouslySetInnerHTML` — see **sanitize-html**.
**Approved**: pending

**Decision**: Headers level 1–2 use display roles (title and heading) from the palette; level 3 uses the heading role at its default weight; levels 4–6 use body font with bold weight.
**Rationale**: The palette has no smaller heading role, and inventing one would diverge from the toolkit's type scale.
**Approved**: pending

**Decision**: Code highlighting colors are emitted as CSS variables, allowing the reading theme to repaint via CSS without re-processing the markdown.
**Rationale**: This eliminates flashing or a "Rendering…" state on theme change.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best-practices |

Security and semantic-markup statuses rest on `process-markdown.ts`'s `rehype-sanitize` allowlist plus `remark-rehype`'s `allowDangerousHtml: false`, and on `MarkdownRenderer.tsx`'s `aria-busy`/`aria-live`/`role="alert"` markup together with real `<a>`/`<h1>`–`<h6>` elements; keyboard-navigable rests on those same native elements. Contrast is `partial` because the renderer applies palette/theme colors as supplied without independently verifying they meet WCAG AA. Unicode support is `passed` because neither the `AttributedString` parser nor the `unified`/`remark`/`rehype` pipeline restricts or transcodes the character set of the text they process. `separation-of-concerns` passes: the Apple `MarkdownRenderer` only walks parsed block/run structure into `NSAttributedString`, delegating syntax highlighting to an injected `CodeHighlighter`; the web pipeline's parsing (`remark-parse`/`remark-gfm`), sanitization (`rehype-sanitize`), and highlighting (Shiki) are separate composed stages in `process-markdown.ts`. `unit-test-coverage` passes: `MarkdownRendererTests.swift` (Apple) and `process-markdown.test.ts` (web) each exercise this component's rendering pipeline directly.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Fixed Autolinks overview line: only Web restricts href scheme via rehype-sanitize; Apple has no protocol allowlist and copies run.link verbatim (javascript:/file:/custom schemes render live). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename all requirements to subject-only kebab-case and update every citation; tag Apple-only/Web-only behavior throughout (extended attributes, tab-separated cells, inline-style embedding, NSStrikethroughStyle) with the other platform's equivalent; reconcile the highlighter-failure and silent-logging contradictions with the web error pane; reformat Design Decisions to Decision/Rationale/Approved; add a Compliance table; document how images, raw HTML, hard breaks and autolinks are handled; expand Conformance Test Vectors to cover every requirement and edge case, splitting the folded inline-formatting vector |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Replace review markers on the Compose and WinUI 3 Platform Notes bullets with concrete translation guidance |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
