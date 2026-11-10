
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `markdown-document-editor.preview.empty` | "Nothing to preview yet." | Shown in the preview pane when the editor content is empty or whitespace-only (**empty-preview-placeholder**). |
| `markdown-document-editor.subject.default` | "Editor" | Default accessible-name subject for the layout toggle groups when `subject` is not provided (**accept-subject-label**). |

Both strings are hardcoded literals in the source today rather than routed through an i18n layer; localizing them means introducing these keys at the call sites above. Beyond these two strings, and any button labels contributed by the composed `MarkdownEditorToolbar` and `MarkdownReadingPalette` (covered by their own recipes), this component renders no other user-facing text of its own.

