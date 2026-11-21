
- **render-card-shell**: The block MUST render its content in a `Card` and forward `className` and remaining host attributes to it.
- **render-title**: When `title` is a non-empty string, the block MUST render it in a `CardHeader` as a `CardTitle`, and MUST omit the header otherwise.
- **render-description-through-renderer**: When `renderMarkdown` is given, the block MUST render the description as the result of calling it with the description string, inside `CardContent`.
- **render-description-as-plain-text**: When `renderMarkdown` is absent, the block MUST render the description as a whitespace-preserving paragraph (`whitespace-pre-wrap`), never as HTML.
- **omit-empty-content**: The block MUST omit `CardContent` when `description` is empty or absent.
- **render-nothing-when-empty**: The block MUST render nothing (return null) when both `title` and `description` are empty or absent.
