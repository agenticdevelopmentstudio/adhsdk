
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `items` | `readonly T[]` | required | The full (unfiltered) item array; its length is `total`. |
| `getId` | `(item: T) => string` | required | Callback to get a unique ID for each item. |
| `getTitle` | `(item: T) => string \| undefined \| null` | required | Callback to get title text for each item; also searched by the default matcher. |
| `getSubtitle` | `(item: T) => string \| undefined \| null` | undefined | Callback to get subtitle text for each item; also searched by the default matcher. |
| `getDetails` | `(item: T) => string \| undefined \| null` | undefined | Callback to get details text for each item; also searched by the default matcher. |
| `getSearchableExtras` | `(item: T) => readonly (string \| undefined \| null)[]` | undefined | Extra strings searched alongside title/subtitle/details by the default matcher. |
| `match` | `(item: T, queryLower: string) => boolean` | default matcher (case-insensitive substring, see **filter-items**) | Overrides the default matcher entirely; receives the item and the already-lower-cased, trimmed query. |
| `initialQuery` | `string` | `""` | Initial value of the query/input text. |
| `placeholder` | string | "Filter…" | Placeholder text for the input field |
| `className` | string | undefined | Optional CSS class name to apply to the root element (appended to "fl-root") |
| `autoFocus` | boolean | false | Whether the input field should receive focus on mount |
| `renderItem` | `(item: T) => ReactNode` | undefined | Optional custom render function for item content; if provided, overrides title/subtitle/details rendering (see **custom-item-render**) |
| `onSelect` | `(item: T) => void` | undefined | Callback invoked when an item is selected via Enter or click; makes items clickable buttons if provided |
| `onHighlightChange` | `(item: T \| null) => void` | undefined | Callback invoked when the highlighted item changes; receives the highlighted item or null |
| `footer` | ReactNode | undefined | Optional element to render as the last list item |
| `emptyContent` | ReactNode | undefined | Optional custom message shown when filtering yields zero visible items while `total > 0`; has no effect when `total === 0` (see **default-no-matches-message**, **custom-empty-content**) |

