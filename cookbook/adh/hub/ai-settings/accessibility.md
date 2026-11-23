
- **Role/trait**: The models table is a native table with header cells; the Available control is a
  checkbox; the create modal is a modal dialog labelled "New service"; the blocker message in the
  button bar has the status role; every error line (list, save, delete, create and connect errors) is
  the shared `ErrorText` with the alert role; the rail icons are marked decorative.
- **available-checkbox-label**: NEEDS REVIEW: Not implemented in source. Neither the design nor the source says how each row's Available checkbox is named for assistive technology; a row with only a bare checkbox cannot be told apart from the next, and the screen's reviewer needs to decide on a per-model accessible name (for example the model's display name) before this is testable.
- **Keyboard**: Every control is a native input, select, button or checkbox, so it takes the platform's
  default keyboard path; the source adds no custom key handling.
- **Announce state changes**: The blocker message announces itself (status role) and every error line
  announces itself (alert role), including a failed connect status. "Connected successfully." is plain
  text with no live region.
- **Minimum tap target**: Not applicable: the sizes come from the shared button, input and checkbox
  components; this component defines none of its own.
- **Contrast**: Not determinable from source: the colors are theme tokens whose resolved values this
  component does not define.

