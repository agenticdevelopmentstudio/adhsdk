
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dropdown-001 | render-trigger, render-content | Render DropdownMenu with Trigger and Content | Trigger element renders; clicking trigger shows menu content |
| dropdown-002 | close-on-item-select | Render MenuItem inside open menu; click it | Menu closes after click |
| dropdown-003 | close-on-link-select | Render LinkItem inside open menu; click it | Menu closes; browser link semantics preserved (middle-click opens new tab) |
| dropdown-004 | close-on-escape | Open menu; press Escape key | Menu closes; focus returns to trigger |
| dropdown-005 | close-on-outside-click | Open menu; click outside | Menu closes |
| dropdown-006 | support-checkbox-items | Render CheckboxItem with checked={true} | Checkmark icon appears in indicator slot |
| dropdown-007 | support-checkbox-items | Render CheckboxItem with checked={false} | Indicator slot is empty |
| dropdown-008 | support-radio-items | Render RadioGroup with RadioItem selected | Circle indicator appears in indicator slot |
| dropdown-009 | support-radio-items | Render RadioGroup with RadioItem unselected | Indicator slot is empty |
| dropdown-010 | support-submenus | Render SubmenuRoot with SubmenuTrigger inside open parent menu | Submenu opens; ChevronRight icon renders on trigger |
| dropdown-011 | position-with-offset | Render DropdownMenuContent with side="bottom" sideOffset={8} | Content positioned 8px below trigger |
| dropdown-012 | position-with-offset | Render DropdownMenuContent with default sideOffset | Content positioned 4px from trigger (default) |
| dropdown-013 | support-semantic-classes | Render MenuItem | MenuItem renders with class adh-dropdown-menu__item |
| dropdown-014 | support-inset-items | Render MenuItem with inset={true} | MenuItem renders with classes adh-dropdown-menu__item adh-dropdown-menu__item--inset |
| dropdown-015 | support-accent-items | Render MenuItem with accent={true} | MenuItem renders with classes adh-dropdown-menu__item adh-dropdown-menu__item--accent |
| dropdown-016 | close-on-click-default | Render open menu with CheckboxItem; click it | Menu closes (closeOnClick defaults to true) |
| dropdown-017 | close-on-click-default | Render open menu with RadioItem; click it | Menu closes (closeOnClick defaults to true) |
| dropdown-018 | close-on-click-default | Render open menu with LinkItem; click it | Menu closes (closeOnClick defaults to true) |
| dropdown-019 | keyboard-navigation | Open menu; press ArrowDown then ArrowUp | Focus moves to the next item, then back to the previous item |
| dropdown-020 | focus-management | Open menu via trigger click | Focus moves into the menu, landing on the first focusable item |
| dropdown-021 | checkbox-state-announcement | Render CheckboxItem with checked={true}; inspect DOM | Item exposes aria-checked="true" |
| dropdown-022 | disabled-state-announcement | Render MenuItem with disabled={true}; attempt to move focus to it via ArrowDown | Focus moves onto the disabled item (Base UI's list navigation does not skip disabled items) and it exposes aria-disabled="true" |
| dropdown-023 | submenu-indication | Render SubmenuTrigger | Trigger exposes aria-haspopup="menu" and renders the ChevronRight icon |
| dropdown-024 | support-submenus | Open SubmenuRoot; move focus outside the submenu (e.g. ArrowLeft to the parent item) | Submenu closes while the parent menu remains open |

