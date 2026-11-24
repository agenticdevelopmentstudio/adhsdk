
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

