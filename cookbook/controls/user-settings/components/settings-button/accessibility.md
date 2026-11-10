
- **Role**: Implicit button role from native HTML `<button>` element.
- **Label requirements**: Component MUST receive accessible text content either as children (text nodes or elements with text content) or via `aria-label` attribute passed through rest props.
- **Button type**: Component uses semantic HTML button element, providing built-in keyboard support (Space and Enter keys trigger the button in user agents).
- **Custom attributes**: All ARIA attributes (aria-label, aria-pressed, aria-expanded, etc.) MUST be passable via rest props and applied to the button element.
- **Minimum tap target**: Minimum tap/click target size is determined by CSS styling applied via the `aws-button` and variant classes; the component enforces no minimum size in code.

