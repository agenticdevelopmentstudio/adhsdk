
- **Layout**: A vertical stack with 8px (`gap-2`) between rows; the root and each row can shrink below content width (`min-w-0`) so long names wrap instead of widening the list.
- **Name**: Monospace, 11px, muted text color (`text-apt-text-muted`), wraps with `overflow-wrap: anywhere`.
- **Value**: Monospace, 11px, semibold, full text color (`text-apt-text`), does not shrink; aligned to the first baseline of the name (`items-baseline`) with an 8px gap from it.
- **Bar**: 6px tall track (`h-1.5`) with a 4px top margin; the fill is the full track height, rounded on its right corners only (`rounded-r`), coloured by `color`, 2px minimum width when the value is greater than zero.
- **Selectable row**: Block-level button, full width, small corner radius (`rounded-sm`), pointer cursor, no default outline; a 2px gold ring at 40% opacity on keyboard focus.
- **Dimmed row**: 55% opacity on every row except the selected one while a selection exists.
- **Expand button**: Monospace, 10px, muted text color, underlined with a 2px underline offset, no padding, 8px top margin, text becomes full text color on hover, same focus ring as a row.
- **Empty state**: Monospace, 12px (`text-xs`), dim text color (`text-apt-text-dim`).
- **Min/Max size**: None. The width is whatever the parent gives it.

