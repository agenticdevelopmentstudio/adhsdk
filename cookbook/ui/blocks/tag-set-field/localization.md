
The `label` and `noun` props are host-supplied and already localizable. The remaining microcopy is hardcoded English in the source and is not currently exposed as overridable props or externalized string keys — concatenating `noun` into a fixed English sentence shape (`"Add a ${noun}…"`) also assumes English grammar (e.g. the indefinite article "a"), which will not read correctly in every target language without further work:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `tag-set-field.combobox-aria-label` | `Add a ${noun}` | Combobox `ariaLabel` |
| `tag-set-field.combobox-placeholder` | `Add a ${noun}…` | Combobox placeholder |
| `tag-set-field.chooser-input-label` | `Filter or add a ${noun}` | EntityChooser `inputLabel` |
| `tag-set-field.chooser-placeholder` | `Filter or add a ${noun}…` | EntityChooser placeholder |
| (from Field) | (parent-provided) | `label` and `hint` are provided by the parent and are not localized by this component. |

The component constructs microcopy dynamically from the `noun` prop and does not maintain a separate string catalog. All other user-facing text originates from parent props.

