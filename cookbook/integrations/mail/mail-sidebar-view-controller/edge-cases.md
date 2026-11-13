
- **No accounts**: With no accounts the outline has zero rows and no message is drawn (MUST). Covered by the rebuild path in mail-sidebar-003.
- **Account with no mailboxes**: The group row MUST show with no children, and an item with no children is not expandable (mail-sidebar-002).
- **Unread zero or absent**: A count of zero or nil MUST draw no count label (mail-sidebar-009, mail-sidebar-010).
- **Unknown label**: A label id with no symbol of its own MUST show the tag symbol (mail-sidebar-005).
- **Deep nesting**: Indentation grows by 14 points per depth level with no upper bound in the source, so a deep label can push its title off the row; the title truncates at the tail.
- **Selection not listed**: When the selected mailbox is nil or not in the list, the sidebar MUST leave the outline selection alone rather than clear it (mail-sidebar-016, mail-sidebar-017).
- **Selection echo**: The sidebar MUST suppress the selection callback while it applies the model's selection (mail-sidebar-013).
- **Selection cleared by the outline**: A cleared outline selection sends nothing to the model, so the model keeps its selected mailbox (mail-sidebar-019).
- **Rebuild resets expansion**: Each rebuild expands every group again, so a group the user collapsed re-expands the next time accounts or mailboxes change.
- **Selection after rebuild**: Rebuilding re-applies the model's selection, so the selected row survives a reload (MUST).
- **Selection task**: Selecting a mailbox starts an unstructured task that awaits the model; the sidebar does not wait for it or handle its failure. Errors reach the user through the model's `errorMessage`, not through this controller.
- **Concurrent access**: The controller and its model are main-actor isolated; model changes arrive on the main queue, and the selection call runs in a task that awaits the main-actor model.
- **Offline or disconnected**: Not applicable to this controller: it makes no network call and only displays what the model holds.

