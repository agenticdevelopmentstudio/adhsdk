
- **Corner radius**: None on the pane or body; the pane is a layout shell.
- **Padding**: The body is 16px on all sides (`p-4`); the bar has none and sits flush against the top and sides of the pane.
- **Font**: Not applicable: the pane renders no text of its own; text comes from the bar and the editor.
- **Background**: None set by the pane; it inherits from the host.
- **Foreground/Text**: None set by the pane.
- **Border**: None on the pane or body.
- **Shadow**: None.
- **Min/Max size**: The pane fills the height of its container (`h-full`) and may shrink below content size (`min-h-0 min-w-0`) so the editor scrolls inside it. The body is a column with a 12px gap (`gap-3`) between the host's children and the editor.

