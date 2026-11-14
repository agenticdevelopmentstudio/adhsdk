
- **Empty or null input value**: Component renders with empty field; placeholder text visible if provided; no error state unless `aria-invalid="true"` is set externally
- **Very long input text**: Component uses `min-w-0` to prevent flex/grid overflow; text scrolls horizontally within field rather than pushing container
- **Autofill with undefined token**: An autofill token that is explicitly `undefined` behaves exactly like an absent one: the opt-out set is applied, so password managers stay out of the field. The mechanism is in the React/Web note.
- **Autofill with explicit token (e.g., "email")**: The token passes through unchanged and no opt-out attribute is applied, so password managers can detect and populate the field.
- **Disabled state combined with other states**: See **disabled-precedence**; focus ring and hover are not visible when disabled
- **Disabled state with aria-invalid**: Both classes applied; visual indicators show both states; disabled state takes precedence in user interaction

