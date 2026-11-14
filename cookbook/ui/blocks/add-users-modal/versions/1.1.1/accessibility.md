
`Dialog` modal semantics with focus trap and restore; entry inputs are
labeled via `Field`. Tab order follows DOM order: Name → Email → Phone →
Note → Add button; the `flex-1` element between Note and Add is layout
spacing only and has no effect on tab order (see **tab-order**). Esc closes
the dialog (subject to the discard-confirm rule) but is not itself a tab
stop. Enter-to-add keeps focus flowing back to Name for fast repeated entry.
The empty staged table displays the `DataTable` empty label.

