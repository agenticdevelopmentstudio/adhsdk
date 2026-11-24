
- **Role**: The component is a grouped form control. The shared `Field` component provides an accessible label via the `label` prop. Each sub-control (Combobox, EntityChooser, EntitySelectionChips) provides its own accessible role and label.
- **Combobox label**: Set via `ariaLabel={`Add a ${noun}`}` (see **noun-in-placeholders**).
- **EntityChooser label**: Set via `ariaLabel={label}` (the field-level label) to associate it with the field.
- **Chips group label**: Set via `ariaLabel={label}` on `EntitySelectionChips` to announce the group.
- **Keyboard navigation**: Combobox, EntityChooser, and the chips' remove controls are each individually keyboard-accessible; TagSetField adds no keyboard handling of its own. Chip removal's specific keyboard behavior is `EntitySelectionChips`'s own — see [adhsdk.ingredient.ui.components.inputs.entity-chooser](cookbook:79f7ed30-3193-49bc-856b-d7dd01303baa).
- **Item addition is not announced**: The component does not emit an ARIA live-region announcement when an item is added. Screen-reader users only perceive the change through the Combobox's own text clearing and the new chip entering the DOM — neither of which is an explicit announcement. This is a real gap in the source, not a documented feature.
- **Item removal is not announced**: Likewise, removing a chip only updates `value` and re-renders the chip list; no live-region announcement accompanies it.
- **Minimum tap target**: Combobox input and EntityChooser trigger button SHOULD meet platform minimum touch target size (44×44pt on iOS, 48×48dp on Android, typically 44px on web).

