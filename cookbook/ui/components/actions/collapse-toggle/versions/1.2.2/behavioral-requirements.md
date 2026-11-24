
- **click-invokes-on-toggle**: Clicking the button MUST invoke the `onToggle` callback with the click event.
- **forwarded-click-event**: The `onToggle` callback MUST receive the React `MouseEvent` so the caller can inspect modifier keys (Ctrl/⌘-click).
- **glyph-when-collapsed**: When `collapsed` is `true`, the button MUST display the `»` (RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK, U+00BB) glyph.
- **glyph-when-expanded**: When `collapsed` is `false`, the button MUST display the `«` (LEFT-POINTING DOUBLE ANGLE QUOTATION MARK, U+00AB) glyph.
- **aria-label-text**: The button's `aria-label` MUST be set to "Collapse {label}" when `collapsed` is `false`, and "Expand {label}" when `collapsed` is `true`, where `{label}` is the value of the `label` prop.
- **aria-expanded-state**: The button's `aria-expanded` attribute MUST be set to `true` when `collapsed` is `false`, and `false` when `collapsed` is `true`.
- **title-attribute-text**: The button's `title` attribute MUST match the `aria-label` value to provide tooltip text.
- **button-type**: The button element MUST have `type="button"` to prevent form submission.
- **aria-controls-optional**: If the `controls` prop is provided, the button's `aria-controls` attribute SHOULD be set to that value to indicate the region being toggled.
- **classname-merge**: The component MUST accept an optional `className` prop and apply it to the button element; when a caller class conflicts with one of the component's default classes for the same CSS property, the caller's class MUST override the default.

