
- **Empty or undefined className**: Component renders with base styles; missing or undefined className does not break rendering.
- **Invalid orientation value**: The source performs no runtime validation of the orientation value; whatever is passed flows directly into `aria-orientation` and the web-only `data-orientation` attribute. Because the web implementation's height/width styling is defined only for the literal values `"horizontal"` and `"vertical"` via `data-[orientation=...]` CSS selectors, an unrecognized value receives neither variant's sizing — the element keeps only `shrink-0` and the border background, with no explicit thickness or span. Callers MUST pass only `"horizontal"` or `"vertical"`; see **orientation-sync**.
- **Width/height override**: If parent layout or custom className sets explicit dimensions orthogonal to the separator's orientation, the separator renders within those constraints.
- **Zero-space layout**: If the separator's orthogonal dimension is constrained to less than 1px, the line may not be visible; the component does not resize itself.

