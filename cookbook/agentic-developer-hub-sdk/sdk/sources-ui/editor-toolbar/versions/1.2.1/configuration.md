
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| availableModes | [MarkdownEditorMode] | MarkdownEditorMode.allCases | Array of modes the user can select from |
| mode | MarkdownEditorMode | .split | Currently selected editor mode |
| showsHelpButton | Bool | true | Whether the help button is visible |
| showsImportButton | Bool | true | Whether the import button is visible |
| onModeChange | ((MarkdownEditorMode) -> Void)? | nil | Callback fired when mode selection changes |
| onImport | (() -> Void)? | nil | Callback fired when import button is tapped |
| onSyntaxHelpRequested | (() -> Void)? | nil | Callback fired when help button is tapped |

