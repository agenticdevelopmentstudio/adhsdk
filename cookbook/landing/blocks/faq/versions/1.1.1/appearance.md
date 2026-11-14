
The component renders semantic HTML with no inline styles. Appearance is entirely controlled by external CSS via the `lp-faq` class on the root container and browser default `<details>`/`<summary>` styling:

- **Container**: A `<div>` with class `lp-faq` wraps all entries.
- **Entry structure**: Each entry is a native `<details>` element.
- **Summary styling**: Browser default — typically bold text, with a disclosure triangle before the text. Exact appearance (icon shape, animation, colors) depends on the stylesheet.
- **Details content**: Rendered as block content within the details element. Browser default includes margin/padding between summary and content.
- **Visual state indicators**: The browser provides a visual indicator (disclosure triangle rotation or similar) when the details element is open vs. closed.

