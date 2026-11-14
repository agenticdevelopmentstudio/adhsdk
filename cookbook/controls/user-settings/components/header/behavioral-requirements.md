
- **h2-element**: Component MUST render a semantic `<h2>` HTML element.
- **default-class**: Component MUST always include the `aws-header` CSS class on the rendered element.
- **class-composition**: Component MUST accept an optional `className` prop and combine the `aws-header` class with it, filtering out falsy values before joining.
- **children-content**: Component MUST render the content passed via the `children` prop (if any) inside the heading element.
- **non-empty-label**: Consumers MUST supply non-empty, meaningful content in `children`; an empty heading has no accessible label and is a barrier for screen reader users. The component still renders without error when `children` is empty (see #edge-cases).

