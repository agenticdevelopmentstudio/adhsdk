
- **Null or undefined children**: If `children` is `undefined` or `null`, the heading renders empty but still displays the `<h2>` element with the `aws-header` class. MUST render successfully without error. Consumers MUST NOT render a `Header` with no content: an empty heading has no accessible label and is a barrier for screen reader users (see #accessibility above).
- **Empty className**: If `className` is an empty string or `undefined`, only the `aws-header` class is applied. MUST NOT produce duplicate spaces or malformed class attributes.
- **Multiple className values**: If `className` contains multiple space-separated class names (e.g., `"class1 class2"`), the component MUST preserve all of them when composing with `aws-header`.
- **Special characters in className**: If `className` contains special characters or unusual values, the component MUST pass them through to the DOM without sanitization (delegating to React's default behavior).
- **Non-string children**: If `children` is a React component, element, or other `ReactNode`, the component MUST render it as-is without type checking.

