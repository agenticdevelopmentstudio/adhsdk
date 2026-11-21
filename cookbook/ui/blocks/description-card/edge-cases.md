
- **Whitespace-only strings** are non-empty: they render a card with blank text; callers trim.
- **Renderer output is trusted**: the block does not sanitise what `renderMarkdown` returns.
- **Title only / description only** each render one slot.
