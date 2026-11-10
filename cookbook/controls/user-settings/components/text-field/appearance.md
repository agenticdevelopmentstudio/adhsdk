
- **Corner radius**: `0.375rem`, set by `.aws-field__input` in `packages/web/packages/controls/src/user-settings/styles.css`.
- **Padding**: `0.5rem` vertical × `0.65rem` horizontal, set by `.aws-field__input`.
- **Font**: The input inherits the surrounding font (`font: inherit`) at `font-size: 0.9rem`. The label uses `font-size: 0.8rem`, `font-weight: 500`, uppercase, `letter-spacing: 0.04em`. The hint uses `font-size: 0.75rem`.
- **Background**: `var(--aws-bg)` (resolves to `var(--color-surface, var(--bg, #0c0c0f))`).
- **Foreground/Text**: The input uses `color: inherit`; the label and hint use `var(--aws-text-muted)`.
- **Border**: `1px solid var(--aws-border)`; focus changes it to `var(--aws-accent)`; disabled drops opacity to `0.55`.
- **Shadow**: None; the stylesheet applies no shadow to `.aws-field__input`.
- **Min/Max size**: The input is `width: 100%` with no min/max; the textarea additionally sets `min-height: 4.5rem` and `resize: vertical`, on top of the fixed `rows={4}` set by the component.

