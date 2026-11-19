
- **Role/trait**: Not customized — no explicit accessibility role is set;
  the text field carries the platform's own built-in text-field
  accessibility role.
- **Label requirements**: The component sets the label as the accessible
  title of every editable field (see titles-every-field-by-label), the way
  the sibling checkbox row links its switch to its label, so a screen
  reader announces each field by the row's title rather than as an unnamed
  text field. Because the link is made for every field in the
  editable-fields list, a variant's added fields (the secure row's revealed
  field) are titled by the label too.
- **Announce state changes**: Not applicable — the component has no loading
  state and never disables itself in source (see States); typed characters
  being entered or deleted are announced through the text field's own
  native accessibility value reporting, unmodified by this component.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-driven
  composition (no touch input path); the 44×44pt minimum is touch-interface
  guidance, not a pointer-interface requirement. No explicit control size is
  set on the text field, so it keeps the platform's regular system
  click-target metrics.
- **minimum-contrast-ratio**: The label and the field's typed text take the theme's primary-text role and a placeholder takes the placeholder-text role; the component checks neither, and the placeholder role's contrast floor is recorded in Design Decisions.

