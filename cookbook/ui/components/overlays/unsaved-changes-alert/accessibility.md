
- **role**: Role SHOULD be `alertdialog`, because this is a destructive confirmation that interrupts the user (WAI-ARIA). The React/Web implementation deviates: it inherits `dialog` from AlertModal's underlying `Dialog` wrapper over base-ui's plain `Dialog` primitive, and the package's own tests query this prompt by role `dialog`.
- **label-requirement**: The modal's accessible name is its title, "Discard unsaved changes?".
- **description-requirement**: The description prop provides the accessible description of what will be lost. Implementations MUST associate the description text with the modal using `aria-describedby` or equivalent, even when the description is the empty string (see #requirements/render-description).
- **keyboard-navigation**: Focus MUST be trapped inside the modal while it is open. Neither Enter nor Escape MUST invoke `onDiscard` (#requirements/discard-requires-explicit-action); every dismissal path's outcome is defined in #requirements/dismissal-outcomes.
- **button-labels**: Both buttons MUST have accessible labels; "Discard" and "Stay" are the required labels.
- **minimum-touch-target**: Per [Apple HIG: Layout](https://developer.apple.com/design/human-interface-guidelines/layout) and [Material Design: Accessible design](https://m3.material.io/foundations/accessible-design/overview), both buttons MUST have a touch target of at least 44×44 pt (iOS) or 48×48 dp (Android); per [WCAG 2.5.5 Target Size (Enhanced)](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html), the web target is at least 44×44 CSS px.

