
- **Empty or null input value**: Component renders with empty field; placeholder text visible if provided; no error state unless `aria-invalid="true"` is set externally
- **Very long input text**: Component uses `min-w-0` to prevent flex/grid overflow; text scrolls horizontally within field rather than pushing container
- **Autofill with undefined token**: `autoComplete={undefined}` is destructured and not spread, then `noAutofillPropsFor(undefined)` returns the off-attribute set to prevent password manager intrusion; this is the correct behavior for fields that should not autofill
- **Autofill with explicit token (e.g., "email")**: Helper returns nothing to overwrite; explicit token written before spread wins; password managers can detect and populate
- **Disabled state combined with other states**: Disabled MUST override all other interactive states; focus ring and hover are not visible when disabled
- **Disabled state with aria-invalid**: Both classes applied; visual indicators show both states; disabled state takes precedence in user interaction

