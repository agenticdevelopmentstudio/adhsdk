
| State | Appearance change |
|---|---|
| Content-sized (default) | outer `flex: 0 0 auto`; body `flex-none`, no scroll |
| Fill + scroll (`scroll`) | outer `flex: 1 1 0` + `min-h-0`; body `flex-auto overflow-y-auto` |
| No icon | title starts the header (leading glyph slot omitted) |
| Count 0 / absent | count hidden |
| No center | actions block gains `ml-auto` to sit at the right edge |
| Center present | center fills the middle; actions sit to its right |
| `maxHeight` / `flex` set | outer element uses the caller's layout numbers |

