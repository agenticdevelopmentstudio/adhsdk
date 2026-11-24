
- **Layout**: Two rows in a vertical flex container with an 8px gap between them (`flex flex-col gap-2`). Top row (`flex w-full items-stretch gap-2`): Combobox and EntityChooser side by side, 8px gap. Bottom row: the chips group, spanning the full field width.
- **Combobox width**: Flexible (`flex-1`); grows to fill whatever width the EntityChooser leaves.
- **EntityChooser width**: Fixed at 176px (`w-44`), and it does not shrink (`shrink-0`) — the Combobox, not the chooser, absorbs any extra or missing space.
- **Chips row**: Spans the full field width; renders nothing visually when `value` is empty.
- **Disabled state**: Combobox, EntityChooser, and each chip's remove control render with platform-appropriate disabled styling.

