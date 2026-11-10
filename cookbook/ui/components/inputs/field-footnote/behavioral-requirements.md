
- **error-shown-when-present**: When `error` prop is set to a truthy value, the component MUST render that value in the error presentation (red, monospace, small text).
- **error-takes-precedence**: When both `error` and `hint` props are truthy, the component MUST show only the error, not the hint.
- **hint-shown-without-error**: When `error` prop is not set or is falsy, and `hint` prop is truthy, the component MUST render the hint in the hint presentation (dim text, monospace, small text).
- **renders-nothing-when-empty**: When both `error` and `hint` props are falsy or undefined, the component MUST return null (render nothing).
- **error-id-applied**: When `errorId` prop is provided, the component MUST apply that value as the `id` attribute on the error span element.
- **error-id-only-on-error**: When `errorId` prop is provided, the `id` attribute MUST be applied only to the error span, never to the hint span.
- **caller-class-name-merged**: When `className` prop is provided, the component MUST append it to the default classes; a caller class MUST override any default class it conflicts with.
- **supports-react-node-content**: The component MUST accept any node type (string, element, fragment, or number) in both `hint` and `error` props for rendering when present. A falsy value — including the number `0` or an empty string `""` — is treated as absent rather than rendered; see **renders-nothing-when-empty**.

