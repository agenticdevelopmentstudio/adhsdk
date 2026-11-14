
- **render-container**: Component MUST render a div with class `lp-roadmap` as the root element.
- **render-eyebrow-when-present**: Component MUST render a span with class `lp-eyebrow` containing the `eyebrow` prop's value whenever `eyebrow` is any value other than `undefined` (including `null`, `""`, `false`, or any other ReactNode).
- **eyebrow-omitted-when-absent**: Component MUST NOT render an eyebrow span element when the `eyebrow` prop is exactly `undefined` (prop omitted).
- **render-children**: Component MUST render all child content within the root container.
- **eyebrow-precedes-children**: Component MUST render the eyebrow span (when present) before `children` within the root container.

