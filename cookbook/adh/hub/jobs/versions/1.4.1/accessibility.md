
- **Role/trait**: The status table is a native table with header cells. Every status badge carries its
  status as text. Every error line is the shared error text with the alert role.
- **status-text-not-color**: A run's or step's status MUST be readable as text, not only as a color.
- **Keyboard**: Every control is a native input, select, button or checkbox. The step list's reordering
  MUST be reachable from the keyboard (move up and move down buttons), not only by dragging.
- **Announce state changes**: A live run's status change MUST be announced through a polite live region.
- **Labels**: Each step editor's fields MUST carry labels naming the step, so two steps' fields can be told
  apart.
- **Unambiguous names**: A notify checkbox's accessible name MUST name what it does in full ("Notify
  when a run failed", "Notify by Email"), and a template's offer checkbox MUST be named exactly "Offered
  by <set name>", never with the set's name twice. The box sits inside its label, which names it, so that label
  MUST carry the full name, with the short text shown on screen. The once-shown secret's confirm MUST
  be named "Close without copying", never plain "Close", which is the name of the dialogs' ✕ buttons
  that keep the secret open.
