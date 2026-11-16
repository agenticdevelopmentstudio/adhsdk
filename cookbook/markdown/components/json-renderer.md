---
id: b32270be-49b8-4227-9e30-1d8e781ab3b5
title: "JSON Renderer"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-14
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Pretty-prints JSON or JSON Lines as a highlighted code block, or shows invalid text as written under a note."
platforms:
  - typescript
  - web
tags:
  - markdown
  - prose
  - content-rendering
depends-on: []
related:
  - 2d18fdbd-b2c5-46c0-8e6f-ceb7467fafa6
references:
  - https://shiki.style
approved-by: ""
approved-date: ""
---

# JSON Renderer

## Overview

A client React component that shows a stored JSON document, or a JSON Lines file, laid out for reading: two-space indents, one record after another, in the same code-block styling as a fenced json block rendered by `MarkdownRenderer`. Text that is neither JSON nor JSON Lines is shown exactly as written under a one-line note saying so, never silently reformatted. Documents larger than 512 KiB of characters skip syntax colouring so the page does not stall. Use it for a tool pane or file viewer that holds raw JSON text, such as an agent trajectory.

## Behavioral Requirements

- **client-component**: The component MUST be a client component (the source opens with the `use client` directive).
- **accept-content**: The component MUST take the raw JSON or JSON Lines text, as stored, in a required `content` string prop.
- **accept-wrap**: The component MUST accept an optional boolean `wrap` prop that defaults to `false`.
- **pretty-print-document**: When `content`, trimmed of surrounding whitespace, parses as a single JSON document, the component MUST show it re-serialised with two-space indents.
- **pretty-print-lines**: When `content` is not a single JSON document but has at least two non-blank lines that each parse as JSON, the component MUST show each record pretty-printed with two-space indents, the records joined by a single newline in their original order.
- **skip-blank-lines**: In the JSON Lines case the component MUST ignore lines that are empty or whitespace-only.
- **single-line-not-lines**: A single non-blank line that fails to parse as a document MUST NOT be treated as JSON Lines; it is invalid text.
- **invalid-shown-as-written**: When `content` is neither a JSON document nor JSON Lines (including when it is empty or whitespace-only, or when any one non-blank line of a multi-line text fails to parse), the component MUST show `content` unmodified, not trimmed and not re-indented.
- **invalid-note**: In the invalid case the component MUST show the one-line note "Not valid JSON — shown as written." before the content.
- **valid-no-note**: In the valid case the component MUST NOT show the invalid-text note.
- **same-block-styling**: Below the size limit the component MUST render through `MarkdownRenderer`, by wrapping the body in a Markdown code fence, so the block carries the same styling and syntax colours as a fenced code block in a Markdown document.
- **fence-language**: Valid JSON MUST be fenced with the language `json`; invalid text MUST be fenced with no language, so it is not highlighted as JSON.
- **fence-longer-than-body**: The fence MUST use more backticks than the longest backtick run inside the body, and never fewer than three, so a body that contains backticks cannot close the fence early.
- **forward-wrap**: Below the size limit the component MUST pass `wrap` to `MarkdownRenderer`.
- **highlight-limit**: The component MUST treat a body longer than `JSON_HIGHLIGHT_LIMIT` (524288 characters, `512 * 1024`, counted as `String.length` UTF-16 code units) as too large to colour. The limit is exported as a constant.
- **limit-boundary**: A body of exactly `JSON_HIGHLIGHT_LIMIT` characters MUST still be rendered through `MarkdownRenderer` with colours; only a body strictly longer takes the plain path.
- **limit-measures-body**: The size test MUST measure the text that would be displayed (the pretty-printed text when valid, `content` when not), not the raw input length.
- **plain-path-markup**: Above the limit the component MUST render the body, unaltered, inside a `pre` element with class `shiki` containing a `code` element, within a root `div` carrying the prose class list.
- **plain-path-wrap**: Above the limit the component MUST apply the `adh-mv-prose--wrap` modifier to the root when `wrap` is true.
- **plain-path-note**: Above the limit, when the body is invalid, the component MUST show the note as a paragraph with class `adh-mv-json-note` before the `pre` element.
- **plain-path-no-processing**: Above the limit the component MUST NOT invoke the Markdown pipeline.
- **memoise-pretty**: The component SHOULD recompute the pretty-printed text only when `content` changes (see Design Decisions).
- **inherit-markdown-errors**: Below the limit, the component MUST NOT add its own handling of a Markdown pipeline failure; the rendering, error and "Rendering…" states are those of `MarkdownRenderer`.
- **default-measure**: The component MUST NOT accept a prose-measure prop; the width is the default `reading` measure on both paths.

## Appearance

- **Corner radius**: Not applicable: the component sets none of its own; below the limit the code block is styled by `MarkdownRenderer`, and above it by the `adh-mv-prose` styles for `pre.shiki`.
- **Padding**: Not applicable: none set by this component; it comes from the shared prose styles.
- **Font**: Monospace code, from the code-block styling shared with `MarkdownRenderer`. The invalid-text note below the limit is Markdown emphasis (italic) in the prose body font; above the limit the note is italic through `adh-mv-json-note`.
- **Background**: Below the limit, the shiki dual-theme code-block background shared with `MarkdownRenderer`. Above the limit, the `pre.shiki` background from the prose styles, without token colours.
- **Foreground/Text**: Below the limit, shiki token colours for valid JSON; invalid text has no language, so it has no token colours and renders as a bare `pre` without the `shiki` class. Above the limit, a single text colour. The plain-path note uses the muted text variable `--mdv-text-muted`.
- **Border**: Not applicable: none set by this component.
- **Shadow**: Not applicable: none set by this component.
- **Min/Max size**: Not applicable: no size constraint of its own. The root fills the width of its prose measure (`reading`, about 72ch). Long lines scroll sideways unless `wrap` is true.

## States

| State | Appearance change |
|-------|------------------|
| Default | Pretty-printed JSON in a coloured code block. |
| Pressed | Not applicable: the component has no interactive element. |
| Disabled | Not applicable: the component has no interactive element. |
| Focused | Not applicable: the component adds no focusable element of its own. |
| Loading | Below the limit, `MarkdownRenderer` shows a subtle "Rendering…" note (`aria-live="polite"`, `aria-busy="true"`) while its async pipeline runs. Above the limit there is no loading state; the output is synchronous. |
| Invalid text | The note "Not valid JSON — shown as written." followed by the unmodified content, uncoloured. |
| Large document | Plain `pre.shiki` block without syntax colours; the invalid note, if any, is a `p.adh-mv-json-note`. |
| Render error | Below the limit, `MarkdownRenderer` shows its alert pane "Failed to render document". Above the limit there is no error state. |

## Accessibility

- **semantic-markup**: Content is shown as a code block (`pre` containing `code`) on both paths, and the invalid note is a paragraph, so assistive technology reads the structure natively.
- **loading-announcement**: Below the limit, the "Rendering…" state is announced politely (`aria-live="polite"`, `aria-busy="true"`) and a pipeline failure is announced as an alert (`role="alert"`); both come from `MarkdownRenderer`.
- **no-own-controls**: The component adds no interactive control, so it defines no label, target-size or focus requirement of its own.
- **keyboard-scroll-highlighted**: Below the limit, the code block is the `pre` that the shiki highlighter emits, which carries `tabindex="0"` by default; the sanitisation schema in the Markdown pipeline allows the raw `tabindex` property shiki emits on `pre`, so a keyboard reader can focus the block and scroll a long unwrapped line sideways.
- **keyboard-scroll**: NEEDS REVIEW: Not implemented in source. Above the limit the plain `pre.shiki` is written by this component with no `tabindex`, so a long unwrapped line scrolls sideways but the block cannot take keyboard focus, and neither path gives the block an accessible name. Evidence that would settle it: a keyboard test of the oversized path in a browser, and a decision on whether the plain `pre` should be focusable.
- **contrast**: NEEDS REVIEW: Not implemented in source. The colours come from shiki's dual themes and the `--mdv-text-muted` variable; the source cannot say whether the note and token colours reach 4.5:1 in every reading theme. Evidence that would settle it: a contrast measurement of each reading palette.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| json-renderer-001 | pretty-print-document | `{"a":1,"b":[true]}` (from `pretty-json.test.ts`, "indents a JSON document") | Body is `{`, `  "a": 1,`, `  "b": [`, `    true`, `  ]`, `}` on separate lines, fenced as json, no note. |
| json-renderer-002 | pretty-print-lines, skip-blank-lines | `{"a":1}`, a blank line, `{"b":2}`, trailing newline (from "indents each record of JSON Lines") | Body is `{` / `  "a": 1` / `}` / `{` / `  "b": 2` / `}`, joined by a single newline, no blank line between records. |
| json-renderer-003 | invalid-shown-as-written, invalid-note, fence-language | `not json` (from "returns null for text that is neither") | Note "Not valid JSON — shown as written." then `not json` in a fence with no language. |
| json-renderer-004 | invalid-shown-as-written | `{"a":1}` newline `nope` (from "returns null for text that is neither") | One bad line makes the whole text invalid; shown unchanged with the note. |
| json-renderer-005 | invalid-shown-as-written | `   ` (whitespace only, from the same test) | Treated as invalid: the note, then the whitespace unmodified. |
| json-renderer-006 | fence-longer-than-body | JSON string value that contains a run of four backticks (derived from `pretty-json.test.ts`, "fences with more backticks than the body holds") | Fence is five backticks; block does not close early. |
| json-renderer-007 | single-line-not-lines, valid-no-note | A single line `{"a":1` (unterminated) | Invalid: the note and the text as written. |
| json-renderer-008 | limit-boundary | Valid JSON whose pretty-printed body is exactly 524288 characters | Rendered through `MarkdownRenderer`, with colours. |
| json-renderer-009 | highlight-limit, plain-path-markup, plain-path-no-processing | Valid JSON whose pretty-printed body is 524289 characters | A `div.adh-mv-prose` containing `pre.shiki > code` with the body; no Markdown pipeline call; no note. |
| json-renderer-010 | plain-path-note | Invalid text of 524289 characters | `p.adh-mv-json-note` with the note, then `pre.shiki > code` with the text unmodified. |
| json-renderer-011 | limit-measures-body | Compact JSON of 400000 characters that pretty-prints to more than 524288 | Takes the plain path, because the displayed text exceeds the limit. |
| json-renderer-012 | forward-wrap, plain-path-wrap | `wrap` true, once with a small and once with an oversized body | Small: `wrap` is passed to `MarkdownRenderer`. Oversized: root class includes `adh-mv-prose--wrap`. |
| json-renderer-013 | accept-wrap, default-measure | `wrap` omitted, oversized body | Root class is `adh-mv-prose` only: no wrap modifier and no fill modifier. |
| json-renderer-014 | inherit-markdown-errors | Small valid body while the Markdown pipeline rejects | `MarkdownRenderer`'s "Failed to render document" alert pane is shown; the component adds nothing. |

Test coverage note: `packages/web/packages/markdown/src/__tests__/jsonRenderer.test.tsx` renders `JsonRenderer` for all 14 vectors; `pretty-json.test.ts` and `prose-class.test.ts` cover the helpers. The one SHOULD requirement, `memoise-pretty`, has no vector because it is a performance property with no observable output.

## Edge Cases

- **Empty or whitespace-only content (MUST)**: `prettyJson` returns null for a trimmed empty string, so the component shows the invalid note and the content as written.
- **Valid scalar document (MUST)**: Text such as `42` or `"hi"` parses as a single document and is shown re-serialised.
- **Single JSON Lines record (MUST)**: A text with fewer than two non-blank lines that is not a valid document is invalid; one line is never treated as JSON Lines.
- **Mixed valid and invalid lines (MUST)**: One failing line makes the whole text invalid, and every line is shown as written.
- **Crossing the limit on edit (MUST)**: If `content` changes from small to large, the component switches from the `MarkdownRenderer` path to the plain path on the next render, and back again when it shrinks.
- **Backticks in the body (MUST)**: A body that contains backtick runs is fenced with a longer run, so the code block does not end early.
- **Body already ending in a newline (MUST)**: The fence adds no extra blank line before the closing fence.
- **Duplicate keys and number precision (MUST)**: The text is re-serialised from a parsed value, so duplicate object keys collapse to the last value and numbers that do not round-trip in a double lose precision. This is a consequence of `JSON.parse` followed by `JSON.stringify`; the source does not preserve the original tokens.
- **Concurrent access**: Not applicable: the component is a pure function of its props at render time; its only async work is inside `MarkdownRenderer`, which cancels a stale result when `content` changes.
- **Error states (MUST)**: Parse failures are not errors; they are the invalid state above. A Markdown pipeline failure below the limit shows the `MarkdownRenderer` error pane. Above the limit there is no pipeline to fail.
- **Offline or disconnected state**: Not applicable: the component performs no network access; it renders text it is given.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `content` | `string` | required | The JSON or JSON Lines text, as stored. |
| `wrap` | `boolean` | `false` | Wrap long lines instead of scrolling sideways. |
| `JSON_HIGHLIGHT_LIMIT` | exported `number` constant | `524288` (`512 * 1024`) | Character count above which the body is shown without syntax colours. Not a prop; changing it needs a code change. |

## Deep Linking

Not applicable: the component renders text it is given and owns no route or URL.

## Localization

- **note-string**: NEEDS REVIEW: Not implemented in source. The note "Not valid JSON — shown as written." is a hard-coded English literal on both paths and is not routed through any string table. Evidence that would settle it: the host application's localization approach and whether this note is ever shown to non-English readers.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal in source) | Not valid JSON — shown as written. | Shown above text that is not JSON or JSON Lines, as a paragraph (plain path) or Markdown emphasis (Markdown path). |

JSON content itself is shown verbatim and is not translated.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component has no animation. |
| Increase Contrast | Not applicable: the component sets no colours of its own beyond the muted note variable; colours come from the shared reading theme. |
| Differentiate Without Color | Not applicable: the invalid state is signalled by a text note, not by colour alone. |

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: None.
- **Storage**: None. The component holds the text only in props and a memoised pretty-printed string.
- **Transmission**: None. All work happens in the browser; nothing is sent.
- **Retention**: None.

## Logging

Not applicable: the component logs nothing. The only logging on this path is the `console.error` that `MarkdownRenderer` writes when its pipeline fails.

## Platform Notes

- **SwiftUI**: Not a source platform. Pretty-print with `JSONSerialization` (option `.prettyPrinted` emits two-space indents but writes a space before each colon and does not preserve key order, so write a small serializer if the exact layout matters) and show the result in a `Text` with a monospaced font inside a horizontal `ScrollView`. Split JSON Lines on newlines and parse each. Syntax colouring needs `AttributedString` runs or a highlighter package; apply a size cut-off for the same reason as `JSON_HIGHLIGHT_LIMIT`. Show the invalid note as a leading italic `Text`.
- **Compose**: Not a source platform. Build the text with `kotlinx.serialization` `Json { prettyPrint = true; prettyPrintIndent = "  " }` and show it in a `SelectionContainer` around a `Text` with `FontFamily.Monospace`, inside `horizontalScroll`; use a `LazyColumn` of lines for very large documents. Colour by building an `AnnotatedString` of `SpanStyle` runs; skip it above the size limit. The note is an italic `Text` above the block.
- **React/Web**: Source platform. Implemented in `packages/web/packages/markdown/src/components/JsonRenderer.tsx`, with `prettyJson` and `fenceCode` in `lib/pretty-json.ts` and the class list from `proseClassName` in `lib/prose-class.ts`; the note style `adh-mv-json-note` is in `markdown-viewer.css`. It memoises the pretty-printed text with `useMemo` and reuses `MarkdownRenderer` below the limit so highlighting stays in one place. The component and the constant are exported from the package index.
- **AppKit / UIKit**: Not a source platform. Use a read-only, non-editable `NSTextView` in an `NSScrollView` (or `UITextView` with `isEditable = false`) with a monospaced font and `NSAttributedString` colouring; `textContainer.widthTracksTextView` and the line-break mode map to the `wrap` prop. Pretty-print with `JSONSerialization` as above, and turn colouring off beyond the size limit, since attributed-string layout of very large documents is slow.
- **WinUI 3**: Not a source platform. Start from a `ScrollViewer` (`HorizontalScrollBarVisibility="Auto"` for no-wrap, `Disabled` for wrap) holding a `RichTextBlock` or a read-only `RichEditBox` with `FontFamily="Consolas"` and `IsTextSelectionEnabled="True"`. `TextWrapping` is `NoWrap` or `Wrap` from the `wrap` property. Pretty-print with `System.Text.Json` (`JsonSerializerOptions.WriteIndented = true` emits two-space indents) and split JSON Lines with one `JsonDocument.Parse` per non-blank line. Colour tokens by emitting `Run` elements with `Foreground` brushes from theme resources (`TextFillColorPrimaryBrush`, and `TextFillColorSecondaryBrush` for the note), so Light, Dark and High Contrast follow the system theme through `ThemeResource`. Above the size limit, bind a single `Run` with no per-token elements; a `RichTextBlock` with tens of thousands of inlines is slow. Make the scroll area keyboard-reachable by setting `IsTabStop="True"` on the `ScrollViewer`, and give the control an `AutomationProperties.Name` such as "JSON document". Put the invalid note in a leading italic `TextBlock` (`FontStyle="Italic"`). There is no `VisualStateManager` state beyond the default, because the control is non-interactive.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/markdown/src/components/JsonRenderer.tsx` | confirmed (1.0.2) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Text that does not parse is shown exactly as written under a one-line note, never repaired or partially reformatted.
**Rationale**: The component's doc comment says "never silently reformatted"; a viewer for stored files must not alter evidence of a malformed document.
**Approved**: pending

**Decision**: JSON Lines is detected only after whole-document parsing fails, and needs at least two non-blank lines, all of which must parse.
**Rationale**: A single line that is not a document is far more likely to be broken JSON than a one-record file, and one bad line makes the whole text ambiguous; showing it as written avoids guessing.
**Approved**: pending

**Decision**: Below 512 KiB the body is rendered by `MarkdownRenderer` inside a Markdown fence rather than highlighted directly.
**Rationale**: It gives the same code-block styling and shiki themes as a fenced json block in a document, with highlighting kept in one place. The cost is that output arrives after the async pipeline, and the body is passed through Markdown parsing, which is why the fence must be longer than any backtick run in it.
**Approved**: pending

**Decision**: Above `JSON_HIGHLIGHT_LIMIT` (`512 * 1024` characters) the body is shown as plain `pre.shiki > code` without syntax colours and without calling the pipeline.
**Rationale**: The source comment says shiki on a multi-megabyte trajectory stalls the page for seconds. The limit is a workaround for that, measured on displayed characters, and is a constant rather than a prop. The plain `pre` carries the `shiki` class so it picks up the code-block styles of the highlighted path and only the colours differ.
**Approved**: pending

**Decision**: The pretty-printed text is memoised on `content` so a re-render with the same text does not parse it again.
**Rationale**: Parsing and re-serialising a large document is the component's one synchronous cost; it is a SHOULD because skipping it changes speed, not output.
**Approved**: pending

**Decision**: Re-serialisation goes through `JSON.parse` then `JSON.stringify`, so duplicate keys collapse and non-round-tripping numbers change.
**Rationale**: It is the simplest way to guarantee two-space indents and valid output; the source accepts this loss of fidelity, and the recipe records it because a reader of a raw file may be surprised.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.performance.lazy-loading](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/93049d53-e8e2-5ea3-8a3a-9eb07e60d0e2) | partial | performance |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |

Parsing, fencing and class-list logic live in small pure helpers (`prettyJson`, `fenceCode`, `proseClassName`) and Markdown rendering stays in `MarkdownRenderer`, so the component only chooses between two paths: that meets separation-of-concerns. Unit-test coverage passes: the helpers have tests and `jsonRenderer.test.tsx` covers all 14 vectors against the component. Performance is partial: the size limit protects the page from a slow highlight, but the pretty-print itself runs synchronously on the render thread for any size. Semantic markup passes because output is a `pre` and `code`: `pre.shiki` for valid JSON and for the oversized plain path, and a bare `pre` for invalid text, which is fenced with no language and so is not highlighted. `jsonRenderer.test.tsx` asserts `pre.shiki` wherever the source produces it. Keyboard navigation is partial: below the limit the shiki `pre` is focusable, but the open question on `keyboard-scroll` remains for the oversized plain `pre`, which is not. No-hardcoded-strings fails on the open question on `note-string`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-16 | Mike Fullerton | The keyboard-scroll requirement names the raw tabindex property the sanitize schema keeps on shiki's pre |
| 1.0.2 | 2026-11-14 | Mike Fullerton | Conformance tests added (jsonRenderer.test.tsx, 14 of 14 vectors); unit-test-coverage now passed. |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Match recipe to source: valid JSON renders pre.shiki, language-less invalid text a bare pre |
