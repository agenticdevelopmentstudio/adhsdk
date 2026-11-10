
A master/detail block in `@adh-sdk/ui`: the shared `ListHeader`
(filter + actions + delete) over a `DataTable`, over a details pane. The list
and the details pane are PEERS in the column — the details never overlays the
list — and the divider between them renders as the details pane's always-visible
header bar (`ResizableSplit`'s header-bar variant, titled by `detailsLabel`). It
composes `ListHeader` + `DataTable` + `ResizableSplit` + `AlertModal` + `Button`.

It owns the selection state and filter; it renders rows in a `DataTable`
(clicking a row selects it; ↑/↓ move the selection — DataTable's keyboard nav),
and a bottom details pane that reflects the single selected row. It is generic
over row type `T`. Selection can be driven internally or mirrored to a URL
parameter for deep-linking (when `paramKey` is provided).

