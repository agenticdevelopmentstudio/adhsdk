
- **centered-modal**: `DialogContent` MUST render a centered, portalled popup over a dimmed, blurred backdrop.
- **backdrop-dismissal-disabled**: By default the dialog MUST NOT close on a backdrop or outside click (`disablePointerDismissal`); a caller MAY re-enable it with `disablePointerDismissal={false}`.
- **escape-closes**: Escape MUST close the dialog by default.
- **escape-overridable**: A composing component MAY keep the dialog open on Escape by supplying its own `onOpenChange` handler (see Edge Cases, "Escape override, uncontrolled" and "Escape override, controlled").
- **close-affordance**: `DialogContent` MUST render a labelled `×` close button by default, and activating it MUST close the dialog; `showClose={false}` MUST hide it.
- **focus-trap**: While open, focus MUST be trapped within the dialog and restored to the opener on close.
- **dialog-labelling**: Every composing dialog MUST render a `DialogTitle` so the dialog is labelled for assistive technology; `DialogDescription` SHOULD be rendered whenever the dialog has descriptive text.

