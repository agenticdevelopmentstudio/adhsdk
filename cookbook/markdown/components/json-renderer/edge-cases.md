
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

