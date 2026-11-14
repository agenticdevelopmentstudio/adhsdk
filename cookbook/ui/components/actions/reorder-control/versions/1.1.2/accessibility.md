
- **Role/trait**: The outer container uses role="group"; each button is a standard button control.
- **Label requirements**: The group has an aria-label ("Reorder" or "Reorder subject"); each button has an aria-label with the direction and optional subject; title attributes provide tooltips.
- **Icon semantics**: Arrow icons are marked aria-hidden="true" because their meaning is conveyed by the button's aria-label.
- **State announcement**: aria-disabled on both buttons (not the group) when busy; aria-busy set to true on the group when busy (see **group-aria-busy**) and removed when not busy.
- **Disabled state**: When canMoveUp or canMoveDown is false, the button's disabled attribute is set. Independently, when busy, aria-disabled is set on that same button to preserve keyboard focus — the two are not exclusive, so a boundary button that is also busy carries both attributes at once (see **overlapping-disabled-states**).
- **Keyboard navigation**: Buttons are fully keyboard accessible; disabled buttons are skipped by tab order; focused buttons can be activated via Enter or Space.
- **Minimum tap target**: Buttons use the icon-sm variant, which is 28×28px — short of all three platform minimum tap targets (44×44pt iOS, 48×48dp Android, 40×40px web). The Button component's `--adh-button-min-height` / `--adh-button-min-width` CSS variables let a consuming surface raise the floor for every descendant button, but icon-sm's own default does not meet these minimums.

