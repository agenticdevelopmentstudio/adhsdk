
Both components are pure and stateless — every prop flows down into layout or the
composed `StatusDot`; nothing flows back up.

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| `tone` | Caller | StatusDot | Down | Prop pass-through |
| `label` / `labelTitle` | Caller | Truncating label element | Down | Prop |
| `trailing` | Caller | Trailing slot | Down | Prop (rendered when non-null) |
| `as` / `divided` | Caller | Root element + wrapper classes | Down | Prop |
| host attributes (`data-*`, `id`) | Caller | Root element | Down | Rest-prop spread |

