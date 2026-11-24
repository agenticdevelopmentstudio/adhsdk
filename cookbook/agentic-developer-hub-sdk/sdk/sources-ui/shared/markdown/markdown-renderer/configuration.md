
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `highlighter` | `(CodeHighlighter)?` / `undefined` | `nil` / not provided | (Apple) Optional injected syntax highlighter for fenced code blocks. If nil, code blocks render in unstyled monospaced font. (Web) Shiki highlighter is hard-wired internally; no configuration exposed. |
| `palette` | `SemanticPalette` | Required | (Apple) Semantic color and font palette providing platform-appropriate styling. |
| `textColor` | `PlatformColor` | Required | (Apple) Base text color for the rendered output. |
| `content` | `string` | Required | (Web) Raw markdown string (frontmatter stripped by component). |

