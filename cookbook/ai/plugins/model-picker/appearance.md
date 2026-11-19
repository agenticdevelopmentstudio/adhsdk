
- **Corner radius**: The popover's own; the chooser sets none.
- **Padding**: The chooser keeps its current layout inside the popover: the
  search field above the list on the left, the detail pane on the right,
  divided by a split; the detail pane uses the composable settings panel's
  standard insets. The control uses the settings row insets of the panel it
  sits in, with the platform's standard spacing between label, caret, colon
  and name.
- **Font**: The control's label uses the theme's body font, like every
  settings row label. The name button uses the body font in the link style
  (the accent color, no bezel). List rows use the body font; the detail
  pane's heading uses the heading font, its fact lines the caption font and
  its description the body font.
- **Background**: The popover's material behind the chooser; the list's scroll
  host paints the theme's surface color.
- **Foreground/Text**: Control label: primary text color. Caret: a borderless
  button showing the `chevron.down` symbol in the secondary text color. Name
  button: the accent color, as a link. Detail fit line: secondary text when
  the model fits, warning color in the warn tier, danger color in the block
  tier.
- **Border**: None on the control's buttons (both borderless).
- **Shadow**: The popover's own; none of the component's.
- **Min/Max size**: The popover has a fixed content size large enough for the
  list and a readable detail pane; the list keeps its width and the detail
  pane takes the rest.

