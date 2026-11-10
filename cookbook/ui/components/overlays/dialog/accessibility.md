
- **Role and properties**: `role="dialog"` with `aria-modal="true"` (set by Base UI); dialog is labelled by `DialogTitle` (via `aria-labelledby`) and described by `DialogDescription` (via `aria-describedby`) when they are rendered — see **dialog-labelling**.
- **Focus management**: Focus is trapped within the dialog while open and restored to the triggering element on close (Base UI handles this).
- **Keyboard**: Escape closes the dialog by default; Tab and Shift+Tab cycle focus within the trapped set. See **escape-closes** for how a composing component overrides this.
- **Close affordance**: The close button (`×`) carries `aria-label="Close"` to announce its purpose; this string is hardcoded directly in `dialog.tsx`'s `DialogContent`, not supplied by Base UI (see Localization).
- **Target size**: The close button's hit area is limited to its `size-4` (16×16px) icon — no padding class enlarges the clickable region — so it does not meet 44×44pt/48×48dp guidance. See Compliance's `touch-target-size` status.

