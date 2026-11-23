
- **Corner radius**: The History window's shelf is a bordered card with a
  `12pt` corner radius, as the projects window's shelf is. Not applicable
  to the panel itself, which draws no card of its own.
- **Padding**: The panel's filter field and list follow the Settings
  sidebar's spacing; the shelf follows the projects window's shelf (panel
  bar across the top, the panel host beneath). Exact values are the
  builder's, matched to those two components.
- **Font**: A row's title in the list's primary text role, its address and
  relative time in a secondary text role, resolved by the active theme's
  typography rather than fixed sizes.
- **Background**: The panel and the shelf card fill with the
  `windowBackground` palette role.
- **Foreground/Text**: Title rows use the primary text role; address and
  time use `secondaryText`; a selected row uses the list's selection
  colors.
- **Border**: The shelf card strokes with the `outline` palette role, as
  the projects window's shelf does. The panel draws no border of its own.
- **Shadow**: Not applicable — neither the panel nor the window draws or
  configures a shadow beyond the window's system default.
- **Min/Max size**: The window is resizable; its minimum and default sizes
  are the builder's, large enough to show the filter field, the two header
  buttons and several rows without clipping.

