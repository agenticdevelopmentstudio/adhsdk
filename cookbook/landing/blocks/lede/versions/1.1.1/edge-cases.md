
- **Empty children**: If children is empty string or not provided, component renders an empty paragraph; no guard prevents this (lede-009).
- **Null or undefined className**: Optional className prop defaults to undefined; filtered out via **clean-class-attribute**.
- **Empty-string className**: An explicit `className=""` is also falsy and is filtered out the same way, leaving only `lp-lede`.
- **Whitespace-only className**: A className that is only whitespace (e.g. `" "`) is truthy, so **clean-class-attribute** does not filter it; the rendered class attribute keeps the stray whitespace token.
- **Multiple class names in className**: If className contains multiple space-separated class names, all are appended after `lp-lede`.
- **No className provided**: Component renders with only the `lp-lede` class.

