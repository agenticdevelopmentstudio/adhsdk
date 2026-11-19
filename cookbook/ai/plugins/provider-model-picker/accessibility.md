
- **Role/trait**: A pop-up button for the provider; the model row's roles are
  the model picker control's.
- **Label requirements**: The popup's accessibility label MUST be the provider
  row's label, so a caller's custom label ("Summaries provider") is what a
  screen reader says.
- **Announce state changes**: A provider change updates the model row's name,
  which the platform reports as a value change of its name button.
- **Minimum tap target**: Pointer-driven controls on macOS; the platform popup
  meets the platform's own size.
- **Contrast**: Colors come from theme roles; the theme decides whether they
  clear 4.5:1.

Keyboard: with the platform's full keyboard navigation turned on, Tab moves
from the popup to the model row's caret and name, and Space opens the popup;
with it off, macOS gives the pop-up button and the borderless buttons no Tab
focus.

