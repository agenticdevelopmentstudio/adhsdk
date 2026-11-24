
- **Role**: Menu items MUST have the `menuitem` role (provided by Base UI MenuPrimitive).
- **Label requirement**: Menu items MUST have accessible text content or an aria-label.
- **Keyboard navigation**: Menu MUST support arrow key navigation (up/down to move focus, left/right to open/close submenus).
- **Escape key**: Menu MUST close on Escape, returning focus to the trigger.
- **Focus management**: Focus MUST return to the trigger when the menu closes.
- **Checkbox state announcement**: Checkbox items MUST announce checked state to assistive technology via aria-checked.
- **Radio state announcement**: Radio items MUST announce selected state to assistive technology via aria-checked.
- **Disabled state announcement**: Disabled items MUST announce disabled state via aria-disabled.
- **Submenu indication**: Submenu triggers MUST indicate they open a submenu (via ChevronRight icon and aria-haspopup).
- **Minimum target size**: Menu items SHOULD have a minimum touch/click target size of 44×44px (WCAG 2.5.5 Target Size Enhanced; see references).

