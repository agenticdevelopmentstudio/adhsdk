
`StatCard` holds no state — it is pure, declarative assembly. Every prop flows down
into a composed part; nothing flows back up except the browser navigation an
`ExternalLink` triggers (a new tab).

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| `title` / `icon` / `className` | Caller | InfoPanel | Down | Prop pass-through |
| `link` (`{href,label}`) | Caller | ExternalLink (actions slot) | Down | Prop → `actions` |
| `actions` | Caller | InfoPanel actions slot (after the link) | Down | Prop → `actions` |
| host attributes (`data-*`, `id`) | Caller | InfoPanel root `<section>` | Down | Rest-prop spread |
| `stats[]` | Caller | StatRow (one per entry) | Down | Array `map` |
| `children` | Caller | Body stack (after rows) | Down | Prop |
| `footnote` | Caller | Footnote caption | Down | Prop (rendered when non-null) |
| deep-link navigation | ExternalLink | New browser tab | Up (side effect) | `target="_blank"` anchor |

