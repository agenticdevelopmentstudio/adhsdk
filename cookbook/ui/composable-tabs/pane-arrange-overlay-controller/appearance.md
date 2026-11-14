
- **Corner radius**: Not applicable: the overlay's appearance is defined by `ComposableTabsArrangeOverlayView`, outside this file.
- **Padding**: The overlay is inset by `ComposableTabsPaneBackgroundView.borderInset` from each edge of the pane view (2 points in the source). The title bar stack has 4 points of spacing.
- **Font**: Not applicable: the file sets no text style.
- **Background**: The overlay's scrim is drawn by `ComposableTabsArrangeOverlayView`. The integrated title bar sets the window background to the theme palette's project pane backdrop color.
- **Foreground/Text**: The toggle button's content tint is the palette's accent color while the mode is on and the system default otherwise.
- **Border**: None set here; the overlay stays inside the active-pane border.
- **Shadow**: None.
- **Min/Max size**: A title bar button is 36 by 24 points with a 14-point symbol; the accessory is 40 points wide per button and 24 points tall.

