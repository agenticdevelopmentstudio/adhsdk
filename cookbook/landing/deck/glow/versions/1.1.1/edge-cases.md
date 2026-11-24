
- **Undefined className**: Falsy; filtered from the combined class list. Element renders with 'lp-glow' only.
- **Empty string className**: Empty string is falsy and filtered. Element renders with 'lp-glow' only.
- **Whitespace-only className**: The string is truthy, so it is not filtered. The rendered `class` attribute becomes `class="lp-glow   "`; a browser's class-attribute tokenizer splits on ASCII whitespace and discards empty tokens, so this resolves to the single token `lp-glow`.
- **Multi-token className**: Each whitespace-separated token supplied in `className` (e.g. `"a b"`) is preserved as its own token in the rendered class list, alongside `lp-glow`.

