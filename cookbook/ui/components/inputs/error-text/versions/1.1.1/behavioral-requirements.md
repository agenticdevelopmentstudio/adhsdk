
- **render-when-error-present**: The component MUST render an element with `role="alert"` when the `error` prop is a non-empty string, signaling to assistive technologies that the content is a time-sensitive alert or error message.
- **render-nothing-when-error-absent**: The component MUST return `null` and render nothing when the `error` prop is `null`, `undefined`, or an empty string.
- **include-error-text-content**: The component MUST render the exact text from the `error` prop as the element's text content.
- **apply-error-color**: The component MUST apply the design system's error color token to the rendered element by default, and this color MUST NOT be overridden by a caller-supplied `className`. See Design Decision **color-and-role-non-negotiable**.
- **default-text-size**: The component applies the design system's small text-size token to the rendered element by default. Callers MAY override the size via `className` for dense layouts; overriding the size MUST NOT affect the error color or the alert role.
- **support-classname-prop**: The component MUST accept an optional `className` prop and merge it with the default classes using the `cn()` utility function.
- **error-text-render-as-paragraph**: The `ErrorText` variant MUST render the alert as a `<p>` element.
- **dialog-error-text-render-as-span**: The `DialogErrorText` variant MUST render the alert as a `<span>` element with block-level display, to create a line-break effect without nesting `<p>` inside `<p>`.
- **dialog-error-text-top-margin**: The `DialogErrorText` variant MUST apply the design system's small top-margin token to provide vertical spacing from the dialog description text.

