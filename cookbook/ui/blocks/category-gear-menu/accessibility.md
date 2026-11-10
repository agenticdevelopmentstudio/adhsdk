
- **Role**: Trigger element MUST have a button role; menu MUST have a menu role and menu items MUST have menuitem role (provided by DropdownMenu and DropdownMenuItem components).
- **Label**: Trigger MUST be labeled "{Noun} actions" to describe its purpose to assistive technology users.
- **Disabled state announcement**: Disabled menu items MUST be announced as disabled to assistive technology.
- **Touch target**: GearMenuTrigger MUST provide a minimum touch target of 44×44 CSS px on web, 44×44pt on iOS/macOS, or 48×48dp on Android.
- **Keyboard navigation**: Menu MUST support arrow keys and Enter/Space to select items (delegated to DropdownMenu component).

