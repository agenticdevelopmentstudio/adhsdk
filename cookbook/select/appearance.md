
Two implementations exist in source: the generic (`aws-field`) implementation defers all appearance to caller-supplied CSS classes and specifies no fixed values in source; the apt-token implementation gives concrete values. The following canonical appearance draws from the apt-token implementation, given as sizes in px and a semantic role per color.

- **Container**: Wrapper `<div>` (`position: relative` in the apt implementation) that groups the label, select, and hint; the generic implementation applies the classes `aws-field` and `aws-field--select` as its styling hooks.
- **Native select styling**: The native select element renders with `appearance: none` to allow custom styling while retaining native behavior.
- **Corner radius**: 8px, from the shared field-shell style.
- **Padding**: 12px horizontal, 8px vertical; the apt implementation adds 36px of trailing padding to clear the chevron icon.
- **Font**: 14px; color role "primary text".
- **Background**: color role "field surface", from the shared field-shell style.
- **Border**: 1px, color role "field border" by default; on focus, color role "accent".
- **Focus ring**: 2px, color role "accent" at 25% opacity.
- **Indicator icon**: 16px chevron-down icon, positioned 12px from the trailing edge, vertically centered; color role "muted text".
- **Min/Max size**: height 36px; width grows to fill its container.
- **Disabled appearance**: 50% opacity, pointer events removed, cursor shows not-allowed.

