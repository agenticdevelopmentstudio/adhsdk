
- **open-slots**: The layout MUST keep an ordered array of open slots, each expecting one commit ID and carrying a lane.
- **leftmost-expecting-slot**: A commit MUST take the leftmost slot expecting its ID; every other slot expecting it MUST close into it, routing from its own column to the commit's column in the row's top segments.
- **new-commit-slot**: A commit no slot expects MUST take the first empty slot, or a new slot at the right when none is empty, and that slot MUST open with a new lane.
- **first-parent-slot**: The first parent MUST take the leftmost of the commit's own slot and any other slot already expecting it: it inherits the commit's slot, or, when a slot to the left already expects it, the commit's slot closes and its line joins that slot.
- **further-parent-slot**: Each further parent MUST reuse the leftmost slot already expecting it, or else take the first empty slot or a new slot at the right, opening it with a new lane.
- **root-closes-slot**: A commit with no parents MUST close its slot.
- **missing-parent-stays-open**: A parent that never appears MUST leave its slot open for the rest of the layout (a shallow clone) without failing.
- **trim-right**: Empty slots at the right MUST be removed after every commit; empty slots between open ones stay, so open slots never shift columns.
- **monotonic-lanes**: Lanes MUST come from a counter that only increases from 0, assigned when a slot opens and carried with the slot until it closes, so no lane is reused while the layout lives; a view takes it modulo its palette.
- **top-segments**: A row's top segments MUST hold one segment per slot open at the row's top edge, in column order: a slot expecting the commit routes from its column to the commit's column, every other slot passes straight through; each carries its slot's lane.
- **bottom-segments**: A row's bottom segments MUST hold the first-parent edge from the commit's column to its slot, carrying the commit's lane; each further-parent edge from the commit's column to its slot, carrying that slot's lane; and a straight segment for every other open slot, carrying its lane; sorted by `from`, then `to`.
- **row-width**: A row's width MUST be the largest of the slot count at its top edge, the slot count at its bottom edge (both right-trimmed) and the commit's column plus one.
- **stateful-paging**: Appending commits in several calls MUST yield the same rows, in order, as appending them in one call; rows already returned are never revised.

