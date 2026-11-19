
- **Role/trait**: Inherited unmodified from the text edit row — no
  explicit accessibility role override appears in either file; the
  platform's secure text field carries its own built-in secure-text-field
  accessibility role.
- **Label requirements**: Both fields the row edits — the masked field and
  the plain field shown while revealed — take their accessible title from
  the row's label (**titles-fields-with-label**), as the sibling checkbox row
  ([adhsdk.ingredient.ui.settings.rows.checkbox-view](cookbook:e9c10ff7-4e13-4007-a963-d2a9e4006745))
  links its switch to its label, so a screen reader announces either field
  by the row's title rather than as an unnamed text field. The text edit
  row's construction sets the link for every field it edits; this
  component's only part is listing both fields as edited.
- **Accessory buttons**: The buttons are image-only, so their names come
  from **labels-accessory-buttons** ("Copy"; "Show" or "Hide"), which also
  serve as their tooltips; their place in the key-view loop after the field
  is **accessory-buttons-follow-field-in-key-order**.
- **Announce state changes**: Inherited unmodified from the text edit row
  — the component has no loading state and never disables itself in
  source; masked characters being typed or deleted are announced through
  the platform's own native accessibility value reporting.
- **Minimum tap target**: Inherited unmodified from the text edit row —
  this is a pointer/trackpad-driven control composition (no touch input
  path in source); the 44×44pt minimum is touch guidance, not a
  pointer-interface requirement.
- **Contrast**: Inherited unmodified from the text edit row — the label
  and the field's typed-text color both resolve to the theme's
  `primaryText` role, and placeholder text resolves to `placeholderText`,
  which is guaranteed only a 1.6:1 contrast floor against the background
  (see design-decisions ([adhsdk.ingredient.ui.settings.rows.text-edit-view](cookbook:c1787e74-2485-4d7b-a219-feb4c07cf97c))
  and **contrast-ratio** in Compliance below). Whether an active theme's
  actual resolved colors clear WCAG 2.1 SC 1.4.3's 4.5:1 threshold for
  body text is a property of the chosen theme, not of this component.

