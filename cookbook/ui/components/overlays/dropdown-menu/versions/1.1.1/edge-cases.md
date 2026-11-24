
- **Empty menu**: Menu with no items still renders and positions correctly; no minimum height constraint forces item rendering.
- **Very long item text**: Item text that exceeds the available menu width truncates with an ellipsis rather than wrapping (see the long-item-text-truncates design decision).
- **Disabled items**: Items with a `disabled` prop render in disabled state and do not respond to click events.
- **No trigger provided**: `MenuPrimitive.Root` renders without error. Without a Trigger child, the menu has no interactive control that opens it and MUST remain closed unless opened programmatically via a controlled `open` prop; Base UI emits no dev-time warning for this case.
- **Multiple submenus**: Nested submenus at depth >1 position relative to their parent submenu; no depth limit enforced by component.
- **Rapid item clicks**: Clicking multiple items rapidly before menu closes closes menu on first click; subsequent clicks do not interact with menu items if menu is already closed.
- **Focus on disabled item**: Arrow-key navigation (ArrowUp/ArrowDown/Home/End) does NOT skip disabled items — Base UI's list navigation runs with an empty `disabledIndices` set, so a disabled item can still receive focus and is exposed via `aria-disabled="true"`; it is only dimmed visually (`pointer-events: none`, reduced opacity). The one exception: when the menu opens via the keyboard and the first item is disabled, that initial focus placement skips it.
- **Menu with only separators**: Menu renders separators without error; visually appears as empty menu with dividers.
- **Checkbox item without checked prop**: CheckboxItem without explicit `checked` prop behaves as unchecked (no indicator icon shown).
- **Radio item without value**: A RadioItem in a RadioGroup without a `value` prop MUST NOT participate in group selection: it renders and remains clickable, but selecting it does not change the RadioGroup's value and it never renders the selected indicator.

