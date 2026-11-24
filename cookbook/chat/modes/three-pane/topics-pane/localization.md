
The header text is currently a hardcoded string literal in `TopicsPane.tsx` (see **render-header**), not read from a resource file. The key below is the recommended externalization target, not a key the current source reads.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| pane.header.topics | "Topics" | Header text for the topics pane |

