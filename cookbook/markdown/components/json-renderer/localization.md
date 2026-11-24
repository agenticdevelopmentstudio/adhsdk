
- **note-string**: NEEDS REVIEW: Not implemented in source. The note "Not valid JSON — shown as written." is a hard-coded English literal on both paths and is not routed through any string table. Evidence that would settle it: the host application's localization approach and whether this note is ever shown to non-English readers.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none; literal in source) | Not valid JSON — shown as written. | Shown above text that is not JSON or JSON Lines, as a paragraph (plain path) or Markdown emphasis (Markdown path). |

JSON content itself is shown verbatim and is not translated.

