
The shared `Pagination` in `@adh-sdk/ui` — the list pager used above and below
paged surfaces in the host application. It is a compact `Prev` / "Page X of Y" / `Next` control: a
centered `nav` landmark holding two shared `Button`s (`variant="outline"`,
`size="sm"`) around a mono caption.

It is fully **controlled**: the host owns `page` and `totalPages` and receives
`onPageChange(nextPage)` when a button is clicked — the pager renders the host's truth
and requests a change rather than keeping its own counter. When there is only one page
(`totalPages <= 1`) it renders nothing, so call sites never wrap it in their own
`{totalPages > 1 && …}` conditional. The `Prev` button is disabled on the first page
and `Next` on the last, so an out-of-range request can never be issued from the edges.

A single export ships from `@adh-sdk/ui/components/pagination`: the `Pagination`
component. It carries `"use client"` (it composes the client `Button`) but holds no
internal state — the displayed page is always the `page` prop.

