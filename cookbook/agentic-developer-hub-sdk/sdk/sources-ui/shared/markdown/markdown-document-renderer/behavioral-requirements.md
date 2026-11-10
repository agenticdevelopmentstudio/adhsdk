
- **accept-markdown-string**: Component MUST accept a markdown string as input.
- **accept-semantic-palette**: Component MUST accept a `SemanticPalette` used to resolve the foreground color for each alert's role and for other themed runs.
- **accept-text-color**: Component MUST accept a base `PlatformColor` applied as the foreground color of non-alert rendered text.
- **remove-frontmatter**: Component MUST strip YAML frontmatter from the beginning of the document before rendering (content between leading `---` delimiter and closing `---`).
- **detect-alert-blockquotes**: Component MUST detect GitHub alert blockquotes formatted as `> [!TYPE]` where TYPE is one of: NOTE, TIP, IMPORTANT, WARNING, or CAUTION. Detection MUST occur on the source string before markdown parsing, not on the rendered output.
- **require-alert-tag-on-first-line**: Alert blockquotes MUST have the tag (`[!TYPE]`) alone on the first line of the quote block. Tags appearing on subsequent lines or in continuation quotes MUST NOT trigger alert styling.
- **color-alerts-by-role**: Detected alerts MUST be colored according to their mapped semantic role: NOTE→info, TIP→success, IMPORTANT→accent, WARNING→warning, CAUTION→danger.
- **preserve-alert-styling-across-blockquote**: Alert coloring MUST apply to the entire blockquote block, including all lines the blockquote contains, not just until the first blank line.
- **replace-alert-tag-with-label**: The `[!TYPE]` tag MUST be removed from the rendered output and replaced by the alert's uppercase label (NOTE, TIP, IMPORTANT, WARNING, CAUTION), inheriting the alert's color.
- **render-task-list-unchecked**: Unchecked task list items formatted as `- [ ]` in GFM MUST be rendered with a Unicode open checkbox character (U+2610, ☐).
- **render-task-list-checked**: Checked task list items formatted as `- [x]` or `- [X]` in GFM MUST be rendered with a Unicode ballot box with check character (U+2611, ☑).
- **collapse-task-list-bullet**: After rendering, the bullet/tab/checkbox sequence a task-list item inherits from ordinary list rendering (bullet, tab, checkbox, non-breaking space) MUST be collapsed to the checkbox followed by a plain tab, matching the layout of other list markers.
- **exclude-fenced-code-from-processing**: Lines within fenced code blocks MUST NOT be processed for alert detection, task list rewriting, or quote line hardening.
- **normalize-line-endings**: Line endings MUST be normalized to LF (U+000A) in the rendered output. CRLF line endings in source MUST be converted.
- **harden-blockquote-breaks**: A consecutive blockquote line MUST have a trailing two-space hard break appended so its line separation from the next blockquote line survives rendering, unless the line already ends in a hard break (a trailing backslash or two or more trailing spaces).
- **accept-optional-highlighter**: Component MUST accept an optional code highlighter instance for syntax highlighting in fenced code blocks and MUST NOT require one.
- **return-attributed-string**: Component MUST return an `NSAttributedString` with all formatting applied (colors, typography, emphasis).

