
- **render-paragraph**: Component MUST render a `<p>` HTML element.
- **apply-default-class**: Component MUST apply the class name `aws-explanation` to the rendered element.
- **render-children**: Component MUST render all provided `children` content inside the paragraph element.
- **accepts-optional-classname**: Component MAY accept an optional `className` prop.
- **combine-classnames**: Component MUST combine the default class name with the optional `className` prop, separated by a space, if `className` is provided.
- **filter-falsy-classnames**: Component MUST filter out falsy or empty class name values before rendering to prevent invalid class attributes.

