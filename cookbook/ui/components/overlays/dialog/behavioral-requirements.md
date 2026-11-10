
- **centered-modal**: `DialogContent` MUST render a centered, portalled popup over a dimmed, blurred backdrop.
- **backdrop-dismissal-disabled**: By default the dialog MUST NOT close on a backdrop or outside click (`disablePointerDismissal`); a caller MAY re-enable it with `disablePointerDismissal={false}`.
- **escape-closes**: Escape MUST close the dialog, unless a composing component overrides it via its own `onOpenChange` handler.
- **close-affordance**: `DialogContent` MUST render a labelled `×` close button by default; `showClose={false}` MUST hide it.
- **focus-trap**: While open, focus MUST be trapped within the dialog and restored to the opener on close.
- **dialog-labelling**: Every composing dialog MUST render a `DialogTitle` so the dialog is labelled for assistive technology; `DialogDescription` MUST be rendered when descriptive text is needed.

