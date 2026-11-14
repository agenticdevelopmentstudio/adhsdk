
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| menu-button-001 | button-element | Render with default props | Button element with `type="button"` is rendered |
| menu-button-002 | accessible-label | `label="Menu"` | `aria-label="Menu"` is present on button element |
| menu-button-003 | menu-icon-default | No `icon` prop | Three `<span class="mb-bar">` elements render |
| menu-button-004 | close-icon-variant | `icon="close"` | Two `<span class="mb-bar">` elements render |
| menu-button-005 | menu-button-class | Default render | Button has class `menu-button` |
| menu-button-006 | close-variant-class | `icon="close"` | Button has classes `menu-button` and `menu-button--close` |
| menu-button-007 | custom-classname | `className="custom-class"` | Button includes `custom-class` in its class list |
| menu-button-008 | button-attribute-passthrough | `onClick={handler}` | Handler is invoked on button click |
| menu-button-009 | button-attribute-passthrough | `disabled={true}`, then simulate a click | Button has the `disabled` attribute; the `onClick` handler is not invoked |
| menu-button-010 | menu-icon-default, close-icon-variant | Toggle `icon` prop from `'menu'` to `'close'` | Bar count changes from three to two; `menu-button--close` class is added |
| menu-button-011 | plain-element-bars | Render with default props | Each `.mb-bar` element's tag name is `SPAN`; no `<svg>` element is present |
| menu-button-012 | menu-icon-default | `icon="menu"` (explicit) | Three `<span class="mb-bar">` elements render, same as the default |
| menu-button-013 | menu-icon-default, close-icon-variant | `icon="hamburger"` (value outside the type) | Two `<span class="mb-bar">` elements render, and `menu-button--close` is NOT applied — the third bar is gated on `icon === 'menu'` specifically (not `icon !== 'close'`), so a value that is neither `'menu'` nor `'close'` renders neither the full menu icon nor the close variant |
| menu-button-014 | custom-classname | No `className` prop | Button's `class` attribute is exactly `menu-button` with no extra whitespace or empty tokens |
| menu-button-015 | relative-positioning | Default render | `.menu-button` computed `position` is `relative`; the `::after` element's computed size is 44×44px |
| menu-button-016 | accessible-label | `label` prop omitted (bypassing the type system) | No `aria-label` attribute is present on the button |
| menu-button-017 | accessible-label | `label=""` | `aria-label=""` is present; the button has an empty accessible name |
| menu-button-018 | custom-classname, close-variant-class | `icon="close" className="custom-class"` | Button's `class` attribute is `menu-button menu-button--close custom-class` |

