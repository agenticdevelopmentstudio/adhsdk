
- **active-theme**: The control MUST accept the id of the currently active theme as an input value.
- **mark-active-selection**: The control MUST display the theme identified by the active theme id as the current selection.
- **emit-theme-change**: The control MUST invoke a change callback with the newly selected theme's id whenever the user picks a different theme.
- **render-theme-options**: The control MUST present one selectable option per theme in the available theme registry, showing each theme's label as the visible text and using each theme's id as the underlying value.
- **unique-control-id**: The control MUST generate a unique identifier for its selection element so that multiple instances on the same page do not collide.
- **label-control**: The control MUST render a visible label that is programmatically associated with the selection element via the unique identifier.
- **group-container**: The control MUST wrap the label and selection element in a single container element, associating them as one interaction unit.
- **accessible-label**: The control MUST expose the accessible name "Select reading theme" on the selection element for screen reader users.

