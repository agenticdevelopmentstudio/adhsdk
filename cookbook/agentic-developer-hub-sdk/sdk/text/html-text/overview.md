
`HTMLText` is a caseless `enum` of static functions that turns sender-controlled HTML (an HTML-only mail body) into plain text readable in a terminal or by a model, and decodes HTML character references in short strings (Gmail snippets, meta content). It has two public operations:

- `plainText(fromHTML:)` takes a `String` of HTML and returns the text it reads as.
- `decodeEntities(_:)` takes a `String` and returns it with character references decoded, control characters and invisible padding dropped.

It is deliberately small: there is no layout engine and no WebKit (which wants the main thread). The source's own doc comment states the contract: `style`, `script`, `title`, `noscript` and comments are dropped; block elements and `<br>` become line breaks (a paragraph or heading a blank line); every other tag is removed; entities are decoded; whitespace is collapsed as a browser would, keeping line breaks, except inside `<pre>`, which keeps it. The conversion is one linear pass over the input's Unicode scalars, because the HTML is sender-controlled.

`plainText(fromHTML:)` is four stages in a fixed order: `markup` (tags, hidden elements, entities, whitespace collapsing, soft-break markers), `resolveBreaks` (soft-break markers become newlines, list bullets are written), `tidy` (per-line whitespace, blank-line collapsing) and `restorePreformatted` (the spaces and tabs held back inside `<pre>` are put back). The type has no stored state and never throws.

