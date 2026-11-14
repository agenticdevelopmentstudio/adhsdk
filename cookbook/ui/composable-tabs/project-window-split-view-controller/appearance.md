
- **Corner radius**: None set here; the shelf's bordered card belongs to the shelf controller.
- **Padding**: None; the content is pinned to the safe area and the shelf to the whole pane (see `content-safe-area` and `shelf-full-height`).
- **Font**: Not applicable: the component draws no text.
- **Background**: The content pane is the theme's window background; the shelf pane is the theme's project pane backdrop; both are reapplied on a theme change (see `theme-repaint`).
- **Foreground/Text**: Not applicable: the component draws no text or glyphs of its own.
- **Border**: A thin divider between the panes (see `divider-thin`); no other border.
- **Shadow**: None.
- **Min/Max size**: Content pane minimum width 300 points; shelf pane 180 through 480 points, 240 points by default; a slide's duration is 0.2 seconds.

