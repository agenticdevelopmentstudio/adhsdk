
- **Empty sites array**: Component renders a navigation container with no orbs. No error is thrown; the component degrades gracefully.
- **currentSite not in sites**: No orb receives the current state. The component does not error; aria-current is not applied to any link.
- **currentSite is null/undefined**: Same as above; no orb is marked current.
- **Missing site properties**: The component does not validate site properties and renders them directly without null or undefined checks. If any required property (url, name, emoji, iconGradient) is missing, the component will render an incomplete or broken link and the caller is responsible for ensuring all site data is well-formed.
- **className prop is empty string**: Empty strings are filtered out before joining; class attribute does not contain empty tokens.
- **docked=false and docked=undefined**: No `is-docked` class applied; both cases are treated identically.

