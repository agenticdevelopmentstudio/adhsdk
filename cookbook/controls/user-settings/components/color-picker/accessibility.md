
- **Role**: `<input type="color">` has no dedicated ARIA role mapping in the HTML-AAM spec; browsers and assistive technologies expose it inconsistently (for example, as a generic color well rather than a `textbox`). The `label` is associated to the input via `htmlFor` matching the input's `id`.
- **Label requirements**: When a `label` prop is provided, it MUST be associated to the input via `htmlFor` matching the input's `id`.
- **Hex value announcement**: The hex value display is marked `aria-hidden="true"`, on the assumption that the color input's own accessible state already conveys the value when it changes. That assumption is not verified across every browser/AT pairing, so some combinations may not announce the color at all once it is hidden from the accessibility tree.
- **Minimum tap target**: The native color input button itself has user-agent-defined sizing; the label and hint text are not interactive tap targets.
- **Keyboard navigation**: The native HTML color input supports standard keyboard interaction (Tab to focus, Enter/Space to open picker on supporting browsers).

