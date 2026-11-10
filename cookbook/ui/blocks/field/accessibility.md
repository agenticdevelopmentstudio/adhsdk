
- The caption and control share one `<label>` element, so the caption is a real,
  programmatic label for the control — clicking it focuses the control and screen
  readers announce the caption when the control is focused.
- The caption text is authored by the caller; it MUST be human-readable label text
  (implicit association carries no `aria-label`).
- The error line is plain text in the label's flow, so it is read with the field;
  it carries no `role="alert"`, so callers that need assertive announcement
  SHOULD add their own `role="alert"` wrapper around the message they pass as
  `error`.
- `errorId` names the rendered error line (never the hint line — see
  **name-error-line**) so the caller's own control can point its
  `aria-describedby` at it. This is the mechanism that connects an error to its
  control: `Field` only makes the target nameable, and the caller wires
  `aria-describedby={errorId}` onto the control it passes as `children`.
- Color is not the only error signal in practice — the message text itself states
  the error — but callers SHOULD keep error copy meaningful for non-visual users.

