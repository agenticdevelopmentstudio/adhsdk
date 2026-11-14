
| Option | Behavior |
|--------|----------|
| Reduce Motion | Component does not apply motion within its own render. Sub-components (Combobox, EntityChooser, EntitySelectionChips) are responsible for respecting OS reduce-motion preferences. |
| Increase Contrast | Component does not apply contrast changes; sub-components handle contrast adjustments. |
| Differentiate Without Color | Component uses text and icons provided by sub-components; no color-only differentiation is introduced by TagSetField. |

