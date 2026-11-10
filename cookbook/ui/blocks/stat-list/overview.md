
`StatList` and `StatListRow` in `@adh-sdk/ui` are the shared **status list** — a
vertical stack of "tone dot + truncating label + trailing figure" rows. It is the
fleet/telemetry idiom: a monitor's *down sites* (name · duration), a card's *top
error issues* (title · count · deep link). Each row is a `StatusDot` (size 7) at the
family tone, a `min-w-0 flex-1 truncate` label, and a right-aligned `shrink-0`
trailing slot the caller fills (a bold duration, a count plus an `ExternalLink`).

It was extracted because that exact row + list grammar was hand-rolled
character-identically in the fleet status site (`MonitorCard`), the status backend's
telemetry cards (`TelemetrySections`), and the ui-showcase — the "same markup twice →
extract it" rule. `StatList` owns the list wrapper (an optional top divider + the
row gap); `StatListRow` owns one row. Both are **pure assembly** — the only visual
primitive is the shared `StatusDot`; everything else is layout + the caller's text.

