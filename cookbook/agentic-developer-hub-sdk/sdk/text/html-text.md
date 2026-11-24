---
id: 9a4dcb9e-5e7e-479b-922c-37d066a8a18a
title: "HTML Text"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Stateless HTML-to-plain-text reader and HTML entity decoder: one linear pass, hidden elements dropped, breaks and whitespace resolved, control characters stripped."
platforms:
  - swift
  - macos
  - ios
tags:
  - html
  - text
  - entities
  - parsing
  - mail
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# HTML Text

## Overview

`HTMLText` is a caseless `enum` of static functions that turns sender-controlled HTML (an HTML-only mail body) into plain text readable in a terminal or by a model, and decodes HTML character references in short strings (Gmail snippets, meta content). It has two public operations:

- `plainText(fromHTML:)` takes a `String` of HTML and returns the text it reads as.
- `decodeEntities(_:)` takes a `String` and returns it with character references decoded, control characters and invisible padding dropped.

It is deliberately small: there is no layout engine and no WebKit (which wants the main thread). The contract is: `style`, `script`, `title`, `noscript` and comments are dropped; block elements and `<br>` become line breaks (a paragraph or heading a blank line); every other tag is removed; entities are decoded; whitespace is collapsed as a browser would, keeping line breaks, except inside `<pre>`, which keeps it. The conversion is one linear pass over the input's Unicode scalars, because the HTML is sender-controlled.

Informatively, the Swift implementation of `plainText(fromHTML:)` is four stages in a fixed order (ports need not copy this structure; the observable effects are specified in the requirements): `markup` (tags, hidden elements, entities, whitespace collapsing, soft-break markers), `resolveBreaks` (soft-break markers become newlines, list bullets are written), `tidy` (per-line whitespace, blank-line collapsing) and `restorePreformatted` (the spaces and tabs held back inside `<pre>` are put back). The type has no stored state and never throws.

## Behavioral Requirements

### Entry points

- **plain-text-entry**: `HTMLText.plainText(fromHTML:)` MUST accept any `String` and return a `String`, and MUST NOT throw or return an optional.
- **empty-input**: `plainText(fromHTML:)` MUST return the empty string for empty input and for input that produces no visible text (only hidden elements, comments and whitespace).
- **decode-entities-entry**: `HTMLText.decodeEntities(_:)` MUST be public, accept a `String`, return a `String`, and MUST NOT throw.
- **plain-text-no-ampersand**: `decodeEntities(_:)` MUST return text that has no `&` unchanged, except that control characters and invisible padding are still dropped.
- **stateless**: Every operation MUST depend only on its arguments and immutable constants, so concurrent calls from any thread do not interact.
- **stage-order**: The order of processing is not itself part of the contract; its observable effects are. Entities MUST be decoded before whitespace is collapsed (**entity-before-whitespace**), and trailing spaces and tabs in `<pre>` MUST be trimmed only after preformatted content is restored (**pre-trailing-trim**). A port MAY use any internal structure that gives these results.

### Tag recognition

- **tag-start**: A `<` MUST begin a tag only when the next scalar is an ASCII letter, `/`, `!` or `?`; any other `<` (including a `<` that is the last scalar) MUST be kept as literal text.
- **tag-name**: A tag name MUST be read as ASCII letters, digits, `-` and `:`, and MUST be matched case-insensitively (ASCII `A`-`Z` lowercased).
- **tag-attributes**: Attributes MUST be skipped up to the closing `>`, and the tag MAY span lines.
- **quoted-attribute-value**: A quote (`"` or `'`) that follows an `=` (with only whitespace between) MUST open a value that runs to the matching quote, so a `>` inside it does not end the tag.
- **comment**: A comment from `<!--` through the first `-->` that begins after the `<!--` opener (so `<!-->` does not close itself) MUST be removed and replaced by a single space.
- **declaration**: A `<!` or `<?` construct that is not a comment MUST be removed up to the next `>` and produce no output.
- **bogus-close**: `</` followed by a scalar that is not a name scalar (ASCII letter, digit, `-` or `:`) MUST be removed up to the next `>` and produce no output.
- **unterminated-markup**: An unclosed comment, declaration, tag or quoted attribute value MUST end processing, keeping the text read before it and dropping the rest of the input.
- **other-tags-removed**: A tag that is not hidden, a break element, `li`, `td` or `th` MUST be removed, leaving its text content.

### Hidden elements

- **hidden-elements**: The content of `style`, `script`, `title` and `noscript` elements MUST be dropped, from the opening tag through the end of the first matching `</name …>`.
- **hidden-open-space**: An opening hidden tag MUST contribute a single space before its content is skipped.
- **hidden-close-match**: A closing tag MUST match a hidden element only if its name equals the element name (case-insensitively) and is followed by a non-name scalar or the end of input, so `</styles>` does not close `style`.
- **hidden-unclosed**: A hidden element with no matching closing tag MUST drop the rest of the input, keeping the text before it.
- **hidden-stray-close**: A closing hidden tag met outside a hidden element MUST produce no output.
- **hidden-raw-content**: Content inside a hidden element MUST NOT be parsed as markup, so a `</b` or `<p>` inside a script does not end or affect it.

### Line breaks and lists

- **br-break**: `<br>`, `<br/>` and `</br>` MUST each produce a line break (`\n`).
- **paragraph-elements**: Opening and closing tags of `p`, `h1`-`h6`, `blockquote`, `table`, `ul`, `ol`, `dl`, `pre` and `hr` MUST each produce a blank-line break.
- **line-elements**: Opening and closing tags of `div`, `tr`, `li`, `dt`, `dd`, `section`, `article`, `header`, `footer`, `nav`, `aside`, `main`, `address`, `figure`, `figcaption`, `center`, `form` and `fieldset` MUST each produce a single line break.
- **soft-break-merge**: A run of consecutive break-producing tags (with only spaces between) MUST resolve to the largest break in the run, counting the newlines the text already ends with, so `</div><div>` is one line break and a `<br>` followed by `<div>` adds no blank line.
- **break-edges**: Soft breaks at the very start or end of the text MUST be dropped.
- **table-cells**: `td` and `th` tags, opening or closing, MUST each produce a space, so cells of a row read on one line.
- **list-bullet**: An opening `li` MUST produce a `- ` bullet written before the item's first text (after any breaks its block children add), so `<li><p>First</p></li>` reads `- First`.
- **list-bullet-empty**: An `li` with no text MUST write no bullet.

### Whitespace

- **whitespace-collapse**: Outside `<pre>`, any run of space, tab, line feed or carriage return in the source text MUST collapse to one space.
- **nbsp-plain**: A non-breaking space (and any other Unicode space) in the result MUST be treated as whitespace by the tidy stage, becoming a plain space and being trimmed and collapsed like one.
- **line-trim**: Each output line MUST be trimmed and its internal runs of whitespace collapsed to single spaces.
- **blank-line-collapse**: More than one consecutive blank line MUST become one blank line, and blank lines at the start or end MUST be removed.
- **line-endings**: The tidy stage MUST treat `\r\n` and `\r` as line breaks, and the result MUST use `\n` only.

### Preformatted text

- **pre-preserve**: Inside `<pre>`, spaces, tabs and line breaks in the text MUST be kept.
- **pre-first-newline**: A line break immediately after an opening `<pre>` MUST be dropped.
- **pre-line-endings**: `\r\n` and a lone `\r` inside `<pre>` MUST each be one line break.
- **pre-trailing-trim**: Trailing spaces and tabs on each line MUST be trimmed after `<pre>` content is restored; leading ones MUST be kept.
- **pre-depth**: Nested `<pre>` MUST be tracked by depth, an unbalanced `</pre>` MUST NOT go below zero, and an unclosed `<pre>` MUST stay preformatted to the end of the input.
- **pre-decoded-breaks**: An encoded line break (`&#10;`) inside `<pre>` MUST be a line break, and outside `<pre>` MUST be collapsible whitespace.
- **pre-private-use**: Input scalars U+E000 and U+E001 in a text run MUST be dropped, because they are the internal stand-ins for preformatted spaces and tabs.

### Entity decoding

- **entity-named**: A named reference found in the built-in table (`amp`, `lt`, `gt`, `quot`, `apos`, `nbsp`, spacing and joiner entities, typographic punctuation, currency, symbols, arrows, fractions and the accented Latin letters) MUST decode to its character; names are case-sensitive. The full table is under Configuration, Entity Tables.
- **entity-numeric**: A numeric reference, decimal (`&#39;`) or hexadecimal with `x` or `X` (`&#x27;`, `&#X2014;`), MUST decode to its Unicode scalar.
- **entity-numeric-digits**: A numeric reference MUST have 1 to 8 ASCII digits (hex digits for hexadecimal), no sign and no space, and a non-zero value; otherwise it MUST be left as written.
- **entity-invalid-scalar**: A numeric reference whose value is not a valid Unicode scalar MUST be left as written.
- **entity-windows-1252**: A numeric reference from 128 to 159 MUST decode as windows-1252 for the 27 codes that map under Configuration, Entity Tables (for example 146 to a right single quote); the five undefined codes (129, 141, 143, 144, 157) MUST decode to nothing.
- **entity-lookahead**: A reference MUST end at a `;` within 12 scalars after the `&` (so a name or number is at most 11 scalars); an `&` with no `;` in that window MUST be left as written.
- **entity-unknown**: An unknown name, an empty name and any malformed reference MUST be left exactly as written, including the `&` and `;`.
- **entity-single-pass**: Decoding MUST happen once, so `&amp;lt;` yields `&lt;`.
- **entity-scalar-based**: Decoding MUST work on Unicode scalars, so a `;` or `&` followed by a combining mark or joiner still decodes.
- **entity-before-whitespace**: In `plainText(fromHTML:)`, entities MUST be decoded before whitespace is collapsed, so `&#10;` and `&#13;` are whitespace like any other.
- **entity-not-reparsed**: Decoded text MUST NOT be read as markup, so `&lt;b&gt;` appears as the literal `<b>`.
- **entity-attributes-ignored**: Attribute values are part of a removed tag, so entities in them MUST NOT appear in the output.

### Control and invisible characters

- **control-dropped**: C0 controls other than tab, line feed and carriage return, DEL, and C1 controls MUST be dropped, whether raw or produced by a reference, so mail cannot write terminal escape sequences.
- **control-no-marker-forgery**: A raw control character in the input MUST NOT act as a soft-break or bullet marker.
- **invisible-dropped**: Zero-width space (U+200B), word joiner (U+2060), byte order mark (U+FEFF), soft hyphen (U+00AD) and combining grapheme joiner (U+034F) MUST be dropped.
- **joiner-between-visible**: Zero-width non-joiner (U+200C) and joiner (U+200D) MUST be kept only when the previous kept scalar and the next non-invisible, non-control scalar are both non-joiners and non-whitespace; otherwise they MUST be dropped.

### Resource safety

- **linear-time**: Conversion MUST take time linear in the number of input Unicode scalars: a single forward pass in which an unclosed construct ends processing instead of being rescanned. The wall-clock budget used by vector html-text-027 is a detail of that test, not part of the requirement.
- **no-feedback**: The function MUST NOT perform network, file or process access; the output is a pure function of the input string.

## Appearance

Not applicable — this is a text-conversion enum with no visual surface, not a visual component.

## States

Not applicable — this is a stateless conversion enum, not a visual component. Within one call the writer tracks preformatted depth, whether it is at the start of a `<pre>`, and whether the last preformatted scalar was a carriage return; none persists between calls.

## Accessibility

Not applicable — this is a text-conversion enum, not a visual component.

## Conformance Test Vectors

Tests are in `HTMLTextTests` (`packages/apple/AgenticDeveloperHubSDK/SDK/Tests/AgenticDeveloperHubSDKTests/HTMLTextTests.swift`); the named test is the source of each vector's assertion.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| html-text-001 | plain-text-entry, empty-input | `plainText` of `""`; of a document with only a `style` in `head` and a space in `body` (test `emptyOrInvisibleHTMLIsEmpty`) | `""` in both cases |
| html-text-002 | decode-entities-entry, entity-named, entity-numeric | `decodeEntities` of `I&#39;m &lt;here&gt; &amp; &quot;ok&quot;`; of `it&#x27;s &#X2014; &rsquo;&hellip;`; of `a&nbsp;b` (test `decodesNamedAndNumericEntities`) | `I'm <here> & "ok"`; `it's — ’…`; `a` U+00A0 `b` |
| html-text-003 | plain-text-no-ampersand | `decodeEntities("plain words")` (test `plainTextWithoutAmpersandIsUnchanged`) | `plain words` |
| html-text-004 | entity-single-pass | `decodeEntities("&amp;lt;")` (test `decodesOnlyOnce`) | `&lt;` |
| html-text-005 | entity-unknown, entity-numeric-digits, entity-invalid-scalar, entity-lookahead | `decodeEntities` of `AT&T; R&D &bogus; &#; &#xZZ; &#0; &#+65; &#-65; &# 65; &#x+41; &#123456789; 5 & 6; tom&jerry` (test `leavesUnknownAndMalformedReferencesAlone`) | Output equals the input, character for character |
| html-text-006 | entity-windows-1252 | `decodeEntities` of `don&#146;t &#147;quoted&#148; &#128;5&#133;`; of `a&#x92;b` (test `readsTheC1RangeAsWindows1252`) | `don’t “quoted” €5…`; `a’b` |
| html-text-007 | entity-windows-1252 | `decodeEntities("&#129;&#157;x")` (test `dropsControlCharactersSoMailCantDriveTheTerminal`) | `x` |
| html-text-008 | control-dropped | `decodeEntities` of `&#27;[2J&#27;]0;title&#7;done`; of raw ESC `[31mred` BEL and U+009B; of `tab&#9;and&#10;line` (test `dropsControlCharactersSoMailCantDriveTheTerminal`) | `[2J]0;titledone`; `raw[31mred`; `tab` TAB `and` LF `line` |
| html-text-009 | control-dropped, entity-before-whitespace | `plainText("<p>&#27;[2Jhi</p>")` (same test) | `[2Jhi` |
| html-text-010 | invisible-dropped | `decodeEntities("Hi&zwnj;&#847;&#8203; there\u{FEFF}")` (test `dropsInvisiblePaddingCharacters`) | `Hi there` |
| html-text-011 | entity-scalar-based, nbsp-plain | `decodeEntities` of `Preheader&nbsp;` U+034F `&nbsp;` U+034F; `plainText("<p>Sale&nbsp;" U+034F "&nbsp;" U+034F "</p>")` (test `decodesAReferenceFollowedByACombiningMark`) | `Preheader` U+00A0 U+00A0; `Sale` |
| html-text-012 | joiner-between-visible | `decodeEntities` of man-ZWJ-laptop, `👨&zwj;💻`, a Persian word with ZWNJ and `&zwnj;` form (test `keepsJoinersThatJoinVisibleCharacters`) | Joiner kept; the decoded and raw forms are equal to the raw joined sequence |
| html-text-013 | joiner-between-visible | `decodeEntities("&zwnj; &zwnj;&nbsp;Sale\u{200C}")` (same test) | U+0020 U+00A0 `Sale`: every joiner dropped |
| html-text-014 | hidden-elements, comment, hidden-open-space | A document with `title`, `style`, a comment and a `script` around `<p>Visible</p>` (test `htmlDropsHeadStyleScriptAndComments`) | `Visible` |
| html-text-015 | paragraph-elements, line-elements, br-break, whitespace-collapse, entity-numeric | `<p>Hi Mike,</p>`, then `<p>Thanks   for` newline `   applying.<br>We&#39;ll be in touch.<br/>Soon.</p>`, `<div>The Team</div>`, `<div>Acme&nbsp;Inc.</div>` (test `htmlKeepsParagraphsAndLineBreaks`) | `Hi Mike,` blank line `Thanks for applying.` newline `We'll be in touch.` newline `Soon.` blank line `The Team` newline `Acme Inc.` |
| html-text-016 | blank-line-collapse, break-edges, soft-break-merge, line-trim | `<div><div><p>&nbsp;</p><p>One</p></div></div><br><br><br><br><table><tr><td>Two</td></tr></table>` (test `htmlCollapsesBlankLinesAndTrimsLines`) | `One\n\nTwo` |
| html-text-017 | table-cells, list-bullet, line-elements | A two-row table (`td`, `td`; `th`, `td`) then `<ul><li>First</li><li>Second &amp; last</li></ul>` (test `htmlTableCellsAndListItems`) | `Role Engineer\nWhere Remote\n\n- First\n- Second & last` |
| html-text-018 | list-bullet | `<ul><li><p>First</p></li><li><p>Second</p></li></ul>`; `<ol><li><div>One</div></li><li> Two</li></ol>` (test `listItemsWithBlockChildrenKeepTheirBullets`) | `- First\n\n- Second`; `- One\n- Two` |
| html-text-019 | br-break, soft-break-merge | `Line one</br>Line two`; `Line<br> <div>Next</div>`; `Line<br>\n  <p>Para</p>` (test `closingBrIsABreakAndASpaceAfterBrAddsNoBlankLine`) | `Line one\nLine two`; `Line\nNext`; `Line\n\nPara` |
| html-text-020 | other-tags-removed, entity-not-reparsed, entity-attributes-ignored, quoted-attribute-value | `<p>See <a href="https://example.com/x?a=1&amp;b=2">the posting</a> &lt;b&gt;now&lt;/b&gt;</p>` (test `htmlLinksKeepTheirTextAndEscapedTagsSurvive`) | `See the posting <b>now</b>` |
| html-text-021 | tag-name, tag-attributes, hidden-close-match | `<HTML><HEAD><STYLE>` newline `x{}` newline `</STYLE></HEAD><BODY><P` newline `class="a">Up</P><BR>Down</BODY></HTML>` (test `htmlTagsAreCaseInsensitiveAndSpanLines`) | `Up\n\nDown` |
| html-text-022 | tag-start | `<p>I <3 you</p><p><a href=x>link</a></p>` (test `aBareLessThanIsTextAndAQuotedGreaterThanStaysInItsTag`) | `I <3 you\n\nlink` |
| html-text-023 | quoted-attribute-value | `<p>Hi Mike,</p><img alt="Shop now >" width="200"><p>Thanks</p>`; `<p title='a > b'>x < y and y > z</p>` (same test) | `Hi Mike,\n\nThanks`; `x < y and y > z` |
| html-text-024 | control-no-marker-forgery | `plainText("a < b" U+0001 U+0002 " c")` (same test) | `a < b c` |
| html-text-025 | unterminated-markup, hidden-unclosed | `<p>Shown</p><!-- never closed <p>gone</p>`; `<p>Shown</p><style>p{} <p>gone</p>`; `<p>Shown</p><img src="x` (test `anUnclosedCommentTagOrHiddenElementRunsToTheEnd`) | `Shown` for each |
| html-text-026 | hidden-raw-content, hidden-elements | `<script>if (a</b) {}</script>Shown` (same test) | `Shown` |
| html-text-027 | linear-time | Five hostile inputs: 50,000 `<!--`; a `style` plus 50,000 `a{} `; 100,000 `< ` then `<p>end</p>`; 50,000 `<a `; 50,000 `</` (test `hostileHTMLConvertsInLinearTime`) | All five convert in under 5 seconds total; the second yields `x` |
| html-text-028 | pre-preserve | `<pre>step 1 ok\nstep 2 FAILED</pre>` (test `preKeepsItsLineBreaksAndIndentation`) | `step 1 ok\nstep 2 FAILED` |
| html-text-029 | pre-first-newline, pre-line-endings, pre-trailing-trim, pre-decoded-breaks | `<pre>\n  indented\r\n\tTab  \nx&#10;y</pre>` (same test) | `  indented\n\tTab\nx\ny` |
| html-text-030 | pre-preserve, whitespace-collapse, pre-depth | `<p>a   b</p><PRE>x  <b>y</b></PRE><p>c\n d</p>` (same test) | `a b\n\nx  y\n\nc d` |
| html-text-031 | entity-before-whitespace, pre-decoded-breaks | `<p>Thank you for applying.&#13;\nWe will review it&#13;\nand reply.</p>`; `a&#10;&#9;b` (test `encodedLineBreaksAreCollapsibleWhitespace`) | `Thank you for applying. We will review it and reply.`; `a b` |
| html-text-032 | declaration, bogus-close | `<p>A</p><!DOCTYPE html><?xml version="1.0"?></ x><p>B</p>` (derived from `tag(in:at:)`; no test) | `A\n\nB` |
| html-text-033 | pre-depth | `<pre>a</pre></pre><p>b</p>` and `<pre>a  b` (derived from `TextWriter.write(tag:)`; no test) | `a\n\nb`; `a  b` |
| html-text-034 | pre-private-use | `plainText("a" U+E000 "b")` (derived from `TextWriter.write(text:)`; no test) | `ab` |
| html-text-035 | stateless | Two concurrent calls on different strings (derived from the type declaration; no test, unverified) | Each returns the result it returns alone |
| html-text-036 | comment | `a<!--x-->b` (derived from the comment rule; no test) | `a b` |
| html-text-037 | hidden-open-space, hidden-elements | `a<script>x</script>b` (derived; no test) | `a b` |
| html-text-038 | hidden-stray-close | `a</style>b` (derived; no test) | `ab` |
| html-text-039 | list-bullet-empty | `<ul><li></li><li>x</li></ul>` (derived; no test) | `- x` |
| html-text-040 | comment | `a<!-->b-->c` (the comment edge; derived; no test) | `a c` |
| html-text-041 | control-dropped | `a` U+000C `b` (the form feed edge case; derived; no test) | `ab` |
| html-text-042 | entity-scalar-based, entity-unknown | `&am<b>p;` (an entity split by a tag; derived; no test) | `&amp;` as literal text, not decoded |
| html-text-043 | blank-line-collapse | `<pre>a` LF LF LF `b</pre>` (blank lines inside `pre`; derived; no test) | `a\n\nb` |
## Edge Cases

- **Empty and null input** (MUST): `""` returns `""`; a `String` is never nil. An input of only whitespace, comments or hidden elements returns `""` (vectors html-text-001, html-text-014).
- **Bare angle brackets** (MUST): `<` followed by a digit, a space or the end of input is text, and a `>` outside a tag is text (vectors html-text-022, html-text-023).
- **Unclosed constructs** (MUST): An unclosed comment, declaration, tag, quoted attribute or hidden element ends processing; the text before it is kept, the rest is dropped, as in a browser (vector html-text-025).
- **Comment edge** (MUST): The search for `-->` starts after the `<!--` opener, so `<!-->` does not close itself and runs on to a later `-->` or to the end (vector html-text-040).
- **Quote handling** (MUST): A quote only opens a value right after `=`; a quote elsewhere in a tag is ignored, and an unmatched value quote drops the rest of the input.
- **Form feed** (MUST): U+000C is a control, so decoding drops it from text before whitespace collapsing sees it; it never becomes a space in text, although the attribute scanner treats it as whitespace (vector html-text-041).
- **Hostile input size** (MUST): Inputs of 50,000 to 100,000 repeated openers convert in under 5 seconds (vector html-text-027). There is no explicit input-size limit.
- **Entity boundaries** (MUST): Decoding works one text run at a time, so a reference split by a tag (`&am<b>p;`) is not decoded (vector html-text-042).
- **Entity at the lookahead limit** (MUST): A name or number needing more than 11 scalars before `;` is left as written, as is any numeric reference of 9 or more digits (vector html-text-005 covers the 9-digit case; no vector isolates the 11-scalar limit for names).
- **Out-of-range numerics** (MUST): `&#0;`, surrogate code points and values above U+10FFFF are left as written; `&#128;` to `&#159;` map as windows-1252; other controls decode to nothing.
- **Lists without text** (MUST): An `li` with no text writes no bullet, and an `li` whose first child is a block element still gets one bullet before the text.
- **Nested `pre`** (MUST): Depth is counted, so the content stays preformatted until the outer `</pre>`; a stray `</pre>` does nothing.
- **Blank lines in `pre`** (MUST): The tidy stage collapses consecutive empty lines everywhere, including inside `<pre>` (vector html-text-043).
- **Concurrent access**: Not applicable — every function is a static function over its arguments and `let` constants, with no shared mutable state, so there is nothing to interleave.
- **Offline or disconnected state**: Not applicable — the conversion does no I/O.
- **Error states** (MUST): There are none to raise; the functions are total. Malformed markup degrades by being kept as text, left as written or truncated, as listed above.
- **Cancellation and timeouts**: The functions are synchronous with no cancellation or timeout hook; the only bound is the single-pass design.

## Configuration

Nothing is supplied by the caller or the environment: both operations take only their string, and there are no environment variables, settings keys or injected dependencies. The behavior is set by built-in constants, listed below. They are private and are not settings a caller can change.

**Built-in constants**

| Constant | Type | Default | Description |
|--------|------|---------|-------------|
| `hidden` | `Set<String>` | `style`, `script`, `title`, `noscript` | Elements whose content is dropped |
| `paragraphElements` | `Set<String>` | `p`, `h1`-`h6`, `blockquote`, `table`, `ul`, `ol`, `dl`, `pre`, `hr` | Elements that produce a blank-line break |
| `lineElements` | `Set<String>` | `div`, `tr`, `li`, `dt`, `dd`, `section`, `article`, `header`, `footer`, `nav`, `aside`, `main`, `address`, `figure`, `figcaption`, `center`, `form`, `fieldset` | Elements that produce a single line break |
| `named` | `[String: String]` | 77 entries (listed under Entity Tables in this section) | Named references that decode |
| `windows1252` | `[UInt32: Character]` | 27 entries (listed under Entity Tables in this section) | Characters shown for `&#128;` to `&#159;` |
| `invisible` | `Set<Unicode.Scalar>` | U+200B, U+2060, U+FEFF, U+00AD, U+034F | Scalars always dropped |
| `joiners` | `Set<Unicode.Scalar>` | U+200C, U+200D | Scalars kept only between two visible scalars |
| marker scalars | `Unicode.Scalar` | U+0001, U+0002, U+0003; U+E000, U+E001 | Internal soft-break, paragraph-break and bullet markers; stand-ins for preformatted space and tab |
| reference window | `Int` | 12 scalars after `&` | How far to look for the `;` |
| numeric digits | `ClosedRange<Int>` | 1 to 8 | Digits allowed in a numeric reference |

### Entity Tables

Both tables are built-in and complete: a reference not listed here is unknown and is left as written. Names are case-sensitive.

#### Named references (77)

| Name | Decodes to | Scalar |
|------|-----------|--------|
| `amp` | `&` | U+0026 |
| `lt` | `<` | U+003C |
| `gt` | `>` | U+003E |
| `quot` | `"` | U+0022 |
| `apos` | `'` | U+0027 |
| `nbsp` | (space or invisible) | U+00A0 |
| `ensp` | (space or invisible) | U+2002 |
| `emsp` | (space or invisible) | U+2003 |
| `thinsp` | (space or invisible) | U+2009 |
| `zwnj` | (space or invisible) | U+200C |
| `zwj` | (space or invisible) | U+200D |
| `shy` | (space or invisible) | U+00AD |
| `ndash` | – | U+2013 |
| `mdash` | — | U+2014 |
| `hellip` | … | U+2026 |
| `bull` | • | U+2022 |
| `middot` | · | U+00B7 |
| `lsquo` | ‘ | U+2018 |
| `rsquo` | ’ | U+2019 |
| `sbquo` | ‚ | U+201A |
| `ldquo` | “ | U+201C |
| `rdquo` | ” | U+201D |
| `bdquo` | „ | U+201E |
| `laquo` | « | U+00AB |
| `raquo` | » | U+00BB |
| `lsaquo` | ‹ | U+2039 |
| `rsaquo` | › | U+203A |
| `copy` | © | U+00A9 |
| `reg` | ® | U+00AE |
| `trade` | ™ | U+2122 |
| `deg` | ° | U+00B0 |
| `plusmn` | ± | U+00B1 |
| `times` | × | U+00D7 |
| `divide` | ÷ | U+00F7 |
| `euro` | € | U+20AC |
| `pound` | £ | U+00A3 |
| `cent` | ¢ | U+00A2 |
| `yen` | ¥ | U+00A5 |
| `sect` | § | U+00A7 |
| `para` | ¶ | U+00B6 |
| `dagger` | † | U+2020 |
| `Dagger` | ‡ | U+2021 |
| `prime` | ′ | U+2032 |
| `Prime` | ″ | U+2033 |
| `larr` | ← | U+2190 |
| `rarr` | → | U+2192 |
| `uarr` | ↑ | U+2191 |
| `darr` | ↓ | U+2193 |
| `frac12` | ½ | U+00BD |
| `frac14` | ¼ | U+00BC |
| `frac34` | ¾ | U+00BE |
| `iexcl` | ¡ | U+00A1 |
| `iquest` | ¿ | U+00BF |
| `aacute` | á | U+00E1 |
| `eacute` | é | U+00E9 |
| `iacute` | í | U+00ED |
| `oacute` | ó | U+00F3 |
| `uacute` | ú | U+00FA |
| `Aacute` | Á | U+00C1 |
| `Eacute` | É | U+00C9 |
| `Iacute` | Í | U+00CD |
| `Oacute` | Ó | U+00D3 |
| `Uacute` | Ú | U+00DA |
| `agrave` | à | U+00E0 |
| `egrave` | è | U+00E8 |
| `ograve` | ò | U+00F2 |
| `auml` | ä | U+00E4 |
| `euml` | ë | U+00EB |
| `ouml` | ö | U+00F6 |
| `uuml` | ü | U+00FC |
| `Auml` | Ä | U+00C4 |
| `Ouml` | Ö | U+00D6 |
| `Uuml` | Ü | U+00DC |
| `ntilde` | ñ | U+00F1 |
| `Ntilde` | Ñ | U+00D1 |
| `ccedil` | ç | U+00E7 |
| `szlig` | ß | U+00DF |

#### windows-1252 numeric references 128 to 159 (27)

The five codes 129, 141, 143, 144 and 157 are undefined and decode to nothing.

| Code | Decodes to | Scalar |
|------|-----------|--------|
| 128 (0x80) | € | U+20AC |
| 130 (0x82) | ‚ | U+201A |
| 131 (0x83) | ƒ | U+0192 |
| 132 (0x84) | „ | U+201E |
| 133 (0x85) | … | U+2026 |
| 134 (0x86) | † | U+2020 |
| 135 (0x87) | ‡ | U+2021 |
| 136 (0x88) | ˆ | U+02C6 |
| 137 (0x89) | ‰ | U+2030 |
| 138 (0x8A) | Š | U+0160 |
| 139 (0x8B) | ‹ | U+2039 |
| 140 (0x8C) | Œ | U+0152 |
| 142 (0x8E) | Ž | U+017D |
| 145 (0x91) | ‘ | U+2018 |
| 146 (0x92) | ’ | U+2019 |
| 147 (0x93) | “ | U+201C |
| 148 (0x94) | ” | U+201D |
| 149 (0x95) | • | U+2022 |
| 150 (0x96) | – | U+2013 |
| 151 (0x97) | — | U+2014 |
| 152 (0x98) | ˜ | U+02DC |
| 153 (0x99) | ™ | U+2122 |
| 154 (0x9A) | š | U+0161 |
| 155 (0x9B) | › | U+203A |
| 156 (0x9C) | œ | U+0153 |
| 158 (0x9E) | ž | U+017E |
| 159 (0x9F) | Ÿ | U+0178 |
## Deep Linking

Not applicable: `HTMLText` reads strings and has no URL scheme or route; links in the HTML are removed with their tags and only the link text is kept.

## Localization

Not applicable: the only literal the code writes is the ASCII list bullet `- ` and line breaks, which are part of the output format; there are no user-facing messages, so no string table exists.

## Accessibility Options

Not applicable: this is a text-conversion enum with no motion, contrast or color, so it responds to none of Reduce Motion, Increase Contrast or Differentiate Without Color.

## Feature Flags

Not applicable: the source reads no flags or settings; behavior is fixed by constants.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the conversion works on a string in memory and returns a string; it reads, stores, logs and transmits nothing, so any retention or transmission of the mail text belongs to its callers.

## Logging

Not applicable: the source contains no log calls.

## Platform Notes

- **SwiftUI**: The Swift implementation is a Foundation-only file with no UI import, so SwiftUI code calls it directly and shows the result in `Text`. Run it off the main thread for large bodies; it needs no actor. Use it instead of `AttributedString(html:)` or `NSAttributedString` HTML import, which go through WebKit and want the main thread.
- **Compose**: Port as a Kotlin `object` with pure functions over `String`. Walk code points (`String.codePointAt`, `Character.charCount`), not UTF-16 chars, because the source works on Unicode scalars and the 12-scalar entity window counts scalars. Use `StringBuilder` for output and `Set<String>` constants. Avoid `Html.fromHtml`, which builds a styled span tree and keeps links and layout. Display with a `Text` composable.
- **React/Web**: Port as a TypeScript module of two functions. Iterate with `for...of` or `codePointAt` so astral characters (emoji with joiners) count as one scalar. Do not use `DOMParser` or `innerHTML`: they parse more than this contract does, and running them on mail HTML is the risk this file avoids. The hand-written pass is single-threaded, so there is no ordering concern.
- **AppKit / UIKit**: Same Swift file on macOS and iOS; it uses `Unicode.Scalar`, `String.UnicodeScalarView`, `CharacterSet.whitespaces` and `components(separatedBy:)` from Foundation. `CharacterSet.whitespaces` is what turns non-breaking and other Unicode spaces into plain ones in the tidy stage, so a port needs an equivalent Zs-category and tab test. Bridge to `NSTextField` or `UITextView` as plain text, not as attributed text.
- **WinUI 3**: Port as a `static class HtmlText` with `PlainText(string html)` and `DecodeEntities(string text)`. Enumerate scalars with `string.EnumerateRunes()` (`System.Text.Rune`), not `char`, to match Unicode scalar semantics; `Rune.IsWhiteSpace` and `System.Globalization.UnicodeCategory.SpaceSeparator` stand in for `CharacterSet.whitespaces`. Build output with `StringBuilder`, and hold the tables as `HashSet<string>`, `FrozenDictionary<string, string>` and `Dictionary<uint, string>`. Replace the private-use and control-character markers (U+E000, U+E001, U+0001 to U+0003) with the same scalars, since `StringBuilder` accepts them. Parse numeric references with `uint.TryParse(…, NumberStyles.HexNumber, CultureInfo.InvariantCulture, …)` after checking digits yourself; `uint.TryParse` accepts signs and spaces that the contract rejects. The functions need no `Task` or `async` (they are CPU-bound and pure), so call from `Task.Run` in a view-model for large bodies. Show the result in a `TextBlock` with `IsTextSelectionEnabled="True"`; do not use `RichTextBlock` or a `WebView2` to read the HTML.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/Sources/Text/HTMLText.swift` | confirmed (1.0.1) |

## Design Decisions

**Decision**: Convert with a hand-written single pass over Unicode scalars, with no layout engine, no WebKit and no regular expressions.
**Rationale**: The HTML is sender-controlled, so the conversion must be linear in the input and nothing may be rescanned; WebKit wants the main thread. A test bounds hostile inputs to 5 seconds.
**Approved**: pending

**Decision**: An unclosed comment, tag, quoted value or hidden element drops the rest of the input.
**Rationale**: A browser treats an unclosed construct as running to the end of the input; stopping also avoids rescanning, which keeps the pass linear.
**Approved**: pending

**Decision**: Breaks are carried as control-character markers (U+0001 line, U+0002 paragraph, U+0003 bullet) and resolved after the whole text is read.
**Rationale**: Soft breaks must merge with their neighbours (`</div><div>` is one break) and a bullet must follow the breaks block children add. Decoding drops raw controls first, so mail cannot forge a marker (test `aBareLessThanIsTextAndAQuotedGreaterThanStaysInItsTag`).
**Approved**: pending

**Decision**: Spaces and tabs inside `<pre>` are held as private-use stand-ins (U+E000, U+E001) until the tidy stage is done.
**Rationale**: The tidy stage collapses and trims whitespace on every line; stand-ins that are neither whitespace nor controls survive it. The cost, a quirk, is that a literal U+E000 or U+E001 in the input is dropped.
**Approved**: pending

**Decision**: `decodeEntities` decodes only a built-in list of named references plus all numeric ones, looks 12 scalars ahead for the `;`, and leaves anything else as written.
**Rationale**: Names and numbers are short, and looking further only finds the next sentence's `;`; leaving unknown references untouched keeps text such as `AT&T;` intact.
**Approved**: pending

**Decision**: Numeric references 128 to 159 decode as windows-1252.
**Rationale**: Browsers show these characters, and Word and Outlook meant them; the five undefined codes stay controls and are dropped.
**Approved**: pending

**Decision**: Control characters are dropped from decoded text and from raw text.
**Rationale**: Dropping them stops mail writing terminal escape sequences; tab and line breaks are kept because they are whitespace.
**Approved**: pending

**Decision**: Zero-width non-joiner and joiner are kept only between two visible, non-joiner scalars; the other invisible characters are always dropped.
**Rationale**: Joiners shape emoji sequences and Persian and Indic words, while marketing mail fills preview text with them.
**Approved**: pending

**Decision**: Entities are decoded on each text run before whitespace is collapsed, and decoded text is not reparsed.
**Rationale**: `&#10;` is then whitespace like any other (a line break only inside `<pre>`), and `&lt;b&gt;` is shown as `<b>`, as a browser shows it (tests `encodedLineBreaksAreCollapsibleWhitespace`, `htmlLinksKeepTheirTextAndEscapedTagsSurvive`).
**Approved**: pending

**Decision**: Table cells produce a space, rows a line break and `table` a blank line; list items are written as `- ` regardless of `ul` or `ol`.
**Rationale**: Keeps a row on one line in a terminal; the source has no numbering, so ordered lists read as bullets (test `listItemsWithBlockChildrenKeepTheirBullets`).
**Approved**: pending

**Decision**: Truncated or malformed markup degrades silently: the caller gets the text read so far, or the reference left as written, and no error or flag.
**Rationale**: Mail bodies are routinely malformed, and a browser shows them anyway; the output is read by a person or a model, which can use partial text, and an error channel would force every caller to handle a case that has no better answer than the partial text. The cost is that a caller cannot tell truncation happened, which is why `explicit-error-handling` is `partial` in Compliance.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | security |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | internationalization |
| [adc.check.performance.resource-efficiency](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d5fe7b8e-1051-5581-b2c5-1adae8fdd5fc) | passed | performance |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |

`HTMLText` is one pure type with two entry points and private helpers per stage (tags, writer, breaks, entities, whitespace), no I/O and no state, which is separation of concerns. `HTMLTextTests` covers entity decoding, control and invisible characters, every tag family, `pre`, unterminated constructs and hostile-input timing; a few behaviors (declarations, bogus close tags, unbalanced `pre`, private-use input, stray hidden close tags, empty list items, the comment edge, form feed, entities split by a tag, blank lines inside `pre`) have no test, so coverage is strong but not complete. The input is sanitized for terminal use by dropping control characters and for resource use by the single pass. The result is partial for explicit error handling because the functions have no error channel: malformed markup is silently truncated or left as written, and the caller cannot tell it happened (an accepted trade-off; see Design Decisions).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Listed the 77 named entities and 27 windows-1252 mappings, recast stage-order and linear-time as observable requirements, removed source-comment citations, added a silent-degradation Design Decision, added vectors html-text-036 to 043, and dropped the logic tag and the source path. |
