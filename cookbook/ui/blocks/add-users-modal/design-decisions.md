
- **Decision**: A row needs at least a name, email, or phone to be added; an
  admin note alone does not cause a row to be appended, so a note-only entry
  is a no-op for row-adding — but the note is not cleared, and it does count
  as dirty for `confirm-cancel-when-dirty`.
  **Rationale**: Avoids staging rows with no usable identity or contact
  information, while still treating a typed note as work the user could lose.
  **Approved**: pending
- **Decision**: Enter-to-add refocuses Name.
  **Rationale**: Enables fast repeated keyboard entry.
  **Approved**: pending
- **Decision**: Explicit DOM tab order ends on Add after Note; the flexible
  spacer between them is layout only and does not itself produce the order.
  **Rationale**: Predictable keyboard flow to the primary entry action.
  **Approved**: pending
- **Decision**: Cancel confirms only when dirty.
  **Rationale**: Avoids nagging the user when there is nothing to lose.
  **Approved**: pending
- **Decision**: `busy` disables the footer Add button only; does not block
  Esc or Cancel. A backdrop click is always inert, independent of `busy`,
  because the shared `Dialog` sets `disablePointerDismissal` (dismissal only
  via an explicit button, per the family's dialog-dismissal policy).
  **Rationale**: Prevents accidental duplicate submissions while allowing
  users to abandon unsaved work via Esc/Cancel if needed.
  **Approved**: pending
- **Decision**: The AddUsersModal validates only presence (name/email/phone
  non-blank), not email or phone format; format validation is the caller's
  responsibility, before or after `onAdd` is invoked.
  **Rationale**: The component stages contact rows for the caller to submit;
  format rules typically depend on the caller's backend and are out of scope
  for the staging UI.
  **Approved**: pending
- **Decision**: Each staged row carries an internally generated id
  (`` `${Date.now()}-${index}` ``) used only for `DataTable` selection
  identity; the id is stripped before rows are passed to `onAdd`, so the
  public `DraftUser` shape has no id field.
  **Rationale**: Two staged rows can have identical name/email/phone/note
  values, so a stable per-row key is needed for selection even though the
  caller-facing type doesn't need one.
  **Approved**: pending

