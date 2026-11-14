
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
| dropdown-020 | focus-management | Open menu from the keyboard (ArrowDown on the focused trigger) | Focus moves onto the first focusable item |
| dropdown-021 | checkbox-state-announcement | Render CheckboxItem with checked={true}; inspect DOM | Item exposes aria-checked="true" |
| dropdown-022 | disabled-state-announcement | Render MenuItem with disabled={true}; attempt to move focus to it via ArrowDown | Focus moves onto the disabled item (Base UI's list navigation does not skip disabled items) and it exposes aria-disabled="true" |
| dropdown-023 | submenu-indication | Render SubmenuTrigger | Trigger exposes aria-haspopup="menu" and renders the ChevronRight icon |
| dropdown-024 | support-submenus | Open SubmenuRoot; move focus outside the submenu (e.g. ArrowLeft to the parent item) | Submenu closes while the parent menu remains open |
| dropdown-025 | focus-on-pointer-open | Open menu via trigger click | Focus moves into the menu popup; no item is focused until an arrow key or hover |
| dropdown-026 | keep-open-when-close-on-click-false | Render open menu with a CheckboxItem `closeOnClick={false}`; click it | Menu stays open; `onCheckedChange` fires |
| dropdown-027 | keyboard-navigation | Open menu; press End, then Home | Focus moves to the last item, then the first item |
| dropdown-028 | keyboard-navigation | Render under a right-to-left direction; open a submenu with ArrowLeft, close it with ArrowRight | Submenu opens on ArrowLeft and closes on ArrowRight |
| dropdown-029 | disabled-state-announcement | Click a disabled MenuItem | Its click handler is not called and the menu stays open |
| dropdown-030 | radio-state-announcement | Render a selected RadioItem; inspect DOM | Item exposes `aria-checked="true"` |
| dropdown-031 | closed-without-trigger | Render `DropdownMenu` with no Trigger and no `open` prop | Menu stays closed |
| dropdown-032 | ignore-valueless-radio | Click a RadioItem with no `value` inside a RadioGroup | RadioGroup value is unchanged; no selected indicator renders |
| dropdown-033 | scale-text-with-root-font-size | Inspect the computed `font-size` of a MenuItem at root font sizes 16px and 20px | Item text size scales with the root font size |
| dropdown-034 | meet-text-contrast | Compute item text contrast against the menu surface in the active theme | Contrast ratio is at least 4.5:1; source does not verify this |
| dropdown-035 | minimum-target-size | Measure a MenuItem hit box on a coarse pointer | Target behavior: at least 44×44px. Source grows rows by a fixed fraction only, so this vector fails today |
