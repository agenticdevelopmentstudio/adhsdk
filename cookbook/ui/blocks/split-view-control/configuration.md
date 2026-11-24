
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `view` | SplitView object | required | State object from `useSplitView()` hook, containing layout, pane, effective, wide, showEditor, showPreview, and panesId |
| `subject` | string | required | Context string describing what is being switched (e.g., "Editor", "Document"), used in aria-labels |
| `editLabel` | string | "Edit" | Label text for the edit toggle item |
| `previewLabel` | string | "Preview" | Label text for the preview toggle item |
| `className` | string | undefined | Optional CSS class name(s) to merge with base flex layout |

