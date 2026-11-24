
- **renders-children**: Component MUST render all ReactNode children, in order.
- **container-class**: Component MUST apply the `lp-cta` CSS class to its container div.
- **children-untouched**: Component MUST NOT modify or filter props passed to children; all children render with their original props intact.
- **wrapping-centered-row**: Component MUST lay its children out as a horizontal row that wraps onto additional rows when they exceed the available width and centers the children on each row; it MUST NOT switch to a vertical axis at any width (see Appearance, **Layout**, for the exact values).
