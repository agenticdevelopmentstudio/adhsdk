
- **Role**: Trigger is a button (`DropdownMenuTrigger`, exposing `aria-haspopup="menu"`). The open dropdown uses the ARIA `menu` pattern: each `PopupMenuItem` and the "All" row are exposed as `menuitemradio` (single-selection semantics — see **single-select-item-group**), and the "New…" row is a plain `menuitem`.
- **Label**: `ariaLabel` prop is required and MUST be provided by the caller; it is applied directly to the trigger.
- **Icon accessibility**: The icon (default affordance icon or custom) MUST be excluded from assistive-technology announcements — see **hide-icon-from-accessibility**.
- **State announcement**: Changes in selection (e.g., item marked as selected) are announced by the dropdown menu's native ARIA attributes.
- **Minimum tap target**: The web trigger is approximately 25.6px tall (12.8px text + 6.4px top padding + 6.4px bottom padding), which meets WCAG 2.5.8's 24×24px minimum target size for web pointer input. Native ports MUST meet their platform's own minimum instead: 44×44pt (Apple, per HIG) or 48×48dp (Android/Windows).
- **Keyboard navigation**: Trigger is focusable via keyboard; dropdown menu handles arrow keys and Enter/Escape per ARIA practices. The focus indicator replaces the default outline with a border-color change — see **focus-indicator-contrast**.
- **Label for items**: Each item displays its `label` prop as visible text; no additional accessible labels are required.

