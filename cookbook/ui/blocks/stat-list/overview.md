
`StatList` and `StatListRow` in `@adh-sdk/ui` are the shared **status list** — a
vertical stack of "tone dot + truncating label + trailing figure" rows. It is the
fleet/telemetry idiom: a monitor's *down sites* (name · duration), a card's *top
error issues* (title · count · deep link). Each row is a `StatusDot` (7 px) at the
family tone, a label that flexes to claim the remaining width and clips with an
ellipsis, and a right-aligned non-shrinking trailing slot the caller fills (a bold duration, a count plus an `ExternalLink`).

It was extracted because that exact row + list grammar was hand-rolled
character-identically in the fleet status site, the status backend's telemetry
cards, and the ui-showcase — the "same markup twice → extract it" rule. `StatList` owns the list wrapper (an optional top divider + the
row gap); `StatListRow` owns one row. Both are **pure assembly** — the only visual
primitive is the shared `StatusDot`; everything else is layout + the caller's text.

