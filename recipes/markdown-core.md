---
id: 9f938c20-ea6e-42d7-9ddf-9531a96e3ad0
title: Markdown Core
domain: adhsdk://recipes/markdown-core
type: ingredient
version: 1.0.3
status: review
language: en
created: '2026-09-23'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'Cross-platform markdown document logic: fence scanning, frontmatter
  parsing and serialization, title/excerpt derivation, the document model, the
  web fetch hook, and the web render pipeline that markdown-family components
  build on.'
platforms:
- swift
- macos
- ios
- typescript
- web
tags:
- markdown
- frontmatter
- yaml
- content-model
depends-on: []
related:
- adhsdk://recipes/markdown-content
- adhsdk://recipes/markdown-renderer
- adhsdk://recipes/markdown-viewer
- adhsdk://recipes/markdown-reading-palette
references: []
approved-by: ''
approved-date: ''
---

# Markdown Core

## Overview

Markdown Core is the non-UI logic underlying every markdown-family component in this toolkit: fence scanning, YAML-frontmatter parsing and serialization, title/excerpt derivation, the `MarkdownDocument` value model, a web data-fetching hook, and the web HTML render pipeline (including its GitHub-style alert transform and its reading-theme data). It has no visual surface of its own — consumer components (`markdown-content`, `markdown-renderer`, `markdown-viewer`, `markdown-reading-palette`, and others) build their UI on top of the functions and types documented here.

Two platforms share this ingredient, each built for a different constraint. The Apple side (`FenceScanner`, `Frontmatter`/`YAMLScalar`, `MarkdownDocument`, `MarkdownText`) is Foundation-only Swift that compiles into all five of the toolkit's platform frameworks; because it must stay portable to platforms with no bundled YAML library, its frontmatter reader/writer is a hand-rolled, conservative scalar parser rather than a full YAML implementation, and its title/excerpt logic mirrors a Node.js backend ("adh") that it does not itself depend on. The web side (`useMarkdownDocument`, `document-title.ts`, `process-markdown.ts`, `remark-adh-alerts.ts`, `palettes.ts`/`registry.ts`) runs on Node and the browser and, for exactly one concern — reading and writing a document's frontmatter `title` — spends the cost of a real `yaml` package that the Apple side cannot afford. The two implementations are deliberately allowed to diverge on the handful of YAML constructs (block sequences, flow mappings, folded/literal block scalars, aliases) the Apple parser cannot type, and those divergences are pinned as tests, not left as open questions.

Both sides independently derive title and excerpt text from the same three regex families — paired backtick fences, paired tilde fences, and an unterminated-fence tail — transcribed line-for-line from adh's own `lib/markdown.ts`. That title-search logic is kept deliberately separate from the CommonMark-correct `FenceScanner` used for actual rendering, because the two answer different questions: what a renderer must treat as a code block, versus what adh's own lazy-regex title search has always treated as one (see Design Decisions).

## Behavioral Requirements

### Fence scanning (FenceScanner.swift)

- **fence-marker-recognition**: `FenceScanner.fence(in:)` MUST recognize a line as a fence opener when, after any amount of leading whitespace, it contains a run of 3 or more identical fence-marker characters (backtick or tilde); an info string following the run is permitted and does not affect recognition.
- **backtick-fence-info-string-restriction**: A backtick-fenced opener's info string MUST NOT itself contain a backtick — `FenceScanner.fence(in:)` MUST treat such a line as not a fence at all. A tilde-fenced opener's info string has no such restriction.
- **closing-fence-matching**: `FenceScanner.classify(_:)` MUST close an open fence only on a line whose marker character matches the opener's, whose run length is greater than or equal to the opener's length, and which carries no info string; a shorter run, a mismatched marker, or a run followed by any info string MUST be classified `.insideFence`, not `.closingFence`.
- **unterminated-fence-runs-to-eof**: Once an opening fence is seen with no matching closer, `FenceScanner.classify(_:)` MUST classify every remaining line as `.insideFence` through end of input, and `fencedBlockContents(in:)` MUST yield no fenced block for it.
- **grapheme-cluster-line-splitting**: `FenceScanner.classify(_:)` MUST split input into lines on `Character.isNewline` (grapheme-cluster boundaries), not a scalar `"\n"` split, so a CRLF sequence is one line terminator rather than producing an extra empty line.

### Frontmatter parsing and serialization (Frontmatter.swift, YAMLScalar)

- **frontmatter-block-detection**: `Frontmatter.split(_:)` MUST recognize a leading frontmatter block using the pattern `^---\r?\n([\s\S]*?)\r?\n---[ \t]*\r?\n?`, anchored to the start of the string, mirroring adh's own `FRONTMATTER_RE`; content not opening with `---` at position 0, or whose opening fence has no matching closing `---` line, MUST be treated as having no frontmatter block.
- **byte-exact-round-trip**: `FrontmatterSplit`'s `prefix` and `body` MUST concatenate back to the original input byte-for-byte (`prefix + body == original`), whether or not the input has a frontmatter block; `block` is a substring of `prefix` (the fenced content only, without the `---` delimiter lines) and is not itself part of the reconstruction.
- **fail-soft-parsing**: `Frontmatter.parse(_:)` MUST return an empty dictionary, never throw, for content with no frontmatter block or a block with no scalar-looking `key: value` lines.
- **last-duplicate-key-wins**: `Frontmatter.parse(_:)` MUST resolve a key duplicated within one block to its last occurrence's value.
- **string-typed-value-only**: `Frontmatter.stringValue(_:in:)` MUST return a value only when `YAMLScalar` types it as a string (mirroring adh's `typeof v === 'string'`); a boolean, number, null, or otherwise-untypeable scalar MUST yield `nil` even though `Frontmatter.value(_:in:)` would return its raw text.
- **setting-rewrites-normalizes-duplicates**: `Frontmatter.setting(_:to:in:)` MUST rewrite an existing key in place, append a new key when absent and the new value is non-nil, and collapse every duplicate occurrence of the key into a single line.
- **setting-nil-removes-key**: `Frontmatter.setting(_:to:in:)` MUST remove all lines for a key when the new value is `nil`, and MUST remove the entire frontmatter block (fences included) when doing so empties it.
- **setting-preserves-body-line-endings**: `Frontmatter.setting(_:to:in:)` MUST re-emit the rewritten block LF-normalized while leaving the body's own line endings untouched.
- **round-trip-inverse-pair**: `Frontmatter.unquote(_:)` and `Frontmatter.serialize(_:)`/`serializeString(_:)` MUST be exact inverses for the 5 recognized escapes (double-quote, backslash, newline, carriage-return, tab); an unrecognized escape sequence MUST keep its leading backslash on unquoting rather than dropping it.
- **conservative-quoting**: `YAMLScalar.needsQuoting(_:)` MUST quote a scalar starting with a YAML indicator character, a YAML 1.1 boolean synonym (`yes`/`no`/`on`/`off`, case-insensitive), or anything that would otherwise be misread as null, boolean, or numeric.
- **json-projection-typed-scalars**: `Frontmatter.jsonText(for:)` MUST type each scalar through `YAMLScalar` (boolean, number, null, or string) when serializing to canonical sorted JSON, and MUST fall back to the literal source text as a JSON string for anything `YAMLScalar` cannot type (a flow mapping, a nested flow sequence, or a block-scalar header). This reader diverges from adh's real YAML parser on three specific constructs — see Design Decisions.
- **flow-sequence-parsing**: `Frontmatter.flowSequenceItems(_:)` MUST parse a single-level `[a, b]`-style flow sequence item by item, honoring quoted items and escapes, and MUST return `nil` (not a partial parse) for a sequence containing a nested `[` or `{`.

### Document model (MarkdownDocument.swift)

- **document-value-semantics**: `MarkdownDocument` MUST be a `Sendable`, `Equatable`, `Identifiable` value type whose `id` is the sole identity; `currentVersion` and `latestVersionID` MUST be treated as server-owned fields the model never mutates itself.
- **derived-title-and-excerpt**: `MarkdownDocument.title` and `.excerpt` MUST be computed on read from `content` via `MarkdownText.deriveTitle`/`deriveExcerpt`, never stored, so they cannot drift out of sync with `content`.
- **pinned-state-lives-in-frontmatter**: `MarkdownDocument.isPinned` MUST reflect the frontmatter `pinned` key being the literal string `"true"`, and `setPinned(_:)` MUST write it through `Frontmatter.setting("pinned", to:in:)` as a real boolean when pinning and remove the key when unpinning, so pinning adds an actual `pinned: true` line, not a quoted string.
- **factory-defaults-match-adh**: `MarkdownDocument.new(id:content:ownerKind:ownerID:now:)` MUST default `visibility` to `.private`, `stage` to `.draft`, `isDeleted` to `false`, and `currentVersion` to `1`.

### Title and excerpt derivation (MarkdownText.swift)

- **utf16-title-truncation**: `MarkdownText.truncated(_:toUTF16CodeUnits:)` MUST truncate by UTF-16 code unit count (mirroring JavaScript's `String.prototype.slice`) and MUST drop a surrogate pair entirely rather than emit half of one when the cut point falls inside it.
- **unicode-scalar-excerpt-source-window**: `MarkdownText.excerptSource(_:)` MUST window content to `excerptSourceCharacters` (2000) Unicode scalars, mirroring PostgreSQL's `left()`, independent of the UTF-16-based title truncation.
- **fence-stripping-before-title-search**: `MarkdownText.titleSearchBody(_:)` MUST strip a leading frontmatter block (via `Frontmatter.split(_:).body`) and then strip paired backtick fences, paired tilde fences, and a trailing unterminated fence, in that order, using adh's own regex patterns, before any title line is searched for.
- **line-syntax-stripped-once**: `MarkdownText.stripLineSyntax(_:)` MUST strip one leading run of blockquote markers, one leading run of heading hashes, and one leading list marker — each applied once, not to a syntactic fixed point — then trim, before a line is accepted as a title candidate.
- **frontmatter-title-precedence**: `MarkdownText.resolvedTitle(_:frontmatterSource:)` MUST prefer a non-empty, trimmed frontmatter `title`, then a non-empty, trimmed frontmatter `name`, before falling back to the first non-empty stripped body line, then to `"Untitled"`.
- **title-character-cap**: `MarkdownText.deriveTitle(_:)` MUST cap the resolved title at `titleCharacterLimit` (500) UTF-16 code units.
- **excerpt-skips-title-line**: `MarkdownText.deriveExcerpt(_:frontmatterFrom:)` MUST skip exactly the first body line when the title came from the body (not frontmatter), then collect up to `excerptLines` (4) lines, each capped at `excerptLineCharacters` (160) UTF-16 code units.
- **content-hash-is-sha256-hex**: `MarkdownText.contentHash(_:)` MUST return the lowercase hex SHA-256 digest of `content` via CryptoKit.
- **byte-length-is-utf8**: `MarkdownText.byteLength(_:)` MUST return the UTF-8 byte count of `content`.
- **scalar-newline-line-splitting**: `MarkdownText.lines(of:)` MUST split on the Unicode scalar `"\n"`, not `Character`, for CRLF-safe parity with adh's own line splitting — distinct from `FenceScanner`'s grapheme-cluster splitting, which answers a different question (see Design Decisions).

### Web fetch hook (useMarkdownDocument.ts)

- **fetcher-held-in-ref**: `useMarkdownDocument` MUST hold the caller-supplied `fetcher` in a `useRef` reassigned every render, not as an effect dependency, so an unmemoized inline fetcher does not re-fire the fetch effect.
- **timeout-aborts-with-reason**: `useMarkdownDocument` MUST start an `AbortController` per fetch and abort it with reason `TIMEOUT_REASON` (`'mdv-timeout'`) after `timeoutMs` (default `DEFAULT_TIMEOUT_MS`, 15000 ms) elapses.
- **stale-response-suppression**: On success, `useMarkdownDocument` MUST drop the resolved document only when the controller was aborted for a reason other than the timeout reason (an unmount or an `id` change); a fetch that was aborted for the timeout reason but nonetheless resolves MUST still be shown as a success with that data — it is neither dropped nor surfaced as the timeout error. On error, the same stale check applies to a rejection aborted for a non-timeout reason, and a rejection whose abort reason is the timeout reason MUST be surfaced as the timeout error message ("Timed out loading document after Ns."); only a late rejection, never a late resolution, produces that message.
- **default-fetcher-error-messages**: `defaultMarkdownFetcher`'s `messageFromResponse(res, id)` MUST read the response body as text exactly once, MUST parse an `application/problem+json` body into a `title` and `detail` joined by an em dash when both are present, and MUST otherwise produce a 404-specific "Document not found" message or a generic HTTP-status message.
- **idle-state-when-id-absent**: `useMarkdownDocument` MUST report `idle` state whenever `id` is absent, derived on read rather than synchronized through the fetch effect.

### Web frontmatter title read/write parity (document-title.ts)

- **frontmatter-re-mirrors-backend**: `document-title.ts`'s `FRONTMATTER_RE` MUST be the exact pattern `/^---\r?\n([\s\S]*?)\r?\n---[ \t]*\r?\n?/`, matching the backend's own frontmatter matcher.
- **real-yaml-parser-for-frontmatter**: `frontmatterOf(content)` MUST parse the frontmatter block with the `yaml` package's `parseYaml(..., { logLevel: 'silent' })` rather than a line regex, and MUST return `null` when the parsed result is not a plain object (including an array) or when `parseYaml` itself throws (for example an unresolved alias). Because `logLevel: 'silent'` swallows a YAML *syntax* error and returns whatever partial document `yaml` could recover, a syntactically malformed block (e.g. `foo: [unclosed`) does NOT make `frontmatterOf` return `null` — it returns the recovered mapping, so a malformed block can still yield a title on the read path even though the write path separately refuses to touch the same block (see **write-path-refuses-unparseable-yaml**, which checks `parseDocument`'s error list rather than `parseYaml`'s silent recovery).
- **title-derivation-parity-with-apple**: `deriveDocumentTitle(content)` MUST resolve a title in the same precedence as `MarkdownText.resolvedTitle` — frontmatter title, then frontmatter name, then the first stripped non-empty body line, then `'Untitled'` — capped at `MAX_TITLE` (500) characters.
- **write-path-refuses-unparseable-yaml**: `setFrontmatterTitle(content, title)` MUST leave `content` unchanged when the existing frontmatter block fails to parse or its parsed contents are not a mapping, rather than attempting to patch malformed YAML.
- **write-path-avoids-spurious-edits**: `setFrontmatterTitle(content, title)` MUST NOT create a frontmatter block when none exists and the derived title already equals the requested title, MUST NOT rewrite an existing `title` value that already equals the requested value, and MUST always double-quote a title it does write.
- **write-path-never-touches-name**: `setFrontmatterTitle` MUST NOT write or delete a frontmatter `name` key under any circumstance. It MAY read `name` indirectly — via `deriveDocumentTitle`'s title-precedence fallback (frontmatter `title`, then `name`, then the first body line) — solely to decide whether a block with no `title` key already derives the requested title, in which case it MUST leave `content` unchanged rather than injecting a spurious `title` key (see mdc-035).
- **byte-identical-reemission**: `setFrontmatterTitle` MUST stringify an untouched frontmatter block with `flowCollectionPadding: false` and `lineWidth: 0` so a block it does not need to change round-trips byte-identically.

### Web render pipeline (process-markdown.ts)

- **pipeline-stage-order**: `processMarkdown(raw)` MUST run its unified pipeline in order: gray-matter frontmatter split, `remark-parse`, `remark-gfm`, `remarkAdhAlerts`, `remark-rehype` (`allowDangerousHtml` left at its default `false`, so raw HTML in source is dropped, not passed through), `rehype-slug`, `rehype-autolink-headings` (`behavior: 'wrap'`), shiki syntax highlighting via `rehypeShikiFromHighlighter`, `rehype-sanitize`, then `rehype-stringify`.
- **highlight-before-sanitize**: Syntax highlighting MUST run before sanitization, because the highlighter produces real hast element nodes for the sanitizer to filter; sanitizing first would strip the highlighter's own token markup.
- **highlighter-lazy-singleton**: `getHighlighter()` MUST lazily create the shiki highlighter exactly once at module scope, and `getProcessor()` MUST likewise lazily build the unified processor once, reusing both across calls in the same process.
- **sanitize-allowlist-not-denylist**: `sanitizeSchema` MUST sanitize by an explicit tag/attribute/protocol allowlist; `script`, `style`, `iframe`, `object`, `embed`, and `form` MUST be stripped, and the `style` attribute MUST be permitted only on `code`, `pre`, and `span` — never globally — so shiki's dual-theme CSS variables survive while an inline-style vector on other tags does not. `className` is, by contrast, allowed globally (the schema's `'*'` entry, plus `li`), which is what lets `remark-adh-alerts`'s retagged `div`/`p` alert markup keep its `adh-mv-alert`/`adh-mv-alert-title` classes through sanitization (see **marker-stripped-title-injected**).
- **sanitize-protocol-allowlist**: `sanitizeSchema.protocols` MUST restrict `href` to `http`, `https`, `mailto`, and `tel`, and `src`/`cite` to `http`/`https` only; no `data:` URI is permitted anywhere.
- **frontmatter-exposed-as-metadata**: `processMarkdown(raw)` MUST return the frontmatter object gray-matter parses alongside `html`, and MUST return `title` only when `frontmatter['title']` is itself a string.
- **malformed-frontmatter-yaml-handling**: `processMarkdown(raw)` calls `matter(raw)` (gray-matter) with no `try`/`catch`; malformed YAML frontmatter makes gray-matter throw, and because `processMarkdown` is an `async` function, that throw surfaces as a rejected promise rather than a render that treats the frontmatter as absent. No source file or test (`process-markdown.test.ts`, read in full) exercises this path.

### Alert blockquote transform (remark-adh-alerts.ts)

- **alert-marker-recognition**: `remarkAdhAlerts` MUST recognize a blockquote as a GitHub-style alert only when its first child is a paragraph whose first inline child is a text node matching `^\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*` at its start, and MUST recurse into every blockquote's children regardless of whether that blockquote matched, so a nested alert inside a non-alert blockquote is still transformed.
- **marker-stripped-title-injected**: On a match, `transformAlert` MUST strip that alert-marker text from the paragraph (removing the now-empty leading paragraph entirely when the alert marker was its only content), retag the blockquote as an `adh-mv-alert adh-mv-alert--{kind}` `div` via `data.hName`/`data.hProperties`, and prepend a title paragraph rendering the matching English entry of `ALERT_TITLES` as an `adh-mv-alert-title` element.

### Theme data (palettes.ts, registry.ts)

- **palette-module-owns-all-color-literals**: `palettes.ts` MUST be the sole module in the package permitted to contain concrete color literals for the 13 `--mdv-*` custom properties, across the 4 built-in palettes (`dark`, `light`, `sepia`, `github`); shiki's own code-block colors MUST NOT be defined there.
- **theme-lookup-falls-back-by-id**: `getThemeById(id)` MUST fall back to the theme whose `id` equals `DEFAULT_THEME_ID` (`'dark'`) when `id` is not found, looked up by id rather than by array position, so reordering `VIEWER_THEMES` cannot change the fallback theme.
- **theme-id-validation-rejects-nullish**: `isValidThemeId(id)` MUST return `false` for `null` or `undefined` as well as for any id absent from `VIEWER_THEME_IDS`.

## Appearance

Not applicable — markdown-core is a headless logic layer (fence scanning, frontmatter parsing, title/excerpt derivation, a document model, a fetch hook, and a render pipeline that emits HTML strings and theme data); it draws no UI of its own.

## States

Not applicable — the only state machine here is `useMarkdownDocument`'s `FetchState<T>` (`idle`/`loading`/`error`/`success`), and it is a data value returned to a caller, not a visual state; see Behavioral Requirements for its transitions.

## Accessibility

Not applicable — markdown-core renders no interactive UI; the HTML string `processMarkdown` emits is consumed by presentation-layer components (e.g. `markdown-renderer`, `markdown-viewer`) that own accessibility semantics for what they display.

## Conformance Test Vectors

| ID | Requirements | Input | Expected | Citation |
|---|---|---|---|---|
| mdc-001 | fence-marker-recognition | ` ```lang ` opener paired with ` ``` ` closer | both lines classified as fence delimiters, contents between as `.insideFence` | FenceScannerTests.swift "both fence markers open and close a block" |
| mdc-002 | backtick-fence-info-string-restriction | a backtick opener whose info string itself contains a backtick | line is not classified as a fence at all | FenceScannerTests.swift "an opener's info string is allowed, and a backtick in it is not a fence at all" |
| mdc-003 | closing-fence-matching | a closer shorter than its opener, or carrying an info string, or of the other marker | classified `.insideFence`, block stays open | FenceScannerTests.swift "a closing fence must be at least as long as the opener", "a closing fence carries no info string", "a fence is closed only by its own marker" |
| mdc-004 | unterminated-fence-runs-to-eof | a fence opened and never closed | `fencedBlockContents` yields no block | FenceScannerTests.swift "an unterminated fence runs to the end of the document and yields no block" |
| mdc-005 | grapheme-cluster-line-splitting | CRLF-separated document | split into the correct line count, no phantom empty line | FenceScannerTests.swift "a CRLF document is split into its lines, not read as one" |
| mdc-006 | frontmatter-block-detection, byte-exact-round-trip | 8 samples incl. CRLF, an unclosed block, a block not at position 0 | `prefix + body` reconstructs the original exactly; non-frontmatter content splits to no block | FrontmatterTests.swift "prefix and body always recombine into the original, byte for byte", "a block that is not at the very start is not frontmatter", "an unterminated block is not frontmatter" |
| mdc-007 | fail-soft-parsing | content with no frontmatter block | `Frontmatter.parse` returns an empty dictionary, no throw | FrontmatterTests.swift "fails soft: lines it cannot read are skipped, not thrown" |
| mdc-008 | setting-rewrites-normalizes-duplicates | a key duplicated across multiple lines, then rewritten | write collapses every occurrence to one line | FrontmatterTests.swift "overwriting a duplicated key leaves exactly one line, and it is the new one", "a document whose block duplicates a key is normalised by one round trip" |
| mdc-009 | setting-nil-removes-key | removing the sole remaining key | the entire frontmatter block is removed | FrontmatterTests.swift "removing the last key removes the whole block" |
| mdc-010 | round-trip-inverse-pair | a value containing `C:\Users\me` | the unrecognized escape's backslash survives the round trip | FrontmatterTests.swift "an unrecognised escape keeps its backslash rather than losing it" |
| mdc-011 | conservative-quoting | values `true`, a YAML 1.1 boolean synonym, a number-looking string, and an ordinary word | the former are quoted on write, the ordinary word is not | FrontmatterTests.swift "a value YAML would type as something other than a string is quoted", "an ordinary word is still written bare" |
| mdc-012 | json-projection-typed-scalars | bool, negative int, float, scientific notation, hex, octal, null, `~`, and string scalars | `jsonText` types each as the matching JSON type | FrontmatterTests.swift "jsonText emits each value as the JSON type YAML gives it" |
| mdc-013 | json-projection-typed-scalars | a flow mapping `{a: 1}`, a nested sequence, and a block-scalar header `>-` | `jsonText` falls back to literal text for each rather than guessing a type | FrontmatterTests.swift "what jsonText will not type, it hands back as text rather than guessing" |
| mdc-014 | flow-sequence-parsing | a nested flow sequence `[a, [b]]` | `flowSequenceItems` returns `nil`, not a partial parse | FrontmatterTests.swift "a flow sequence becomes a JSON array of its typed items" (nested case) |
| mdc-015 | string-typed-value-only | a boolean-typed `pinned: true` value | `stringValue` returns `nil` though `value` would return `"true"` | FrontmatterTests.swift "stringValue reads only what YAML would type as a string" |
| mdc-016 | derived-title-and-excerpt, factory-defaults-match-adh | `MarkdownDocument.new(...)` | `visibility == .private`, `stage == .draft`, `currentVersion == 1`, title/excerpt computed from content | MarkdownDocumentTests.swift "a new document is a private draft owned by its creator", "a new document derives its title and excerpt from its content" |
| mdc-017 | pinned-state-lives-in-frontmatter | `setPinned(true)` on `"# Hi\n"` | content becomes `"---\npinned: true\n---\n# Hi\n"`; `stringValue("pinned", ...)` is `nil` | MarkdownDocumentTests.swift "pinning writes frontmatter and unpinning removes it" |
| mdc-018 | content-hash-is-sha256-hex | `"abc"`, `""`, `"# Hello\n"` | SHA-256 hex digests `ba7816bf...015ad`, `e3b0c442...b852b855`, `90f8ec56...4ad17be` | MarkdownTextTests.swift "the content hash is a stable lowercase SHA-256 of the UTF-8 bytes" |
| mdc-019 | title-character-cap | a first line long enough that the 500th UTF-16 unit falls inside a surrogate pair | the title is capped at 500 units, and the split pair is dropped rather than half-emitted | MarkdownAdhParityTests.swift "drops a surrogate pair the 500th code unit would split" |
| mdc-020 | frontmatter-title-precedence | frontmatter with `name` but no `title` | title falls back to the frontmatter `name` value | MarkdownTextTests.swift "frontmatter name is the fallback, and loses to title when both are set" |
| mdc-021 | fence-stripping-before-title-search | a document whose lazily-paired fence markers do not close each other the way `FenceScanner` would read them | the title resolves per adh's own lazy-regex pairing, a documented quirk distinct from `FenceScanner` | MarkdownTextTests.swift "a fenced code block is not a title" |
| mdc-022 | excerpt-skips-title-line | a title resolved from frontmatter | the excerpt does not skip a body line | MarkdownTextTests.swift "the excerpt keeps the first body line when frontmatter named the title" |
| mdc-023 | unicode-scalar-excerpt-source-window | a frontmatter block extending past the 2000-scalar excerpt window | the title still resolves from the whole document's frontmatter, not just the windowed excerpt source | MarkdownAdhParityTests.swift (excerpt-source-window section) |
| mdc-024 | json-projection-typed-scalars (documented divergence) | a YAML block sequence `allowed:\n  - a\n  - b` | `jsonText` types the key as JSON `null`, not an array | MarkdownAdhParityTests.swift "DIVERGENCE: a block sequence is flattened away, where adh's parser keeps it" |
| mdc-025 | json-projection-typed-scalars (documented divergence) | a flow mapping `{a: 1}`, a folded block scalar `>-`, and an alias `*undef` | each reaches the JSON column as literal text, not a parsed value | MarkdownAdhParityTests.swift "DIVERGENCE: a flow mapping, a block scalar and an alias reach the column as text" |
| mdc-026 | fail-soft-parsing (documented divergence) | a malformed/non-mapping frontmatter block (`name: *undef`) | `stringValue("name", ...)` still returns `"*undef"`, where adh's parser would null the whole block | MarkdownAdhParityTests.swift "adh nulls a malformed or non-mapping block; this reader still reads its keys" |
| mdc-027 | default-fetcher-error-messages | an ok HTTP response | resolves to the parsed JSON body | fetcher.test.ts "resolves to the JSON body on an ok response" |
| mdc-028 | default-fetcher-error-messages | a `422` response with an `application/problem+json` body (`title`/`detail`) | rejects with the `title`/`detail` message joined by an em dash | fetcher.test.ts "rejects with a \"title — detail\" message for problem+json errors" |
| mdc-029 | default-fetcher-error-messages | a `404` response with no content-type | rejects with a "Document not found" message | fetcher.test.ts "rejects with \"Document not found\" for a 404" |
| mdc-030 | theme-lookup-falls-back-by-id | an unknown theme id | `getThemeById` returns the `DEFAULT_THEME_ID` theme, not `VIEWER_THEMES[0]` | registry.test.ts "falls back to DEFAULT_THEME_ID for an unknown id" |
| mdc-031 | theme-id-validation-rejects-nullish | `isValidThemeId(null)` | returns `false` | registry.test.ts "returns false for null" |
| mdc-032 | frontmatter-exposed-as-metadata | markdown with a YAML frontmatter block | `processMarkdown` strips it from the rendered HTML and returns it as `frontmatter` | process-markdown.test.ts "strips YAML frontmatter and exposes it as metadata" |
| mdc-033 | sanitize-allowlist-not-denylist | markdown containing `<script>`, an `onerror` handler, and an inline `style` on a `<div>` | all three are stripped from the rendered HTML | process-markdown.test.ts "is inert to XSS payloads" |
| mdc-034 | write-path-refuses-unparseable-yaml | an existing frontmatter block containing unparseable YAML (`title: [unclosed`) | `setFrontmatterTitle` returns the input unchanged | document-title.test.ts "refuses to rewrite frontmatter it cannot parse" |
| mdc-035 | write-path-avoids-spurious-edits | a document whose derived title already equals the requested title, with no explicit frontmatter | `setFrontmatterTitle` does not inject a frontmatter block | document-title.test.ts "does not inject frontmatter when the document already derives the requested title" |
| mdc-036 | byte-identical-reemission | a complex, untouched frontmatter block | `setFrontmatterTitle` re-emits it byte-identically | document-title.test.ts "re-emits an untouched block byte-identically" |
| mdc-037 | title-derivation-parity-with-apple | a title written as a folded (`>-`) YAML block scalar | `frontmatterOf`/`deriveDocumentTitle` read its folded value, not the `>-` marker | document-title.test.ts "reads a folded (>-) title as its folded VALUE, not as the \">-\" marker" |

## Edge Cases

- Fewer than 3 fence-marker characters MUST NOT be treated as a fence opener regardless of surrounding whitespace **(boundary value)** — fence-marker-recognition.
- A closing-fence line shorter than its opener, of the wrong marker, or carrying its own info string MUST be classified `.insideFence`, not treated as a closer **(malformed input)** — closing-fence-matching.
- An opening fence with no matching closer anywhere in the remaining input MUST run to end of file and yield no fenced block **(unterminated input)** — unterminated-fence-runs-to-eof.
- A frontmatter-looking `---` block not anchored at position 0 MUST NOT be recognized as frontmatter **(malformed input)** — frontmatter-block-detection.
- An unclosed `---` block MUST NOT be recognized as frontmatter **(malformed input)** — frontmatter-block-detection.
- Setting a frontmatter key to `nil` when it is the block's only key MUST remove the whole block, fences included, not leave an empty shell **(boundary value)** — setting-nil-removes-key.
- A title-cap cut that falls inside a UTF-16 surrogate pair MUST drop the whole pair rather than emit an invalid half **(boundary value, Unicode)** — title-character-cap.
- A frontmatter block extending past the 2000-Unicode-scalar excerpt source window MUST still be read in full for title derivation **(boundary value)** — unicode-scalar-excerpt-source-window.
- A fetch aborted for the timeout reason that nonetheless resolves afterward MUST be shown as a success with that data — a timeout-reason abort does not, by itself, drop the result the way an unmount/id-change abort does; only a fetch that instead rejects after a timeout abort produces the timeout error message **(concurrent access)** — stale-response-suppression.
- A `problem+json` error body MUST be read as text exactly once; a second read (e.g. also as JSON) would throw a "body already used" error **(error state)** — default-fetcher-error-messages.
- A malformed or non-mapping frontmatter block on the write path MUST leave `content` completely unchanged rather than attempting a partial patch **(error state)** — write-path-refuses-unparseable-yaml.
- A syntactically malformed frontmatter block (e.g. `foo: [unclosed`) does NOT make `frontmatterOf`/`deriveDocumentTitle` return `null` or fall back to the body — `parseYaml`'s silent log level recovers a partial document, so the read path still derives a title from it, while `setFrontmatterTitle`'s write path independently refuses to touch the same block because `parseDocument` reports an error **(read/write asymmetry)** — real-yaml-parser-for-frontmatter, write-path-refuses-unparseable-yaml.
- Raw HTML embedded in source markdown MUST be dropped by `remark-rehype`'s default `allowDangerousHtml: false`, never passed to the sanitizer as trusted markup **(security boundary)** — pipeline-stage-order.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `fetcher` | `MarkdownFetcher` | `defaultMarkdownFetcher` | `useMarkdownDocument` option overriding how the document is retrieved; held in a ref so an unmemoized inline function does not re-trigger the fetch effect. |
| `timeoutMs` | `number` | `15000` (`DEFAULT_TIMEOUT_MS`) | `useMarkdownDocument` option controlling how long to wait before aborting the fetch with reason `'mdv-timeout'`. |
| `MarkdownText.excerptLines` | `Int` (constant) | `4` | Apple-side constant capping the number of lines `deriveExcerpt` collects; not exposed as a runtime option. |
| `MarkdownText.excerptLineCharacters` | `Int` (constant) | `160` | Apple-side constant capping each excerpt line, in UTF-16 code units. |
| `MarkdownText.excerptSourceCharacters` | `Int` (constant) | `2000` | Apple-side constant windowing `excerptSource` to this many Unicode scalars before excerpt derivation runs. |
| `titleCharacterLimit` / `MAX_TITLE` | `Int` / `number` (constant) | `500` | Shared cap, on both Apple and web, on a derived or written title's length. |

## Deep Linking

Not applicable: markdown-core defines no routes or URL schemes of its own. `MarkdownDocument.publicRoute` and the default fetcher's `/api/content/markdown/{id}` path are opaque strings owned by the consuming application's routing layer, not by this ingredient.

## Localization

Almost everything in markdown-core passes author-supplied content through untouched — titles, excerpts, and frontmatter values are derived from the document's own content, and `processMarkdown`'s output HTML carries whatever language the source markdown was written in. The one component-owned, user-visible English string set is `remark-adh-alerts.ts`'s `ALERT_TITLES` map (`Note`, `Tip`, `Important`, `Warning`, `Caution`), emitted verbatim into every alert block's title paragraph regardless of document or consumer locale, with no localization table backing it in source. `MarkdownText.untitled`'s `"Untitled"` fallback and the default fetcher's error messages (a timeout message, a 404 message, a generic HTTP-status message) are likewise hardcoded English with no localization hook. A caller needing localized alert titles, a localized untitled placeholder, or localized fetch-error text must intercept or replace these at a layer above markdown-core.

## Accessibility Options

Not applicable — markdown-core exposes no accessibility-facing options (motion, contrast, text-size, or announcement preferences). The sanitize schema's tag/attribute allowlist is a security boundary, not an accessibility feature, and the accessibility semantics of rendered HTML are owned by the presentation-layer component that hosts it.

## Feature Flags

Not applicable — no source file in this ingredient reads or branches on a feature flag. Fence scanning, frontmatter parsing, title/excerpt derivation, the render pipeline's stage order, the alert transform, and the theme registry's four built-in themes are all unconditional.

## Analytics

Not applicable — no source file in this ingredient emits or references an analytics or telemetry event. `useMarkdownDocument`'s error and timeout states are returned to the caller as data, never reported anywhere.

## Privacy

- **Data collected**: markdown-core touches only the document `content` string a caller supplies (plus the `id`, `ownerKind`, `ownerID`, and timestamps `MarkdownDocument` is constructed with); it derives no new personal data of its own beyond hashing that content (`contentHash`).
- **Storage**: None of these sources persist anything. `MarkdownDocument` is an in-memory value type, and the web hook/pipeline hold no document cache beyond the module-scope shiki highlighter/processor singletons, which store compiled highlighting grammars, not document content.
- **Transmission**: `defaultMarkdownFetcher` sends only the caller-supplied, URL-encoded `id` to `/api/content/markdown/{id}` over `credentials: 'same-origin'`; no other `MarkdownDocument` field is transmitted by this ingredient.
- **Retention**: Not applicable — markdown-core enforces no retention policy of its own. `MarkdownDocument.deletedAt`/`isDeleted` are server-owned soft-delete fields this ingredient reads and writes but does not act on.

## Logging

Not applicable — no source file in this ingredient writes to a log, console, or telemetry sink. `useMarkdownDocument` surfaces failures only through its returned `FetchState`, never via `console.error` or similar.

## Platform Notes

- **Apple (Swift, source platform)**: `FenceScanner`, `Frontmatter`, `YAMLScalar`, `MarkdownDocument`, and `MarkdownText` are Foundation-only and compile into all five of the toolkit's platform frameworks from one source. Every type is `Sendable`; `MarkdownVisibility`, `MarkdownStage`, and `MarkdownOwnerKind` are also `Codable, CaseIterable` string-backed value types, and `MarkdownDocument` itself has no reference semantics anywhere.
- **Web/TypeScript (source platform)**: `useMarkdownDocument`, `document-title.ts`, `process-markdown.ts`, `remark-adh-alerts.ts`, and the theme registry/palette modules are plain functions and one React hook, with no class state. The only module-level mutable state is the two lazy singletons (`getHighlighter()`, `getProcessor()`); they are safe under Node's single-threaded event loop but would need reconsideration (e.g. per-isolate memoization) before running under a worker-pool or multi-isolate runtime.
- **Kotlin/Android (planned, no source yet)**: a port of `Frontmatter`/`YAMLScalar` needs an equivalent conservative-quoting scalar reader/writer, since no bundled YAML dependency is assumed. `FenceScanner`/`MarkdownText`'s three counting units — UTF-16 code units, Unicode scalars, grapheme clusters — map to Kotlin `String` UTF-16 chars, `codePoints()`, and `BreakIterator` respectively; a port must keep them as distinct as the Apple source does, not collapse them to one.
- **C#/Windows (planned, no source yet)**: the same three units map to .NET `string` UTF-16 chars, `System.Globalization.StringInfo`/rune enumeration, and `StringInfo.GetTextElementEnumerator` for grapheme clusters. `Frontmatter.setting`'s duplicate-key normalization and remove-empties-the-block behavior has no direct BCL equivalent and would need to be hand-ported against `FrontmatterTests.swift` line for line.
- **WinUI 3**: Port the four Apple types into a UI-free .NET class library (C#) that the WinUI 3 app references, so no XAML type leaks into the logic. Type mapping: `FenceScanner`/`Frontmatter`/`YAMLScalar`/`MarkdownText` become `static class`es of pure functions; `FrontmatterSplit`, `FenceScanner.Fence`, and `MarkdownClassifiedLine` become `readonly record struct`s; `MarkdownDocument` becomes a `sealed record` with `init`-only server-owned fields (`CurrentVersion`, `LatestVersionId`) and `with`-expression mutation, `Title`/`Excerpt` as computed getters (never stored); `MarkdownVisibility`/`MarkdownStage`/`MarkdownOwnerKind` become C# `enum`s serialized by name through `System.Text.Json`'s `JsonStringEnumConverter` with explicit wire names; `Date` becomes `DateTimeOffset`. String/regex/scanning: `NSRegularExpression` becomes `System.Text.RegularExpressions.Regex` held in `static readonly` fields (or `[GeneratedRegex]` source generators) with `RegexOptions.CultureInvariant` and no `ECMAScript` flag, so `\s`, `[\s\S]*?`, `\A`, and `\z` keep their Unicode meaning — the frontmatter pattern `^---\r?\n([\s\S]*?)\r?\n---[ \t]*\r?\n?` and the number pattern carry over verbatim. `Character.isNewline` splitting has no BCL equivalent: write one splitter that treats `\r\n` as a single terminator and also breaks on `\n`, `\r`, `\v`, `\f`, U+0085, U+2028, and U+2029, and use it for `FenceScanner.classify` and every frontmatter-block line walk; `MarkdownText.lines(of:)` stays a plain `Split('\n')`. UTF-16 title truncation is `string.Substring` with a `char.IsHighSurrogate` check at the cut so a surrogate pair is dropped whole; the 2000-scalar excerpt window counts via `string.EnumerateRunes()`; grapheme work uses `StringInfo.GetTextElementEnumerator`. YAML frontmatter parsing: do not substitute YamlDotNet — port the hand-rolled conservative scalar reader/writer as-is, because a real YAML parser would erase the pinned divergences listed in Design Decisions. `Int(_:radix:)`/`Double(_:)` become `long.TryParse`/`Convert.ToInt64(s, 8|16)`/`double.TryParse` with `CultureInfo.InvariantCulture`, and the `NSNumber` int-versus-double distinction becomes emitting a `long` versus a `double` so an integer still writes as `3`, not `3.0`. `JSONSerialization` with `.sortedKeys, .withoutEscapingSlashes` becomes a `Utf8JsonWriter` over a `SortedDictionary<string, object?>` keyed with `StringComparer.Ordinal` and `JavaScriptEncoder.UnsafeRelaxedJsonEscaping`; CryptoKit `SHA256` becomes `SHA256.HashData(Encoding.UTF8.GetBytes(content))` rendered with `Convert.ToHexStringLower`; `byteLength` is `Encoding.UTF8.GetByteCount`. Keep byte-identical: `prefix + body` reconstructing the input exactly, the five-escape `serialize`/`unquote` pair (including keeping the backslash on unknown escapes), `setting`'s LF-normalized block with untouched body line endings, the canonical `jsonText` output, the lowercase SHA-256 hex, the `"Untitled"` fallback, and the 500/4/160/2000 limits — run the Conformance Test Vectors as an xUnit or MSTest suite against the port. Concurrency: Swift `Sendable` maps to immutability — records with `init`-only properties and stateless static methods are safe on any thread, and the `static readonly` regex fields are initialized once by the CLR thread-safely. The logic is synchronous; a WinUI 3 view model that parses large documents off the UI thread calls it via `Task.Run` and marshals results back through `DispatcherQueue.TryEnqueue` before touching bound properties.

## Design Decisions

- **Decision**: Keep `FenceScanner` (CommonMark-correct, used for rendering) and `MarkdownText.titleSearchBody` (adh's lazy-paired-fence regex, used only for title/excerpt derivation) as two deliberately separate scanners rather than unifying them.
  **Rationale**: The two answer different questions — a renderer must reject false-positive fences the way CommonMark requires, while adh's own title/excerpt derivation is pinned byte-for-byte to a lazy-regex quirk (see MarkdownTextTests "a fenced code block is not a title"). Unifying them would either break renderer correctness or silently move the title column on the next sync with adh's backend.
  **Approved**: pending
- **Decision**: Do not adopt a full YAML parser in the Apple `Frontmatter`/`YAMLScalar` implementation; keep the hand-rolled scalar reader/writer and accept its documented divergences from adh's real parser (block sequences flatten to `null`, flow mappings/block scalars/aliases pass through as literal text, a malformed block still yields readable keys instead of nulling entirely).
  **Rationale**: `FenceScanner`/`Frontmatter` compile into all five platform frameworks from one Foundation-only source; a real YAML parser is a foundation-tier commitment the toolkit has not made. The three MarkdownAdhParityTests DIVERGENCE cases pin the resulting behavior as tested fact rather than leaving it as a silent surprise.
  **Approved**: pending
- **Decision**: Track three separate unit systems across `MarkdownText` — UTF-16 code units for title truncation and JS `.slice()` parity, Unicode scalars for the excerpt source window and Postgres `left()` parity, and grapheme clusters (`Character.isNewline`) for `FenceScanner`'s line splitting — rather than one unit throughout.
  **Rationale**: Each unit mirrors a specific counterpart the Apple port must stay identical with (JavaScript, PostgreSQL, and CommonMark line semantics, respectively); collapsing to one unit would silently break parity with whichever counterpart that unit doesn't match.
  **Approved**: pending
- **Decision**: Rewrite the web `document-title.ts` from a line-regex approach to the real `yaml` package (`parseYaml`/`parseDocument`/`Document`), rather than mirroring the Apple side's hand-rolled scalar approach.
  **Rationale**: A prior line-regex implementation corrupted a folded (`>-`) title scalar on save, and because the backend fails the whole `frontmatter` jsonb column to null on any unparseable YAML, that one bad write silently destroyed `adh_source` and `summary` alongside it. The web package already runs on the Node.js runtime the real `yaml` package targets, so there is no five-platform-portability cost to paying for a real parser there.
  **Approved**: pending
- **Decision**: Run shiki syntax highlighting before `rehype-sanitize` in `process-markdown.ts`'s pipeline, and scope the `style` attribute allowlist to `pre`/`code`/`span` only (leaving `className` allowed globally).
  **Rationale**: Highlighting must run first because it produces real hast element nodes for the sanitizer to filter — sanitizing first would strip the highlighter's own token markup. Scoping `style` to those three tags, rather than allowing it globally, lets shiki's dual-theme CSS variables through while closing the inline-style XSS vector everywhere else; `className` stays allowed globally so structural classes such as `remark-adh-alerts`'s `adh-mv-alert` markup survive sanitization.
  **Approved**: pending
- **Decision**: Look up a viewer theme by `id` in `getThemeById`, falling back to the theme whose id equals `DEFAULT_THEME_ID`, rather than falling back to `VIEWER_THEMES[0]`.
  **Rationale**: A separate no-flash bootstrap script outside these sources also falls back by `DEFAULT_THEME_ID`; a position-based fallback here would diverge from it the moment `VIEWER_THEMES` is reordered, producing a theme flash on reload for an unknown id.
  **Approved**: pending
- **Decision**: Confine every concrete color literal to `palettes.ts` (the "STANDING palette exception"), and keep shiki's own code-block colors out of it entirely.
  **Rationale**: Centralizing color literals in one module lets every other module in the package, and consumers of `registry.ts`, style purely from `--mdv-*` custom properties, with no per-theme branch anywhere else in the render path; shiki's colors are excluded because they come from its own theme files, not this palette.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | passed | security |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | reliability |
| [safe-defaults](agenticdevelopercookbook://compliance/user-safety#safe-defaults) | passed | user-safety |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | internationalization |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | privacy-and-data |

`input-sanitization` passes: `process-markdown.ts`'s `sanitizeSchema` is an explicit tag/attribute/protocol allowlist, runs after highlighting, strips `script`/`style`/`iframe`/`object`/`embed`/`form`, and restricts URL protocols to `http`/`https`/`mailto`/`tel` with no `data:` URIs. `explicit-error-handling` passes: `useMarkdownDocument` and `defaultMarkdownFetcher` model every failure (network error, non-ok response, timeout) as an explicit `FetchState`/thrown `Error` with a resolved message, never a silent `undefined`; `setFrontmatterTitle` and `Frontmatter.parse`/`jsonText` fail soft on malformed input rather than throwing uncaught. `unit-test-coverage` passes: all ten sources are covered by dedicated suites (`FenceScannerTests`, `FrontmatterTests`, `MarkdownTextTests`, `MarkdownDocumentTests`, `MarkdownAdhParityTests` on Apple; `document-title.test.ts`, `fetcher.test.ts`, `registry.test.ts`, `process-markdown.test.ts` on web), well beyond the vectors table's minimum. `separation-of-concerns` passes: rendering (`process-markdown.ts`), frontmatter/title derivation (`Frontmatter`/`MarkdownText`/`document-title.ts`), the document model (`MarkdownDocument`), data fetching (`useMarkdownDocument`), and theme data (`palettes.ts`/`registry.ts`) are independent modules with no circular dependencies between them. `idempotent-operations` passes: `Frontmatter.setting` and `setFrontmatterTitle` both no-op when the requested value already matches, and `Frontmatter.setting`'s duplicate-key normalization is stable under a second write (`FrontmatterTests` "a round trip is idempotent"). `safe-defaults` passes: `MarkdownDocument.new` defaults to `.private`/`.draft`, and `useMarkdownDocument` defaults to a 15-second timeout rather than an unbounded fetch. `unicode-support` passes given the UTF-16/Unicode-scalar/grapheme-cluster triple-unit design documented above and its dedicated surrogate-pair test. `no-hardcoded-strings` is **partial**: `remark-adh-alerts.ts`'s `ALERT_TITLES`, `MarkdownText.untitled`, and the default fetcher's error strings are hardcoded English with no localization hook, as stated in Localization above. `data-minimization` passes: the default fetcher transmits only a document `id`, never the full `MarkdownDocument` payload.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.0.2 | 2026-09-24 | Claude | Added a WinUI 3 Platform Notes bullet with .NET type, regex, line-splitting, YAML-frontmatter, JSON, hashing, byte-identical, and concurrency guidance for a C# port. |
| 1.0.3 | 2026-09-25 | Mike Fullerton | Fixed byte-exact-round-trip/mdc-006/WinUI to prefix+body (block is substring of prefix, not concatenated); stale-response-suppression to show late timeout resolves as success; sanitize-allowlist scoped style-only, className stays global; write-path-never-touches-name allows reading name via deriveDocumentTitle; real-yaml-parser-for-frontmatter notes silent logLevel recovers malformed YAML instead of nulling. |
