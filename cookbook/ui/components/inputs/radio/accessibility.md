
- **Role/trait**: Radio button (native semantic role via Base UI RadioPrimitive.Root)
- **Label requirements**: Labels are external to the RadioGroupItem; the form must associate labels via standard form patterns (e.g., `<label htmlFor="radio-id">` or wrapping)
- **Announce state changes**: Checked/unchecked state is automatically announced by assistive technology via the semantic radio role
- **Minimum tap target**: The 16×16px control alone is below the WCAG 2.5.8 (AA) minimum target size of 24×24 CSS pixels. Base UI's radio role lets a click on the associated `<label>` select the item, so consumers MUST ensure the label (or an equivalent wrapping hit area) extends the clickable region to at least 24×24px.
- **Keyboard navigation**: RadioGroupItem supports Space to select while focused (see **space-selects**) and shows a visible focus indicator (see **focus-visible**). Arrow-key navigation between items and the group's single Tab stop are managed by the RadioGroup container — see [adhsdk.ingredient.controls.user-settings.components.radio-group](cookbook:d431934e-d64c-4dcf-bdab-b7c3465ee71b).
- **Focus indicator**: Visible focus ring (gold border and ring) provides keyboard focus indication

