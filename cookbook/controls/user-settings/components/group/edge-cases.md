
- **Null title**: When `title` is `null` or `undefined`, the component treats it as falsy and does not render a title element.
- **Empty title**: When `title` is an empty string `""`, it is falsy and does not render a title element.
- **Falsy hint**: When `hint` is `null`, `undefined`, `false`, or empty string `""`, nothing renders in its place. When `hint` is the number `0`, the `<p class="aws-group__hint">` wrapper still does not render, but the literal text `0` renders directly inside the `<section>` — the `hint && <p>…</p>` pattern short-circuits to the falsy operand itself, and React renders that bare `0` as a text node.
- **No children**: When `children` is not provided, `undefined`, or `null`, the body div is rendered empty but still present.
- **React node children**: The `title`, `hint`, and `children` props accept `ReactNode`, which may be strings, numbers, elements, fragments, arrays, or null. All valid React node types MUST render correctly.
- **Multiple children**: When `children` is an array (list of React elements), all items MUST render within the body div without modification.
- **Custom className combinations**: When `className` contains multiple space-separated classes, all MUST be preserved and applied to the root element.
- **Null/empty custom className**: When `className` is `null`, `undefined`, or empty string `""`, it MUST be filtered out and not added to the element.

