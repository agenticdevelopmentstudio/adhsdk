
- **list-rendering**: Component MUST render the entries within a single semantic list.
- **list-item-rendering**: Component MUST render each entry as one item within that list.
- **item-label-content**: Component MUST render the entry's `label` as the content of its list item.
- **active-item-state**: Component MUST mark a list item as active when its entry's `open` property is `true`.
- **inactive-item-state**: Component MUST NOT mark a list item as active when `open` is not `true`.
- **upcoming-list-variant**: Component MUST present the list in its de-emphasized, "upcoming" variant when `soon` is `true`.
- **default-list-variant**: Component MUST NOT present the upcoming variant when `soon` is not `true`.
- **base-list-styling**: Component MUST apply the list's baseline styling identity regardless of which variant is active.

