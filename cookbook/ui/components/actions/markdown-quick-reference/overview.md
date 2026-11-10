
A standalone toolbar control in `@adh-sdk/ui`
(`components/markdown-quick-reference`). It is a thin wrapper that passes a
fixed `MARKDOWN_SYNTAX` list into the shared `SyntaxQuickReference` shell
(`components/quick-reference`) — the same shell the ink editor's quick
reference uses. `SyntaxQuickReference` renders the outline `Button` trigger
and the dismissible `Popover` listing the common GitHub-flavoured markdown
syntax — headings, bold/italic, inline + fenced code, bullet/numbered lists,
links, and blockquote.

Because `SyntaxQuickReference` is built on the shared `Popover` primitive, the
control inherits outside-click and Escape dismissal plus focus restore to the
trigger. It is wired into the `MarkdownEditor` toolbar by default, but is
exported on its own so any editor toolbar can drop it in. It holds no state of
its own and takes no value.

