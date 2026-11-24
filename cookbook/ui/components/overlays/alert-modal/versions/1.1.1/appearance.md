
- **Corner radius**: Not applicable — owned by `DialogContent` via the Dialog recipe ([adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1)).
- **Padding**: Not applicable — owned by `DialogContent` via the Dialog recipe.
- **Font**: Title weight/size are inherited from `DialogTitle` (unmodified here); `AlertModal` only overrides the title's text color and adds a leading-icon layout (`flex items-center gap-2 text-apt-gold`).
- **Background**: Not applicable — owned by `DialogContent` via the Dialog recipe.
- **Foreground/Text**: Title text is `text-apt-gold`. Tone icon color is `text-apt-blue` (info), `text-apt-green` (success), or `text-apt-red` (error/destructive). Busy spinner (alert mode) is `text-apt-text-muted`.
- **Border**: Not applicable — owned by `DialogContent` via the Dialog recipe.
- **Shadow**: Not applicable — owned by `DialogContent` via the Dialog recipe.
- **Min/Max size**: Not applicable — sizing is owned by `DialogContent` and can be overridden via the `contentClassName` prop.
- **Icon size**: Tone icon is `size-5 shrink-0`; busy spinner (alert mode) is `size-4 animate-spin`.
- **Confirm button (alert mode)**: `size="sm"`, `className="w-full"` (full width of the footer).

