
- **Undefined children**: If `children` is `undefined` or `null`, the component MUST render an empty div with layout classes applied.
- **Empty children array**: If `children` is an empty array, the component MUST render an empty div with layout classes applied.
- **Gap as zero**: If `gap={0}`, the component MUST apply `gap: "0px"`; if `gap="0"`, it MUST apply `gap: "0"`.
- **Conflicting inline styles**: If `style` contains `gap`, `alignItems`, or `justifyContent`, those values MUST take precedence over the `gap`/`align`/`justify` props, because `style` is spread last when merging.
- **Empty or absent className**: If `className` is not provided or is an empty string, the class attribute contains no empty or extra whitespace tokens.

