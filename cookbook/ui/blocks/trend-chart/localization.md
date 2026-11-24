
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `emptyLabel` | No data in this range. | Prop with a default |
| table toggle | View as table | Hard-coded, not a prop |
| table header | Period | Hard-coded, not a prop |
| missing value | — | Hard-coded em dash in tooltip and table |

Number formatting uses fixed `en` locale formatters in `formatCount`; callers localize through `formatValue`, `formatLabel` and `formatDetail`.

