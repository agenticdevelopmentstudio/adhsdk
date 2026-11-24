
- **Role**: Implicit button role from native HTML `<button>` element.
- **Label requirements**: See #requirements/consumer-accessible-label.
- **Button type**: Component uses semantic HTML button element, providing built-in keyboard support (Space and Enter keys trigger the button in user agents).
- **Custom attributes**: ARIA attributes (aria-label, aria-pressed, aria-expanded, etc.) pass through rest props to the button element; see #requirements/accept-html-attributes.
- **Minimum tap target**: Minimum tap/click target size is determined by the `aws-button` stylesheet rules; the component enforces no minimum size in code. See Appearance for the resulting size.

