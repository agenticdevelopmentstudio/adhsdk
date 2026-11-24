
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| markdown-001 | render-markdown, sanitize-output, apply-prose-class | `{ content: "# Hello\n\nWorld" }` | Root `<div class="adh-mv-prose">` containing an `<h1>` whose text content is `Hello` and a `<p>` whose text content is `World`. Comparison ignores whitespace between tags and the `id`/anchor-`<a>` wrapper that rehype-slug and rehype-autolink-headings add to every heading — this normalization applies to every vector below that renders a heading. |
| markdown-002 | accept-optional-class, apply-prose-class | `{ content: "text", className: "custom-override" }` | Root `<div>` class attribute is exactly `"adh-mv-prose custom-override"` |
| markdown-003 | strip-frontmatter | `{ content: "---\nfrontmatter: value\n---\n# Title" }` | `<div class="adh-mv-prose"><h1>Title</h1></div>` — the leading `---…---` block and its contents do not appear anywhere in the output |
| markdown-004 | sanitize-output | `{ content: "<script>alert('xss')</script>" }` | Output contains no `<script` substring and no `on`-prefixed event-handler attribute |
| markdown-005 | highlight-code | `` { content: "```ts\nconst x = 1\n```" } `` | Output contains a `<pre class="shiki …">` element (class list includes `shiki`) whose descendant `<code>`/`<span>` elements carry the highlighted tokens. Comparison ignores the exact token boundaries and the `--shiki-light`/`--shiki-dark` CSS variable values, which are theme data. |
| markdown-006 | strip-frontmatter | `{ content: "# Title\n\n---\n\nMore text" }` | The `---` MUST render as an `<hr>` element between the two paragraphs — it is a thematic break, not frontmatter, because it does not start at position 0 of the content |
| markdown-007 | output-root-div, apply-prose-class | `{ content: "   \n\n  " }` | `<div class="adh-mv-prose"></div>` — an empty root, no error thrown |
| markdown-008 | output-root-div, apply-prose-class | `{ content: "" }` | `<div class="adh-mv-prose"></div>` — an empty root, no error thrown |
| markdown-009 | accept-optional-class | `{ content: "text" }` (no `className`) | Root `<div>` class attribute is exactly `"adh-mv-prose"` — no trailing space, no literal `undefined`/`null` |
| markdown-010 | render-markdown, highlight-code | `{ content: "- a\n  - b\n\n\| A \| B \|\n\|---\|---\|\n\| 1 \| 2 \|\n\n` `` ```js\nconst y = 2\n``` `` `\n\n[link]` `(https://example.com)" }` | Renders without throwing: a nested `<ul>`, a `<table>`, a shiki-highlighted `<pre class="shiki …">`, and an `<a href="https://example.com">` |

