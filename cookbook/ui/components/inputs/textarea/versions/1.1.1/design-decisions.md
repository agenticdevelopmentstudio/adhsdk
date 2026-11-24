
**Decision**: The component inherits its base visual treatment from `fieldShellClass`, the same base used by the Input component.
**Rationale**: This keeps visual consistency across form fields and centralizes updates to the shared style layer in one place.
**Approved**: pending

**Decision**: The component accepts an `autoComplete` prop and combines it with `noAutofillPropsFor(autoComplete)` to prevent password-manager and autocomplete-manager decoration, without removing the ability to opt back in.
**Rationale**: Textareas are never credentials, but managers still decorate them when the surrounding page reads like a form. `noAutofillPropsFor` returns the full suppression attribute set (`autocomplete="off"` plus the vendor-specific ignore attributes) when `autoComplete` is `undefined` or `"off"` (trimmed and compared case-insensitively), and returns no suppression attributes at all when `autoComplete` is set to any other value — a real autofill token such as `"email"` or `"current-password"` — handing the field back to managers so a form that genuinely wants autofill can opt back in by naming a token.
**Approved**: pending

**Decision**: The component applies `transition-colors` to smooth color changes during state transitions (focus, disabled, invalid).
**Rationale**: This improves perceived responsiveness without requiring JavaScript or animation libraries. The source defines no `motion-reduce:` variant, so this transition does not respect the `prefers-reduced-motion` preference (see Accessibility Options and Compliance).
**Approved**: pending

**Decision**: The component uses the native `aria-invalid` attribute to communicate validation errors.
**Rationale**: This approach is semantic, testable, and accessible; it does not invent a custom error state property.
**Approved**: pending

