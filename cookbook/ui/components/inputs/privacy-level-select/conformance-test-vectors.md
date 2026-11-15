
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| privacy-001 | render-trigger-with-current-level | value="only-me" | Trigger displays "Only me" text |
| privacy-002 | render-chevron-icon | Component mounted | Trigger displays chevrons-up-down icon (14px, right-aligned) |
| privacy-003 | open-popover-on-trigger-click | User clicks trigger, popover closed | Popover opens; aria-expanded="true" on trigger |
| privacy-004 | close-popover-on-selection | User clicks "Hub members" option, popover open | Popover closes; onChange called with "hub"; aria-expanded="false" on trigger |
| privacy-005 | close-popover-on-escape | Popover open, user presses Escape | Popover closes; aria-expanded="false" |
| privacy-006 | navigate-with-arrow-keys | Popover open, cursor on "hub", user presses ArrowDown | Cursor moves to "public"; aria-activedescendant updates to "public" option ID |
| privacy-007 | clamp-navigation-at-bounds | Popover open, cursor on "public", user presses ArrowDown | Cursor stays on "public"; does not move to disabled "Team / Org" option |
| privacy-008 | select-with-enter-or-space | Popover open, cursor on "only-me", user presses Enter | Popover closes; onChange called with "only-me" (and nothing else) |
| privacy-009 | open-popover-with-trigger-keys | Trigger focused, popover closed, user presses Space | Popover opens; aria-expanded="true"; cursor initializes to current value |
| privacy-010 | display-all-three-enabled-options | Popover open | Three clickable options rendered: "Only me", "Hub members", "Public" |
| privacy-011 | show-check-on-selected-option | value="hub", popover open | Check icon (gold, 14px) visible only on "Hub members" option |
| privacy-012 | display-disabled-coming-soon-option | Popover open | "Team / Org" option rendered with 40% opacity and "Coming soon" badge |
| privacy-013 | highlight-hovered-option | Popover open, user hovers on "public" option | Option background changes to `apt-highlight/15` |
| privacy-014 | highlight-keyboard-focused-option | Popover open, cursor on "hub" via arrow navigation | Option background changes to `apt-highlight/15` |
| privacy-015 | respect-disabled-prop | disabled={true}, user clicks trigger | Popover does not open; onChange is not called |
| privacy-016 | apply-disabled-styling | disabled={true} | Trigger renders with opacity 50%, cursor not-allowed |
| privacy-017 | focus-listbox-on-open | User opens popover via trigger click | Listbox surface receives focus (can accept keyboard input immediately) |
| privacy-018 | reset-cursor-to-value-on-open | value="public", user clicks trigger to open | Cursor initializes to "public" option (keyboard can select immediately without navigation) |
| privacy-020 | read-value-prop | value prop changes from "only-me" to "public" externally while the popover is closed, then it is opened | Trigger shows "Public" with the Globe icon; on open the "Public" option has `aria-selected="true"` and the check icon, the other options `aria-selected="false"`; `aria-activedescendant` points to the "Public" option |
| privacy-021 | call-onchange-with-selected-level | User clicks "hub" option | onChange callback invoked with argument "hub" (string, not object) |
| privacy-022 | support-aria-label | ariaLabel="Profile visibility", rendered | Trigger and listbox both have aria-label="Profile visibility" |
| privacy-023 | apply-aria-haspopup | Component rendered | Trigger element has aria-haspopup="listbox" |
| privacy-024 | apply-aria-expanded | Popover open | Trigger has aria-expanded="true"; when closed, aria-expanded="false" |
| privacy-025 | apply-aria-activedescendant | Popover open, cursor on "hub" | Listbox has aria-activedescendant set to ID of "hub" option |
| privacy-026 | apply-role-listbox | Popover open | Listbox surface has role="listbox" |
| privacy-027 | apply-role-option-to-entries | Popover open | All four options (three enabled + "Team / Org") have role="option" |
| privacy-028 | set-aria-selected | value="only-me", popover open | "Only me" option has aria-selected="true"; others have aria-selected="false" |
| privacy-029 | set-aria-disabled-on-coming-soon | Popover open | "Team / Org" option has aria-disabled="true" |
| privacy-030 | support-custom-class-name | className="custom-class" prop passed | Trigger element includes custom-class in its className |
| privacy-031 | prevent-default-on-trigger-keys | Trigger focused, user presses ArrowDown to open | Browser default behavior is prevented; page does not scroll |
| privacy-032 | prevent-default-on-navigation-keys | Popover open, user presses ArrowUp | Browser default behavior is prevented; page does not scroll |
| privacy-033 | use-unique-option-ids | Two instances rendered on one page, each opened in turn (opening one dismisses the other) | Every option `id` is unique across the page (each of the form `<useId>-opt-only_me`, `-opt-hub`, `-opt-public`); each listbox's `aria-activedescendant` resolves to an option inside that same listbox |
| privacy-034 | truncate-trigger-text | Trigger width constrained, long label text | Label text truncates with an ellipsis; the icon does not shrink and remains fully visible |
| privacy-035 | read-value-prop | popover open with cursor on "only-me" (value "only-me"), then ArrowDown to "hub", then `value` changes externally to "public" | Trigger shows "Public" and the check moves to "Public"; `aria-activedescendant` still points to the "hub" option (cursor not moved) |
| privacy-036 | prevent-default-on-navigation-keys | Popover open, user presses Escape | The keydown's default is prevented; popover closes; no `onChange` call |
| privacy-037 | respect-disabled-prop | Popover open, then `disabled` becomes `true` | Popover stays open (see the disabled-while-open Design Decision); trigger renders at 50% opacity with cursor `not-allowed` |
| privacy-038 | open-popover-with-trigger-keys | Trigger focused, popover closed, user presses Enter | Popover opens; `aria-expanded="true"`; listbox receives focus; cursor on the current value |
| privacy-039 | select-with-enter-or-space | Popover open, cursor on "hub", user presses Space | Popover closes; `onChange` called once with "hub" |
