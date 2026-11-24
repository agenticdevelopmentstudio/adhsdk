
- **title**: Component MUST render the `title` prop as required content in a centered layout.
- **dashed-border**: Component MUST display a dashed border around the container.
- **non-optional-title**: Component MUST declare `title` as a required, non-optional prop, rejecting a missing value at the type level rather than leaving the runtime behavior undefined.
- **optional-icon**: Component MUST render the `icon` prop when provided, positioned above the title, and MUST NOT render the icon wrapper when `icon` is absent.
- **icon-size**: When `icon` is provided, the icon wrapper MUST constrain it to 24×24px (6×6 units).
- **optional-description**: Component MUST render the `description` prop when provided, positioned below the title, and MUST NOT render the description wrapper when `description` is absent.
- **optional-action**: Component MUST render the `action` prop when provided, positioned below the description, and MUST NOT render the action wrapper when `action` is absent.
- **classname**: Component MUST accept and apply a `className` prop for custom styling via class composition.
- **centered-content**: Component MUST center all content both horizontally and vertically within the container.
- **minimum-height**: Component MUST enforce a minimum height of 160 pixels.

