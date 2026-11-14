
- **Corner radius**: Not applicable: the source sets none; the chat view and the
  native controls draw their own.
- **Padding**: The chat view is pinned to the container's four edges with no inset;
  an option row is a vertical stack of a label and its control, 4 points apart.
- **Font**: Not set by this controller; the labels are plain system labels and the
  chat view owns its own type.
- **Background**: A themed container using the window-background role, so it follows
  the active theme.
- **Foreground/Text**: Not set here; the status line text comes from the chat view.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: The container starts at 360 by 500 points; the persona field is
  at least 360 points wide and exactly 110 points high.

