
- **Empty content**: When `content` is an empty string, the component MUST render an empty `<div class="adh-mv-prose"></div>` (markdown-008).
- **Whitespace-only content**: When `content` contains only whitespace, the component MUST render the same empty `<div class="adh-mv-prose"></div>`, with no error thrown (markdown-007).
- **Complex markdown**: Nested lists, tables, code blocks, inline code, and links MUST all be processed and rendered without error (markdown-010).
- **Missing className prop**: When `className` is not provided or undefined, the component MUST render with only the `adh-mv-prose` class (no undefined or null appended) (markdown-009).
- **Unclosed leading `---`**: A document that opens with `---` at position 0 but has no later line starting with `---` (for example `"---\n\nIntro paragraph.\n\nMore text"`) is NOT a thematic break followed by paragraphs — the frontmatter parser consumes the whole remainder as the frontmatter block. If that remainder parses as YAML, the component renders an empty `<div class="adh-mv-prose"></div>` and the document body is silently dropped; if it does not parse as YAML (for example the remainder starts with `*emphasis*`, or uses Pandoc-style metadata closed by `...`), the parse failure MUST propagate per **propagate-render-errors** instead of rendering partial output.

