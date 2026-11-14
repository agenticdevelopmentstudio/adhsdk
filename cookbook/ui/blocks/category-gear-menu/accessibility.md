
- **role**: Trigger element MUST have a button role; menu MUST have a menu role and menu items MUST have menuitem role (provided by DropdownMenu and DropdownMenuItem components).
- **trigger-label**: Trigger MUST be labeled "{Noun} actions" to describe its purpose to assistive technology users.
- **disabled-state-announcement**: Disabled menu items MUST be announced as disabled to assistive technology.
- **touch-target-size**: NEEDS REVIEW: Not implemented in source. `GearMenuTrigger` is 24×24 CSS px (`size-6`) with a 14px icon, below the 44×44 CSS px, 44×44pt and 48×48dp platform minimums; settling it needs a decision on whether this dense header control is held to those minimums (WCAG 2.2 sets 24×24 CSS px as its floor) or the trigger is enlarged.
- **keyboard-navigation**: Menu MUST support arrow keys and Enter/Space to select items (delegated to DropdownMenu component).

