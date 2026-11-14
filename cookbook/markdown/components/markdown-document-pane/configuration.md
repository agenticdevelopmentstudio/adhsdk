
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `document` | `DocumentSaveBarProps['document'] & { value: string or null; edit: function }` | required | The document from `useVersionedDocument`. Until `value` loads the body is empty. |
| `editable` | boolean | required | Whether the document may be changed here. False shows the same view without the bar, unless a draft or conflict is pending. |
| `noun` | string | `document` | What the document is called in the bar's notices ("file", "note"). |
| `messages` | `DocumentSaveBarMessages` | none | Replaces any of the bar's notices. |
| `children` | ReactNode | none | The host's own content above the editor, inside the padded body. |
| Editor props | `MarkdownDocumentEditorProps` less `value`, `onChange`, `readOnly` | editor's own | Every other prop is forwarded to `MarkdownDocumentEditor`. |

