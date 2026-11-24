
- **Decision**: Display the color's hex value rather than RGB.
  **Rationale**: Hex is the standard representation for web colors, matches developer expectations, and is more compact in the form than an RGB triplet.
  **Approved**: pending

- **Decision**: Mark the hex value display with `aria-hidden="true"`.
  **Rationale**: The value duplicates state already exposed through the color input itself, so hiding the plain-text span avoids a redundant announcement in browsers/AT pairs where the input's accessible state already conveys the value on change. This assumes typical Chromium/WebKit + VoiceOver/NVDA behavior and has not been verified against every browser/AT combination.
  **Approved**: pending

- **Decision**: Use the native `<input type="color">` rather than a custom color-picker UI.
  **Rationale**: Leverages user-agent-provided UX, reduces bundle size, and ensures consistent behavior across browsers without building custom picker/canvas logic.
  **Approved**: pending

- **Decision**: Require both `value` and `onChange` props, making this a controlled component.
  **Rationale**: Keeps the parent in full control of color state, enabling validation, side effects, and multi-field coordination without the component owning any internal state.
  **Approved**: pending

- **Decision**: Display the raw `value` prop as the hex text rather than the browser-normalized value the input holds.
  **Rationale**: The component is controlled, so the parent's `value` is the single source of truth and the text shows exactly what the parent passed; the input's own lowercase `#rrggbb` form is only seen through `onChange`. The cost is that `#FF0000` can sit next to a swatch holding `#ff0000`, and an empty `value` shows blank text beside a black swatch (see **render-hex-display** and Edge Cases).
  **Approved**: pending
