---
id: 840b5a7a-921a-4770-8dea-5ffbf9a2ee6c
title: Markdown Document Renderer
domain: adhsdk://recipes/markdown-document-renderer
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Renders complete markdown documents with GitHub alert callouts, task lists,
  and semantic coloring.
platforms:
- swift
- macos
- ios
tags:
- markdown
- document-rendering
- text-rendering
depends-on:
- adhsdk://recipes/markdown-renderer
related: []
references: []
approved-by: ''
approved-date: ''
---

# Markdown Document Renderer

## Overview

Renders a complete markdown document as an `NSAttributedString`. Distinguishes itself from fragment renderers by handling three document-specific concerns: frontmatter removal, GitHub-style alert blockquotes with semantic role-based coloring, and GitHub Flavored Markdown task list rendering with Unicode checkbox characters. The component accepts an optional code highlighter for syntax highlighting in fenced code blocks. Rendering also requires a semantic palette (used to resolve alert colors and other themed runs) and a base text color for ordinary text, both supplied by the caller — see Configuration.

## Behavioral Requirements

- **accept-markdown-string**: Component MUST accept a markdown string as input.
- **accept-semantic-palette**: Component MUST accept a `SemanticPalette` used to resolve the foreground color for each alert's role and for other themed runs.
- **accept-text-color**: Component MUST accept a base `PlatformColor` applied as the foreground color of non-alert rendered text.
- **remove-frontmatter**: Component MUST strip YAML frontmatter from the beginning of the document before rendering (content between leading `---` delimiter and closing `---`).
- **detect-alert-blockquotes**: Component MUST detect GitHub alert blockquotes formatted as `> [!TYPE]` where TYPE is one of: NOTE, TIP, IMPORTANT, WARNING, or CAUTION. Detection MUST occur on the source string before markdown parsing, not on the rendered output.
- **require-alert-tag-on-first-line**: Alert blockquotes MUST have the tag (`[!TYPE]`) alone on the first line of the quote block. Tags appearing on subsequent lines or in continuation quotes MUST NOT trigger alert styling.
- **color-alerts-by-role**: Detected alerts MUST be colored according to their mapped semantic role: NOTE→info, TIP→success, IMPORTANT→accent, WARNING→warning, CAUTION→danger.
- **preserve-alert-styling-across-blockquote**: Alert coloring MUST apply to the entire blockquote block, including all lines the blockquote contains, not just until the first blank line.
- **replace-alert-tag-with-label**: The `[!TYPE]` tag MUST be removed from the rendered output and replaced by the alert's uppercase label (NOTE, TIP, IMPORTANT, WARNING, CAUTION), inheriting the alert's color.
- **render-task-list-unchecked**: Unchecked task list items formatted as `- [ ]` in GFM MUST be rendered with a Unicode open checkbox character (U+2610, ☐).
- **render-task-list-checked**: Checked task list items formatted as `- [x]` or `- [X]` in GFM MUST be rendered with a Unicode ballot box with check character (U+2611, ☑).
- **collapse-task-list-bullet**: After rendering, the bullet/tab/checkbox sequence a task-list item inherits from ordinary list rendering (bullet, tab, checkbox, non-breaking space) MUST be collapsed to the checkbox followed by a plain tab, matching the layout of other list markers.
- **exclude-fenced-code-from-processing**: Lines within fenced code blocks MUST NOT be processed for alert detection, task list rewriting, or quote line hardening.
- **normalize-line-endings**: Line endings MUST be normalized to LF (U+000A) in the rendered output. CRLF line endings in source MUST be converted.
- **harden-blockquote-breaks**: A consecutive blockquote line MUST have a trailing two-space hard break appended so its line separation from the next blockquote line survives rendering, unless the line already ends in a hard break (a trailing backslash or two or more trailing spaces).
- **accept-optional-highlighter**: Component MUST accept an optional code highlighter instance for syntax highlighting in fenced code blocks and MUST NOT require one.
- **return-attributed-string**: Component MUST return an `NSAttributedString` with all formatting applied (colors, typography, emphasis).

## Appearance

Not applicable: This component is a text-rendering primitive that returns styled text; appearance is determined by the rendering host (view or text system) and the semantic palette passed at render time.

## States

Not applicable: The component is stateless. Rendering is a pure function of input markdown, palette, and text color.

## Accessibility

- **preserve-text-semantic-structure**: Component MUST preserve markdown semantic structure (headings, lists, emphasis) in the rendered output so assistive technologies can interpret document hierarchy.
- **map-alerts-to-color-and-label**: Alert blockquotes MUST be visually distinguished by both color (semantic role) and text label (NOTE, TIP, IMPORTANT, WARNING, CAUTION in uppercase; see **replace-alert-tag-with-label**). Color alone MUST NOT be the only distinguishing factor.
- **render-checkboxes-as-text**: Task list checkboxes MUST render as Unicode text characters (☐, ☑) so assistive technologies can announce them as text, not as interactive controls (task list items are not interactive in a static document).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mdr-001 | remove-frontmatter | `"---\ntitle: Test\n---\n# Heading"` | Rendered output text begins with "Heading"; no frontmatter delimiters or YAML content appear in the output. |
| mdr-002 | detect-alert-blockquotes | `"> [!NOTE]\n> This is a note"` | The literal `[!NOTE]` tag does not appear in the output; the blockquote's rendered range has `.foregroundColor` equal to `palette.platformColor(.info)`. |
| mdr-003 | color-alerts-by-role | `"> [!WARNING]\n> Danger"` | The blockquote's rendered range has `.foregroundColor` equal to `palette.platformColor(.warning)`. |
| mdr-004 | color-alerts-by-role | `"> [!TIP]\n> Good idea"` | The blockquote's rendered range has `.foregroundColor` equal to `palette.platformColor(.success)`. |
| mdr-005 | require-alert-tag-on-first-line | `"> Regular quote\n> [!NOTE]"` | No `.foregroundColor` alert styling is applied anywhere in the output; the literal text `[!NOTE]` appears unchanged. |
| mdr-006 | preserve-alert-styling-across-blockquote | `"> [!CAUTION]\n> Line 1\n> Line 2\n> Line 3"` | `.foregroundColor` equals `palette.platformColor(.danger)` across the full rendered range of all three lines, not just the first. |
| mdr-007 | render-task-list-unchecked | `"- [ ] Unchecked task"` | Rendered output text contains "☐" immediately before "Unchecked task". |
| mdr-008 | render-task-list-checked | `"- [x] Completed task"` | Rendered output text contains "☑" immediately before "Completed task" (lowercase `x`). |
| mdr-009 | render-task-list-checked | `"- [X] Completed task"` | Rendered output text contains "☑" immediately before "Completed task" (uppercase `X`). |
| mdr-010 | exclude-fenced-code-from-processing | `` "```\n> [!NOTE]\n```" `` | The rendered output contains the literal text `> [!NOTE]`; no `.foregroundColor` alert styling is applied. |
| mdr-011 | harden-blockquote-breaks | `"> Line 1\n> Line 2"` | Rendered output preserves "Line 1" and "Line 2" as two separate lines (a literal line break appears between them) — the effect of a two-space hard break inserted on the source's first line. |
| mdr-012 | normalize-line-endings | `"Heading\r\nParagraph"` (CRLF input) | Rendered output string contains no `\r` characters. |
| mdr-013 | accept-optional-highlighter | Component initialized without a highlighter | Rendering succeeds; fenced code block text carries no syntax-highlighting attributes. |
| mdr-014 | accept-optional-highlighter | Component initialized with a highlighter | Fenced code block text carries syntax-highlighting attributes contributed by the supplied highlighter. |
| mdr-015 | return-attributed-string | Any valid markdown input | Return value is an `NSAttributedString` whose string is non-empty and carries a `.font` attribute over some range. |
| mdr-016 | accept-markdown-string | Component invoked with `content: "Hello 世界"` | Call succeeds without a precondition or type-conversion failure; rendered output text contains "Hello 世界" unmodified aside from ordinary markdown conversion. |
| mdr-017 | accept-semantic-palette, accept-text-color | Component rendered with a given `palette` and `textColor` over `"Plain text"` | The rendered "Plain text" run has `.foregroundColor` equal to `textColor`. |
| mdr-018 | replace-alert-tag-with-label | `"> [!NOTE]\n> Body text"` | Rendered output text contains "NOTE" and does not contain the literal substring `[!NOTE]`. |
| mdr-019 | collapse-task-list-bullet | `"- [ ] Todo"` | Rendered output text contains "☐" followed by a tab character immediately before "Todo"; it does not contain a bullet character followed by "☐". |
| mdr-020 | remove-frontmatter | `"---\ntitle: Test\n# Heading"` (no closing `---`) | The leading `---` is not stripped as frontmatter (there is no matching closing `---`), but it is then parsed as ordinary markdown: the CommonMark parser reads the unclosed `---` line as a thematic break, so it renders as the divider-colored `thematicBreakRule` (not the literal text `"---"`), while `"title: Test"` and `"Heading"` remain as literal/rendered content. |
| mdr-021 | remove-frontmatter | `"# Heading\nNo frontmatter here"` (no leading `---`) | Rendered output text is unchanged in content from the input, aside from ordinary markdown-to-attributed-string conversion of the heading; nothing is stripped. |
| mdr-022 | require-alert-tag-on-first-line | `"> [!NOTE] extra text\n> more"` | No `.foregroundColor` alert styling is applied; rendered output text contains the literal `[!NOTE] extra text`. |
| mdr-023 | exclude-fenced-code-from-processing | `` "~~~\n> [!NOTE]\n~~~" `` | The rendered output contains the literal text `> [!NOTE]`; no `.foregroundColor` alert styling is applied. |
| mdr-024 | detect-alert-blockquotes, color-alerts-by-role | `"> [!NOTE]\n> First\n\n> [!WARNING]\n> Second"` | The first blockquote's range has `.foregroundColor` equal to `palette.platformColor(.info)`; the second's range has `.foregroundColor` equal to `palette.platformColor(.warning)`; the two colored ranges do not overlap. |
| mdr-025 | color-alerts-by-role | `"> [!NOTE]\n> > nested line"` | `.foregroundColor` equals `palette.platformColor(.info)` continuously across both the first line and the nested line, as one span. |
| mdr-026 | render-task-list-unchecked | `"Just text [ ] not a list item"` | Rendered output text contains the literal substring `[ ]` unchanged; it is not replaced with "☐". |
| mdr-027 | harden-blockquote-breaks | `"> Line 1  \n> Line 2"` (first line already ends with two trailing spaces) | Exactly one hard break separates "Line 1" and "Line 2" in the rendered output; no doubled break or extra blank line appears. |
| mdr-028 | accept-markdown-string, return-attributed-string | `""` (empty string) | Return value is an `NSAttributedString` whose string is empty (length 0). |

## Edge Cases

- **Null or empty input**: An empty string MUST render as an empty `NSAttributedString`. A nil input is not possible in Swift's type system; the API requires a non-nil String. See mdr-028.
- **No frontmatter**: A document with no leading `---` delimiter MUST render without modification to the content. See mdr-021.
- **Malformed frontmatter**: A leading `---` without a closing `---` on a subsequent line MUST NOT be stripped as frontmatter — it is left as the start of content — but that unclosed `---` line is then parsed as ordinary markdown, which the CommonMark parser reads as a thematic break: it renders as the divider-colored `thematicBreakRule`, not as a literal `"---"` line. See mdr-020.
- **Multiple alerts in one document**: Multiple distinct alert blockquotes MUST each be detected and colored independently. See mdr-024.
- **Nested blockquotes**: Detection strips every level of a line's `>` markers uniformly, so a line using more than one `>` (e.g., `> > nested`) is not distinguished from a single-level quote line for the purpose of finding an alert tag. The colored span for an alert is the block's outermost blockquote identity: a nested line is colored as part of the same continuous span as its enclosing top-level blockquote, never as a separate span. See mdr-025.
- **Task list outside list context**: A string matching the task list pattern outside a list item MUST NOT be rewritten (pattern matching is restricted to list item lines). See mdr-026.
- **Already hard-broken quote lines**: A quote line that already ends with `\` or two spaces MUST NOT have another hard break appended, to avoid doubling the break. See mdr-027.
- **Fenced code containing alert or task markers**: All content inside fenced code blocks (delimited by ` ``` ` or `~~~`) MUST be rendered as literal text; alert detection, task list rewriting, and quote hardening MUST NOT apply. See mdr-010, mdr-023.
- **Private-use sentinel collision**: The component uses private-use Unicode code points (U+E000, U+E001) as sentinels during rendering. Author-written content containing these code points is extremely unlikely, and the component does not detect or guard against it if it occurred — the sentinel is placed only after alert tags are confirmed and fenced content is excluded, but no check exists for a coincidental match already present in unrelated text. See **Design Decisions**.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| highlighter | CodeHighlighter? | nil | Optional syntax highlighter for code blocks. If provided, applied to code fences during rendering. |
| palette | SemanticPalette | required | Semantic palette resolved for alert roles and other themed runs; supplied by the caller at render time. |
| textColor | PlatformColor | required | Base foreground color applied to non-alert rendered text; supplied by the caller at render time. |

## Deep Linking

Not applicable: This component is a rendering primitive, not a document view or navigation target.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none) | — | Alert labels (NOTE, TIP, IMPORTANT, WARNING, CAUTION) are fixed English text derived from the alert type's case name, uppercased. See **Design Decisions** for why they are not localized. |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: This component is a text renderer, not an animation. No motion is produced. |
| Increase Contrast | Not applicable: Contrast is controlled by the `SemanticPalette` and host view's text styling, not by the component. |
| Differentiate Without Color | Component MUST use both color and text label for alerts, so differentiation is not color-only. Task list checkboxes (☐, ☑) are text, not color-coded. |

## Feature Flags

| Flag Key | Default | Description |
|----------|---------|-------------|
| (none) | — | No feature flags are defined for this component. |

## Analytics

Not applicable: This component is a text-rendering primitive with no user interaction or lifecycle events to track.

## Privacy

Not applicable: The component processes markdown text without collecting, storing, or transmitting any data beyond the rendered output.

## Logging

Subsystem: Component does not emit logs. Processing happens in the render synchronously; errors are not explicitly logged.

## Platform Notes

- **SwiftUI**: Convert the returned `NSAttributedString` with `AttributedString(attributedString)` and display it with `Text(AttributedString(attributedString))`. Any `.link` attribute on the string is preserved and renders as a tappable link inside the `Text`.
- **Compose**: Build the same pipeline over `buildAnnotatedString`: run the markdown transformations, then emit `SpanStyle` runs for emphasis and code, `ParagraphStyle` for headings and block quotes, and `LinkAnnotation.Url` for links. Alert blocks become a `Row` with a leading icon and a tinted `Surface`; task-list items render the ☐ / ☑ glyph as plain `Text` immediately before the item text — no `Checkbox` composable, matching the source's non-interactive glyph. Display with `Text(annotatedString)` inside a `SelectionContainer`.
- **React/Web**: Use a JavaScript markdown parser (remark or markdown-it) with plugins for GitHub alerts and task lists, rendering to DOM elements or a React tree; the alert palette maps to CSS custom properties on the alert container.
- **AppKit / UIKit**: Use `NSTextView` or `UITextView` with `attributedText` property set to the returned `NSAttributedString`. For macOS, set the text view's delegate to handle any selection or editing. For iOS, ensure the text view is not editable unless document editing is required (use `isEditable = false` for display-only documents). The reference Swift implementation performs alert detection and blockquote/task-list rewriting on the source string before parsing, using `FenceScanner.classify` for fence-aware line classification and the `MarkdownAlert` enum for tag-to-role/label mapping.
- **WinUI 3**: Run the same markdown transformations, then render into a read-only `RichTextBlock`: one `Paragraph` per block, `Run` / `Bold` / `Italic` / `Hyperlink` inlines, a monospace `Run` with `FontFamily="Consolas"` for code, and `Paragraph.Margin` for spacing. Alert blocks become a `Border` with `Background` bound to the semantic brushes (`SystemFillColorCautionBackgroundBrush`, `SystemFillColorAttentionBackgroundBrush`, `SystemFillColorSuccessBackgroundBrush`, `SystemFillColorCriticalBackgroundBrush`) holding an icon and a nested `RichTextBlock`; task-list items render the ☐ / ☑ glyph as a plain `Run` immediately before the item text — no `CheckBox` control, matching the source's non-interactive glyph. Use `RichEditBox` only when the document must be editable.

## Design Decisions

**Decision**: Alert detection runs on the source markdown string before parsing, using a fence-aware line classifier to skip fenced lines, rather than searching the rendered output for alert tags.
**Rationale**: Detecting alerts on the rendered string previously failed three ways: a fenced code block that merely documented `[!NOTE]` suppressed every real alert in the document, because the exclusion list keyed on tag text rather than on which lines were fenced; that list was computed once and drifted off its own ranges as the loop shortened the string on each rewrite; and the colored run was delimited by the first paragraph break, which is not a block boundary and painted parts of adjacent blocks such as tables. Running detection on the source, where fencing and quote-line boundaries are still known, eliminates all three failure modes.
**Approved**: pending

**Decision**: Each detected alert is marked in the source with a sentinel pair of private-use Unicode code points (U+E000 and U+E001) surrounding the alert's index, rather than being colored by searching for its label text.
**Rationale**: The sentinel survives the markdown parser as inert text, which lets the color pass locate the exact alert block precisely instead of inferring it from label text. Private-use code points make a collision with author-written content extremely unlikely (see the **Private-use sentinel collision** edge case), but the component does not detect or reject such a collision if one occurs.
**Approved**: pending

**Decision**: A trailing two-space hard break is appended to a blockquote line when the next line is also a blockquote line and the line does not already end in one, and this happens on the source string before parsing.
**Rationale**: The underlying parser renders a single newline inside a block as a soft line break, collapsing it to a space — a rendering choice within what CommonMark's soft-break rule leaves undefined — so an unmodified multi-line blockquote would run its lines together. A trailing two-space hard break is the CommonMark construct the parser instead honors as a literal line break, so inserting it before parsing preserves the original line structure. It is added only on the source, since the rendered string no longer has soft/hard break distinctions to fix.
**Approved**: pending

**Decision**: GFM task-list markers (`[ ]`, `[x]`, `[X]`) are rewritten to Unicode checkbox characters (☐, ☑) on the source string, rather than left for the renderer to interpret.
**Rationale**: The underlying markdown parser treats `[ ]`/`[x]` as literal text inside a list item and has no notion of a task list, so the substitution must happen before parsing for the checkbox glyphs to appear at all. The renderer then treats a rewritten item as an ordinary list item; see **collapse-task-list-bullet** for how the resulting bullet/tab/checkbox sequence is normalized to match other list markers.
**Approved**: pending

**Decision**: Alert labels (NOTE, TIP, IMPORTANT, WARNING, CAUTION) are emitted in English only and are not localized.
**Rationale**: The label is a fixed uppercase of the alert type's case name; no locale or theme parameter is threaded through rendering that a localized label could be resolved from. Localizing would require adding one.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best-practices |

Contrast and dynamic-type status are partial because the color and font applied to rendered text come from the caller-supplied `SemanticPalette`/`PlatformColor` and `platformFont`, which this component does not itself validate for WCAG AA contrast or type scaling; Unicode handling passes on the evidence of the private-use sentinel pair and non-breaking-space handling in `MarkdownDocumentRenderer.swift`; and the hardcoded English alert labels produced from the alert type's case name fail both string-externalization and no-hardcoded-strings. `separation-of-concerns` passes: `MarkdownDocumentRenderer` owns only frontmatter stripping and the alert/task-list markdown rewrites, delegating the actual CommonMark-to-`NSAttributedString` conversion to the composed `MarkdownRenderer`. `unit-test-coverage` passes: `MarkdownDocumentRendererTests.swift` exercises this type directly, beyond the vectors table's minimum.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from source code |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Platform Notes: replaced not-applicable bullets with Compose, web and WinUI 3 translation guidance |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case and updated every citation; added palette/text-color to Configuration with new acceptance requirements; added requirements for alert-tag-to-label replacement and task-list bullet collapse; fixed the checkbox-as-control contradiction in the Compose and WinUI 3 notes and added an Apple reference-implementation note to AppKit/UIKit; resolved the sentinel-collision and soft/hard-break wording contradictions; restructured Design Decisions into Decision/Rationale/Approved form and added a localization-debt decision; evaluated Compliance; split, tightened, and expanded Conformance Test Vectors for testability and coverage; linked markdown-renderer as a dependency |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Fixed mdr-020/Malformed-frontmatter edge case: unclosed leading --- is left unstripped but then parses as a CommonMark thematic break (renders thematicBreakRule), not as literal "---" text. |
