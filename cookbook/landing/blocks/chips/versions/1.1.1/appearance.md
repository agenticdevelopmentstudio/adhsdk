
- **List container**: A semantic list that always carries its baseline styling identity (see **base-list-styling**), plus an additional "upcoming" modifier when `soon` is `true` (`lp-chips`, optionally with `lp-chips--soon`)
- **List items**: Each item optionally carries an "active" modifier when its entry's `open` is `true` (`lp-chip--open`); items that are not active carry no per-item modifier of their own
- **Active item meaning**: `open: true` marks that specific chip as the emphasized/current item within the row, visually distinguished from the row's other (default) chips. The exact emphasis (e.g. accent color or border) is defined by the consuming stylesheet (`css/blocks.css`) rather than by this component
- **Label content**: Rendered as-is from the `label` property; styling for both the standard and upcoming variants lives in `css/blocks.css`
- **Standard appearance**: Baseline treatment applied to every chip list
- **Upcoming variant**: Dashed, dimmed, accent-free treatment applied at the list level when the list represents items that are not yet available, independent of any individual item's active state

