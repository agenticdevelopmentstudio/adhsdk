
- **hides-when-single-page**: When `totalPages` is `<= 1`, the component MUST render nothing.
- **renders-pagination-landmark**: The component MUST render a `nav` element with `aria-label="Pagination"`.
- **shows-page-caption**: The component MUST render a `Page {page} of {totalPages}` caption reflecting the current props.
- **disables-prev-on-first**: When `page <= 1`, the component MUST disable the `Prev` button.
- **disables-next-on-last**: When `page >= totalPages`, the component MUST disable the `Next` button.
- **pages-backward**: Clicking `Prev` MUST call `onPageChange` with `page - 1`.
- **pages-forward**: Clicking `Next` MUST call `onPageChange` with `page + 1`.
- **controlled-page**: The component MUST reflect the `page` prop directly and MUST NOT advance the page on its own — a new page appears only when the host re-renders with a new `page`.
- **forwards-classname**: The component MUST merge a consumer `className` onto the `nav` via `cn()`.

