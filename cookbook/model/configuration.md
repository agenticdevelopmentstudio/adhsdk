
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Fuse `threshold` | `number` | `0.3` | Hardcoded fuzzy-match tolerance inside `createSearchIndex`; not exposed as a caller-supplied option. |
| Fuse `minMatchCharLength` | `number` | `2` | Hardcoded minimum characters before a match registers; not exposed as a caller-supplied option. |
| Fuse key weights | `number` | title `3`, summary `2`, domain `1` | Hardcoded relative weighting of the three indexed fields; not exposed as a caller-supplied option. |

The functions' inputs (`entries`, `slug`, `section`, `domain`, `sections`, `index`) are call parameters, not configuration; they are described in the Overview and in Behavioral Requirements.
