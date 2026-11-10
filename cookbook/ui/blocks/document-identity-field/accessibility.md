
- **Role**: Compound form control presenting two text inputs
- **Title input label**: Associated via the shared `<label>` element that implicitly wraps both caption and input; the title's accessible name never changes, so implicit wrapping is safe.
- **Slug input label**: Associated via `aria-labelledby` pointing to a `<span id>` containing only the label text — a different technique than the title's, because the slug row's implicit `<label>` also wraps the status span; without `aria-labelledby` the slug input's accessible name would grow, and mutate, with every verdict. `aria-describedby` then carries the verdict as a description, which is allowed to change.
- **Status announcement**: Rendered in an `aria-live="polite"` region; region is unconditionally mounted in DOM so changes are announced
- **Status as description**: Slug input uses `aria-describedby` pointing to status message element when status is present
- **Minimum tap target**: Both inputs inherit minimum touch target size from Input component (platform default, typically 44×44pt on iOS, 48×48dp on Android)
- **Keyboard navigation**: Both inputs are keyboard accessible; Tab navigates title → slug in document order. The status message is never focusable and takes no place in the Tab sequence; it is announced through the `aria-live` region instead.
- **Focus management**: Each input receives focus independently; focus is not trapped or redirected
- **High contrast**: Status message colors derive from tone tokens (muted, success, error) which meet WCAG AA contrast requirements
- **Color not alone**: Slug status is communicated by text and color; unavailable vs. available is text-differentiated, not color-only

