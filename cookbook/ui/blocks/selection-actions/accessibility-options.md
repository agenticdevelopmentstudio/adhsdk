
- **Reduce Motion**: The component itself does not define motion; animation handling is delegated to the Button and AlertModal components. It SHOULD respond to prefers-reduced-motion if those components do.
- **Increase Contrast**: The Button component's styling MUST meet Increase Contrast requirements; Selection Actions adds no additional styling that would interfere.
- **Differentiate Without Color**: Disabled state MUST be communicated via the button's disabled attribute (browser default), not by color alone. Dividers use color; their separating function is structural and announced via ARIA role, not color-dependent.

