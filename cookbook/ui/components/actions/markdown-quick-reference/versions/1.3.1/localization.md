
Known gap, not "not applicable": the component hard-codes every user-facing
string — the `"Markdown quick reference"` title/aria-label, the `"Markdown"`
default trigger text, and all nine `MARKDOWN_SYNTAX` row labels — with no
locale-sensitive formatting per source. The underlying `SyntaxQuickReference`
shell already accepts `title` and `ariaLabel` as props, but
`MarkdownQuickReference` does not forward them as its own props, so a
consumer has no way to localize this ingredient without editing it.

