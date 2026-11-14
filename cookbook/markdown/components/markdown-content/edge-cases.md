
- **Empty content**: When `content` is an empty string, the component MUST render an empty `<div class="adh-mv-prose"></div>` (markdown-008).
- **Whitespace-only content**: When `content` contains only whitespace, the component MUST render the same empty `<div class="adh-mv-prose"></div>`, with no error thrown (markdown-007).
- **Complex markdown**: Nested lists, tables, code blocks, inline code, and links MUST all be processed and rendered without error (markdown-010).
- **Missing className prop**: When `className` is not provided or undefined, the component MUST render with only the `adh-mv-prose` class (no undefined or null appended) (markdown-009).
- **Unclosed leading `---`**: A document that opens with `---` at position 0 but has no later line starting with `---` (for example `"---\n\nIntro paragraph.\n\nMore text"`) has no frontmatter block, because the frontmatter pattern needs both fences. Nothing is stripped, and the whole document renders as ordinary markdown: a thematic break (`<hr>`) followed by the two paragraphs (markdown-012).
- **Malformed frontmatter YAML**: A closed leading `---` block whose contents do not parse as YAML (for example `"---\ntitle: [unclosed\n---\n# Body"`) is still stripped from the body, yields no frontmatter data, and does not throw. The body renders normally (markdown-013).
- **Raw HTML dropped**: Raw HTML in the markdown source, inline or block (`<details>`, `<kbd>`, `<br>`, `<script>`), is removed rather than rendered, because remark-rehype runs with `allowDangerousHtml: false`. Only the text of the surrounding markdown is rendered (markdown-004, markdown-014).
- **Pipeline failure**: When the pipeline rejects (for example the highlighter fails to initialize), the component MUST let the rejection propagate unchanged (markdown-015).

