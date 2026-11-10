
- Every button has an `aria-label`/`title`, suffixed with the consumer's
  `subject` (e.g. "Save changes flag beta") so rows are distinguishable to
  screen readers.
- The pending pair is wrapped in `role="group"` with a state-describing label
  ("Commit changes …" / "Confirm deleting …") and `aria-busy` while a commit
  is in flight.
- The armed trash carries `aria-pressed` to expose the armed state.
- The hover-hidden trash becomes visible on keyboard focus
  (`focus-visible:opacity-100`), so delete is keyboard-operable; while hidden
  it is also `pointer-events-none`, so a blind touch tap (no hover) can't arm
  a delete.
- Focus is preserved across state transitions: arming focuses the ✓;
  committing/cancelling re-anchors on the idle trash. Because busy uses
  `aria-disabled` (not `disabled`), an in-flight commit never drops focus.
- `InlineEditableText` requires an `aria-label` (its shell is invisible at
  rest, so there is no visible label) and supports Enter/Escape.
- The navigation guard's dialog is the platform AlertModal (focus trap,
  destructive keyboard policy).

