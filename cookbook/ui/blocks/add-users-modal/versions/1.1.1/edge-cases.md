
- A fully blank entry (no name, email, or phone) is a no-op for row-adding,
  even with an admin note present; the note field is NOT cleared, and a
  note-only entry still counts as dirty for confirm-cancel-when-dirty.
- Footer Add is disabled at 0 staged rows; an empty staged table shows the
  `DataTable` empty label.
- `busy` disables the footer Add button to prevent multiple submissions;
  Cancel/Esc remain enabled while busy, and still follow the dirty-confirm
  rule.
- Cancel / Esc with a dirty state (rows or entry content, including a
  note-only entry) opens the discard confirm; with a clean state it closes
  immediately. A backdrop click never closes the dialog or opens the confirm
  — it is inert regardless of dirty state, because the shared `Dialog` sets
  `disablePointerDismissal`.
- State resets on close (staged rows, selection, and entry fields), so
  reopening starts with an empty entry row and table.

