
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
