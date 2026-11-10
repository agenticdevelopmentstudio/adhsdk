
- **entry-prop**: The component MUST accept a `HelpEntry` prop containing the popover content.
- **side-prop**: The component MUST accept an optional `side` prop controlling popover vertical/horizontal positioning (`"top"`, `"bottom"`, `"left"`, or `"right"`), with `"bottom"` as the default.
- **align-prop**: The component MUST accept an optional `align` prop controlling popover alignment along the positioning axis (`"start"`, `"center"`, or `"end"`), with `"start"` as the default.
- **flavor-icon**: The component MUST render an icon corresponding to the flavor value in `entry.flavor`, defaulting to `"info"` if not specified. The three supported flavors are `"help"` (a help/question icon), `"info"` (an information icon), and `"new"` (a sparkle/announcement icon).
- **body-text**: The component MUST render the text from `entry.body` in the popover panel.
- **arrow**: The component MUST render an arrow pointing from the popover to its anchor control.
- **optional-title**: If `entry.title` is provided, the component MUST render it as a distinct, visually emphasized element. If `entry.title` is not provided or is empty, the component MUST NOT render a title section.
- **fixed-width**: The component MUST constrain the popover panel width to 320px.
- **accessible-name**: The component MUST set an accessible name on the popover panel combining the flavor label (Help, Information, or What's new) with the title if present. The pattern MUST be `"{flavor}: {title}"` when title exists, or `"{flavor}"` when title is absent.
- **decorative-icon**: The component MUST mark the flavor icon as decorative to assistive technology, since the flavor information is conveyed by the panel's accessible name.
- **color-tokens**: The component MUST apply the design system color tokens for text: `apt-text` for the title, `apt-text-muted` for the icon and body text.

