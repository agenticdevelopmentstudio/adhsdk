
- **Role**: Toolbar, signaled via `role="toolbar"`
- **Label**: Toolbar MUST have a descriptive `aria-label`; default is `"Editing actions"`
- **Button labels**: Each button (Create, Cancel, Save, Delete) MUST have visible text; icons are decorative (`data-icon="inline-start"` indicates icon placement)
- **Disabled state**: Disabled buttons MUST have the `disabled` HTML attribute set
- **Separator**: Visual separators between button groups MUST be marked `aria-hidden="true"` to prevent screen reader announcements
- **Loading indicator**: When `actions.saving` is `true`, the Save button text changes to `"Saving…"` to provide feedback; this is the accessible indicator of the saving state (not an aria-live region)
- **Keyboard interaction**: Buttons MUST be keyboard accessible and focusable per the shared Button component's implementation. Each button is its own tab stop; the bar does not implement the WAI-ARIA toolbar keyboard pattern (a single tab stop with arrow keys moving between buttons), so `role="toolbar"` is a landmark-style label here and `keyboard-navigable` is recorded as partial in Compliance
- **Touch target**: Buttons inherit their touch target size from the shared Button component at its `sm` size. This is a known shortfall against the 44×44pt platform HIG minimum, recorded as `touch-target-size` failed in Compliance; it is the same shortfall the Button recipe ([adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0)) documents for that size
- **Semantic structure**: No `aria-pressed`, `aria-checked`, or other state attributes beyond `disabled`; the button text change ("Save" → "Saving…") is the state indicator

