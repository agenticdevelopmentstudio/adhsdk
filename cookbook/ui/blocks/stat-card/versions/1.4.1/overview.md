
`StatCard` in `@adh-sdk/ui` is the dashboard stat card: an `InfoPanel` headed by
an icon + title with an optional "{tool} ↗" deep link (plus optional extra header
controls via `actions`) in the header actions slot, over a vertical stack of `StatRow` figures, optional freeform content, and a muted
mono footnote. It is **pure assembly** — the shell is `InfoPanel`, the rows are
`StatRow`, the link is `ExternalLink` — so this block owns only the arrangement (a
`gap-2.5` column plus the footnote treatment), not any new chrome.

From a declarative `stats[]` (each `{ label, value, tone }`) it renders one `StatRow`
per entry; `children` render after the rows for the freeform cases (a live error
line, a sparkline), and `footnote` renders last as a small dim mono qualifier (e.g.
"anonymous · cookieless · approximate"). The card is always content-sized — it uses
`InfoPanel`'s default (non-scroll) mode, so it grows to its content rather than
scrolling.

It was extracted from a status site's Traffic/Errors telemetry cards, so every site's
"figure card with a deep link into the source tool" shares one component.

