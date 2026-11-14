
- **definition-of-present**: The component MUST treat a value as present only when it is not null, not undefined, not false, not the empty string and not zero. Every requirement and every Platform Notes bullet uses this one definition; the web source tests it with a truthiness check.
- **error-shown-when-present**: When `error` prop is present, the component MUST render that value in the error presentation (red, monospace, small text).
- **error-takes-precedence**: When both `error` and `hint` props are present, the component MUST show only the error, not the hint.
- **hint-shown-without-error**: When `error` prop is not present, and `hint` prop is present, the component MUST render the hint in the hint presentation (dim text, monospace, small text).
- **renders-nothing-when-empty**: When neither `error` nor `hint` is present, the component MUST return null (render nothing).
- **error-id-applied**: When `errorId` prop is provided, the component MUST apply that value as the `id` attribute on the error span element.
- **error-id-only-on-error**: When `errorId` prop is provided, the `id` attribute MUST be applied only to the error span, never to the hint span.
- **caller-class-name-merged**: When the caller supplies a style override (web: the `className` prop), the component MUST apply it on top of the default styling, and a caller style MUST win over any default it conflicts with. Platform equivalents are in Platform Notes.
- **supports-rich-content**: The component MUST accept any content type the platform renders (web: string, element, fragment or number) in both `hint` and `error` for rendering when present. A value that is not present — including the number `0` or an empty string `""` — is treated as absent rather than rendered; see **renders-nothing-when-empty**.

