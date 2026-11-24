
The component renders a native `label` element, providing semantic meaning for assistive technologies. Consumers are responsible for associating the label with its form control via the `htmlFor` attribute (matching the control's `id`) or by nesting the form control within the label. The source disables the `jsx-a11y/label-has-associated-control` ESLint rule at the component definition, because the component is a reusable primitive that does not know which control it pairs with; consumers supply the association via `...props`.

- **Role**: Label (native HTML semantic element)
- **Label requirements**: Consumer MUST provide `htmlFor` attribute or nest the associated form control
- **Focus behavior**: Clicking the label moves focus to (and, for checkboxes/radios, toggles) its associated control — see **focuses-associated-control**
- **Announce state changes**: Disabled state is communicated via opacity and cursor change; screen readers perceive this via the peer element's own disabled state, not via the label

