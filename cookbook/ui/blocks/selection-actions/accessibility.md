
- Role: Buttons are standard `<button>` elements with implicit button role.
- Labels: Each action button uses the text from `action.label` (can be React node). Delete button uses the hardcoded label "Delete".
- Toolbar semantics: The component renders no `role="toolbar"` and no arrow-key or roving-tabindex navigation; the APG toolbar pattern in `references` applies to the host container, which MUST supply `role="toolbar"` and that keyboard navigation if it wants them. Each button is reachable by Tab.
- Dividers: Separators use ARIA `role="separator"` with `aria-orientation="vertical"` to communicate structural grouping to screen reader users.
- State announcement: Disabled state is implicit in the button's `disabled` attribute; browser and assistive technology automatically announce disabled buttons.
- Touch target: Buttons use the Button component's small size. The Button ingredient's own spec documents that its fixed size-variant heights sit below the Apple HIG 44×44pt and Material 48×48dp minimum touch-target guidance by default, and that a surface must opt in to a larger floor via `--adh-button-min-height`/`--adh-button-min-width` on an ancestor. Selection Actions does not set either variable, so it does not guarantee an accessible tap target on its own; a host that requires one MUST set the floor itself.
- Modal accessibility: The AlertModal component MUST provide its own focus management, role attributes, and keyboard dismissal (Escape key).

