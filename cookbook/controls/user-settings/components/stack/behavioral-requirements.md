
- **render-children**: Both VStack and HStack MUST render all child elements passed via the `children` prop.
- **apply-gap-prop**: The component MUST apply the `gap` prop as a CSS `gap` property; when `gap` is a number, it MUST be converted to a pixel string (e.g., `16` becomes `"16px"`); when `gap` is a string, it MUST be applied as-is.
- **gap-omitted-when-unset**: When the `gap` prop is not provided, the computed inline style MUST have no `gap` declaration.
- **apply-align**: The component MUST apply the `align` prop directly to the CSS `alignItems` property.
- **apply-justify**: The component MUST apply the `justify` prop directly to the CSS `justifyContent` property.
- **apply-inline-styles**: The component MUST merge provided `style` prop values with layout-specific styles, giving precedence to `style` prop values when both are present.
- **apply-class-names**: The component MUST apply the base class name `aws-stack` to the root element; MUST apply either `aws-stack--v` for VStack or `aws-stack--h` for HStack; MUST append the `className` prop if provided.
- **no-rest-prop-forwarding**: The component MUST NOT forward any prop other than `children`, `gap`, `align`, `justify`, `className`, and `style` to the root element; `id`, `role`, `aria-*`, and any other attribute cannot be set through Stack's props.
- **render-non-semantic-div**: The component SHOULD render a `div` element for flexible, CSS-class-based styling; because a `div` carries no ARIA semantics, this renders a non-semantic element that adds no role or landmark to the accessibility tree.

