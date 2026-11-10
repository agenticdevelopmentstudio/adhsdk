
- **hr-element**: The component MUST render as an HTML `<hr>` element.
- **base-class**: The component MUST apply the class `{{app_prefix}}-divider` to the rendered element.
- **extra-class-name**: The component SHOULD accept an optional `className` prop that is appended to the base class.
- **filter-empty-classes**: The component MUST NOT render empty or null class names; class filtering MUST remove falsy values before joining.

