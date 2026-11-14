
A generic, selectable, optionally-sortable, optionally-reorderable table primitive in `@adh-sdk/ui`.
It is a **controlled** table: the caller owns `rows`, the `selectedIds` set, and
the optional `sort`. The component renders columns, handles pointer + keyboard
selection, and reports changes up. It is generic over the row type `T` and owns
the multi-row selection model (click / ⇧-click / ⌥-click / keyboard). It is the
foundation for `ListWithDetailsPane` and `AddUsersModal`.

