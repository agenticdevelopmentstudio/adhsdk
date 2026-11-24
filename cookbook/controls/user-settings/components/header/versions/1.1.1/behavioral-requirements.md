
- **h2-element**: Component MUST render a semantic `<h2>` HTML element.
- **default-class**: Component MUST always include the `aws-header` CSS class on the rendered element.
- **class-composition**: Component MUST combine the `aws-header` class with any `className` prop provided, filtering out falsy values before joining.
- **children-content**: Component MUST render the content passed via the `children` prop (if any) inside the heading element.
- **classname-prop**: Component MUST accept an optional `className` prop to allow consumer-supplied CSS classes to be applied alongside the default class.

