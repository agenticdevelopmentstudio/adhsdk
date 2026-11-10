
- **Container**: Flex column layout; accepts a caller-provided class for the root.
- **Button bar**: Dark surface background, rounded top corners, left and right borders; holds the search input, filter inputs, facet menus, action nodes, and the selection-count button.
- **Search input**: Height 2rem (32px), max-width 20rem, `search` input type, with an accessible label.
- **Text filter inputs**: Height 2rem (32px), width from filter metadata or 14rem default, `search` input type.
- **Facet menu buttons**: Dark/ghost variant, small size.
- **Table**: Rows are one line tall; columns are resizable and sortable. Nested inside the details pane, the table's top rounding and top border are removed so the bar, the rows, the divider, and the pane read as one continuous card; standalone, it caps at `maxHeightClass` (default 60% of the viewport height).
- **Selection count button**: Ghost variant, small size, height 1.75rem (28px), extra-small text; shows the selected count and, when any selected rows are hidden by a filter, an accent-colored "(N not shown)" suffix.
- **Error alerts**: Error/danger variant with a triangle-alert icon; positioned above the table when rows exist, or replacing the entire list when none do.
- **Truncation alert**: Accent variant with a triangle-alert icon, positioned above the table.
- **Details pane**: A resizable split whose divider doubles as the pane's header bar; the pane's height is fixed by `details.heightClass` or a 60%-of-viewport default (the split sizes its panes as percentages of that height, so a definite height is required rather than a cap). The header bar shows the row name or the pane label on the left and header actions on the right. The bottom half shows the row's rendered details, or the empty/many-selected message.
- **Cell values**: Rendered as plain text; a null or empty value from a `value`-based column renders as an em dash in a dim, de-emphasized text color rather than the normal text color.

