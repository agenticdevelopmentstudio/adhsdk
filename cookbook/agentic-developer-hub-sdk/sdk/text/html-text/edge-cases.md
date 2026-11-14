
- **Empty and null input** (MUST): `""` returns `""`; a `String` is never nil. An input of only whitespace, comments or hidden elements returns `""` (vectors html-text-001, html-text-014).
- **Bare angle brackets** (MUST): `<` followed by a digit, a space or the end of input is text, and a `>` outside a tag is text (vectors html-text-022, html-text-023).
- **Unclosed constructs** (MUST): An unclosed comment, declaration, tag, quoted attribute or hidden element ends processing; the text before it is kept, the rest is dropped, as in a browser (vector html-text-025).
- **Comment edge** (MUST): The search for `-->` starts after the `<!--` opener, so `<!-->` does not close itself and runs on to a later `-->` or to the end.
- **Quote handling** (MUST): A quote only opens a value right after `=`; a quote elsewhere in a tag is ignored, and an unmatched value quote drops the rest of the input.
- **Form feed** (MUST): U+000C is a control, so decoding drops it from text before whitespace collapsing sees it; it never becomes a space in text, although the attribute scanner treats it as whitespace.
- **Hostile input size** (MUST): Inputs of 50,000 to 100,000 repeated openers convert in under 5 seconds (vector html-text-027). There is no explicit input-size limit.
- **Entity boundaries** (MUST): Decoding works one text run at a time, so a reference split by a tag (`&am<b>p;`) is not decoded.
- **Entity at the lookahead limit** (MUST): A name or number needing more than 11 scalars before `;` is left as written, as is any numeric reference of 9 or more digits.
- **Out-of-range numerics** (MUST): `&#0;`, surrogate code points and values above U+10FFFF are left as written; `&#128;` to `&#159;` map as windows-1252; other controls decode to nothing.
- **Lists without text** (MUST): An `li` with no text writes no bullet, and an `li` whose first child is a block element still gets one bullet before the text.
- **Nested `pre`** (MUST): Depth is counted, so the content stays preformatted until the outer `</pre>`; a stray `</pre>` does nothing.
- **Blank lines in `pre`** (MUST): The tidy stage collapses consecutive empty lines everywhere, including inside `<pre>`.
- **Concurrent access**: Not applicable — every function is a static function over its arguments and `let` constants, with no shared mutable state, so there is nothing to interleave.
- **Offline or disconnected state**: Not applicable — the conversion does no I/O.
- **Error states** (MUST): There are none to raise; the functions are total. Malformed markup degrades by being kept as text, left as written or truncated, as listed above.
- **Cancellation and timeouts**: The functions are synchronous with no cancellation or timeout hook; the only bound is the single-pass design.

