
- **Role**: The native `<select>` element exposes the `combobox` role to assistive technology (a single-selection native select maps to ARIA `combobox`, not `listbox`); no additional ARIA role is needed.
- **Label requirement**: A visual `<label>` element (via `htmlFor`) and an `aria-label` on the select both provide an accessible name; the `aria-label` ("Select reading theme") takes precedence in the computed accessible name. It contains the visible label text ("Theme") as a substring, satisfying WCAG 2.5.3 Label in Name.
- **Group container**: The wrapping `role="group"` associates the label and control as one interaction unit; it carries no accessible name of its own, so screen readers rely on the control's own accessible name (see **accessible-label**), not the group's.
- **Keyboard navigation**: The native select supports standard keyboard interaction (arrow keys, Enter/Space to open, arrow keys to navigate options, Enter to select)
- **Screen reader**: Screen readers announce the select's accessible name ("Select reading theme") and the option text when navigating
- **Touch/click target**: The control is 32px tall (the component's `h-8` sizing) with an auto width and a 112px minimum; the label is adjacent and can be clicked to focus the control. See **touch-target-size** in Compliance.

