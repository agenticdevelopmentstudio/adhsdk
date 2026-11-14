
- Dialog role, `aria-modal`, focus trap, and focus restoration to the opener are inherited unchanged from the `Dialog` primitive ([adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1)); `AlertModal` does not re-derive or override them.
- The dialog MUST be labelled by `title` (via `DialogTitle`) and, when provided, described by `description` (via `DialogDescription`).
- The tone icon is decorative: it is rendered with `aria-hidden` and never substitutes for a text label.
- The alert-mode busy spinner exposes `role="status"` and `aria-label="Working…"`; confirm-mode busy is forwarded to `DialogActions`, which applies the identical `role="status"` / `aria-label="Working…"` treatment ([adhsdk.ingredient.ui.components.overlays.dialog-actions](cookbook:f679a77e-04f7-4e43-b898-6d78a637a760)).
- Both footer buttons are the shared `Button` component, which renders a real, focusable `<button>` — keyboard activation (Space/Enter) is native ([adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0)).
- Minimum touch/click target size, minimum contrast ratio, and other platform-specific accessibility requirements are inherited from the `Button` component and the shared design-token stylesheet; see [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) and the WCAG 2.1 AA reference in [adc.guideline.cookbook.ui.platform-design-languages](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f26a9468-a15c-4cd2-b944-d39221e7eee2).

