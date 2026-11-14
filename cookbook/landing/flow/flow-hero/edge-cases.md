
- **Null headline or sub**: The component requires both `headline` and `sub` as mandatory props (not optional in the type signature); passing null or undefined violates the type contract. Behavior is undefined if coerced to render.
- **Empty content slots**: Only `undefined` hides the `children`, `meta` and `shot` containers; `null` and `""` still render an empty one (see the **Gate the `children`, `meta`, and `shot` containers** design decision). See **actions-container**, **meta-paragraph**, **shot-container**, and vectors flow-hero-013 through flow-hero-015. 
- **Omitted mark**: When `mark` is `undefined`, nothing renders for it and the headline is the first element in the `Wrap` (see **mark**).
- **Nested components in mark**: The `mark` prop is rendered as-is; if the host provides complex nested React elements, they render without modification. No validation is performed on the mark's content or structure.
- **Very long text**: Headline and subheading text that exceeds single-line length will wrap per CSS (managed by stylesheet). The component imposes no text truncation or ellipsis.
- **Rich content in headline and sub**: Both `headline` and `sub` accept ReactNode, allowing the host to embed spans, links, or other elements. The component renders them as-is without sanitization.
- **Uppercase meta opt-out**: There is no prop to turn the `meta` uppercasing off; see the **Uppercase the `meta` text via CSS** design decision for the opt-out.

