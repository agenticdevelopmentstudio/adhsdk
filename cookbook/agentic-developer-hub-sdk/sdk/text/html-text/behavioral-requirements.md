
### Entry points

- **plain-text-entry**: `HTMLText.plainText(fromHTML:)` MUST accept any `String` and return a `String`, and MUST NOT throw or return an optional.
- **empty-input**: `plainText(fromHTML:)` MUST return the empty string for empty input and for input that produces no visible text (only hidden elements, comments and whitespace).
- **decode-entities-entry**: `HTMLText.decodeEntities(_:)` MUST be public, accept a `String`, return a `String`, and MUST NOT throw.
- **plain-text-no-ampersand**: `decodeEntities(_:)` MUST return text that has no `&` unchanged, except that control characters and invisible padding are still dropped.
- **stateless**: Every operation MUST depend only on its arguments and immutable constants, so concurrent calls from any thread do not interact.
- **stage-order**: `plainText(fromHTML:)` MUST apply, in this order, tag and entity processing, break resolution, whitespace tidying, and restoration of preformatted spaces and tabs.

### Tag recognition

- **tag-start**: A `<` MUST begin a tag only when the next scalar is an ASCII letter, `/`, `!` or `?`; any other `<` (including a `<` that is the last scalar) MUST be kept as literal text.
- **tag-name**: A tag name MUST be read as ASCII letters, digits, `-` and `:`, and MUST be matched case-insensitively (ASCII `A`-`Z` lowercased).
- **tag-attributes**: Attributes MUST be skipped up to the closing `>`, and the tag MAY span lines.
- **quoted-attribute-value**: A quote (`"` or `'`) that follows an `=` (with only whitespace between) MUST open a value that runs to the matching quote, so a `>` inside it does not end the tag.
- **comment**: A comment from `<!--` through the first `-->` that starts at or after the third scalar of the comment body MUST be removed and replaced by a single space.
- **declaration**: A `<!` or `<?` construct that is not a comment MUST be removed up to the next `>` and produce no output.
- **bogus-close**: `</` followed by a scalar that cannot start a name MUST be removed up to the next `>` and produce no output.
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

- **entity-named**: A named reference found in the built-in table (`amp`, `lt`, `gt`, `quot`, `apos`, `nbsp`, spacing and joiner entities, typographic punctuation, currency, symbols, arrows, fractions and the listed accented Latin letters) MUST decode to its character; names are case-sensitive.
- **entity-numeric**: A numeric reference, decimal (`&#39;`) or hexadecimal with `x` or `X` (`&#x27;`, `&#X2014;`), MUST decode to its Unicode scalar.
- **entity-numeric-digits**: A numeric reference MUST have 1 to 8 ASCII digits (hex digits for hexadecimal), no sign and no space, and a non-zero value; otherwise it MUST be left as written.
- **entity-invalid-scalar**: A numeric reference whose value is not a valid Unicode scalar MUST be left as written.
- **entity-windows-1252**: A numeric reference from 128 to 159 MUST decode as windows-1252 for the 27 codes that map (for example 146 to a right single quote); the five undefined codes (129, 141, 143, 144, 157) MUST decode to nothing.
- **entity-lookahead**: A reference MUST end at a `;` within 11 scalars after the `&`; an `&` with no `;` in that window MUST be left as written.
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

- **linear-time**: Conversion MUST make a single forward pass in which an unclosed construct ends processing instead of being rescanned; the test suite bounds five hostile 50,000 to 100,000 repetition inputs to under 5 seconds in total.
- **no-feedback**: The function MUST NOT perform network, file or process access; the output is a pure function of the input string.

