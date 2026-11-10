
- **Empty theme registry**: If the theme registry is empty, the control MUST render with no options; no error is thrown, and the control remains present but offers no selectable theme.
- **Unknown active theme id**: If the given active theme id does not match any theme in the registry, the control renders with no option visibly selected; selecting any option still invokes **emit-theme-change**.
- **Theme registry mutation**: The registry is immutable input. Mutating a theme object's fields in place (e.g., changing a label) after render is a caller error: the control MUST NOT be relied upon to reflect that mutation until the control's own next render (e.g., driven by a change to the active theme id or a parent re-render).
- **Rapid theme changes**: Each selection closes the dropdown; picking a different theme again requires reopening it. The control MUST NOT debounce or deduplicate **emit-theme-change**: every selection, however rapid the sequence, invokes the callback once per change.
- **Focus retention on selection**: The native `<select>` element keeps keyboard focus after an option is chosen; focus does not move away from the control.

