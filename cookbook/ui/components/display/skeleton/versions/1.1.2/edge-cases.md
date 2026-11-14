
- **Empty className prop**: When `className` is `undefined`, `null`, or an empty string, the component SHOULD apply only its built-in pulsing animation, corner radius, and surface background (see **pulsing-animation**, **rounded-corners**, **surface-background**).
- **Invalid CSS class names in className**: The component MUST accept any string in the `className` prop without validation or error handling. Invalid class names are silently passed through; rendering behavior depends on whether the CSS classes exist.
- **Very large dimensions**: No minimum or maximum size constraints exist. The component renders at any size specified via `className` or `style`.
- **Rendering in disabled or read-only contexts**: Not applicable. The component is not interactive.
- **Animation performance**: The pulsing animation runs continuously by default. Under `prefers-reduced-motion`, the component does not disable itself automatically; a consumer suppresses it via the **reduced-motion-support** override.

