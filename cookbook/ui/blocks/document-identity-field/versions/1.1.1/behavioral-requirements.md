
- **render-two-inputs**: Component MUST render two text inputs, one for title and one for slug.
- **render-title-label**: Component MUST render a label for the title input (default text "Title", customizable via `titleLabel` prop).
- **render-slug-label**: Component MUST render a label for the slug input (default text "Slug", customizable via `slugLabel` prop).
- **accept-title-prop**: Component MUST accept `title` string prop and display it in the title input.
- **accept-slug-prop**: Component MUST accept `slug` string prop and display it in the slug input.
- **title-change-callback**: Component MUST call `onTitleChange` callback with the new string when the user edits the title input.
- **slug-change-callback**: Component MUST call `onSlugChange` callback with the new string when the user edits the slug input.
- **slug-follows-title**: Component MUST call `onSlugChange` when the user edits the title, passing the result of applying the `slugify` function to the new title, if the slug has not been manually edited.
- **stop-auto-slugify-after-manual-edit**: Component MUST stop auto-generating the slug from the title once the user has manually edited the slug; on subsequent title edits, the slug remains unchanged until the component is remounted (e.g., with a new `key`) — there is no in-place reset.
- **accept-slugify-function**: Component MUST accept a `slugify` function prop that takes a title string and returns a slug string, used to derive the slug from title edits.
- **accept-verdict**: Component MUST accept an optional `verdict` prop (SlugVerdict type) with properties `status` ("idle" | "checking" | "available" | "unavailable") and `reason` (string or null).
- **display-status-message**: Component MUST display a status message corresponding to the verdict status: null for "idle", "Checking…" for "checking", "Available" for "available", "Unavailable" for "unavailable".
- **display-verdict-reason**: Component MUST display `verdict.reason` when present and non-null, replacing the default status message; the reason is displayed for all non-idle statuses.
- **announce-status-changes**: Component MUST announce verdict status changes and reason text to assistive technology using an `aria-live="polite"` region.
- **accept-disabled-prop**: Component MUST accept an optional `disabled` boolean prop (default false); when true, both inputs MUST be disabled.
- **container-class-name**: Component MUST accept an optional `className` string prop and apply it to the container element.
- **position-status-in-slug-row**: Component MUST render the status message as a sibling element to the slug input within the same row, not below or above it.
- **use-monospace-slug-font**: Component MUST render the slug input's text in a monospace font, at a smaller size than the title input.

