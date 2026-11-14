
| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `content` | string | Yes | — | Raw markdown string. A leading YAML frontmatter block (`---` at the very start of the string through the matching closing `---`) is stripped before processing; a `---` appearing later, after a blank line, is an ordinary thematic break and renders as `<hr>`. A leading `---` with no matching closing `---` is instead treated as an unterminated frontmatter block that consumes the rest of the document (see **strip-frontmatter**, Edge Cases). |
| `className` | string | No | undefined | Additional CSS class(es) appended to the root `<div>` class list (see **accept-optional-class**). |

