
- **render-as-button**: Component MUST render as a standard HTML `<button>` element.
- **accept-html-attributes**: Component MUST accept and pass through all standard HTMLButtonElement attributes (onClick, disabled, aria-*, data-*, etc.) via rest props.
- **support-children**: Component MUST render the `children` prop if provided; children MAY be text nodes or React elements.
- **apply-base-class**: Component MUST always include the CSS class `aws-button` on the rendered button element.
- **apply-variant-class**: Component MUST apply a variant-based CSS class in the format `aws-button--{variant}` where variant is the value of the `variant` prop.
- **default-variant**: Component MUST default the `variant` prop to `'primary'` when not provided.
- **closed-variant-set**: Component's `variant` prop MUST be constrained to the closed set `'primary' | 'secondary' | 'destructive'` (the `SettingsButtonVariant` type), so no other string is assignable.
- **default-type**: Component MUST default the HTML `type` attribute to `'button'` when not provided.
- **merge-classname**: Component MUST combine `aws-button`, the variant class, and any custom `className` prop using whitespace separation, filtering out falsy values.

