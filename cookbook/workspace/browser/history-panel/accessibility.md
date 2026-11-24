
- **Role/trait**: The filter field is a search field; the list is a table
  of selectable rows; the remove and Clear History… buttons are buttons.
- **Label requirements**: The remove button, which shows only a glyph,
  carries the accessibility label "Remove Selected Visits", matching its
  tooltip; Clear History… carries its title. Each row's accessible text is
  the visit's title, address and relative time.
- **Announce state changes**: Not specified by the design; a reload
  replaces the table's rows, which the platform's table announces as it
  does for any reload.
- **Keyboard / assistive-technology navigation**: The filter field and the
  list are both reachable by the keyboard; arrow keys move the selection,
  and Return opens the selected visit (see `panel-opens-visit`).
- **Minimum tap target**: Not applicable — a pointer-driven desktop
  surface; the buttons use the platform's standard small control size.

