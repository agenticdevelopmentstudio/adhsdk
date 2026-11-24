
- **Long or non-wrapping text**: The base style sets `white-space: nowrap` (see #appearance), so the component MUST NOT wrap children onto multiple lines; long content overflows its container instead, and the parent SHOULD size or scroll to accommodate it.
- **Nesting inside inline-only content**: The component always renders a `<p>` element (see #accessibility). The component MUST NOT be nested inside another `<p>`, a `<button>`, or other elements that only accept inline content, since that produces invalid HTML. CSS (such as overriding `display`) does not change what HTML nesting is valid, and the component has no `as` or element prop, so callers MUST NOT place it in phrasing-only content and SHOULD place it in block-level content.
- **`free` prop omitted**: When `free` is not provided, the component MUST behave identically to `free={false}` (see #requirements/accent-opt-in).

