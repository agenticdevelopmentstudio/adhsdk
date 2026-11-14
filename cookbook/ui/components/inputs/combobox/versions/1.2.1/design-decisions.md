
**Decision**: Wrap the headless primitive, don't hand-roll. Combobox ARIA (`role`, `aria-expanded`, `aria-controls`, `aria-activedescendant`), roving activation, filtering, and floating-popup positioning are handled by Base UI's `Autocomplete`.
**Rationale**: Reimplementing these would be error-prone and inconsistent with the rest of `@adh-sdk/ui`, which already composes Base UI primitives.
**Approved**: pending

**Decision**: Replace the native `<datalist>` pattern rather than use it directly.
**Rationale**: `<datalist>` cannot be styled to match the design system, and its screen-reader and keyboard support varies significantly across browsers; a themed, keyboard-correct wrapper gives every site one consistent, accessible autocomplete instead.
**Approved**: pending

**Decision**: Autocomplete, not Combobox/Select. Base UI's `Autocomplete` primitive is used rather than the selection-oriented `Combobox`.
**Rationale**: The value is the free text the user types (datalist semantics), not a fixed selection from a set of options, so `Autocomplete` is the matching primitive.
**Approved**: pending

**Decision**: Suggestions are plain strings, not `{value, label}` objects.
**Rationale**: Plain strings mirror the `<datalist>` pattern this component replaces; richer item shapes belong to `ListChooser` / `OptionMenu`.
**Approved**: pending

**Decision**: The wrapper adds theme only, no additional behavior beyond styling and the controlled `value`/`onValueChange` surface.
**Rationale**: Keeping the wrapper disposable and easy to track against upstream Base UI changes.
**Approved**: pending

