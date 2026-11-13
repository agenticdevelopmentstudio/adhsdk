
- **Corner radius**: Not applicable: the controller draws nothing itself; the panes and the system split view draw their own content.
- **Padding**: Not applicable: the controller sets no insets; its only layout values are the pane widths below.
- **Font**: Not applicable: the controller sets no text; the alert uses system alert typography.
- **Background**: Not applicable: no background is set by this controller.
- **Foreground/Text**: Not applicable: no text is set by this controller beyond the alert strings.
- **Border**: The system split view's dividers separate the panes; the controller sets no border.
- **Shadow**: Not applicable: none set by this controller.
- **Min/Max size**: Sidebar 180 to 320 points wide. Message list at least 280 points wide. Reader at least 360 points wide. The window's minimum content width is therefore at least 820 points (180 + 280 + 360), a consequence of the pane minimums rather than a value the source sets.

The sidebar pane uses the system sidebar style and the list pane the system content-list style; the reader is a plain pane.

