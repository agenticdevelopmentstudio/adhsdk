
- **Positioning**: Positioned via Base UI Positioner (side, sideOffset, align, alignOffset); z-index 50.
- **Item padding**: Applied via semantic `adh-dropdown-menu__item` class.
- **Item inset**: When `inset={true}`, applies `adh-dropdown-menu__item--inset` class for additional horizontal padding.
- **Item accent**: When `accent={true}`, applies `adh-dropdown-menu__item--accent` class for the theme's accent styling on hover/focus.
- **Checkbox icon**: Check icon from lucide-react rendered when CheckboxItem is checked, styled via `adh-dropdown-menu__indicator-check` class.
- **Radio icon**: Circle icon from lucide-react rendered when RadioItem is selected, styled via `adh-dropdown-menu__indicator-dot` class.
- **Submenu chevron**: ChevronRight icon from lucide-react rendered on SubmenuTrigger, styled via `adh-dropdown-menu__sub-trigger-chevron` class.
- **Separator**: Rendered via MenuPrimitive.Separator with class `adh-dropdown-menu__separator`.
- **Label**: Plain styled div with class `adh-dropdown-menu__label`, supports `inset` prop.

