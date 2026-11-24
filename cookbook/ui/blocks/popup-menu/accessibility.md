
- **Role**: Trigger is a button (`DropdownMenuTrigger`, exposing `aria-haspopup="menu"`). The open dropdown uses the ARIA `menu` pattern: each `PopupMenuItem` and the "All" row are exposed as `menuitemradio` (single-selection semantics — see **single-select-item-group**), and the "New…" row is a plain `menuitem`.
- **Label**: `ariaLabel` prop is required and MUST be provided by the caller; it is applied directly to the trigger.
- **Icon accessibility**: The default affordance icon MUST be excluded from assistive-technology announcements; a custom icon is the caller's to hide — see **hide-icon-from-accessibility**.
- **State announcement**: Changes in selection (e.g., item marked as selected) are announced by the dropdown menu's native ARIA attributes.
- **Minimum tap target**: The web trigger's height is its line box (the component sets no line-height, so it inherits the ambient one) plus 12.8px of vertical padding (6.4px top and bottom) plus a 1px border top and bottom; at any line height of 9.2px or more this meets WCAG 2.5.8's 24×24px minimum target size for web pointer input. Native ports MUST meet their platform's own minimum instead: 44×44pt (Apple, per HIG) or 48×48dp (Android/Windows).
- **Keyboard navigation**: Trigger is focusable via keyboard; dropdown menu handles arrow keys and Enter/Escape per ARIA practices. The focus indicator replaces the default outline with a border-color change — see **focus-indicator-contrast**.
- **focus-border-contrast**: NEEDS REVIEW: Not implemented in source. The focus indicator is a border color change to the `apt-gold` token and the source does not state its contrast against the adjacent surface; a token-pair measurement in each theme would settle whether it meets the 3:1 floor named in **focus-indicator-contrast**.
- **Label for items**: Each item displays its `label` prop as visible text; no additional accessible labels are required.

