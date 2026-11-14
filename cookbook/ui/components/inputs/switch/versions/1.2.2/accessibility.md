
- **Role**: The underlying base-ui `Switch.Root` renders as a `<span role="switch">` (plus a visually hidden native `<input type="checkbox">` beside it for form semantics); it is not a native button.
- **State announcement**: The component exposes checked state via the `aria-checked` attribute, updated when state changes.
- **Keyboard support**: The component MUST be keyboard accessible via Tab navigation and Space (optionally Enter) to toggle.
- **Minimum tap target**: The outer container (36px × 20px) does not meet the 44×44pt minimum touch target on all platforms; consumers SHOULD wrap the Switch in a larger interactive area for mobile contexts.
- **Disabled communication**: When disabled, base-ui sets `aria-disabled="true"` and `data-disabled` on the `<span>` root and moves it out of the tab order (`tabindex="-1"`); the native HTML `disabled` attribute is applied only to the hidden `<input>`, not the visible root. Because the root never matches the CSS `:disabled` pseudo-class, the `disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50` Tailwind utilities never take effect — the track/thumb keep full opacity and the cursor stays `pointer`. Toggling is still blocked, but by Base UI's internal click/keydown guards, not by `pointer-events: none`.
- **Label association**: The component itself has no text content; a label element or aria-label MUST be provided by the consumer.

