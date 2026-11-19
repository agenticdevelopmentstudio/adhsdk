
- **Role/trait**: The caret and the name are buttons; the label is static text.
  The chooser's list is a table and its search field a search field.
- **Label requirements**: The caret button's symbol MUST carry the
  accessibility description "Choose a model" (it shows only a symbol), and
  the name button MUST use the control's label as its accessibility title
  element, so a screen reader reads the shown name with the label as its
  title rather than a bare model id.
- **Announce state changes**: Opening the popover moves focus to the search
  field, which the platform announces; a chosen model updates the name
  button's title, which the platform reports.
- **Minimum tap target**: Pointer-driven controls on macOS; the 44×44pt
  minimum is touch guidance. The caret is a borderless, inline-bezel symbol
  button at the platform's regular control size (the control sets no smaller
  size).
- **Contrast**: Colors come from theme roles (primary and secondary text,
  accent, warning, danger); whether a theme's resolved values clear 4.5:1 is
  the theme's property, not this component's.

Keyboard: Tab reaches the caret and the name button; Space or Return on
either opens the chooser. In the popover, the arrow keys move the selection
from the search field, Return chooses and closes, and Escape closes.

