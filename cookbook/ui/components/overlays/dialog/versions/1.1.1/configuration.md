
Subcomponents and their key props:
- **Dialog** (root): `disablePointerDismissal` (bool, default `true`), `open` (bool), `onOpenChange` (callback).
- **DialogTrigger**: Forwards Base UI Trigger props; typically wraps an action button.
- **DialogClose**: Forwards Base UI Close props; used in footer buttons or standalone.
- **DialogContent**: `showClose` (bool, default `true`), `className` (string for overrides); forwards Base UI Popup props.
- **DialogHeader**: `className` override; forwards div props.
- **DialogFooter**: `className` override; forwards div props.
- **DialogTitle**: Forwards Base UI Title props.
- **DialogDescription**: Forwards Base UI Description props.

