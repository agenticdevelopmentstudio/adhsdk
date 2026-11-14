
- **hr-element**: The component MUST render as an HTML `<hr>` element.
- **base-class**: The component MUST apply the class `{{app_prefix}}-divider` to the rendered element.
- **extra-class-name**: The component SHOULD accept an optional `className` prop that is appended to the base class.
- **implicit-separator-role**: The component MUST NOT set an explicit `role` attribute; it relies on the implicit `separator` role of `<hr>`.
- **filter-empty-classes**: The component MUST drop falsy `className` values before joining the class names.

