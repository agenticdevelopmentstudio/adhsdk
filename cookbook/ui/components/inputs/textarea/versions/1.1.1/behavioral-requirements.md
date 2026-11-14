
- **textarea-root**: The component MUST render an HTML `<textarea>` element as its root node.
- **prop-forwarding**: The component MUST accept and forward all standard HTML textarea props (e.g., `value`, `onChange`, `placeholder`, `disabled`, `rows`, `cols`) to the underlying textarea element via spread props.
- **custom-classname**: The component MUST accept a `className` prop and merge it with the default styles, so both apply unless they conflict, in which case the custom class wins.
- **autocomplete-control**: The component MUST accept an `autoComplete` prop to control browser autocomplete behavior, and MUST forward it to the textarea element.
- **autofill-suppression**: The component MUST suppress password manager and autocomplete manager decoration based on the `autoComplete` value, even though textareas are never credentials.
- **fieldshell-base-styles**: The component MUST apply the shared field-shell base visual treatment (border, background, corner radius) also used by the Input component.
- **min-height**: The component MUST set a minimum height of 64px.
- **full-width**: The component MUST set width to 100% of its container.
- **padding**: The component MUST apply padding of 12px horizontally and 8px vertically.
- **font-size**: The component MUST use a 14px font size.
- **text-color**: The component MUST apply the `text-apt-text` token color to the textarea text.
- **color-transition**: The component MUST smoothly transition color changes during state transitions (focus, disabled, invalid).
- **outline-removal**: The component MUST remove the default browser focus outline, since the component provides its own focus indicator.
- **placeholder-styling**: The component MUST render placeholder text using the dimmed text token color (`apt-text-dim`).
- **focus-indicator**: The component MUST show a focus indicator when `focus-visible` state is active, consisting of a border change to `apt-gold` and a 2px ring with `apt-gold/25` opacity.
- **disabled-state**: The component MUST disable pointer events, show a not-allowed cursor, and reduce opacity to 50% when the `disabled` attribute is present.
- **invalid-state**: The component MUST change the border and ring color to `apt-red` with `apt-red/25` ring opacity when the `aria-invalid` attribute is set to `true`.
- **data-slot**: The component MUST set the `data-slot="textarea"` attribute on the root textarea element for testing and targeting purposes.

