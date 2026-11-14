
**Default (Fused) Mode:**
- Container: the shared field-shell token (border + field-surface background + corner radius), with a row-wrapping layout; chips and the inline input are co-located in one container.
- Chips: the neutral-chip token for valid entries, the error-chip token for invalid entries, each wrapped in a removable-chip affordance with a trailing × control.
- Inline input: borderless, transparent background, primary-text color; placeholder text (placeholder-text token) shown only when the chip list is empty.

**Separate Input Mode:**
- Recipients box: the same field-shell token as the fused container, with a minimum height so it doesn't collapse when empty, wrapping chips. Chips here are the same removable `RemovableChip` elements as fused mode — the remove affordance works identically — unless `readOnly` is also set, in which case they become static Badges exactly as in Read-Only Mode. Placeholder text ("No recipients yet") shown when empty.
- Input element: rendered separately below the recipients box, using the shared Input primitive at tighter vertical metrics than its default. Omitted entirely when `readOnly=true`.

**Read-Only Mode:**
- No input field is rendered.
- Recipients display with the same neutral-chip / error-chip tokens as the editable modes, without a remove affordance.

**Focus and Disabled:**
- Default mode: the container itself carries the focus-accent token when any descendant is focused.
- Separate mode: focus-accent is carried by the Input primitive's own focus styling, not the recipients box.
- Disabled: the disabled token (reduced opacity, non-interactive) applies to the whole component.

