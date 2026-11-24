
The component renders hard-coded English UI chrome — `"Prev"`, `"Next"`, and the
`"Page {page} of {totalPages}"` caption — directly in JSX. These strings are
user-facing: a sighted user reads them and a screen reader announces the button
labels, so they are not exempt from localization simply because they are "chrome"
rather than content. The source has no `labels` prop, formatter, or other override
mechanism, so a host rendering `Pagination` in a non-English UI displays this English
text as-is; supplying localized labels is the host's responsibility until the
component grows one.

