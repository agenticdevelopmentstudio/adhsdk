
- **Role**: Toolbar, signaled via `role="toolbar"`
- **Label**: Toolbar MUST have a descriptive `aria-label`; default is `"Editing actions"`
- **Button labels**: Each button (Create, Cancel, Save, Delete) MUST have visible text; icons are decorative (`data-icon="inline-start"` indicates icon placement)
- **Disabled state**: Disabled buttons MUST have the `disabled` HTML attribute set
- **Separator**: Visual separators between button groups MUST be marked `aria-hidden="true"` to prevent screen reader announcements
- **Loading indicator**: When `actions.saving` is `true`, the Save button text changes to `"Saving…"` to provide feedback; this is the accessible indicator of the saving state (not an aria-live region)
- **Keyboard interaction**: Buttons MUST be keyboard accessible and focusable per the shared Button component's implementation
- **Touch target**: Buttons inherit minimum touch target size from the shared Button component (`sm` size); verify this meets at least 44×44pt per platform HIG
- **Semantic structure**: No `aria-pressed`, `aria-checked`, or other state attributes beyond `disabled`; the button text change ("Save" → "Saving…") is the state indicator

