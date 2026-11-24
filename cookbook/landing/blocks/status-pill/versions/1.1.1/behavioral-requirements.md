
- **accept-children**: Component MUST accept and render any `ReactNode` as children content.
- **base-style**: Component MUST render the root element in the pill's base style (see **Appearance**). The React/Web implementation applies this via the `lp-status` CSS class.
- **accent-style**: When the `free` prop is explicitly `true`, the component MUST render the accented style — a distinct border color over a dimmed background (see **Appearance**). The React/Web implementation applies this by adding the `lp-status--free` CSS class alongside `lp-status`.
- **accent-opt-in**: When the `free` prop is absent or falsy, the component MUST NOT render the accented style; accenting is opt-in, never the default.
- **status-conveyed-by-text**: The status MUST be conveyed by the children text content; the accented border and background are supplementary and MUST NOT be the only way the status is communicated.

