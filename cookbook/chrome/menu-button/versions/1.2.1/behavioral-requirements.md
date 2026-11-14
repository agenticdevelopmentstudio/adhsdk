
- **button-element**: Component MUST render as an HTML `<button>` element with `type="button"`.
- **accessible-label**: Component MUST accept a required `label` prop that is used as the button's accessible name via `aria-label`.
- **menu-icon-default**: Component MUST display three bars (hamburger icon) when no `icon` prop is provided or when `icon="menu"`.
- **close-icon-variant**: Component MUST display two bars crossed (close icon) when `icon="close"`.
- **button-attribute-passthrough**: Component MUST pass through all standard `HTMLButtonElement` attributes (e.g., `disabled`, `onClick`, `className`, `data-*` attributes).
- **menu-button-class**: Component MUST apply the CSS class `menu-button` to the button element.
- **close-variant-class**: Component MUST apply the CSS class `menu-button--close` to the button element when `icon="close"`.
- **custom-classname**: Component MUST allow custom CSS classes to be added via a `className` prop and combine them with the component's internal classes.
- **plain-element-bars**: Component MUST render bars as plain `<span>` elements with class `mb-bar` rather than as an SVG, to enable animation and color inheritance.
- **relative-positioning**: The button MUST be `position: relative` so the 44×44px `::after` hit-area pseudo-element centers on it correctly (`css/base.css`).

