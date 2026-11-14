
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `items` | `readonly BarListItem[]` | (required) | Rows in display order. Each item has `name: string`, `value: number` and optional `detail: string` that replaces the formatted value. |
| `ariaLabel` | `string` | (required) | Says what is being ranked, for a screen reader. |
| `color` | `string` | `var(--color-apt-cat-blue)` | Any CSS color; normally a theme token. Fills every bar. |
| `formatValue` | `(value: number) => string` | the trend chart block's count formatter | Turns a value into the text shown beside the name. |
| `maxItems` | `number` | `8` | Rows shown at first; a button beneath opens the rest. |
| `onSelect` | `(name: string) => void` | `undefined` | When given, each row becomes a button that calls it with the row's name. |
| `selected` | `string \| null` | `null` | The name of the selected row; drives the pressed state and the dimming of other rows. |
| `emptyLabel` | `string` | `"Nothing to show."` | Text shown when `items` is empty. |
| `className` | `string` | `undefined` | Extra classes for the outermost element and the empty-state element. |

