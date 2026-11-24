
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mdr-001 | remove-frontmatter | `"---\ntitle: Test\n---\n# Heading"` | Rendered output text begins with "Heading"; no frontmatter delimiters or YAML content appear in the output. |
| mdr-002 | detect-alert-blockquotes | `"> [!NOTE]\n> This is a note"` | The literal `[!NOTE]` tag does not appear in the output; the blockquote's rendered range has `.foregroundColor` equal to `palette.platformColor(.info)`. |
| mdr-003 | color-alerts-by-role | `"> [!WARNING]\n> Danger"` | The blockquote's rendered range has `.foregroundColor` equal to `palette.platformColor(.warning)`. |
| mdr-004 | color-alerts-by-role | `"> [!TIP]\n> Good idea"` | The blockquote's rendered range has `.foregroundColor` equal to `palette.platformColor(.success)`. |
| mdr-005 | require-alert-tag-on-first-line | `"> Regular quote\n> [!NOTE]"` | No `.foregroundColor` alert styling is applied anywhere in the output; the literal text `[!NOTE]` appears unchanged. |
| mdr-006 | preserve-alert-styling-across-blockquote | `"> [!CAUTION]\n> Line 1\n> Line 2\n> Line 3"` | `.foregroundColor` equals `palette.platformColor(.danger)` across the full rendered range of all three lines, not just the first. |
| mdr-007 | render-task-list-unchecked | `"- [ ] Unchecked task"` | Rendered output text contains "☐" immediately before "Unchecked task". |
| mdr-008 | render-task-list-checked | `"- [x] Completed task"` | Rendered output text contains "☑" immediately before "Completed task" (lowercase `x`). |
| mdr-009 | render-task-list-checked | `"- [X] Completed task"` | Rendered output text contains "☑" immediately before "Completed task" (uppercase `X`). |
| mdr-010 | exclude-fenced-code-from-processing | `` "```\n> [!NOTE]\n```" `` | The rendered output contains the literal text `> [!NOTE]`; no `.foregroundColor` alert styling is applied. |
| mdr-011 | harden-blockquote-breaks | `"> Line 1\n> Line 2"` | Rendered output preserves "Line 1" and "Line 2" as two separate lines (a literal line break appears between them) — the effect of a two-space hard break inserted on the source's first line. |
| mdr-012 | normalize-line-endings | `"Heading\r\nParagraph"` (CRLF input) | Rendered output string contains no `\r` characters. |
| mdr-013 | accept-optional-highlighter | Component initialized without a highlighter | Rendering succeeds; fenced code block text carries no syntax-highlighting attributes. |
| mdr-014 | accept-optional-highlighter | Component initialized with a highlighter | Fenced code block text carries syntax-highlighting attributes contributed by the supplied highlighter. |
| mdr-015 | return-attributed-string | Any valid markdown input | Return value is an `NSAttributedString` whose string is non-empty and carries a `.font` attribute over some range. |
| mdr-016 | accept-markdown-string | Component invoked with `content: "Hello 世界"` | Call succeeds without a precondition or type-conversion failure; rendered output text contains "Hello 世界" unmodified aside from ordinary markdown conversion. |
| mdr-017 | accept-semantic-palette, accept-text-color | Component rendered with a given `palette` and `textColor` over `"Plain text"` | The rendered "Plain text" run has `.foregroundColor` equal to `textColor`. |
| mdr-018 | replace-alert-tag-with-label | `"> [!NOTE]\n> Body text"` | Rendered output text contains "NOTE" and does not contain the literal substring `[!NOTE]`. |
| mdr-019 | collapse-task-list-bullet | `"- [ ] Todo"` | Rendered output text contains "☐" followed by a tab character immediately before "Todo"; it does not contain a bullet character followed by "☐". |
| mdr-020 | remove-frontmatter | `"---\ntitle: Test\n# Heading"` (no closing `---`) | The leading `---` is not stripped as frontmatter (there is no matching closing `---`), but it is then parsed as ordinary markdown: the CommonMark parser reads the unclosed `---` line as a thematic break, so it renders as the divider-colored `thematicBreakRule` (not the literal text `"---"`), while `"title: Test"` and `"Heading"` remain as literal/rendered content. |
| mdr-021 | remove-frontmatter | `"# Heading\nNo frontmatter here"` (no leading `---`) | Rendered output text is unchanged in content from the input, aside from ordinary markdown-to-attributed-string conversion of the heading; nothing is stripped. |
| mdr-022 | require-alert-tag-on-first-line | `"> [!NOTE] extra text\n> more"` | No `.foregroundColor` alert styling is applied; rendered output text contains the literal `[!NOTE] extra text`. |
| mdr-023 | exclude-fenced-code-from-processing | `` "~~~\n> [!NOTE]\n~~~" `` | The rendered output contains the literal text `> [!NOTE]`; no `.foregroundColor` alert styling is applied. |
| mdr-024 | detect-alert-blockquotes, color-alerts-by-role | `"> [!NOTE]\n> First\n\n> [!WARNING]\n> Second"` | The first blockquote's range has `.foregroundColor` equal to `palette.platformColor(.info)`; the second's range has `.foregroundColor` equal to `palette.platformColor(.warning)`; the two colored ranges do not overlap. |
| mdr-025 | color-alerts-by-role | `"> [!NOTE]\n> > nested line"` | `.foregroundColor` equals `palette.platformColor(.info)` continuously across both the first line and the nested line, as one span. |
| mdr-026 | render-task-list-unchecked | `"Just text [ ] not a list item"` | Rendered output text contains the literal substring `[ ]` unchanged; it is not replaced with "☐". |
| mdr-027 | harden-blockquote-breaks | `"> Line 1  \n> Line 2"` (first line already ends with two trailing spaces) | Exactly one hard break separates "Line 1" and "Line 2" in the rendered output; no doubled break or extra blank line appears. |
| mdr-028 | accept-markdown-string, return-attributed-string | `""` (empty string) | Return value is an `NSAttributedString` whose string is empty (length 0). |

