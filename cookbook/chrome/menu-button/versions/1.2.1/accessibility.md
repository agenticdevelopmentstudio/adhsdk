
- **Role**: Button (implicit from `<button>` element).
- **Accessible name**: MUST be provided via the required `label` prop, which is applied as `aria-label`. The button has no visible text, so an accessible name is required.
- **Icon symbol**: Hamburger menu and close icons are purely visual; the accessible name provided by `label` replaces them functionally (e.g., "Menu" or "Close menu").
- **Keyboard navigation**: Button is fully keyboard accessible via standard `<button>` element behavior; may be activated via Space or Enter keys.
- **Assistive technology**: Screen readers will announce the button's accessible name and role.
- **Toggle state (consumer-managed)**: The component itself tracks no open/closed state. When used to toggle a menu, the composing screen SHOULD pass `aria-expanded` and `aria-controls` (referencing the menu it opens) through the button's pass-through props, and SHOULD update `label` to match the current state (e.g. "Open menu" / "Close menu").
- **Minimum tap target**: The button's visible icon box is 32×32px (`--menu-size`), but the button exposes a 44×44px hit area via an absolutely positioned `::after` pseudo-element (`--menu-hit: 44px`), centred on the button because `.menu-button` is `position: relative` (`css/base.css`; see **relative-positioning**). This meets the 44×44pt minimum tap target guideline.

