
- **Background**: Transparent; the component sets no background or border of its own.
- **Padding**: Bottom padding is `calc(var(--kb-inset) + var(--safe-bottom))` (see adjust-bottom-padding), animated over 180ms ease-out; left, right, and top padding are not set by the composer itself — add them via `className`.
- **Border**: None; the component sets no border.
- **Width / position / stacking order**: Not owned by ViewportComposer. It renders a plain block `<div>` with no explicit `width` or `position`; its full width and its position at the bottom of the page come from being the last child inside `ViewportShell`'s column-flex layout — see [adhsdk.ingredient.viewport.viewport-shell](cookbook:960a1577-bf48-4d56-a93f-aa690853f64f).
- **Height**: Auto (sized by children and padding)

