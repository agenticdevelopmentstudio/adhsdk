
- **Empty or invalid value**: The component performs no validation or parsing of `value`; it passes the prop straight through to the native `<input type="color">`. Per the HTML value-sanitization algorithm, any value that is not a valid 6-digit lowercase hex color — including an empty string — is reset to `#000000` by the browser itself; the component does not detect or surface this fallback. The hex text display is unaffected by this sanitization: it always shows the raw `value` prop (see **render-hex-display**), so an empty or non-lowercase `value` renders a swatch showing `#000000` next to hex text that does not match it, until a controlled parent updates `value` from `onChange`'s already-lowercased argument.
- **Null or undefined label/hint**: Component gracefully skips rendering label or hint if props are not provided; no error or empty placeholder is shown.
- **Disabled with active focus**: On some platforms, a disabled input may retain focus; the browser's native input handles this state.
- **Rapid value changes**: Multiple onChange calls in quick succession (e.g., from drag in the picker) are all propagated immediately; the component does not debounce.

