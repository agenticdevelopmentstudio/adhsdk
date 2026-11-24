
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `labels` | readonly string[] | required | One label per bucket |
| `series` | readonly TrendSeries[] | required | Name, CSS color and one value per label (null is a gap) |
| `ariaLabel` | string | required | Says what the chart shows |
| `variant` | `"line"` or `"bars"` | `"line"` | Bars draw the first series only |
| `height` | number | 200 | Plot height in pixels |
| `formatValue` | (number) => string | `formatCount` | Tooltip and table values |
| `formatLabel` | (string) => string | identity | Axis labels |
| `formatDetail` | (string) => string | `formatLabel` | Tooltip and table labels |
| `emptyLabel` | string | "No data in this range." | Shown when there is nothing to plot |
| `className` | string | none | Merged onto the root |

