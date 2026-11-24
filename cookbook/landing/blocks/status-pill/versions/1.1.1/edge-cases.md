
- **Long or non-wrapping text**: The base style sets `white-space: nowrap` (see **Appearance**), so the component MUST NOT wrap children onto multiple lines; long content overflows its container instead, and the parent SHOULD size or scroll to accommodate it.
- **Nesting inside inline-only content**: The component always renders a `<p>` element (see **Accessibility**). The component MUST NOT be nested inside another `<p>`, a `<button>`, or other elements that only accept inline content, since that produces invalid HTML; callers needing an inline pill SHOULD override `display` on the root or wrap it in block-level content.
- **`free` prop omitted**: When `free` is not provided, the component MUST behave identically to `free={false}` (see **accent-opt-in**).

