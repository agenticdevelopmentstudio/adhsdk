
- **renders-item-toggle-buttons**: The component MUST render each `ToggleGroupItem` as a real, focusable toggle button carrying its `value`.
- **marks-selected-item-pressed**: The component MUST mark the item whose `value` is in the group's current value as pressed (`data-[pressed]`).
- **pressed-item-gold-fill**: The pressed item MUST show the gold fill treatment (`bg-apt-gold` with `text-apt-bg`), visually distinct from the muted rest state.
- **emits-value-on-select**: Selecting an item MUST call `onValueChange` with the group's next value array.
- **single-select-via-value-array**: When driven single-select (`value={[selected]}`, `multiple` unset), the component MUST reflect exactly the one item in that array as pressed.
- **keyboard-operable**: A focused item MUST be operable by keyboard (arrow-key roving focus between items and Enter/Space activation), per the Base UI ToggleGroup primitive.
- **focus-visible-ring**: A keyboard-focused item MUST show a visible focus ring (`focus-visible:ring-2 ring-apt-gold/40`).
- **disabled-item-inert**: A disabled item MUST NOT respond to pointer input, MUST be skipped during roving keyboard navigation, and MUST render dimmed (`opacity-50`, `pointer-events-none`).
- **forwards-group-and-item-props**: The component MUST forward arbitrary props (incl. `aria-label`, `className`, `multiple`, `defaultValue`) to the underlying Base UI group and item primitives.
- **single-select-keeps-selection**: When driven single-select (`value={[selected]}`, `multiple` unset), the consumer MUST ignore the empty array from `onValueChange` (the deselect case) so the group keeps exactly one item pressed at all times.

