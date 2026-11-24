
- **Role**: Compound form control presenting two text inputs
- **Title input label**: Associated via the shared `<label>` element that the `Field` component ([adhsdk.ingredient.ui.blocks.field](cookbook:0c199036-81c3-47c3-9e79-e4b8187ca69a)) renders in its inline layout, which implicitly wraps both caption and input; the title's accessible name never changes, so implicit wrapping is safe.
- **Slug input label**: Associated via `aria-labelledby` pointing to a `<span id>` containing only the label text — a different technique than the title's, because the slug row's implicit `<label>` also wraps the status span; without `aria-labelledby` the slug input's accessible name would grow, and mutate, with every verdict. `aria-describedby` then carries the verdict as a description, which is allowed to change.
- **Status announcement**: Rendered in an `aria-live="polite"` region; region is unconditionally mounted in DOM so changes are announced
- **Status as description**: Slug input uses `aria-describedby` pointing to status message element when status is present
- **Minimum tap target**: Both inputs inherit their touch target size from the `Input` component ([adhsdk.ingredient.ui.components.inputs.input](cookbook:0f5b7167-b375-4f44-977b-566f720a453d)) and add none of their own; on the web the minimum is 24×24 CSS px (WCAG 2.5.8)
- **Keyboard navigation**: Both inputs are keyboard accessible; Tab navigates title → slug in document order. The status message is never focusable and takes no place in the Tab sequence; it is announced through the `aria-live` region instead.
- **Focus management**: Each input receives focus independently; focus is not trapped or redirected
- **High contrast**: Status message colors derive from tone tokens (muted, success, error) which meet WCAG AA contrast requirements
- **Color not alone**: Slug status is communicated by text and color; unavailable vs. available is text-differentiated, not color-only

