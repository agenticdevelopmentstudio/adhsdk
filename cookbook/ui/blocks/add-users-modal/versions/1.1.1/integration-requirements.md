
- **add-row-on-enter-or-button**: The AddUsersModal MUST append a `DraftUser`
  to the staged `DataTable`, clear the entry fields, and refocus the Name input
  when Enter is pressed in any entry field or the entry **Add** button is
  activated.
- **ignore-blank-entry**: The AddUsersModal MUST treat an entry with no name,
  email, or phone as fully blank and MUST NOT append a row, even if an admin
  note is present. A note-only entry is a no-op for row-adding purposes, but
  the note field is NOT cleared (only a successful add, or a close that
  resets state, clears the entry fields); a note-only entry still counts as
  dirty for **confirm-cancel-when-dirty** below.
- **tab-order**: The entry row MUST follow DOM order Name → Email → Phone →
  Note → **Add**. The `flex-1` element between Note and Add is layout spacing
  only; it has no effect on tab order.
- **disable-footer-add-when-empty**: The footer **Add** button MUST be
  `disabled` while the staged `DataTable` contains no rows.
- **disable-footer-add-when-busy**: The footer **Add** button MUST be
  `disabled` when `busy` is true.
- **call-onadd-and-close**: Activating the footer **Add** MUST call
  `onAdd(stagedRows)`, then reset internal state (staged rows, selection, and
  entry fields), and call `onClose()` — immediately, regardless of `busy`. The
  modal does not wait for `busy` to clear before calling `onClose()`; the
  caller's `open` prop still governs whether the dialog remains mounted.
- **confirm-cancel-when-dirty**: Cancel or Esc MUST open a discard-confirm
  `UnsavedChangesAlert` when the staged table has rows OR the entry row has
  content (name, email, phone, or note is non-blank); otherwise it MUST close
  immediately. A backdrop click is inert: the shared `Dialog` sets
  `disablePointerDismissal`, so a backdrop click neither closes the dialog nor
  opens the confirm, regardless of dirty state. `busy` does not disable Cancel
  or Esc. State resets on close.

